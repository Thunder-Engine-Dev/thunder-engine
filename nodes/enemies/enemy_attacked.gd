# Node should be placed as a child of Area2D
extends Node

const PROJECTILE_IMMUINE: Dictionary = {
	Data.ATTACKERS.head: false,
	Data.ATTACKERS.starman: false,
	Data.ATTACKERS.shell: false,
	&"shell_defence": 0, # Available only when Data.ATTACKERS.shell is "true"
	Data.ATTACKERS.fireball: false,
	Data.ATTACKERS.beetroot: false,
	Data.ATTACKERS.iceball: false,
	Data.ATTACKERS.hammer: false,
}

@export_category("EnemyAttacked")
@export_group("General")
@export_node_path(Node2D) var center_node: NodePath = ^"../.."
@export_node_path(AudioStreamPlayer2D) var sound_player: NodePath = ^"Sound"
@export_group("Stamping","stamping_")
@export var stamping_enabled: bool = true
@export var stamping_available: bool = true
@export var stamping_hurtable: bool = true
@export var stamping_standard: Vector2 = Vector2.DOWN
@export var stamping_offset: Vector2
@export var stamping_creation: Node2DCreation
@export var stamping_scores: int
@export var stamping_sound: AudioStream
@export var stamping_player_jumping_min: float = 400
@export var stamping_player_jumping_max: float = 650
@export_group("Killing","killing_")
@export var killing_enabled: bool = true
@export var killing_immmuine:Dictionary = PROJECTILE_IMMUINE
@export var killing_creation: Node2DCreation
@export var killing_scores: int
@export var killing_sound_succeeded: AudioStream
@export var killing_sound_failed: AudioStream
@export_group("Extra")
@export var custom_script: Script

var stamping_delayed: bool

@onready var extra_script: Script = ByNodeScript.activate_script(custom_script,self)
@onready var area:Area2D = get_parent()
@onready var center: Node2D = get_node_or_null(center_node)
@onready var sound: AudioStreamPlayer2D = get_node_or_null(sound_player)

signal stamped
signal stamped_succeeded
signal stamped_failed
signal killed
signal killed_succeeded
signal killed_failed


func got_stamped(by: Node2D, offset: Vector2 = Vector2.ZERO) -> Dictionary:
	var result: Dictionary
	
	if !center:
		push_error("[No Center Node Error] No center node set. Please check if you have set the center node of EnemyAttacked. At" + str(get_path()))
		return result
	
	var dot:float = by.global_position.direction_to(
		center.global_transform.translated(stamping_offset + offset).get_origin()
	).dot(stamping_standard)
	
	if stamping_delayed: return result
	
	stamped.emit()
	
	if dot > 0:
		stamped_succeeded.emit()
		stamping_delayed = true
		
		var delayer: SceneTreeTimer = get_tree().create_timer(get_physics_process_delta_time() * 5)
		delayer.timeout.connect(
			func() -> void:
				stamping_delayed = false
		)
		
		_creation(stamping_creation)
		result = {result = true, jumping_min = stamping_player_jumping_min, jumping_max = stamping_player_jumping_max}
	else:
		stamped_failed.emit()
		result = {result = false}
	
	return result


func _sound(stream:AudioStream) -> void:
	if !sound || !center: return
	
	var snd: AudioStreamPlayer2D = sound.duplicate()
	
	snd.stream = stream
	snd.autoplay = true
	snd.finished.connect(snd.queue_free)
	
	center.add_sibling(sound)
	
	snd.position = center.position


func _creation(creation: Node2DCreation) -> void:
	if !creation: return
	
	creation.prepare(center)
	
	if creation.creation_physics:
		creation.call_physics().apply_velocity_local().override_gravity().unbind()
	
	creation.create()
