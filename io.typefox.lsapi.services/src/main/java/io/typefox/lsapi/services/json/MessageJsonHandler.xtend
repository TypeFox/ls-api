/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.json

import com.google.common.collect.Lists
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import io.typefox.lsapi.CancelParamsImpl
import io.typefox.lsapi.CodeActionParamsImpl
import io.typefox.lsapi.CodeLensImpl
import io.typefox.lsapi.CodeLensParamsImpl
import io.typefox.lsapi.CommandImpl
import io.typefox.lsapi.CompletionItemImpl
import io.typefox.lsapi.CompletionListImpl
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

class MessageJsonHandler {
	
	static val REQUEST_PARAM_TYPES = #{
		MessageMethods.INITIALIZE -> InitializeParamsImpl,
		MessageMethods.DOC_COMPLETION -> TextDocumentPositionParamsImpl,
		MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		MessageMethods.DOC_HOVER -> TextDocumentPositionParamsImpl,
		MessageMethods.DOC_SIGNATURE_HELP -> TextDocumentPositionParamsImpl,
		MessageMethods.DOC_DEFINITION -> TextDocumentPositionParamsImpl,
		MessageMethods.DOC_HIGHLIGHT -> TextDocumentPositionParamsImpl,
		MessageMethods.DOC_REFERENCES -> ReferenceParamsImpl,
		MessageMethods.DOC_SYMBOL -> DocumentSymbolParamsImpl,
		MessageMethods.WORKSPACE_SYMBOL -> WorkspaceSymbolParamsImpl,
		MessageMethods.DOC_CODE_ACTION -> CodeActionParamsImpl,
		MessageMethods.DOC_CODE_LENS -> CodeLensParamsImpl,
		MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		MessageMethods.DOC_FORMATTING -> DocumentFormattingParamsImpl,
		MessageMethods.DOC_RANGE_FORMATTING -> DocumentRangeFormattingParamsImpl,
		MessageMethods.DOC_TYPE_FORMATTING -> DocumentOnTypeFormattingParamsImpl,
		MessageMethods.DOC_RENAME -> RenameParamsImpl,
		MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl
	}
	
	static val RESPONSE_RESULT_TYPES = #{
		MessageMethods.INITIALIZE -> InitializeResultImpl,
		MessageMethods.DOC_COMPLETION -> CompletionListImpl,
		MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		MessageMethods.DOC_HOVER -> HoverImpl,
		MessageMethods.DOC_SIGNATURE_HELP -> SignatureHelpImpl,
		MessageMethods.DOC_DEFINITION -> LocationImpl,
		MessageMethods.DOC_HIGHLIGHT -> DocumentHighlightImpl,
		MessageMethods.DOC_REFERENCES -> LocationImpl,
		MessageMethods.DOC_SYMBOL -> SymbolInformationImpl,
		MessageMethods.WORKSPACE_SYMBOL -> SymbolInformationImpl,
		MessageMethods.DOC_CODE_ACTION -> CommandImpl,
		MessageMethods.DOC_CODE_LENS -> CodeLensImpl,
		MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		MessageMethods.DOC_FORMATTING -> TextEditImpl,
		MessageMethods.DOC_RANGE_FORMATTING -> TextEditImpl,
		MessageMethods.DOC_TYPE_FORMATTING -> TextEditImpl,
		MessageMethods.DOC_RENAME -> WorkspaceEditImpl
	}
	
	static val NOTIFICATION_PARAM_TYPES = #{
		MessageMethods.SHOW_DIAGNOSTICS -> PublishDiagnosticsParamsImpl,
		MessageMethods.DID_CHANGE_CONF -> DidChangeConfigurationParamsImpl,
		MessageMethods.DID_OPEN_DOC -> DidOpenTextDocumentParamsImpl,
		MessageMethods.DID_CHANGE_DOC -> DidChangeTextDocumentParamsImpl,
		MessageMethods.DID_CLOSE_DOC -> DidCloseTextDocumentParamsImpl,
		MessageMethods.DID_CHANGE_FILES -> DidChangeWatchedFilesParamsImpl,
		MessageMethods.DID_SAVE_DOC -> DidSaveTextDocumentParamsImpl,
		MessageMethods.SHOW_MESSAGE -> MessageParamsImpl,
		MessageMethods.LOG_MESSAGE -> MessageParamsImpl,
		MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl,
		MessageMethods.CANCEL -> CancelParamsImpl
	}
	
	val jsonParser = new JsonParser
	val Gson gson
	
	@Accessors(PUBLIC_SETTER)
	var (String)=>String responseMethodResolver
	
	new() {
		this.gson = new GsonBuilder().registerTypeAdapterFactory(new EnumTypeAdapterFactory).create()
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
			throw new IllegalStateException("Response methods are not accepted.")
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
