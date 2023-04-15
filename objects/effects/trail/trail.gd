extends Sprite2D

@export_category("Trail")
@export var fade_out_strength: float = 0.05


func _physics_process(delta: float) -> void:
	modulate.a -= fade_out_strength * Thunder.get_delta(delta)
	if modulate.a <= 0.0:
		queue_free()
