/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json

import java.io.InputStream
import java.io.OutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Future
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.concurrent.CancellationException
import java.util.concurrent.ExecutionException

@FinalFieldsConstructor
abstract class AbstractJsonBasedServer {
	
	@Accessors(PROTECTED_GETTER)
	val ExecutorService executorService
	
	@Accessors(PUBLIC_GETTER, PROTECTED_SETTER)
	LanguageServerProtocol protocol
	
	Future<?> ioHandlerJoin
	
	def synchronized void connect(InputStream input, OutputStream output) {
		if (isActive)
			throw new IllegalStateException("Cannot connect while active.")
		protocol.ioHandler.output = output
		protocol.ioHandler.input = input
		ioHandlerJoin = executorService.submit(protocol.ioHandler)
	}
	
	def synchronized void exit() {
		protocol.ioHandler.stop()
	}
	
	def boolean isActive() {
		protocol.ioHandler.isRunning
	}
	
	def void join() throws InterruptedException, ExecutionException {
		if (ioHandlerJoin === null)
			throw new IllegalStateException("Cannot join before connected.")
		try {
			ioHandlerJoin.get()
		} catch (CancellationException e) {
			// Execution was canceled
		}
	}
	
}