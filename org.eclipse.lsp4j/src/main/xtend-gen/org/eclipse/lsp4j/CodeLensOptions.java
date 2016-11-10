package org.eclipse.lsp4j;

import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * Code Lens options.
 */
@SuppressWarnings("all")
public class CodeLensOptions {
  /**
   * Code lens has a resolve provider as well.
   */
  private boolean ResolveProvider;
  
  /**
   * Code lens has a resolve provider as well.
   */
  @Pure
  public boolean isResolveProvider() {
    return this.ResolveProvider;
  }
  
  /**
   * Code lens has a resolve provider as well.
   */
  public void setResolveProvider(final boolean ResolveProvider) {
    this.ResolveProvider = ResolveProvider;
  }
  
  public CodeLensOptions() {
    
  }
  
  public CodeLensOptions(final boolean ResolveProvider) {
    this.ResolveProvider = ResolveProvider;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("ResolveProvider", this.ResolveProvider);
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
    CodeLensOptions other = (CodeLensOptions) obj;
    if (other.ResolveProvider != this.ResolveProvider)
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + (this.ResolveProvider ? 1231 : 1237);
    return result;
  }
}
