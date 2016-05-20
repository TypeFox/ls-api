/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

final class MessageMethods {
	
	public static val INITIALIZE = 'initialize'
	public static val SHUTDOWN = 'shutdown'
	public static val EXIT = 'exit'
	public static val COMPLETION = 'textDocument/completion'
	public static val RESOLVE_COMPLETION = 'completionItem/resolve'
	public static val HOVER = 'textDocument/hover'
	public static val SIGNATURE_HELP = 'textDocument/signatureHelp'
	public static val DEFINITION = 'textDocument/definition'
	public static val DOCUMENT_HIGHLIGHT = 'textDocument/documentHighlight'
	public static val DOCUMENT_REFERENCES = 'textDocument/references'
	public static val DOCUMENT_SYMBOL = 'textDocument/documentSymbol'
	public static val WORKSPACE_SYMBOL = 'workspace/symbol'
	public static val CODE_ACTION = 'textDocument/codeAction'
	public static val CODE_LENS = 'textDocument/codeLens'
	public static val RESOLVE_CODE_LENS = 'codeLens/resolve'
	public static val FORMATTING = 'textDocument/formatting'
	public static val RANGE_FORMATTING = 'textDocument/rangeFormatting'
	public static val ON_TYPE_FORMATTING = 'textDocument/onTypeFormatting'
	public static val DOCUMENT_RENAME = 'textDocument/rename'
	public static val SHOW_MESSAGE_REQUEST = 'window/showMessageRequest'
	
	public static val PUBLIC_DIAGNOSTICS = 'textDocument/publishDiagnostics'
	public static val DID_CHANGE_CONFIGURATION = 'workspace/didChangeConfiguration'
	public static val DID_OPEN = 'textDocument/didOpen'
	public static val DID_CHANGE_DOCUMENT = 'textDocument/didChange'
	public static val DID_CLOSE = 'textDocument/didClose'
	public static val DID_CHANGE_WATCHED_FILES = 'workspace/didChangeWatchedFiles'
	public static val DID_SAVE = 'textDocument/didSave'
	public static val SHOW_MESSAGE = 'window/showMessage'
	public static val LOG_MESSAGE = 'window/logMessage'
	
	/** Hidden constructor to avoid instantiation. */
	private new() {}
	
}