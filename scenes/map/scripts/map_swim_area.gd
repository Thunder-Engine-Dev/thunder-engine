extends Area2D

@onready var player = Scenes.current_scene.get_node("Player")

func _ready():
	var hitbox = Scenes.current_scene.get_node("Player/Player/hitbox")
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area2D) -> void:
	if area.get_instance_id() == get_instance_id():
		player.player.play("swim")


func _on_area_exited(area: Area2D) -> void:
	if area.get_instance_id() == get_instance_id():
		player.player.play("walk")
