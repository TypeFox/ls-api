/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json;

import io.typefox.lsapi.ResponseErrorCode;

public class InvalidMessageException extends RuntimeException {
	
	private static final long serialVersionUID = 1L;

	private final String requestId;
	
	private final ResponseErrorCode errorCode;
	
	public InvalidMessageException(String message) {
		super(message);
		this.requestId = null;
		this.errorCode = ResponseErrorCode.InvalidRequest;
	}
	
	public InvalidMessageException(String message, String requestId) {
		super(message);
		this.requestId = requestId;
		this.errorCode = ResponseErrorCode.InvalidRequest;
	}
	
	public InvalidMessageException(String message, String requestId, Throwable cause) {
		super(message, cause);
		this.requestId = requestId;
		this.errorCode = ResponseErrorCode.InvalidRequest;
	}
	
	public InvalidMessageException(String message, String requestId, ResponseErrorCode errorCode) {
		super(message);
		this.requestId = requestId;
		this.errorCode = errorCode;
	}
	
	public String getRequestId() {
		return requestId;
	}
	
	public ResponseErrorCode getErrorCode() {
		return errorCode;
	}
	
}
