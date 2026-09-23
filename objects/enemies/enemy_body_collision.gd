extends Area2D

@export_category("Enemy's Body Collision")
@export var solid: bool = true
@export var turn_back: bool = true
@export var enable_offscreen: bool = true
## If [code]true[/code], colliding with another enemy adds it to the ignore list for a fraction of a second,
## to prevent from getting stuck when one is above another.[br]If you have many enemies close to each other,
## you may have to disable this.
@export var prevent_from_getting_stuck: bool = true

var _prev_collided_areas = {}


func _ready() -> void:
	area_entered.connect(
		func(area: Area2D) -> void:
			if area.get_script() != get_script() || area.owner == owner: return
			if owner is GravityBody2D && area.solid && turn_back && (
				(prevent_from_getting_stuck && !area.get_instance_id() in _prev_collided_areas) || !prevent_from_getting_stuck
			):
				owner.turn_x()
			
			_prev_collided_areas[area.get_instance_id()] = 0
	)
	
	if enable_offscreen:
		process_mode = PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	if !prevent_from_getting_stuck:
		return
	
	for area in _prev_collided_areas:
		var instance = instance_from_id(area)
		if !is_instance_valid(instance) || !overlaps_area(instance):
			_prev_collided_areas[area] += 10 * delta
			if _prev_collided_areas[area] > 4:
				_prev_collided_areas.erase(area)
