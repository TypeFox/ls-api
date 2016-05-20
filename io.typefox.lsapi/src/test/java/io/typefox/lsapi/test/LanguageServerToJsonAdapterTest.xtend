/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.test

import io.typefox.lsapi.CompletionOptionsImpl
import io.typefox.lsapi.InitializeResultImpl
import io.typefox.lsapi.ServerCapabilitiesImpl
import io.typefox.lsapi.json.LanguageServerProtocol
import io.typefox.lsapi.json.LanguageServerToJsonAdapter
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.io.PipedInputStream
import java.io.PipedOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.junit.After
import org.junit.Before
import org.junit.Test

import static org.junit.Assert.*

class LanguageServerToJsonAdapterTest {
	
	MockedLanguageServer mockedServer
	LanguageServerToJsonAdapter adapter
	OutputStream adapterInput
	ByteArrayOutputStream adapterOutput
	ExecutorService executorService
	
	@Before
	def void setup() {
		mockedServer = new MockedLanguageServer
		val pipe = new PipedInputStream
		adapterOutput = new ByteArrayOutputStream
		adapter = new LanguageServerToJsonAdapter(mockedServer, pipe, adapterOutput)
		adapterInput = new PipedOutputStream(pipe)
		executorService = Executors.newCachedThreadPool
		adapter.onError[ message, t |
			if (t !== null)
				t.printStackTrace()
			else if (message !== null)
				System.err.println(message)
		]
		adapter.start()
	}
	
	@After
	def void teardown() {
		adapter.stop()
	}
	
	protected def void writeMessage(String content) {
		val responseBytes = content.bytes
		val headerBuilder = new StringBuilder
		headerBuilder.append(LanguageServerProtocol.H_CONTENT_LENGTH).append(': ').append(responseBytes.length).append('\r\n\r\n')
		adapterInput.write(headerBuilder.toString.bytes)
		adapterInput.write(responseBytes)
	}
	
	protected def void assertOutput(String expected) {
		val trimmed = expected.trim
		val targetSize = trimmed.bytes.length
		while (adapterOutput.size < targetSize) {
			Thread.sleep(10)
		}
		assertEquals(trimmed, adapterOutput.toString.replace('\r', ''))
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
					"rootPath":"file:///tmp/"
				}
			}
		''')
		assertOutput('''
			Content-Length: 100
			
			{"id":"0","result":{"capabilities":{"completionProvider":{"resolveProvider":true}}},"jsonrpc":"2.0"}
		''')
		assertFalse(mockedServer.methodCalls.get('initialize').empty)
	}
	
}