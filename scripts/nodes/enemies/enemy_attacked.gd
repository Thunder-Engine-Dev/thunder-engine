# Node should be placed as a child of _area2D
extends Node

## Node that made the node [member center_node] an enemy that can be damaged
##
## This node is used in objectial scenes, like enemies, to give them capability of being damaged
## via attackers like projectiles, shells, the starman, etc.

const COIN_EFFECT = preload("res://engine/objects/effects/coin_effect/coin_effect.tscn")
const COIN = preload("res://engine/objects/items/coin/coin.wav")

@export_category("EnemyAttacked")
@export_group("General")
## The node that you are going to define as an enemy capable to be damaged
@export_node_path("Node2D") var center_node: NodePath = ^"../.."
@export_group("Stomping","stomping_")
## If [code]true[/code], the enemy can be damaged via player's stomping
@export var stomping_enabled: bool = true
## If [code]true[/code], the enemy will hurt player if the player fails
## stomping or directly touches it
@export var stomping_hurtable: bool = true
## The normal that defines the success and failure of player's stomping[br]
## For example, if you set this to Vector2(0,-1) and the player stomps onto it, the
## player will fail stomping and get hurt[br]
## [b]Note:[/b] It's recommended to normalize this vector
@export var stomping_standard: Vector2 = Vector2.DOWN
## Offset of detection of stomping, used to make the detection
## more precise and flexible
@export var stomping_offset: Vector2
## Corpse of the enemy stomped by the player
@export var stomping_creation: InstanceNode2D
## Scores given to the player when the enemy gets stomped
@export var stomping_scores: int
## Sound triggered when the enemy gets stomped
@export var stomping_sound: AudioStream
## Minimum of player's jumping speed, triggered when player stomps onto
## the enemy and you [b]aren't[/b] holding the jumping key
@export var stomping_player_jumping_min: float = 450
## Maximum of player's jumping speed, triggered when player stomps onto
## the enemy and you [b]are[/b] holding the jumping key
@export var stomping_player_jumping_max: float = 700
@export var stomping_delay_frames: float = 5
@export_group("Killing","killing_")
## If [code]true[/code], the enemy will be able to be killed by attackers
## like projectiles, shells, the starman, etc
@export var killing_enabled: bool = true
## Attackers listed with [code]false[/code] will be blocked by the enemy
## and the attack will be regarded as failed one
## [b]Note:[/b] For the attack of shells, there is a "shell_defence" as integer that
## determines the enemy killed if the shell's one is greater than this one
@export var killing_immune: Dictionary = {
	Data.ATTACKERS.head: false,
	Data.ATTACKERS.starman: false,
	Data.ATTACKERS.shell: false,
	&"shell_defence": 0, # Available only when Data.ATTACKERS.shell is "true"
	&"shell_forced": false, # DO NOT REMOVE THIS!!
	Data.ATTACKERS.fireball: false,
	Data.ATTACKERS.beetroot: false,
	Data.ATTACKERS.iceball: false,
	Data.ATTACKERS.hammer: false,
	Data.ATTACKERS.boomerang: false,
}
## Corpse of the enemy killed by the attacker
@export var killing_creation: InstanceNode2D
## Scores give by the enemy when the enemy gets killed
@export var killing_scores: int
## Sound triggered when the enemy gets killed successfully
@export var killing_sound_succeeded: AudioStream
## Sound triggered when the enemy blocks the attacker
@export var killing_sound_failed: AudioStream
## Will turn the enemy on screen into a coin upon touching the goal gate
@export var turn_into_coin_on_level_end: bool = true
@export_group("Sound", "sound_")
@export var sound_pitch: float = 1.0
@export_group("Extra")
## Custom vars for [member custom_scipt][br]
@export var custom_vars: Dictionary
## Custom [ByNodeScript] to extend functions
@export var custom_script: Script

var _stomping_delayer: SceneTreeTimer:
	get = get_stomping_delayer

@warning_ignore("unused_private_class_variable")
@onready var _extra_script: Script = ByNodeScript.activate_script(custom_script, self, custom_vars)
@onready var _center: Node2D = get_node_or_null(center_node)

@onready var _stomping_combo_enabled: bool = SettingsManager.get_tweak("stomping_combo", false)

## Emitted when the enemy gets stomped by the player
signal stomped
## Emitted when the enemy gets stomped successfully
signal stomped_succeeded
## Emitted when the enemy touches the player directly
signal stomped_failed
## Emitted when the enemy gets killed by the attacker
signal killed
## Emitted when the enemy gets killed successfully
signal killed_succeeded
## Emitted when the enemy blocks the attacker
signal killed_failed
## Emitted when the type of enemy attack is marked as "signal"
signal attack_custom_signal

var _on_killed: bool # To prevent multiple creation by multiple attackers


