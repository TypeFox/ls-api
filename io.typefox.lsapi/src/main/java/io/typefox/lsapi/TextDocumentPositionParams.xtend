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
 * A parameter literal used in requests to pass a text document and a position inside that document.
 */
@LanguageServerAPI
interface TextDocumentPositionParams {
	
	/**
	 * The text document.
	 */
	def TextDocumentIdentifier getTextDocument()
	
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	def String getUri()
	
	/**
	 * The position inside the text document.
	 */
	def Position getPosition()
	
}