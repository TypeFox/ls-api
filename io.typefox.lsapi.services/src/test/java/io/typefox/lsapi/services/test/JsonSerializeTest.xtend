/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import com.google.gson.GsonBuilder
import io.typefox.lsapi.DiagnosticSeverity
import io.typefox.lsapi.Message
import io.typefox.lsapi.ResponseErrorCode
import io.typefox.lsapi.builders.CompletionListBuilder
import io.typefox.lsapi.builders.DocumentFormattingParamsBuilder
import io.typefox.lsapi.builders.RequestMessageBuilder
import io.typefox.lsapi.builders.ResponseMessageBuilder
import io.typefox.lsapi.impl.DiagnosticImpl
import io.typefox.lsapi.impl.DidChangeTextDocumentParamsImpl
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
import io.typefox.lsapi.services.json.EnumTypeAdapterFactory
import io.typefox.lsapi.services.json.MessageJsonHandler
import io.typefox.lsapi.services.json.MessageMethods
import java.util.ArrayList
import java.util.HashMap
import org.junit.Assert
import org.junit.Before
import org.junit.Test

import static extension io.typefox.lsapi.services.test.LineEndings.*

class JsonSerializeTest {
	
	MessageJsonHandler jsonHandler
	
	@Before
	def void setup() {
		val gsonBuilder = new GsonBuilder().registerTypeAdapterFactory(new EnumTypeAdapterFactory).setPrettyPrinting
		jsonHandler = new MessageJsonHandler(gsonBuilder.create())
	}
	
	private def assertSerialize(Message message, CharSequence expected) {
		Assert.assertEquals(expected.toString.trim, jsonHandler.serialize(message).toSystemLineEndings)
	}
	
	@Test
	def void testCompletion() {
		val message = new RequestMessageImpl => [
			jsonrpc = "2.0"
			id = "1"
			method = MessageMethods.DOC_COMPLETION
			params = new TextDocumentPositionParamsImpl => [
				textDocument = new TextDocumentIdentifierImpl("file:///tmp/foo")
				position = new PositionImpl(4, 22)
			]
		]
		message.assertSerialize('''
			{
			  "id": "1",
			  "method": "textDocument/completion",
			  "params": {
			    "textDocument": {
			      "uri": "file:///tmp/foo"
			    },
			    "position": {
			      "line": 4,
			      "character": 22
			    }
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testDidChange() {
		val message = new NotificationMessageImpl => [
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
		]
		message.assertSerialize('''
			{
			  "method": "textDocument/didChange",
			  "params": {
			    "textDocument": {
			      "version": 0,
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
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testPublishDiagnostics() {
		val message = new NotificationMessageImpl => [
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
		]
		message.assertSerialize('''
			{
			  "method": "textDocument/publishDiagnostics",
			  "params": {
			    "uri": "file:///tmp/foo",
			    "diagnostics": [
			      {
			        "range": {
			          "start": {
			            "line": 4,
			            "character": 22
			          },
			          "end": {
			            "line": 4,
			            "character": 25
			          }
			        },
			        "severity": 1,
			        "message": "Couldn\u0027t resolve reference to State \u0027bar\u0027."
			      }
			    ]
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testRename() {
		val message = new ResponseMessageImpl => [
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
		]
		message.assertSerialize('''
			{
			  "id": "12",
			  "result": {
			    "changes": {
			      "file:///tmp/foo": [
			        {
			          "range": {
			            "start": {
			              "line": 3,
			              "character": 32
			            },
			            "end": {
			              "line": 3,
			              "character": 35
			            }
			          },
			          "newText": "foobar"
			        },
			        {
			          "range": {
			            "start": {
			              "line": 4,
			              "character": 22
			            },
			            "end": {
			              "line": 4,
			              "character": 25
			            }
			          },
			          "newText": "foobar"
			        }
			      ]
			    }
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testResponseError() {
		val message = new ResponseMessageImpl => [
			jsonrpc = "2.0"
			id = "12"
			error = new ResponseErrorImpl => [
				code = ResponseErrorCode.InvalidRequest
				message = "Could not parse request."
			]
		]
		message.assertSerialize('''
			{
			  "id": "12",
			  "error": {
			    "code": -32600,
			    "message": "Could not parse request."
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testBuildCompletionList() {
		val message = new ResponseMessageBuilder [
			jsonrpc("2.0")
			id("12")
			result(new CompletionListBuilder[
				incomplete(true)
			].build)
		].build
		message.assertSerialize('''
			{
			  "id": "12",
			  "result": {
			    "incomplete": true
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testBuildDocumentFormattingParams() {
		val message = new RequestMessageBuilder [
			jsonrpc("2.0")
			id("12")
			method(MessageMethods.DOC_FORMATTING)
			params(new DocumentFormattingParamsBuilder[
				textDocument[
					uri("file:///tmp/foo")
				]
				options[
					tabSize(4)
					insertSpaces(false)
				]
			].build)
		].build
		message.assertSerialize('''
			{
			  "id": "12",
			  "method": "textDocument/formatting",
			  "params": {
			    "textDocument": {
			      "uri": "file:///tmp/foo"
			    },
			    "options": {
			      "tabSize": 4,
			      "insertSpaces": false
			    }
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	@Test
	def void testTelemetry() {
		val message = new NotificationMessageImpl => [
			jsonrpc = "2.0"
			method = MessageMethods.TELEMETRY_EVENT
			params = new TestObject
		]
		message.assertSerialize('''
			{
			  "method": "telemetry/event",
			  "params": {
			    "foo": 12.3,
			    "bar": "qwertz"
			  },
			  "jsonrpc": "2.0"
			}
		''')
	}
	
	private static class TestObject {
		package double foo = 12.3
		package String bar = "qwertz"
	}
	
}