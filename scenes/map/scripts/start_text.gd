extends Node2D

@onready var map = Scenes.current_scene

var _tw: Tween


func _ready() -> void:
	modulate.a = 0
	
	if map is Map2D:
		map.player_entered_level.connect(_enter_level)


func _physics_process(delta: float) -> void:
	if map.to_level.is_empty(): return
	if _tw: return
	
	_tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	_tw.tween_property(self, ^"modulate:a", 1, 0.5)
	_tw.tween_property(self, ^"modulate:a", 0, 0.5)


func _enter_level() -> void:
	if !_tw: return
	_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_SINE)
	_tw.tween_property(self, ^"modulate:a", 0, 1)
