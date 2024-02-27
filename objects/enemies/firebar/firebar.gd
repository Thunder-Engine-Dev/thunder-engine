@tool
extends Node2D

const Fireball := preload("./fireball_firebar.tscn")

@export_category("Firebar")
@export var preview: bool:
	set(value):
		preview = value
		
		if !Engine.is_editor_hint():
			return
		
		for i in get_children():
			if i.is_in_group(&"firebar" + str(get_instance_id())):
				i.preview = preview
				if !preview:
					i.angle = angle
@export_range(0, 100) var fireballs: int = 5:
	set(value):
		fireballs = value
		if is_node_ready():
			_fireballs()
@export_range(0, 256, 0.001, "suffix:px") var ball_radius: float = 8:
	set(value):
		ball_radius = value
		if is_node_ready():
			_fireballs()
@export_group("Physics")
@export_range(-18000, 18000, 0.001, "suffix:°/s") var angular_speed: float = 100:
	set(value):
		angular_speed = value
		if is_node_ready():
			for i in get_children():
				if i.is_in_group(&"firebar" + str(get_instance_id())):
					i.angular_speed = angular_speed
@export_range(-180, 180, 0.001, "degrees") var angle: float:
	set(value):
		angle = value
		if is_node_ready():
			for i in get_children():
				if i.is_in_group(&"firebar" + str(get_instance_id())):
					i.angle = angle


func _ready() -> void:
	# Create fireballs
	_fireballs()
	
	set_deferred(&"preview", preview) # Triggers setter to iterate children for preview setting in deferred manner


func _fireballs() -> void:
	# Clear all
	for i in get_children():
		if i.is_in_group(&"firebar" + str(get_instance_id())):
			i.queue_free()
	# Create
	for j in fireballs:
		var f := Fireball.instantiate()
		f.radius = 2 * ball_radius * j
		f.angular_speed = angular_speed
		f.angle = angle
		f.add_to_group(&"firebar" + str(get_instance_id()))
		add_child.call_deferred(f)
