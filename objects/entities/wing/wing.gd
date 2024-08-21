extends AnimatedSprite2D

@export_category("Wing")
@export var flip_as_parent: bool = true
@export var follow_parent_animation_speed: bool = true

@onready var sprite: AnimatedSprite2D = get_parent() as AnimatedSprite2D
@onready var pos_x: float = position.x


func _ready() -> void:
	if sprite && follow_parent_animation_speed:
		sprite_frames.set_animation_speed(animation, sprite.sprite_frames.get_animation_speed(sprite.animation))
		_physics_process(0)


func _physics_process(_delta: float) -> void:
	if flip_as_parent:
		position.x = -pos_x if sprite.flip_h else pos_x
		flip_h = sprite.flip_h
