extends GeneralMovementBody2D

const explosion_effect = preload("res://engine/objects/effects/explosion/explosion.tscn")

@export var jumping_speed: float = -250.0
@export var belongs_to: Data.PROJECTILE_BELONGS = Data.PROJECTILE_BELONGS.PLAYER

@onready var texture:Sprite2D = $Texture


func _ready():
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	
	texture.rotation_degrees += 12 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)


func jump(jspeed:float = jumping_speed) -> void:
	super(jspeed)

func explode():
	var effect: Callable = func(eff: Node2D) -> void:
		eff.global_transform = global_transform
	
	NodeCreator.prepare_2d(explosion_effect, self).create_2d().bind_global_transform()
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _exit_tree():
	if belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
		Thunder._current_player.states.projectiles_count += 1
