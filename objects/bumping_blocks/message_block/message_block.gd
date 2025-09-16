extends StaticBumpingBlock

@export_multiline var message: String
@export var font_size: int = 18
@export var box_size := Vector2(320, 96)
@export var message_label_settings: LabelSettings
@export var hide_by_accept_cancel: bool = false
@export var hide_by_mouse_click: bool = false

const MESSAGE_BLOCK = preload("res://engine/objects/bumping_blocks/message_block/message_block.wav")

var activated: bool = false
var _prev_pause_bool: bool

@onready var box: Node2D = $CanvasLayer/Box
@onready var texture: TextureRect = $CanvasLayer/Box/Texture
@onready var text: Label = $CanvasLayer/Box/Texture/Text

signal message_shown
signal message_hidden

func got_bumped(by_player: bool = false) -> void:
	if _triggered: return
	if activated: return
	bump(false)
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().physics_frame
	show_message.call_deferred()


func _physics_process(delta: float) -> void:
	if !activated: return
	if !get_tree().paused:
		get_tree().paused = true
	
	if Input.is_action_just_pressed(&"m_jump") || (hide_by_accept_cancel && (
		Input.is_action_just_pressed(&"ui_accept") || Input.is_action_just_pressed(&"ui_cancel")
	)) || (hide_by_mouse_click && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		hide_message()
		activated = false


func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
	super(disable, bump_rotation, interrupt)


func show_message() -> void:
	message_shown.emit()
	box.scale = Vector2.ZERO
	if message_label_settings:
		text.label_settings = message_label_settings
	text.text = message
	text.add_theme_font_size_override(&"font_size", font_size)
	if box_size != Vector2.ZERO:
		texture.size = box_size
		texture.position = box_size / -2
	process_mode = Node.PROCESS_MODE_ALWAYS
	var _sfx = CharacterManager.get_sound_replace(MESSAGE_BLOCK, MESSAGE_BLOCK, "message_box", false)
	Audio.play_1d_sound(_sfx, true, {ignore_pause = true})
	get_tree().paused = true
	
	if "disable_pause_menu" in Scenes.current_scene:
		_prev_pause_bool = Scenes.current_scene.get(&"disable_pause_menu")
		Scenes.current_scene.set(&"disable_pause_menu", true)
	
	box.position = get_viewport_rect().get_center()
	box.reset_physics_interpolation()
	texture.reset_physics_interpolation()
	
	var tw = get_tree().create_tween().bind_node(box).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(box, ^"scale", Vector2.ONE, 0.5)
	tw.tween_callback(func():
		activated = true
		
	)


func hide_message() -> void:
	if !is_instance_valid(box): return
	message_hidden.emit()
	
	var tw = get_tree().create_tween().bind_node(box)
	tw.tween_property(box, ^"scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		#box.reparent(self)
		#box = $Box
		process_mode = Node.PROCESS_MODE_INHERIT
		get_tree().paused = false
		activated = false
		if "disable_pause_menu" in Scenes.current_scene:
			Scenes.current_scene.set(&"disable_pause_menu", _prev_pause_bool)
	)
