extends Resource
class_name Shaper2D

## Resource that contains a [Shape2D] and its position mainly for [CollisionShape2D]
##
## This resource is used for [CollisionShape2D] or [ShapeCast2D] to easily
## set their shapes and positions

## [Shape2D] used for target [CollisionShape2D]
@export var shape: Shape2D
## [member Node2D.position] for target [CollisionShape2D]
@export var shape_pos: Vector2


## Installs [member shape] for target [param collision_shape] and sets its [member Node2D.position] to [member shape_pos]
func install_shape_for(collision_shape: CollisionShape2D) -> void:
	if !shape: return
	if collision_shape.shape != shape:
		collision_shape.set_deferred(&"shape", shape)
	if collision_shape.position != shape_pos:
		collision_shape.set_deferred(&"position", shape_pos)


## Installs [member shape] for target [param caster] and sets its [member Node2D.position] to [member shape_pos]
func install_shape_for_caster(caster: ShapeCast2D) -> void:
	if !shape: return
	if caster.shape != shape:
		caster.set_deferred(&"shape", shape)
	if caster.position != shape_pos:
		caster.set_deferred(&"position", shape_pos)


func is_shape_equal(collision_shape: CollisionShape2D) -> bool:
	return shape && collision_shape.shape == shape

