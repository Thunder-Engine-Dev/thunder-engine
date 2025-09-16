extends GravityBody2D

signal activated
signal timed_out

const P_SWITCH_RUNOUT = preload("res://engine/objects/p_switch/p_switch_runout.wav")

@export var is_once: bool
@export var source_coins: Array[PackedScene] = [preload("res://engine/objects/items/coin/coin.tscn")]
@export var source_bricks: Array[PackedScene] = [preload("res://engine/objects/bumping_blocks/brick/brick.tscn")]
@export var explosion_effect: PackedScene = preload("res://engine/objects/effects/smoke/smoke.tscn")
@export var p_switch_music = preload("res://engine/objects/p_switch/p_switch_music.ogg")
@export var p_switch_activation_sound = preload("res://engine/objects/core/checkpoint/sounds/switch.wav")

@onready var collision_shape: CollisionShape2D = $Collision
@onready var collision_shape_stomped: CollisionShape2D = $Collision2
@onready var collision_shape_activator: CollisionShape2D = $Activator/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var duration: Timer = $Duration

@export var appear_distance: float = 32
@export var appear_speed: float = 0.5
@export var appear_visible: float = 28

var _music_faded: int = 0

func _physics_process(delta: float) -> void:
	if !appear_distance:
		motion_process(delta)
		modulate.a = 1
		z_index = 0
	else:
		appear_process(Thunder.get_delta(delta))
		z_index = -1
	
	if !duration.is_stopped() && \
		duration.time_left > 0.0 && \
		duration.time_left < 2 && \
		_music_faded == 0:
			_music_faded = 1
			Audio.play_1d_sound(P_SWITCH_RUNOUT, false)
	
	if !duration.is_stopped() && \
		duration.time_left > 0.0 && \
		duration.time_left < 1.5 && \
		_music_faded < 2:
			_music_faded = 2
			var pl: Player = Thunder._current_player
			if pl && !pl.is_starman():
				Audio.stop_music_channel(98, true)


func appear_process(delta: float) -> void:
	appear_distance = max(appear_distance - appear_speed * delta, 0)
	modulate.a = 0.01 if (appear_distance > appear_visible) else 1.0
	position -= Vector2(0, appear_speed).rotated(global_rotation) * delta


func active() -> void:
	collision_shape.set_deferred(&"disabled", true)
	collision_shape_stomped.set_deferred(&"disabled", false)
	collision_shape_activator.set_deferred(&"disabled", true)
	
	sprite.play(&"activated")
	Audio.play_sound(p_switch_activation_sound, self)
	duration.start()
	_swap_coins_and_bricks.call_deferred()
	
	if is_once:
		await get_tree().create_timer(1.5).timeout
		NodeCreator.prepare_2d(explosion_effect, self).bind_global_transform(Vector2.UP * 16).create_2d()
		set_deferred("collision", false)
		$Sprite.visible = false
		collision_shape_stomped.set_deferred(&"disabled", true)
		gravity_scale = 0


func _on_activation(player: Player) -> void:
	if !duration.is_stopped(): return
	
	_music_faded = 0
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if !mus_loader: return
	mus_loader.play_immediately = false
	mus_loader.pause_music()
	for i in Audio._music_tweens:
		i.kill()
	if Audio._music_channels.has(98) && is_instance_valid(Audio._music_channels[98]):
		_stop_music()
	if !is_instance_valid(player): return
	if !player.died.is_connected(_stop_music):
		player.died.connect(_stop_music, CONNECT_ONE_SHOT)
	activated.emit()
	active()
	Audio.play_music(p_switch_music, 98, { volume = 0 }, false, false)


func _on_duration_timeout() -> void:
	if sprite.animation == &"default":
		return
	if !is_once:
		collision_shape.set_deferred(&"disabled", false)
		collision_shape_stomped.set_deferred(&"disabled", true)
		collision_shape_activator.set_deferred(&"disabled", false)
	timed_out.emit()
	sprite.play(&"default")
	_swap_coins_and_bricks.call_deferred()
	_stop_music()
	var player = Thunder._current_player
	if !is_instance_valid(player): return
	if player.completed: return
	if player.died.is_connected(_stop_music):
		player.died.disconnect(_stop_music)
	_music_faded = 0
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if !mus_loader: return
	if mus_loader.is_paused:
		mus_loader.play_immediately = true
		mus_loader.unpause_music()
	elif !mus_loader.buffer.is_empty():
		mus_loader.play_immediately = true
		mus_loader.play_buffered()
		print("Played buffered")


func _stop_music() -> void:
	Audio.stop_music_channel(98, false)


func _swap_coins_and_bricks() -> void:
	# Coins -> bricks
	var new_bricks: Array[Node2D] = []
	for i in get_tree().get_nodes_in_group(&"coin"):
		if !i is Node2D:
			continue
		var brick: PackedScene = null
		for j in source_coins:
			if i.scene_file_path == j.resource_path:
				brick = source_bricks[source_coins.find(j)]
				break
		var new_brick: = NodeCreator.prepare_2d(brick, i).bind_global_transform().create_2d().get_node()
		# Prevents newly created brick from turning into a coin
		new_brick.remove_from_group(&"brick")
		new_brick.add_to_group.call_deferred(&"brick")
		new_bricks.append(new_brick)
		i.queue_free()
	# Bricks -> coins
	for k in get_tree().get_nodes_in_group(&"brick"):
		if !k is Node2D:
			continue
		var coin: PackedScene = null
		if &"result" in k && k.result != null: continue
		for l in source_bricks:
			if k.scene_file_path == l.resource_path:
				coin = source_coins[source_bricks.find(l)]
				break
		NodeCreator.prepare_2d(coin, k).bind_global_transform().create_2d().get_node()
		k.queue_free()
