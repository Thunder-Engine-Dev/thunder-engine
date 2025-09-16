extends Window

const EnableDebug = preload("res://engine/singletones/nodes/debug/enable_debug.gd")

signal executed(command_name: String, args: Array)

var commands: Dictionary

@onready var input: LineEdit = $"UI/CmdInput"
@onready var output: RichTextLabel = $"UI/OutputContainer/Output"
@onready var bind_logic = $BindLogic

var history: Array = ['']
var position_in_history: int

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
	
	self.print("[wave amp=50 freq=2][b][rainbow freq=0.2][center][font_size=24]Welcome to the Console![/font_size][/center][/rainbow][/b][/wave]")
	
	$"UI/Enter".pressed.connect(execute)
	$"UI/Paused".pressed.connect(func():
		Thunder.set_pause_game($"UI/Paused".button_pressed)
	)
	$"UI/OutputContainer/Output".focus_mode = Control.FOCUS_CLICK
	$"UI/OutputContainer/Output".meta_clicked.connect(func(meta: Variant):
		OS.shell_open(str(meta))
	)
	mouse_entered.connect(func():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	)
	close_requested.connect(
		func():
			Thunder.set_pause_game(false)
			hide()
	)
	

func _input(event) -> void:
	if !debug_mode && !SettingsManager.get_tweak("console_enabled", false): return
	if event.is_action_pressed("ui_accept") && has_focus():
		execute()

func load_commands(dir: String) -> void:
	for cmd in DirAccess.get_files_at(dir):
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
	
	if !visible || !has_focus(): return
	
	if Input.is_action_just_pressed("ui_up"):
		move_history(1)
	if Input.is_action_just_pressed("ui_down"):
		move_history(-1)
	if Input.is_action_just_pressed(&"ui_focus_prev"):
		move_suggestion(-1)
	elif Input.is_action_just_pressed(&"ui_focus_next"):
		move_suggestion(1)



func execute() -> void:
	self.print("[b]> %s[/b]" % input.text)
	
	history.remove_at(0)
	history.push_front(input.text)
	history.push_front("")
	move_history_to_latest(null)
	
	internal_execute(input.text)
	
	input.clear()
	input.grab_focus()

func internal_execute(_in: String) -> void:
	var args = _in.split(' ')
	
	var cmdName = args[0]
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
	position_in_history = clamp(position_in_history, 0, history.size() - 1)
	input.text = history[position_in_history]
	input.caret_column = input.text.length()
	if !input.text_changed.is_connected(move_history_to_latest):
		input.text_changed.connect(move_history_to_latest, CONNECT_ONE_SHOT)

func move_history_to_latest(_new_text) -> void:
	position_in_history = 0

func move_suggestion(amount: int) -> void:
	var uncompl_text: String = input.text.left(input.caret_column)
	if " " in uncompl_text:
		return
	var found: String
	var cmd_keys: Array = commands.keys()
	for i: int in len(cmd_keys):
		var cmd: String = cmd_keys[i]
		if cmd.begins_with(uncompl_text) && uncompl_text != cmd:
			found = cmd
			break
		if uncompl_text == cmd:
			found = cmd_keys[wrapi(i + amount, 0, commands.size() - 1)]
			break
	if found:
		var old_text: String = input.text.get_slice(" ", 1)
		if old_text: old_text = " " + old_text
		input.text = found + old_text.right(len(input.text) - len(uncompl_text))
		input.caret_column = found.length()

func print(msg: Variant) -> void:
	if output: output.text += "%s\n" % msg
	
	print_rich(msg)

func col_print(msg: String, col:Color) -> void:
	output.text += "[color=%s]%s[/color]\n" % [col.to_html(), msg]
	print_rich(msg)

func _on_visibility_changed():
	input.grab_focus()
