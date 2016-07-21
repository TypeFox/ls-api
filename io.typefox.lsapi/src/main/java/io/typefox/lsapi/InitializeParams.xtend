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
 * The initialize request is sent as the first request from the client to the server.
 */
@LanguageServerAPI
interface InitializeParams {
	
	/**
	 * The process Id of the parent process that started the server.
	 */
	def Integer getProcessId()
	
	/**
	 * The rootPath of the workspace. Is null if no folder is open.
	 */
	def String getRootPath()
	
	/**
	 * The capabilities provided by the client (editor)
	 */
	def ClientCapabilities getCapabilities()
	
	/**
	 * An optional extension to the protocol.
	 * To tell the server what client (editor) is talking to it.
	 */
	def String getClientName()

}