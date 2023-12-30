@tool
@icon("./icon.svg")
extends Node2D
class_name Stage2D

## Base stage/scene class[br]
## When the instance of the class gets notified with [member Node._ready], the instance
## will automatically call [method Scenes.register] to make [member Scenes.current_scene] work decently

var _is_stage_ready: bool


## Emitted when p switch starts
signal p_switch_activeates
## Emitted when p switch ends
signal p_switch_deactivates


var p_switch_timer: Timer

func _ready() -> void:
	for i in 5:
		await get_tree().process_frame
	_is_stage_ready = true
	
	p_switch_timer = Timer.new()
	add_child(p_switch_timer)


## Fast method to call [method Scenes.reload_current_scene] in [Stage2D] and its extended classes
func restart() -> void:
	Scenes.reload_current_scene()

## Uses for toggle p switch
func toggle_p_switch(time: float) -> void:
	if !p_switch_timer.is_stopped():
		return
	
	p_switch_activeates.emit()
	p_switch_timer.start(time)
	
	await p_switch_timer.timeout
	
	p_switch_deactivates.emit()

