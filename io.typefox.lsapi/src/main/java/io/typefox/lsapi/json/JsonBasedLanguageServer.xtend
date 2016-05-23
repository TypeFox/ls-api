/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import io.typefox.lsapi.CodeActionParams
import io.typefox.lsapi.CodeLens
import io.typefox.lsapi.CodeLensParams
import io.typefox.lsapi.Command
import io.typefox.lsapi.CompletionItem
import io.typefox.lsapi.DidChangeConfigurationParams
import io.typefox.lsapi.DidChangeTextDocumentParams
import io.typefox.lsapi.DidChangeWatchedFilesParams
import io.typefox.lsapi.DidCloseTextDocumentParams
import io.typefox.lsapi.DidOpenTextDocumentParams
import io.typefox.lsapi.DidSaveTextDocumentParams
import io.typefox.lsapi.DocumentFormattingParams
import io.typefox.lsapi.DocumentHighlight
import io.typefox.lsapi.DocumentOnTypeFormattingParams
import io.typefox.lsapi.DocumentRangeFormattingParams
import io.typefox.lsapi.DocumentSymbolParams
import io.typefox.lsapi.Hover
import io.typefox.lsapi.InitializeParams
import io.typefox.lsapi.InitializeResult
import io.typefox.lsapi.LanguageServer
import io.typefox.lsapi.Location
import io.typefox.lsapi.Message
import io.typefox.lsapi.MessageAcceptor
import io.typefox.lsapi.MessageParams
import io.typefox.lsapi.NotificationCallback
import io.typefox.lsapi.NotificationMessage
import io.typefox.lsapi.NotificationMessageImpl
import io.typefox.lsapi.PublishDiagnosticsParams
import io.typefox.lsapi.ReferenceParams
import io.typefox.lsapi.RenameParams
import io.typefox.lsapi.RequestMessageImpl
import io.typefox.lsapi.ResponseError
import io.typefox.lsapi.ResponseMessage
import io.typefox.lsapi.ShowMessageRequestParams
import io.typefox.lsapi.SignatureHelp
import io.typefox.lsapi.SymbolInformation
import io.typefox.lsapi.TextDocumentPositionParams
import io.typefox.lsapi.TextDocumentService
import io.typefox.lsapi.TextEdit
import io.typefox.lsapi.WindowService
import io.typefox.lsapi.WorkspaceEdit
import io.typefox.lsapi.WorkspaceService
import io.typefox.lsapi.WorkspaceSymbolParams
import java.io.InputStream
import java.io.OutputStream
import java.util.List
import java.util.Map
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

/**
 * A language server that delegates to an input and an output stream through the JSON-based protocol.
 */
class JsonBasedLanguageServer implements LanguageServer, MessageAcceptor {
	
	@Accessors(PUBLIC_GETTER)
	val textDocumentService = new TextDocumentServiceImpl(this)
	
	@Accessors(PUBLIC_GETTER)
	val windowService = new WindowServiceImpl(this)
	
	@Accessors(PUBLIC_GETTER)
	val workspaceService = new WorkspaceServiceImpl(this)
	
	val LanguageServerProtocol.InputListener inputListener
	
	val LanguageServerProtocol protocol
	
	val nextRequestId = new AtomicInteger
	
	val executorService = Executors.newCachedThreadPool
	
	val Map<String, ResponseReader> responseReaderMap = newHashMap
	
	val Multimap<String, Pair<Class<?>, NotificationCallback<?>>> notificationCallbackMap = HashMultimap.create
	
	new() {
		this(new MessageJsonHandler)
	}
	
	new(MessageJsonHandler jsonHandler) {
		jsonHandler.responseMethodResolver = [ id |
			synchronized (responseReaderMap) {
				responseReaderMap.get(id)?.method
			}
		]
		protocol = new LanguageServerProtocol(jsonHandler, this)
		inputListener = new LanguageServerProtocol.InputListener(protocol)
	}
	
	def void connect(InputStream input, OutputStream output) {
		if (inputListener.isActive)
			throw new IllegalStateException("Cannot connect after the communication has started.")
		protocol.output = output
		inputListener.input = input
	}
	
	override accept(Message message) {
		if (message instanceof ResponseMessage) {
			synchronized (responseReaderMap) {
				val reader = responseReaderMap.remove(message.id)
				if (reader !== null)
					reader.read(message)
				else
					protocol.logError("No matching request for response with id " + message.id, null)
			}
		} else if (message instanceof NotificationMessage) {
			val callbacks = synchronized (notificationCallbackMap) {
				notificationCallbackMap.get(message.method).filter[key.isInstance(message.params)].map[value].toList
			}
			for (callback : callbacks) {
				(callback as NotificationCallback<Object>).call(message.params)
			}
		}
	}
	
