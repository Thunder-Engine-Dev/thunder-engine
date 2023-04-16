extends GeneralMovementBody2D
class_name Projectile

@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER


func _ready():
	super()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _exit_tree():
	if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
		Thunder._current_player.states.projectiles_count += 1
