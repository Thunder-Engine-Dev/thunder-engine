extends GeneralMovementBody2D
class_name Projectile

@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER


func _ready():
	super()


func _exit_tree():
	if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
		Thunder._current_player.states.projectiles_count += 1