	protected def void sendRequest(String methodId, Object parameter) {
		val message = new RequestMessageImpl => [
			jsonrpc = LanguageServerProtocol.JSONRPC_VERSION
			id = Integer.toString(nextRequestId.getAndIncrement)
			method = methodId
			params = parameter
		]
		protocol.accept(message)
	}
	
	protected def <T> T waitForResult(String methodId, Object parameter, Class<T> resultType) {
		val requestId = Integer.toString(nextRequestId.getAndIncrement)
		val result = waitForResult(methodId, parameter, requestId)
		if (result instanceof ResponseError)
			throw new InvalidMessageException(result.message, requestId, result.code)
		else if (resultType.isInstance(result))
			return result as T
		else
			throw new InvalidMessageException("No valid response received from server.", requestId)
	}
	
	protected def <T> List<T> waitForListResult(String methodId, Object parameter, Class<T> resultType) {
		val requestId = Integer.toString(nextRequestId.getAndIncrement)
		val result = waitForResult(methodId, parameter, requestId)
		if (result instanceof ResponseError)
			throw new InvalidMessageException(result.message, requestId, result.code)
		else if (resultType.isInstance(result))
			return #[result as T]
		else if (result instanceof List<?> && (result as List<?>).forall[resultType.isInstance(it)])
			return result as List<T>
		else
			throw new InvalidMessageException("No valid response received from server.", requestId)
	}
	
	protected def Object waitForResult(String methodId, Object parameter, String requestId) {
		val message = new RequestMessageImpl => [
			jsonrpc = LanguageServerProtocol.JSONRPC_VERSION
			id = requestId
			method = methodId
			params = parameter
		]
		synchronized (inputListener) {
			if (!inputListener.active) {
				executorService.execute(inputListener)
			}
		}
		val responseReader = new ResponseReader(methodId)
		synchronized (responseReaderMap) {
			responseReaderMap.put(message.id, responseReader)
		}
		protocol.accept(message)
		val future = executorService.submit(responseReader)
		return future.get()
	}
	
	protected def sendNotification(String methodId, Object parameter) {
		val message = new NotificationMessageImpl => [
			jsonrpc = LanguageServerProtocol.JSONRPC_VERSION
			method = methodId
			params = parameter
		]
		protocol.accept(message)
	}
	
	protected def <T> void addCallback(String methodId, NotificationCallback<T> callback, Class<T> parameterType) {
		synchronized (notificationCallbackMap) {
			notificationCallbackMap.put(methodId, parameterType -> callback)
		}
	}
	
	override initialize(InitializeParams params) {
		waitForResult(MessageMethods.INITIALIZE, params, InitializeResult)
	}
	
	override shutdown() {
		try {
			sendRequest(MessageMethods.SHUTDOWN, null)
		} finally {
			executorService.shutdown()
		}
	}
	
	override exit() {
		try {
			sendRequest(MessageMethods.EXIT, null)
		} finally {
			executorService.shutdownNow()
			inputListener.stop()
			synchronized (responseReaderMap) {
				for (reader : responseReaderMap.values) {
					reader.stop()
				}
			}
		}
	}
	
	def onError((String, Throwable)=>void callback) {
		protocol.addErrorListener(callback)
	}
	
	@FinalFieldsConstructor
	private static class TextDocumentServiceImpl implements TextDocumentService {
		
		val JsonBasedLanguageServer server
		
		override completion(TextDocumentPositionParams position) {
			server.waitForListResult(MessageMethods.DOC_COMPLETION, position, CompletionItem)
		}
		
		override resolveCompletionItem(CompletionItem unresolved) {
			server.waitForResult(MessageMethods.RESOLVE_COMPLETION, unresolved, CompletionItem)
		}
		
		override hover(TextDocumentPositionParams position) {
			server.waitForResult(MessageMethods.DOC_HOVER, position, Hover)
		}
		
		override signatureHelp(TextDocumentPositionParams position) {
			server.waitForResult(MessageMethods.DOC_SIGNATURE_HELP, position, SignatureHelp)
		}
		
		override definition(TextDocumentPositionParams position) {
			server.waitForListResult(MessageMethods.DOC_DEFINITION, position, Location)
		}
		
