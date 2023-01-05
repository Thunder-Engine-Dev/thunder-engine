# Node should be placed as a child of Area2D
extends Node

@export_category("EnemyAttacked")
@export_group("Stamping","stamping_")
@export var stamping_enabled: bool = true
@export var stamping_hurtable: bool = true
@export var stamping_offset: Vector2
@export var stamping_creation: Node2DCreation

