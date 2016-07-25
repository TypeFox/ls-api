/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import io.typefox.lsapi.DiagnosticSeverity
import io.typefox.lsapi.Message
import io.typefox.lsapi.ResponseErrorCode
import io.typefox.lsapi.impl.DiagnosticImpl
import io.typefox.lsapi.impl.DidChangeTextDocumentParamsImpl
import io.typefox.lsapi.impl.HoverImpl
import io.typefox.lsapi.impl.MarkedStringImpl
import io.typefox.lsapi.impl.NotificationMessageImpl
import io.typefox.lsapi.impl.PositionImpl
import io.typefox.lsapi.impl.PublishDiagnosticsParamsImpl
import io.typefox.lsapi.impl.RangeImpl
import io.typefox.lsapi.impl.RequestMessageImpl
import io.typefox.lsapi.impl.ResponseErrorImpl
import io.typefox.lsapi.impl.ResponseMessageImpl
import io.typefox.lsapi.impl.TextDocumentContentChangeEventImpl
import io.typefox.lsapi.impl.TextDocumentIdentifierImpl
import io.typefox.lsapi.impl.TextDocumentPositionParamsImpl
import io.typefox.lsapi.impl.TextEditImpl
import io.typefox.lsapi.impl.VersionedTextDocumentIdentifierImpl
import io.typefox.lsapi.impl.WorkspaceEditImpl
import io.typefox.lsapi.services.json.InvalidMessageException
import io.typefox.lsapi.services.json.MessageJsonHandler
import io.typefox.lsapi.services.json.MessageMethods
import java.util.ArrayList
import java.util.HashMap
import org.junit.Before
import org.junit.Test

import static org.junit.Assert.*

import static extension io.typefox.lsapi.services.test.LineEndings.*

class JsonParseTest {
	
	MessageJsonHandler jsonHandler
	
	@Before
	def void setup() {
		jsonHandler = new MessageJsonHandler
	}
	
	private def void assertParse(CharSequence json, Message expected) {
		assertEquals(expected.toString, jsonHandler.parseMessage(json).toString)
	}
	
	private def void assertIssues(CharSequence json, CharSequence expectedIssues) {
		try {
			jsonHandler.parseMessage(json)
			fail('''Expected exception: «InvalidMessageException.name»''')
		} catch (InvalidMessageException e) {
			assertEquals(expectedIssues.toString, e.message.toSystemLineEndings)
		}
	}
	
	@Test
	def void testCompletion() {
		'''
			{
				"jsonrpc": "2.0",
				"id": 1,
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"position": {
						"line": 4,
						"character": 22
					}
				}
			}
		'''.assertParse(new RequestMessageImpl => [
			jsonrpc = "2.0"
			id = "1"
			method = MessageMethods.DOC_COMPLETION
			params = new TextDocumentPositionParamsImpl => [
				textDocument = new TextDocumentIdentifierImpl("file:///tmp/foo")
				position = new PositionImpl(4, 22)
			]
		])
	}
	
	@Test
	def void testDidChange() {
		'''
			{
				"jsonrpc": "2.0",
				"method": "textDocument/didChange",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					},
					"contentChanges": [
						{
							"range": {
								"start": {
									"line": 7,
									"character": 12
								},
								"end": {
									"line": 8,
									"character": 16
								}
							},
							"rangeLength": 20,
							"text": "bar"
						}
					]
				}
			}
		'''.assertParse(new NotificationMessageImpl => [
			jsonrpc = "2.0"
			method = MessageMethods.DID_CHANGE_DOC
			params = new DidChangeTextDocumentParamsImpl => [
				textDocument = new VersionedTextDocumentIdentifierImpl => [
					uri = "file:///tmp/foo"
				]
				contentChanges = new ArrayList => [
					add(new TextDocumentContentChangeEventImpl => [
						range = new RangeImpl => [
							start = new PositionImpl(7, 12)
							end = new PositionImpl(8, 16)
						]
						rangeLength = 20
						text = "bar"
					])
				]
			]
		])
	}
	
