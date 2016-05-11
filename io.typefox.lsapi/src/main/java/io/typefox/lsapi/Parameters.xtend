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

/**
 * The initialize request is sent as the first request from the client to the server.
 */
@LanguageServerAPI
interface InitializeParams {
	
	/**
	 * The process Id of the parent process that started the server.
	 */
	def int getProcessId()
	
	/**
	 * The rootPath of the workspace. Is null if no folder is open.
	 */
	def String getRootPath()
	
	/**
	 * The capabilities provided by the client (editor)
	 */
	def Object getCapabilities()
	
}

@LanguageServerAPI
interface CancelParams {
	
	/**
	 * The request id to cancel.
	 */
	def String getId()
	
}

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

/**
 * The references request is sent from the client to the server to resolve project-wide references for the symbol
 * denoted by the given text document position.
 */
@LanguageServerAPI
interface ReferenceParams extends TextDocumentPositionParams {
	
	def ReferenceContext getContext()
	
}

/**
 * The references request is sent from the client to the server to resolve project-wide references for the symbol
 * denoted by the given text document position.
 */
@LanguageServerAPI
interface ReferenceContext {
	
	/**
	 * Include the declaration of the current symbol.
	 */
	def boolean isIncludeDeclaration()
	
}

/**
 * The code action request is sent from the client to the server to compute commands for a given text document and range.
 * The request is triggered when the user moves the cursor into an problem marker in the editor or presses the lightbulb
 * associated with a marker.
 */
@LanguageServerAPI
interface CodeActionParams {
	
	/**
	 * The document in which the command was invoked.
	 */
	def TextDocumentIdentifier getTextDocument()
	
	/**
	 * The range for which the command was invoked.
	 */
	def Range getRange()
	
	/**
	 * Context carrying additional information.
	 */
	def CodeActionContext getContext()
	
}

/**
 * Contains additional diagnostic information about the context in which a code action is run.
 */
@LanguageServerAPI
interface CodeActionContext {
	
	/**
	 * An array of diagnostics.
	 */
	def List<? extends Diagnostic> getDiagnostics()
	
}

/**
 * The code lens request is sent from the client to the server to compute code lenses for a given text document.
 */
@LanguageServerAPI
interface CodeLensParams {
	
	/**
	 * The document to request code lens for.
	 */
	def TextDocumentIdentifier getTextDocument()
	
}

/**
 * The document formatting resquest is sent from the server to the client to format a whole document.
 */
@LanguageServerAPI
interface DocumentFormattingParams {
	
	/**
	 * The document to format.
	 */
	def TextDocumentIdentifier getTextDocument()
	
	/**
	 * The format options
	 */
	def FormattingOptions getOptions()
	
}

/**
 * The document on type formatting request is sent from the client to the server to format parts of the document during typing.
 */
@LanguageServerAPI
interface DocumentOnTypeFormattingParams extends DocumentFormattingParams {
	
	/**
	 * The position at which this request was send.
	 */
	def Position getPosition()
	
	/**
	 * The character that has been typed.
	 */
	def String getCh()
	
}

/**
 * The document range formatting request is sent from the client to the server to format a given range in a document.
 */
@LanguageServerAPI
interface DocumentRangeFormattingParams extends DocumentFormattingParams {
	
	/**
	 * The range to format
	 */
	def Range getRange()
	
}

/**
 * The document symbol request is sent from the client to the server to list all symbols found in a given text document.
 */
@LanguageServerAPI
interface DocumentSymbolParams {
	
	/**
	 * The text document.
	 */
	def TextDocumentIdentifier getTextDocument()
	
}

/**
 * The parameters of a Workspace Symbol Request.
 */
@LanguageServerAPI
interface WorkspaceSymbolParams {
	
	/**
	 * A non-empty query string
	 */
	def String getQuery()
	
}

/**
 * The rename request is sent from the client to the server to do a workspace wide rename of a symbol.
 */
@LanguageServerAPI
interface RenameParams {
	
	/**
	 * The document in which to find the symbol.
	 */
	def TextDocumentIdentifier getTextDocument()
	
	/**
	 * The position at which this request was send.
	 */
	def Position getPosition()
	
	/**
	 * The new name of the symbol. If the given name is not valid the request must return a
	 * ResponseError with an appropriate message set.
	 */
	def String getNewName()
	
}

/**
 * The document change notification is sent from the client to the server to signal changes to a text document.
 */
@LanguageServerAPI
interface DidChangeTextDocumentParams {
	
	/**
	 * The document that did change. The version number points to the version after all provided content changes have
     * been applied.
	 */
	def VersionedTextDocumentIdentifier getTextDocument()
	
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	def String getUri()
	
