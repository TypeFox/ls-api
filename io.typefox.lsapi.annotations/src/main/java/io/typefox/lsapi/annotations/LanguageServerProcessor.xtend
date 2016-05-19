/*******************************************************************************
 * Copyright (c) 2016 TypeFox GmbH (http://www.typefox.io) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package io.typefox.lsapi.annotations

import java.util.LinkedList
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.AccessorsProcessor
import org.eclipse.xtend.lib.annotations.EqualsHashCodeProcessor
import org.eclipse.xtend.lib.annotations.ToStringConfiguration
import org.eclipse.xtend.lib.annotations.ToStringProcessor
import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.Visibility

class LanguageServerProcessor extends AbstractInterfaceProcessor {
	
	override doRegisterGlobals(InterfaceDeclaration annotatedInterface, RegisterGlobalsContext context) {
		context.registerClass(annotatedInterface.implName)
	}
	
	override doTransform(MutableInterfaceDeclaration annotatedInterface, extension TransformationContext context) {
		generateImpl(annotatedInterface, context)
	}
	
	protected def generateImpl(MutableInterfaceDeclaration annotatedInterface, extension TransformationContext context) {
		val impl = annotatedInterface.implName.findClass
		impl.implementedInterfaces = #[annotatedInterface.newTypeReference]
		impl.docComment = annotatedInterface.docComment
		
		val superApiInterfaces = annotatedInterface.getSuperApiInterfaces(context).toList
		val visitedInterfaces = newHashSet
		if (!superApiInterfaces.empty) {
			impl.extendedClass = superApiInterfaces.head.implName.newTypeReference
			val interfaceQueue = new LinkedList
			interfaceQueue += superApiInterfaces.head
			do {
				val i = interfaceQueue.removeFirst
				if (visitedInterfaces += i)
					interfaceQueue.addAll(i.getSuperApiInterfaces(context))
			} while (!interfaceQueue.empty)
		}
		impl.generateMembers(annotatedInterface, visitedInterfaces, context)
		
		val toStringUtil = new ToStringProcessor.Util(context)
		toStringUtil.addToString(impl, impl.declaredFields, new ToStringConfiguration)
		
		val equalsHashCodeUtil = new EqualsHashCodeProcessor.Util(context)
		equalsHashCodeUtil.addEquals(impl, impl.declaredFields, !superApiInterfaces.empty)
		equalsHashCodeUtil.addHashCode(impl, impl.declaredFields, !superApiInterfaces.empty)
	}
	
	private def getSuperApiInterfaces(InterfaceDeclaration it, extension TransformationContext context) {
		extendedInterfaces.map[type].filter(InterfaceDeclaration).filter[
			findAnnotation(LanguageServerAPI.findTypeGlobally) !== null
		]
	}
	
	private def void generateMembers(MutableClassDeclaration impl, InterfaceDeclaration source,
			Set<InterfaceDeclaration> visitedInterfaces, extension TransformationContext context) {
		source.declaredMethods.filter[
			!static && thePrimaryGeneratedJavaElement && parameters.empty && returnType !== null
				&& (returnType.inferred || !returnType.isVoid)
		].forEach[ method |
			impl.addField(method.fieldName) [ field |
				field.type = method.getFieldType(context)
				field.docComment = method.docComment
				val accessorsUtil = new AccessorsProcessor.Util(context) {
					override getGetterName(FieldDeclaration it) {
						method.simpleName
					}
				}
				
				accessorsUtil.addGetter(field, Visibility.PUBLIC)
				impl.findDeclaredMethod(method.simpleName) => [
					addAnnotation(newAnnotationReference(Override))
					if (method.findAnnotation(Deprecated.findTypeGlobally) !== null)
						addAnnotation(newAnnotationReference(Deprecated))
				]
				
				if (!field.type.inferred)
					accessorsUtil.addSetter(field, Visibility.PUBLIC)
			]
		]
		visitedInterfaces += source
		source.getSuperApiInterfaces(context).filter[!visitedInterfaces.contains(it)].forEach[
			impl.generateMembers(it, visitedInterfaces, context)
		]
	}
	
	private def getFieldType(MethodDeclaration method, extension TransformationContext context) {
		val returnType = method.returnType.type
		if (returnType instanceof InterfaceDeclaration) {
			if (returnType.findAnnotation(LanguageServerAPI.findTypeGlobally) !== null)
				return returnType.implName.findTypeGlobally.newTypeReference
		}
		val typeArguments = method.returnType.actualTypeArguments
		if (returnType == List.findTypeGlobally && typeArguments.size == 1) {
			val contentTypeRef = typeArguments.get(0)
			val contentType = if (contentTypeRef.isWildCard) contentTypeRef.upperBound?.type
			if (contentType instanceof InterfaceDeclaration) {
				if (contentType.findAnnotation(LanguageServerAPI.findTypeGlobally) !== null)
					return List.newTypeReference(contentType.implName.findTypeGlobally.newTypeReference)
			}
		}
		if (returnType == Map.findTypeGlobally && typeArguments.size == 2) {
			val contentTypeRef = typeArguments.get(1)
			val contentType = if (contentTypeRef.isWildCard) contentTypeRef.upperBound?.type
			if (contentType instanceof InterfaceDeclaration) {
				if (contentType.findAnnotation(LanguageServerAPI.findTypeGlobally) !== null)
					return Map.newTypeReference(typeArguments.get(0), contentType.implName.findTypeGlobally.newTypeReference)
			}
		}
		return method.returnType
	}
	
	private def getFieldName(MethodDeclaration method) {
		val name = method.simpleName
		if (name.startsWith('get') && name.length > 3)
			name.substring(3).toFirstLower
		else if (name.startsWith('is') && name.length > 2)
			name.substring(2).toFirstLower
		else
			name
	}
	
	private def getImplName(Type t) {
		t.qualifiedName + 'Impl'
	}

}