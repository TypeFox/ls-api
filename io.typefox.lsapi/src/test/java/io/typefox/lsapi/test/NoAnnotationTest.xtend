package io.typefox.lsapi.test

import org.junit.Test
import io.typefox.lsapi.CancelParams
import io.typefox.lsapi.annotations.LanguageServerAPI
import org.junit.Assert

class NoAnnotationTest {
    
    @Test def void testNoAnnotation() {
        Assert.assertFalse(CancelParams.annotations.exists[annotationType == LanguageServerAPI])
    }
}