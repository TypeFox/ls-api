package org.eclipse.lsp4j

import java.util.ArrayList
import java.util.LinkedHashMap
import java.util.List
import java.util.Map
import org.eclipse.lsp4j.generator.LanguageServerAPI
import org.eclipse.lsp4j.jsonrpc.validation.NonNull

@LanguageServerAPI
class ClientCapabilities {
}

/**
 * Contains additional diagnostic information about the context in which a code action is run.
 */
@LanguageServerAPI
class CodeActionContext {
	/**
	 * An array of diagnostics.
	 */
	@NonNull
	List<Diagnostic> diagnostics = newArrayList
}

/**
 * The code action request is sent from the client to the server to compute commands for a given text document and range.
 * The request is triggered when the user moves the cursor into an problem marker in the editor or presses the lightbulb
 * associated with a marker.
 */
@LanguageServerAPI
class CodeActionParams {
	/**
	 * The document in which the command was invoked.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
	/**
	 * The range for which the command was invoked.
	 */
	@NonNull
	Range range
	/**
	 * Context carrying additional information.
	 */
	@NonNull
	CodeActionContext context
}

/**
 * A code lens represents a command that should be shown along with source text, like the number of references,
 * a way to run tests, etc.
 * 
 * A code lens is <em>unresolved</em> when no command is associated to it. For performance reasons the creation of a
 * code lens and resolving should be done to two stages.
 */
@LanguageServerAPI
class CodeLens {
	/**
	 * The range in which this code lens is valid. Should only span a single line.
	 */
	@NonNull
	Range range
	/**
	 * The command this code lens represents.
	 */
	Command command
	/**
	 * An data entry field that is preserved on a code lens item between a code lens and a code lens resolve request.
	 */
	Object data
}

/**
 * Code Lens options.
 */
@LanguageServerAPI
class CodeLensOptions {
	/**
	 * Code lens has a resolve provider as well.
	 */
	boolean ResolveProvider
}

/**
 * The code lens request is sent from the client to the server to compute code lenses for a given text document.
 */
