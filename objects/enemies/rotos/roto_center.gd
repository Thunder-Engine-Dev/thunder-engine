@tool
extends Node2D

@export_category("Roto-Disks")
@export_group("Preview")
@export var preview: bool:
	set(to):
		preview = to
		switch_preview(preview)

enum ARRANGE_AS {
	SELECT_ACTION,
	BAR,
	LINE_BAR,
	CIRCLE
}

@export var arrange_as: ARRANGE_AS = ARRANGE_AS.SELECT_ACTION:
	set(to):
		match to:
			ARRANGE_AS.BAR: bar_like(false)
			ARRANGE_AS.LINE_BAR: bar_like(true)
			ARRANGE_AS.CIRCLE: circle_like()

func switch_preview(on: bool) -> void:
	for i in get_children():
		if !i.is_in_group(&"#roto"):
			continue
		i.preview = on


func bar_like(force_phase: bool) -> void:
	var rotos: PackedVector2Array = []
	for i in get_children():
		if !i.is_in_group(&"#roto"):
			continue
		rotos.append(i.amplitude)
	rotos.sort()
	rotos.reverse()
	
	for j in get_child_count():
		var roto: Node2D = get_child(j)
		if !roto.is_in_group(&"#roto"):
			continue
		roto.amplitude = (rotos[0] / float(rotos.size())) * (j + 1)
		if force_phase:
			roto.phase = 0


func circle_like() -> void:
	var rotos: PackedVector2Array = []
	for i in get_children():
		if !i.is_in_group(&"#roto"):
			continue
		rotos.append(i.amplitude)
	rotos.sort()
	rotos.reverse()
	
	for j in get_child_count():
		var roto: Node2D = get_child(j)
		if !roto.is_in_group(&"#roto"):
			continue
		roto.amplitude = rotos[0]
		roto.phase = (360.0 / float(rotos.size())) * j
