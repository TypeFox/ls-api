/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.util

import io.typefox.lsapi.DidChangeTextDocumentParamsImpl
import io.typefox.lsapi.DidChangeWatchedFilesParamsImpl
import io.typefox.lsapi.DidCloseTextDocumentParamsImpl
import io.typefox.lsapi.DidOpenTextDocumentParamsImpl
import io.typefox.lsapi.DocumentSymbolParamsImpl
import io.typefox.lsapi.FileEventImpl
import io.typefox.lsapi.HoverImpl
import io.typefox.lsapi.InitializeParamsImpl
import io.typefox.lsapi.MarkedStringImpl
import io.typefox.lsapi.Position
import io.typefox.lsapi.PositionImpl
import io.typefox.lsapi.Range
import io.typefox.lsapi.RangeImpl
import io.typefox.lsapi.ReferenceContextImpl
import io.typefox.lsapi.ReferenceParamsImpl
import io.typefox.lsapi.SignatureHelpImpl
import io.typefox.lsapi.SignatureInformationImpl
import io.typefox.lsapi.TextDocumentContentChangeEventImpl
import io.typefox.lsapi.TextDocumentIdentifierImpl
import io.typefox.lsapi.TextDocumentItemImpl
import io.typefox.lsapi.TextDocumentPositionParamsImpl
import io.typefox.lsapi.TextEditImpl
import io.typefox.lsapi.VersionedTextDocumentIdentifierImpl
import io.typefox.lsapi.WorkspaceSymbolParamsImpl
import java.util.List
import io.typefox.lsapi.ParameterInformationImpl

/**
 * @author Sven Efftinge - Initial contribution and API
 */
class LsapiFactories {

	static def PositionImpl newPosition(int line, int character) {
		new PositionImpl => [
			it.line = line
			it.character = character
		]
	}

	static def PositionImpl copyPosition(Position position) {
		new PositionImpl => [
			it.line = position.line
			it.character = position.character
		]
	}

	static def RangeImpl newRange(PositionImpl start, PositionImpl end) {
		new RangeImpl => [
			it.start = start
			it.end = end
		]
	}

	static def RangeImpl copyRange(Range source) {
		new RangeImpl => [
			it.start = copyPosition(source.start)
			it.end = copyPosition(source.end)
		]
	}

	static def TextEditImpl newTextEdit(RangeImpl range, String newText) {
		new TextEditImpl => [
			it.range = range
			it.newText = newText
		]
	}

	static def TextDocumentIdentifierImpl newTextDocumentIdentifier(String uri) {
		val identifier = new TextDocumentIdentifierImpl
		identifier.uri = uri
		return identifier
	}

	static def VersionedTextDocumentIdentifierImpl newVersionedTextDocumentIdentifier(String uri, int version) {
		val identifier = new VersionedTextDocumentIdentifierImpl
		identifier.uri = uri
		identifier.version = version
		return identifier
	}

	static def TextDocumentItemImpl newTextDocumentItem(String uri, String languageId, int version, String text) {
		val item = new TextDocumentItemImpl
		item.uri = uri
		item.languageId = languageId
		item.version = version
		item.text = text
		return item
	}

	static def FileEventImpl newFileEvent(String uri, int type) {
		val fileEvent = new FileEventImpl
		fileEvent.uri = uri
		fileEvent.type = type
		return fileEvent
	}

	static def TextDocumentContentChangeEventImpl newTextDocumentContentChangeEvent(RangeImpl range,
		Integer rangeLength, String text) {
		val changeEvent = new TextDocumentContentChangeEventImpl
		changeEvent.range = range
		changeEvent.rangeLength = rangeLength
		changeEvent.text = text
		return changeEvent
	}

	static def InitializeParamsImpl newInitializeParams(int processId, String rootPath) {
		val params = new InitializeParamsImpl
		params.processId = processId
		params.rootPath = rootPath
		return params
	}

	protected static def void initialize(TextDocumentPositionParamsImpl params, String uri, int line, int column) {
		params.textDocument = uri.newTextDocumentIdentifier
		params.position = newPosition(line, column)
	}

	static def TextDocumentPositionParamsImpl newTextDocumentPositionParams(String uri, int line, int column) {
		val params = new TextDocumentPositionParamsImpl
		params.initialize(uri, line, column)
		return params
	}

	static def DocumentSymbolParamsImpl newDocumentSymbolParams(String uri) {
		val params = new DocumentSymbolParamsImpl
		params.textDocument = uri.newTextDocumentIdentifier
		return params
	}

	static def WorkspaceSymbolParamsImpl newWorkspaceSymbolParams(String query) {
		val params = new WorkspaceSymbolParamsImpl
		params.query = query
		return params
	}

	static def ReferenceParamsImpl newReferenceParams(String uri, int line, int column, ReferenceContextImpl context) {
		val params = new ReferenceParamsImpl
		params.initialize(uri, line, column)
		params.context = context
		return params
	}

	static def DidOpenTextDocumentParamsImpl newDidOpenTextDocumentParams(String uri, String languageId, int version,
		String text) {
		val params = new DidOpenTextDocumentParamsImpl
		params.uri = uri
		params.textDocument = newTextDocumentItem(uri, languageId, version, text)
		return params
	}

	static def DidCloseTextDocumentParamsImpl newDidCloseTextDocumentParams(String uri) {
		val params = new DidCloseTextDocumentParamsImpl
		params.textDocument = uri.newTextDocumentIdentifier
		return params
	}

	static def DidChangeWatchedFilesParamsImpl newDidChangeWatchedFilesParams(List<FileEventImpl> changes) {
		val params = new DidChangeWatchedFilesParamsImpl
		params.changes = changes
		return params
	}

	static def DidChangeTextDocumentParamsImpl newDidChangeTextDocumentParamsImpl(String uri, int version,
		List<TextDocumentContentChangeEventImpl> contentChanges) {
		val params = new DidChangeTextDocumentParamsImpl
		params.textDocument = newVersionedTextDocumentIdentifier(uri, version)
		params.contentChanges = contentChanges
		return params
	}

	static def MarkedStringImpl newMarkedString(String value, String language) {
		val markedString = new MarkedStringImpl
		markedString.value = value
		markedString.language = language
		return markedString
	}

	static def HoverImpl emptyHover() {
		return newHover(emptyList, null)
	}

	static def HoverImpl newHover(List<MarkedStringImpl> contents, RangeImpl range) {
		val hover = new HoverImpl
		hover.contents = contents
		hover.range = range
		return hover
	}

	static def SignatureHelpImpl emptySignatureHelp() {
		return newSignatureHelp(emptyList, null, null)
	}

	static def SignatureHelpImpl newSignatureHelp(List<SignatureInformationImpl> signatures, Integer activeSignature,
		Integer activeParameter) {
		val signatureHelp = new SignatureHelpImpl
		signatureHelp.signatures = signatures
		signatureHelp.activeSignature = activeSignature
		signatureHelp.activeParameter = activeParameter
		return signatureHelp
	}

	static def SignatureInformationImpl newSignatureInformation(String label, String documentation,
		List<ParameterInformationImpl> parameters) {
		val signatureInformation = new SignatureInformationImpl
		signatureInformation.label = label
		signatureInformation.documentation = documentation
		signatureInformation.parameters = parameters
		return signatureInformation
	}

	static def ParameterInformationImpl newParameterInformation(String label, String documentation) {
		val parameterInformation = new ParameterInformationImpl
		parameterInformation.label = label
		parameterInformation.documentation = documentation
		return parameterInformation
	}

}
