/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.transport.client

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
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
import io.typefox.lsapi.PublishDiagnosticsParams
import io.typefox.lsapi.ReferenceParams
import io.typefox.lsapi.RenameParams
import io.typefox.lsapi.ResponseError
import io.typefox.lsapi.ResponseMessage
import io.typefox.lsapi.ShowMessageRequestParams
import io.typefox.lsapi.SignatureHelp
import io.typefox.lsapi.SymbolInformation
import io.typefox.lsapi.TextDocumentPositionParams
import io.typefox.lsapi.TextEdit
import io.typefox.lsapi.WorkspaceEdit
import io.typefox.lsapi.WorkspaceSymbolParams
import io.typefox.lsapi.impl.CancelParamsImpl
import io.typefox.lsapi.services.LanguageServer
import io.typefox.lsapi.services.TextDocumentService
import io.typefox.lsapi.services.WindowService
import io.typefox.lsapi.services.WorkspaceService
import io.typefox.lsapi.services.transport.AbstractLanguageEndpoint
import io.typefox.lsapi.services.transport.InvalidMessageException
import io.typefox.lsapi.services.transport.trace.DelegatingMessageTracer
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

class LanguageClientEndpoint extends AbstractLanguageEndpoint implements LanguageServer, MethodResolver {

    @Accessors(PUBLIC_GETTER)
    val textDocumentService = new TextDocumentServiceImpl(this)

    @Accessors(PUBLIC_GETTER)
    val windowService = new WindowServiceImpl(this)

    @Accessors(PUBLIC_GETTER)
    val workspaceService = new WorkspaceServiceImpl(this)
    
    @Accessors(PROTECTED_GETTER)
    val nextRequestId = new AtomicInteger
    
    @Accessors(PROTECTED_GETTER)
    val Map<String, RequestHandler<?>> requestHandlerMap = newHashMap
    
    @Accessors(PROTECTED_GETTER)
    val Multimap<String, Pair<Class<?>, Consumer<?>>> notificationCallbackMap = HashMultimap.create
    
    new() {
        this(Executors.newCachedThreadPool)
    }
    
    new(ExecutorService executorService) {
        super(executorService)
    }
    
    override resolveMethod(String requestId) {
        synchronized (requestHandlerMap) {
            requestHandlerMap.get(requestId)?.method
        }
    }
    
