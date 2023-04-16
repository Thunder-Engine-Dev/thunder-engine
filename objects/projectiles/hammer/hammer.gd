extends Projectile

@onready var texture: Sprite2D = $Texture


func _physics_process(delta: float) -> void:
	super(delta)
	
	texture.rotation_degrees += 8 * (-1 if speed.x < 0 else 1) * Thunder.get_delta(delta)

