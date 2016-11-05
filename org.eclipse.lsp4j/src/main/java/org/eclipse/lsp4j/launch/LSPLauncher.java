package org.eclipse.lsp4j.launch;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.util.concurrent.ExecutorService;
import java.util.function.Function;

import org.eclipse.lsp4j.jsonrpc.Launcher;
import org.eclipse.lsp4j.jsonrpc.MessageConsumer;
import org.eclipse.lsp4j.services.LanguageClient;
import org.eclipse.lsp4j.services.LanguageServer;

public class LSPLauncher {
	
	public static Launcher<LanguageClient> createServerLauncher(LanguageServer server, InputStream in, OutputStream out) {
		return Launcher.createLauncher(server, LanguageClient.class, in, out);
	}
	
	public static Launcher<LanguageClient> createServerLauncher(LanguageServer server, InputStream in, OutputStream out, boolean validate, PrintWriter trace) {
		return Launcher.createLauncher(server, LanguageClient.class, in, out, validate, trace);
	}
	
	public static Launcher<LanguageClient> createServerLauncher(LanguageServer server, InputStream in, OutputStream out, ExecutorService executorService, Function<MessageConsumer, MessageConsumer> wrapper) {
		return Launcher.createLauncher(server, LanguageClient.class, in, out, executorService, wrapper);
	}
	
	public static Launcher<LanguageServer> createClientLauncher(LanguageClient client, InputStream in, OutputStream out) {
		return Launcher.createLauncher(client, LanguageServer.class, in, out);
	}
	
	public static Launcher<LanguageServer> createClientLauncher(LanguageClient client, InputStream in, OutputStream out, boolean validate, PrintWriter trace) {
		return Launcher.createLauncher(client, LanguageServer.class, in, out, validate, trace);
	}
	
	public static Launcher<LanguageServer> createClientLauncher(LanguageClient client, InputStream in, OutputStream out, ExecutorService executorService, Function<MessageConsumer, MessageConsumer> wrapper) {
		return Launcher.createLauncher(client, LanguageServer.class, in, out, executorService, wrapper);
	}

}
