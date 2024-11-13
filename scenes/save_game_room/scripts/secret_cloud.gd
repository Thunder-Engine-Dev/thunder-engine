extends AnimatedSprite2D

@export var SECRET_SOUND: AudioStream = preload("res://engine/scenes/save_game_room/sounds/cloud_secret.wav")
@export var LIFE_MUSHROOM: PackedScene = preload("res://engine/objects/powerups/life_mushroom/life_mushroom.tscn")

@export var tries: int = 3
var progress: int = 0

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.body_entered.connect(func(body: Node2D):
		if progress == -1: return
		if body is Projectile && "ball" in body.name:
			progress += 1
		
		if progress >= tries:
			animation = "secret"
			Audio.play_sound(SECRET_SOUND, self, true, {volume = -6})
			progress = -1
			
			var life: Node2D = LIFE_MUSHROOM.instantiate()
			life.position = global_position + Vector2(0, 32)
			Scenes.current_scene.add_child.call_deferred(life)
			life.add_to_group(&"_secret_cloud_result")
			life.z_index = -6
			if "appear_visible" in life:
				life.appear_visible = 1
	)


func reset_cloud() -> void:
	progress = 0
	animation = "default"
	get_tree().call_group(&"_secret_cloud_result", &"queue_free")
