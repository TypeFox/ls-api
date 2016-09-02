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
import io.typefox.lsapi.Message
import io.typefox.lsapi.RequestMessage
import io.typefox.lsapi.impl.CancelParamsImpl
import io.typefox.lsapi.impl.CodeActionParamsImpl
import io.typefox.lsapi.impl.CodeLensImpl
import io.typefox.lsapi.impl.CodeLensParamsImpl
import io.typefox.lsapi.impl.CommandImpl
import io.typefox.lsapi.impl.CompletionItemImpl
import io.typefox.lsapi.impl.CompletionListImpl
import io.typefox.lsapi.impl.DidChangeConfigurationParamsImpl
import io.typefox.lsapi.impl.DidChangeTextDocumentParamsImpl
import io.typefox.lsapi.impl.DidChangeWatchedFilesParamsImpl
import io.typefox.lsapi.impl.DidCloseTextDocumentParamsImpl
import io.typefox.lsapi.impl.DidOpenTextDocumentParamsImpl
import io.typefox.lsapi.impl.DidSaveTextDocumentParamsImpl
import io.typefox.lsapi.impl.DocumentFormattingParamsImpl
import io.typefox.lsapi.impl.DocumentHighlightImpl
import io.typefox.lsapi.impl.DocumentOnTypeFormattingParamsImpl
import io.typefox.lsapi.impl.DocumentRangeFormattingParamsImpl
import io.typefox.lsapi.impl.DocumentSymbolParamsImpl
import io.typefox.lsapi.impl.HoverImpl
import io.typefox.lsapi.impl.InitializeParamsImpl
import io.typefox.lsapi.impl.InitializeResultImpl
import io.typefox.lsapi.impl.LocationImpl
import io.typefox.lsapi.impl.MessageImpl
import io.typefox.lsapi.impl.MessageParamsImpl
import io.typefox.lsapi.impl.NotificationMessageImpl
import io.typefox.lsapi.impl.PublishDiagnosticsParamsImpl
import io.typefox.lsapi.impl.ReferenceParamsImpl
import io.typefox.lsapi.impl.RenameParamsImpl
import io.typefox.lsapi.impl.RequestMessageImpl
import io.typefox.lsapi.impl.ResponseErrorImpl
import io.typefox.lsapi.impl.ResponseMessageImpl
import io.typefox.lsapi.impl.ShowMessageRequestParamsImpl
import io.typefox.lsapi.impl.SignatureHelpImpl
import io.typefox.lsapi.impl.SymbolInformationImpl
import io.typefox.lsapi.impl.TextDocumentPositionParamsImpl
import io.typefox.lsapi.impl.TextEditImpl
import io.typefox.lsapi.impl.WorkspaceEditImpl
import io.typefox.lsapi.impl.WorkspaceSymbolParamsImpl
import io.typefox.lsapi.services.json.adapters.CollectionTypeAdapterFactory
import io.typefox.lsapi.services.json.adapters.EnumTypeAdapterFactory
import io.typefox.lsapi.services.json.adapters.MarkedStringTypeAdapterFactory
import io.typefox.lsapi.services.transport.client.MethodResolver
import io.typefox.lsapi.services.validation.IMessageValidator
import io.typefox.lsapi.services.validation.MessageIssue
import io.typefox.lsapi.services.validation.ReflectiveMessageValidator
import java.io.Reader
import java.io.StringReader
import java.io.StringWriter
import java.io.Writer
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class MessageJsonHandler {
	
	static val REQUEST_PARAM_TYPES = #{
		io.typefox.lsapi.services.transport.MessageMethods.INITIALIZE -> InitializeParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_COMPLETION -> TextDocumentPositionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_HOVER -> TextDocumentPositionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_SIGNATURE_HELP -> TextDocumentPositionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_DEFINITION -> TextDocumentPositionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_HIGHLIGHT -> TextDocumentPositionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_REFERENCES -> ReferenceParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_SYMBOL -> DocumentSymbolParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.WORKSPACE_SYMBOL -> WorkspaceSymbolParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_CODE_ACTION -> CodeActionParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_CODE_LENS -> CodeLensParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_FORMATTING -> DocumentFormattingParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_RANGE_FORMATTING -> DocumentRangeFormattingParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_TYPE_FORMATTING -> DocumentOnTypeFormattingParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_RENAME -> RenameParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl
	}
	
	static val RESPONSE_RESULT_TYPES = #{
		io.typefox.lsapi.services.transport.MessageMethods.INITIALIZE -> InitializeResultImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_COMPLETION -> CompletionListImpl,
		io.typefox.lsapi.services.transport.MessageMethods.RESOLVE_COMPLETION -> CompletionItemImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_HOVER -> HoverImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_SIGNATURE_HELP -> SignatureHelpImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_DEFINITION -> LocationImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_HIGHLIGHT -> DocumentHighlightImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_REFERENCES -> LocationImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_SYMBOL -> SymbolInformationImpl,
		io.typefox.lsapi.services.transport.MessageMethods.WORKSPACE_SYMBOL -> SymbolInformationImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_CODE_ACTION -> CommandImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_CODE_LENS -> CodeLensImpl,
		io.typefox.lsapi.services.transport.MessageMethods.RESOLVE_CODE_LENS -> CodeLensImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_FORMATTING -> TextEditImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_RANGE_FORMATTING -> TextEditImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_TYPE_FORMATTING -> TextEditImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DOC_RENAME -> WorkspaceEditImpl
	}
	
	static val NOTIFICATION_PARAM_TYPES = #{
		io.typefox.lsapi.services.transport.MessageMethods.SHOW_DIAGNOSTICS -> PublishDiagnosticsParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_CHANGE_CONF -> DidChangeConfigurationParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_OPEN_DOC -> DidOpenTextDocumentParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_CHANGE_DOC -> DidChangeTextDocumentParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_CLOSE_DOC -> DidCloseTextDocumentParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_CHANGE_FILES -> DidChangeWatchedFilesParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.DID_SAVE_DOC -> DidSaveTextDocumentParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.SHOW_MESSAGE -> MessageParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.LOG_MESSAGE -> MessageParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.SHOW_MESSAGE_REQUEST -> ShowMessageRequestParamsImpl,
		io.typefox.lsapi.services.transport.MessageMethods.CANCEL -> CancelParamsImpl
	}
	
	val jsonParser = new JsonParser
	val Gson gson
	val IMessageValidator messageValidator = new ReflectiveMessageValidator
	
	@Accessors(PUBLIC_SETTER)
    MethodResolver methodResolver
	
	@Accessors(PUBLIC_SETTER)
	var boolean validateMessages = true
	
	new() {
		this(defaultGsonBuilder.create)
	}
	
	new(Gson gson) {
		this.gson = gson
	}
    
	def static GsonBuilder getDefaultGsonBuilder() {
	    new GsonBuilder()
	    	.registerTypeAdapterFactory(new CollectionTypeAdapterFactory)
            .registerTypeAdapterFactory(new EnumTypeAdapterFactory)
            .registerTypeAdapterFactory(new MarkedStringTypeAdapterFactory)
	}
	
	@Deprecated
	def void setResponseMethodResolver((String)=>String responseMethodResolver) {
	    methodResolver = if (responseMethodResolver === null) null else [responseMethodResolver.apply(it)]
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
		if (validateMessages) {
			val issues = messageValidator.validate(result)
			if (!issues.empty)
				throw new InvalidMessageException(issuesToString(result, json, issues), idElement?.asString, null, json)
		}
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
				result.params = gson.fromJson(params, paramType ?: Object)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse request: " + e.message, requestId, e, json)
		}
	}
	
	protected def ResponseMessageImpl parseResponse(JsonObject json, String responseId) {
		if (methodResolver === null)
			throw new IllegalStateException("Response methods are not accepted.")
		try {
			val result = new ResponseMessageImpl
			result.id = responseId
			val resultElem = json.get('result')
			if (resultElem !== null) {
				val method = methodResolver.resolveMethod(responseId)
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
					} else {
						result.result = gson.fromJson(resultElem, Object)
					}
				}
			} else {
				val error = json.get('error')?.asJsonObject
				if (error !== null)
					result.error = gson.fromJson(error, ResponseErrorImpl)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse response: " + e.message, responseId, e, json)
		}
	}
	
	protected def NotificationMessageImpl parseNotification(JsonObject json, String method) {
		try {
			val result = new NotificationMessageImpl
			result.method = method
			val params = json.get('params')?.asJsonObject
			if (params !== null) {
				val paramType = NOTIFICATION_PARAM_TYPES.get(method)
				result.params = gson.fromJson(params, paramType ?: Object)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse notification: " + e.message, null, e, json)
		}
	}
	
	def String serialize(Message message) {
		val writer = new StringWriter
		serialize(message, writer)
		return writer.toString
	}
	
	def void serialize(Message message, Writer output) {
		if (validateMessages) {
			val issues = messageValidator.validate(message)
			if (!issues.empty)
				throw new io.typefox.lsapi.services.transport.InvalidMessageException(issuesToString(message, null, issues),
						if (message instanceof RequestMessage) message.id)
		}
		gson.toJson(message, output)
	}
	
	private def String issuesToString(Message message, JsonObject json, List<MessageIssue> issues) '''
		«FOR issue : issues»
			Error: «issue.text»
		«ENDFOR»
		The message was:
			«json ?: message»
	'''
	
}
