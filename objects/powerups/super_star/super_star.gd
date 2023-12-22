extends Powerup

@export var starman_duration: float = 10
@export var starman_music: Resource = preload("res://engine/objects/powerups/super_star/music-starman.ogg")

var player = Thunder._current_player

func _physics_process(delta: float) -> void:
	super(delta)
	if is_on_floor():
		jump(250)
	if !appear_distance:
		$Sprite.speed_scale = 5

func collect() -> void:
	super()
	player.starman(starman_duration)
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if !mus_loader: return
	mus_loader.play_immediately = false
	mus_loader.pause_music()
	Audio.play_music(starman_music, 98)
