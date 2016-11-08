/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.lsp4j.jsonrpc.json;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.lsp4j.jsonrpc.MessageConsumer;
import org.eclipse.lsp4j.jsonrpc.MessageProducer;

public class ConcurrentMessageProcessor implements Runnable {
    
    public static Future<?> startProcessing(MessageProducer messageProducer, MessageConsumer messageConsumer,
    		ExecutorService executorService) {
    	ConcurrentMessageProcessor reader = new ConcurrentMessageProcessor(messageProducer, messageConsumer);
        return executorService.submit(reader);
    }
	
	private static final Logger LOG = Logger.getLogger(ConcurrentMessageProcessor.class.getName());

    private boolean isRunning;

    private final MessageProducer messageProducer;
    private final MessageConsumer messageConsumer;
    
    public ConcurrentMessageProcessor(MessageProducer messageProducer, MessageConsumer messageConsumer) {
    	this.messageProducer = messageProducer;
    	this.messageConsumer = messageConsumer;
    }
    
    public void run() {
        if (isRunning) {
            throw new IllegalStateException("The reader is already running.");
        }
        isRunning = true;
        try {
            messageProducer.listen(messageConsumer);
        } catch (Exception e) {
            LOG.log(Level.SEVERE, e.getMessage(), e);
        } finally {
            isRunning = false;
        }
    }
				
}
