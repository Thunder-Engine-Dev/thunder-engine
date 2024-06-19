extends CanvasItem

var _tw: Tween


func _ready() -> void:
	modulate.a = 0


func _physics_process(delta: float) -> void:
	if _tw: return
	
	_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_tw.tween_property(self, ^"modulate:a", 1, 0.5)
	_tw.tween_property(self, ^"modulate:a", 0, 0.5)
