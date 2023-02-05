class_name Command

enum Error {
	OK = -1,
	Unknown = 0,
	Param = 1, # Uses for miss param
	Wrong = 2, # Something went wrong
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
	if args.size() < params.keys().size():
		return messages[Error.Param]
	
	# TODO: Check if param have wrong type
	# for
	
	
	var res: ExecuteResult = execute(args)
	
	if res.err != Error.OK:
		return messages[res.err]
	
	return res.msg

# NOT FOR OVERRIDING
func get_help() -> String:
	var result: String = ""
	
	if params.is_empty():
		result = "No Params"
	else:
		for k in params.keys():
			# TODO: replace print intager to print actual type name
			result += " <%s: %s(type)>" % [k, params[k]]
	
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

func add_param(key: String, val: int) -> Command:
	params[key] = val
	return self

@warning_ignore("shadowed_variable")
func set_name(name: String) -> Command:
	self.name = name
	return self
