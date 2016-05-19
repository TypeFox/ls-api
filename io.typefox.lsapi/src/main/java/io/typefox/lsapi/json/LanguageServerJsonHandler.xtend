/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import com.google.common.collect.Lists
import com.google.gson.Gson
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import io.typefox.lsapi.CodeActionParamsImpl
import io.typefox.lsapi.CodeLensImpl
import io.typefox.lsapi.CodeLensParamsImpl
import io.typefox.lsapi.CommandImpl
import io.typefox.lsapi.CompletionItemImpl
import io.typefox.lsapi.DidChangeConfigurationParamsImpl
import io.typefox.lsapi.DidChangeTextDocumentParamsImpl
import io.typefox.lsapi.DidChangeWatchedFilesParamsImpl
import io.typefox.lsapi.DidCloseTextDocumentParamsImpl
import io.typefox.lsapi.DidOpenTextDocumentParamsImpl
import io.typefox.lsapi.DidSaveTextDocumentParamsImpl
import io.typefox.lsapi.DocumentFormattingParamsImpl
import io.typefox.lsapi.DocumentHighlightImpl
import io.typefox.lsapi.DocumentOnTypeFormattingParamsImpl
import io.typefox.lsapi.DocumentRangeFormattingParamsImpl
import io.typefox.lsapi.DocumentSymbolParamsImpl
import io.typefox.lsapi.HoverImpl
import io.typefox.lsapi.InitializeParamsImpl
import io.typefox.lsapi.InitializeResultImpl
import io.typefox.lsapi.LocationImpl
import io.typefox.lsapi.Message
import io.typefox.lsapi.MessageImpl
import io.typefox.lsapi.MessageParamsImpl
import io.typefox.lsapi.NotificationMessageImpl
import io.typefox.lsapi.PublishDiagnosticsParamsImpl
import io.typefox.lsapi.ReferenceParamsImpl
import io.typefox.lsapi.RenameParamsImpl
import io.typefox.lsapi.RequestMessageImpl
import io.typefox.lsapi.ResponseErrorImpl
import io.typefox.lsapi.ResponseMessageImpl
import io.typefox.lsapi.ShowMessageRequestParamsImpl
import io.typefox.lsapi.SignatureHelpImpl
import io.typefox.lsapi.SymbolInformationImpl
import io.typefox.lsapi.TextDocumentPositionParamsImpl
import io.typefox.lsapi.TextEditImpl
import io.typefox.lsapi.WorkspaceEditImpl
import io.typefox.lsapi.WorkspaceSymbolParamsImpl
import java.io.Reader
import java.io.StringReader
import java.io.StringWriter
import java.io.Writer
import org.eclipse.xtend.lib.annotations.Accessors

class LanguageServerJsonHandler {
	
