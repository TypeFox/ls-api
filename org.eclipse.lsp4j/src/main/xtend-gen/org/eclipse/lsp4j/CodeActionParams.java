package org.eclipse.lsp4j;

import org.eclipse.lsp4j.CodeActionContext;
import org.eclipse.lsp4j.Range;
import org.eclipse.lsp4j.TextDocumentIdentifier;
import org.eclipse.lsp4j.jsonrpc.validation.NonNull;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * The code action request is sent from the client to the server to compute commands for a given text document and range.
 * The request is triggered when the user moves the cursor into an problem marker in the editor or presses the lightbulb
 * associated with a marker.
 */
@SuppressWarnings("all")
public class CodeActionParams {
  /**
   * The document in which the command was invoked.
   */
  @NonNull
  private TextDocumentIdentifier textDocument;
  
  /**
   * The range for which the command was invoked.
   */
  @NonNull
  private Range range;
  
  /**
   * Context carrying additional information.
   */
  @NonNull
  private CodeActionContext context;
  
  /**
   * The document in which the command was invoked.
   */
  @Pure
  public TextDocumentIdentifier getTextDocument() {
    return this.textDocument;
  }
  
  /**
   * The document in which the command was invoked.
   */
  public void setTextDocument(final TextDocumentIdentifier textDocument) {
    this.textDocument = textDocument;
  }
  
  /**
   * The range for which the command was invoked.
   */
  @Pure
  public Range getRange() {
    return this.range;
  }
  
  /**
   * The range for which the command was invoked.
   */
  public void setRange(final Range range) {
    this.range = range;
  }
  
  /**
   * Context carrying additional information.
   */
  @Pure
  public CodeActionContext getContext() {
    return this.context;
  }
  
  /**
   * Context carrying additional information.
   */
  public void setContext(final CodeActionContext context) {
    this.context = context;
  }
  
  public CodeActionParams() {
    
  }
  
  public CodeActionParams(final TextDocumentIdentifier textDocument, final Range range, final CodeActionContext context) {
    this.textDocument = textDocument;
    this.range = range;
    this.context = context;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("textDocument", this.textDocument);
    b.add("range", this.range);
    b.add("context", this.context);
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
    CodeActionParams other = (CodeActionParams) obj;
    if (this.textDocument == null) {
      if (other.textDocument != null)
        return false;
    } else if (!this.textDocument.equals(other.textDocument))
      return false;
    if (this.range == null) {
      if (other.range != null)
        return false;
    } else if (!this.range.equals(other.range))
      return false;
    if (this.context == null) {
      if (other.context != null)
        return false;
    } else if (!this.context.equals(other.context))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + ((this.textDocument== null) ? 0 : this.textDocument.hashCode());
    result = prime * result + ((this.range== null) ? 0 : this.range.hashCode());
    result = prime * result + ((this.context== null) ? 0 : this.context.hashCode());
    return result;
  }
}
