extends Node2D

const DEBRIS_EFFECT = preload("res://engine/objects/effects/brick_debris/brick_debris.tscn")

@export_range(0, 5, 0.01, "or_greater", "suffix:s") var movement_duration: float = 0.1
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")
@export_group("Sounds", "sound_")
@export var breaking_sound: AudioStream = preload("res://engine/objects/enemies/icicle/sounds/icicle.wav")

@onready var sprite: Sprite2D = $Sprite2D
@onready var left_explosion: Marker2D = $LeftExplosion
@onready var right_explosion: Marker2D = $RightExplosion


func _ready() -> void:
	var destination := global_position + Vector2.DOWN.rotated(global_rotation) * sprite.texture.get_size().y
	
	var tw := create_tween()
	tw.tween_property(self, ^"global_position", destination, movement_duration)
	
	await tw.finished
	await get_tree().create_timer(0.2, false).timeout
	
	_explosion()


func _explosion() -> void:
	Audio.play_sound(breaking_sound, self, false)
	
	for i in [left_explosion.position, right_explosion.position]:
		NodeCreator.prepare_2d(explosion_effect, self).bind_global_transform(i).create_2d()
	
	var speeds := [
		Vector2(2, -6), 
		Vector2(4, -7), 
		Vector2(-2, -6), 
		Vector2(-4, -7)
	]
	for j in speeds:
		NodeCreator.prepare_2d(DEBRIS_EFFECT, self) \
			.bind_global_transform(right_explosion.position).create_2d(true).call_method(func(eff: Node2D):
				eff.texture = preload("./textures/icicle_debris.png")
				eff.velocity = j
		)
	
	queue_free()
