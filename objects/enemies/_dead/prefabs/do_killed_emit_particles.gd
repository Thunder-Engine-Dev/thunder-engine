extends ByNodeScript



func _ready() -> void:
	if !node is GPUParticles2D && !node is CPUParticles2D:
		return
	
	var lifetime = vars.get("lifetime", node.lifetime)
	var tw = node.create_tween()
	tw.tween_interval(lifetime)
	tw.tween_callback(node.set_emitting.bind(false))
	tw.tween_interval(node.lifetime)
	tw.tween_callback(node.queue_free)
