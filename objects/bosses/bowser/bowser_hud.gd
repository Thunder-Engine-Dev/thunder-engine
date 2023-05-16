extends CanvasLayer

var bowser: Node2D

@onready var head: TextureRect = $Head
@onready var life: TextureRect = $Head/Life
@onready var init_pos_y: float = head.get_viewport_transform().affine_inverse().origin.y -256
@onready var to_pos_y: float = head.position.y


func _ready() -> void:
	head.position.y = init_pos_y


func life_changed(lives: int) -> void:
	if !life.texture: return
	
	if lives > 0 && head.position.y != to_pos_y:
		var tween: Tween = create_tween()
		tween.tween_property(head, "position:y", to_pos_y, 1)
	elif lives <= 0 && head.position.y != init_pos_y:
		var tween: Tween = create_tween()
		tween.tween_property(head, "position:y", init_pos_y, 1)
	
	if lives <= 0: life.visible = false
	else: life.visible = true
	
	life.position.x = -life.texture.get_size().x * lives
	life.size.x = abs(life.position.x)
