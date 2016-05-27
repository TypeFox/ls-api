/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json

import io.typefox.lsapi.ResponseError
import org.eclipse.xtend.lib.annotations.Accessors

@Accessors
class InvalidMessageException extends RuntimeException {
	
	val String requestId
	
	val int errorCode
	
	new(String message) {
		super(message)
		this.requestId = null
		this.errorCode = ResponseError.INVALID_REQUEST
	}
	
	new(String message, String requestId) {
		super(message)
		this.requestId = requestId
		this.errorCode = ResponseError.INVALID_REQUEST
	}
	
	new(String message, String requestId, Throwable cause) {
		super(message, cause)
		this.requestId = requestId
		this.errorCode = ResponseError.INVALID_REQUEST
	}
	
	new(String message, String requestId, int errorCode) {
		super(message)
		this.requestId = requestId
		this.errorCode = errorCode
	}
	
}
