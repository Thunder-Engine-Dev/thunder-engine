extends NodeModifier
class_name PlayerPhysicsModifier

## Add this group to scenes that you wish to apply this modifier to.
@export var scene_group_name: String
## Player Config to apply when triggered. Key is the character name (e.g. Mario).
@export var apply_config: Dictionary[String, PlayerConfig] = {}
## Which config properties should be applied. Everything not listed here is ignored.
@export var apply_properties: PackedStringArray

var is_applied: bool
@onready var player: Player = $".."

func _ready():
	player.suit_changed.connect(_remove_config.unbind(1), CONNECT_DEFERRED)

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
		if collider && (
			scene_group_name.is_empty() || (scene_group_name && collider.is_in_group(scene_group_name))
		):
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
	if !player || !player.get(&"suit"): return
	if !is_applied:
		var character_config = apply_config.get(CharacterManager.get_character_name(), "Mario")
		for prop in apply_properties:
			player.suit.physics_config[prop] = character_config[prop]
	
	is_applied = true


func _remove_config() -> void:
	if !is_instance_valid(player): return
	if !is_applied: return
	
	for prop in apply_properties:
		player.suit.physics_config[prop] = player.config_buffer[prop]
	
	is_applied = false
