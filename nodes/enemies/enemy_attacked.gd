# Node should be placed as a child of Area2D
extends Node

const PROJECTILE_IMMUNE_TO: Dictionary = {
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
@export_group("Stomping","stomping_")
@export var stomping_enabled: bool = true
@export var stomping_available: bool = true
@export var stomping_hurtable: bool = true
@export var stomping_standard: Vector2 = Vector2.DOWN
@export var stomping_offset: Vector2
@export var stomping_creation: Node2DCreation
@export var stomping_scores: int
@export var stomping_sound: AudioStream
@export var stomping_player_jumping_min: float = 400
@export var stomping_player_jumping_max: float = 650
@export_group("Killing","killing_")
@export var killing_enabled: bool = true
@export var killing_immune: Dictionary = PROJECTILE_IMMUNE_TO
@export var killing_creation: Node2DCreation
@export var killing_scores: int
@export var killing_sound_succeeded: AudioStream
@export var killing_sound_failed: AudioStream
@export_group("Extra")
@export var custom_script: Script

var stomping_delayer: SceneTreeTimer

@onready var extra_script: Script = ByNodeScript.activate_script(custom_script, self)
@onready var area: Area2D = get_parent()
@onready var center: Node2D = get_node_or_null(center_node)
@onready var sound: AudioStreamPlayer2D = get_node_or_null(sound_player)

signal stomped
signal stomped_succeeded
signal stomped_failed
signal killed
signal killed_succeeded
signal killed_failed


func got_stomped(by: Node2D, offset: Vector2 = Vector2.ZERO) -> Dictionary:
	var result: Dictionary
	
	if !center:
		push_error("[No Center Node Error] No center node set. Please check if you have set the center node of EnemyAttacked. At " + str(get_path()))
		return result
	
	var dot: float = by.global_position.direction_to(
		center.global_transform.translated(stomping_offset + offset).get_origin()
	).dot(stomping_standard)
	
	if stomping_delayer: return result
	
	stomped.emit()
	
	if dot > 0:
		stomped_succeeded.emit()
		
		stomping_delayer = get_tree().create_timer(get_physics_process_delta_time() * 5)
		stomping_delayer.timeout.connect(
			func() -> void:
				stomping_delayer = null
		)
		
		_creation(stomping_creation)
		result = {result = true, jumping_min = stomping_player_jumping_min, jumping_max = stomping_player_jumping_max}
	else:
		stomped_failed.emit()
		result = {result = false}
	
	return result


func _sound(stream: AudioStream) -> void:
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
