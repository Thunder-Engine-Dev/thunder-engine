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

## Assign ShapeCast2D of the Bumping Block here.
@export_group("Bump Detection")
@export var cast_below: ShapeCast2D #if cast_below: cast_below.body_entered.connect()
@export var cast_above: ShapeCast2D
@export var cast_left: ShapeCast2D
@export var cast_right: ShapeCast2D

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
	
	if disable:
		if cast_below: cast_below.enabled = false
		if cast_above: cast_above.enabled = false
		if cast_left: cast_left.enabled = false
		if cast_right: cast_right.enabled = false
	
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


func is_body_colliding(body: CollisionObject2D, shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return collider is body
	return false

func is_player_colliding(shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return collider is Player
	return false
