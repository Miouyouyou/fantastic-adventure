extends Node

class FormField:
	const FIELD_TYPE_INVALID:int = -1
	var field_name:String = ""
	var field_type:int = FIELD_TYPE_INVALID
	var field_type_args:PoolStringArray = []

func add_field(field_name:String, field_type:int):
	pass

func display_field(field:FormField):
	match field.field_type:
		_:
			return
	pass
