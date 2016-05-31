/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import io.typefox.lsapi.DidOpenTextDocumentParamsImpl
import io.typefox.lsapi.InitializeParamsImpl
import io.typefox.lsapi.PositionImpl
import io.typefox.lsapi.TextDocumentIdentifierImpl
import io.typefox.lsapi.TextDocumentItemImpl
import io.typefox.lsapi.TextDocumentPositionParamsImpl
import io.typefox.lsapi.services.json.JsonBasedLanguageServer
import io.typefox.lsapi.services.json.LanguageServerProtocol
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import org.junit.After
import org.junit.Before
import org.junit.Test

import static org.junit.Assert.*

class JsonBasedLanguageServerTest {
	
	static val TIMEOUT = 2000
	
	JsonBasedLanguageServer server
	OutputStream serverInput
	ByteArrayOutputStream serverOutput
	
	@Before
	def void setup() {
		val pipe = new PipedInputStream
		serverOutput = new ByteArrayOutputStream
		server = new JsonBasedLanguageServer
		serverInput = new PipedOutputStream(pipe)
		server.connect(pipe, serverOutput)
		server.onError[ message, t |
			if (t !== null)
				t.printStackTrace()
			else if (message !== null)
				System.err.println(message)
		]
		server.start()
	}
	
	@After
	def void teardown() {
		server.exit()
	}
	
	protected def void waitForOutput(int startSize) {
		val startTime = System.currentTimeMillis
		while (serverOutput.size <= startSize) {
			Thread.sleep(10)
			assertTrue(System.currentTimeMillis - startTime < TIMEOUT)
		}
	}
	
	protected def void writeMessage(String content) {
		val responseBytes = content.bytes
		val headerBuilder = new StringBuilder
		headerBuilder.append(LanguageServerProtocol.H_CONTENT_LENGTH).append(': ').append(responseBytes.length).append('\r\n\r\n')
		serverInput.write(headerBuilder.toString.bytes)
		serverInput.write(responseBytes)
		serverInput.flush()
	}
	
	protected def assertOutput(String expected) {
		assertEquals(expected.trim, serverOutput.toString.replace('\r', ''))
	}
	
	protected def assertResult(Object result, String expected) {
		assertNotNull(result)
		assertEquals(expected.trim, result.toString)
	}
	
	@Test
	def void testInitialize() {
		val future = server.initialize(new InitializeParamsImpl => [
			rootPath = 'file:///tmp/'
		])
		waitForOutput(0)
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"result": {
					"capabilities": {
						"completionProvider": {
							"resolveProvider": false
						},
						"textDocumentSync": 2
					}
				}
			}
		''')
		future.get(TIMEOUT, TimeUnit.MILLISECONDS).assertResult('''
			InitializeResultImpl [
			  capabilities = ServerCapabilitiesImpl [
			    textDocumentSync = 2
			    hoverProvider = null
			    completionProvider = CompletionOptionsImpl [
			      resolveProvider = false
			      triggerCharacters = null
			    ]
			    signatureHelpProvider = null
			    definitionProvider = null
			    referencesProvider = null
			    documentHighlightProvider = null
			    documentSymbolProvider = null
			    workspaceSymbolProvider = null
			    codeActionProvider = null
			    codeLensProvider = null
			    documentFormattingProvider = null
			    documentRangeFormattingProvider = null
			    documentOnTypeFormattingProvider = null
			    renameProvider = null
			  ]
			  supportedLanguages = null
			]
		''')
		assertOutput('''
			Content-Length: 99
			
			{"id":"0","method":"initialize","params":{"processId":0,"rootPath":"file:///tmp/"},"jsonrpc":"2.0"}
		''')
	}
	
	@Test
	def void testDidOpen() {
		server.initialize(new InitializeParamsImpl)
		waitForOutput(0)
		val initReqSize = serverOutput.size
		writeMessage('''{"jsonrpc":"2.0","id":"0","result":{"capabilities":{"textDocumentSync":2}}}''')
		server.textDocumentService.didOpen(new DidOpenTextDocumentParamsImpl => [
			textDocument = new TextDocumentItemImpl => [
				uri = "file:///tmp/foo"
				text = "bla bla"
			]
		])
		waitForOutput(initReqSize)
		assertOutput('''
			Content-Length: 73
			
			{"id":"0","method":"initialize","params":{"processId":0},"jsonrpc":"2.0"}Content-Length: 130
			
