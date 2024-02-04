extends Camera2D

@onready var player = Scenes.current_scene.get_node(Scenes.current_scene.player)
@export var speed: float = 250


func _physics_process(delta: float) -> void:
	if !player.reached: return
	var left_right:int = int(Input.is_action_pressed("m_right")) - int(Input.is_action_pressed("m_left"))
	var up_down:int = int(Input.is_action_pressed("m_down")) - int(Input.is_action_pressed("m_up"))
	var run: int = 1 + int(Input.is_action_pressed("m_run"))
	position += speed * delta * run * Vector2(left_right, up_down)
	position = position.clamp(
			Vector2(limit_left, limit_top), Vector2(limit_bottom, limit_right)
		)
