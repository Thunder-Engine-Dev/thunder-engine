extends Powerup

const JUMP_SOUND = preload("res://engine/objects/players/prefabs/sounds/kick.wav")
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	audio_stream_player_2d.stream = JUMP_SOUND

func _physics_process(delta: float) -> void:
	super(delta)
	if is_on_floor() && !appear_distance:
		jump(350)
		audio_stream_player_2d.play()
