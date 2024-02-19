extends Transition

const ANIMATION_NAME = &"FadePixelate"

var paused: bool = false
var speed_closing: float = 0.4
var speed_opening: float = -0.4
var progress: float = 1.0
var middle_switch: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	start.emit()
	animation_player.play(ANIMATION_NAME)
	animation_player.speed_scale = -speed_opening
	animation_player.animation_finished.connect(func():
		middle.emit()
		animation_player.play_backwards.call_deferred(ANIMATION_NAME)
		animation_player.speed_scale = speed_closing
		animation_player.animation_finished.connect(
			emit_signal.bind(&"end"),
			CONNECT_ONE_SHOT | CONNECT_DEFERRED
		),
		CONNECT_ONE_SHOT
	)

## Sets the center of transition on some node
func on(ref: Variant) -> Transition:
	return self

## Sets the speeds
func with_speeds(s_closing: float, s_opening: float) -> Transition:
	speed_closing = s_closing
	speed_opening = s_opening
	return self

func start_transition(speed: float = 1.0) -> void:
	if animation_player.is_playing():
		animation_player.stop(true)

		#$AnimationPlayer.connect('animation_finished', self, '_end_transition', [], CONNECT_ONESHOT)

	animation_player.playback_speed = speed
	animation_player.play(ANIMATION_NAME)

func _end_transition(anim_name: String) -> void:
	emit_signal('fade_in_ended')
	$AnimationPlayer.call_deferred('play_backwards', anim_name)
#	if !$AnimationPlayer.is_connected('animation_finished', self, '_transition_ended'):

#		$AnimationPlayer.connect('animation_finished', self, '_transition_ended', [], CONNECT_ONESHOT)
	


func _transition_ended(_anim_name) -> void:
	emit_signal('fade_out_ended')
	#print('[SceneTransition] Fade out ended')
	$AnimationPlayer.play('RESET')

func _physics_process(delta: float) -> void:
	if paused && animation_player.is_playing():
		animation_player.pause()
		return
	if !paused && !animation_player.is_playing():
		animation_player.play()
	
