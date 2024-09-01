extends GeneralMovementBody2D

@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var collision_shape: CollisionShape2D = $Body/Collision

var is_broken: bool


func stomp() -> void:
	enemy_attacked.stomping_enabled = false
	sprite_node.play("crash")
	collision_shape.set_deferred("disabled", true)
	speed.x = 0
	is_broken = true
	await get_tree().create_timer(4.0, false).timeout
	_shake()


func _physics_process(delta: float) -> void:
	if is_broken:
		motion_process(delta, slide)
		return
	
	super(delta)


func _shake() -> void:
	var spr = get_node(sprite) as AnimatedSprite2D
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(spr, "position:x", 1, 0.04)
	tw.tween_property(spr, "position:x", -1, 0.04)
	tw.set_loops(15)
	await tw.finished
	sprite_node.play_backwards("crash")
	
	await get_tree().create_timer(0.4, false).timeout
	enemy_attacked.stomping_enabled = true
	collision_shape.set_deferred("disabled", false)
	is_broken = false
	
	speed.x = 50
	if Thunder._current_player:
		update_dir.call_deferred()
		speed_to_dir.call_deferred()
	
	sprite_node.play("default")