	static val REQUEST_PARAM_TYPES = #{
		'initialize' -> InitializeParamsImpl,
		'textDocument/completion' -> TextDocumentPositionParamsImpl,
		'completionItem/resolve' -> CompletionItemImpl,
		'textDocument/hover' -> TextDocumentPositionParamsImpl,
		'textDocument/signatureHelp' -> TextDocumentPositionParamsImpl,
		'textDocument/definition' -> TextDocumentPositionParamsImpl,
		'textDocument/documentHighlight' -> TextDocumentPositionParamsImpl,
		'textDocument/references' -> ReferenceParamsImpl,
		'textDocument/documentSymbol' -> DocumentSymbolParamsImpl,
		'workspace/symbol' -> WorkspaceSymbolParamsImpl,
		'textDocument/codeAction' -> CodeActionParamsImpl,
		'textDocument/codeLens' -> CodeLensParamsImpl,
		'codeLens/resolve' -> CodeLensImpl,
		'textDocument/formatting' -> DocumentFormattingParamsImpl,
		'textDocument/rangeFormatting' -> DocumentRangeFormattingParamsImpl,
		'textDocument/onTypeFormatting' -> DocumentOnTypeFormattingParamsImpl,
		'textDocument/rename' -> RenameParamsImpl,
		'window/showMessageRequest' -> ShowMessageRequestParamsImpl
	}
	
	static val RESPONSE_RESULT_TYPES = #{
		'initialize' -> InitializeResultImpl,
		'textDocument/completion' -> CompletionItemImpl,
		'completionItem/resolve' -> CompletionItemImpl,
		'textDocument/hover' -> HoverImpl,
		'textDocument/signatureHelp' -> SignatureHelpImpl,
		'textDocument/definition' -> LocationImpl,
		'textDocument/documentHighlight' -> DocumentHighlightImpl,
		'textDocument/documentSymbol' -> SymbolInformationImpl,
		'workspace/symbol' -> SymbolInformationImpl,
		'textDocument/codeAction' -> CommandImpl,
		'textDocument/codeLens' -> CodeLensImpl,
		'codeLens/resolve' -> CodeLensImpl,
		'textDocument/formatting' -> TextEditImpl,
		'textDocument/rangeFormatting' -> TextEditImpl,
		'textDocument/onTypeFormatting' -> TextEditImpl,
		'textDocument/rename' -> WorkspaceEditImpl
	}
	
	static val NOTIFICATION_PARAM_TYPES = #{
		'textDocument/publishDiagnostics' -> PublishDiagnosticsParamsImpl,
		'workspace/didChangeConfiguration' -> DidChangeConfigurationParamsImpl,
		'textDocument/didOpen' -> DidOpenTextDocumentParamsImpl,
		'textDocument/didChange' -> DidChangeTextDocumentParamsImpl,
		'textDocument/didClose' -> DidCloseTextDocumentParamsImpl,
		'workspace/didChangeWatchedFiles' -> DidChangeWatchedFilesParamsImpl,
		'textDocument/didSave' -> DidSaveTextDocumentParamsImpl,
		'window/showMessage' -> MessageParamsImpl,
		'window/logMessage' -> MessageParamsImpl
	}
	
	val jsonParser = new JsonParser
	val Gson gson
	
	@Accessors(PUBLIC_SETTER)
	var (String)=>String responseMethodResolver
	
	new() {
		this.gson = new Gson
	}
	
	new(Gson gson) {
		this.gson = gson
	}
	
	def Message parseMessage(CharSequence input) {
		parseMessage(new StringReader(input.toString))
	}
	
	def Message parseMessage(Reader input) {
		val json = jsonParser.parse(input).asJsonObject
		val idElement = json.get('id')
		val methodElement = json.get('method')
		var MessageImpl result
		if (idElement !== null && methodElement !== null)
			result = parseRequest(json, idElement.asString, methodElement.asString)
		else if (idElement !== null && (json.get('result') !== null || json.get('error') !== null))
			result = parseResponse(json, idElement.asString)
		else if (methodElement !== null)
			result = parseNotification(json, methodElement.asString)
		else
			result = new MessageImpl
		result.jsonrpc = json.get('jsonrpc')?.asString
		return result
	}
	
	protected def RequestMessageImpl parseRequest(JsonObject json, String requestId, String method) {
		try {
			val result = new RequestMessageImpl
			result.id = requestId
			result.method = method
			val params = json.get('params')?.asJsonObject
			if (params !== null) {
				val paramType = REQUEST_PARAM_TYPES.get(method)
				if (paramType !== null)
					result.params = gson.fromJson(params, paramType)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse request: " + e.message, requestId, e)
		}
	}
	
	protected def ResponseMessageImpl parseResponse(JsonObject json, String responseId) {
		if (responseMethodResolver === null)
			throw new IllegalStateException("No response method resolver has been configured.")
		try {
			val result = new ResponseMessageImpl
			result.id = responseId
			val resultElem = json.get('result')
			if (resultElem !== null) {
				val method = responseMethodResolver.apply(responseId)
				if (method !== null) {
					val resultType = RESPONSE_RESULT_TYPES.get(method)
					if (resultType !== null) {
						if (resultElem.isJsonArray) {
							val arrayElem = resultElem.asJsonArray
							val list = Lists.newArrayListWithExpectedSize(arrayElem.size)
							for (e : arrayElem) {
								list += gson.fromJson(e, resultType)
							}
							result.result = list
						} else {
							result.result = gson.fromJson(resultElem, resultType)
						}
					}
				}
			} else {
				val error = json.get('error')?.asJsonObject
				if (error !== null)
					result.error = gson.fromJson(error, ResponseErrorImpl)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse response: " + e.message, responseId, e)
		}
	}
	
	protected def NotificationMessageImpl parseNotification(JsonObject json, String method) {
		try {
			val result = new NotificationMessageImpl
			result.method = method
			val params = json.get('params')?.asJsonObject
			if (params !== null) {
				val paramType = NOTIFICATION_PARAM_TYPES.get(method)
				if (paramType !== null)
					result.params = gson.fromJson(params, paramType)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse notification: " + e.message, null, e)
		}
	}
	
	def String serialize(Message message) {
		val writer = new StringWriter
		serialize(message, writer)
		return writer.toString
	}
	
	def void serialize(Message message, Writer output) {
		gson.toJson(message, output)
	}
	
}
