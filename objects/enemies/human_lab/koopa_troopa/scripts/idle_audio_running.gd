extends Timer

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"

func _ready() -> void:
	await get_tree().create_timer(1.5, false, false, true).timeout
	start()
	timeout.connect(_on_timeout)


func _on_timeout() -> void:
	if audio_stream_player_2d.playing: return
	if randi_range(0, 9) == 1:
		audio_stream_player_2d.play()
