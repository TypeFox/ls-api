/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.test

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import io.typefox.lsapi.CodeActionParams
import io.typefox.lsapi.CodeLens
import io.typefox.lsapi.CodeLensParams
import io.typefox.lsapi.Command
import io.typefox.lsapi.CompletionItem
import io.typefox.lsapi.DidChangeConfigurationParams
import io.typefox.lsapi.DidChangeTextDocumentParams
import io.typefox.lsapi.DidChangeWatchedFilesParams
import io.typefox.lsapi.DidCloseTextDocumentParams
import io.typefox.lsapi.DidOpenTextDocumentParams
import io.typefox.lsapi.DidSaveTextDocumentParams
import io.typefox.lsapi.DocumentFormattingParams
import io.typefox.lsapi.DocumentHighlight
import io.typefox.lsapi.DocumentOnTypeFormattingParams
import io.typefox.lsapi.DocumentRangeFormattingParams
import io.typefox.lsapi.DocumentSymbolParams
import io.typefox.lsapi.Hover
import io.typefox.lsapi.InitializeParams
import io.typefox.lsapi.InitializeResult
import io.typefox.lsapi.LanguageServer
import io.typefox.lsapi.Location
import io.typefox.lsapi.MessageParams
import io.typefox.lsapi.NotificationCallback
import io.typefox.lsapi.PublishDiagnosticsParams
import io.typefox.lsapi.ReferenceParams
import io.typefox.lsapi.RenameParams
import io.typefox.lsapi.ShowMessageRequestParams
import io.typefox.lsapi.SignatureHelp
import io.typefox.lsapi.SymbolInformation
import io.typefox.lsapi.TextDocumentPositionParams
import io.typefox.lsapi.TextDocumentService
import io.typefox.lsapi.TextEdit
import io.typefox.lsapi.WindowService
import io.typefox.lsapi.WorkspaceEdit
import io.typefox.lsapi.WorkspaceService
import io.typefox.lsapi.WorkspaceSymbolParams
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class MockedLanguageServer implements LanguageServer {
	
	val textDocumentService = new MockedTextDocumentService(this)
	
	val windowService = new MockedWindowService
	
	val workspaceService = new MockedWorkspaceService(this)
	
	@Accessors
	val Multimap<String, Object> methodCalls = HashMultimap.create
	
	@Accessors(PUBLIC_SETTER)
	Object response
	
	override MockedTextDocumentService getTextDocumentService() {
		textDocumentService
	}
	
	override MockedWindowService getWindowService() {
		windowService
	}
	
	override MockedWorkspaceService getWorkspaceService() {
		workspaceService
	}
	
	override initialize(InitializeParams params) {
		methodCalls.put('initialize', params)
		return response as InitializeResult
	}
	
	override shutdown() {
		methodCalls.put('shutdown', new Object)
	}
	
	override exit() {
		methodCalls.put('exit', new Object)
	}
	
	@FinalFieldsConstructor
	static class MockedTextDocumentService implements TextDocumentService {
		
		val MockedLanguageServer server
		
		val List<NotificationCallback<PublishDiagnosticsParams>> publishDiagnosticCallbacks = newArrayList
		
		override completion(TextDocumentPositionParams position) {
			server.methodCalls.put('completion', position)
			return server.response as List<? extends CompletionItem>
		}
		
		override resolveCompletionItem(CompletionItem unresolved) {
			server.methodCalls.put('resolveCompletionItem', unresolved)
			return server.response as CompletionItem
		}
		
		override hover(TextDocumentPositionParams position) {
			server.methodCalls.put('hover', position)
			return server.response as Hover
		}
		
		override signatureHelp(TextDocumentPositionParams position) {
			server.methodCalls.put('signatureHelp', position)
			return server.response as SignatureHelp
		}
		
		override definition(TextDocumentPositionParams position) {
			server.methodCalls.put('definition', position)
			return server.response as List<? extends Location>
		}
		
		override references(ReferenceParams params) {
			server.methodCalls.put('references', params)
			return server.response as List<? extends Location>
		}
		
		override documentHighlight(TextDocumentPositionParams position) {
			server.methodCalls.put('documentHighlight', position)
			return server.response as DocumentHighlight
		}
		
		override documentSymbol(DocumentSymbolParams params) {
			server.methodCalls.put('documentSymbol', params)
			return server.response as List<? extends SymbolInformation>
		}
		
		override codeAction(CodeActionParams params) {
			server.methodCalls.put('codeAction', params)
			return server.response as List<? extends Command>
		}
		
		override codeLens(CodeLensParams params) {
			server.methodCalls.put('codeLens', params)
			return server.response as List<? extends CodeLens>
		}
		
		override resolveCodeLens(CodeLens unresolved) {
			server.methodCalls.put('resolveCodeLens', unresolved)
			return server.response as CodeLens
		}
		
		override formatting(DocumentFormattingParams params) {
			server.methodCalls.put('formatting', params)
			return server.response as List<? extends TextEdit>
		}
		
		override rangeFormatting(DocumentRangeFormattingParams params) {
			server.methodCalls.put('rangeFormatting', params)
			return server.response as List<? extends TextEdit>
		}
		
		override onTypeFormatting(DocumentOnTypeFormattingParams params) {
			server.methodCalls.put('onTypeFormatting', params)
			return server.response as List<? extends TextEdit>
		}
		
		override rename(RenameParams params) {
			server.methodCalls.put('rename', params)
			return server.response as WorkspaceEdit
		}
		
		override didOpen(DidOpenTextDocumentParams params) {
			server.methodCalls.put('didOpen', params)
		}
		
		override didChange(DidChangeTextDocumentParams params) {
			server.methodCalls.put('didChange', params)
		}
		
		override didClose(DidCloseTextDocumentParams params) {
			server.methodCalls.put('didClose', params)
		}
		
		override didSave(DidSaveTextDocumentParams params) {
			server.methodCalls.put('didSave', params)
		}
		
		override onPublishDiagnostics(NotificationCallback<PublishDiagnosticsParams> callback) {
			publishDiagnosticCallbacks.add(callback)
		}
		
		def void publishDiagnostics(PublishDiagnosticsParams params) {
			for (c : publishDiagnosticCallbacks) {
				c.call(params)
			}
		}
		
	}
	
	static class MockedWindowService implements WindowService {
		
		val List<NotificationCallback<MessageParams>> showMessageCallbacks = newArrayList
		
		val List<NotificationCallback<ShowMessageRequestParams>> showMessageRequestCallbacks = newArrayList
		
		val List<NotificationCallback<MessageParams>> logMessageCallbacks = newArrayList
		
		override onShowMessage(NotificationCallback<MessageParams> callback) {
			showMessageCallbacks.add(callback)
		}
		
		def void showMessage(MessageParams params) {
			for (c : showMessageCallbacks) {
				c.call(params)
			}
		}
		
		override onShowMessageRequest(NotificationCallback<ShowMessageRequestParams> callback) {
			showMessageRequestCallbacks.add(callback)
		}
		
		def void showMessageRequest(ShowMessageRequestParams params) {
			for (c : showMessageRequestCallbacks) {
				c.call(params)
			}
		}
		
		override onLogMessage(NotificationCallback<MessageParams> callback) {
			logMessageCallbacks.add(callback)
		}
		
		def void logMessage(MessageParams params) {
			for (c : logMessageCallbacks) {
				c.call(params)
			}
		}
		
	}
	
	@FinalFieldsConstructor
	static class MockedWorkspaceService implements WorkspaceService {
		
		val MockedLanguageServer server
		
		override symbol(WorkspaceSymbolParams params) {
			server.methodCalls.put('symbol', params)
			return server.response as List<? extends SymbolInformation>
		}
		
		override didChangeConfiguraton(DidChangeConfigurationParams params) {
			server.methodCalls.put('didChangeConfiguraton', params)
		}
		
		override didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
			server.methodCalls.put('didChangeWatchedFiles', params)
		}
		
	}
	
}