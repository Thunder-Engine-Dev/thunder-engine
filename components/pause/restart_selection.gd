extends MenuSelection

@onready var pause: Control = $"../.."
@onready var player: Player = Thunder._current_player
var can_restart: bool = true
var is_dead: bool = false

func _ready() -> void:
	Scenes.scene_ready.connect(_reset)

func _reset() -> void:
	is_dead = false
	modulate.v = 1
	can_restart = false

func _player_died() -> void:
	is_dead = true
	if Data.values.lives == 0: modulate.v = 0.5

func _physics_process(delta):
	super(delta)
	
	player = Thunder._current_player
	var restart_enabled: bool = (
		&"enable_restart_in_pause" in Scenes.current_scene &&
		Scenes.current_scene.enable_restart_in_pause
	)
	if player && restart_enabled && !player.died.is_connected(_player_died):
		player.died.connect(_player_died, CONNECT_ONE_SHOT + CONNECT_DEFERRED)
	
	if !get_tree().paused: return
	if is_dead: return

	if (
		restart_enabled == false ||
		!is_instance_valid(player) ||
		(is_instance_valid(player) && player.completed)
	):
		can_restart = false
		modulate.v = 0.5
	else:
		can_restart = true
		modulate.v = 1
	

func _handle_select() -> void:
	if is_dead && Data.values.lives != 0:
		super()
		Thunder._current_player_state = null
		Scenes.reload_current_scene()
		Data.values.lives -= 1
		Data.values.onetime_blocks = false
		is_dead = false
		Scenes.custom_scenes.pause._no_unpause = false
		pause.toggle()
		return
	if !can_restart: return
	if !player: return
	super()
	Scenes.custom_scenes.pause._no_unpause = false
	pause.toggle()
	player.die()
