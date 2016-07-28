/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Supplier;

import org.eclipse.xtext.xbase.lib.Exceptions;
import org.eclipse.xtext.xbase.lib.Pair;

import com.google.common.collect.HashMultimap;
import com.google.common.collect.Iterables;
import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import com.google.common.collect.Multimap;

import io.typefox.lsapi.CodeActionParams;
import io.typefox.lsapi.CodeLens;
import io.typefox.lsapi.CodeLensParams;
import io.typefox.lsapi.Command;
import io.typefox.lsapi.CompletionItem;
import io.typefox.lsapi.CompletionList;
import io.typefox.lsapi.DidChangeConfigurationParams;
import io.typefox.lsapi.DidChangeTextDocumentParams;
import io.typefox.lsapi.DidChangeWatchedFilesParams;
import io.typefox.lsapi.DidCloseTextDocumentParams;
import io.typefox.lsapi.DidOpenTextDocumentParams;
import io.typefox.lsapi.DidSaveTextDocumentParams;
import io.typefox.lsapi.DocumentFormattingParams;
import io.typefox.lsapi.DocumentHighlight;
import io.typefox.lsapi.DocumentOnTypeFormattingParams;
import io.typefox.lsapi.DocumentRangeFormattingParams;
import io.typefox.lsapi.DocumentSymbolParams;
import io.typefox.lsapi.Hover;
import io.typefox.lsapi.InitializeParams;
import io.typefox.lsapi.InitializeResult;
import io.typefox.lsapi.Location;
import io.typefox.lsapi.Message;
import io.typefox.lsapi.MessageParams;
import io.typefox.lsapi.NotificationMessage;
import io.typefox.lsapi.PublishDiagnosticsParams;
import io.typefox.lsapi.ReferenceParams;
import io.typefox.lsapi.RenameParams;
import io.typefox.lsapi.ResponseError;
import io.typefox.lsapi.ResponseMessage;
import io.typefox.lsapi.ShowMessageRequestParams;
import io.typefox.lsapi.SignatureHelp;
import io.typefox.lsapi.SymbolInformation;
import io.typefox.lsapi.TextDocumentPositionParams;
import io.typefox.lsapi.TextEdit;
import io.typefox.lsapi.WorkspaceEdit;
import io.typefox.lsapi.WorkspaceSymbolParams;
import io.typefox.lsapi.impl.CancelParamsImpl;
import io.typefox.lsapi.impl.NotificationMessageImpl;
import io.typefox.lsapi.impl.RequestMessageImpl;
import io.typefox.lsapi.services.LanguageServer;
import io.typefox.lsapi.services.TextDocumentService;
import io.typefox.lsapi.services.WindowService;
import io.typefox.lsapi.services.WorkspaceService;

/**
 * A language server that delegates to an input and an output stream through the JSON-based protocol.
 */
class JsonBasedLanguageServer extends AbstractJsonBasedServer implements LanguageServer, Consumer<Message> {
	
	private final TextDocumentServiceImpl textDocumentService = new TextDocumentServiceImpl();
	
	private final WindowServiceImpl windowService = new WindowServiceImpl();
	
	private final WorkspaceServiceImpl workspaceService = new WorkspaceServiceImpl();
	
	private final AtomicInteger nextRequestId = new AtomicInteger();
	
	private final Map<String, RequestHandler<?>> requestHandlerMap = Maps.newHashMap();
	
	private final Multimap<String, Pair<Class<?>, Consumer<?>>> notificationCallbackMap = HashMultimap.create();
	
	public JsonBasedLanguageServer() {
		this(new MessageJsonHandler());
	}
	
	public JsonBasedLanguageServer(MessageJsonHandler jsonHandler) {
		this(jsonHandler, Executors.newCachedThreadPool());
	}
	
	public JsonBasedLanguageServer(MessageJsonHandler jsonHandler, ExecutorService executorService) {
		super(executorService);
		jsonHandler.setResponseMethodResolver(id -> {
			synchronized (requestHandlerMap) {
				RequestHandler<?> requestHandler = requestHandlerMap.get(id);
				if (requestHandler != null)
					return requestHandler.getMethodId();
				else
					return null;
			}
		});
		setProtocol(createProtocol(jsonHandler));
	}
	
	public TextDocumentService getTextDocumentService() {
		return textDocumentService;
	}
	
	public WindowService getWindowService() {
		return windowService;
	}
	
