extends Area2D

const GRAVITY: float = 2500.0

@export_category("Bowser's Corpse")
@export var duration: float = 2
@export var falling_acceleration: float = 0.2
@export_group("Sounds")
@export var falling_sound: AudioStream = preload("../sounds/bowser_fall.wav")
@export var into_lava_sound: AudioStream = preload("../sounds/bowser_into_lava.wav")

var move: bool
var velocity: Vector2

var direction_to_complete: int

func _ready() -> void:
	await get_tree().create_timer(duration, false).timeout
	Audio.play_sound(falling_sound, self)
	move = true


func _physics_process(delta: float) -> void:
	if !move: return
	velocity += Vector2.DOWN.rotated(global_rotation) * GRAVITY * falling_acceleration * delta
	global_position += velocity * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	Scenes.current_scene.finish(true, direction_to_complete)
	queue_free()
