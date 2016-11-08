/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.lsp4j.jsonrpc.json;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

import org.eclipse.lsp4j.jsonrpc.MessageConsumer;
import org.eclipse.lsp4j.jsonrpc.messages.Message;

public class StreamMessageConsumer implements MessageConsumer, MessageConstants {

    private final String encoding;
    private final MessageJsonHandler jsonHandler;

    private final Object outputLock = new Object();
    
    private OutputStream output;
    
    public StreamMessageConsumer(MessageJsonHandler jsonHandler) {
    	this(null, StandardCharsets.UTF_8.name(), jsonHandler);
    }
    
    public StreamMessageConsumer(OutputStream output, MessageJsonHandler jsonHandler) {
    	this(output, StandardCharsets.UTF_8.name(), jsonHandler);
    }
    
    public StreamMessageConsumer(OutputStream output, String encoding, MessageJsonHandler jsonHandler) {
        this.output = output;
        this.encoding = encoding;
		this.jsonHandler = jsonHandler;    	    
    }
    
    public OutputStream getOutput() {
    	return output;
    }
    
    public void setOutput(OutputStream output) {
    	this.output = output;
    }
    
    @Override
    public void consume(Message message) {
        if (message.getJsonrpc() == null) {
            message.setJsonrpc(JSONRPC_VERSION);
        }
        
        try {
	        String content = jsonHandler.serialize(message);
	        byte[] contentBytes = content.getBytes(encoding);
	        int contentLength = contentBytes.length;
	        
	        String header = getHeader(contentLength);
	        byte[] headerBytes = header.getBytes(StandardCharsets.US_ASCII);
	        
	        synchronized (outputLock) {
	            output.write(headerBytes);
	            output.write(contentBytes);
	            output.flush();
	        }
        } catch (IOException e) {
        	throw new RuntimeException(e);
        }
    }
    
    protected String getHeader(int contentLength) {
        StringBuilder headerBuilder = new StringBuilder();
        appendHeader(headerBuilder, CONTENT_LENGTH_HEADER, contentLength).append(CRLF);
        if (!StandardCharsets.UTF_8.name().equals(encoding)) {
        	appendHeader(headerBuilder, CONTENT_TYPE_HEADER, JSON_MIME_TYPE);
            headerBuilder.append("; charset=").append(encoding).append(CRLF);
        }
        headerBuilder.append(CRLF);
        return headerBuilder.toString();
    }
    
    protected StringBuilder appendHeader(StringBuilder builder, String name, Object value) {
        return builder.append(name).append(": ").append(value);
    }

}
