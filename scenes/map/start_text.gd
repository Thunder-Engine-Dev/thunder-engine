extends Sprite2D

@onready var map = Scenes.current_scene

func _ready() -> void:
	modulate.a = 0

func _physics_process(delta: float) -> void:
	if map.to_level.is_empty(): return
	
	modulate.a = min(modulate.a + 1 * delta, 1)