func _ready() -> void:
	stomped_succeeded.connect(_lss)
	killed_succeeded.connect(_lks)
	killed_failed.connect(_lkf)
	if turn_into_coin_on_level_end:
		add_to_group(&"end_level_sequence")


func _lss():
	Audio.play_sound(stomping_sound, _center, false, {pitch = sound_pitch})
func _lks():
	Audio.play_sound(killing_sound_succeeded, _center, false, {pitch = sound_pitch})
func _lkf():
	Audio.play_sound(killing_sound_failed, _center, false, {pitch = sound_pitch})


## Makes the enemy stomped by the player, usually triggered
## by the player[br]
## If [param offset] set, the actual offset will be [member stomping_offset]
## + [param offset]
func got_stomped(by: Node2D, vel: Vector2, offset: Vector2 = Vector2(0, -2)) -> Dictionary:
	var result: Dictionary
	
	if !stomping_enabled || _stomping_delayer: return result
	
	if !_center:
		push_error("[No Center Node Error] No _center node set. Please check if you have set the _center node of EnemyAttacked. At " + str(get_path()))
		return result
	
	var dot: float = by.global_position.direction_to(
		_center.global_transform.translated(stomping_offset + offset).get_origin()
	).dot(stomping_standard.rotated(_center.global_rotation))
	var dotdown: float = vel.dot(stomping_standard.rotated(_center.global_rotation))
	
	stomped.emit()
	if dot > 0 && dotdown >= 0:
		stomping_delay()
		stomped_succeeded.emit()
		if stomping_scores > 0:
			if !_stomping_combo_enabled:
				ScoreText.new(str(stomping_scores), _center)
				Data.values.score += stomping_scores
			elif is_instance_valid(by):
				var _do_combo: bool = true
				if by.stomping_combo.get_combo() == 0:
					var try = Combo.STOMP_COMBO_ARRAY.find(stomping_scores)
					if try > 0:
						by.stomping_combo._combo = try
					else:
						var combo_size: int = len(Combo.STOMP_COMBO_ARRAY)
						for i in combo_size:
							if stomping_scores < Combo.STOMP_COMBO_ARRAY[i]:
								by.stomping_combo._combo = max(0, i)
								_do_combo = false
								ScoreText.new(str(stomping_scores), by)
								Data.values.score += stomping_scores
								break
				if _do_combo:
					by.stomping_combo.combo()
		
		_creation(stomping_creation)
		
		result = {
			result = true,
			jumping_min = stomping_player_jumping_min,
			jumping_max = stomping_player_jumping_max
		}
	elif stomping_hurtable:
		if by is Player && by.is_invincible(): return result
		stomped_failed.emit()
		result = {result = false}
	
	return result


## Makes the enemy killed by a certain attacker[br]
## [param by] is type of the attacker, see [member killing_immune][br]
## You can give the extra behavior by inputting [param special_tags]
func got_killed(by: StringName, special_tags: Array = [], trigger_killed_failed: bool = true) -> Dictionary:
	var result: Dictionary
	
	if !killing_enabled || !by in killing_immune || _on_killed: 
		return result
	
	_on_killed = true
	var shell_attack := false
	
	if killing_immune[by]:
		if trigger_killed_failed:
			killed_failed.emit()
		
		result = {
			result = false,
			attackee = self
		}
	else:
		if &"shell_attack" in special_tags:
			shell_attack = true
		
		killed_succeeded.emit()
		
		_creation(killing_creation)
		
		var no_score: bool = &"no_score" in special_tags
		if killing_scores > 0 && !no_score:
			ScoreText.new(str(killing_scores), _center)
			Data.values.score += killing_scores
		
		result = {
			result = true,
			attackee = self
		}
		if shell_attack:
			result.type = &"shell"
	
	# Reset _on_killed status to allow killing
	get_tree().physics_frame.connect(func():
		_on_killed = false
	, CONNECT_ONE_SHOT)
	
	return result


func _creation(creation: InstanceNode2D) -> void:
	if !creation: return
	
	var vars: Dictionary = {
		enemy_attacked = self,
	}
	NodeCreator.prepare_ins_2d(creation, _center).execute_instance_script(vars).create_2d()


func stomping_delay() -> void:
	_stomping_delayer = get_tree().create_timer(get_physics_process_delta_time() * stomping_delay_frames)
	_stomping_delayer.timeout.connect(
		func() -> void:
			_stomping_delayer = null
	)


func get_stomping_delayer() -> SceneTreeTimer:
	return _stomping_delayer


func _on_level_end() -> void:
	if !killing_enabled: return
	if !Thunder.view.is_getting_closer(_center, 32):
		if Thunder.view.is_getting_closer(_center, 320):
			_center.queue_free.call_deferred()
		return
	Audio.play_1d_sound(COIN)
	NodeCreator.prepare_2d(COIN_EFFECT, _center).bind_global_transform().create_2d().call_method(func(node):
		node.score_given = 1000
	)
	Data.add_coin()
	_center.queue_free.call_deferred()
