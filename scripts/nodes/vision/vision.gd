extends VisibleOnScreenNotifier2D

@export var new_rect: Rect2 = Rect2(Vector2(-128, -128), Vector2(256, 256))


func _ready() -> void:
	screen_entered.connect(
		func() -> void:
			rect = new_rect
	)
