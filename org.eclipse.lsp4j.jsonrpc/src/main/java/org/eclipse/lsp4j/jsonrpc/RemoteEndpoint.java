/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.lsp4j.jsonrpc;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.logging.Logger;

import org.eclipse.lsp4j.jsonrpc.json.MessageConstants;
import org.eclipse.lsp4j.jsonrpc.json.MethodProvider;
import org.eclipse.lsp4j.jsonrpc.messages.Message;
import org.eclipse.lsp4j.jsonrpc.messages.NotificationMessage;
import org.eclipse.lsp4j.jsonrpc.messages.RequestMessage;
import org.eclipse.lsp4j.jsonrpc.messages.ResponseError;
import org.eclipse.lsp4j.jsonrpc.messages.ResponseErrorCode;
import org.eclipse.lsp4j.jsonrpc.messages.ResponseMessage;

/**
 * An {@link Endpoint} that can be connected to a {@link MessageConsumer} and {@link MessageProducer}.
 * It handles the translation from {@link Message} objects to calls on {@link Endpoint}.
 */
public class RemoteEndpoint implements Endpoint, MessageConsumer, MethodProvider {

	private final static String CANCEL_METHOD = "$/cancel";
	private static final Logger LOG = Logger.getLogger(RemoteEndpoint.class.getName());
	
	private final MessageConsumer out;
	private final Endpoint localEndpoint;
	private final Function<Throwable, ResponseError> exceptionHandler;
	
	private final AtomicInteger nextRequestId = new AtomicInteger();
	private final Map<String, PendingRequestInfo> sentRequestMap = new LinkedHashMap<>();
	private final Map<String, CompletableFuture<?>> receivedRequestMap = new LinkedHashMap<>();
	
	private static class PendingRequestInfo {
		PendingRequestInfo(RequestMessage requestMessage2, Consumer<ResponseMessage> responseHandler2) {
			this.requestMessage = requestMessage2;
			this.responseHandler = responseHandler2;
		}
		RequestMessage requestMessage;
		Consumer<ResponseMessage> responseHandler;
	}
	
	public RemoteEndpoint(MessageConsumer out, Endpoint localEndpoint, Function<Throwable, ResponseError> exceptionHandler) {
		if (out == null)
			throw new NullPointerException("out");
		if (localEndpoint == null)
			throw new NullPointerException("localEndpoint");
		if (exceptionHandler == null)
			throw new NullPointerException("exceptionHandler");
		this.out = out;
		this.localEndpoint = localEndpoint;
		this.exceptionHandler = exceptionHandler;
	}
	
	public RemoteEndpoint(MessageConsumer out, Endpoint localEndpoint) {
		this(out, localEndpoint, (throwable) -> {
			ResponseError error = new ResponseError();
			error.setMessage(throwable.getMessage());
			error.setCode(ResponseErrorCode.InternalError);
			return error;
		});
	}

	@Override
	public void notify(String method, Object parameter) {
		NotificationMessage notificationMessage = new NotificationMessage();
		notificationMessage.setJsonrpc(MessageConstants.JSONRPC_VERSION);
		notificationMessage.setMethod(method);
		notificationMessage.setParams(parameter);
		out.consume(notificationMessage);
	}

	@Override
	public CompletableFuture<Object> request(String method, Object parameter) {
		RequestMessage requestMessage = new RequestMessage();
		final String id = String.valueOf(nextRequestId.incrementAndGet());
		requestMessage.setId(id);
		requestMessage.setMethod(method);
		requestMessage.setParams(parameter);
		final CompletableFuture<Object> result = new CompletableFuture<Object>() {
			@Override
			public boolean cancel(boolean mayInterruptIfRunning) {
				sendCancelNotification(id);
				return super.cancel(mayInterruptIfRunning);
			}
		};
		Consumer<ResponseMessage> responseHandler = (responseMessage) -> {
			if (responseMessage.getError() != null) {
				result.completeExceptionally(new ResponseErrorException(responseMessage.getError()));
			} else {
				result.complete(responseMessage.getResult());
			}
		};
		synchronized(sentRequestMap) {
			sentRequestMap.put(id, new PendingRequestInfo(requestMessage, responseHandler));
		}
		out.consume(requestMessage);
		return result;
	}

	protected void sendCancelNotification(String id) {
		Map<String, String> cancelParams = new HashMap<String, String>();
		cancelParams.put("id", id);
		notify(CANCEL_METHOD, cancelParams);
	}

	@Override
	public void consume(Message message) {
		if (message instanceof NotificationMessage) {
			NotificationMessage notificationMessage = (NotificationMessage) message;
			handleNotification(notificationMessage);
		} else if (message instanceof RequestMessage) {
			RequestMessage requestMessage = (RequestMessage) message;
			handleRequest(requestMessage);
		} else if (message instanceof ResponseMessage) {
			ResponseMessage responseMessage = (ResponseMessage) message;
			handleResponse(responseMessage);
		}
	}

	protected void handleResponse(ResponseMessage responseMessage) {
		PendingRequestInfo pendingRequestInfo;
		synchronized (sentRequestMap) {
			pendingRequestInfo = sentRequestMap.remove(responseMessage.getId());
		}
		if (pendingRequestInfo == null) {
			throw new IllegalStateException("Unmatched response message " + responseMessage);
		}
		pendingRequestInfo.responseHandler.accept(responseMessage);
	}

	protected void handleNotification(NotificationMessage notificationMessage) {
		if (CANCEL_METHOD.equals(notificationMessage.getMethod())) {
			Object cancelParams = notificationMessage.getParams();
			if (cancelParams instanceof Map<?,?>) {
				synchronized (receivedRequestMap) {
					String id = (String) ((Map<?, ?>) cancelParams).get("id");
					CompletableFuture<?> future = receivedRequestMap.get(id);
					if (future == null) {
						throw new IllegalStateException("Unmatched cancel notification: " + notificationMessage);
					}
					future.cancel(true);
				}
				return;
			} else {
				LOG.warning("Cancellation support disabled, since the '$/cancel' method has explicitly been registered.");
			}
		}
		localEndpoint.notify(notificationMessage.getMethod(), notificationMessage.getParams());
	}
	
	protected void handleRequest(RequestMessage requestMessage) {
		final ResponseMessage responseMessage = new ResponseMessage();
		responseMessage.setId(requestMessage.getId());
		responseMessage.setJsonrpc(MessageConstants.JSONRPC_VERSION);
		CompletableFuture<?> future = localEndpoint.request(requestMessage.getMethod(), requestMessage.getParams());
		synchronized (receivedRequestMap) {
			receivedRequestMap.put(requestMessage.getId(), future);
		}
		future.thenAccept((result) -> {
			responseMessage.setResult(result);
			out.consume(responseMessage);
		}).exceptionally((Throwable t) -> {
			if (!(t instanceof CancellationException)) {
				ResponseError errorObject = exceptionHandler.apply(t);
				if (errorObject != null) {
					responseMessage.setError(errorObject);
					out.consume(responseMessage);
				}
			}
			return null;
		}).thenApply((obj) -> {
			synchronized (receivedRequestMap) {
				receivedRequestMap.remove(requestMessage.getId());
			}
			return null;
		});
	}

	@Override
	public String resolveMethod(String requestId) {
		synchronized (sentRequestMap) {
			PendingRequestInfo requestInfo = sentRequestMap.get(requestId);
			if (requestInfo != null) {
				return requestInfo.requestMessage.getMethod();
			}
		}
		return null;
	}
	
}