	public WorkspaceService getWorkspaceService() {
		return workspaceService;
	}
	
	protected LanguageServerProtocol createProtocol(MessageJsonHandler jsonHandler) {
		return new LanguageServerProtocol(jsonHandler, this);
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public void accept(Message message) {
		if (message instanceof ResponseMessage) {
			ResponseMessage responseMessage = (ResponseMessage) message;
			synchronized (requestHandlerMap) {
				RequestHandler<?> handler = requestHandlerMap.remove(responseMessage.getId());
				if (handler != null)
					handler.accept(responseMessage);
				else
					getProtocol().logError("No matching request for response with id " + responseMessage.getId(), null);
			}
		} else if (message instanceof NotificationMessage) {
			NotificationMessage notificationMessage = (NotificationMessage) message;
			Object params = notificationMessage.getParams();
			List<Consumer<?>> callbacks = Lists.newArrayList();
			synchronized (notificationCallbackMap) {
				for (Pair<Class<?>, Consumer<?>> pair : notificationCallbackMap.get(notificationMessage.getMethod())) {
					if (pair.getKey().isInstance(params))
						callbacks.add(pair.getValue());
				}
			}
			for (Consumer<?> callback : callbacks) {
				((Consumer<Object>) callback).accept(params);
			}
		}
	}
	
	protected void sendRequest(String methodId, Object parameter) {
		RequestMessageImpl message = new RequestMessageImpl();
		message.setJsonrpc(LanguageServerProtocol.JSONRPC_VERSION);
		message.setId(Integer.toString(nextRequestId.getAndIncrement()));
		message.setMethod(methodId);
		message.setParams(parameter);
		getProtocol().accept(message);
	}
	
	protected <T> CompletableFuture<T> getPromise(String methodId, Object parameter, Class<T> resultType) {
		String messageId = Integer.toString(nextRequestId.getAndIncrement());
		RequestHandler<T> handler = new RequestHandler<T>(methodId, messageId, parameter, resultType);
		synchronized (requestHandlerMap) {
			requestHandlerMap.put(messageId, handler);
		}
		CompletableFuture<T> promise = CompletableFuture.supplyAsync(handler, getExecutorService());
		promise.whenComplete((result, throwable) -> {
			if (promise.isCancelled()) {
				handler.cancel();
				sendNotification(MessageMethods.CANCEL, new CancelParamsImpl(messageId));
			}
		});
		return promise;
	}
	
	protected <T> CompletableFuture<List<? extends T>> getListPromise(String methodId, Object parameter, Class<T> resultType) {
		String messageId = Integer.toString(nextRequestId.getAndIncrement());
		ListRequestHandler<T> handler = new ListRequestHandler<T>(methodId, messageId, parameter, resultType);
		synchronized (requestHandlerMap) {
			requestHandlerMap.put(messageId, handler);
		}
		CompletableFuture<List<? extends T>> promise = CompletableFuture.supplyAsync(handler, getExecutorService());
		promise.whenComplete((result, throwable) -> {
			if (promise.isCancelled()) {
				handler.cancel();
				sendNotification(MessageMethods.CANCEL, new CancelParamsImpl(messageId));
			}
		});
		return promise;
	}
	
	protected void sendNotification(String methodId, Object parameter) {
		NotificationMessageImpl message = new NotificationMessageImpl();
		message.setJsonrpc(LanguageServerProtocol.JSONRPC_VERSION);
		message.setMethod(methodId);
		message.setParams(parameter);
		getProtocol().accept(message);
	}
	
	protected <T> void addCallback(String methodId, Consumer<T> callback, Class<T> parameterType) {
		synchronized (notificationCallbackMap) {
			notificationCallbackMap.put(methodId, Pair.of(parameterType, callback));
		}
	}
	
	@Override
	public CompletableFuture<InitializeResult> initialize(InitializeParams params) {
		return getPromise(MessageMethods.INITIALIZE, params, InitializeResult.class);
	}
	
	@Override
	public void shutdown() {
		try {
			sendRequest(MessageMethods.SHUTDOWN, null);
		} finally {
			getExecutorService().shutdown();
		}
	}
	
	@Override
	public void exit() {
		try {
			sendRequest(MessageMethods.EXIT, null);
		} finally {
			getExecutorService().shutdownNow();
			synchronized (requestHandlerMap) {
				for (RequestHandler<?> handler : requestHandlerMap.values()) {
					handler.cancel();
				}
			}
			super.exit();
		}
	}
	
	@Override
	public void onTelemetryEvent(Consumer<Object> callback) {
		addCallback(MessageMethods.TELEMETRY_EVENT, callback, Object.class);
	}
	
	public void onError(BiConsumer<String, Throwable> callback) {
		getProtocol().addErrorListener(callback);
	}
	
	protected class TextDocumentServiceImpl implements TextDocumentService {
		
		@Override
		public CompletableFuture<CompletionList> completion(TextDocumentPositionParams position) {
			return getPromise(MessageMethods.DOC_COMPLETION, position, CompletionList.class);
		}
		
		@Override
		public CompletableFuture<CompletionItem> resolveCompletionItem(CompletionItem unresolved) {
			return getPromise(MessageMethods.RESOLVE_COMPLETION, unresolved, CompletionItem.class);
		}
		
		@Override
		public CompletableFuture<Hover> hover(TextDocumentPositionParams position) {
			return getPromise(MessageMethods.DOC_HOVER, position, Hover.class);
		}
		
		@Override
		public CompletableFuture<SignatureHelp> signatureHelp(TextDocumentPositionParams position) {
			return getPromise(MessageMethods.DOC_SIGNATURE_HELP, position, SignatureHelp.class);
		}
		
		@Override
		public CompletableFuture<List<? extends Location>> definition(TextDocumentPositionParams position) {
			return getListPromise(MessageMethods.DOC_DEFINITION, position, Location.class);
		}
		
		@Override
		public CompletableFuture<List<? extends Location>> references(ReferenceParams params) {
			return getListPromise(MessageMethods.DOC_REFERENCES, params, Location.class);
		}
		
		@Override
		public CompletableFuture<DocumentHighlight> documentHighlight(TextDocumentPositionParams position) {
			return getPromise(MessageMethods.DOC_HIGHLIGHT, position, DocumentHighlight.class);
		}
		
		@Override
		public CompletableFuture<List<? extends SymbolInformation>> documentSymbol(DocumentSymbolParams params) {
			return getListPromise(MessageMethods.DOC_SYMBOL, params, SymbolInformation.class);
		}
		
		@Override
		public CompletableFuture<List<? extends Command>> codeAction(CodeActionParams params) {
			return getListPromise(MessageMethods.DOC_CODE_ACTION, params, Command.class);
		}
		
		@Override
		public CompletableFuture<List<? extends CodeLens>> codeLens(CodeLensParams params) {
			return getListPromise(MessageMethods.DOC_CODE_LENS, params, CodeLens.class);
		}
		
		@Override
		public CompletableFuture<CodeLens> resolveCodeLens(CodeLens unresolved) {
			return getPromise(MessageMethods.RESOLVE_CODE_LENS, unresolved, CodeLens.class);
		}
		
		@Override
		public CompletableFuture<List<? extends TextEdit>> formatting(DocumentFormattingParams params) {
			return getListPromise(MessageMethods.DOC_FORMATTING, params, TextEdit.class);
		}
		
		@Override
		public CompletableFuture<List<? extends TextEdit>> rangeFormatting(DocumentRangeFormattingParams params) {
			return getListPromise(MessageMethods.DOC_RANGE_FORMATTING, params, TextEdit.class);
		}
		
		@Override
		public CompletableFuture<List<? extends TextEdit>> onTypeFormatting(DocumentOnTypeFormattingParams params) {
			return getListPromise(MessageMethods.DOC_TYPE_FORMATTING, params, TextEdit.class);
		}
		
		@Override
		public CompletableFuture<WorkspaceEdit> rename(RenameParams params) {
			return getPromise(MessageMethods.DOC_RENAME, params, WorkspaceEdit.class);
		}
		
		@Override
		public void didOpen(DidOpenTextDocumentParams params) {
			sendNotification(MessageMethods.DID_OPEN_DOC, params);
		}
		
		@Override
		public void didChange(DidChangeTextDocumentParams params) {
			sendNotification(MessageMethods.DID_CHANGE_DOC, params);
		}
		
		@Override
		public void didClose(DidCloseTextDocumentParams params) {
			sendNotification(MessageMethods.DID_CLOSE_DOC, params);
		}
		
		@Override
		public void didSave(DidSaveTextDocumentParams params) {
			sendNotification(MessageMethods.DID_SAVE_DOC, params);
		}
		
		@Override
		public void onPublishDiagnostics(Consumer<PublishDiagnosticsParams> callback) {
			addCallback(MessageMethods.SHOW_DIAGNOSTICS, callback, PublishDiagnosticsParams.class);
		}
		
	}
	
	protected class WindowServiceImpl implements WindowService {
		
		@Override
		public void onShowMessage(Consumer<MessageParams> callback) {
			addCallback(MessageMethods.SHOW_MESSAGE, callback, MessageParams.class);
		}
		
		@Override
		public void onShowMessageRequest(Consumer<ShowMessageRequestParams> callback) {
			addCallback(MessageMethods.SHOW_MESSAGE_REQUEST, callback, ShowMessageRequestParams.class);
		}
		
		@Override
		public void onLogMessage(Consumer<MessageParams> callback) {
			addCallback(MessageMethods.LOG_MESSAGE, callback, MessageParams.class);
		}
		
	}
	
	protected class WorkspaceServiceImpl implements WorkspaceService {
		
		@Override
		public CompletableFuture<List<? extends SymbolInformation>>  symbol(WorkspaceSymbolParams params) {
			return getListPromise(MessageMethods.WORKSPACE_SYMBOL, params, SymbolInformation.class);
		}
		
		@Override
		public void didChangeConfiguraton(DidChangeConfigurationParams params) {
			sendNotification(MessageMethods.DID_CHANGE_CONF, params);
		}
		
		@Override
		public void didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
			sendNotification(MessageMethods.DID_CHANGE_FILES, params);
		}
		
	}
	
