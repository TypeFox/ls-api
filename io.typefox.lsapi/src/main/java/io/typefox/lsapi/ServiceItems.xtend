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

@LanguageServerAPI
interface LanguageDescription {
    
    /**
     * The language id.
     */
    def String getLanguageId()
    
    /**
     * The optional content types this language is associated with.
     */
    def List<String> getMimeTypes()
    
    /**
     * The fileExtension this language is associated with. At least one extension must be provided.
     */
    def List<String> getFileExtensions()
    
    /**
     * The optional highlighting configuration to support client side syntax highlighting.
     * The format is client (editor) dependent.
     */
    def String getHighlightingConfiguration()
}

@LanguageServerAPI
interface InitializeError {
	
	/**
	 * Indicates whether the client should retry to send the initialize request after showing the message provided
     * in the ResponseError.
	 */
	def boolean isRetry()
	
}

/**
 * Represents a collection of completion items to be presented in the editor.
 */
@LanguageServerAPI
interface CompletionList {
	
	/**
     * This list it not complete. Further typing should result in recomputing this list.
     */
    def boolean isIncomplete()
    
    /**
     * The completion items.
     */
    def List<? extends CompletionItem> getItems()
    
}

/**
 * The Completion request is sent from the client to the server to compute completion items at a given cursor position.
 * Completion items are presented in the IntelliSense user interface. If computing complete completion items is expensive
 * servers can additional provide a handler for the resolve completion item request. This request is send when a
 * completion item is selected in the user interface.
 */
@LanguageServerAPI
interface CompletionItem {
	
	val KIND_TEXT = 1
	val KIND_METHOD = 2
	val KIND_FUNCTION = 3
	val KIND_CONSTRUCTOR = 4
	val KIND_FIELD = 5
	val KIND_VARIABLE = 6
	val KIND_CLASS = 7
	val KIND_INTERFACE = 8
	val KIND_MODULE = 9
	val KIND_PROPERTY = 10
	val KIND_UNIT = 11
	val KIND_VALUE = 12
	val KIND_ENUM = 13
	val KIND_KEYWORD = 14
	val KIND_SNIPPET = 15
	val KIND_COLOR = 16
	val KIND_FILE = 17
	val KIND_REFERENCE = 18
	
	/**
	 * The label of this completion item. By default also the text that is inserted when selecting this completion.
	 */
	def String getLabel()
	
	/**
	 * The kind of this completion item. Based of the kind an icon is chosen by the editor.
	 */
	def Integer getKind()
	
	/**
	 * A human-readable string with additional information about this item, like type or symbol information.
	 */
	def String getDetail()
	
	/**
	 * A human-readable string that represents a doc-comment.
	 */
	def String getDocumentation()
	
	/**
	 * A string that shoud be used when comparing this item with other items. When `falsy` the label is used.
	 */
	def String getSortText()
	
	/**
	 * A string that should be used when filtering a set of completion items. When `falsy` the label is used.
	 */
	def String getFilterText()
	
	/**
	 * A string that should be inserted a document when selecting this completion. When `falsy` the label is used.
	 */
	def String getInsertText()
	
	/**
	 * An edit which is applied to a document when selecting this completion. When an edit is provided the value of
     * insertText is ignored.
	 */
	def TextEdit getTextEdit()
	
	/**
	 * An data entry field that is preserved on a completion item between a completion and a completion resolve request.
	 */
	def Object getData()
	
}

/**
 * The result of a hover request.
 */
@LanguageServerAPI
interface Hover {
	
	/**
	 * The hover's content
	 */
	def List<? extends MarkedString> getContents()
	
	/**
	 * An optional range
	 */
	def Range getRange()
	
}

/**
 * A code lens represents a command that should be shown along with source text, like the number of references,
 * a way to run tests, etc.
 *
 * A code lens is <em>unresolved</em> when no command is associated to it. For performance reasons the creation of a
 * code lens and resolving should be done to two stages.
 */
@LanguageServerAPI
interface CodeLens {
	
	/**
	 * The range in which this code lens is valid. Should only span a single line.
	 */
	def Range getRange()
	
	/**
	 * The command this code lens represents.
	 */
	def Command getCommand()
	
	/**
	 * An data entry field that is preserved on a code lens item between a code lens and a code lens resolve request.
	 */
	def Object getData()
	
}

/**
 * Signature help represents the signature of something callable. There can be multiple signature but only one
 * active and only one active parameter.
 */
@LanguageServerAPI
interface SignatureHelp {
	
	/**
	 * One or more signatures.
	 */
	def List<? extends SignatureInformation> getSignatures()
	
	/**
	 * The active signature.
	 */
	def Integer getActiveSignature()
	
	/**
	 * The active parameter of the active signature.
	 */
	def Integer getActiveParameter()
	
}

