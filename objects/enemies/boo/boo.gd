extends "res://engine/scripts/nodes/general_movement/circle_movement.gd"

const BOO_SOUND = preload("res://engine/objects/enemies/boo/sounds/boo1.wav")
const SMOKE = preload("res://engine/objects/effects/smoke/smoke.tscn")

@export var speed: float = 50
@export var variations: Array[SpriteFrames]
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	sprite.sprite_frames = variations.pick_random()
	await get_tree().physics_frame
	center = global_position

func _physics_process(delta: float) -> void:
	var player: Player = Thunder._current_player
	if !player:
		sprite.animation = &"default"
		return
	
	facing = Thunder.Math.look_at(global_position, player.global_position, global_transform)
	dir = sign(facing)

	if &"flip_h" in sprite:
		sprite.flip_h = (facing < 0 && facing != 0)

	if player.direction == dir:
		sprite.animation = &"chase"
		super(delta)
		center = center.move_toward(
			player.position,
			speed * delta
		)
	else:
		sprite.animation = &"default"
		

func _from_bumping_block() -> void:
	Audio.play_sound(BOO_SOUND, self)
	position += Vector2(0, -24).rotated(global_rotation)
	center = global_position
	z_index += 1
	
	var smoke = SMOKE.instantiate()
	smoke.position = global_position
	Scenes.current_scene.add_child(smoke)
