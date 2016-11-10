package org.eclipse.lsp4j;

import org.eclipse.lsp4j.CodeLensOptions;
import org.eclipse.lsp4j.CompletionOptions;
import org.eclipse.lsp4j.DocumentOnTypeFormattingOptions;
import org.eclipse.lsp4j.SignatureHelpOptions;
import org.eclipse.lsp4j.TextDocumentSyncKind;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

@SuppressWarnings("all")
public class ServerCapabilities {
  /**
   * Defines how text documents are synced.
   */
  private TextDocumentSyncKind textDocumentSync;
  
  /**
   * The server provides hover support.
   */
  private Boolean hoverProvider;
  
  /**
   * The server provides completion support.
   */
  private CompletionOptions completionProvider;
  
  /**
   * The server provides signature help support.
   */
  private SignatureHelpOptions signatureHelpProvider;
  
  /**
   * The server provides goto definition support.
   */
  private Boolean definitionProvider;
  
  /**
   * The server provides find references support.
   */
  private Boolean referencesProvider;
  
  /**
   * The server provides document highlight support.
   */
  private Boolean documentHighlightProvider;
  
  /**
   * The server provides document symbol support.
   */
  private Boolean documentSymbolProvider;
  
  /**
   * The server provides workspace symbol support.
   */
  private Boolean workspaceSymbolProvider;
  
  /**
   * The server provides code actions.
   */
  private Boolean codeActionProvider;
  
  /**
   * The server provides code lens.
   */
  private CodeLensOptions codeLensProvider;
  
  /**
   * The server provides document formatting.
   */
  private Boolean documentFormattingProvider;
  
  /**
   * The server provides document range formatting.
   */
  private Boolean documentRangeFormattingProvider;
  
  /**
   * The server provides document formatting on typing.
   */
  private DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider;
  
  /**
   * The server provides rename support.
   */
  private Boolean renameProvider;
  
  /**
   * Defines how text documents are synced.
   */
  @Pure
  public TextDocumentSyncKind getTextDocumentSync() {
    return this.textDocumentSync;
  }
  
  /**
   * Defines how text documents are synced.
   */
  public void setTextDocumentSync(final TextDocumentSyncKind textDocumentSync) {
    this.textDocumentSync = textDocumentSync;
  }
  
  /**
   * The server provides hover support.
   */
  @Pure
  public Boolean getHoverProvider() {
    return this.hoverProvider;
  }
  
  /**
   * The server provides hover support.
   */
  public void setHoverProvider(final Boolean hoverProvider) {
    this.hoverProvider = hoverProvider;
  }
  
  /**
   * The server provides completion support.
   */
  @Pure
  public CompletionOptions getCompletionProvider() {
    return this.completionProvider;
  }
  
  /**
   * The server provides completion support.
   */
  public void setCompletionProvider(final CompletionOptions completionProvider) {
    this.completionProvider = completionProvider;
  }
  
  /**
   * The server provides signature help support.
   */
  @Pure
  public SignatureHelpOptions getSignatureHelpProvider() {
    return this.signatureHelpProvider;
  }
  
  /**
   * The server provides signature help support.
   */
  public void setSignatureHelpProvider(final SignatureHelpOptions signatureHelpProvider) {
    this.signatureHelpProvider = signatureHelpProvider;
  }
  
  /**
   * The server provides goto definition support.
   */
  @Pure
  public Boolean getDefinitionProvider() {
    return this.definitionProvider;
  }
  
  /**
   * The server provides goto definition support.
   */
  public void setDefinitionProvider(final Boolean definitionProvider) {
    this.definitionProvider = definitionProvider;
  }
  
  /**
   * The server provides find references support.
   */
  @Pure
  public Boolean getReferencesProvider() {
    return this.referencesProvider;
  }
  
  /**
   * The server provides find references support.
   */
  public void setReferencesProvider(final Boolean referencesProvider) {
    this.referencesProvider = referencesProvider;
  }
  
  /**
   * The server provides document highlight support.
   */
  @Pure
  public Boolean getDocumentHighlightProvider() {
    return this.documentHighlightProvider;
  }
  
  /**
   * The server provides document highlight support.
   */
  public void setDocumentHighlightProvider(final Boolean documentHighlightProvider) {
    this.documentHighlightProvider = documentHighlightProvider;
  }
  
  /**
   * The server provides document symbol support.
   */
  @Pure
  public Boolean getDocumentSymbolProvider() {
    return this.documentSymbolProvider;
  }
  
