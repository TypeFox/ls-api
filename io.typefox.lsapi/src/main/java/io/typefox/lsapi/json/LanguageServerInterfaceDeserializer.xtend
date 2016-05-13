/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import com.google.common.collect.Lists
import com.google.common.collect.Maps
import com.google.gson.JsonArray
import com.google.gson.JsonDeserializationContext
import com.google.gson.JsonDeserializer
import com.google.gson.JsonElement
import com.google.gson.JsonObject
import java.lang.reflect.Method
import java.lang.reflect.ParameterizedType
import java.lang.reflect.Type
import java.lang.reflect.WildcardType
import java.util.List
import java.util.Map

class LanguageServerInterfaceDeserializer<T> implements JsonDeserializer<T> {
	
	override deserialize(JsonElement json, Type type, JsonDeserializationContext context) {
		val typeAsClass = type as Class<? extends T>
		val implClass = if (typeAsClass.isInterface)
			Class.forName(typeAsClass.name + 'Impl') as Class<? extends T>
		else
			typeAsClass
		val result = implClass.newInstance
		if (json instanceof JsonObject) {
			for (entry : json.entrySet) {
				val setterName = 'set' + entry.key.toFirstUpper
				val setter = implClass.methods.findFirst[name == setterName]
				if (setter !== null)
					setValue(result, setter, entry.value, context)
			}
		}
		return result
	}
	
	protected def setValue(T receiver, Method setter, JsonElement value,
			JsonDeserializationContext context) {
		val paramType = setter.genericParameterTypes.get(0)
		if (value instanceof JsonArray && paramType == List) {
			var listContentType = (paramType as ParameterizedType).actualTypeArguments.get(0)
			if (listContentType instanceof WildcardType)
				listContentType = listContentType.upperBounds.get(0)
			val jsonArray = value as JsonArray
			val list = Lists.newArrayListWithExpectedSize(jsonArray.size)
			for (arrayElem : jsonArray) {
				list += context.deserialize(arrayElem, listContentType)
			}
			setter.invoke(receiver, list)
		} else if (value instanceof JsonObject && paramType == Map) {
			val mapContentType = (paramType as ParameterizedType).actualTypeArguments.get(1)
			val jsonObject = value as JsonObject
			val map = Maps.newHashMapWithExpectedSize(jsonObject.entrySet.size)
			for (mapEntry : jsonObject.entrySet) {
				map.put(mapEntry.key, context.deserialize(mapEntry.value, mapContentType))
			}
			setter.invoke(receiver, map)
		} else {
			setter.invoke(receiver, context.<Object>deserialize(value, paramType))
		}
	}
	
}
