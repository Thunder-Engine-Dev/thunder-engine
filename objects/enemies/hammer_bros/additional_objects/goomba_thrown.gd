extends GeneralMovementBody2D

@export var goomba_creation: InstanceNode2D
@export var rotation_speed: float = 22.5
@export var limit_of_spawned_enemies: int = 25
@export var enemy_life_time: float = 15

@onready var solid_checker: Area2D = $SolidChecker
@onready var col: CollisionShape2D = $Collision
@onready var visible_on_screen_enabler_2d: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D

var collision_enabled: bool = false
var _is_ready: bool = false

func _ready() -> void:
	life_time = 5
	for i in 2:
		await get_tree().physics_frame
	_is_ready = true

func _physics_process(delta: float) -> void:
	super(delta)
	get_node(sprite).rotation_degrees += rotation_speed * Thunder.get_delta(delta)
	if !_is_ready: return
	
	if !collision_enabled:
		if solid_checker.get_overlapping_bodies().size() == 0 && speed.y > 0:
			collision_enabled = true
			col.set_deferred(&"disabled", false)
	
	if collision_enabled && is_on_floor():
		while (
			get_tree().get_node_count_in_group(&"#spawned_by_throw") > limit_of_spawned_enemies &&
			is_inside_tree() && !is_queued_for_deletion()
		):
			var enemy = get_tree().get_first_node_in_group(&"#spawned_by_throw")
			if is_instance_valid(enemy) && enemy is Node:
				enemy.remove_from_group(&"#spawned_by_throw")
				enemy.queue_free()
		
		NodeCreator.prepare_ins_2d(goomba_creation, self).call_method(
			func(enemy: Node):
				var en_attacked = enemy.get_node_or_null("Body/EnemyAttacked")
				if en_attacked:
					en_attacked.stomping_delay_frames = 0.0
		).create_2d().call_method(
			func(enemy: Node) -> void:
				enemy.add_to_group(&"#spawned_by_throw")
				enemy.life_time = enemy_life_time
				var groups = get_groups().filter(func(st): return "_spawn" in st)
				for i in groups:
					enemy.add_to_group(i)
		)
		queue_free()
