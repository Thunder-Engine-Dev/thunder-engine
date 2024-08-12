extends Window

var commands: Dictionary

@onready var input: LineEdit = $"UI/CmdInput"
@onready var output: RichTextLabel = $"UI/OutputContainer/Output"
@onready var bind_logic = $BindLogic

var history: Array = ['']
var position_in_history: int


func _ready():
	if !OS.is_debug_build() && !SettingsManager.get_tweak("console_enabled", false):
		queue_free()
		return
	load_commands("res://engine/singletones/nodes/debug/console/commands/")
	
	self.print("[wave amp=50 freq=2][b][rainbow freq=0.2][center][font_size=24]Welcome to the Console![/font_size][/center][/rainbow][/b][/wave]")
	
	$"UI/Enter".pressed.connect(execute)
	$"UI/Paused".pressed.connect(func(): Thunder.set_pause_game($"UI/Paused".button_pressed))
	close_requested.connect(
		func():
			Thunder.set_pause_game(false)
			hide()
	)

func _input(event) -> void:
	if !OS.is_debug_build() && !SettingsManager.get_tweak("console_enabled", false): return
	if event.is_action_pressed("ui_accept") && has_focus():
		execute()

func load_commands(dir: String) -> void:
	for cmd in DirAccess.get_files_at(dir):
		var command: Command = load(dir+cmd).register()
		commands[command.name] = command

func _physics_process(delta: float) -> void:
	if !OS.is_debug_build() && !SettingsManager.get_tweak("console_enabled", false): return
	if Input.is_action_just_pressed("a_console"):
		visible = !visible
		$UI/Paused.button_pressed = visible
		Thunder.set_pause_game(visible)
		
	if visible && has_focus():
		if Input.is_action_just_pressed("ui_up"):
			move_history(1)
		if Input.is_action_just_pressed("ui_down"):
			move_history(-1)


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

func print(msg: Variant) -> void:
	output.text += "%s\n" % msg
	
	print_rich(msg)

func col_print(msg: String, col:Color) -> void:
	output.text += "[color=%s]%s[/color]\n" % [col.to_html(), msg]
	print_rich(msg)

func _on_visibility_changed():
	input.grab_focus()
