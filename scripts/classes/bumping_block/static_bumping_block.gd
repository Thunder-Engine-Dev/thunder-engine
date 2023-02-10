# Base for blocks that can be bumped from below like bricks and question blocks
@icon("res://engine/scripts/classes/bumping_block/icon.png")
extends StaticBody2D
class_name StaticBumpingBlock

@export var result: Node2DCreation
@export var active: bool = true
var triggered: bool = false

@export_group("Sounds")
@export var appear_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/appear.wav")
@export var bump_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/bump.wav")
@export var break_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/break.wav")

@export_group("Bump Detection")
@export var area_below: Area2D #if detection_below: detection_below.body_entered.connect()
@export var area_above: Area2D
@export var area_left: Area2D
@export var area_right: Area2D

var no_result_appearing_animation: bool = false

signal bumped
signal result_appeared

func _ready() -> void:
	if !Engine.is_editor_hint():
		visible = true
		return

func _physics_process(delta) -> void:
	if Engine.is_editor_hint():
		_editor_process()
		return

func _editor_process() -> void:
	return

func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
	if interrupt && triggered: return
	if !active: return
	
	triggered = true
	
	var init_position = position
	var tw = get_tree().create_tween()#.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", init_position + Vector2(0, -6).rotated(deg_to_rad(bump_rotation)), 0.12)#.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", init_position, 0.12)#.set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if !disable:
			triggered = false
	)
	
	if result:
		call_deferred(&"_creation", result)
		result_appeared.emit()
	else:
		Audio.play_sound(bump_sound, self)
	
	bumped.emit()
	
func _creation(creation: Node2DCreation) -> void:
	if !creation: return
	
	var center = self
	creation.prepare(self, center)
	creation.set_meta(&"no_appearing", no_result_appearing_animation)
	
	Audio.play_sound(appear_sound, self)
	
	if creation.creation_physics:
		creation.call_physics().apply_velocity_local().override_gravity().unbind()
	
	creation.create()
