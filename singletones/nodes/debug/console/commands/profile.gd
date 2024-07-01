extends Command

static func register() -> Command:
	return new().set_name("profile").add_param("name", TYPE_STRING, true).set_description("Switch the current profile")

func execute(args:Array) -> Command.ExecuteResult:
	var profile = ProfileManager
	if args.is_empty():
		return Command.ExecuteResult.new("Current Profile: " + profile.current_profile.name)
	if profile.profiles.has(args[0]):
		profile.current_profile = profile.profiles[args[0]]
	else:
		var prof_names: Array = []
		for i in profile.profiles:
			prof_names.append(i)
		
		return Command.ExecuteResult.new(
"""ERROR: Profile not found! Try one of these:
%s""" % [str(prof_names)]
		)
	
	return Command.ExecuteResult.new("Success")

