/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi

import io.typefox.lsapi.annotations.LanguageServerAPI

@LanguageServerAPI
interface ServerCapabilities {
	
	/**
	 * Defines how text documents are synced.
	 */
	def TextDocumentSyncKind getTextDocumentSync()
	
	/**
	 * The server provides hover support.
	 */
	def Boolean isHoverProvider()
	
	/**
	 * The server provides completion support.
	 */
	def CompletionOptions getCompletionProvider()
	
	/**
	 * The server provides signature help support.
	 */
	def SignatureHelpOptions getSignatureHelpProvider()
	
	/**
	 * The server provides goto definition support.
	 */
	def Boolean isDefinitionProvider()
	
	/**
	 * The server provides find references support.
	 */
	def Boolean isReferencesProvider()
	
	/**
	 * The server provides document highlight support.
	 */
	def Boolean isDocumentHighlightProvider()
	
	/**
	 * The server provides document symbol support.
	 */
	def Boolean isDocumentSymbolProvider()
	
	/**
	 * The server provides workspace symbol support.
	 */
	def Boolean isWorkspaceSymbolProvider()
	
	/**
	 * The server provides code actions.
	 */
	def Boolean isCodeActionProvider()
	
	/**
	 * The server provides code lens.
	 */
	def CodeLensOptions getCodeLensProvider()
	
	/**
	 * The server provides document formatting.
	 */
	def Boolean isDocumentFormattingProvider()
	
	/**
	 * The server provides document range formatting.
	 */
	def Boolean isDocumentRangeFormattingProvider()
	
	/**
	 * The server provides document formatting on typing.
	 */
	def DocumentOnTypeFormattingOptions getDocumentOnTypeFormattingProvider()
	
	/**
	 * The server provides rename support.
	 */
	def Boolean isRenameProvider()
	
}