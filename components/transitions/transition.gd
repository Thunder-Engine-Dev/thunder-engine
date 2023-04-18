extends Control
class_name Transition
## This is the generic transition class

signal start
signal middle
signal end

## Adds the transition globally and calls the start signal
func build() -> void:
	TransitionManager.accept_transition(self)
	start.emit()
