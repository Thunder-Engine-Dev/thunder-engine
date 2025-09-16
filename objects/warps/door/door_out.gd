extends Area2D

@export var sprite_frames: SpriteFrames = preload("res://engine/objects/warps/door/door_animation.tres")
@export_category("DoorOut")
@export var warping_speed: float = 50
@export var warping_sound: AudioStream = preload("res://engine/objects/players/prefabs/sounds/door-close.wav")
@export var trigger_immediately: bool = false

var player: Player

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_bg: Sprite2D = $SpriteBG
@onready var pos_player: Marker2D = $PosPlayer

signal player_exit


func _ready() -> void:
	sprite.sprite_frames = sprite_frames
	if trigger_immediately:
		player = Thunder._current_player
		player.speed = Vector2.ZERO
		pass_player(player)

func _physics_process(delta: float) -> void:
	if !player: return
	
	player.global_position = pos_player.global_position
	player.sprite.play(&"default")


func pass_player(new_player: Player) -> void:
	if Engine.is_editor_hint(): return
	if !is_instance_valid(new_player): return
	player = new_player
	
	# Recover z_index if called directly
	sprite.z_index = 10
	sprite_bg.z_index = 1
	
	player.global_position = pos_player.global_position
	player.reset_physics_interpolation()
	player.sprite.play(&"default")
	player.speed = Vector2.ZERO
	player.warp = Player.Warp.OUT
	sprite.play(&"open")
	sprite_bg.visible = true
	
	await get_tree().physics_frame
	Audio.play_sound(warping_sound, self, false)


func _on_animation_finished() -> void:
	if !sprite: return
	if sprite.animation == &"open":
		sprite.z_index = 1
		sprite_bg.z_index = 1
		sprite.play(&"close")
	elif sprite.animation == &"close":
		
		player_exit.emit()
		sprite.z_index = 0
		sprite.play(&"default")
		
		sprite_bg.z_index = 0
		sprite_bg.visible = false
		player.warp = Player.Warp.NONE
		player = null
		Thunder._current_hud.timer.paused = false