    override accept(Message message) {
        if (message instanceof ResponseMessage) {
            synchronized (requestHandlerMap) {
                val handler = requestHandlerMap.remove(message.id)
                if (handler !== null)
                    handler.accept(message)
                else
                    logError("No matching request for response with id " + message.id, null)
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
    
    protected def <T> CompletableFuture<T> getPromise(String methodId, Object parameter, Class<T> resultType) {
        val requestId = nextRequestId()
        val handler = new RequestHandler<T>(methodId, requestId, parameter, resultType, this)
        synchronized (requestHandlerMap) {
            requestHandlerMap.put(requestId, handler)
        }
        val promise = CompletableFuture.supplyAsync(handler, executorService)
        promise.whenComplete[ result, throwable |
            if (promise.isCancelled) {
                handler.cancel()
                sendNotification(CANCEL, new CancelParamsImpl(requestId))
            }
        ]
        return promise
    }
    
    protected def String nextRequestId() {
        Integer.toString(nextRequestId.getAndIncrement)
    }
    
    protected def <T> CompletableFuture<List<? extends T>> getListPromise(String methodId, Object parameter, Class<T> resultType) {
        val messageId = Integer.toString(nextRequestId.getAndIncrement)
        val handler = new ListRequestHandler<T>(methodId, messageId, parameter, resultType, this)
        synchronized (requestHandlerMap) {
            requestHandlerMap.put(messageId, handler)
        }
        return CompletableFuture.supplyAsync(handler, executorService)
    }
    
    protected def <T> void addCallback(String methodId, Consumer<T> callback, Class<T> parameterType) {
        synchronized (notificationCallbackMap) {
            notificationCallbackMap.put(methodId, parameterType -> callback)
        }
    }
    
    override initialize(InitializeParams params) {
        getPromise(INITIALIZE, params, InitializeResult)
    }
    
    override shutdown() {
        try {
            sendRequest(SHUTDOWN, null)
        } finally {
            executorService.shutdown()
        }
    }
    
    override exit() {
        try {
            sendRequest(EXIT, null)
        } finally {
            close
            synchronized (requestHandlerMap) {
                for (handler : requestHandlerMap.values) {
                    handler.cancel()
                }
            }
        }
    }
    
    protected def sendRequest(String method, Object params) {
        val requestId = nextRequestId()
        sendRequest(requestId, method, params)
    }
    
    protected override sendRequest(String id, String method, Object params) {
        super.sendRequest(id, method, params)
    }
    
    protected override sendNotification(String method, Object params) {
        super.sendNotification(method, params)
    }
    
    override onTelemetryEvent(Consumer<Object> callback) {
        addCallback(TELEMETRY_EVENT, callback, Object)
    }
    
    @Deprecated
    def onError((String, Throwable)=>void callback) {
        messageTracer = new DelegatingMessageTracer(messageTracer) {
            
            override onError(String message, Throwable throwable) {
                callback.apply(message, throwable)
                delegate?.onError(message, throwable)
            }
            
        }
    }
    
    @FinalFieldsConstructor
    protected static class TextDocumentServiceImpl implements TextDocumentService {
        
        val LanguageClientEndpoint connection
        
        override completion(TextDocumentPositionParams position) {
            connection.getPromise(DOC_COMPLETION, position, CompletionList)
        }
        
        override resolveCompletionItem(CompletionItem unresolved) {
            connection.getPromise(RESOLVE_COMPLETION, unresolved, CompletionItem)
        }
        
        override hover(TextDocumentPositionParams position) {
            connection.getPromise(DOC_HOVER, position, Hover)
        }
        
        override signatureHelp(TextDocumentPositionParams position) {
            connection.getPromise(DOC_SIGNATURE_HELP, position, SignatureHelp)
        }
        
        override definition(TextDocumentPositionParams position) {
            connection.getListPromise(DOC_DEFINITION, position, Location)
        }
        
        override references(ReferenceParams params) {
            connection.getListPromise(DOC_REFERENCES, params, Location)
        }
        
        override documentHighlight(TextDocumentPositionParams position) {
            connection.getListPromise(DOC_HIGHLIGHT, position, DocumentHighlight)
        }
        
        override documentSymbol(DocumentSymbolParams params) {
            connection.getListPromise(DOC_SYMBOL, params, SymbolInformation)
        }
        
        override codeAction(CodeActionParams params) {
            connection.getListPromise(DOC_CODE_ACTION, params, Command)
        }
        
        override codeLens(CodeLensParams params) {
            connection.getListPromise(DOC_CODE_LENS, params, CodeLens)
        }
        
        override resolveCodeLens(CodeLens unresolved) {
            connection.getPromise(RESOLVE_CODE_LENS, unresolved, CodeLens)
        }
        
        override formatting(DocumentFormattingParams params) {
            connection.getListPromise(DOC_FORMATTING, params, TextEdit)
        }
        
        override rangeFormatting(DocumentRangeFormattingParams params) {
            connection.getListPromise(DOC_RANGE_FORMATTING, params, TextEdit)
        }
        
        override onTypeFormatting(DocumentOnTypeFormattingParams params) {
            connection.getListPromise(DOC_TYPE_FORMATTING, params, TextEdit)
        }
        
        override rename(RenameParams params) {
            connection.getPromise(DOC_RENAME, params, WorkspaceEdit)
        }
        
        override didOpen(DidOpenTextDocumentParams params) {
            connection.sendNotification(DID_OPEN_DOC, params)
        }
        
        override didChange(DidChangeTextDocumentParams params) {
            connection.sendNotification(DID_CHANGE_DOC, params)
        }
        
        override didClose(DidCloseTextDocumentParams params) {
            connection.sendNotification(DID_CLOSE_DOC, params)
        }
        
        override didSave(DidSaveTextDocumentParams params) {
            connection.sendNotification(DID_SAVE_DOC, params)
        }
        
        override onPublishDiagnostics(Consumer<PublishDiagnosticsParams> callback) {
            connection.addCallback(SHOW_DIAGNOSTICS, callback, PublishDiagnosticsParams)
        }
        
    }
    
    @FinalFieldsConstructor
    protected static class WindowServiceImpl implements WindowService {
        
        val LanguageClientEndpoint connection
        
        override onShowMessage(Consumer<MessageParams> callback) {
            connection.addCallback(SHOW_MESSAGE, callback, MessageParams)
        }
        
        override onShowMessageRequest(Consumer<ShowMessageRequestParams> callback) {
            connection.addCallback(SHOW_MESSAGE_REQUEST, callback, ShowMessageRequestParams)
        }
        
        override onLogMessage(Consumer<MessageParams> callback) {
            connection.addCallback(LOG_MESSAGE, callback, MessageParams)
        }
        
    }
    
    @FinalFieldsConstructor
    protected static class WorkspaceServiceImpl implements WorkspaceService {
        
        val LanguageClientEndpoint connection
        
        override symbol(WorkspaceSymbolParams params) {
            connection.getListPromise(WORKSPACE_SYMBOL, params, SymbolInformation)
        }
        
        override didChangeConfiguration(DidChangeConfigurationParams params) {
            connection.sendNotification(DID_CHANGE_CONF, params)
        }
        
        override didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
            connection.sendNotification(DID_CHANGE_FILES, params)
        }
        
    }
    
    @FinalFieldsConstructor
    protected static class RequestHandler<T> implements Supplier<T> {
        
        @Accessors
        val String method
        
        @Accessors
        val String requestId
        
        val Object params
        
        @Accessors(PROTECTED_GETTER)
        val Class<?> resultType
        
        val LanguageClientEndpoint connection
        
        @Accessors(PROTECTED_GETTER)
        Object result
        
        override get() {
            connection.sendRequest(requestId, method, params)
            synchronized (this) {
                while (result === null) {
                    wait()
                }
            }
            return convertResult()
        }
        
        protected def <T> convertResult() {
            if (result instanceof ResponseError)
                throw new InvalidMessageException(result.message, requestId, result.code)
            else if (resultType.isInstance(result))
                return result as T
            else if (!(result instanceof CancellationException))
                throw new InvalidMessageException("No valid response received from server.", requestId)
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
                throw new InvalidMessageException(result.message, getRequestId, result.code)
            else if (resultType.isInstance(result))
                return #[result as T]
            else if (result instanceof List<?> && (result as List<?>).forall[resultType.isInstance(it)])
                return result as List<T>
            else if (!(result instanceof CancellationException))
                throw new InvalidMessageException("No valid response received from server.", getRequestId)
        }
        
    }
    
}