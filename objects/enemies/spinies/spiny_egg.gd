extends GeneralMovementBody2D

@export var spiny_creation: InstanceNode2D

@onready var solid_checker: Area2D = $SolidChecker
@onready var col: CollisionShape2D = $Collision

var collision_enabled: bool = false
var _is_ready: bool = false

func _ready() -> void:
	for i in 2:
		await get_tree().physics_frame
	_is_ready = true

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += 22.5 * Thunder.get_delta(delta)
	if !_is_ready: return
	
	if !collision_enabled:
		if solid_checker.get_overlapping_bodies().size() == 0:
			collision_enabled = true
			col.set_deferred(&"disabled", false)
	
	
	if collision_enabled && is_on_floor():
		NodeCreator.prepare_ins_2d(spiny_creation, self).create_2d().call_method(func(node):
			
			var spr = node.get_node(node.sprite)
			if spr.sprite_frames.has_animation(&"appear"):
				spr.play(&"appear")
		)
		queue_free()
