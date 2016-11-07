/**
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */
package org.eclipse.lsp4j.services;

import java.util.List;
import java.util.concurrent.CompletableFuture;

import org.eclipse.lsp4j.CodeActionParams;
import org.eclipse.lsp4j.CodeLens;
import org.eclipse.lsp4j.CodeLensParams;
import org.eclipse.lsp4j.Command;
import org.eclipse.lsp4j.CompletionItem;
import org.eclipse.lsp4j.CompletionList;
import org.eclipse.lsp4j.DidChangeTextDocumentParams;
import org.eclipse.lsp4j.DidCloseTextDocumentParams;
import org.eclipse.lsp4j.DidOpenTextDocumentParams;
import org.eclipse.lsp4j.DidSaveTextDocumentParams;
import org.eclipse.lsp4j.DocumentFormattingParams;
import org.eclipse.lsp4j.DocumentHighlight;
import org.eclipse.lsp4j.DocumentOnTypeFormattingParams;
import org.eclipse.lsp4j.DocumentRangeFormattingParams;
import org.eclipse.lsp4j.DocumentSymbolParams;
import org.eclipse.lsp4j.Hover;
import org.eclipse.lsp4j.Location;
import org.eclipse.lsp4j.ReferenceParams;
import org.eclipse.lsp4j.RenameParams;
import org.eclipse.lsp4j.SignatureHelp;
import org.eclipse.lsp4j.SymbolInformation;
import org.eclipse.lsp4j.TextDocumentPositionParams;
import org.eclipse.lsp4j.TextEdit;
import org.eclipse.lsp4j.WorkspaceEdit;
import org.eclipse.lsp4j.jsonrpc.services.JsonNotification;
import org.eclipse.lsp4j.jsonrpc.services.JsonRequest;
import org.eclipse.lsp4j.jsonrpc.services.JsonSegment;

@JsonSegment("textDocument")
public interface TextDocumentService {
	/**
	 * The Completion request is sent from the client to the server to compute
	 * completion items at a given cursor position. Completion items are
	 * presented in the IntelliSense user interface. If computing complete
	 * completion items is expensive servers can additional provide a handler
	 * for the resolve completion item request. This request is sent when a
	 * completion item is selected in the user interface.
	 */
	@JsonRequest
	CompletableFuture<CompletionList> completion(TextDocumentPositionParams position);

	/**
	 * The request is sent from the client to the server to resolve additional
	 * information for a given completion item.
	 */
	@JsonRequest
	CompletableFuture<CompletionItem> resolveCompletionItem(CompletionItem unresolved);

	/**
	 * The hover request is sent from the client to the server to request hover
	 * information at a given text document position.
	 */
	@JsonRequest
	CompletableFuture<Hover> hover(TextDocumentPositionParams position);

	/**
	 * The signature help request is sent from the client to the server to
	 * request signature information at a given cursor position.
	 */
	@JsonRequest
	CompletableFuture<SignatureHelp> signatureHelp(TextDocumentPositionParams position);

	/**
	 * The goto definition request is sent from the client to the server to
	 * resolve the definition location of a symbol at a given text document
	 * position.
	 */
	@JsonRequest
	CompletableFuture<List<? extends Location>> definition(TextDocumentPositionParams position);

	/**
	 * The references request is sent from the client to the server to resolve
	 * project-wide references for the symbol denoted by the given text document
	 * position.
	 */
	@JsonRequest
	CompletableFuture<List<? extends Location>> references(ReferenceParams params);

	/**
	 * The document highlight request is sent from the client to the server to
	 * to resolve a document highlights for a given text document position.
	 */
	@JsonRequest
	CompletableFuture<List<? extends DocumentHighlight>> documentHighlight(TextDocumentPositionParams position);

	/**
	 * The document symbol request is sent from the client to the server to list
	 * all symbols found in a given text document.
	 */
	@JsonRequest
	CompletableFuture<List<? extends SymbolInformation>> documentSymbol(DocumentSymbolParams params);

	/**
	 * The code action request is sent from the client to the server to compute
	 * commands for a given text document and range. The request is trigger when
	 * the user moves the cursor into an problem marker in the editor or presses
	 * the lightbulb associated with a marker.
	 */
	@JsonRequest
	CompletableFuture<List<? extends Command>> codeAction(CodeActionParams params);

	/**
	 * The code lens request is sent from the client to the server to compute
	 * code lenses for a given text document.
	 */
	@JsonRequest
	CompletableFuture<List<? extends CodeLens>> codeLens(CodeLensParams params);

	/**
	 * The code lens resolve request is sent from the clien to the server to
	 * resolve the command for a given code lens item.
	 */
	@JsonRequest
	CompletableFuture<CodeLens> resolveCodeLens(CodeLens unresolved);

	/**
	 * The document formatting request is sent from the client to the server to
	 * format a whole document.
	 */
	@JsonRequest
	CompletableFuture<List<? extends TextEdit>> formatting(DocumentFormattingParams params);

	/**
	 * The document range formatting request is sent from the client to the
	 * server to format a given range in a document.
	 */
	@JsonRequest
	CompletableFuture<List<? extends TextEdit>> rangeFormatting(DocumentRangeFormattingParams params);

	/**
	 * The document on type formatting request is sent from the client to the
	 * server to format parts of the document during typing.
	 */
	@JsonRequest
	CompletableFuture<List<? extends TextEdit>> onTypeFormatting(DocumentOnTypeFormattingParams params);

	/**
	 * The rename request is sent from the client to the server to do a
	 * workspace wide rename of a symbol.
	 */
	@JsonRequest
	CompletableFuture<WorkspaceEdit> rename(RenameParams params);

	/**
	 * The document open notification is sent from the client to the server to
	 * signal newly opened text documents. The document's truth is now managed
	 * by the client and the server must not try to read the document's truth
	 * using the document's uri.
	 */
	@JsonNotification
	void didOpen(DidOpenTextDocumentParams params);

	/**
	 * The document change notification is sent from the client to the server to
	 * signal changes to a text document.
	 */
	@JsonNotification
	void didChange(DidChangeTextDocumentParams params);

	/**
	 * The document close notification is sent from the client to the server
	 * when the document got closed in the client. The document's truth now
	 * exists where the document's uri points to (e.g. if the document's uri is
	 * a file uri the truth now exists on disk).
	 */
	@JsonNotification
	void didClose(DidCloseTextDocumentParams params);

	/**
	 * The document save notification is sent from the client to the server when
	 * the document for saved in the client.
	 */
	@JsonNotification
	void didSave(DidSaveTextDocumentParams params);
}
