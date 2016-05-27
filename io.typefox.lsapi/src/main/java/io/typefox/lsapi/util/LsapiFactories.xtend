/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.util

import io.typefox.lsapi.PositionImpl
import io.typefox.lsapi.RangeImpl
import io.typefox.lsapi.TextEditImpl
import io.typefox.lsapi.Range
import io.typefox.lsapi.Position

/**
 * @author Sven Efftinge - Initial contribution and API
 */
class LsapiFactories {
    
    static def PositionImpl newPosition(int line, int character) {
        new PositionImpl => [
            it.line = line
            it.character = character
        ]
    }
    
    static def PositionImpl copyPosition(Position position) {
        new PositionImpl => [
            it.line = position.line
            it.character = position.character
        ]
    }
    
    static def RangeImpl newRange(PositionImpl start, PositionImpl end) {
        new RangeImpl => [
            it.start = start
            it.end = end
        ]
    }
    
    static def RangeImpl copyRange(Range source) {
        new RangeImpl => [
            it.start = copyPosition(source.start)
            it.end = copyPosition(source.end)
        ]
    }
    
    static def TextEditImpl newTextEdit(RangeImpl range, String newText) {
        new TextEditImpl => [
            it.range = range
            it.newText = newText
        ]
    }
    
}
