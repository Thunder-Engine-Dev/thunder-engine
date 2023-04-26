extends GeneralMovementBody2D

@export var spring_jump_height: float = 900

@onready var enemy_attacked: Node = $Body/EnemyAttacked


func trigger() -> void:
	var spr = get_node(sprite) as AnimatedSprite2D
	spr.play(&"default")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("m_jump"):
		enemy_attacked.stomping_player_jumping_max = spring_jump_height
		await get_tree().create_timer(0.1).timeout
		enemy_attacked.stomping_player_jumping_max = enemy_attacked.stomping_player_jumping_min
		return
