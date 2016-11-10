package org.eclipse.lsp4j;

import java.util.List;
import org.eclipse.xtext.xbase.lib.Pure;
import org.eclipse.xtext.xbase.lib.util.ToStringBuilder;

/**
 * Signature help options.
 */
@SuppressWarnings("all")
public class SignatureHelpOptions {
  /**
   * The characters that trigger signature help automatically.
   */
  private List<String> triggerCharacters;
  
  /**
   * The characters that trigger signature help automatically.
   */
  @Pure
  public List<String> getTriggerCharacters() {
    return this.triggerCharacters;
  }
  
  /**
   * The characters that trigger signature help automatically.
   */
  public void setTriggerCharacters(final List<String> triggerCharacters) {
    this.triggerCharacters = triggerCharacters;
  }
  
  public SignatureHelpOptions() {
    
  }
  
  public SignatureHelpOptions(final List<String> triggerCharacters) {
    this.triggerCharacters = triggerCharacters;
  }
  
  @Override
  @Pure
  public String toString() {
    ToStringBuilder b = new ToStringBuilder(this);
    b.add("triggerCharacters", this.triggerCharacters);
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
    SignatureHelpOptions other = (SignatureHelpOptions) obj;
    if (this.triggerCharacters == null) {
      if (other.triggerCharacters != null)
        return false;
    } else if (!this.triggerCharacters.equals(other.triggerCharacters))
      return false;
    return true;
  }
  
  @Override
  @Pure
  public int hashCode() {
    final int prime = 31;
    int result = super.hashCode();
    result = prime * result + ((this.triggerCharacters== null) ? 0 : this.triggerCharacters.hashCode());
    return result;
  }
}