  /**
   * The server provides document symbol support.
   */
  public void setDocumentSymbolProvider(final Boolean documentSymbolProvider) {
    this.documentSymbolProvider = documentSymbolProvider;
  }
  
  /**
   * The server provides workspace symbol support.
   */
  @Pure
  public Boolean getWorkspaceSymbolProvider() {
    return this.workspaceSymbolProvider;
  }
  
  /**
   * The server provides workspace symbol support.
   */
  public void setWorkspaceSymbolProvider(final Boolean workspaceSymbolProvider) {
    this.workspaceSymbolProvider = workspaceSymbolProvider;
  }
  
  /**
   * The server provides code actions.
   */
  @Pure
  public Boolean getCodeActionProvider() {
    return this.codeActionProvider;
  }
  
  /**
   * The server provides code actions.
   */
  public void setCodeActionProvider(final Boolean codeActionProvider) {
    this.codeActionProvider = codeActionProvider;
  }
  
  /**
   * The server provides code lens.
   */
  @Pure
  public CodeLensOptions getCodeLensProvider() {
    return this.codeLensProvider;
  }
  
  /**
   * The server provides code lens.
   */
  public void setCodeLensProvider(final CodeLensOptions codeLensProvider) {
    this.codeLensProvider = codeLensProvider;
  }
  
  /**
   * The server provides document formatting.
   */
  @Pure
  public Boolean getDocumentFormattingProvider() {
    return this.documentFormattingProvider;
  }
  
  /**
   * The server provides document formatting.
   */
  public void setDocumentFormattingProvider(final Boolean documentFormattingProvider) {
    this.documentFormattingProvider = documentFormattingProvider;
  }
  
  /**
   * The server provides document range formatting.
   */
  @Pure
  public Boolean getDocumentRangeFormattingProvider() {
    return this.documentRangeFormattingProvider;
  }
  
  /**
   * The server provides document range formatting.
   */
  public void setDocumentRangeFormattingProvider(final Boolean documentRangeFormattingProvider) {
    this.documentRangeFormattingProvider = documentRangeFormattingProvider;
  }
  
  /**
   * The server provides document formatting on typing.
   */
  @Pure
  public DocumentOnTypeFormattingOptions getDocumentOnTypeFormattingProvider() {
    return this.documentOnTypeFormattingProvider;
  }
  
  /**
   * The server provides document formatting on typing.
   */
  public void setDocumentOnTypeFormattingProvider(final DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider) {
    this.documentOnTypeFormattingProvider = documentOnTypeFormattingProvider;
  }
  
  /**
   * The server provides rename support.
   */
  @Pure
  public Boolean getRenameProvider() {
    return this.renameProvider;
  }
  
  /**
   * The server provides rename support.
   */
  public void setRenameProvider(final Boolean renameProvider) {
    this.renameProvider = renameProvider;
  }
  
  public ServerCapabilities() {
    
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("textDocumentSync", this.textDocumentSync);
    b.add("hoverProvider", this.hoverProvider);
    b.add("completionProvider", this.completionProvider);
    b.add("signatureHelpProvider", this.signatureHelpProvider);
    b.add("definitionProvider", this.definitionProvider);
    b.add("referencesProvider", this.referencesProvider);
    b.add("documentHighlightProvider", this.documentHighlightProvider);
    b.add("documentSymbolProvider", this.documentSymbolProvider);
    b.add("workspaceSymbolProvider", this.workspaceSymbolProvider);
    b.add("codeActionProvider", this.codeActionProvider);
    b.add("codeLensProvider", this.codeLensProvider);
    b.add("documentFormattingProvider", this.documentFormattingProvider);
    b.add("documentRangeFormattingProvider", this.documentRangeFormattingProvider);
    b.add("documentOnTypeFormattingProvider", this.documentOnTypeFormattingProvider);
    b.add("renameProvider", this.renameProvider);
    return b.toString();
  }
  
