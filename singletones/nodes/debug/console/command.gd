class_name Command

enum Error{
	OK = -1,
	Unknown = 0,
	Param = 1, # Uses for miss param
	Wrong = 2, # Something went wrong
}

class ExecuteResult:
	var msg: String
	var err: Error
	func _init(msg,err = -1): self.msg = msg; self.err = err

# For print what goes wrong
const messages: Dictionary = { 
	Error.Unknown:"[color=red]Unknown Error[/color]",
	Error.Param:"[color=red]Invalid Params[/color]",
	Error.Wrong:"[color=red]Something Went Wrong[/color]"}

const NIY: String = "Not Implemented Yet"


var name: StringName = "null"
var params: Dictionary = {} # Example {"Name of Param": Type } Use typeof
var description: String = NIY


# NOT FOR OVERRIDING
func try_execute(args: Array) -> String:
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
	if params.is_empty(): return "No Params"
	
	var result: String = ""
	
	for k in params.keys():
		# TODO: replace print intager to print actual type name
		result += " <%s: %s(type)>" % [k,params[k]]
	
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

func set_name(name: String) -> Command:
	self.name = name
	return self
