extends Node

## Sets the seed for Random Number Generator for enemies and other hazards to use.
## Affects only the current scene, and will automatically randomize the seed when freed.\n
## If you need to make this script affect your custom stuff too, see [member Thunder.rng].

@export var seed_value: int = 100
@export var log_output: bool = false

func _enter_tree() -> void:
	Thunder.rng.set_seed(seed_value)
	if log_output:
		print("Random set.")

func _exit_tree() -> void:
	Thunder.rng.randomize_seed()
	if log_output:
		print("Random returned to normal")
