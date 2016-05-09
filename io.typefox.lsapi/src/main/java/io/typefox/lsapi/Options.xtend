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
import java.util.Map

/**
 * Value-object describing what options formatting should use.
 */
@LanguageServerAPI
interface FormattingOptions {
	
	/**
	 * Size of a tab in spaces.
	 */
	def int getTabSize()
	
	/**
	 * Prefer spaces over tabs.
	 */
	def boolean isInsertSpaces()
	
	/**
	 * Signature for further properties.
	 */
	def Map<String, String> getProperties()
	
}

/**
 * Code Lens options.
 */
@LanguageServerAPI
interface CodeLensOptions {
	
	/**
	 * Code lens has a resolve provider as well.
	 */
	def boolean getResolveProvider()
	
}

/**
 * Completion options.
 */
@LanguageServerAPI
interface CompletionOptions {
	
	/**
	 * The server provides support to resolve additional information for a completion item.
	 */
	def boolean getResolveProvider()
	
	/**
	 * The characters that trigger completion automatically.
	 */
	def List<String> getTriggerCharacters()
	
}

/**
 * Format document on type options
 */
@LanguageServerAPI
interface DocumentOnTypeFormattingOptions {
	
	/**
	 * A character on which formatting should be triggered, like `}`.
	 */
	def String getFirstTriggerCharacter()
	
	/**
	 * More trigger characters.
	 */
	def List<String> getMoreTriggerCharacter()
	
}

/**
 * Signature help options.
 */
@LanguageServerAPI
interface SignatureHelpOptions {
	
	/**
	 * The characters that trigger signature help automatically.
	 */
	def List<String> getTriggerCharacters()
	
}

@LanguageServerAPI
interface ServerCapabilities {
	
	/**
	 * Documents should not be synced at all.
	 */
	val SYNC_NONE = 0
	
	/**
	 * Documents are synced by always sending the full content of the document.
	 */
	val SYNC_FULL = 1
	
	/**
	 * Documents are synced by sending the full content on open. After that only incremental
     * updates to the document are send.
	 */
	val SYNC_INCREMENTAL = 2
	
	/**
	 * Defines how text documents are synced.
	 */
	def Integer getTextDocumentSync()
	
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
