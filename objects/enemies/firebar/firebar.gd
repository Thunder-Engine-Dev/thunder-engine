@tool
extends Node2D

const Fireball := preload("./fireball_firebar.tscn")
const ClassFireball := preload("./fireball_firebar.gd")

@export_category("Firebar")
@export var preview: bool:
	set(value):
		preview = value
		
		if !Engine.is_editor_hint():
			return
		
		for i in get_children():
			if i is ClassFireball:
				i.preview = preview
				if !preview:
					i.angle = angle
@export_range(1, 100) var fireballs: int = 5:
	set(value):
		fireballs = value
		if is_node_ready():
			for i in get_children():
				if i is ClassFireball:
					i.queue_free()
			for j in fireballs:
				var f := Fireball.instantiate()
				f.radius = 2 * ball_radius * j
				f.angular_speed = angular_speed
				f.angle = angle
				f.position = Vector2.ZERO
				add_child.call_deferred(f)
@export_range(0, 256, 0.001, "suffix:px") var ball_radius: float = 8:
	set(value):
		ball_radius = value
		if is_node_ready():
			var f := get_children()
			for i in f.size():
				if f[i] is ClassFireball:
					f[i].radius = 2 * ball_radius * i
@export_group("Physics")
@export_range(-18000, 18000, 0.001, "suffix:°/s") var angular_speed: float = 100:
	set(value):
		angular_speed = value
		if is_node_ready():
			for i in get_children():
				if i is ClassFireball:
					i.angular_speed = angular_speed
@export_range(-180, 180, 0.001, "degrees") var angle: float:
	set(value):
		angle = value
		if is_node_ready():
			for i in get_children():
				if i is ClassFireball:
					i.angle = angle

@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	# Create fireballs
	fireballs = fireballs
	
	if Engine.is_editor_hint():
		set_deferred(&"preview", preview) # Triggers setter to iterate children for preview setting in deferred manner
	else:
		visible_on_screen_enabler_2d.visible = true
		visible_on_screen_enabler_2d.rect.position = -Vector2.ONE * 2 * ball_radius * fireballs
		visible_on_screen_enabler_2d.rect.size = Vector2.ONE * 4 * ball_radius * fireballs
