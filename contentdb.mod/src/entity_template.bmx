' ------------------------------------------------------------------------------
' -- game_object_template.bmx
' -- 
' -- A template of a game object. Contains details used for construction (such 
' -- as inheritance, descriptions etc) along with a collection of components 
' -- that are used by `EntityFactory` to construct an `Entity` instance.
' --
' -- This file is part of pangolin.mod (https://www.sodaware.net/pangolin/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See COPYING for full license information.
' ------------------------------------------------------------------------------


SuperStrict

Import brl.map
Import brl.linkedlist

Import "component_template.bmx"

Type EntityTemplate
	
	' -- Information
	Field _name:String
	Field _description:String
	Field _inherits:String
	
	' -- Internal organisation
	Field _category:String
	
	' TODO: Replace this with a StringList
	Field _tags:TList
	
	' -- Component Templates
	Field _componentTemplates:TMap
	Field _componentTemplatesList:TList	'< List of ComponentTemplate
	
	
	' ------------------------------------------------------------
	' -- Getting Component Information
	' ------------------------------------------------------------
	
	''' <summary>Get the name of the template.</summary>
	Method getName:String()
		Return Self._name
	End Method
	
	''' <summary>Get the full identifier of the template.</summary>
	Method getIdentifier:String()
		Return Self._name.ToLower()
	End Method
	
	''' <summary>Get the docstring of the template.</summary>
	Method getDescription:String()
		Return Self._description
	End Method

	''' <summary>Get the identifier of the parent template, if it has one .</summary>	
	Method getParentTemplate:String()
		Return Self._inherits
	End Method
	
	''' <summary>Get the optional category this .</summary>	
	Method getCategory:String()
		Return Self._category
	End Method
	
	
	' ------------------------------------------------------------
	' -- Setting data
	' ------------------------------------------------------------
	
	Method setCategory:EntityTemplate(category:String)
		Self._category = category
		Return Self
	End Method
	
	
	' ------------------------------------------------------------
	' -- Structure Queries
	' ------------------------------------------------------------
	
	''' <summary>Check if this template is a child of `parentName`.</summary>
	Method inherits:Byte(parentName:String)
		Return (Lower(parentName) = Lower(Self._inherits))
	End Method
	
	''' <summary>Check if this template contains a specific component.</summary>
	Method hasComponentTemplate:Int(templateName:String)
		Return (Self.getComponentTemplate(templateName) <> Null)
	End Method
	
	''' <summary>Count the number of components in this template.</summary>
	Method countComponents:Int()
		' TODO: Slow -- room for optimisation
		Return Self._componentTemplatesList.Count()
	End Method

	''' <summary>Get all ComponentTemplate objects that make up this entity.</summary>
	Method getComponentTemplates:TList()
		Return Self._componentTemplatesList
	End Method
	
	Method getComponentTemplate:ComponentTemplate(templateName:String)
		If templateName = "" Then Return Null	
		Return ComponentTemplate(Self._componentTemplates.ValueForKey(templateName.ToLower()))
	End Method
	
	Method getTemplateString:String(path:String)
		Local component:ComponentTemplate = Self.getComponentTemplate(Left(path, path.Find(".")))
		If component = Null Then Throw "Could not find ComponentTemplate ~q" + Left(path, path.Find(".")) + "~q"
		Return component.GetFieldValue(Right(path, path.Length - path.Find(".") - 1))
	End Method
		
	Method addComponentTemplate(newComponent:ComponentTemplate)
		Self._componentTemplates.Insert(newComponent.getSchemaIdentifier(), newComponent)	'Lower(newComponent\m_Schema\m_Name), 
		Self._componentTemplatesList.AddLast(newComponent)
	End Method
	
	
	' ------------------------------------------------------------
	' -- Copying Templates
	' ------------------------------------------------------------
		
	Method clone:EntityTemplate()
		
		Local template:Entitytemplate = New EntityTemplate
		
		' Clone basic details
		template._name 			= Self._name
		template._description 	= Self._description
		template._inherits 		= Self._inherits
		template._category 		= Self._category
		template._tags			= Self._tags.Copy()
		
		' Copy component templates
		For Local component:ComponentTemplate = EachIn Self._componentTemplatesList
			template.addComponentTemplate(component.clone())
		Next
		
		Return template
		
	End Method
	
	
	' ------------------------------------------------------------
	' -- Internal DEBUG
	' ------------------------------------------------------------
	
	Method _dump:String()
		
		local output:string
		
		output :+ "EntityTemplate[" + Self.GetName() + "] {" + "~n"
		output :+ "~tdoc~t= " + Self._description + "~n"
		
		For Local tmp:ComponentTemplate = EachIn Self._componentTemplates.Values()
			output :+ "~t[" + tmp.getSchemaName() + "] { ~n"
			
			For Local fld:String = EachIn tmp._fieldValues.Keys()
				output :+ "~t~t" + fld + "~t~t~t = " + tmp.getfieldvalue(fld) + "~n"
			
			Next
			
			output :+ "~t}~n"
		Next

		output :+ "}"
		
		return output
		
	End Method
	
	
	' ------------------------------------------------------------
	' -- Creation / Destruction
	' ------------------------------------------------------------
	
	Method New()
		Self._tags                      = New TList
		Self._componentTemplates        = New TMap
		Self._componentTemplatesList    = New TList
	End Method
	
	''' <summary>Creates and initialises a new EntityTemplate object and returns it.</summary>
	''' <returns>The newly created EntityTemplate object.</returns>
	Function Create:EntityTemplate(name:String, doc:String = "", inherits:String = "")
		Local this:EntityTemplate = New EntityTemplate
		this._name			= name
		this._inherits		= inherits
		this._description	= doc
		Return this
	End Function
	
End Type