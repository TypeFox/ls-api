package io.typefox.lsapi.annotations.chedto

import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference

class CheDTOGenerator extends AbstractInterfaceProcessor {
	
	override doRegisterGlobals(InterfaceDeclaration annotatedClass, extension RegisterGlobalsContext context) {
		context.registerInterface(annotatedClass.DTOName)
	}
	
	def String getDTOName(Type declaration) {
		return 'org.eclipse.che.plugin.languageserver.shared.lsapi.'+declaration.simpleName+"DTO"
	}
	
	override doTransform(MutableInterfaceDeclaration annotatedClass, extension TransformationContext context) {
		val dto = context.findInterface(annotatedClass.DTOName)
		dto.addAnnotation(newAnnotationReference("org.eclipse.che.dto.shared.DTO"))
		dto.extendedInterfaces = #[annotatedClass.newTypeReference()]
		
		dto.overrideDTOGetters(annotatedClass, context)
	}
	
	def void overrideDTOGetters(MutableInterfaceDeclaration declaration, InterfaceDeclaration superType, extension TransformationContext context) {
		for (m : superType.declaredMethods) {
			if (m.returnType.isDTO) {
				declaration.addMethod(m.simpleName) [
					docComment = '''
						Overridden to return the DTO type.
					'''
					returnType = m.returnType.convertToDTOTypeReference(context)
				]
			}
		}
		for (extendedInterface : superType.extendedInterfaces) {
			declaration.overrideDTOGetters(extendedInterface.type as InterfaceDeclaration, context)
		}
	}
	
	def TypeReference convertToDTOTypeReference(TypeReference reference, extension TransformationContext context) {
		if (!reference.actualTypeArguments.isEmpty) {
			val param = convertToDTOTypeReference(reference.actualTypeArguments.head.upperBound, context)
			return reference.type.newTypeReference(param)
		}
		return reference.type.DTOName.newTypeReference
	}
	
	def boolean isDTO(TypeReference reference) {
		reference.name.startsWith("io.typefox") 
		|| reference.name.startsWith("java.util.List") && reference.actualTypeArguments.head.upperBound.isDTO
	}
	
}