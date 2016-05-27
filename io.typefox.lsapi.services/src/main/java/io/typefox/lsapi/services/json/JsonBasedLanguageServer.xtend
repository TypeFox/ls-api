/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import io.typefox.lsapi.CancelParamsImpl
import io.typefox.lsapi.CodeActionParams
import io.typefox.lsapi.CodeLens
import io.typefox.lsapi.CodeLensParams
import io.typefox.lsapi.Command
import io.typefox.lsapi.CompletionItem
import io.typefox.lsapi.CompletionList
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
import io.typefox.lsapi.Location
import io.typefox.lsapi.Message
import io.typefox.lsapi.MessageParams
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
import io.typefox.lsapi.TextEdit
import io.typefox.lsapi.WorkspaceEdit
import io.typefox.lsapi.WorkspaceSymbolParams
import io.typefox.lsapi.services.LanguageServer
import io.typefox.lsapi.services.MessageAcceptor
import io.typefox.lsapi.services.TextDocumentService
import io.typefox.lsapi.services.WindowService
import io.typefox.lsapi.services.WorkspaceService
import java.io.InputStream
import java.io.OutputStream
import java.util.List
import java.util.Map
import java.util.concurrent.CancellationException
import java.util.concurrent.CompletableFuture
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import java.util.function.Consumer
import java.util.function.Supplier
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
	
	@Accessors(PROTECTED_GETTER)
	val LanguageServerProtocol protocol
	
	val ExecutorService executorService
	
	val nextRequestId = new AtomicInteger
	
	val Map<String, RequestHandler<?>> requestHandlerMap = newHashMap
	
	val Multimap<String, Pair<Class<?>, Consumer<?>>> notificationCallbackMap = HashMultimap.create
	
	new() {
		this(new MessageJsonHandler)
	}
	
	new(MessageJsonHandler jsonHandler) {
		this(jsonHandler, Executors.newCachedThreadPool)
	}
	
	new(MessageJsonHandler jsonHandler, ExecutorService executorService) {
		this.executorService = executorService
		jsonHandler.responseMethodResolver = [ id |
			synchronized (requestHandlerMap) {
				requestHandlerMap.get(id)?.methodId
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
	
	protected def void ensureInputListener() {
		synchronized (inputListener) {
			if (!inputListener.active) {
				executorService.execute(inputListener)
			}
		}
	}
	
	override accept(Message message) {
		if (message instanceof ResponseMessage) {
			synchronized (requestHandlerMap) {
				val handler = requestHandlerMap.remove(message.id)
				if (handler !== null)
					handler.accept(message)
				else
					protocol.logError("No matching request for response with id " + message.id, null)
			}
		} else if (message instanceof NotificationMessage) {
			val callbacks = synchronized (notificationCallbackMap) {
				notificationCallbackMap.get(message.method).filter[key.isInstance(message.params)].map[value].toList
			}
			for (callback : callbacks) {
				(callback as Consumer<Object>).accept(message.params)
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
	
	protected def <T> CompletableFuture<T> getPromise(String methodId, Object parameter, Class<T> resultType) {
		val messageId = Integer.toString(nextRequestId.getAndIncrement)
		val handler = new RequestHandler<T>(methodId, messageId, parameter, resultType, this)
		synchronized (requestHandlerMap) {
			requestHandlerMap.put(messageId, handler)
		}
		val promise = CompletableFuture.supplyAsync(handler, executorService)
		promise.whenComplete[ result, throwable |
			if (promise.isCancelled) {
				handler.cancel()
				sendNotification(MessageMethods.CANCEL, new CancelParamsImpl => [id = messageId])
			}
		]
		return promise
	}
	
	protected def <T> CompletableFuture<List<? extends T>> getListPromise(String methodId, Object parameter, Class<T> resultType) {
		val messageId = Integer.toString(nextRequestId.getAndIncrement)
		val handler = new ListRequestHandler<T>(methodId, messageId, parameter, resultType, this)
		synchronized (requestHandlerMap) {
			requestHandlerMap.put(messageId, handler)
		}
		return CompletableFuture.supplyAsync(handler, executorService)
	}
	
	protected def sendNotification(String methodId, Object parameter) {
		val message = new NotificationMessageImpl => [
			jsonrpc = LanguageServerProtocol.JSONRPC_VERSION
			method = methodId
			params = parameter
		]
		protocol.accept(message)
	}
	
	protected def <T> void addCallback(String methodId, Consumer<T> callback, Class<T> parameterType) {
		synchronized (notificationCallbackMap) {
			notificationCallbackMap.put(methodId, parameterType -> callback)
		}
	}
	
	override initialize(InitializeParams params) {
		getPromise(MessageMethods.INITIALIZE, params, InitializeResult)
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
			synchronized (requestHandlerMap) {
				for (handler : requestHandlerMap.values) {
					handler.cancel()
				}
			}
		}
	}
	
	def onError((String, Throwable)=>void callback) {
		protocol.addErrorListener(callback)
	}
	
	@FinalFieldsConstructor
	protected static class TextDocumentServiceImpl implements TextDocumentService {
		
		val JsonBasedLanguageServer server
		
		override completion(TextDocumentPositionParams position) {
			server.getPromise(MessageMethods.DOC_COMPLETION, position, CompletionList)
		}
		
		override resolveCompletionItem(CompletionItem unresolved) {
			server.getPromise(MessageMethods.RESOLVE_COMPLETION, unresolved, CompletionItem)
		}
		
		override hover(TextDocumentPositionParams position) {
			server.getPromise(MessageMethods.DOC_HOVER, position, Hover)
		}
		
		override signatureHelp(TextDocumentPositionParams position) {
			server.getPromise(MessageMethods.DOC_SIGNATURE_HELP, position, SignatureHelp)
		}
		
		override definition(TextDocumentPositionParams position) {
			server.getListPromise(MessageMethods.DOC_DEFINITION, position, Location)
		}
		
		override references(ReferenceParams params) {
			server.getListPromise(MessageMethods.DOC_REFERENCES, params, Location)
		}
		
		override documentHighlight(TextDocumentPositionParams position) {
			server.getPromise(MessageMethods.DOC_HIGHLIGHT, position, DocumentHighlight)
		}
		
		override documentSymbol(DocumentSymbolParams params) {
			server.getListPromise(MessageMethods.DOC_SYMBOL, params, SymbolInformation)
		}
		
		override codeAction(CodeActionParams params) {
			server.getListPromise(MessageMethods.DOC_CODE_ACTION, params, Command)
		}
		
		override codeLens(CodeLensParams params) {
			server.getListPromise(MessageMethods.DOC_CODE_LENS, params, CodeLens)
		}
		
		override resolveCodeLens(CodeLens unresolved) {
			server.getPromise(MessageMethods.RESOLVE_CODE_LENS, unresolved, CodeLens)
		}
		
		override formatting(DocumentFormattingParams params) {
			server.getListPromise(MessageMethods.DOC_FORMATTING, params, TextEdit)
		}
		
		override rangeFormatting(DocumentRangeFormattingParams params) {
			server.getListPromise(MessageMethods.DOC_RANGE_FORMATTING, params, TextEdit)
		}
		
		override onTypeFormatting(DocumentOnTypeFormattingParams params) {
			server.getListPromise(MessageMethods.DOC_TYPE_FORMATTING, params, TextEdit)
		}
		
		override rename(RenameParams params) {
			server.getPromise(MessageMethods.DOC_RENAME, params, WorkspaceEdit)
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
		
		override onPublishDiagnostics(Consumer<PublishDiagnosticsParams> callback) {
			server.addCallback(MessageMethods.SHOW_DIAGNOSTICS, callback, PublishDiagnosticsParams)
		}
		
	}
	
	@FinalFieldsConstructor
	protected static class WindowServiceImpl implements WindowService {
		
		val JsonBasedLanguageServer server
		
		override onShowMessage(Consumer<MessageParams> callback) {
			server.addCallback(MessageMethods.SHOW_MESSAGE, callback, MessageParams)
		}
		
		override onShowMessageRequest(Consumer<ShowMessageRequestParams> callback) {
			server.addCallback(MessageMethods.SHOW_MESSAGE_REQUEST, callback, ShowMessageRequestParams)
		}
		
		override onLogMessage(Consumer<MessageParams> callback) {
			server.addCallback(MessageMethods.LOG_MESSAGE, callback, MessageParams)
		}
		
	}
	
	@FinalFieldsConstructor
	protected static class WorkspaceServiceImpl implements WorkspaceService {
		
		val JsonBasedLanguageServer server
		
		override symbol(WorkspaceSymbolParams params) {
			server.getListPromise(MessageMethods.WORKSPACE_SYMBOL, params, SymbolInformation)
		}
		
		override didChangeConfiguraton(DidChangeConfigurationParams params) {
			server.sendNotification(MessageMethods.DID_CHANGE_CONF, params)
		}
		
		override didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
			server.sendNotification(MessageMethods.DID_CHANGE_FILES, params)
		}
		
	}
	
	@FinalFieldsConstructor
	protected static class RequestHandler<T> implements Supplier<T> {
		
		@Accessors
		val String methodId
		
		@Accessors(PROTECTED_GETTER)
		val String messageId
		
		val Object parameter
		
		@Accessors(PROTECTED_GETTER)
		val Class<?> resultType
		
		val JsonBasedLanguageServer server
		
		@Accessors(PROTECTED_GETTER)
		Object result
		
		override get() {
			val message = new RequestMessageImpl => [
				jsonrpc = LanguageServerProtocol.JSONRPC_VERSION
				id = messageId
				method = methodId
				params = parameter
			]
			server.ensureInputListener()
			server.protocol.accept(message)
			synchronized (this) {
				while (result === null) {
					wait()
				}
			}
			return convertResult()
		}
		
		protected def <T> convertResult() {
			if (result instanceof ResponseError)
				throw new InvalidMessageException(result.message, messageId, result.code)
			else if (resultType.isInstance(result))
				return result as T
			else if (!(result instanceof CancellationException))
				throw new InvalidMessageException("No valid response received from server.", messageId)
		}
		
		def void accept(ResponseMessage message) {
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
		
		def void cancel() {
			result = new CancellationException
			synchronized (this) {
				notify()
			}
		}
		
	}
	
	@FinalFieldsConstructor
	protected static class ListRequestHandler<T> extends RequestHandler<List<? extends T>> {
		
		override protected List<? extends T> convertResult() {
			val result = getResult
			val resultType = getResultType
			if (result instanceof ResponseError)
				throw new InvalidMessageException(result.message, getMessageId, result.code)
			else if (resultType.isInstance(result))
				return #[result as T]
			else if (result instanceof List<?> && (result as List<?>).forall[resultType.isInstance(it)])
				return result as List<T>
			else if (!(result instanceof CancellationException))
				throw new InvalidMessageException("No valid response received from server.", getMessageId)
		}
		
	}
	
}