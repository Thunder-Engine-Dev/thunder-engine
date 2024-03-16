extends ByNodeScript

func _ready() -> void:
	if node is GPUParticles2D:
		node.one_shot = true
