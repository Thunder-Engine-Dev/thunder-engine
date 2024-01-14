extends GravityBody2D

@export var is_once: bool
@export var source_coins: Array[PackedScene] = [preload("res://engine/objects/items/coin/coin.tscn")]
@export var source_bricks: Array[PackedScene] = [preload("res://engine/objects/bumping_blocks/brick/brick.tscn")]

@onready var activator: Area2D = $Activator
@onready var collision_shape: CollisionShape2D = $Collision
@onready var collision_shape_stomped: CollisionShape2D = $Collision2
@onready var collision_shape_activator: CollisionShape2D = $Activator/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var duration: Timer = $Duration


func _physics_process(delta: float) -> void:
	motion_process(delta)


func active() -> void:
	collision_shape.set_deferred(&"disabled", true)
	collision_shape_stomped.set_deferred(&"disabled", false)
	
	sprite.play(&"activated")
	duration.start()
	_swap_coins_and_bricks.call_deferred()
	
	if is_once:
		await duration.timeout
		queue_free()


func _on_activator_body_entered(body: Node2D):
	if !duration.is_stopped(): return
	if body == Thunder._current_player:
		while !body.is_on_floor():
			await get_tree().process_frame
		active()


func _on_duration_timeout() -> void:
	collision_shape.set_deferred(&"disabled", false)
	collision_shape_stomped.set_deferred(&"disabled", true)
	sprite.play(&"default")
	_swap_coins_and_bricks.call_deferred()


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
		for l in source_bricks:
			if k.scene_file_path == l.resource_path:
				coin = source_coins[source_bricks.find(l)]
				break
		NodeCreator.prepare_2d(coin, k).bind_global_transform().create_2d().get_node()
		k.queue_free()
