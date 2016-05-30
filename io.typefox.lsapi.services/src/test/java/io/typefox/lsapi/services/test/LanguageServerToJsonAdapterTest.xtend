/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import io.typefox.lsapi.CompletionItemImpl
import io.typefox.lsapi.CompletionOptionsImpl
import io.typefox.lsapi.Diagnostic
import io.typefox.lsapi.DiagnosticImpl
import io.typefox.lsapi.InitializeResultImpl
import io.typefox.lsapi.PositionImpl
import io.typefox.lsapi.PublishDiagnosticsParamsImpl
import io.typefox.lsapi.RangeImpl
import io.typefox.lsapi.ServerCapabilitiesImpl
import io.typefox.lsapi.services.json.LanguageServerProtocol
import io.typefox.lsapi.services.json.LanguageServerToJsonAdapter
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.io.PipedInputStream
import java.io.PipedOutputStream
import org.junit.After
import org.junit.Before
import org.junit.Test

import static org.junit.Assert.*

class LanguageServerToJsonAdapterTest {
	
	static val TIMEOUT = 2000
	
	MockedLanguageServer mockedServer
	LanguageServerToJsonAdapter adapter
	OutputStream adapterInput
	ByteArrayOutputStream adapterOutput
	
	@Before
	def void setup() {
		mockedServer = new MockedLanguageServer
		val pipe = new PipedInputStream
		adapterOutput = new ByteArrayOutputStream
		adapter = new LanguageServerToJsonAdapter(mockedServer)
		adapterInput = new PipedOutputStream(pipe)
		adapter.connect(pipe, adapterOutput)
		adapter.protocol.addErrorListener[ message, t |
			if (!(t instanceof MockedLanguageServer.ForcedException)) {
				if (t !== null)
					t.printStackTrace()
				else if (message !== null)
					System.err.println(message)
			}
		]
		adapter.start()
	}
	
	@After
	def void teardown() {
		adapter.exit()
	}
	
	protected def void writeMessage(String content) {
		val responseBytes = content.bytes
		val headerBuilder = new StringBuilder
		headerBuilder.append(LanguageServerProtocol.H_CONTENT_LENGTH).append(': ').append(responseBytes.length).append('\r\n\r\n')
		adapterInput.write(headerBuilder.toString.bytes)
		adapterInput.write(responseBytes)
		adapterInput.flush()
	}
	
	protected def void assertOutput(String expected) {
		val startTime = System.currentTimeMillis
		val trimmed = expected.trim
		val targetSize = trimmed.bytes.length
		while (adapterOutput.size < targetSize) {
			Thread.sleep(10)
			assertTrue(System.currentTimeMillis - startTime < TIMEOUT)
		}
		assertEquals(trimmed, adapterOutput.toString.replace('\r', ''))
	}
	
	protected def void assertMethodCall(String method, String params) {
		val startTime = System.currentTimeMillis
		while (mockedServer.methodCalls.get(method).empty) {
			Thread.sleep(10)
			assertTrue(System.currentTimeMillis - startTime < TIMEOUT)
		}
		if (params !== null)
			assertEquals(params.trim, String.valueOf(mockedServer.methodCalls.get(method).head))
	}
	
	@Test
	def void testInitialize() {
		mockedServer.response = new InitializeResultImpl => [
			capabilities = new ServerCapabilitiesImpl => [
				completionProvider = new CompletionOptionsImpl => [
					resolveProvider = true
				]
			]
		]
		writeMessage('''
			{
				"jsonrpc":"2.0",
				"id": "0",
				"method": "initialize",
				"params": {
					"processId": 123,
					"rootPath": "file:///tmp/"
				}
			}
		''')
		assertOutput('''
			Content-Length: 100
			
			{"id":"0","result":{"capabilities":{"completionProvider":{"resolveProvider":true}}},"jsonrpc":"2.0"}
		''')
		assertMethodCall('initialize', '''
			InitializeParamsImpl [
			  processId = 123
			  rootPath = "file:///tmp/"
			  capabilities = null
			]
		''')
	}
	