			{"method":"textDocument/didOpen","params":{"textDocument":{"uri":"file:///tmp/foo","version":0,"text":"bla bla"}},"jsonrpc":"2.0"}
		''')
	}
	
	@Test
	def void testCompletion() {
		val future = server.textDocumentService.completion(new TextDocumentPositionParamsImpl => [
			textDocument = new TextDocumentIdentifierImpl => [
				uri = "file:///tmp/foo"
			]
			position = new PositionImpl => [
				line = 4
				character = 7
			]
		])
		waitForOutput(0)
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"result": {
					"items": [
						{
							"detail": "State",
							"insertText": "bar",
							"label": "bar"
						},
						{
							"detail": "State",
							"insertText": "foo",
							"label": "foo"
						}
					]
				}
			}
		''')
		future.get(TIMEOUT, TimeUnit.MILLISECONDS).assertResult('''
			CompletionListImpl [
			  incomplete = false
			  items = ArrayList (
			    CompletionItemImpl [
			      label = "bar"
			      kind = null
			      detail = "State"
			      documentation = null
			      sortText = null
			      filterText = null
			      insertText = "bar"
			      textEdit = null
			      data = null
			    ],
			    CompletionItemImpl [
			      label = "foo"
			      kind = null
			      detail = "State"
			      documentation = null
			      sortText = null
			      filterText = null
			      insertText = "foo"
			      textEdit = null
			      data = null
			    ]
			  )
			]
		''')
		assertOutput('''
			Content-Length: 149
			
			{"id":"0","method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/foo"},"position":{"line":4,"character":7}},"jsonrpc":"2.0"}
		''')
	}
	
	@Test
	def void testInvertedCompletionResponses() {
		val future1 = server.textDocumentService.completion(new TextDocumentPositionParamsImpl => [
			textDocument = new TextDocumentIdentifierImpl => [
				uri = "file:///tmp/foo"
			]
			position = new PositionImpl => [
				line = 4
				character = 7
			]
		])
		val future2 = server.textDocumentService.completion(new TextDocumentPositionParamsImpl => [
			textDocument = new TextDocumentIdentifierImpl => [
				uri = "file:///tmp/foo"
			]
			position = new PositionImpl => [
				line = 5
				character = 3
			]
		])
		waitForOutput(0)
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "1",
				"result": {
					"items": [
						{
							"detail": "State",
							"insertText": "bar",
							"label": "bar"
						}
					]
				}
			}
		''')
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"result": {
					"items": [
						{
							"detail": "State",
							"insertText": "foo",
							"label": "foo"
						}
					]
				}
			}
		''')
		future1.get(TIMEOUT, TimeUnit.MILLISECONDS).assertResult('''
			CompletionListImpl [
			  incomplete = false
			  items = ArrayList (
			    CompletionItemImpl [
			      label = "foo"
			      kind = null
			      detail = "State"
			      documentation = null
			      sortText = null
			      filterText = null
			      insertText = "foo"
			      textEdit = null
			      data = null
			    ]
			  )
			]
		''')
		future2.get(TIMEOUT, TimeUnit.MILLISECONDS).assertResult('''
			CompletionListImpl [
			  incomplete = false
			  items = ArrayList (
			    CompletionItemImpl [
			      label = "bar"
			      kind = null
			      detail = "State"
			      documentation = null
			      sortText = null
			      filterText = null
			      insertText = "bar"
			      textEdit = null
			      data = null
			    ]
			  )
			]
		''')
	}
	
	@Test
	def void testPublishDiagnostics() {
		val diagnostics = new LinkedBlockingQueue
		server.textDocumentService.onPublishDiagnostics[
			diagnostics.add(it)
		]
		server.initialize(new InitializeParamsImpl)
		waitForOutput(0)
		writeMessage('''{"jsonrpc":"2.0","id":"0","result":{"capabilities":{"textDocumentSync":2}}}''')
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"method": "textDocument/publishDiagnostics",
				"params": {
					"diagnostics": [
						{
							"message": "Couldn\u0027t resolve reference to State \u0027bard\u0027.",
							"range": {
								"start": {
									"character": 22,
									"line": 4
								},
								"end": {
									"character": 26,
									"line": 4
								}
							},
							"severity": 1
						}
					],
					"uri": "file:///tmp/foo"
				}
			}
		''')
		diagnostics.poll(TIMEOUT, TimeUnit.MILLISECONDS).assertResult('''
			PublishDiagnosticsParamsImpl [
			  uri = "file:///tmp/foo"
			  diagnostics = ArrayList (
			    DiagnosticImpl [
			      range = RangeImpl [
			        start = PositionImpl [
			          line = 4
			          character = 22
			        ]
			        end = PositionImpl [
			          line = 4
			          character = 26
			        ]
			      ]
			      severity = 1
			      code = null
			      source = null
			      message = "Couldn't resolve reference to State 'bard'."
			    ]
			  )
			]
		''')
	}
	
	@Test
	def void testCancel() {
		val future = server.textDocumentService.completion(new TextDocumentPositionParamsImpl => [
			textDocument = new TextDocumentIdentifierImpl => [
				uri = "file:///tmp/foo"
			]
			position = new PositionImpl => [
				line = 4
				character = 7
			]
		])
		waitForOutput(0)
		val complReqSize = serverOutput.size
		future.cancel(true)
		waitForOutput(complReqSize)
		assertOutput('''
			Content-Length: 149
			
			{"id":"0","method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/foo"},"position":{"line":4,"character":7}},"jsonrpc":"2.0"}Content-Length: 64
			
			{"method":"$/cancelRequest","params":{"id":"0"},"jsonrpc":"2.0"}
		''')
	}
	
}