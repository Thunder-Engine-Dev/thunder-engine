extends RigidBody2D

var id: int
var amount: int
var chomp: Node2D
var pile: Node2D

var _is_chained: bool = true

@onready var vis: VisibleOnScreenEnabler2D = $VisibleOnScreenNotifier2D


func _physics_process(delta: float) -> void:
	if !_is_chained:
		return
	if !chomp || !pile: 
		return
	global_position = pile.global_position.lerp(chomp.global_position, float(id) / float(amount))
	reset_physics_interpolation()


func get_transformed_vector(vec: Vector2) -> Vector2:
	return chomp.global_transform.basis_xform(vec)

func disconnect_chomp() -> void:
	if is_inside_tree():
		vis.queue_free()
		freeze = false
		linear_velocity = -get_gravity().normalized().rotated(randf_range(-PI / 6, PI / 6)) * randf_range(250, 350)
		
		await get_tree().create_timer(1.5, false).timeout
		var tw: Tween = create_tween()
		tw.tween_property(self, ^"modulate:a", 0.0, 1)
		await tw.finished
		queue_free()
	_is_chained = false
