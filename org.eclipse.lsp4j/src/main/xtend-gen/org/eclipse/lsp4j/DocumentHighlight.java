package org.eclipse.lsp4j;

import org.eclipse.lsp4j.DocumentHighlightKind;
import org.eclipse.lsp4j.Range;
import org.eclipse.lsp4j.jsonrpc.validation.NonNull;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * A document highlight is a range inside a text document which deserves special attention. Usually a document highlight
 * is visualized by changing the background color of its range.
 */
@SuppressWarnings("all")
public class DocumentHighlight {
  /**
   * The range this highlight applies to.
   */
  @NonNull
  private Range range;
  
  /**
   * The highlight kind, default is {@link DocumentHighlightKind#Text}.
   */
  private DocumentHighlightKind kind;
  
  /**
   * The range this highlight applies to.
   */
  @Pure
  public Range getRange() {
    return this.range;
  }
  
  /**
   * The range this highlight applies to.
   */
  public void setRange(final Range range) {
    this.range = range;
  }
  
  /**
   * The highlight kind, default is {@link DocumentHighlightKind#Text}.
   */
  @Pure
  public DocumentHighlightKind getKind() {
    return this.kind;
  }
  
  /**
   * The highlight kind, default is {@link DocumentHighlightKind#Text}.
   */
  public void setKind(final DocumentHighlightKind kind) {
    this.kind = kind;
  }
  
  public DocumentHighlight() {
    
  }
  
  public DocumentHighlight(final Range range, final DocumentHighlightKind kind) {
    this.range = range;
    this.kind = kind;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("range", this.range);
    b.add("kind", this.kind);
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
    DocumentHighlight other = (DocumentHighlight) obj;
    if (this.range == null) {
      if (other.range != null)
        return false;
    } else if (!this.range.equals(other.range))
      return false;
    if (this.kind == null) {
      if (other.kind != null)
        return false;
    } else if (!this.kind.equals(other.kind))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + ((this.range== null) ? 0 : this.range.hashCode());
    result = prime * result + ((this.kind== null) ? 0 : this.kind.hashCode());
    return result;
  }
}
