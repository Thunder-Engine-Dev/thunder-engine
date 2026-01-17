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

## Run this every process frame
var _prev_delta: float = -1
func _calculate_delta_lag(delta: float) -> bool:
	if _prev_delta == -1:
		_prev_delta = delta
	var _lag_spike: bool = false
	if delta / _prev_delta > 2:
		_lag_spike = true
	_prev_delta = delta
	return _lag_spike
