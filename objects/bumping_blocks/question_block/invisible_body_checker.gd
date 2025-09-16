extends Area2D

## This script is needed for external attacks that should open invisible question blocks,
## e.g. a beetroot or a shell.

var _active: bool = true

@onready var parent: StaticBumpingBlock = $".."

func _ready() -> void:
	if parent.initially_visible_and_solid:
		queue_free.call_deferred()
		return
	parent.bumped.connect(func() -> void:
		_active = false
		queue_free.call_deferred()
	)


func got_bumped(by_player: bool = false) -> void:
	if !_active: return
	if parent._triggered: return
	if by_player: return
	
	parent.call_bump()
	