	protected class RequestHandler<T> implements Supplier<T> {
		
		private final String methodId;
		
		private final String messageId;
		
		private final Object parameter;
		
		private final Class<?> resultType;
		
		private Object result;
		
		public RequestHandler(String methodId, String messageId, Object parameter, Class<?> resultType) {
			this.methodId = methodId;
			this.messageId = messageId;
			this.parameter = parameter;
			this.resultType = resultType;
		}
		
		public String getMethodId() {
			return methodId;
		}
		
		public String getMessageId() {
			return messageId;
		}
		
		public Class<?> getResultType() {
			return resultType;
		}
		
		public Object getResult() {
			return result;
		}
		
		@Override
		public T get() {
			RequestMessageImpl message = new RequestMessageImpl();
			message.setJsonrpc(LanguageServerProtocol.JSONRPC_VERSION);
			message.setId(messageId);
			message.setMethod(methodId);
			message.setParams(parameter);
			getProtocol().accept(message);
			try {
				synchronized (this) {
					while (result == null) {
						wait();
					}
				}
			} catch (InterruptedException e) {
				Exceptions.sneakyThrow(e);
			}
			return convertResult();
		}
		
		@SuppressWarnings("unchecked")
		protected T convertResult() {
			if (result instanceof ResponseError) {
				ResponseError error = (ResponseError) result;
				throw new InvalidMessageException(error.getMessage(), messageId, error.getCode());
			} else if (resultType.isInstance(result))
				return (T) result;
			else if (!(result instanceof CancellationException))
				throw new InvalidMessageException("No valid response received from server.", messageId);
			else
				return null;
		}
		
