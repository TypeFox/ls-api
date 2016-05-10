/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi

import com.google.common.collect.Lists
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.JsonObject
import com.google.gson.JsonParser
import io.typefox.lsapi.annotations.LanguageServerAPI
import java.io.Reader
import java.io.StringReader
import java.io.StringWriter
import java.io.Writer
import java.lang.reflect.Method
import java.lang.reflect.ParameterizedType
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors

class LanguageServerJsonHandler {
	
	static val REQUEST_PARAM_TYPES = #{
		'initialize' -> InitializeParams,
		'textDocument/completion' -> TextDocumentPositionParams,
		'completionItem/resolve' -> CompletionItem,
		'textDocument/hover' -> TextDocumentPositionParams,
		'textDocument/signatureHelp' -> TextDocumentPositionParams,
		'textDocument/definition' -> TextDocumentPositionParams,
		'textDocument/documentHighlight' -> TextDocumentPositionParams,
		'textDocument/references' -> ReferenceParams,
		'textDocument/documentSymbol' -> DocumentSymbolParams,
		'workspace/symbol' -> WorkspaceSymbolParams,
		'textDocument/codeAction' -> CodeActionParams,
		'textDocument/codeLens' -> CodeLensParams,
		'codeLens/resolve' -> CodeLens,
		'textDocument/formatting' -> DocumentFormattingParams,
		'textDocument/rangeFormatting' -> DocumentRangeFormattingParams,
		'textDocument/onTypeFormatting' -> DocumentOnTypeFormattingParams,
		'textDocument/rename' -> RenameParams,
		'window/showMessageRequest' -> ShowMessageRequestParams
	}
	
	static val RESPONSE_RESULT_TYPES = #{
		'initialize' -> InitializeResult,
		'textDocument/completion' -> CompletionItem,
		'completionItem/resolve' -> CompletionItem,
		'textDocument/hover' -> Hover,
		'textDocument/signatureHelp' -> SignatureHelp,
		'textDocument/definition' -> Location,
		'textDocument/documentHighlight' -> DocumentHighlight,
		'textDocument/documentSymbol' -> SymbolInformation,
		'workspace/symbol' -> SymbolInformation,
		'textDocument/codeAction' -> Command,
		'textDocument/codeLens' -> CodeLens,
		'codeLens/resolve' -> CodeLens,
		'textDocument/formatting' -> TextEdit,
		'textDocument/rangeFormatting' -> TextEdit,
		'textDocument/onTypeFormatting' -> TextEdit,
		'textDocument/rename' -> WorkspaceEdit
	}
	
	static val NOTIFICATION_PARAM_TYPES = #{
		'textDocument/publishDiagnostics' -> PublishDiagnosticsParams,
		'workspace/didChangeConfiguration' -> DidChangeConfigurationParams,
		'textDocument/didOpen' -> DidOpenTextDocumentParams,
		'textDocument/didChange' -> DidChangeTextDocumentParams,
		'textDocument/didClose' -> DidCloseTextDocumentParams,
		'workspace/didChangeWatchedFiles' -> DidChangeWatchedFilesParams,
		'textDocument/didSave' -> DidSaveTextDocumentParams,
		'window/showMessage' -> MessageParams,
		'window/logMessage' -> MessageParams
	}
	
	val jsonParser = new JsonParser
	val Gson gson
	
	@Accessors(PUBLIC_SETTER)
	var (String)=>String responseMethodResolver
	
	new() {
		val gsonBuilder = new GsonBuilder()
		val visitedTypes = newHashSet
		gsonBuilder.registerAdapters(RequestMessage, visitedTypes)
		for (type : REQUEST_PARAM_TYPES.values) {
			gsonBuilder.registerAdapters(type, visitedTypes)
		}
		gsonBuilder.registerAdapters(ResponseMessage, visitedTypes)
		for (type : RESPONSE_RESULT_TYPES.values) {
			gsonBuilder.registerAdapters(type, visitedTypes)
		}
		gsonBuilder.registerAdapters(NotificationMessage, visitedTypes)
		for (type : NOTIFICATION_PARAM_TYPES.values) {
			gsonBuilder.registerAdapters(type, visitedTypes)
		}
		gson = gsonBuilder.create()
	}
	
	private def <T> void registerAdapters(GsonBuilder gsonBuilder, Class<T> type,
			Set<Class<?>> visitedTypes) {
		if (visitedTypes.add(type)) {
			val deserializer = new LanguageServerInterfaceDeserializer<T>
			val serializer = new LanguageServerInterfaceSerializer<T>
			gsonBuilder.registerTypeAdapter(type, deserializer)
			gsonBuilder.registerTypeAdapter(type, serializer)
			val implClass = Class.forName(type.name + 'Impl') as Class<? extends T>
			gsonBuilder.registerTypeAdapter(implClass, deserializer)
			gsonBuilder.registerTypeAdapter(implClass, serializer)
			
			for (method : type.methods) {
				val returnType = method.type
				if (returnType?.getAnnotation(LanguageServerAPI) !== null)
					registerAdapters(gsonBuilder, returnType, visitedTypes)
			}
		}
	}
	
	private def getType(Method method) {
		val genericType = method.genericReturnType
		if (genericType instanceof Class<?>)
			return genericType
		else if (genericType instanceof ParameterizedType) {
			if (method.returnType == List)
				return genericType.actualTypeArguments.get(0) as Class<?>
			else if (method.returnType == Map)
				return genericType.actualTypeArguments.get(1) as Class<?>
		}
	}
	
	def Message parseMessage(String input) {
		parseMessage(new StringReader(input))
	}
	
	def Message parseMessage(Reader input) {
		val json = jsonParser.parse(input).asJsonObject
		val idElement = json.get('id')
		val methodElement = json.get('method')
		val resultElement = json.get('result')
		if (idElement !== null && methodElement !== null)
			parseRequest(json, idElement.asString, methodElement.asString)
		else if (idElement !== null && resultElement !== null)
			parseResponse(json, idElement.asString)
		else if (methodElement !== null)
			parseNotification(json, methodElement.asString)
		else
			new MessageImpl
	}
	
	protected def RequestMessage parseRequest(JsonObject json, String requestId, String method) {
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
	
	protected def ResponseMessage parseResponse(JsonObject json, String responseId) {
		if (responseMethodResolver === null)
			throw new IllegalStateException("No response id resolver has been configured.")
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
					result.error = gson.fromJson(error, ResponseError)
			}
			return result
		} catch (Exception e) {
			throw new InvalidMessageException("Could not parse response: " + e.message, responseId, e)
		}
	}
	
	protected def NotificationMessage parseNotification(JsonObject json, String method) {
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
		switch message {
			RequestMessage:
				gson.toJson(message, RequestMessage, output)
			ResponseMessage:
				gson.toJson(message, ResponseMessage, output)
			NotificationMessage:
				gson.toJson(message, NotificationMessage, output)
			default:
				gson.toJson(message, output)
		}
	}
	
}