		override references(ReferenceParams params) {
			server.waitForListResult(MessageMethods.DOC_REFERENCES, params, Location)
		}
		
		override documentHighlight(TextDocumentPositionParams position) {
			server.waitForResult(MessageMethods.DOC_HIGHLIGHT, position, DocumentHighlight)
		}
		
		override documentSymbol(DocumentSymbolParams params) {
			server.waitForListResult(MessageMethods.DOC_SYMBOL, params, SymbolInformation)
		}
		
		override codeAction(CodeActionParams params) {
			server.waitForListResult(MessageMethods.DOC_CODE_ACTION, params, Command)
		}
		
		override codeLens(CodeLensParams params) {
			server.waitForListResult(MessageMethods.DOC_CODE_LENS, params, CodeLens)
		}
		
		override resolveCodeLens(CodeLens unresolved) {
			server.waitForResult(MessageMethods.RESOLVE_CODE_LENS, unresolved, CodeLens)
		}
		
		override formatting(DocumentFormattingParams params) {
			server.waitForListResult(MessageMethods.DOC_FORMATTING, params, TextEdit)
		}
		
		override rangeFormatting(DocumentRangeFormattingParams params) {
			server.waitForListResult(MessageMethods.DOC_RANGE_FORMATTING, params, TextEdit)
		}
		
		override onTypeFormatting(DocumentOnTypeFormattingParams params) {
			server.waitForListResult(MessageMethods.DOC_TYPE_FORMATTING, params, TextEdit)
		}
		
		override rename(RenameParams params) {
			server.waitForResult(MessageMethods.DOC_RENAME, params, WorkspaceEdit)
		}
		
		override didOpen(DidOpenTextDocumentParams params) {
			server.sendNotification(MessageMethods.DID_OPEN_DOC, params)
		}
		
		override didChange(DidChangeTextDocumentParams params) {
			server.sendNotification(MessageMethods.DID_CHANGE_DOC, params)
		}
		
		override didClose(DidCloseTextDocumentParams params) {
			server.sendNotification(MessageMethods.DID_CLOSE_DOC, params)
		}
		
		override didSave(DidSaveTextDocumentParams params) {
			server.sendNotification(MessageMethods.DID_SAVE_DOC, params)
		}
		
		override onPublishDiagnostics(NotificationCallback<PublishDiagnosticsParams> callback) {
			server.addCallback(MessageMethods.SHOW_DIAGNOSTICS, callback, PublishDiagnosticsParams)
		}
		
	}
	
	@FinalFieldsConstructor
	private static class WindowServiceImpl implements WindowService {
		
		val JsonBasedLanguageServer server
		
		override onShowMessage(NotificationCallback<MessageParams> callback) {
			server.addCallback(MessageMethods.SHOW_MESSAGE, callback, MessageParams)
		}
		
		override onShowMessageRequest(NotificationCallback<ShowMessageRequestParams> callback) {
			server.addCallback(MessageMethods.SHOW_MESSAGE_REQUEST, callback, ShowMessageRequestParams)
		}
		
		override onLogMessage(NotificationCallback<MessageParams> callback) {
			server.addCallback(MessageMethods.LOG_MESSAGE, callback, MessageParams)
		}
		
	}
	
	@FinalFieldsConstructor
	private static class WorkspaceServiceImpl implements WorkspaceService {
		
		val JsonBasedLanguageServer server
		
		override symbol(WorkspaceSymbolParams params) {
			server.waitForListResult(MessageMethods.WORKSPACE_SYMBOL, params, SymbolInformation)
		}
		
		override didChangeConfiguraton(DidChangeConfigurationParams params) {
			server.sendNotification(MessageMethods.DID_CHANGE_CONF, params)
		}
		
		override didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
			server.sendNotification(MessageMethods.DID_CHANGE_FILES, params)
		}
		
	}
	
	@FinalFieldsConstructor
	private static class ResponseReader implements Callable<Object> {
		
		@Accessors
		val String method
		
		Object result
		
		override call() {
			synchronized (this) {
				while (result === null) {
					wait()
				}
				return result
			}
		}
		
		def void read(ResponseMessage message) {
			if (message.result !== null)
				result = message.result
			else if (message.error !== null)
				result = message.error
			else
				result = new Object
			synchronized (this) {
				notify()
			}
		}
		
		def void stop() {
			result = new Object
			synchronized (this) {
				notify()
			}
		}
		
	}
	
}