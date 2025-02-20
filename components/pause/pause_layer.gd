extends CanvasLayer


func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	await get_tree().process_frame
	GlobalViewport.vp.add_child.call_deferred(self)
