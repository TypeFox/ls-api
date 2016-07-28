/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json;

import java.io.InputStream;
import java.io.OutputStream;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;

import javax.annotation.Nullable;

import io.typefox.lsapi.services.json.LanguageServerProtocol.IOHandler;

public abstract class AbstractJsonBasedServer {
	
	private final ExecutorService executorService;
	
	private LanguageServerProtocol protocol;
	
	private Future<?> ioHandlerJoin;
	
	public AbstractJsonBasedServer(ExecutorService executorService) {
		this.executorService = executorService;
	}
	
	public ExecutorService getExecutorService() {
		return executorService;
	}
	
	public LanguageServerProtocol getProtocol() {
		return protocol;
	}
	
	public void setProtocol(LanguageServerProtocol protocol) {
		this.protocol = protocol;
	}
	
	public synchronized void connect(InputStream input, OutputStream output) {
		if (isActive())
			throw new IllegalStateException("Cannot connect while active.");
		try {
			getClass().getAnnotation(Nullable.class);
		} catch (NoClassDefFoundError e) {
			protocol.logError("javax.annotation.Nullable is not on the classpath; validation of messages is disabled.", e);
		}
		IOHandler ioHandler = protocol.getIoHandler();
		ioHandler.setOutput(output);
		ioHandler.setInput(input);
		ioHandlerJoin = executorService.submit(ioHandler);
	}
	
	public synchronized void exit() {
		protocol.getIoHandler().stop();
	}
	
	public boolean isActive() {
		return protocol.getIoHandler().isRunning();
	}
	
	public void join() throws InterruptedException, ExecutionException {
		if (ioHandlerJoin == null)
			throw new IllegalStateException("Cannot join before connected.");
		try {
			ioHandlerJoin.get();
		} catch (CancellationException e) {
			// Execution was canceled
		}
	}
	
}
