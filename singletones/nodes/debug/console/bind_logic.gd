extends Node

const binds_path = "user://binds.thss"

var binds: Dictionary = {
	"_bind_reset": [
		[KEY_SHIFT, KEY_F2]
	],
}

signal binds_updated
signal binds_saved
signal binds_loaded

func _ready():
	load_binds()
	reload_binds()

## Saves the binds variable to file
func save_binds() -> void:
	var data = JSON.stringify(binds)
	
	var file: FileAccess = FileAccess.open(binds_path, FileAccess.WRITE)
	file.store_string(data)
	file.close()
	
	binds_saved.emit()
	print("[Debug Binds] Binds saved!")

## Loads the binds variable from file
func load_binds() -> void:
	var path: String = binds_path
	if !FileAccess.file_exists(path):
		print("[Debug Binds] Using the default binds, no saved ones.")
		return
	
	var data: String = FileAccess.get_file_as_string(path)
	var dict = JSON.parse_string(data)
	
	if dict == null:
		OS.alert("Failed to load saved binds " + name, "Can't load bind file!")
		return
	
	binds = dict
	binds_loaded.emit()
	print("[Debug Binds] Loaded binds from file.")


func reload_binds() -> void:
	for action in binds:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		if !(binds[action] and binds[action] is Array): continue
		if !InputMap.has_action(action):
			InputMap.add_action(action)
		for i in binds[action]:
			var key = InputEventKey.new()
			key.pressed = true
			for scancode in i:
				if scancode == KEY_SHIFT:
					key.shift_pressed = true
					continue
				elif scancode == KEY_CTRL:
					key.ctrl_pressed = true
					continue
				elif scancode == KEY_ALT:
					key.alt_pressed = true
					continue
				key.keycode = scancode
				if !key is InputEventKey: continue
			InputMap.action_add_event(action, key)
	
		#print(InputMap.action_get_events(action))
	binds_updated.emit()
	print("[Debug Binds] Reloaded input maps from binds.")


func _physics_process(delta):
	if !Input.is_anything_pressed(): return
	if Console.has_focus(): return
	if OS.has_feature("template") && !SettingsManager.get_tweak("console_enabled", false): return
	
	var actions: Array[StringName] = InputMap.get_actions()
	for k in actions:
		if k.begins_with("_bind_"):
			var command: String = k.split("_bind_")[1]
			for j in binds.keys():
				if j == k && Input.is_action_just_pressed(k):
					Console.internal_execute(command)
