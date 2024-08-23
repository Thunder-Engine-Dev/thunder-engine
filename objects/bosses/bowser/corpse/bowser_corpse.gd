extends Area2D

const LAVA_BUBBLES = preload("res://engine/objects/effects/bubble/lava_bubbles.tscn")
const GRAVITY: float = 2500.0

@export_category("Bowser's Corpse")
@export var duration: float = 2
@export var falling_acceleration: float = 0.15
@export_group("Sounds")
@export var falling_sound: AudioStream = preload("../sounds/bowser_fall.wav")
@export var into_lava_sound: AudioStream = preload("../sounds/bowser_into_lava.wav")

var move: bool
var in_lava: bool
var velocity: Vector2

var direction_to_complete: int

func _ready() -> void:
	await get_tree().create_timer(duration, false).timeout
	Audio.play_sound(falling_sound, self)
	move = true


func _physics_process(delta: float) -> void:
	if !move: return
	if in_lava && velocity.y > 50:
		velocity += Vector2.UP.rotated(global_rotation) * 1625 * delta
	else:
		velocity += Vector2.DOWN.rotated(global_rotation) * GRAVITY * falling_acceleration * delta
	global_position += velocity * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	Scenes.current_scene.finish(true, direction_to_complete)
	queue_free()


func got_in_lava() -> void:
	if in_lava: return
	Audio.play_sound(into_lava_sound, self)
	in_lava = true
	var bubbles = LAVA_BUBBLES.instantiate()
	Scenes.current_scene.add_child(bubbles)
	bubbles.position = global_position + Vector2(0, 32)
	bubbles.reset_physics_interpolation()
	var tw = bubbles.create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(bubbles.set_emitting.bind(false))
	tw.tween_interval(1.0)
	tw.tween_callback(bubbles.queue_free)
