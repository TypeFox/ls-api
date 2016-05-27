/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import io.typefox.lsapi.Message
import io.typefox.lsapi.MessageAcceptor
import io.typefox.lsapi.MessageImpl
import io.typefox.lsapi.RequestMessage
import io.typefox.lsapi.ResponseError
import io.typefox.lsapi.ResponseErrorImpl
import io.typefox.lsapi.ResponseMessage
import io.typefox.lsapi.ResponseMessageImpl
import java.io.IOException
import java.io.InputStream
import java.io.InterruptedIOException
import java.io.OutputStream
import java.io.UnsupportedEncodingException
import java.nio.channels.ClosedChannelException
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class LanguageServerProtocol implements MessageAcceptor {
	
	public static val JSONRPC_VERSION = '2.0'
	
	public static val H_CONTENT_LENGTH = 'Content-Length'
	public static val H_CONTENT_TYPE = 'Content-Type'
	
	static val CT_JSON = 'application/json'
	
	val MessageJsonHandler jsonHandler
	
	val MessageAcceptor incomingMessageAcceptor
	
	@Accessors
	OutputStream output
	
	@Accessors
	String outputEncoding = 'UTF-8'
	
	val List<(String, Throwable)=>void> errorListeners = newArrayList
	val List<(Message, String)=>void> incomingMessageListeners = newArrayList
	val List<(Message, String)=>void> outgoingMessageListeners = newArrayList
	
	val outputLock = new Object
	
	def void addErrorListener((String, Throwable)=>void listener) {
		errorListeners.add(listener)
	}
	
	def void addIncomingMessageListener((Message, String)=>void listener) {
		incomingMessageListeners.add(listener)
	}
	
	def void addOutgoingMessageListener((Message, String)=>void listener) {
		outgoingMessageListeners.add(listener)
	}
	
	def listen(InputStream in) throws IOException {
		var StringBuilder headerBuilder
		var StringBuilder debugBuilder
		var newLine = false
		var contentLength = -1
		var charset = 'UTF-8'
		var c = in.read
		while (c != -1) {
			if (debugBuilder === null)
				debugBuilder = new StringBuilder
			debugBuilder.append(c as char)
			if (c.matches('\n')) {
				if (newLine) {
					if (contentLength < 0) {
						logError(new IllegalStateException(
							'Missing header ' + H_CONTENT_LENGTH + ' in input "' + debugBuilder + '"'
						))
					} else {
						try {
							val buffer = newByteArrayOfSize(contentLength)
							val bytesRead = in.read(buffer, 0, contentLength)
							if (bytesRead < 0) {
								return
							}
							handleMessage(new String(buffer, charset), charset)
						} catch (UnsupportedEncodingException e) {
							logError(e)
						}
						newLine = false
					}
					contentLength = -1
					debugBuilder = null
				} else if (headerBuilder !== null) {
					val line = headerBuilder.toString
					val sepIndex = line.indexOf(':')
					if (sepIndex >= 0) {
						val key = line.substring(0, sepIndex).trim
						switch key {
							case H_CONTENT_LENGTH:
								try {
									contentLength = Integer.parseInt(line.substring(sepIndex + 1).trim)
								} catch (NumberFormatException e) {
									logError(e)
								}
							case H_CONTENT_TYPE: {
								val charsetIndex = line.indexOf('charset=')
								if (charsetIndex >= 0)
									charset = line.substring(charsetIndex + 8).trim
							}
						}
					}
					headerBuilder = null
				}
				newLine = true
			} else if (!c.matches('\r')) {
				if (headerBuilder === null)
					headerBuilder = new StringBuilder
				headerBuilder.append(c as char)
				newLine = false
			}
			c = in.read
		}
	}
	
	private def matches(int c1, char c2) {
		c1 == c2
	}
	
	protected def void handleMessage(String content, String charset) throws IOException {
		var String requestId
		try {
			val message = jsonHandler.parseMessage(content)
			if (message instanceof RequestMessage)
				requestId = message.id
			logIncomingMessage(message, content)
			
			incomingMessageAcceptor.accept(message)
			
		} catch (InvalidMessageException e) {
			logError(e)
			val response = createErrorResponse(e.message, e.errorCode, e.requestId)
			send(response, charset)
		} catch (Exception e) {
			logError(e)
			val response = createErrorResponse(e.message, ResponseError.INTERNAL_ERROR, requestId)
			send(response, charset)
		}
	}
	
	protected def void logIncomingMessage(Message message, String json) {
		for (l : incomingMessageListeners) {
			l.apply(message, json)
		}
	}
	
	override accept(Message message) {
		send(message, outputEncoding)
	}
	
	protected def send(Message message, String charset) {
		if (message.jsonrpc === null && message instanceof MessageImpl)
			(message as MessageImpl).jsonrpc = JSONRPC_VERSION
		val content = jsonHandler.serialize(message)
		
		val responseBytes = content.getBytes(charset)
		val headerBuilder = new StringBuilder
		headerBuilder.append(H_CONTENT_LENGTH).append(': ').append(responseBytes.length).append('\r\n')
		if (charset !== 'UTF-8')
			headerBuilder.append(H_CONTENT_TYPE).append(': ').append(CT_JSON).append('; charset=').append(charset).append('\r\n')
		headerBuilder.append('\r\n')
		synchronized (outputLock) {
			output.write(headerBuilder.toString.bytes)
			output.write(responseBytes)
			output.flush
			
			logOutgoingMessage(message, content)
		}
	}
	
	protected def ResponseMessage createErrorResponse(String errorMessage, int errorCode, String requestId) {
		val response = new ResponseMessageImpl
		response.jsonrpc = JSONRPC_VERSION
		if (requestId !== null)
			response.id = requestId
		response.error = new ResponseErrorImpl => [
			message = errorMessage
			code = errorCode
		]
		return response
	}
	
	protected def void logOutgoingMessage(Message message, String json) {
		for (l : outgoingMessageListeners) {
			l.apply(message, json)
		}
	}
	
	protected def logError(Throwable throwable) {
		logError(throwable.message, throwable)
	}
	
	protected def logError(String message, Throwable throwable) {
		for (l : errorListeners) {
			l.apply(message, throwable)
		}
	}
	
	@FinalFieldsConstructor
	static class InputListener implements Runnable {
		
		val LanguageServerProtocol protocol
		
		@Accessors(PUBLIC_SETTER)
		InputStream input
		
		@Accessors(PUBLIC_GETTER)
		boolean active
		
		Thread thread
		
		override run() {
			thread = Thread.currentThread
			active = true
			try {
				while (active) {
					protocol.listen(input)
				}
			} catch (InterruptedIOException e) {
				// The listener was interrupted, e.g. by calling stop()
			} catch (ClosedChannelException e) {
				// The channel whose stream has been listened was closed
			} catch (IOException e) {
				protocol.logError(e)
			} finally {
				active = false
				thread = null
			}
		}
		
		def void stop() {
			active = false
			thread?.interrupt()
		}
		
	}
	
}