		public void accept(ResponseMessage message) {
			if (message.getResult() != null)
				result = message.getResult();
			else if (message.getError() != null)
				result = message.getError();
			else
				result = new Object();
			synchronized (this) {
				notify();
			}
		}
		
		public void cancel() {
			result = new CancellationException();
			synchronized (this) {
				notify();
			}
		}
		
	}
	
	protected class ListRequestHandler<T> extends RequestHandler<List<? extends T>> {
		
		public ListRequestHandler(String methodId, String messageId, Object parameter, Class<?> resultType) {
			super(methodId, messageId, parameter, resultType);
		}
		
		@SuppressWarnings("unchecked")
		@Override
		protected List<? extends T> convertResult() {
			Object result = getResult();
			Class<?> resultType = getResultType();
			if (result instanceof ResponseError) {
				ResponseError error = (ResponseError) result;
				throw new InvalidMessageException(error.getMessage(), getMessageId(), error.getCode());
			} else if (resultType.isInstance(result))
				return Collections.singletonList((T) result);
			else if (result instanceof List<?> && Iterables.all((List<?>) result,
					(Object it) -> getResultType().isInstance(it)))
				return (List<T>) result;
			else if (!(result instanceof CancellationException))
				throw new InvalidMessageException("No valid response received from server.", getMessageId());
			else
				return null;
		}
		
	}
	
}