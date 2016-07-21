/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi

import io.typefox.lsapi.annotations.LanguageServerAPI
import java.util.List

@LanguageServerAPI
interface InitializeResult {
	
	/**
	 * The capabilities the language server provides.
	 */
	def ServerCapabilities getCapabilities()
	
	
	/**
	 * An optional extension to the protocol, 
	 * that allows to provide information about the supported languages.
	 */
	def List<? extends LanguageDescription> getSupportedLanguages()
	
}