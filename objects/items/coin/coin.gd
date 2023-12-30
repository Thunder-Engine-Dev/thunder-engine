extends Area2D

const coin_effect: PackedScene = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")

@export var sound: AudioStream = preload("res://engine/objects/items/coin/coin.wav")

func _ready() -> void:
	var level = Scenes.current_scene
	
	if level is Level:
		level.p_switch_activeates.connect(toggle_brick)
		level.p_switch_deactivates.connect(toggle_brick)
	
	


func _from_bumping_block() -> void:
	Audio.play_sound(sound, self)
	NodeCreator.prepare_2d(coin_effect, self).create_2d().bind_global_transform()
	Data.add_coin()
	queue_free()

func _physics_process(delta):
	if !Thunder._current_player: return
	if overlaps_body(Thunder._current_player):
		collect()


func collect() -> void:
	Data.add_coin()
	
	NodeCreator.prepare_2d(coin_effect, self).call_method( func(eff: Node2D) -> void:
		eff.explode()
	).create_2d().bind_global_transform()
	
	Audio.play_sound(sound, self)
	queue_free()

## Activates when p switch pressed
func toggle_brick() -> void:
	var brick = preload("res://engine/objects/bumping_blocks/brick/brick.tscn").instantiate()
	Scenes.current_scene.add_child.call_deferred(brick)
	brick.global_position = global_position
	queue_free()
