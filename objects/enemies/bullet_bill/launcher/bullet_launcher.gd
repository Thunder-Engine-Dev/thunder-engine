extends Control

@export_category("BulletBillLauncher")
@export_group("Bullet")
@export var bullet_bill:InstanceNode2D
@export_group("Delay")
@export var first_shooting: float
@export var shooting_delay_min: float
@export var shooting_delay_max: float

@onready var obstacle: StaticBody2D = $Obstacle
@onready var collision_shape: CollisionShape2D = $Obstacle/CollisionShape2D
@onready var launcher: Sprite2D = $Launcher


func _ready() -> void:
	obstacle.position.y = get_rect().size.y / 2
	collision_shape.shape.size.y = get_rect().size.y
