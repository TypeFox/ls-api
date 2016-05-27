/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.services.test

import com.google.gson.GsonBuilder
import io.typefox.lsapi.Diagnostic
import io.typefox.lsapi.DiagnosticImpl
import io.typefox.lsapi.DidChangeTextDocumentParamsImpl
import io.typefox.lsapi.Message
import io.typefox.lsapi.NotificationMessageImpl
import io.typefox.lsapi.PositionImpl
import io.typefox.lsapi.PublishDiagnosticsParamsImpl
import io.typefox.lsapi.RangeImpl
import io.typefox.lsapi.RequestMessageImpl
import io.typefox.lsapi.ResponseError
import io.typefox.lsapi.ResponseErrorImpl
import io.typefox.lsapi.ResponseMessageImpl
import io.typefox.lsapi.TextDocumentContentChangeEventImpl
import io.typefox.lsapi.TextDocumentIdentifierImpl
import io.typefox.lsapi.TextDocumentPositionParamsImpl
import io.typefox.lsapi.TextEditImpl
import io.typefox.lsapi.VersionedTextDocumentIdentifierImpl
import io.typefox.lsapi.WorkspaceEditImpl
import io.typefox.lsapi.services.json.MessageJsonHandler
import java.util.ArrayList
import java.util.HashMap
import org.junit.Assert
import org.junit.Before
import org.junit.Test

class JsonSerializeTest {
	
	MessageJsonHandler jsonHandler
	
	@Before
	def void setup() {
		val gsonBuilder = new GsonBuilder().setPrettyPrinting
		jsonHandler = new MessageJsonHandler(gsonBuilder.create())
	}
	
	private def assertSerialize(Message message, CharSequence expected) {
		Assert.assertEquals(expected.toString.trim, jsonHandler.serialize(message))
	}
	
	@Test
	def void testCompletion() {
		val message = new RequestMessageImpl => [
			jsonrpc = "2.0"
			id = "1"
			method = "textDocument/completion"
			params = new TextDocumentPositionParamsImpl => [
				textDocument = new TextDocumentIdentifierImpl => [
					uri = "file:///tmp/foo"
				]
				position = new PositionImpl => [
					line = 4
					character = 22
				]
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
			method = "textDocument/didChange"
			params = new DidChangeTextDocumentParamsImpl => [
				textDocument = new VersionedTextDocumentIdentifierImpl => [
					uri = "file:///tmp/foo"
				]
				contentChanges = new ArrayList => [
					add(new TextDocumentContentChangeEventImpl => [
						range = new RangeImpl => [
							start = new PositionImpl => [
								line = 7
								character = 12
							]
							end = new PositionImpl => [
								line = 8
								character = 16
							]
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
			method = "textDocument/publishDiagnostics"
			params = new PublishDiagnosticsParamsImpl => [
				uri = "file:///tmp/foo"
				diagnostics = new ArrayList => [
					add(new DiagnosticImpl => [
						range = new RangeImpl => [
							start = new PositionImpl => [
								line = 4
								character = 22
							]
							end = new PositionImpl => [
								line = 4
								character = 25
							]
						]
						severity = Diagnostic.SEVERITY_ERROR
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
					put("file:///tmp/foo", new TextEditImpl => [
						range = new RangeImpl => [
							start = new PositionImpl => [
								line = 4
								character = 22
							]
							end = new PositionImpl => [
								line = 4
								character = 25
							]
						]
						newText = "foobar"
					])
				]
			]
		]
		message.assertSerialize('''
			{
			  "id": "12",
			  "result": {
			    "changes": {
			      "file:///tmp/foo": {
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
				code = ResponseError.INVALID_REQUEST
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
	
}