extends Transition

const ANIMATION_NAME: StringName = &"FadePixelate"

var paused: bool = false
var speed_closing: float = 2.2
var speed_opening: float = -2.2

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	name = "blur_transition"
	start.emit()
	animation_player.play(ANIMATION_NAME)
	animation_player.speed_scale = -speed_opening
	animation_player.animation_finished.connect(_end_transition,
		CONNECT_ONE_SHOT
	)

## Sets the center of transition on some node
func on(ref: Variant) -> Transition:
	return self

#func start_transition(speed: float = 1.0) -> void:
	#if animation_player.is_playing():
		#animation_player.stop(true)
#
		##$AnimationPlayer.connect('animation_finished', self, '_end_transition', [], CONNECT_ONESHOT)
#
	#animation_player.playback_speed = speed
	#animation_player.play(ANIMATION_NAME)

func _end_transition(anim_name: StringName) -> void:
	middle.emit()
	animation_player.play_backwards.call_deferred(ANIMATION_NAME)
	animation_player.speed_scale = speed_closing
	animation_player.animation_finished.connect(
		_transition_ended,
		CONNECT_ONE_SHOT
	)


func _transition_ended(anim_name: StringName) -> void:
	end.emit()
	#print('[SceneTransition] Fade out ended')


func _physics_process(delta: float) -> void:
	if paused && animation_player.is_playing():
		animation_player.pause()
		return
	if !paused && !animation_player.is_playing():
		animation_player.play()
