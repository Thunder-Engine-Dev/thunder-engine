extends RayCast2D

@export var slope_down_height: float = 33

@onready var parent: Node2D = get_parent()

@onready var posx: float = position.x
@onready var tary: float = target_position.y


func _physics_process(delta: float) -> void:
	if parent is GravityBody2D:
		if parent.is_on_floor():
			var slope_y: float = slope_down_height * tan(parent.get_floor_angle(parent.up_direction))
			if parent.is_on_slope() && parent.speed.y > 0 && target_position.y != slope_y:
				target_position.y = slope_y
				force_raycast_update()
			elif target_position.y != tary:
				target_position.y = tary
				force_raycast_update()
			
			if !is_colliding():
				parent.turn_x()
		
		position.x = posx * sign(parent.speed.x)
