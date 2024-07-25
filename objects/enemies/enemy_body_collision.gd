extends Area2D

@export_category("Enemy's Body Collision")
@export var solid: bool = true
@export var turn_back: bool = true

var _prev_collided_areas = {}


func _ready() -> void:
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.get_script() != get_script() || area.owner == owner: return
			if owner is GravityBody2D && area.solid && turn_back && !(area.get_instance_id() in _prev_collided_areas):
				owner.turn_x()
			
			_prev_collided_areas[area.get_instance_id()] = 0
	)


func _physics_process(delta: float) -> void:
	var collided_areas = get_overlapping_areas()
	for area in _prev_collided_areas:
		var instance = instance_from_id(area)
		if !is_instance_valid(instance) || !(instance in collided_areas):
			_prev_collided_areas[area] += 10 * delta
			if _prev_collided_areas[area] > 4:
				_prev_collided_areas.erase(area)