/**
 * Represents the signature of something callable. A signature can have a label, like a function-name, a doc-comment, and
 * a set of parameters.
 */
@LanguageServerAPI
interface SignatureInformation {
	
	/**
	 * The label of this signature. Will be shown in the UI.
	 */
	def String getLabel()
	
	/**
	 * The human-readable doc-comment of this signature. Will be shown in the UI but can be omitted.
	 */
	def String getDocumentation()
	
	/**
	 * The parameters of this signature.
	 */
	def List<? extends ParameterInformation> getParameters()
	
}

/**
 * Represents a parameter of a callable-signature. A parameter can have a label and a doc-comment.
 */
@LanguageServerAPI
interface ParameterInformation {
	
	/**
	 * The label of this signature. Will be shown in the UI.
	 */
	def String getLabel()
	
	/**
	 * The human-readable doc-comment of this signature. Will be shown in the UI but can be omitted.
	 */
	def String getDocumentation()
	
}

/**
 * Represents information about programming constructs like variables, classes, interfaces etc.
 */
@LanguageServerAPI
interface SymbolInformation {
	
	val KIND_FILE = 1
	val KIND_MODULE = 2
	val KIND_NAMESPACE = 3
	val KIND_PACKAGE = 4
	val KIND_CLASS = 5
	val KIND_METHOD = 6
	val KIND_PROPERTY = 7
	val KIND_FIELD = 8
	val KIND_CONSTRUCTOR = 9
	val KIND_ENUM = 10
	val KIND_INTERFACE = 11
	val KIND_FUNCTION = 12
	val KIND_VARIABLE = 13
	val KIND_CONSTANT = 14
	val KIND_STRING = 15
	val KIND_NUMBER = 16
	val KIND_BOOLEAN = 17
	val KIND_ARRAY = 18
	
	/**
	 * The name of this symbol.
	 */
	def String getName()
	
	/**
	 * The kind of this symbol.
	 */
	def int getKind()
	
	/**
	 * The location of this symbol.
	 */
	def Location getLocation()
	
	/**
	 * The name of the symbol containing this symbol.
	 */
	def String getContainer()
	
}

/**
 * Represents a diagnostic, such as a compiler error or warning. Diagnostic objects are only valid in the scope of a resource.
 */
@LanguageServerAPI
interface Diagnostic {
	
	/**
	 * Reports an error.
	 */
	val SEVERITY_ERROR = 1
	
	/**
	 * Reports a warning.
	 */
	val SEVERITY_WARNING = 2
	
	/**
	 * Reports an information.
	 */
	val SEVERITY_INFO = 3
	
	/**
	 * Reports a hint.
	 */
	val SEVERITY_HINT = 5
	
	/**
	 * The range at which the message applies
	 */
	def Range getRange()
	
	/**
	 * The diagnostic's severity. Can be omitted. If omitted it is up to the client to interpret diagnostics as error,
	 * warning, info or hint.
	 */
	def Integer getSeverity()
	
	/**
	 * The diagnostic's code. Can be omitted.
	 */
	def String getCode()
	
	/**
	 * A human-readable string describing the source of this diagnostic, e.g. 'typescript' or 'super lint'.
	 */
	def String getSource()
	
	/**
	 * The diagnostic's message.
	 */
	def String getMessage()
	
}

/**
 * A document highlight is a range inside a text document which deserves special attention. Usually a document highlight
 * is visualized by changing the background color of its range.
 */
@LanguageServerAPI
interface DocumentHighlight {
	
	/**
	 * A textual occurrance.
	 */
	val KIND_TEXT = 1
	
	/**
	 * Read-access of a symbol, like reading a variable.
	 */
	val KIND_READ = 2
	
	/**
	 * Write-access of a symbol, like writing to a variable.
	 */
	val KIND_WRITE = 3
	
	/**
	 * The range this highlight applies to.
	 */
	def Range getRange()
	
	/**
	 * The highlight kind, default is KIND_TEXT.
	 */
	def Integer getKind()
	
}

/**
 * A workspace edit represents changes to many resources managed in the workspace.
 */
@LanguageServerAPI
interface WorkspaceEdit {
	
	/**
	 * Holds changes to existing resources.
	 */
	def Map<String, ? extends List<? extends TextEdit>> getChanges()
	
}

/**
 * An item to transfer a text document from the client to the server.
 */
@LanguageServerAPI
interface TextDocumentItem {
	
	/**
	 * The text document's uri.
	 */
	def String getUri()
	
	/**
	 * The text document's language identifier
	 */
	def String getLanguageId()
	
	/**
	 * The version number of this document (it will strictly increase after each change, including undo/redo).
	 */
	def int getVersion()
	
	/**
	 * The content of the opened  text document.
	 */
	def String getText()
	
}
