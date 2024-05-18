extends CanvasLayer


func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	GlobalViewport.vp.add_child.call_deferred(self)