  @Override
  @Pure
  public boolean equals(final Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    if (!super.equals(obj))
      return false;
    ServerCapabilities other = (ServerCapabilities) obj;
    if (this.textDocumentSync == null) {
      if (other.textDocumentSync != null)
        return false;
    } else if (!this.textDocumentSync.equals(other.textDocumentSync))
      return false;
    if (this.hoverProvider == null) {
      if (other.hoverProvider != null)
        return false;
    } else if (!this.hoverProvider.equals(other.hoverProvider))
      return false;
    if (this.completionProvider == null) {
      if (other.completionProvider != null)
        return false;
    } else if (!this.completionProvider.equals(other.completionProvider))
      return false;
    if (this.signatureHelpProvider == null) {
      if (other.signatureHelpProvider != null)
        return false;
    } else if (!this.signatureHelpProvider.equals(other.signatureHelpProvider))
      return false;
    if (this.definitionProvider == null) {
      if (other.definitionProvider != null)
        return false;
    } else if (!this.definitionProvider.equals(other.definitionProvider))
      return false;
    if (this.referencesProvider == null) {
      if (other.referencesProvider != null)
        return false;
    } else if (!this.referencesProvider.equals(other.referencesProvider))
      return false;
    if (this.documentHighlightProvider == null) {
      if (other.documentHighlightProvider != null)
        return false;
    } else if (!this.documentHighlightProvider.equals(other.documentHighlightProvider))
      return false;
    if (this.documentSymbolProvider == null) {
      if (other.documentSymbolProvider != null)
        return false;
    } else if (!this.documentSymbolProvider.equals(other.documentSymbolProvider))
      return false;
    if (this.workspaceSymbolProvider == null) {
      if (other.workspaceSymbolProvider != null)
        return false;
    } else if (!this.workspaceSymbolProvider.equals(other.workspaceSymbolProvider))
      return false;
    if (this.codeActionProvider == null) {
      if (other.codeActionProvider != null)
        return false;
    } else if (!this.codeActionProvider.equals(other.codeActionProvider))
      return false;
    if (this.codeLensProvider == null) {
      if (other.codeLensProvider != null)
        return false;
    } else if (!this.codeLensProvider.equals(other.codeLensProvider))
      return false;
    if (this.documentFormattingProvider == null) {
      if (other.documentFormattingProvider != null)
        return false;
    } else if (!this.documentFormattingProvider.equals(other.documentFormattingProvider))
      return false;
    if (this.documentRangeFormattingProvider == null) {
      if (other.documentRangeFormattingProvider != null)
        return false;
    } else if (!this.documentRangeFormattingProvider.equals(other.documentRangeFormattingProvider))
      return false;
    if (this.documentOnTypeFormattingProvider == null) {
      if (other.documentOnTypeFormattingProvider != null)
        return false;
    } else if (!this.documentOnTypeFormattingProvider.equals(other.documentOnTypeFormattingProvider))
      return false;
    if (this.renameProvider == null) {
      if (other.renameProvider != null)
        return false;
    } else if (!this.renameProvider.equals(other.renameProvider))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + ((this.textDocumentSync== null) ? 0 : this.textDocumentSync.hashCode());
    result = prime * result + ((this.hoverProvider== null) ? 0 : this.hoverProvider.hashCode());
    result = prime * result + ((this.completionProvider== null) ? 0 : this.completionProvider.hashCode());
    result = prime * result + ((this.signatureHelpProvider== null) ? 0 : this.signatureHelpProvider.hashCode());
    result = prime * result + ((this.definitionProvider== null) ? 0 : this.definitionProvider.hashCode());
    result = prime * result + ((this.referencesProvider== null) ? 0 : this.referencesProvider.hashCode());
    result = prime * result + ((this.documentHighlightProvider== null) ? 0 : this.documentHighlightProvider.hashCode());
    result = prime * result + ((this.documentSymbolProvider== null) ? 0 : this.documentSymbolProvider.hashCode());
    result = prime * result + ((this.workspaceSymbolProvider== null) ? 0 : this.workspaceSymbolProvider.hashCode());
    result = prime * result + ((this.codeActionProvider== null) ? 0 : this.codeActionProvider.hashCode());
    result = prime * result + ((this.codeLensProvider== null) ? 0 : this.codeLensProvider.hashCode());
    result = prime * result + ((this.documentFormattingProvider== null) ? 0 : this.documentFormattingProvider.hashCode());
    result = prime * result + ((this.documentRangeFormattingProvider== null) ? 0 : this.documentRangeFormattingProvider.hashCode());
    result = prime * result + ((this.documentOnTypeFormattingProvider== null) ? 0 : this.documentOnTypeFormattingProvider.hashCode());
    result = prime * result + ((this.renameProvider== null) ? 0 : this.renameProvider.hashCode());
    return result;
  }
}
