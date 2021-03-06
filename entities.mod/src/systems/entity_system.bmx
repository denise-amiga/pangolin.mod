' ------------------------------------------------------------------------------
' -- src/systems/entity_system.bmx
' --
' -- An EntitySystem is used to perform actions on entities that have certain
' -- components attached to them. This is the base class that all other systems
' -- should extend.
' --
' -- This file is part of pangolin.mod (https://www.sodaware.net/pangolin/)
' -- Copyright (c) 2009-2017 Phil Newton
' --
' -- See COPYING for full license information.
' ------------------------------------------------------------------------------


''' <summary>
''' An EntitySystem is used to perform actions on entities.
'''
''' The entities that are processed can be limited to just entities with one or
''' more specific components. For example, a `PlayerInputSystem` that only
''' processes entities with a`PlayerComponent`.
'''
''' This is the base class that all other systems should extend.
''' </summary>
Type EntitySystem Extends KernelAwareInterface Abstract

	Field _isEnabled:Byte                   '''< Is this system enabled?
	Field _systemBit:Byte                   '''< The unique bit for this system.
	Field _typeBits:BitStorage              '''< Types that this system is interested in.
	Field _world:World                      '''< World this system belongs to.
	Field _actives:EntityBag                '''< All entities this system is interested in.


	' ------------------------------------------------------------
	' -- Enabling / Disabling
	' ------------------------------------------------------------

	''' <summary>Enable this system.</summary>
	Method enableSystem()
		Self._isEnabled = True
		Self.onEnabled()
	End Method

	''' <summary>Disable this system.</summary>
	Method disableSystem()
		Self._isEnabled = False
		Self.onDisabled()
	End Method

	''' <summary>Check if the system is enabled.</summary>
	''' <return>True if system enabled, false if not.</return>
	Method isEnabled:Byte()
		Return Self._isEnabled
	End Method


	' ------------------------------------------------------------
	' -- Hooks
	' ------------------------------------------------------------

	''' <summary>Called when this system has been disabled.</summary>
	Method onDisabled()
	End Method

	''' <summary>Called when this system has been enabled.</summary>
	Method onEnabled()
	End Method

	''' <summary>Called when this system is removed from the World.</summary>
	Method cleanup()
	End Method


	' ------------------------------------------------------------
	' -- Getters / Setters
	' ------------------------------------------------------------

	''' <summary>Get the entity manager attached to this system's world.</summary>
	Method getEntityManager:EntityManager()
		Return Self._world.getEntityManager()
	End Method

	''' <summary>Is this service a sweeper?</summary>
	Method isSweeper:Byte()
		Return False
	End Method

	''' <summary>Get the delta-time since the last time the world ran its services.</summary>
	''' <return>Delta-time in milliseconds.</return>
	Method getDelta:Float()
		Return Self._world._delta
	End Method


	' ------------------------------------------------------------
	' -- Processing
	' ------------------------------------------------------------

	Method processEntities(entities:EntityBag) Abstract

	Method checkProcessing:Byte() Abstract

	''' <summary>Called before all entities are processed by this system.</summary>
	Method beforeProcessEntities()
	End Method

	''' <summary>Called after all entities are processed by this system.</summary>
	Method afterProcessEntities()
	End Method

	' Processes all entities if the system is enabled and can process
	Method process()
		If Not Self._isEnabled Or Not Self.checkProcessing() Then Return

		Self.beforeProcessEntities()
		Self.processEntities(Self._actives)
		Self.afterProcessEntities()
	End Method


	' ------------------------------------------------------------
	' -- Configuration
	' ------------------------------------------------------------

	Method setSystemBit(bit:Byte) Final
		Self._systemBit = bit
	End Method

	Method setWorld(w:World) Final
		Self._world = w
	End Method

	Method getWorld:World() Final
		Return Self._world
	End Method

	Method initialize()
		Self._autoInjectComponentLookups()
		Self.autoloadServices()
	End Method

	''' <summary>Called when an entity has been added to this system's list of interests.</summary>
	Method added(e:Entity)

	End Method

	''' <summary>Called when an entity has been removed from this system's list of interests.</summary>
	Method removed(e:Entity)
	End Method

	Method change(e:Entity)
		Local contains:Byte = Self.contains(e)
		Local interest:Byte = Self.interest(e)

		If interest And Not(contains) Then
			Self._actives.add(e)
			e.addSystemBit(Self._systemBit)
			Self.added(e)
		ElseIf Not(interest) And contains Then
			Self._actives.removeObject(e)
			e.removeSystemBit(Self._systemBit)
			Self.removed(e)
		End If
	End Method

	' Does the entity system bits already contain this system?
	Method contains:Byte(e:Entity)
		Return e.getSystemBits().hasBit(Self._systemBit) And Not Self._typeBits.isEmpty()
	End Method

	' Does the entity have all the components this system is interested in?
	Method interest:Byte(e:Entity)
		Return e.getTypeBits().containsAllBits(Self._typeBits) And Not Self._typeBits.isEmpty()
	End Method

	Method registerComponentByName(componentTypeName:String)
		' TODO: Add some error handling here
		Self.registerComponent(TTypeId.ForName(componentTypeName))
	End Method

	Method registerComponents(componentTypeList:TTypeId[])
		For Local t:TTypeId = EachIn componentTypeList
			Self.registerComponent(t)
		Next
	End Method

	Method registerComponent(t:TTypeId)
		If t = Null Then Return

		Local ct:ComponentType = ComponentTypeManager.getTypeFor(t)
		Self._typeBits.setBit(ct.getBit())
	End Method

	Method isInterestedInComponent:Byte(ct:ComponentType)
		Return Self._typeBits.hasBit(ct.getBit())
	End Method

	''' <summary>Automates registering a system with component types.</summary>
	Method _autoRegisterComponentTypes()
		If Not Self._typeBits.isEmpty() Then Return

		Local imp:String = TTypeId.ForObject(Self).MetaData("component_types")
		Local typeList:String[] = imp.Split(",")

		For Local typeName:String = EachIn typeList
			typeName = typeName.Trim()
			Self.registerComponentByName(typeName)
		Next
	End Method

	''' <summary>
	''' Automatically fetches component type lookups for fields that have a
	''' "component_type" meta field. This is called in the "initialize"
	''' method, so make sure any systems call it.
	''' </summary>
	Method _autoInjectComponentLookups()

		Local system:TTypeId = TTypeId.ForObject(Self)

		For Local f:TField = EachIn system.EnumFields()
			If f.MetaData("component_type") <> Null Then
				f.Set(Self, ComponentTypeManager.getTypeForName(f.MetaData("component_type")))
			EndIf
		Next

	End Method


	' ------------------------------------------------------------
	' -- Enabling / Disabling
	' ------------------------------------------------------------

	Method New()
		Self._actives   = EntityBag.Create()
		Self._isEnabled = True
		Self._typeBits  = New BitStorage
	End Method

End Type
