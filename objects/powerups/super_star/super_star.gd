extends Powerup

@export var starman_duration: float = 10
@export var starman_music: Resource = preload("res://engine/objects/powerups/super_star/music-starman.it")

@onready var player = Thunder._current_player
@onready var _first_jump: bool = true

func _physics_process(delta: float) -> void:
	super(delta)
	if is_on_floor():
		jump(175 if _first_jump else 250)
		_first_jump = false
	if !appear_distance:
		$Sprite.speed_scale = 5

func collect() -> void:
	if appear_distance: return
	
	if score > 0:
		ScoreText.new(str(score), self)
		Data.add_score(score)
	
	queue_free()
	
	Audio.play_sound(pickup_powerup_sound, self, false, {pitch = sound_pitch})
	player.starman(starman_duration)
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if !mus_loader: return
	mus_loader.play_immediately = false
	mus_loader.pause_music()
	for i in Audio._music_tweens:
		i.kill()
	if Audio._music_channels.has(98) && is_instance_valid(Audio._music_channels[98]):
		Audio._music_channels[98].volume_db = 0
	else:
		var _sfx = CharacterManager.get_sound_replace(starman_music, starman_music, "starman", false)
		if "loop" in _sfx: _sfx.loop = true
		Audio.play_music(_sfx, 98, { volume = 0 })
	player._starman_faded = false
