/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi

import io.typefox.lsapi.annotations.LanguageServerAPI

/**
 * A general message as defined by JSON-RPC. The language server protocol always uses "2.0" as the jsonrpc version.
 */
@LanguageServerAPI
interface Message {
	
	def String getJsonrpc()
	
}

/**
 * A notification message. A processed notification message must not send a response back. They work like events.
 */
@LanguageServerAPI
interface NotificationMessage extends Message {
	
	/**
	 * The method to be invoked.
	 */
	def String getMethod()
	
	/**
	 * The notification's params.
	 */
	def Object getParams()
	
}

/**
 * A request message to decribe a request between the client and the server. Every processed request must send a response back
 * to the sender of the request.
 */
@LanguageServerAPI
interface RequestMessage extends Message {
	
	/**
	 * The request id.
	 */
	def String getId()
	
	/**
	 * The method to be invoked.
	 */
	def String getMethod()
	
	/**
	 * The method's params.
	 */
	def Object getParams()
	
}

/**
 * Response Message send as a result of a request.
 */
@LanguageServerAPI
interface ResponseMessage extends Message {
	
	/**
	 * The request id.
	 */
	def String getId()
	
	/**
	 * The result of a request. This can be omitted in the case of an error.
	 */
	def Object getResult()
	
	/**
	 * The error object in case a request fails.
	 */
	def ResponseError getError()
	
}

@LanguageServerAPI
interface ResponseError {
	
	/**
	 * A number indicating the error type that occured.
	 */
	def ResponseErrorCode getCode()
	
	/**
	 * A string providing a short decription of the error.
	 */
	def String getMessage()
	
	/**
	 * A Primitive or Structured value that contains additional information about the error. Can be omitted.
	 */
	def Object getData()
	
}
