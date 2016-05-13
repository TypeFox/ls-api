/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.json

import com.google.gson.JsonObject
import com.google.gson.JsonSerializationContext
import com.google.gson.JsonSerializer
import java.lang.reflect.Method
import java.lang.reflect.Type
import java.util.List
import java.util.Map
import com.google.gson.JsonArray

class LanguageServerInterfaceSerializer<T> implements JsonSerializer<T> {
	
	override serialize(T source, Type type, JsonSerializationContext context) {
		val typeAsClass = type as Class<?>
		val result = new JsonObject
		for (method : typeAsClass.sortedMethods) {
			result.addValue(method.propertyName, method.invoke(source), context)
		}
		return result
	}
	
	protected def getSortedMethods(Class<?> clazz) {
		if (clazz.isInterface) {
			clazz.methods.filter[
				parameterCount == 0 && returnType != Void.TYPE
			].sortWith[
				val result = Integer.compare(
					$1.declaringClass.getInterfaceDistance(clazz),
					$0.declaringClass.getInterfaceDistance(clazz)
				)
				if (result != 0)
					return result
				else
					return $0.name.compareTo($1.name)
			]
		} else {
			clazz.methods.filter[
				declaringClass !== Object && !#{'toString', 'hashCode', 'clone'}.contains(name)
					&& parameterCount == 0 && returnType != Void.TYPE
			].sortWith[
				val result = Integer.compare(
					$1.declaringClass.getClassDistance(clazz),
					$0.declaringClass.getClassDistance(clazz)
				)
				if (result != 0)
					return result
				else
					return $0.name.compareTo($1.name)
			]
		}
	}
	
	protected def int getClassDistance(Class<?> clazz, Class<?> baseClazz) {
		if (clazz == baseClazz)
			return 0
		val superClazz = baseClazz.superclass
		if (superClazz == null)
			return Integer.MAX_VALUE
		return getClassDistance(clazz, superClazz) + 1
	}
	
	protected def int getInterfaceDistance(Class<?> interfaze, Class<?> baseInterfaze) {
		if (interfaze == baseInterfaze)
			return 0
		var result = Integer.MAX_VALUE
		for (superInterfaze : baseInterfaze.interfaces) {
			val d = getInterfaceDistance(interfaze, superInterfaze) + 1
			if (d < result)
				result = d
		}
		return result
	}
	
	protected def getPropertyName(Method method) {
		val name = method.name
		if (name.startsWith('get'))
			name.substring(3).toFirstLower
		else if (name.startsWith('is'))
			name.substring(2).toFirstLower
		else
			name
	}
	
	protected def void addValue(JsonObject object, String property, Object value,
			JsonSerializationContext context) {
		switch value {
			List<Object>: {
				val arrayElement = new JsonArray
				for (e : value) {
					arrayElement.add(context.serialize(e))
				}
				object.add(property, arrayElement)
			}
			Map<Object, Object>: {
				val objectElement = new JsonObject
				for (entry : value.entrySet) {
					objectElement.add(entry.key.toString, context.serialize(entry.value))
				}
				object.add(property, objectElement)
			}
			String:
				object.addProperty(property, value)
			Number:
				object.addProperty(property, value)
			Boolean:
				object.addProperty(property, value)
			Character:
				object.addProperty(property, value)
			case value !== null:
				object.add(property, context.serialize(value))
		}
	}
	
}
