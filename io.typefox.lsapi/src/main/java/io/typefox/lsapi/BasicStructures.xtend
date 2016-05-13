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
 * Position in a text document expressed as zero-based line and character offset.
 */
@LanguageServerAPI
interface Position {
	
	/**
	 * Line position in a document (zero-based).
	 */
	def int getLine()
	
	/**
	 * Character offset on a line in a document (zero-based).
	 */
	def int getCharacter()
	
}

/**
 * A range in a text document expressed as (zero-based) start and end positions.
 */
@LanguageServerAPI
interface Range {
	
	/**
	 * The range's start position
	 */
	def Position getStart()
	
	/**
	 * The range's end position
	 */
	def Position getEnd()
	
}

/**
 * Represents a location inside a resource, such as a line inside a text file.
 */
@LanguageServerAPI
interface Location {
	
	def String getUri()
	
	def Range getRange()
	
}

/**
 * A textual edit applicable to a text document.
 */
@LanguageServerAPI
interface TextEdit {
	
	/**
	 * The range of the text document to be manipulated. To insert text into a document create a range where start === end.
	 */
	def Range getRange()
	
	/**
	 * The string to be inserted. For delete operations use an empty string.
	 */
	def String getNewText()
	
}

/**
 * Represents a reference to a command. Provides a title which will be used to represent a command in the UI and,
 * optionally, an array of arguments which will be passed to the command handler function when invoked.
 */
@LanguageServerAPI
interface Command {
	
	/**
	 * Title of the command, like `save`.
	 */
	def String getTitle()
	
	/**
	 * The identifier of the actual command handler.
	 */
	def String getCommand()
	
	/**
	 * Arguments that the command handler should be invoked with.
	 */
	def List<Object> getArguments()
	
}

/**
 * Text documents are identified using an URI. On the protocol level URI's are passed as strings.
 */
@LanguageServerAPI
interface TextDocumentIdentifier {
	
	/**
	 * The text document's uri.
	 */
	def String getUri()
	
}

/**
 * An identifier to denote a specific version of a text document.
 */
@LanguageServerAPI
interface VersionedTextDocumentIdentifier extends TextDocumentIdentifier {
	
	/**
	 * The version number of this document.
	 */
	def int getVersion()
	
}

@LanguageServerAPI
interface MarkedString {
	
	def String getLanguage()
	
	def String getValue()
	
}

/**
 * A generic call back interface for client notifications
 */
interface NotificationCallback<T> {
    public def void onNotification(T t);
}