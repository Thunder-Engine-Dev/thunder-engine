extends Powerup

const JUMP_SOUND = preload("res://engine/objects/players/prefabs/sounds/kick.wav")
@export var luigi_spriteframes: SpriteFrames
@onready var sprite: AnimatedSprite2D = $Sprite

var has_velset: bool
var has_jumped: bool

func _ready() -> void:
	if CharacterManager.get_character_name() == "Luigi":
		sprite.sprite_frames = luigi_spriteframes
		sprite.play()
		gravity_scale = 0.5
		collided_wall.connect(turn_x)
	super()

func _physics_process(delta: float) -> void:
	super(delta)
	if appear_distance: return
	
	if CharacterManager.get_character_name() == "Luigi":
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
