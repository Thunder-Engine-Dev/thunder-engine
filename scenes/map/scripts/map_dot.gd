extends AnimatedSprite2D

var appear_timer: float
var appear_sec: float = 0.3
var is_appearing: bool = false

@onready var player: Node2D = Scenes.current_scene.get_node(Scenes.current_scene.player)

func _ready() -> void:
	Scenes.current_scene.player_fast_forwarded.connect(_appear)

func _appear() -> void:
	if visible: return
	#appear_sec = 0.02

func _physics_process(delta: float) -> void:
	if !is_appearing:
		return
	
	appear_timer += delta * player.ex
	if appear_timer >= appear_sec:
		is_appearing = false
		await get_tree().physics_frame
		show()
