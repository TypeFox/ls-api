package io.typefox.lsapi.services.json.adapters

import com.google.gson.Gson
import com.google.gson.TypeAdapter
import com.google.gson.TypeAdapterFactory
import com.google.gson.reflect.TypeToken
import com.google.gson.stream.JsonReader
import com.google.gson.stream.JsonToken
import com.google.gson.stream.JsonWriter
import io.typefox.lsapi.MarkedString
import io.typefox.lsapi.impl.MarkedStringImpl
import java.io.IOException
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

class MarkedStringTypeAdapterFactory implements TypeAdapterFactory {

    override <T> create(Gson gson, TypeToken<T> type) {
        if (MarkedStringImpl.isAssignableFrom(type.rawType))
            newTypeAdapter(gson) as TypeAdapter<T>
        else
            null
    }

    private def newTypeAdapter(Gson gson) {
        new MarkedStringTypeAdapter(gson.getDelegateAdapter(this, TypeToken.get(MarkedStringImpl))) as TypeAdapter<?>
    }

    @FinalFieldsConstructor
    static class MarkedStringTypeAdapter extends TypeAdapter<MarkedStringImpl> {

        val TypeAdapter<MarkedStringImpl> delegate

        override read(JsonReader in) throws IOException {
            if (in.peek == JsonToken.STRING) {
                new MarkedStringImpl(MarkedString.PLAIN_STRING, in.nextString)
            } else {
                delegate.read(in)
            }
        }

        override write(JsonWriter out, MarkedStringImpl value) throws IOException {
            if (value.language == MarkedString.PLAIN_STRING)
                out.value(value.value)
            else
                delegate.write(out, value)
        }
    }
}