	@Test
	def void testExit() {
		val startTime = System.currentTimeMillis
		while (!adapter.isActive) {
			Thread.sleep(10)
			assertTrue(System.currentTimeMillis - startTime < TIMEOUT)
		}
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"method": "exit"
			}
		''')
		while (adapter.isActive) {
			Thread.sleep(10)
			assertTrue(System.currentTimeMillis - startTime < TIMEOUT)
		}
	}
	
	@Test
	def void testDidOpen() {
		writeMessage('''
			{
				"jsonrpc":"2.0",
				"method": "textDocument/didOpen",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo",
						"text": "bla bla"
					}
				}
			}
		''')
		assertMethodCall('didOpen', '''
			DidOpenTextDocumentParamsImpl [
			  textDocument = TextDocumentItemImpl [
			    uri = "file:///tmp/foo"
			    languageId = null
			    version = 0
			    text = "bla bla"
			  ]
			  text = null
			]
		''')
	}
	
	@Test
	def void testCompletion() {
		mockedServer.response = newArrayList(
			new CompletionItemImpl => [
				insertText = "foo"
			],
			new CompletionItemImpl => [
				insertText = "bar"
			]
		)
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"position": {
						"line": 4,
						"character": 7
					}
				}
			}
		''')
		assertOutput('''
			Content-Length: 79
			
			{"id":"0","result":[{"insertText":"foo"},{"insertText":"bar"}],"jsonrpc":"2.0"}
		''')
		assertMethodCall('completion', '''
			TextDocumentPositionParamsImpl [
			  textDocument = TextDocumentIdentifierImpl [
			    uri = "file:///tmp/foo"
			  ]
			  uri = null
			  position = PositionImpl [
			    line = 4
			    character = 7
			  ]
			]
		''')
	}
	
	@Test
	def void testDelayedCompletion() {
		mockedServer.response = newArrayList(
			new CompletionItemImpl => [
				insertText = "foo"
			],
			new CompletionItemImpl => [
				insertText = "bar"
			]
		)
		mockedServer.blockResponse = true
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"position": {
						"line": 4,
						"character": 7
					}
				}
			}
		''')
		Thread.sleep(150)
		assertEquals('', adapterOutput.toString)
		mockedServer.blockResponse = false
		assertOutput('''
			Content-Length: 79
			
			{"id":"0","result":[{"insertText":"foo"},{"insertText":"bar"}],"jsonrpc":"2.0"}
		''')
	}
	
	@Test
	def void testPublishDiagnostics() {
		mockedServer.textDocumentService.publishDiagnostics(new PublishDiagnosticsParamsImpl => [
			diagnostics = newArrayList(
				new DiagnosticImpl => [
					range = new RangeImpl => [
						start = new PositionImpl => [
							line = 4
							character = 22
						]
						end = new PositionImpl => [
							line = 4
							character = 26
						]
					]
					severity = Diagnostic.SEVERITY_ERROR
					message = "Couldn't resolve reference to State 'bard'."
				]
			)
			uri = "file:///tmp/foo"
		])
		assertOutput('''
			Content-Length: 273
			
			{"method":"textDocument/publishDiagnostics","params":{"uri":"file:///tmp/foo","diagnostics":[{"range":{"start":{"line":4,"character":22},"end":{"line":4,"character":26}},"severity":1,"message":"Couldn\u0027t resolve reference to State \u0027bard\u0027."}]},"jsonrpc":"2.0"}
		''')
	}
	
	@Test
	def void testCancel() {
		mockedServer.response = 'dummy'
		mockedServer.blockResponse = true
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"position": {
						"line": 4,
						"character": 7
					}
				}
			}
		''')
		Thread.sleep(50)
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"method": "$/cancelRequest",
				"params": {
					"id": "0"
				}
			}
		''')
		Thread.sleep(150)
		assertEquals('', adapterOutput.toString)
		mockedServer.blockResponse = false
	}
	
	@Test
	def void testError() {
		mockedServer.generateError = 'Foo!'
		writeMessage('''
			{
				"jsonrpc": "2.0",
				"id": "0",
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"position": {
						"line": 4,
						"character": 7
					}
				}
			}
		''')
		assertOutput('''
			Content-Length: 67
			
			{"id":"0","error":{"code":-32600,"message":"Foo!"},"jsonrpc":"2.0"}
		''')
	}
	
}