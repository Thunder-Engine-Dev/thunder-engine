extends Node2D

@export_category("Centipede Pathpoints")
@export var path_color: Color = Color.RED
@export_range(0, 32, 0.01, "or_greater", "suffix:px") var path_width: float = 4