	/**
	 * The actual content changes.
	 */
	def List<? extends TextDocumentContentChangeEvent> getContentChanges()
	
}

/**
 * An event describing a change to a text document. If range and rangeLength are omitted the new text is considered
 * to be the full content of the document.
 */
@LanguageServerAPI
interface TextDocumentContentChangeEvent {
	
	/**
	 * The range of the document that changed.
	 */
	def Range getRange()
	
	/**
	 * The length of the range that got replaced.
	 */
	def Integer getRangeLength()
	
	/**
	 * The new text of the document.
	 */
	def String getText()
	
}

/**
 * The watched files notification is sent from the client to the server when the client detects changes
 * to file watched by the language client.
 */
@LanguageServerAPI
interface DidChangeWatchedFilesParams {
	
	/**
	 * The actual file events.
	 */
	def List<? extends FileEvent> getChanges()
	
}

/**
 * An event describing a file change.
 */
@LanguageServerAPI
interface FileEvent {
	
	/**
	 * The file got created.
	 */
	val TYPE_CREATED = 1
	
	/**
	 * The file got changed.
	 */
	val TYPE_CHANGED = 2
	
	/**
	 * The file got deleted.
	 */
	val TYPE_DELETED = 3
	
	/**
	 * The file's uri.
	 */
	def String getUri()
	
	/**
	 * The change type.
	 */
	def int getType()
	
}

/**
 * The document close notification is sent from the client to the server when the document got closed in the client.
 * The document's truth now exists where the document's uri points to (e.g. if the document's uri is a file uri the
 * truth now exists on disk).
 */
@LanguageServerAPI
interface DidCloseTextDocumentParams {
	
	/**
	 * The document that was closed.
	 */
	def TextDocumentIdentifier getTextDocument()
	
}

/**
 * The document open notification is sent from the client to the server to signal newly opened text documents.
 * The document's truth is now managed by the client and the server must not try to read the document's truth using
 * the document's uri.
 */
@LanguageServerAPI
interface DidOpenTextDocumentParams extends TextDocumentIdentifier {
	
	/**
	 * The document that was opened.
	 */
	def TextDocumentItem getTextDocument()
	
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	def String getText()
	
}

/**
 * The document save notification is sent from the client to the server when the document for saved in the clinet.
 */
@LanguageServerAPI
interface DidSaveTextDocumentParams {
	
	/**
	 * The document that was closed.
	 */
	def TextDocumentIdentifier getTextDocument()
	
}

/**
 * A notification sent from the client to the server to signal the change of configuration settings.
 */
@LanguageServerAPI
interface DidChangeConfigurationParams {
	
	def Object getSettings()
	
}

/**
 * Diagnostics notification are sent from the server to the client to signal results of validation runs.
 */
@LanguageServerAPI
interface PublishDiagnosticsParams {
	
	/**
	 * The URI for which diagnostic information is reported.
	 */
	def String getUri()
	
	/**
	 * An array of diagnostic information items.
	 */
	def List<? extends Diagnostic> getDiagnostics()
	
}

/**
 * The show message notification is sent from a server to a client to ask the client to display a particular message
 * in the user interface.
 * 
 * The log message notification is send from the server to the client to ask the client to log a particular message.
 */
@LanguageServerAPI
interface MessageParams {
	
	/**
	 * An error message.
	 */
	val TYPE_ERROR = 1
	
	/**
	 * A warning message.
	 */
	val TYPE_WARNING = 2
	
	/**
	 * An information message.
	 */
	val TYPE_INFO = 3
	
	/**
	 * A log message.
	 */
	val TYPE_LOG = 1
	
	/**
	 * The message type.
	 */
	def int getType()
	
	/**
	 * The actual message.
	 */
	def String getMessage()
	
}

/**
 * The show message request is sent from a server to a client to ask the client to display a particular message in the
 * user interface. In addition to the show message notification the request allows to pass actions and to wait for an
 * answer from the client.
 */
@LanguageServerAPI
interface ShowMessageRequestParams extends MessageParams {
	
	/**
	 * The message action items to present.
	 */
	def List<? extends MessageActionItem> getActions()
	
}

/**
 * The show message request is sent from a server to a client to ask the client to display a particular message in the
 * user interface. In addition to the show message notification the request allows to pass actions and to wait for an
 * answer from the client.
 */
@LanguageServerAPI
interface MessageActionItem {
	
	/**
	 * A short title like 'Retry', 'Open Log' etc.
	 */
	def String getTitle()
	
}
