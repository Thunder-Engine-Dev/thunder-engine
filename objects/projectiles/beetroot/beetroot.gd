extends GeneralMovementBody2D

const explosion_effect: PackedScene = preload("res://engine/objects/effects/explosion/explosion.tscn")

@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER
@export var jumping_speed: float = -450.0
@export var bounces_left: int = 3

var drown: bool = false

@onready var detector:ShapeCast2D = $Attack

signal run_out


func _ready() -> void:
	super()


func bounce(with_sound: bool = true, ceiling: bool = false) -> void:
	if bounces_left <= 0: return
	
	if with_sound:
		Audio.play_sound(preload("res://engine/objects/projectiles/sounds/stun.wav"), self)
	
	turn_x()
	
	if !ceiling: jump(jumping_speed)
	else: vel_set_y(0)
	
	bounces_left -= 1
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	
	if bounces_left == 0:
		run_out.emit()
		collision_layer = 0
		collision_mask = 0


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_tree_exited():
	if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
		Thunder._current_player.states.projectiles_count += 1
