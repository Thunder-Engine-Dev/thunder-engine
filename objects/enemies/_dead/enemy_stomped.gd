extends GeneralMovementBody2D

@export var disappearing_strength:float = 0.1

var destroying: bool

@onready var collision_box:CollisionShape2D = $Collision


func _ready() -> void:
	super()
	
	for i in get_children():
		if i is Sprite2D:
			collision_box.shape.size = i.texture.get_size()
		elif i is AnimatedSprite2D:
			collision_box.shape.size = i.sprite_frames.get_frame_texture(i.animation,i.frame).get_size()

func _process(delta: float) -> void:
	if !destroying: return
	
	modulate.a -= 0.1 * Thunder.get_delta(delta)
	if modulate.a <= 0: queue_free()
