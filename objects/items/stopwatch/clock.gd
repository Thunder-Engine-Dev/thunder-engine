extends Powerup

const STOPWATCH = preload("res://engine/objects/items/stopwatch/stopwatch.wav")

@export var active_for_sec: float = 10.0

var stopwatch_tw: Tween
var stopwatch_active: bool

@onready var sprite: AnimatedSprite2D = $Sprite

func collect() -> void:
	if score > 0:
		ScoreText.new(str(score), self)
		Data.add_score(score)
	
	if Data.values.stopwatch <= 0.0:
		Data.values.stopwatch = active_for_sec
		activate_stopwatch()
	else:
		Data.values.stopwatch = active_for_sec
	
	var powerup_sfx = CharacterManager.get_sound_replace(pickup_powerup_sound, DEFAULT_POWERUP_SOUND, "bonus_activate", false)
	
	Audio.play_sound(powerup_sfx, self, false, {pitch = sound_pitch, ignore_pause = true})


func activate_stopwatch(hide_original: bool = true) -> void:
	if hide_original && sprite.visible:
		$VisibleOnScreenEnabler2D.queue_free()
		process_mode = Node.PROCESS_MODE_INHERIT
		sprite.hide()
		$Body.monitoring = false
		$Body.monitorable = false
		$PointLight2D.enabled = false
		$Collision.set_deferred(&"disabled", true)
		
	if stopwatch_active:
		return
	stopwatch_active = true
	_pause_enemies()
	Data.stopwatch_activated.emit()
	
	if !stopwatch_tw:
		stopwatch_tw = create_tween().set_loops()
		stopwatch_tw.tween_interval(max(0.2, 0.55 * Engine.time_scale))
		stopwatch_tw.tween_callback(Audio.play_1d_sound.bind(STOPWATCH, false, {"volume": 3}))
	

func _physics_process(delta: float) -> void:
	if stopwatch_active:
		Data.values.stopwatch = max(Data.values.stopwatch - delta, 0)
		if !is_instance_valid(Thunder._current_player) || Data.values.stopwatch <= 0:
			_cancel_stopwatch()

## Cancelling Stopwatch Item
func _cancel_stopwatch() -> void:
	Data.values.stopwatch = 0.0
	Data.stopwatch_cancelled.emit()
	if stopwatch_tw:
		stopwatch_tw.kill()
		stopwatch_tw = null
	_resume_enemies()
	
	queue_free()


func _pause_enemies() -> void:
	print(get_groups())
	for i in get_tree().get_nodes_in_group(&"end_level_sequence"):
		if i is Projectile:
			if i.belongs_to == Data.PROJECTILE_BELONGS.PLAYER:
				continue
			i.queue_free()
			continue
		if !i.get(&"_center"): continue
		var vis = Thunder.get_child_by_class_name(i._center, "VisibleOnScreenNotifier2D")
		if vis:
			var connections := vis.get_signal_connection_list(&"screen_exited")
			for j in connections:
				print(j.callable)
			vis.hide()
		i._center.process_mode = Node.PROCESS_MODE_DISABLED
		if i._center.has_node(^"Body"):
			i._center.get_node(^"Body").process_mode = Node.PROCESS_MODE_ALWAYS
		if i._center.get("turn_sprite") && is_instance_valid(i._center.get("sprite_node")):
			i._center.sprite_node.flip_h = i._center.speed.x < 0

func _resume_enemies() -> void:
	for i in get_tree().get_nodes_in_group(&"end_level_sequence"):
		if !i.get(&"_center"): continue
		var vis = Thunder.get_child_by_class_name(i._center, "VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
		if vis: vis.show()
		if vis && "enable_node_path" in vis && vis.enable_node_path == vis.get_path_to(i._center):
			if vis.is_on_screen():
				i._center.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			i._center.process_mode = Node.PROCESS_MODE_INHERIT
		if i._center.has_node(^"Body"):
			i._center.get_node(^"Body").process_mode = Node.PROCESS_MODE_INHERIT
