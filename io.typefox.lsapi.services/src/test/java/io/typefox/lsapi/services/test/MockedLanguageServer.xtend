/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import com.google.common.collect.HashMultimap
import com.google.common.collect.Multimap
import io.typefox.lsapi.CodeActionParams
import io.typefox.lsapi.CodeLens
import io.typefox.lsapi.CodeLensParams
import io.typefox.lsapi.CompletionItem
import io.typefox.lsapi.DidChangeConfigurationParams
import io.typefox.lsapi.DidChangeTextDocumentParams
import io.typefox.lsapi.DidChangeWatchedFilesParams
import io.typefox.lsapi.DidCloseTextDocumentParams
import io.typefox.lsapi.DidOpenTextDocumentParams
import io.typefox.lsapi.DidSaveTextDocumentParams
import io.typefox.lsapi.DocumentFormattingParams
import io.typefox.lsapi.DocumentOnTypeFormattingParams
import io.typefox.lsapi.DocumentRangeFormattingParams
import io.typefox.lsapi.DocumentSymbolParams
import io.typefox.lsapi.InitializeParams
import io.typefox.lsapi.InitializeResult
import io.typefox.lsapi.MessageParams
import io.typefox.lsapi.PublishDiagnosticsParams
import io.typefox.lsapi.ReferenceParams
import io.typefox.lsapi.RenameParams
import io.typefox.lsapi.ShowMessageRequestParams
import io.typefox.lsapi.TextDocumentPositionParams
import io.typefox.lsapi.WorkspaceSymbolParams
import io.typefox.lsapi.services.LanguageServer
import io.typefox.lsapi.services.TextDocumentService
import io.typefox.lsapi.services.WindowService
import io.typefox.lsapi.services.WorkspaceService
import io.typefox.lsapi.services.json.InvalidMessageException
import java.util.List
import java.util.concurrent.CompletableFuture
import java.util.function.Consumer
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class MockedLanguageServer implements LanguageServer {
	
	static class ForcedException extends InvalidMessageException {
		new(String message) {
			super(message)
		}
	}
	
	val textDocumentService = new MockedTextDocumentService(this)
	
	val windowService = new MockedWindowService
	
	val workspaceService = new MockedWorkspaceService(this)
	
	@Accessors
	val Multimap<String, Object> methodCalls = HashMultimap.create
	
	@Accessors(PUBLIC_SETTER)
	Object response
	
	@Accessors(PUBLIC_SETTER)
	boolean blockResponse
	
	@Accessors(PUBLIC_SETTER)
	String generateError
	
	protected def <T> CompletableFuture<T> getPromise() {
		if (generateError !== null) {
			CompletableFuture.supplyAsync[
				throw new ForcedException(generateError)
			]
		} else if (blockResponse) {
			CompletableFuture.supplyAsync[
				while (blockResponse) {
					Thread.sleep(100)
				}
				return response as T
			]
		} else {
			CompletableFuture.completedFuture(response as T)
		}
	}
	
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
		CompletableFuture.supplyAsync[response as InitializeResult]
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
		
		val List<Consumer<PublishDiagnosticsParams>> publishDiagnosticCallbacks = newArrayList
		
		override completion(TextDocumentPositionParams position) {
			server.methodCalls.put('completion', position)
			return server.promise
		}
		
		override resolveCompletionItem(CompletionItem unresolved) {
			server.methodCalls.put('resolveCompletionItem', unresolved)
			return server.promise
		}
		
		override hover(TextDocumentPositionParams position) {
			server.methodCalls.put('hover', position)
			return server.promise
		}
		
		override signatureHelp(TextDocumentPositionParams position) {
			server.methodCalls.put('signatureHelp', position)
			return server.promise
		}
		
		override definition(TextDocumentPositionParams position) {
			server.methodCalls.put('definition', position)
			return server.promise
		}
		
		override references(ReferenceParams params) {
			server.methodCalls.put('references', params)
			return server.promise
		}
		
		override documentHighlight(TextDocumentPositionParams position) {
			server.methodCalls.put('documentHighlight', position)
			return server.promise
		}
		
		override documentSymbol(DocumentSymbolParams params) {
			server.methodCalls.put('documentSymbol', params)
			return server.promise
		}
		
		override codeAction(CodeActionParams params) {
			server.methodCalls.put('codeAction', params)
			return server.promise
		}
		
		override codeLens(CodeLensParams params) {
			server.methodCalls.put('codeLens', params)
			return server.promise
		}
		
		override resolveCodeLens(CodeLens unresolved) {
			server.methodCalls.put('resolveCodeLens', unresolved)
			return server.promise
		}
		
		override formatting(DocumentFormattingParams params) {
			server.methodCalls.put('formatting', params)
			return server.promise
		}
		
		override rangeFormatting(DocumentRangeFormattingParams params) {
			server.methodCalls.put('rangeFormatting', params)
			return server.promise
		}
		
		override onTypeFormatting(DocumentOnTypeFormattingParams params) {
			server.methodCalls.put('onTypeFormatting', params)
			return server.promise
		}
		
		override rename(RenameParams params) {
			server.methodCalls.put('rename', params)
			return server.promise
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
		
		override onPublishDiagnostics(Consumer<PublishDiagnosticsParams> callback) {
			publishDiagnosticCallbacks.add(callback)
		}
		
		def void publishDiagnostics(PublishDiagnosticsParams params) {
			for (c : publishDiagnosticCallbacks) {
				c.accept(params)
			}
		}
		
	}
	
	static class MockedWindowService implements WindowService {
		
		val List<Consumer<MessageParams>> showMessageCallbacks = newArrayList
		
		val List<Consumer<ShowMessageRequestParams>> showMessageRequestCallbacks = newArrayList
		
		val List<Consumer<MessageParams>> logMessageCallbacks = newArrayList
		
		override onShowMessage(Consumer<MessageParams> callback) {
			showMessageCallbacks.add(callback)
		}
		
		def void showMessage(MessageParams params) {
			for (c : showMessageCallbacks) {
				c.accept(params)
			}
		}
		
		override onShowMessageRequest(Consumer<ShowMessageRequestParams> callback) {
			showMessageRequestCallbacks.add(callback)
		}
		
		def void showMessageRequest(ShowMessageRequestParams params) {
			for (c : showMessageRequestCallbacks) {
				c.accept(params)
			}
		}
		
		override onLogMessage(Consumer<MessageParams> callback) {
			logMessageCallbacks.add(callback)
		}
		
		def void logMessage(MessageParams params) {
			for (c : logMessageCallbacks) {
				c.accept(params)
			}
		}
		
	}
	
	@FinalFieldsConstructor
	static class MockedWorkspaceService implements WorkspaceService {
		
		val MockedLanguageServer server
		
		override symbol(WorkspaceSymbolParams params) {
			server.methodCalls.put('symbol', params)
			return server.promise
		}
		
		override didChangeConfiguraton(DidChangeConfigurationParams params) {
			server.methodCalls.put('didChangeConfiguraton', params)
		}
		
		override didChangeWatchedFiles(DidChangeWatchedFilesParams params) {
			server.methodCalls.put('didChangeWatchedFiles', params)
		}
		
	}
	
}