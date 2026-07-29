extends Window

const EnableDebug = preload("res://engine/singletones/nodes/debug/enable_debug.gd")
const NULL_CHAR: String = char(0xFFFD)

signal executed(command_name: String, args: Array[String])

var commands: Dictionary[String, Command]

@onready var input: LineEdit = $"UI/CmdInput"
@onready var output: RichTextLabel = $"UI/OutputContainer/Output"
@onready var bind_logic = $BindLogic

var history: Array[String] = [""]
var position_in_history: int
var _suggestion_old_input_text: String = NULL_CHAR
var _suggestion_temp_output_holder: String = NULL_CHAR

var debug_mode: bool
var command_executed: bool
var allow_developer_commands: bool

# Console Variables
var cv: Dictionary = {
	player_stats_shown = false,
	general_stats_shown = false,
	item_display_shown = false,
	can_save_with_console = false,
	can_save_suspended_with_console = false,
	platform_collision_shown = false,
	unlimited_player_projectiles = false,
	object_names_shown = false,
}


func _ready():
	if "--developer-commands" in OS.get_cmdline_user_args():
		allow_developer_commands = true
		if EnableDebug.DEBUG_ENABLED:
			debug_mode = true
	
	if !OS.has_feature("template"):
		debug_mode = true
	
	load_commands("res://engine/singletones/nodes/debug/console/commands/")
	if DirAccess.dir_exists_absolute("res://commands"):
		load_commands("res://commands/")
	
	if debug_mode:
		self.print("[b]Debug Mode is enabled.[/b]")
	
	self.print(
		"[wave amp=50 freq=2][b][rainbow freq=0.2][center][font_size=24]Welcome to the Console![/font_size][/center][/rainbow][/b][/wave]"
	, false)
	self.print(
		"[color=lime]Hint:[/color] Press Tab or Shift+Tab for autocompletion, and Up/Down for command history."
	, false)
	
	$"UI/Enter".pressed.connect(execute)
	$"UI/Paused".pressed.connect(func():
		Thunder.set_pause_game($"UI/Paused".button_pressed)
	)
	output.focus_mode = Control.FOCUS_CLICK
	output.meta_clicked.connect(func(meta: Variant):
		OS.shell_open(str(meta))
	)
	input.text_changed.connect(func(new_text: String):
		_suggestion_old_input_text = NULL_CHAR
	)
	mouse_entered.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)
	close_requested.connect(
		func():
			Thunder.set_pause_game(false)
			hide()
	)
	

func _input(event: InputEvent) -> void:
	if !debug_mode && !SettingsManager.get_tweak("console_enabled", false): return
	if event.is_action_pressed("ui_accept") && has_focus():
		execute()
	
	if !visible || !has_focus(): return
	if event is InputEventKey && event.is_pressed():
		_handle_command_input(event)


func load_commands(dir: String) -> void:
	for cmd: String in DirAccess.get_files_at(dir):
		if cmd.ends_with(".uid"): continue
		if cmd.begins_with("."): continue
		var command: Command = load(dir + cmd.replace(".remap", "")).register()
		if command.debug_only && (!debug_mode && !Console.allow_developer_commands): continue
		commands[command.name] = command

func _physics_process(delta: float) -> void:
	if !debug_mode && !SettingsManager.get_tweak("console_enabled", false): return
	if Input.is_action_just_pressed("a_console"):
		visible = !visible
		$UI/Paused.button_pressed = visible
		Thunder.set_pause_game(visible)
	
	output.modulate.a = 0.5 if (Console.cv.player_stats_shown || Console.cv.general_stats_shown) else 0.863


func _handle_command_input(event: InputEventKey) -> void:
	var handled: bool = true
	if event.is_action(&"ui_up"):
		move_history(1)
	elif event.is_action(&"ui_down"):
		move_history(-1)
	elif event.is_action(&"ui_focus_prev"):
		move_suggestion(-1)
	elif event.is_action(&"ui_focus_next"):
		move_suggestion(1)
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()



func execute() -> void:
	if input.text.strip_edges() == "":
		input.clear()
		input.grab_focus()
		return
	
	self.print("[b]> %s[/b]" % input.text)
	
	history.remove_at(0)
	if (history.is_empty() || history.front() != input.text) && input.text.strip_edges():
		history.push_front(input.text)
	history.push_front("")
	move_history_to_latest(null)
	
	internal_execute(input.text)
	
	input.clear()
	input.grab_focus()