	@Test
	def void testPublishDiagnostics() {
		'''
			{
				"jsonrpc": "2.0",
				"method": "textDocument/publishDiagnostics",
				"params": {
					"uri": "file:///tmp/foo",
					"diagnostics": [
						{
							"message": "Couldn\u0027t resolve reference to State \u0027bar\u0027.",
							"range": {
								"start": {
									"character": 22,
									"line": 4
								},
								"end": {
									"character": 25,
									"line": 4
								}
							},
							"severity": 1
						}
					]
				}
			}
		'''.assertParse(new NotificationMessageImpl => [
			jsonrpc = "2.0"
			method = MessageMethods.SHOW_DIAGNOSTICS
			params = new PublishDiagnosticsParamsImpl => [
				uri = "file:///tmp/foo"
				diagnostics = new ArrayList => [
					add(new DiagnosticImpl => [
						range = new RangeImpl => [
							start = new PositionImpl(4, 22)
							end = new PositionImpl(4, 25)
						]
						severity = DiagnosticSeverity.Error
						message = "Couldn't resolve reference to State 'bar'."
					])
				]
			]
		])
	}
	
	@Test
	def void testRenameResponse() {
		jsonHandler.responseMethodResolver = [ id |
			switch id {
				case '12': MessageMethods.DOC_RENAME
			}
		]
		'''
			{
				"jsonrpc": "2.0",
				"id": "12",
				"result": {
					"changes": {
						"file:///tmp/foo": [
							{
								"range": {
									"start": {
										"character": 32,
										"line": 3
									},
									"end": {
										"character": 35,
										"line": 3
									}
								},
								"newText": "foobar"
							},
							{
								"range": {
									"start": {
										"character": 22,
										"line": 4
									},
									"end": {
										"character": 25,
										"line": 4
									}
								},
								"newText": "foobar"
							}
						]
					}
				}
			}
		'''.assertParse(new ResponseMessageImpl => [
			jsonrpc = "2.0"
			id = "12"
			result = new WorkspaceEditImpl => [
				changes = new HashMap => [
					put("file:///tmp/foo", newArrayList(
						new TextEditImpl => [
							range = new RangeImpl => [
								start = new PositionImpl(3, 32)
								end = new PositionImpl(3, 35)
							]
							newText = "foobar"
						],
						new TextEditImpl => [
							range = new RangeImpl => [
								start = new PositionImpl(4, 22)
								end = new PositionImpl(4, 25)
							]
							newText = "foobar"
						]
					))
				]
			]
		])
	}
	
	@Test
	def void testResponseError() {
		jsonHandler.responseMethodResolver = [ id |
			switch id {
				case '12':
					'textDocument/rename'
			}
		]
		'''
			{
				"jsonrpc": "2.0",
				"id": "12",
				"error": {
					code = -32600,
					message = "Could not parse request."
				}
			}
		'''.assertParse(new ResponseMessageImpl => [
			jsonrpc = "2.0"
			id = "12"
			error = new ResponseErrorImpl => [
				code = ResponseErrorCode.InvalidRequest
				message = "Could not parse request."
			]
		])
	}
	
	@Test
	def void testTelemetry() {
		'''
			{
				"jsonrpc": "2.0",
				"method": "telemetry/event",
				"params": {
					"foo": 12.3,
					"bar": "qwertz"
				}
			}
		'''.assertParse(new NotificationMessageImpl => [
			jsonrpc = "2.0"
			method = MessageMethods.TELEMETRY_EVENT
			params = newLinkedHashMap('foo' -> 12.3, 'bar' -> 'qwertz')
		])
	}
	
	@Test
	def void testHoverResponse() {
		jsonHandler.responseMethodResolver = [ id |
			switch id {
				case '12': MessageMethods.DOC_HOVER
			}
		]
		'''
			{
				"jsonrpc": "2.0",
				"id": "12",
				"result": {
					"range": {
						"start": {
							"character": 32,
							"line": 3
						},
						"end": {
							"character": 35,
							"line": 3
						}
					},
					"contents": {
						"language": "foolang",
						"value": "boo shuby doo"
					}
				}
			}
		'''.assertParse(new ResponseMessageImpl => [
			jsonrpc = "2.0"
			id = "12"
			result = new HoverImpl => [
				range = new RangeImpl => [
					start = new PositionImpl(3, 32)
					end = new PositionImpl(3, 35)
				]
				contents = newArrayList(new MarkedStringImpl("foolang", "boo shuby doo"))
			]
		])
	}
	
	@Test
	def void testInvalidCompletion() {
		'''
			{
				"jsonrpc": "2.0",
				"id": 1,
				"method": "textDocument/completion",
				"params": {
					"textDocument": {
						"uri": "file:///tmp/foo"
					}
				}
			}
		'''.assertIssues('''
			Error: The property 'position' must have a non-null value.
			The message was:
				{"jsonrpc":"2.0","id":1,"method":"textDocument/completion","params":{"textDocument":{"uri":"file:///tmp/foo"}}}
		''')
	}
	
}