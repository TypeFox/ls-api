package io.typefox.lsapi

import java.util.List

interface TextDocumentService {

    /**
     * The Completion request is sent from the client to the server to compute completion items at a given cursor position. 
     * Completion items are presented in the IntelliSense user interface. If computing complete completion items is expensive 
     * servers can additional provide a handler for the resolve completion item request. This request is send when a completion 
     * item is selected in the user interface.
     * 
     */
    def List<? extends CompletionItem> completion(TextDocumentPositionParams position)
    
    
    /**
     * Diagnostics notification are sent from the server to the client to signal results of validation runs.
     */
    def void onPublishDiagnostics(NotificationCallback<PublishDiagnosticsParams> callback)
}
