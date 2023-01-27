extends Window

var commands: Dictionary

@onready var input: LineEdit = $"UI/CmdInput"
@onready var output: RichTextLabel = $"UI/OutputContainer/Output"

var history: Array = ['']
var position_in_history: int

func _ready():
	load_commands("res://engine/singletones/nodes/debug/console/commands/")
	
	self.print("\t\t\t[wave amp=50 freq=2]Console[/wave]")
	
	$"UI/Enter".pressed.connect(execute)
	close_requested.connect(func (): hide())

func load_commands(dir: String) -> void:
	for cmd in DirAccess.get_files_at(dir):
		var command: Command = load(dir+cmd).register()
		commands[command.name] = command

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("a_console"):
		visible = !visible
	if visible:
		if Input.is_key_pressed(KEY_ESCAPE):
			grab_focus()
		
		if Input.is_action_just_pressed("ui_up"):
			move_history(1)
		if Input.is_action_just_pressed("ui_down"):
			move_history(-1)

func execute() -> void:
	history.append(input.text)
	var args = input.text.split(' ')
	
	var cmdName = args[0]
	args.remove_at(0)
	
	if !commands.has(cmdName):
		col_print("Command does not exist!", Color.RED)
		return
	
	self.print(commands[cmdName].try_execute(args))
	input.clear()

func move_history(amount: int) -> void:
	position_in_history += amount
	position_in_history = clamp(position_in_history, 0, history.size() - 1)
	input.text = history[position_in_history]
	input.caret_column = input.text.length()

func print(msg: String) -> void:
	output.text += msg + '\n'
	print(msg)

func col_print(msg: String, col:Color) -> void:
	output.text += "[color=%s]%s[/color]\n" % [col.to_html(), msg]
	print(msg)

func _on_visibility_changed():
	input.grab_focus()
