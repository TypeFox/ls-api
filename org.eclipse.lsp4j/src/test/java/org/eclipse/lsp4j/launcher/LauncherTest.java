package org.eclipse.lsp4j.launcher;

import java.io.IOException;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.eclipse.lsp4j.CompletionItem;
import org.eclipse.lsp4j.CompletionItemKind;
import org.eclipse.lsp4j.CompletionList;
import org.eclipse.lsp4j.MessageParams;
import org.eclipse.lsp4j.MessageType;
import org.eclipse.lsp4j.Position;
import org.eclipse.lsp4j.TextDocumentIdentifier;
import org.eclipse.lsp4j.TextDocumentPositionParams;
import org.eclipse.lsp4j.jsonrpc.Endpoint;
import org.eclipse.lsp4j.jsonrpc.Launcher;
import org.eclipse.lsp4j.jsonrpc.services.ServiceEndpoints;
import org.eclipse.lsp4j.launch.LSPLauncher;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.lsp4j.services.LanguageServer;
import org.eclipse.xtext.xbase.lib.Pair;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class LauncherTest {
	
	
	@Test public void testNotification() throws IOException {
		
		MessageParams p = new MessageParams();
		p.setMessage("Hello World");
		p.setType(MessageType.Info);
		
		client.expectedNotifications.put("window/logMessage", p);
		serverLauncher.getRemoteProxy().logMessage(p);
		client.joinOnEmpty();
	}
	
	@Test public void testRequest() throws IOException, InterruptedException, ExecutionException {
		
		TextDocumentPositionParams p = new TextDocumentPositionParams();
		p.setPosition(new Position(1,1));
		p.setTextDocument(new TextDocumentIdentifier("test/foo.txt"));
		
		CompletionList result = new CompletionList();
		result.setIsIncomplete(true);
		result.setItems(new ArrayList<>());
		
		CompletionItem item = new CompletionItem();
		item.setDetail("test");
		item.setDocumentation("doc");
		item.setFilterText("filter");
		item.setInsertText("insert");
		item.setKind(CompletionItemKind.Field);
		result.getItems().add(item);
		
		server.expectedRequests.put("textDocument/completion", new Pair<>(p, result));
		Assert.assertEquals(result.toString(), clientLauncher.getRemoteProxy().getTextDocumentService().completion(p).get().toString());
		client.joinOnEmpty();
	}
	
	
	static class AssertingEndpoint implements Endpoint {
		
		public Map<String, Pair<Object, Object>> expectedRequests = new LinkedHashMap<>();
		
		@Override
		public CompletableFuture<?> request(String method, Object parameter) {
			Assert.assertTrue(expectedRequests.containsKey(method));
			Pair<Object, Object> result = expectedRequests.remove(method);
			Assert.assertEquals(result.getKey().toString(), parameter.toString());
			return CompletableFuture.completedFuture(result.getValue());
		}

		public Map<String, Object> expectedNotifications = new LinkedHashMap<>();
		
		@Override
		public void notify(String method, Object parameter) {
			Assert.assertTrue(expectedNotifications.containsKey(method));
			Object object = expectedNotifications.remove(method);
			Assert.assertEquals(object.toString(), parameter.toString());
		}
		
		/**
		 * wait max 1 sec for all expectations to be removed
		 */
		public void joinOnEmpty() {
			long before = System.currentTimeMillis();
			do {
				if (expectedNotifications.isEmpty() && expectedNotifications.isEmpty()) {
					return;
				}
				try {
					Thread.sleep(100);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			} while ( System.currentTimeMillis() < before + 1000);
			Assert.fail("expectations weren't empty "+toString());
		}
		
		@Override
		public String toString() {
			return new ToStringBuilder(this).addAllFields().toString();
		}
		
	}

	private AssertingEndpoint server;
	private Launcher<LanguageClient> serverLauncher;
	private Future<?> serverListening;
	
	private AssertingEndpoint client;
	private Launcher<LanguageServer> clientLauncher;
	private Future<?> clientListening;
	
	@Before public void setup() throws IOException {
		PipedInputStream inClient = new PipedInputStream();
		PipedOutputStream outClient = new PipedOutputStream();
		PipedInputStream inServer = new PipedInputStream();
		PipedOutputStream outServer = new PipedOutputStream();
		
		inClient.connect(outServer);
		outClient.connect(inServer);
		server = new AssertingEndpoint();
		serverLauncher = LSPLauncher.createServerLauncher(ServiceEndpoints.toServiceObject(server, LanguageServer.class), inServer, outServer);
		serverListening = serverLauncher.startListening();
		
		client = new AssertingEndpoint();
		clientLauncher = LSPLauncher.createClientLauncher(ServiceEndpoints.toServiceObject(client, LanguageClient.class), inClient, outClient);
		clientListening = clientLauncher.startListening();
	}
	
	@After public void teardown() throws InterruptedException, ExecutionException {
		clientListening.cancel(true);
		serverListening.cancel(true);
	}

}
