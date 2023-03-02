# Base for blocks that can be bumped from below like bricks and question blocks
@icon("res://engine/scripts/classes/bumping_block/icon.png")
extends StaticBody2D
class_name StaticBumpingBlock

## Base class for blocks that can be bumped by players and enemies[br]
## Generally, bricks, question blocks, message blocks, etc. all belong to the class

## The item you want to let the block spawn when the block gets bumped
@export var result: Node2DCreation
## If [code]false[/code], the block won't react to any kind of bumping
@export var active: bool = true
var _triggered: bool = false

@export_group("Sounds")
## The sound when the block spawns an item
@export var appear_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/appear.wav")
## The sound when the block gets bumped
@export var bump_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/bump.wav")
## The sound when the block breaks (if possible)
@export var break_sound: AudioStream = preload("res://modules/base/objects/bumping_blocks/_sounds/break.wav")

@export_group("Bump Detection")
## Bottom detector of bumping
@export var cast_below: ShapeCast2D #if cast_below: cast_below.body_entered.connect()
## Top detector of bumping
@export var cast_above: ShapeCast2D
## Left-side detector of bumping
@export var cast_left: ShapeCast2D
## Right-side detector of bumping
@export var cast_right: ShapeCast2D

var _no_result_appearing_animation: bool = false

## Emitted when getting bumped
signal bumped
## Emitted when the item gets spawned
signal result_appeared


func _ready() -> void:
	if !Engine.is_editor_hint():
		visible = true
		#Engine.time_scale = 0.5
		return

func _physics_process(delta) -> void:
	if Engine.is_editor_hint():
		_editor_process()
		return

func _editor_process() -> void:
	return


## Make the block bumped. If the block was just now got or is being bumped, then nothing will happen[br]
## If [code]disable[/code] is [code]true[/code], then all cast detectors will be disabled[br]
## [code]bump_rotation[/code] is the direction angle that the block moves when it is being bumped[br]
## [code]interrupy[/code] no usge currently
func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
	if _triggered: return
	if !active: return
	
	_triggered = true
	
	var init_position = position
	var tw = get_tree().create_tween()#.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", init_position + Vector2(0, -6).rotated(deg_to_rad(bump_rotation)), 0.12)#.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", init_position, 0.12)#.set_ease(Tween.EASE_IN)
	tw.tween_callback(_lt.bind(disable))
	
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

func _lt(disable):
	if !disable:
		_triggered = false

func _creation(creation: Node2DCreation) -> void:
	if !creation: return
	
	var center = self
	creation.prepare(self, center)
	creation.set_meta(&"no_appearing", _no_result_appearing_animation)
	
	Audio.play_sound(appear_sound, self)
	
	if creation.creation_physics:
		creation.call_physics().apply_velocity_local().override_gravity().unbind()
	
	creation.create()

## Returns [code]true[/code] if [code]body[/code] collides with [code]shape_cast[/code]
func is_body_colliding(body: CollisionObject2D, shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return is_instance_of(collider, body)
	return false

## Returns [code]true[/code] if [member Thunder._current_player] collides with [code]shape_cast[/code]
func is_player_colliding(shape_cast: ShapeCast2D) -> bool:
	if !shape_cast: push_error("Shape Cast is not valid."); return false
	if !shape_cast.enabled: return false
	
	if shape_cast.is_colliding():
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			
			return collider is Player
	return false
