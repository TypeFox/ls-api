/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import io.typefox.lsapi.InitializeParams
import io.typefox.lsapi.Message
import io.typefox.lsapi.MessageAcceptor
import io.typefox.lsapi.MessageImpl
import io.typefox.lsapi.NotificationMessage
import io.typefox.lsapi.RequestMessage
import io.typefox.lsapi.ResponseError
import io.typefox.lsapi.ResponseErrorImpl
import io.typefox.lsapi.ResponseMessage
import io.typefox.lsapi.ResponseMessageImpl
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.io.UnsupportedEncodingException
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class LanguageServerProtocol implements MessageAcceptor {
	
	public static val JSONRPC_VERSION = '2.0'
	
	public static val H_CONTENT_LENGTH = 'Content-Length'
	public static val H_CONTENT_TYPE = 'Content-Type'
	
	static val CT_JSON = 'application/json'
	
	val OutputStream output
	
	val LanguageServerJsonHandler jsonHandler
	
	val MessageAcceptor incomingMessageAcceptor
	
	@Accessors(PUBLIC_SETTER)
	String outputEncoding = 'UTF-8'
	
	val outputLock = new Object
	
	def listen(InputStream in) throws IOException {
		var StringBuilder headerBuilder
		var StringBuilder debugBuilder
		var newLine = false
		var contentLength = -1
		var charset = 'UTF-8'
		var keepServing = true
		var c = in.read
		while (keepServing && c != -1) {
			if (debugBuilder === null)
				debugBuilder = new StringBuilder
			debugBuilder.append(c as char)
			if (c.matches('\n')) {
				if (newLine) {
					if (contentLength < 0) {
						logException(new IllegalStateException(
							'Missing header ' + H_CONTENT_LENGTH + ' in input "' + debugBuilder + '"'
						))
					} else {
						try {
							val buffer = newByteArrayOfSize(contentLength)
							val bytesRead = in.read(buffer, 0, contentLength)
							if (bytesRead < 0)
								keepServing = false
							else
								keepServing = handleMessage(new String(buffer, charset), charset)
						} catch (UnsupportedEncodingException e) {
							logException(e)
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
									logException(e)
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
	
	protected def boolean handleMessage(String content, String charset) throws IOException {
		var String requestId
		var result = true
		try {
			val message = jsonHandler.parseMessage(content)
			if (message instanceof RequestMessage) {
				logMessage('Received Request', content)
				requestId = message.id
				switch message.method {
					case 'initialize':
						if (message.params instanceof InitializeParams)
							initialize(message.params as InitializeParams)
					case 'shutdown',
					case 'exit':
						result = false
				}
			} else if (message instanceof NotificationMessage) {
				logMessage('Received Notification', content)
			}
			
			incomingMessageAcceptor.accept(message)
			
		} catch (InvalidMessageException e) {
			logException(e)
			val response = createErrorResponse(e.message, e.errorCode, e.requestId)
			send(response, charset)
		} catch (Exception e) {
			logException(e)
			val response = createErrorResponse(e.message, ResponseError.INTERNAL_ERROR, requestId)
			send(response, charset)
		}
		return result
	}
	
	override accept(Message message) {
		send(message, outputEncoding)
	}
	
	protected def send(Message message, String charset) {
		if (message.jsonrpc === null && message instanceof MessageImpl)
			(message as MessageImpl).jsonrpc = JSONRPC_VERSION
		synchronized (outputLock) {
			val content = jsonHandler.serialize(message)
			if (message instanceof ResponseMessage)
				logMessage('Sending Response', content)
			else if (message instanceof NotificationMessage)
				logMessage('Sending Notification', content)
			val responseBytes = content.getBytes(charset)
			val headerBuilder = new StringBuilder
			headerBuilder.append(H_CONTENT_LENGTH).append(': ').append(responseBytes.length).append('\r\n')
			if (charset !== 'UTF-8')
				headerBuilder.append(H_CONTENT_TYPE).append(': ').append(CT_JSON).append('; charset=').append(charset).append('\r\n')
			headerBuilder.append('\r\n')
			output.write(headerBuilder.toString.bytes)
			output.write(responseBytes)
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
	
	protected def initialize(InitializeParams params) {
		// Specialize in subclasses if required
	}
	
	protected def logException(Throwable throwable) {
		// Specialize in subclasses if required
		throwable.printStackTrace()
	}
	
	protected def logMessage(String title, String content) {
		// Specialize in subclasses if required
	}
	
}
