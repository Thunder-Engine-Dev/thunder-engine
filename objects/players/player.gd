extends GravityBody2D
class_name Player

signal suit_appeared
signal suit_changed(to: PlayerSuit)
signal swam
signal shot
signal threw
signal ground_kicked
signal head_bumped
signal grab_init(node: Node2D)
signal grabbed(side_grabbed: bool)
signal invinciblized(dur: float)
signal starmaned(dur: float)
signal starman_attacked
signal damaged
signal died
signal died_with_body(dead_player_body: Node2D)

enum Warp {
	NONE,
	IN,
	OUT,
}

enum WarpDir {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

const HEAD_SIGNAL_COOLDOWN: int = 1

@export_group("General")
@export var suit: PlayerSuit
@export var circle_transition_on_self: bool = true
@export_group("Physics")
@export_enum("Left: -1", "Right: 1") var direction: int = 1:
	set(to):
		direction = to
		if !direction in [-1, 1]:
			direction = [-1, 1].pick_random()
@export_group("Death", "death_")
@export var death_body: PackedScene = preload("res://engine/objects/players/deaths/player_death.tscn")
@export var death_music_override: AudioStream
@export var death_music_ignore_pause: bool = false
@export var death_wait_time: float = 3.5
@export var death_check_for_lives: bool = true
## Specify where to go after player's death. Leave empty to restart the current scene.
@export_file("*.tscn", "*.scn") var death_jump_to_scene: String = ""
@export var death_stop_music: bool = true

var _physics_behavior: ByNodeScript
var _suit_behavior: ByNodeScript
var _animation_behavior: ByNodeScript
var _grab_behavior: ByNodeScript
var _extra_behavior: ByNodeScript

var flasher: Tween
var holding_item: Node2D = null
var config_buffer: PlayerConfig

var left_right: float
var up_down: float
var jumping: int
var jumped: bool
var running: bool
var attacked: bool
var attacking: bool
var slided: bool

@warning_ignore("unused_private_class_variable")
var _has_jumped: bool
var coyote_time: float
var ghost_speed_y: float
var crouch_forced: bool

var is_climbing: bool
var is_sliding: bool
var is_crouching: bool
var is_skidding: bool
var is_holding: bool
var is_underwater: bool
var is_underwater_out: bool

var has_stuck: bool
var has_stuck_animation: bool
var stuck_block_left: bool
var stuck_block_right: bool
var is_sliding_accelerating: bool
var is_able_to_skid: bool

var slippery_strength: float

var completed: bool

var debug_god: bool
var debug_fly: bool

var warp: Warp
var warp_dir: WarpDir
var no_movement: bool
var ignore_input: bool:
	set(to):
		ignore_input = to
		_set_ignore_input()

var _force_suit: bool
var _suit_appear: bool
var _suit_tree_paused: bool
var _sprite_ready: bool = false

@warning_ignore("unused_private_class_variable")
@onready var _is_ready: bool = true

@onready var control: PlayerControl = PlayerControl.new()
@onready var starman_combo: Combo = Combo.new(self)
@onready var stomping_combo: Combo = Combo.new(self, 10, true, Combo.STOMP_COMBO_ARRAY)
@onready var _stomping_combo_enabled: bool = SettingsManager.get_tweak("stomping_combo", false)
@onready var _suit_pause_tweak: bool = SettingsManager.get_tweak("pause_on_suit_change", false)
@warning_ignore("unused_private_class_variable")
@onready var _skid_tweak = SettingsManager.get_tweak("player_skid_animation", false)
@onready var _autorun_tweak = SettingsManager.get_tweak("autorun", false)
@onready var _damage_tweak = SettingsManager.get_tweak("retro_damage_system", false)
@warning_ignore("unused_private_class_variable")
@onready var _super_jump_tweak = SettingsManager.get_tweak("super_jump_bug", false)
@warning_ignore("unused_private_class_variable")
@onready var _crouch_jump_tweak = SettingsManager.get_tweak("crouch_jumping", true)

@onready var force_override_death_sound: bool = false

@onready var sprite_container: Node2D = $SpriteContainer
@onready var sprite: AnimatedSprite2D = $SpriteContainer/Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collision_recovery: RayCast2D = $CollisionRecovery
@onready var body: ShapeCast2D = $Body
@onready var head: ShapeCast2D = $Head
@onready var underwater: Node = $Underwater
@onready var timer_invincible: Timer = $Invincible
@onready var timer_starman: Timer = $Starman
@onready var attack: ShapeCast2D = $Attack
@onready var bubbler: Timer = $Underwater/Bubbler
@onready var stars: CPUParticles2D = $SpriteContainer/Sprite/Stars
@onready var skid: CPUParticles2D = $SpriteContainer/Sprite/Skid
@onready var skin_particles: GPUParticles2D = $SpriteContainer/Sprite/SkinParticles
@onready var death_sprite: Sprite2D = $SpriteDeath


func _ready() -> void:
	# Transition center at the beginning of the level
	if Scenes.current_scene is Stage2D && circle_transition_on_self:
		Scenes.current_scene.stage_ready.connect(func():
	#Scenes.scene_ready.connect(func():
			var cam := Thunder._current_camera
			if is_instance_valid(cam):
				cam.force_update_scroll()

			#for i in 8: # Deferred 8 frames to ensure the transition works after the player touches checkpoint
			#	await get_tree().physics_frame
			#while !Scenes.current_scene._is_stage_ready:
			var trans := TransitionManager.current_transition
			if is_instance_valid(trans) && trans.has_method("on") && trans.paused:
				trans.on(self)
				trans.paused = false
		, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	elif is_instance_valid(TransitionManager.current_transition):
		Scenes.scene_ready.connect(func():
			var trans := TransitionManager.current_transition
			if is_instance_valid(trans) && trans.has_method("on"):
				trans.on(Vector2(0.5, 0.5), true)
				trans.paused = false
		)

	if !Thunder._current_player_state_path.is_empty():
		suit = load(Thunder._current_player_state_path)
	elif Thunder._current_player_state:
		suit = Thunder._current_player_state
	else:
		var small_suit: PlayerSuit = CharacterManager.get_suit("small")
		Thunder._current_player_state = small_suit
		suit = small_suit
	
	var _global_tweaks = CharacterManager.get_misc_texture("global_skin_tweaks")
	if _global_tweaks && _global_tweaks is Dictionary:
		force_override_death_sound = _global_tweaks.get("force_override_death_sound", false)

	change_suit(suit, false, true)

	Thunder._current_player = self
	add_to_group(&"#lava_body")
	
	Thunder._connect(SettingsManager.settings_updated, _on_settings_updated)
	_on_settings_updated.call_deferred()

	if !is_starman():
		sprite.material.set_shader_parameter(&"mixing", false)
		sprite.material.set_shader_parameter(&"slowed_down", false)

	(func():
		if Data.values.lives == -1 && death_check_for_lives:
			Data.values.lives = ProjectSettings.get_setting("application/thunder_settings/player/default_lives", 4)
	).call_deferred()
	
	_detach_sprite.call_deferred()


var _starman_faded: bool

func _physics_process(delta: float) -> void:
	if !Thunder._current_player_state:
		Thunder._current_player_state = suit
	if is_starman() && \
		timer_starman.time_left > 0.0 && \
		timer_starman.time_left < 1.5 && \
		!_starman_faded:
			_starman_faded = true
			sprite.material.set_shader_parameter(&"slowed_down", true)
			Audio.stop_music_channel(98, true)

	if _stomping_combo_enabled && stomping_combo.get_combo() > 0 && is_on_floor():
		stomping_combo.reset_combo()

func change_suit(to: PlayerSuit, appear: bool = true, forced: bool = false) -> void:
	_force_suit = forced
	_suit_appear = appear
	#suit = to
	if (!to || (suit && suit.name == to.name)) && !_force_suit: return
	suit = to.duplicate()

	if suit.animation_sprites:
		sprite.sprite_frames = SkinsManager.apply_player_skin(suit)
	var _jump = CharacterManager.get_suit_sound("jump", "", suit.name)
	var _swim = CharacterManager.get_suit_sound("swim", "", suit.name)
	var _skid = CharacterManager.get_suit_sound("skid", "", suit.name)
	var _hurt = CharacterManager.get_suit_sound("hurt", "", suit.name)
	var _death = CharacterManager.get_voice_line("death", "")
	suit.physics_config = suit.physics_config.duplicate(true)
	if _jump: suit.physics_config.sound_jump = _jump
	if _swim: suit.physics_config.sound_swim = _swim
	if _skid: suit.physics_config.sound_skid = _skid
	if _hurt: suit.sound_hurt = _hurt[randi_range(0, len(_hurt) - 1)]
	if _death: suit.sound_death = _death[randi_range(0, len(_death) - 1)]
	config_buffer = suit.physics_config.duplicate()

	_physics_behavior = null
	_suit_behavior = null
	_animation_behavior = null
	_extra_behavior = null
	
	if suit.physics_behavior:
		_physics_behavior = ByNodeScript.activate_script(suit.physics_behavior, self)
	if suit.grab_behavior:
		_grab_behavior = ByNodeScript.activate_script(suit.grab_behavior, self)
	if suit.behavior_script:
		_suit_behavior = ByNodeScript.activate_script(suit.behavior_script, self, {suit_resource = suit.behavior_resource})
	if suit.animation_behavior:
		_animation_behavior = ByNodeScript.activate_script(suit.animation_behavior, self)
	if suit.extra_behavior:
		_extra_behavior = ByNodeScript.activate_script(suit.extra_behavior, self, suit.extra_vars)
	if _suit_appear:
		_suit_appear = false
		suit_appeared.emit()
	
	var skin_particle_tweaks = CharacterManager.get_suit_tweak("emit_particles", "", suit.name)
	skin_particles.emitting = skin_particle_tweaks && skin_particle_tweaks.enabled
	if skin_particle_tweaks:
		var _particle_color = skin_particle_tweaks.color
		if _particle_color is String:
			_particle_color = Color.from_string(_particle_color, Color.WHITE)
		skin_particles.modulate = _particle_color
		skin_particles.show_behind_parent = skin_particle_tweaks.show_behind
		skin_particles.lifetime = skin_particle_tweaks.lifetime_sec
		skin_particles.local_coords = skin_particle_tweaks.local_coords
		skin_particles.amount_ratio = skin_particle_tweaks.amount_ratio
		var _particle_off = skin_particle_tweaks.offset
		if !_particle_off is Array:
			_particle_off = [0, 0]
		skin_particles.position = Vector2(_particle_off.front(), _particle_off.back())
	
	if !to.resource_path.is_empty():
		Thunder._current_player_state_path = to.resource_path
	Thunder._current_player_state = suit
	suit_changed.emit(suit)
	
	if appear && _suit_pause_tweak:
		_suit_tree_paused = true
		get_tree().paused = true
		Scenes.custom_scenes.pause._no_unpause = true
		sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		await get_tree().create_timer(suit.appearing_time_sec, true, true).timeout
		sprite.process_mode = Node.PROCESS_MODE_INHERIT
		_suit_tree_paused = false
		get_tree().paused = false
		Scenes.custom_scenes.pause._no_unpause = false
	if !appear && sprite.animation in ["appear", "attack", "attack_air"]:
		sprite.animation = "default"

	_force_suit = false
	_suit_appear = false
	set_deferred("is_hurting", false)


func control_process() -> void:
	left_right = clamp(Input.get_axis(control.left, control.right) * 1.25, -1, 1)
	if stuck_block_left && left_right < 0: left_right = 0
	if stuck_block_right && left_right > 0: left_right = 0
	up_down = Input.get_axis(control.up, control.down)
	jumping = int(Input.is_action_pressed(control.jump)) \
		+ int(Input.is_action_just_pressed(control.jump))
	jumped = Input.is_action_just_pressed(control.jump)
	running = Input.is_action_pressed(control.run) && !_autorun_tweak || \
		!Input.is_action_pressed(control.run) && _autorun_tweak
	attacked = Input.is_action_just_pressed(control.attack)
	attacking = Input.is_action_pressed(control.attack)
	is_crouching = suit && suit.physics_crouchable && !is_sliding && (
			( 
				Input.is_action_pressed(control.down) && is_on_floor()
			) || (crouch_forced && !is_on_floor())
		)
	slided = up_down > 0 \
		&& is_on_floor() && abs(rad_to_deg(get_floor_normal().x)) > 39 && !get_meta(&"not_slidable", false)


func _set_ignore_input() -> void:
	left_right = 0.0
	up_down = 0.0
	jumping = 0
	jumped = false
	running = false
	attacked = false
	attacking = false
	is_crouching = false
	slided = false
	_has_jumped = true


#= Status
func invincible(duration: float = 2) -> void:
	timer_invincible.start(duration)
	invinciblized.emit(duration)


func starman(duration: float = 10) -> void:
	sprite.material.set_shader_parameter(&"mixing", true)
	sprite.material.set_shader_parameter(&"slowed_down", false)
	attack.enabled = true
	timer_starman.start(duration)
	invincible(duration)
	starmaned.emit(duration)
	stars.emitting = true


var is_hurting: bool = false
func hurt(tags: Dictionary = {}, override_behavior: Callable = Callable()) -> void:
	if !suit || debug_god || is_hurting:
		return
	if !tags.get(&"hurt_forced", false) && (is_invincible() || completed || warp > Warp.NONE):
		return
	if warp != Warp.NONE: return
	is_hurting = true

	if override_behavior.is_valid():
		override_behavior.call(tags)
		return

	if suit.gets_hurt_to:
		if _damage_tweak:
			change_suit(CharacterManager.get_suit("small"))
		else:
			change_suit(suit.gets_hurt_to)
		invincible.call_deferred(tags.get(&"hurt_duration", 2))
		Audio.play_sound(suit.sound_hurt, self, false, {pitch = suit.sound_pitch, ignore_pause = true})
	else:
		die(tags)

	damaged.emit()


var is_dying: bool = false
func die(tags: Dictionary = {}, override_behavior: Callable = Callable()) -> void:
	if warp != Warp.NONE: return
	if debug_god: return
	if is_dying: return

	if override_behavior.is_valid():
		override_behavior.call(tags)
		return

	is_dying = true

	if death_stop_music:
		Audio.stop_all_musics()
	Audio.play_music(
		suit.sound_death if !death_music_override || force_override_death_sound else death_music_override,
		1 if death_stop_music else 2,
		{pitch = suit.sound_pitch} if !death_music_ignore_pause else {
			pitch = suit.sound_pitch,
			ignore_pause = true
		}
	)

	var _db: Node2D
	if death_body:
		_db = NodeCreator.prepare_2d(death_body, self).bind_global_transform().call_method(
			func(db: Node2D) -> void:
				db.wait_time = death_wait_time
				db.check_for_lives = death_check_for_lives
				db.jump_to_scene = death_jump_to_scene
				#if _suit_pause_tweak:
				#	Scenes.custom_scenes.pause.paused.connect(db.set_process_mode.bind(Node.PROCESS_MODE_INHERIT))
				#	Scenes.custom_scenes.pause.unpaused.connect(db.set_process_mode.bind(Node.PROCESS_MODE_ALWAYS))
				if death_sprite:
					var dsdup: Node2D = death_sprite.duplicate()
					var character_death_sprite = CharacterManager.get_misc_texture("death")
					if character_death_sprite:
						dsdup.texture = character_death_sprite
					db.add_child(dsdup)
					dsdup.visible = true
		).create_2d().get_node()

	#if _suit_pause_tweak && _db:
	#	get_tree().paused = true
	#	_db.process_mode = Node.PROCESS_MODE_ALWAYS
	#	Scenes.custom_scenes.pause._no_unpause = true

	died.emit()
	died_with_body.emit(_db)
	queue_free()


func is_invincible() -> bool:
	return !timer_invincible.is_stopped()


func is_starman() -> bool:
	return !timer_starman.is_stopped()


func sync_position(sync_camera: bool = true) -> void:
	sprite_container.global_position = global_position.round()
	if !sync_camera: return
	var cam: Camera2D = Thunder._current_camera
	if cam && cam is PlayerCamera2D:
		cam.teleport(true)


func _on_starman_timeout() -> void:
	starman_combo.reset_combo()
	sprite.material.set_shader_parameter(&"mixing", false)
	sprite.material.set_shader_parameter(&"slowed_down", false)
	stars.emitting = false
	attack.enabled = is_sliding
	_starman_faded = false
	var mus_loader = Scenes.current_scene.get_node_or_null("MusicLoader")
	if mus_loader:
		if mus_loader.is_paused:
			mus_loader.play_immediately = true
			mus_loader.unpause_music()
		elif !mus_loader.buffer.is_empty():
			mus_loader.play_immediately = true
			mus_loader.play_buffered()
			print("Buffered play")


func _on_starman_killed(what: Node, result: Dictionary) -> void:
	if what == self: return
	# Combo
	if result.result:
		if starman_combo.get_combo() > 0:
			what.sound_pitch = starman_combo.get_pitch()
		#what.got_killed(&"starman", [&"no_score"])
		if what.get("killing_can_combo"):
			starman_combo.combo()
		starman_attacked.emit()


func _on_settings_updated() -> void:
	skid.visible = SettingsManager.get_quality() != SettingsManager.QUALITY.MIN


func _detach_sprite() -> void:
	sprite_container.reparent(get_parent())
	Thunder.reorder_on_top_of(sprite_container, self)
	sprite_container.reset_physics_interpolation()
	_sprite_ready = true


func _exit_tree() -> void:
	if !_sprite_ready: return
	if !is_instance_valid(sprite_container):
		assert(false, "Trying to free an already freed sprite container")
		return
	sprite_container.queue_free()

func _on_reset_interpolation() -> void:
	if !is_instance_valid(sprite_container): return
	sprite_container.reset_physics_interpolation.call_deferred()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
		_on_reset_interpolation()
