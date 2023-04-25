extends GeneralMovementBody2D

enum Type {
	SWIM,
	SOLID,
	LEAP,
	TRACK
}

@export_category("Cheep")
@export var type: Type = Type.SWIM:
	set(mode):
		type = mode
		# Note: to make the setter works, you are NOT supposed to reference @onready vars below!
		# Set property for matched type
		if !is_inside_tree():
			return
		match type:
			Type.SWIM:
				interval.start(swimming_interval)
			Type.SOLID:
				collision_shape.set_deferred(&"disabled", false)
			Type.TRACK:
				speed = Vector2.ZERO
				interval.start(tracking_interval)
			Type.LEAP:
				gravity_scale = leaping_gravity_scale
				enemy_attacked.stomping_standard = Vector2.DOWN
		# Reset the property for unmatched one
		if type != Type.SOLID:
			collision_shape.set_deferred(&"disabled", true)
		if type != Type.LEAP:
			gravity_scale = 0
			enemy_attacked.stomping_standard = Vector2.ZERO
		if always_unstompable:
			enemy_attacked.stomping_standard = Vector2.ZERO
@export_group("Cheep General")
@export var always_unstompable: bool
@export_group("Cheep Swimming", "swimming_")
@export var swimming_y_speed: float = 15
@export var swimming_interval: float = 1
@export var swimming_back_to_water: bool = true
@export_group("Cheep Tracking", "tracking_")
@export var tracking_interval: float = 1
@export var tracking_speed: float = 60
@export_group("Cheep Leaping", "leaping_")
@export var leaping_gravity_scale: float = 0.2

var is_spawned: bool:
	set(to):
		is_spawned = to
		if is_spawned:
			visiblity.scale = 5 * Vector2.ONE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var swim_x: ShapeCast2D = $SwimX
@onready var swim_y: ShapeCast2D = $SwimY
@onready var enemy_attacked: Node = $Body/EnemyAttacked
@onready var interval: Timer = $Interval
@onready var visiblity: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	super()
	# Call setter
	type = type


func _physics_process(delta: float) -> void:
	super(delta)
	
	if type == Type.LEAP || !swimming_back_to_water:
		return
	
	_update_detc_pos(delta)
	var out_of_water_x: bool = _in_water_detection(swim_x)
	var out_of_water_y: bool = _in_water_detection(swim_y)
	if out_of_water_x:
		speed.x *= -1
		_update_detc_pos(delta)
	if out_of_water_y:
		speed.y *= -1
		_update_detc_pos(delta)


func _cheep_swimming() -> void:
	match type:
		Type.SWIM:
			vel_set_y(randf_range(-swimming_y_speed, swimming_y_speed))
		Type.TRACK:
			var player: Player = Thunder._current_player
			if !player:
				return
			vel_set(global_position.direction_to(player.global_position).rotated(-global_rotation) * tracking_speed)


func _in_water_detection(caster: ShapeCast2D) -> bool:
	var result: bool = true
	for i in caster.get_collision_count():
		var collider: Area2D = caster.get_collider(i) as Area2D
		if !collider:
			continue
		if collider.is_in_group(&"#water"):
			result = false
	return result


func _update_detc_pos(delta: float) -> void:
	swim_x.position.x = 48 * speed.x * delta
	swim_y.position.y = 48 * speed.y * delta


func _on_screen_exited() -> void:
	if is_spawned:
		queue_free()
