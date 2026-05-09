extends Node

## Level Part Loader
##
## Use this script to load huge chunks of levels on demand.
## Recommended if your level is lagging due to the amount of objects, and it can be separated by sections.[br]
## A root node of a part can be any Node-derived class, but Node2D is recommended.[br][br]
## Do [b]NOT[/b] instantiate your parts in the level itself - this script automatically does that.

## Insert chunks of levels here, in the order they must appear.
@export var level_parts: Array[PackedScene]
## Checkpoint indexes, where each part must appear. [code]-1[/code] means no checkpoint.
@export var checkpoints_part_indexes: Array[int] = [-1]

var current_ref: Node2D

func _ready() -> void:
	if checkpoints_part_indexes.size() < level_parts.size():
		checkpoints_part_indexes.resize(level_parts.size())
	
	switch_to_part.call_deferred(checkpoints_part_indexes[
		clampi(Data.values.checkpoint, -1, max(checkpoints_part_indexes.size() - 1, 0))
	])


## Switch to the specified part, and remove the previous one if exists.[br]
## Example usage: [signal player_warped_to_pipe_out] signal of Pipe In.
func switch_to_part(index: int) -> void:
	if !level_parts[index]:
		return
	var part = level_parts[index].instantiate()
	Scenes.current_scene.add_child(part)
	if is_instance_valid(current_ref):
		current_ref.queue_free()
	current_ref = part