@LanguageServerAPI
class CodeLensParams {
	/**
	 * The document to request code lens for.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
}

/**
 * Represents a reference to a command. Provides a title which will be used to represent a command in the UI and,
 * optionally, an array of arguments which will be passed to the command handler function when invoked.
 */
@LanguageServerAPI
class Command {
	/**
	 * Title of the command, like `save`.
	 */
	@NonNull
	String title
	/**
	 * The identifier of the actual command handler.
	 */
	@NonNull
	String command
	/**
	 * Arguments that the command handler should be invoked with.
	 */
	List<Object> arguments
}

/**
 * The Completion request is sent from the client to the server to compute completion items at a given cursor position.
 * Completion items are presented in the IntelliSense user class. If computing complete completion items is expensive
 * servers can additional provide a handler for the resolve completion item request. This request is send when a
 * completion item is selected in the user class.
 */
@LanguageServerAPI
class CompletionItem {
	/**
	 * The label of this completion item. By default also the text that is inserted when selecting this completion.
	 */
	@NonNull
	String label
	/**
	 * The kind of this completion item. Based of the kind an icon is chosen by the editor.
	 */
	CompletionItemKind kind
	/**
	 * A human-readable string with additional information about this item, like type or symbol information.
	 */
	String detail
	/**
	 * A human-readable string that represents a doc-comment.
	 */
	String documentation
	/**
	 * A string that shoud be used when comparing this item with other items. When `falsy` the label is used.
	 */
	String sortText
	/**
	 * A string that should be used when filtering a set of completion items. When `falsy` the label is used.
	 */
	String filterText
	/**
	 * A string that should be inserted a document when selecting this completion. When `falsy` the label is used.
	 */
	String insertText
	/**
	 * An edit which is applied to a document when selecting this completion. When an edit is provided the value of
	 * insertText is ignored.
	 */
	TextEdit textEdit
	/**
	 * An data entry field that is preserved on a completion item between a completion and a completion resolve request.
	 */
	Object data
}

/**
 * Represents a collection of completion items to be presented in the editor.
 */
@LanguageServerAPI
class CompletionList {
	/**
	 * This list it not complete. Further typing should result in recomputing this list.
	 */
	boolean isIncomplete
	/**
	 * The completion items.
	 */
	@NonNull
	List<CompletionItem> items = newArrayList
}

/**
 * Completion options.
 */
@LanguageServerAPI
class CompletionOptions {
	/**
	 * The server provides support to resolve additional information for a completion item.
	 */
	Boolean resolveProvider
	/**
	 * The characters that trigger completion automatically.
	 */
	List<String> triggerCharacters
}

/**
 * Represents a diagnostic, such as a compiler error or warning. Diagnostic objects are only valid in the scope of a resource.
 */
@LanguageServerAPI
class Diagnostic {
	/**
	 * The range at which the message applies
	 */
	@NonNull
	Range range
	/**
	 * The diagnostic's severity. Can be omitted. If omitted it is up to the client to interpret diagnostics as error,
	 * warning, info or hint.
	 */
	DiagnosticSeverity severity
	/**
	 * The diagnostic's code. Can be omitted.
	 */
	String code
	/**
	 * A human-readable string describing the source of this diagnostic, e.g. 'typescript' or 'super lint'.
	 */
	String source
	/**
	 * The diagnostic's message.
	 */
	@NonNull
	String message
}

/**
 * A notification sent from the client to the server to signal the change of configuration settings.
 */
@LanguageServerAPI
class DidChangeConfigurationParams {
	@NonNull
	Object settings
}

/**
 * The document change notification is sent from the client to the server to signal changes to a text document.
 */
@LanguageServerAPI
class DidChangeTextDocumentParams {
	/**
	 * The document that did change. The version number points to the version after all provided content changes have
	 * been applied.
	 */
	@NonNull
	VersionedTextDocumentIdentifier textDocument
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	String uri
	/**
	 * The actual content changes.
	 */
	@NonNull
	List<TextDocumentContentChangeEvent> contentChanges = new ArrayList
}

/**
 * The watched files notification is sent from the client to the server when the client detects changes
 * to file watched by the language client.
 */
@LanguageServerAPI
class DidChangeWatchedFilesParams {
	/**
	 * The actual file events.
	 */
	@NonNull
	List<FileEvent> changes = new ArrayList
}

/**
 * The document close notification is sent from the client to the server when the document got closed in the client.
 * The document's truth now exists where the document's uri points to (e.g. if the document's uri is a file uri the
 * truth now exists on disk).
 */
@LanguageServerAPI
class DidCloseTextDocumentParams {
	/**
	 * The document that was closed.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
}

/**
 * The document open notification is sent from the client to the server to signal newly opened text documents.
 * The document's truth is now managed by the client and the server must not try to read the document's truth using
 * the document's uri.
 */
@LanguageServerAPI
class DidOpenTextDocumentParams extends TextDocumentIdentifier {
	/**
	 * The document that was opened.
	 */
	@NonNull
	TextDocumentItem textDocument
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	String text
}

/**
 * The document save notification is sent from the client to the server when the document for saved in the clinet.
 */
@LanguageServerAPI
class DidSaveTextDocumentParams {
	/**
	 * The document that was closed.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
}

/**
 * The document formatting request is sent from the server to the client to format a whole document.
 */
@LanguageServerAPI
class DocumentFormattingParams {
	/**
	 * The document to format.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
	/**
	 * The format options
	 */
	@NonNull
	FormattingOptions options
}

/**
 * A document highlight is a range inside a text document which deserves special attention. Usually a document highlight
 * is visualized by changing the background color of its range.
 */
@LanguageServerAPI
class DocumentHighlight {
	/**
	 * The range this highlight applies to.
	 */
	@NonNull
	Range range
	/**
	 * The highlight kind, default is {@link DocumentHighlightKind#Text}.
	 */
	DocumentHighlightKind kind
}

/**
 * Format document on type options
 */
@LanguageServerAPI
class DocumentOnTypeFormattingOptions {
	/**
	 * A character on which formatting should be triggered, like `}`.
	 */
	@NonNull
	String firstTriggerCharacter
	/**
	 * More trigger characters.
	 */
	List<String> moreTriggerCharacter
}

/**
 * The document on type formatting request is sent from the client to the server to format parts of the document during typing.
 */
@LanguageServerAPI
class DocumentOnTypeFormattingParams extends DocumentFormattingParams {
	/**
	 * The position at which this request was send.
	 */
	@NonNull
	Position position
	/**
	 * The character that has been typed.
	 */
	@NonNull
	String ch
}

/**
 * The document range formatting request is sent from the client to the server to format a given range in a document.
 */
@LanguageServerAPI
class DocumentRangeFormattingParams extends DocumentFormattingParams {
	/**
	 * The range to format
	 */
	@NonNull
	Range range
}

/**
 * The document symbol request is sent from the client to the server to list all symbols found in a given text document.
 */
@LanguageServerAPI
class DocumentSymbolParams {
	/**
	 * The text document.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
}

/**
 * An event describing a file change.
 */
@LanguageServerAPI
class FileEvent {
	/**
	 * The file's uri.
	 */
	@NonNull
	String uri
	/**
	 * The change type.
	 */
	@NonNull
	FileChangeType type
}

/**
 * Value-object describing what options formatting should use.
 */
@LanguageServerAPI
class FormattingOptions {
	/**
	 * Size of a tab in spaces.
	 */
	int tabSize
	/**
	 * Prefer spaces over tabs.
	 */
	boolean insertSpaces
	/**
	 * Signature for further properties.
	 */
	Map<String, String> properties
}

/**
 * The result of a hover request.
 */
@LanguageServerAPI
class Hover {
	/**
	 * The hover's content as markdown
	 */
	@NonNull
	List<String> contents = newArrayList()
	/**
	 * An optional range
	 */
	Range range
}

@LanguageServerAPI
class InitializeError {
	/**
	 * Indicates whether the client should retry to send the initialize request after showing the message provided
	 * in the ResponseError.
	 */
	boolean retry
}

/**
 * The initialize request is sent as the first request from the client to the server.
 */
@LanguageServerAPI
class InitializeParams {
	/**
	 * The process Id of the parent process that started the server.
	 */
	Integer processId
	/**
	 * The rootPath of the workspace. Is null if no folder is open.
	 */
	String rootPath
	/**
	 * User provided initialization options.
	 */
	Object initializationOptions
	/**
	 * The capabilities provided by the client (editor)
	 */
	ClientCapabilities capabilities
	/**
	 * An optional extension to the protocol.
	 * To tell the server what client (editor) is talking to it.
	 */
	String clientName
}

@LanguageServerAPI
class InitializeResult {
	/**
	 * The capabilities the language server provides.
	 */
	@NonNull
	ServerCapabilities capabilities
}

/**
 * Represents a location inside a resource, such as a line inside a text file.
 */
@LanguageServerAPI
class Location {
	@NonNull
	String uri
	@NonNull
	Range range
}

/**
 * The show message request is sent from a server to a client to ask the client to display a particular message in the
 * user class. In addition to the show message notification the request allows to pass actions and to wait for an
 * answer from the client.
 */
@LanguageServerAPI
class MessageActionItem {
	/**
	 * A short title like 'Retry', 'Open Log' etc.
	 */
	@NonNull
	String title
}

/**
 * The show message notification is sent from a server to a client to ask the client to display a particular message
 * in the user class.
 * 
 * The log message notification is send from the server to the client to ask the client to log a particular message.
 */
@LanguageServerAPI
class MessageParams {
	/**
	 * The message type.
	 */
	@NonNull
	MessageType type
	/**
	 * The actual message.
	 */
	@NonNull
	String message
}

/**
 * Represents a parameter of a callable-signature. A parameter can have a label and a doc-comment.
 */
@LanguageServerAPI
class ParameterInformation {
	/**
	 * The label of this signature. Will be shown in the UI.
	 */
	@NonNull
	String label
	/**
	 * The human-readable doc-comment of this signature. Will be shown in the UI but can be omitted.
	 */
	String documentation
}

/**
 * Position in a text document expressed as zero-based line and character offset.
 */
@LanguageServerAPI
class Position {
	/**
	 * Line position in a document (zero-based).
	 */
	int line
	/**
	 * Character offset on a line in a document (zero-based).
	 */
	int character
}

/**
 * Diagnostics notification are sent from the server to the client to signal results of validation runs.
 */
@LanguageServerAPI
class PublishDiagnosticsParams {
	/**
	 * The URI for which diagnostic information is reported.
	 */
	@NonNull
	String uri
	/**
	 * An array of diagnostic information items.
	 */
	@NonNull
	List<Diagnostic> diagnostics = new ArrayList
}

/**
 * A range in a text document expressed as (zero-based) start and end positions.
 */
@LanguageServerAPI
class Range {
	/**
	 * The range's start position
	 */
	@NonNull
	Position start
	/**
	 * The range's end position
	 */
	@NonNull
	Position end
}

/**
 * The references request is sent from the client to the server to resolve project-wide references for the symbol
 * denoted by the given text document position.
 */
@LanguageServerAPI
class ReferenceContext {
	/**
	 * Include the declaration of the current symbol.
	 */
	boolean includeDeclaration
}

/**
 * The references request is sent from the client to the server to resolve project-wide references for the symbol
 * denoted by the given text document position.
 */
@LanguageServerAPI
class ReferenceParams extends TextDocumentPositionParams {
	@NonNull
	ReferenceContext context
}

/**
 * The rename request is sent from the client to the server to do a workspace wide rename of a symbol.
 */
@LanguageServerAPI
class RenameParams {
	/**
	 * The document in which to find the symbol.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
	/**
	 * The position at which this request was send.
	 */
	@NonNull
	Position position
	/**
	 * The new name of the symbol. If the given name is not valid the request must return a
	 * ResponseError with an appropriate message set.
	 */
	@NonNull
	String newName
}

@LanguageServerAPI
class ServerCapabilities {
	/**
	 * Defines how text documents are synced.
	 */
	TextDocumentSyncKind textDocumentSync
	/**
	 * The server provides hover support.
	 */
	Boolean hoverProvider
	/**
	 * The server provides completion support.
	 */
	CompletionOptions completionProvider
	/**
	 * The server provides signature help support.
	 */
	SignatureHelpOptions signatureHelpProvider
	/**
	 * The server provides goto definition support.
	 */
	Boolean definitionProvider
	/**
	 * The server provides find references support.
	 */
	Boolean referencesProvider
	/**
	 * The server provides document highlight support.
	 */
	Boolean documentHighlightProvider
	/**
	 * The server provides document symbol support.
	 */
	Boolean documentSymbolProvider
	/**
	 * The server provides workspace symbol support.
	 */
	Boolean workspaceSymbolProvider
	/**
	 * The server provides code actions.
	 */
	Boolean codeActionProvider
	/**
	 * The server provides code lens.
	 */
	CodeLensOptions codeLensProvider
	/**
	 * The server provides document formatting.
	 */
	Boolean documentFormattingProvider
	/**
	 * The server provides document range formatting.
	 */
	Boolean documentRangeFormattingProvider
	/**
	 * The server provides document formatting on typing.
	 */
	DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider
	/**
	 * The server provides rename support.
	 */
	Boolean renameProvider
}

/**
 * The show message request is sent from a server to a client to ask the client to display a particular message in the
 * user class. In addition to the show message notification the request allows to pass actions and to wait for an
 * answer from the client.
 */
@LanguageServerAPI
class ShowMessageRequestParams extends MessageParams {
	/**
	 * The message action items to present.
	 */
	List<MessageActionItem> actions
}

/**
 * Signature help represents the signature of something callable. There can be multiple signature but only one
 * active and only one active parameter.
 */
@LanguageServerAPI
class SignatureHelp {
	/**
	 * One or more signatures.
	 */
	@NonNull
	List<SignatureInformation> signatures = new ArrayList
	/**
	 * The active signature.
	 */
	Integer activeSignature
	/**
	 * The active parameter of the active signature.
	 */
	Integer activeParameter
}

/**
 * Signature help options.
 */
@LanguageServerAPI
class SignatureHelpOptions {
	/**
	 * The characters that trigger signature help automatically.
	 */
	List<String> triggerCharacters
}

/**
 * Represents the signature of something callable. A signature can have a label, like a function-name, a doc-comment, and
 * a set of parameters.
 */
@LanguageServerAPI
class SignatureInformation {
	/**
	 * The label of this signature. Will be shown in the UI.
	 */
	@NonNull
	String label
	/**
	 * The human-readable doc-comment of this signature. Will be shown in the UI but can be omitted.
	 */
	String documentation
	/**
	 * The parameters of this signature.
	 */
	List<ParameterInformation> parameters
}

/**
 * Represents information about programming constructs like variables, classes, classs etc.
 */
@LanguageServerAPI
class SymbolInformation {
	/**
	 * The name of this symbol.
	 */
	@NonNull
	String name
	/**
	 * The kind of this symbol.
	 */
	@NonNull
	SymbolKind kind
	/**
	 * The location of this symbol.
	 */
	@NonNull
	Location location
	/**
	 * The name of the symbol containing this symbol.
	 */
	String containerName
}

/**
 * An event describing a change to a text document. If range and rangeLength are omitted the new text is considered
 * to be the full content of the document.
 */
@LanguageServerAPI
class TextDocumentContentChangeEvent {
	/**
	 * The range of the document that changed.
	 */
	Range range
	/**
	 * The length of the range that got replaced.
	 */
	Integer rangeLength
	/**
	 * The new text of the document.
	 */
	@NonNull
	String text
}

/**
 * Text documents are identified using an URI. On the protocol level URI's are passed as strings.
 */
@LanguageServerAPI
class TextDocumentIdentifier {
	/**
	 * The text document's uri.
	 */
	@NonNull
	String uri
}

/**
 * An item to transfer a text document from the client to the server.
 */
@LanguageServerAPI
class TextDocumentItem {
	/**
	 * The text document's uri.
	 */
	@NonNull
	String uri
	/**
	 * The text document's language identifier
	 */
	@NonNull
	String languageId
	/**
	 * The version number of this document (it will strictly increase after each change, including undo/redo).
	 */
	int version
	/**
	 * The content of the opened  text document.
	 */
	@NonNull
	String text
}

/**
 * A parameter literal used in requests to pass a text document and a position inside that document.
 */
@LanguageServerAPI
class TextDocumentPositionParams {
	/**
	 * The text document.
	 */
	@NonNull
	TextDocumentIdentifier textDocument
	/**
	 * Legacy property to support protocol version 1.0 requests.
	 */
	@Deprecated
	String uri
	/**
	 * The position inside the text document.
	 */
	@NonNull
	Position position
}

/**
 * A textual edit applicable to a text document.
 */
@LanguageServerAPI
class TextEdit {
	/**
	 * The range of the text document to be manipulated. To insert text into a document create a range where start === end.
	 */
	@NonNull
	Range range
	/**
	 * The string to be inserted. For delete operations use an empty string.
	 */
	@NonNull
	String newText
}

/**
 * An identifier to denote a specific version of a text document.
 */
@LanguageServerAPI
class VersionedTextDocumentIdentifier extends TextDocumentIdentifier {
	/**
	 * The version number of this document.
	 */
	int version
}

/**
 * A workspace edit represents changes to many resources managed in the workspace.
 */
@LanguageServerAPI
class WorkspaceEdit {
	/**
	 * Holds changes to existing resources.
	 */
	@NonNull
	Map<String, List<TextEdit>> changes = new LinkedHashMap
}

/**
 * The parameters of a Workspace Symbol Request.
 */
@LanguageServerAPI
class WorkspaceSymbolParams {
	/**
	 * A non-empty query string
	 */
	@NonNull
	String query
}
