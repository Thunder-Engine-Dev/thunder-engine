extends Node

## For use together with Area2D with player_detection.gd script attached.
## Just add a regular node with this script and connect "player_entered" signals to it.

const INCORRECT = preload("res://engine/components/ui/_sounds/incorrect.wav")
const SELECT_MAIN = preload("res://engine/components/ui/_sounds/select_main.wav")

@export var teleport_by: float = 640

## Call this method to teleport stuff by X axis and play the Incorrect SFX.
func entered() -> void:
	var player = Thunder._current_player
	if !player: return
	var camera: PlayerCamera2D = Thunder._current_camera
	camera.stop_blocking_edges = true
	camera.set(&"ignore_retro_scroll", true)
	var old_xscroll = camera._xscroll
	player.position.x -= teleport_by
	player.reset_physics_interpolation()
	for i in Scenes.current_scene.get_children():
		if i is Projectile:
			i.position.x -= teleport_by
			i.reset_physics_interpolation()
	for i in get_tree().get_nodes_in_group(&"Trail"):
		i.position.x -= teleport_by
		i.reset_physics_interpolation()
	
	var _sfx = CharacterManager.get_sound_replace(INCORRECT, INCORRECT, "menu_failure", false)
	Audio.play_1d_sound(_sfx, false)
	
	camera.teleport(false, true)
	camera._xscroll = old_xscroll
	camera.teleport(false, false)
	camera.reset_physics_interpolation()
	camera.stop_blocking_edges = false
	camera.set(&"ignore_retro_scroll", false)

## Call this method to play a Correct SFX.
func _play_correct() -> void:
	#var _sfx = CharacterManager.get_sound_replace(SELECT_MAIN, SELECT_MAIN, "menu_select", false)
	Audio.play_1d_sound(SELECT_MAIN, false, {volume = -4})
