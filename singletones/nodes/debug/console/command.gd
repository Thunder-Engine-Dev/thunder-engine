class_name Command

enum Error {
	OK = -1,
	Unknown = 0,
	Param = 1, # Uses for miss param
	Wrong = 2, # Something went wrong
}

const type_names = {
	TYPE_NIL: "null",
	TYPE_BOOL: "bool",
	TYPE_INT: "int",
	TYPE_FLOAT: "float",
	TYPE_STRING: "String",
	TYPE_VECTOR2: "Vector2",
	TYPE_VECTOR2I: "Vector2i",
	TYPE_RECT2: "Rect2",
	TYPE_RECT2I: "Rect2i",
	TYPE_VECTOR3: "Vector3",
	TYPE_VECTOR3I: "Vector3i",
	TYPE_TRANSFORM2D: "Transform2D",
	TYPE_VECTOR4: "Vector4",
	TYPE_VECTOR4I: "Vector4i",
	TYPE_PLANE: "Plane",
	TYPE_QUATERNION: "Quaternion",
	TYPE_AABB: "AABB",
	TYPE_BASIS: "Basis",
	TYPE_TRANSFORM3D: "Transform3D",
	TYPE_PROJECTION: "Projection",
	TYPE_COLOR: "Color",
	TYPE_STRING_NAME: "StringName",
	TYPE_NODE_PATH: "NodePath",
	TYPE_RID: "RID",
	TYPE_OBJECT: "Object",
	TYPE_CALLABLE: "Callable",
	TYPE_SIGNAL: "Signal",
	TYPE_DICTIONARY: "Dictionary",
	TYPE_ARRAY: "Array",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
	TYPE_PACKED_INT64_ARRAY: "PackedInt64Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
	TYPE_PACKED_FLOAT64_ARRAY: "PackedFloat64Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
}

class ExecuteResult:
	var msg: Variant
	var err: Error
	@warning_ignore("shadowed_variable", "shadowed_variable")
	func _init(msg, err = Error.OK):
		self.msg = msg
		self.err = err

# For print what goes wrong
const messages: Dictionary = { 
	Error.Unknown: "[color=red]Unknown Error[/color]",
	Error.Param: "[color=red]Invalid Arguments[/color]",
	Error.Wrong: "[color=red]Something Went Wrong[/color]"
}

const NIY: String = "Not Implemented Yet"


var name: StringName = "null"
var params: Dictionary = {} # Example {"Name of Param": Type } Use typeof
var description: String = NIY


# NOT FOR OVERRIDING
func try_execute(args: Array) -> Variant:
	var arg_count: int = 0
	for k in params.keys():
		if !params[k].optional:
			arg_count += 1
	
	if args.size() < arg_count:
		return messages[Error.Param]
	
	# TODO: Check if param have wrong type
	# for
	
	
	var res: ExecuteResult = execute(args)
	
	if res.err != Error.OK:
		return messages[res.err]
	
	return res.msg

# NOT FOR OVERRIDING
func get_help() -> String:
	var result: String = ":"
	
	if params.is_empty():
		result = ""
	else:
		for k in params.keys():
			var opt: bool = params[k].optional
			var opening: String = "aqua][" if opt else "deep_sky_blue]<"
			var closing: String = "]" if opt else ">"
			result += " [color=%s%s: %s%s[/color]" % [
				opening, k, type_names[params[k].type], closing
			]
	
	result += " - %s" % description
	
	return result

# For overriding
static func register() -> Command:
	return null
	
# For overriding
func execute(args: Array) -> ExecuteResult:
	return ExecuteResult.new(NIY)

func set_description(desc: String) -> Command:
	description = desc
	return self

func add_param(key: String, val: int, _optional: bool = false) -> Command:
	params[key] = {
		type = val,
		optional = _optional
	}
	return self

@warning_ignore("shadowed_variable")
func set_name(name: String) -> Command:
	self.name = name
	return self
