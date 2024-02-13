extends Control

@export var scene: String

var loading_status: int
var progress: Array[float]

@onready var progress_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	# Request to load the target scene:
	ResourceLoader.load_threaded_request(scene)
	
func _process(_delta: float) -> void:
	# Update the status:
	loading_status = ResourceLoader.load_threaded_get_status(scene, progress)
	
	# Check the loading status:
	match loading_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			progress_bar.value = progress[0] * 100.0 # Change the ProgressBar value
		ResourceLoader.THREAD_LOAD_LOADED:
			# When done loading, change to the target scene:
			#Scenes._current_scene_buffer = ResourceLoader.load_threaded_get(scene)
			Scenes.load_scene_from_packed.call_deferred(ResourceLoader.load_threaded_get(scene))
		ResourceLoader.THREAD_LOAD_FAILED:
			# Well some error happend:
			print("Error. Could not load Resource")
