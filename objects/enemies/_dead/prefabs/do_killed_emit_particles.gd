extends ByNodeScript

func _ready() -> void:
	if node is GPUParticles2D:
		node.one_shot = true
		var tw = node.create_tween()
		tw.tween_interval(node.lifetime * 2.0)
		tw.tween_callback(node.queue_free)
