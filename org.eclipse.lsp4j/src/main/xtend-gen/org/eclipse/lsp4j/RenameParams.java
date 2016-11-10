package org.eclipse.lsp4j;

import org.eclipse.lsp4j.Position;
import org.eclipse.lsp4j.TextDocumentIdentifier;
import org.eclipse.lsp4j.jsonrpc.validation.NonNull;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * The rename request is sent from the client to the server to do a workspace wide rename of a symbol.
 */
@SuppressWarnings("all")
public class RenameParams {
  /**
   * The document in which to find the symbol.
   */
  @NonNull
  private TextDocumentIdentifier textDocument;
  
  /**
   * The position at which this request was send.
   */
  @NonNull
  private Position position;
  
  /**
   * The new name of the symbol. If the given name is not valid the request must return a
   * ResponseError with an appropriate message set.
   */
  @NonNull
  private String newName;
  
  /**
   * The document in which to find the symbol.
   */
  @Pure
  public TextDocumentIdentifier getTextDocument() {
    return this.textDocument;
  }
  
  /**
   * The document in which to find the symbol.
   */
  public void setTextDocument(final TextDocumentIdentifier textDocument) {
    this.textDocument = textDocument;
  }
  
  /**
   * The position at which this request was send.
   */
  @Pure
  public Position getPosition() {
    return this.position;
  }
  
  /**
   * The position at which this request was send.
   */
  public void setPosition(final Position position) {
    this.position = position;
  }
  
  /**
   * The new name of the symbol. If the given name is not valid the request must return a
   * ResponseError with an appropriate message set.
   */
  @Pure
  public String getNewName() {
    return this.newName;
  }
  
  /**
   * The new name of the symbol. If the given name is not valid the request must return a
   * ResponseError with an appropriate message set.
   */
  public void setNewName(final String newName) {
    this.newName = newName;
  }
  
  public RenameParams() {
    
  }
  
  public RenameParams(final TextDocumentIdentifier textDocument, final Position position, final String newName) {
    this.textDocument = textDocument;
    this.position = position;
    this.newName = newName;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("textDocument", this.textDocument);
    b.add("position", this.position);
    b.add("newName", this.newName);
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
    RenameParams other = (RenameParams) obj;
    if (this.textDocument == null) {
      if (other.textDocument != null)
        return false;
    } else if (!this.textDocument.equals(other.textDocument))
      return false;
    if (this.position == null) {
      if (other.position != null)
        return false;
    } else if (!this.position.equals(other.position))
      return false;
    if (this.newName == null) {
      if (other.newName != null)
        return false;
    } else if (!this.newName.equals(other.newName))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + ((this.textDocument== null) ? 0 : this.textDocument.hashCode());
    result = prime * result + ((this.position== null) ? 0 : this.position.hashCode());
    result = prime * result + ((this.newName== null) ? 0 : this.newName.hashCode());
    return result;
  }
}
