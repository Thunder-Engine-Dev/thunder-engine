extends Camera2D

@export var speed: float = 250

@onready var player = Scenes.current_scene.get_node(Scenes.current_scene.player)
var is_fading: bool

func _ready() -> void:
	Thunder._current_camera = self
	var map := Scenes.current_scene as Map2D
	if !map:
		return
	
	map.player_entered_level.connect(
		func() -> void:
			is_fading = true
			var tw: Tween = create_tween().set_trans(Tween.TRANS_SINE)
			tw.tween_property(self, ^"position", Vector2.ZERO, 0.25)
	)


func _physics_process(delta: float) -> void:
	if !player.reached: return
	if !is_fading:
		var dir: Vector2 = Vector2(
			int(Input.is_action_pressed(&"m_right")) - int(Input.is_action_pressed(&"m_left")),
			int(Input.is_action_pressed(&"m_down")) - int(Input.is_action_pressed(&"m_up"))
		)
		var run: int = 1 + int(Input.is_action_pressed(&"m_run"))
		
		position += speed * delta * run * dir
	
	position = position.clamp(
		Vector2(limit_left + 320, limit_top + 240) - player.position,
		Vector2(limit_right - 320, limit_bottom - 240) - player.position
	)
