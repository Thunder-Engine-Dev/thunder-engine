extends PointLight2D

@export var min_energy: float = 0.5
@export var max_energy: float = 1.2
@export var min_scale: float = 0.8
@export var max_scale: float = 1.2
@export var random_pause: bool = true

var rand_pause: float = randf_range(0.05, 1.7)
var tw: Tween
var tw2: Tween

func _ready() -> void:
	if Thunder.view.is_getting_closer(self, 32):
		random_pause = false
	if random_pause:
		await get_tree().create_timer(rand_pause, false, false, false).timeout
	tw = create_tween().set_loops()
	tw.tween_property(self, "energy", min_energy, 0.8)
	tw.tween_property(self, "energy", max_energy, 1.0)
	tw2 = create_tween().set_loops()
	tw2.tween_property(self, "scale", Vector2.ONE * min_scale, 0.8)
	tw2.tween_property(self, "scale", Vector2.ONE * max_scale, 1.0)
	SettingsManager.settings_updated.connect(_settings_updated)
	_settings_updated.call_deferred()

func _settings_updated() -> void:
	if !is_visible_in_tree():
		if tw && tw.is_running():
			tw.pause()
			tw2.pause()
	else:
		if tw && !tw.is_running():
			tw.play()
			tw2.play()
