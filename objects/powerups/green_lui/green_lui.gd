extends Powerup

const JUMP_SOUND = preload("res://engine/objects/players/prefabs/sounds/kick.wav")
@export var luigi_spriteframes: SpriteFrames

@onready var sprite: AnimatedSprite2D = $Sprite

var _init_spriteframes: SpriteFrames
@onready var _init_gravityscale: float = gravity_scale
var has_velset: bool
var has_jumped: bool
var is_red_mar: bool

func _ready() -> void:
	_init_spriteframes = sprite.sprite_frames
	Thunder._connect(CharacterManager.character_updated, update_look)
	Thunder._connect(SettingsManager.settings_updated, update_look)
	update_look(true)
	
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if appear_distance: return
	
	if is_red_mar:
		if !has_velset:
			has_velset = true
			vel_set_x(150)
		sprite.rotation_degrees += 14 * 50 * delta * signf(speed.x)
		return
	if is_on_floor():
		jump(350)
		if has_jumped:
			Audio.play_sound(JUMP_SOUND, self, false)
		has_jumped = true


func update_look(forced: bool = false) -> void:
	var is_currently_luigi: bool = CharacterManager.get_character_name() == "Luigi"
	if !forced && is_red_mar == is_currently_luigi:
		return
	is_red_mar = is_currently_luigi
	if is_red_mar:
		sprite.sprite_frames = luigi_spriteframes
		sprite.play()
		gravity_scale = 0.5
		Thunder._connect(collided_wall, turn_x)
		if appear_distance && !supply_behavior:
			if !has_velset:
				has_velset = true
				vel_set_x(150)
			has_jumped = true
	else:
		sprite.sprite_frames = _init_spriteframes
		sprite.play()
		gravity_scale = _init_gravityscale
		Thunder._disconnect(collided_wall, turn_x)
		if has_velset:
			has_velset = false
			vel_set_x(0)
		sprite.rotation_degrees = 0
