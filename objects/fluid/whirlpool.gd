@tool
extends Area2D

@export_category("Whirlpool")
@export_group("Effect")
@export_range(0.01, 999999.9, 0.01) var bubble_speed_scale: float = 1.0:
	set(to):
		bubble_speed_scale = to
		$Bubbles.speed_scale = bubble_speed_scale
@export_group("Physics")
@export var sucking_motion: Vector2 = Vector2(100, 50)

@onready var bubbles: GPUParticles2D = $Bubbles
@onready var pos_suck: Marker2D = $PosSuck


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		var bub: GPUParticles2D = $Bubbles
		bub.amount = 10 + 5 * ceilf(scale.x)
		return
	else:
		var player: Player = Thunder._current_player
		if !player: return
		
		if overlaps_body(player) && player.is_underwater:
			var pos: Vector2 = global_transform.affine_inverse().basis_xform(pos_suck.global_position)
			var p_pos: Vector2 = global_transform.affine_inverse().basis_xform(player.global_position)
			
			player.global_position += Vector2(sucking_motion.x * signf(pos.x - p_pos.x), sucking_motion.y * signf(pos.y - p_pos.y)) * delta
			player.move_and_collide(Vector2.ZERO)
