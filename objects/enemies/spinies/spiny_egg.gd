extends GeneralMovementBody2D

@export var spiny_creation: InstanceNode2D
@export var rotation_speed: float = 22.5
@export var free_offscreen: bool = false

@onready var solid_checker: Area2D = $SolidChecker
@onready var col: CollisionShape2D = $Collision
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var enemy_attacked: Node = $Body/EnemyAttacked

var collision_enabled: bool = false
var _is_ready: bool = false

func _ready() -> void:
	if free_offscreen:
		visible_on_screen_enabler_2d.screen_exited.connect(queue_free)
	for i in 2:
		await get_tree().physics_frame
	_is_ready = true

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += rotation_speed * Thunder.get_delta(delta)
	if !_is_ready: return
	
	if !collision_enabled:
		if solid_checker.get_overlapping_bodies().size() == 0:
			collision_enabled = true
			col.set_deferred(&"disabled", false)
	
	if collision_enabled && is_on_floor():
		_create_spiny.call_deferred()


func _create_spiny() -> void:
	if is_queued_for_deletion():
		#print("Spiny egg queued for deletion, cancelling spiny creation!")
		return
	NodeCreator.prepare_ins_2d(spiny_creation, self).create_2d().call_method(func(node):
		var spr = node.get_node(node.sprite)
		if "free_offscreen" in spr:
			spr.free_offscreen = free_offscreen
		if spr.sprite_frames.has_animation(&"appear"):
			spr.play(&"appear")
	)
	queue_free()
