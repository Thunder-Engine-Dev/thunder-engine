# Base for blocks that can be bumped from below like bricks and question blocks
@icon("res://engine/scripts/classes/bumping_block/icon.png")
extends StaticBody2D
class_name StaticBumpingBlock

@export var active: bool = true
var triggered: bool = false

func _ready() -> void:
	if !Engine.is_editor_hint():
		visible = true
	pass

func _physics_process(delta) -> void:
	if Engine.is_editor_hint():
		_editor_process()
		return

func _editor_process() -> void:
	return

func bump(disable: bool, bump_rotation: float = 0, interrupt: bool = false):
	if interrupt && triggered:
		return
	
	triggered = true
	
	var init_position = position
	var tw = get_tree().create_tween()#.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", init_position + Vector2(0, -6).rotated(deg_to_rad(bump_rotation)), 0.15)#.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", init_position, 0.15)#.set_ease(Tween.EASE_IN)
	
