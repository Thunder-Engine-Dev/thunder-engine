extends Control
class_name Transition
## This is the generic transition class

signal start
signal middle
signal end

var correct_aspect_ratio: bool = true

## Adds the transition globally and calls the start signal
func build() -> void:
	TransitionManager.accept_transition(self)
	start.emit()
