extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var h_box_container: MenuItemsController = $Control/HBoxContainer
var parent_items_controller: MenuItemsController

func _ready() -> void:
	animation_player.play(&"open")
	await get_tree().create_timer(0.2).timeout
	h_box_container.focused = true


func trigger_hide() -> void:
	h_box_container.focused = false
	animation_player.play_backwards(&"open")
	await get_tree().create_timer(0.3).timeout
	if !is_inside_tree(): return
	queue_free()
