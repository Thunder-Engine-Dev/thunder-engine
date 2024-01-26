@icon("res://engine/objects/bumping_blocks/question_block/textures/icon.png")
extends StaticBumpingBlock

const NULL_TEXTURE = preload("res://engine/scripts/classes/bumping_block/texture_null.png")
@export var DEBRIS_EFFECT = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")

## For coin bricks. Set to 1 for one-time output
@export var result_counter_value: float = 300
var counter_enabled: bool = false


func _physics_process(_delta):
	super(_delta)
	
	var delta = Thunder.get_delta(_delta)
	
	if counter_enabled:
		result_counter_value = max(result_counter_value - delta, 1)


func bricks_break() -> void:
	Audio.play_sound(break_sound, self)
	var speeds = [Vector2(2, -8), Vector2(4, -7), Vector2(-2, -8), Vector2(-4, -7)]
	for i in speeds:
		NodeCreator.prepare_2d(DEBRIS_EFFECT, self).create_2d(true).call_method(func(eff: Node2D):
			eff.global_transform = global_transform
			eff.velocity = i
		)
			
	Data.values.score += 10
	queue_free()


func got_bumped(by: Node2D) -> void:
	if _triggered: return
	if by is Player:
		if by.is_on_floor() || by.warp != Player.Warp.NONE:
			return
			
	# Brick with some result
	if result && result.creation_nodepack:
		brick_bump_logic()
		return
	
	# Standard brick
	if by is Player && by.suit.type == Data.PLAYER_POWER.SMALL:
		bump(false)
	else:
		hit_attack()
		bricks_break()
	

func brick_bump_logic() -> void:
	if result_counter_value < 1: return
	bump(false)
	if result && !counter_enabled:
		counter_enabled = true
	
	if result_counter_value == 1 || result_counter_value == 0:
		_animated_sprite_2d.animation = &"empty"
		counter_enabled = false
		result_counter_value = 0
