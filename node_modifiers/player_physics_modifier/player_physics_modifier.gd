extends NodeModifier
class_name PlayerPhysicsModifier

## Add this group to scenes that you wish to apply this modifier to.
@export var scene_group_name: String
## Player Config to apply when triggered. Key is the character name (e.g. Mario).
@export var apply_config: Dictionary[String, PlayerConfig] = {}
## Which config properties should be applied. Everything not listed here is ignored.
@export var apply_properties: PackedStringArray

var _cached_config: PlayerConfig

var is_applied: bool
@onready var player: Player = $".."

func _ready():
	player.suit_changed.connect((func(a = null):
		_cached_config = null
		_remove_config()
	), CONNECT_DEFERRED + CONNECT_REFERENCE_COUNTED + CONNECT_ONE_SHOT)

func _physics_process(delta):
	var _player = null
	
	if player && !is_applied:
		if !is_instance_valid(player):
			_deinitialise()
			return
		_add_config()
	
	var kc: = KinematicCollision2D.new()
	target_node.test_move(target_node.global_transform, Vector2.DOWN.rotated(target_node.global_rotation), kc)
	if kc:
		var collider: = kc.get_collider()
		if collider && collider.is_in_group(scene_group_name):
			_player = target_node
			_logic()
	
	if !_player && player && is_applied:
		_remove_config()
		_end_logic(true)

func _logic() -> void:
	pass

func _end_logic(remove: bool) -> void:
	pass

func _deinitialise() -> void:
	pass

func _add_config() -> void:
	if !player: return
	if !_cached_config:
		var new_config = player.config_buffer.duplicate(true)
		var character_config = apply_config.get(CharacterManager.get_character_name(), "Mario")
		for prop in apply_properties:
			new_config[prop] = character_config[prop]
		_cached_config = new_config
	
	player.suit.physics_config = _cached_config
	is_applied = true


func _remove_config() -> void:
	if !is_instance_valid(player): return
	if !is_applied: return
	
	player.suit.physics_config = player.config_buffer
	is_applied = false