func internal_execute(_in: String) -> void:
	var args: PackedStringArray = _in.strip_edges().split(" ")
	
	var cmdName: String = args[0]
	args.remove_at(0)
	
	if !commands.has(cmdName):
		if cmdName != "":
			col_print("Command does not exist!", Color.RED)
		return
	
	if commands[cmdName].is_cheat && !debug_mode:
		command_executed = true
	
	self.print(commands[cmdName].try_execute(args))

func move_history(amount: int) -> void:
	position_in_history += amount
	position_in_history = clampi(position_in_history, 0, history.size() - 1)
	input.text = history[position_in_history]
	input.caret_column = input.text.length()
	if !input.text_changed.is_connected(move_history_to_latest):
		input.text_changed.connect(move_history_to_latest, CONNECT_ONE_SHOT)

func move_history_to_latest(_new_text) -> void:
	position_in_history = 0

func move_suggestion(amount: int) -> void:
	var last_split: String = input.text.get_slice(" ", input.text.get_slice_count(" ") - 1)
	var uncompl_text: String = input.text.left(input.caret_column)
	if input.text.length() > input.caret_column && input.text.right(-input.caret_column).strip_edges() != "":
		return
	var found: String
	if " " in uncompl_text:
		uncompl_text = last_split.left(input.caret_column)
		found = get_next_suggestion(get_argument_keys(), amount)
		if found:
			var old_text: String = input.text
			if old_text:
				old_text = old_text + " "
			input.text = old_text.left(len(input.text) - len(uncompl_text)) + found
			input.caret_column = input.text.length()
		return
	found = get_next_suggestion(commands.keys(), amount)
	if found:
		var old_text: String = input.text.get_slice(" ", 1)
		if old_text:
			old_text = " " + old_text
		input.text = found + old_text.right(len(input.text) - len(uncompl_text))
		input.caret_column = input.text.length()


func print(msg: Variant, to_stdout: bool = true) -> void:
	if _suggestion_temp_output_holder != NULL_CHAR:
		output.text = _suggestion_temp_output_holder
		_suggestion_temp_output_holder = NULL_CHAR
	
	output.text += "%s\n" % msg
	if to_stdout:
		print_rich(msg)

func col_print(msg: String, col: Color, to_stdout: bool = true) -> void:
	if _suggestion_temp_output_holder != NULL_CHAR:
		output.text = _suggestion_temp_output_holder
		_suggestion_temp_output_holder = NULL_CHAR
	
	output.text += "[color=%s]%s[/color]\n" % [col.to_html(), msg]
	if to_stdout:
		print_rich(msg)

func _print_suggested_values(msg: String) -> void:
	if _suggestion_temp_output_holder == NULL_CHAR:
		_suggestion_temp_output_holder = output.text
	
	var new_output: String = (
		_suggestion_temp_output_holder + "[color=dark_gray]Suggested:[/color] " + msg + ""
	)
	if output.text != new_output:
		output.text = new_output


func get_next_suggestion(search_keys: Array, amount: int) -> String:
	if !search_keys:
		return ""
	var _input_text: String = _suggestion_old_input_text
	if _input_text == NULL_CHAR:
		_input_text = input.text
	
	var last_split: String = _input_text.get_slice(" ", _input_text.get_slice_count(" ") - 1)
	var uncompl_text: String = last_split.left(_input_text.length())
	var _suggestions: Array = get_suggestions(search_keys, uncompl_text)
	if !_suggestions:
		return ""
	
	var suggested: String = input.text.get_slice(
		" ", input.text.get_slice_count(" ") - 1
	).left(input.text.length())
	
	var found: String = str(_suggestions.front())
	if _suggestions.has(suggested):
		found = str(_suggestions[wrapi(_suggestions.find(suggested) + amount, 0, _suggestions.size())])
	
	if _suggestion_old_input_text == NULL_CHAR:
		_suggestion_old_input_text = input.text
	if _suggestions.size() > 1:
		_print_suggested_values(", ".join(_suggestions))
	return found

func get_suggestions(search_keys: Array, input_text: String) -> Array:
	return search_keys.filter(func(cmd: String):
		return cmd.begins_with(input_text)
	)


func get_argument_keys(args: PackedStringArray = input.text.split(" ")) -> Array:
	var cmdName := args[0]
	args.remove_at(0)
	
	if !commands.has(cmdName):
		return []
	return commands[cmdName].get_argument_options(args, args.size() - 1)


var init_pos := position
func _on_visibility_changed():
	input.grab_focus()
	if !visible: return
	var scale: float = SettingsManager.get_ui_scale(self)
	SettingsManager.scale_window(self, scale)
	if position == init_pos:
		position *= scale
