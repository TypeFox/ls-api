/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.lsp4j

import org.eclipse.lsp4j.annotations.LanguageServerAPI
import org.eclipse.lsp4j.jsonrpc.validation.NonNull

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