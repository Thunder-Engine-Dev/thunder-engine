extends Node

var current_skin: String = "Luigi"

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"

var _custom_textures_raw: Dictionary
var custom_textures: Dictionary
var custom_sprite_frames: Dictionary

@onready var base_sprite_frames: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_super.tres")
@onready var animation_list: PackedStringArray = base_sprite_frames.get_animation_names()

func _init() -> void:
	var tex: Dictionary = load_external_textures()
	print(tex)
	if tex.is_empty(): return
	#_custom_textures_raw = tex[0]
	custom_textures = tex


func _ready() -> void:
	print(animation_list)


func load_external_textures() -> Dictionary:
	print(base_dir)
	if !DirAccess.dir_exists_absolute(base_dir):
		print("Skipped loading custom textures")
		return {}
	
	var loaded: Dictionary = {}
	var dir_access = DirAccess.open(base_dir)
	if !dir_access:
		return {}
	
	var directories: PackedStringArray = DirAccess.get_directories_at(base_dir)
	#print(directories)
	for i in directories:
		dir_access.change_dir(base_dir + "/" + i)
		var _anims: PackedStringArray = DirAccess.get_directories_at(base_dir + "/" + i)
		loaded[i] = {}
		print(_anims)
		for j in _anims:
			var file_path: String = base_dir + "/" + i + "/" + j
			dir_access.change_dir(file_path)
			dir_access.list_dir_begin()
			var file_name: String = dir_access.get_next()
			#print(file_name)
			loaded[i][j] = {}
			while file_name != "":
				var file_ext: String = file_name.get_extension().to_lower()
				if !dir_access.current_is_dir() && file_ext == "png":
					var texture_name: String = file_name.trim_suffix("." + file_ext)
					
					var file: Image = Image.load_from_file(file_path + "/" + file_name)
					var file_texture: ImageTexture = ImageTexture.create_from_image(file)
					loaded[i][j][texture_name] = file_texture
				
				file_name = dir_access.get_next()
	return loaded


func get_custom_sprite_frames(old_sprites: SpriteFrames, skin_name: String, power: String) -> SpriteFrames:
	var custom_tex
	
	if custom_sprite_frames.has(skin_name):
		return custom_sprite_frames[skin_name]

	custom_tex = custom_textures[skin_name][power]
	var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex)
	custom_sprite_frames[skin_name] = new_sprites
	return new_sprites


func new_custom_sprite_frames(old_sprites: SpriteFrames, textures: Dictionary) -> SpriteFrames:
	if !old_sprites: return null
	if textures.is_empty(): return old_sprites

	var new_sprites := SpriteFrames.new()
	for anim in old_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		new_sprites.set_animation_speed(anim, old_sprites.get_animation_speed(anim))
		new_sprites.set_animation_loop(anim, old_sprites.get_animation_loop(anim))
		for frame in old_sprites.get_frame_count(anim):
			var tex = old_sprites.get_frame_texture(anim, frame)
			var new_tex := AtlasTexture.new()
			if anim in textures:
				if tex is AtlasTexture:
					new_tex.atlas = textures[anim] # ImageTexture
					new_tex.margin = tex.margin
					new_tex.region = tex.region
				else:
					new_tex.atlas = new_tex
			else:
				new_tex = tex
			new_sprites.add_frame(anim, new_tex)
	return new_sprites
