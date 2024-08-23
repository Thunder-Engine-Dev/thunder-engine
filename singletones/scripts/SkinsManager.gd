extends Node

var current_skin: String = ""

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"

var custom_textures: Dictionary
var custom_sprite_frames: Dictionary
var skins: Array[PlayerSkin] = []

@onready var base_sprite_frames: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_super.tres")
@onready var animation_list: PackedStringArray = base_sprite_frames.get_animation_names()

func _init() -> void:
	var tex: Dictionary = load_external_textures()
	#print(tex)
	if tex.is_empty(): return
	custom_textures = tex


#func _ready() -> void:
#	print(animation_list)
	
	# Saving animation sprite frames
	#var err = ResourceSaver.save(base_sprite_frames, base_dir + "/animation.tres", ResourceSaver.FLAG_RELATIVE_PATHS)
	#print(err)


func load_external_textures() -> Dictionary:
	print(base_dir)
	if !DirAccess.dir_exists_absolute(base_dir):
		print("Skipped loading custom textures")
		return {}
	
	var loaded: Dictionary = {}
	var dir_access = DirAccess.open(base_dir)
	if !dir_access:
		return {}
	
	custom_sprite_frames = {}
	skins = []
	var directories: PackedStringArray = DirAccess.get_directories_at(base_dir)
	#print(directories)
	for i in directories:
		dir_access.change_dir(base_dir + "/" + i)
		var _anims: PackedStringArray = DirAccess.get_directories_at(base_dir + "/" + i)
		loaded[i] = {}
		custom_sprite_frames[i] = {}
		print(_anims)
		for j in _anims:
			var file_path: String = base_dir + "/" + i + "/" + j
			dir_access.change_dir(file_path)
			dir_access.list_dir_begin()
			if !dir_access.file_exists(file_path + "/skin_settings.tres"):
				continue
			var file_name: String = dir_access.get_next()
			#print(file_name)
			loaded[i][j] = {}
			#custom_sprite_frames[i][j] = null
			while file_name != "":
				var file_ext: String = file_name.get_extension().to_lower()
				# Loading external skin textures to cache
				if !dir_access.current_is_dir() && file_ext == "png":
					var texture_name: String = file_name.trim_suffix("." + file_ext)
					
					var file: Image = Image.load_from_file(file_path + "/" + file_name)
					var file_texture: ImageTexture = ImageTexture.create_from_image(file)
					print(file_path + "/" + file_name)
					loaded[i][j][texture_name] = file_texture
				# Loading skin settings (regions, loops etc.) to cache
				elif !dir_access.current_is_dir() && file_name == "skin_settings.tres":
					var _skin = ResourceLoader.load(file_path + "/skin_settings.tres", "Resource", ResourceLoader.CACHE_MODE_REPLACE)
					skins.append(_skin)
				
				file_name = dir_access.get_next()
	dir_access.list_dir_end()
	return loaded


func get_custom_sprite_frames(old_sprites: SpriteFrames, skin_name: String, power: String) -> SpriteFrames:
	var custom_tex: Dictionary = {}
	
	# Loading cached sprite frames, if exist
	if custom_sprite_frames.has(skin_name) && custom_sprite_frames[skin_name].has(power):
		return custom_sprite_frames[skin_name][power]

	# Loading custom power textures
	if custom_textures[skin_name].has(power):
		custom_tex = custom_textures[skin_name][power]
	
	# Loading external sprite frames to cache
	var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex, power) #load_sprite_frames(skin_name, power)
	if !skin_name in custom_sprite_frames:
		custom_sprite_frames[skin_name] = {}
	custom_sprite_frames[skin_name][power] = new_sprites
	if new_sprites:
		return new_sprites
	
	# Fallback
	push_warning('[Skins Manager] Textures for power "%s" do not exist.' % power)
	return old_sprites


#func load_sprite_frames(skin_name: String, power: String) -> SpriteFrames:
	#var frames = ResourceLoader.load(base_dir + "/animation_mario_%s.tres" % power, "SpriteFrames")
	#return frames


func new_custom_sprite_frames(old_sprites: SpriteFrames, textures: Dictionary, power: String) -> SpriteFrames:
	if !old_sprites: return null
	if textures.is_empty(): return old_sprites

	var new_sprites := SpriteFrames.new()
	var _regions: Dictionary = skins[0].animation_regions
	for anim in old_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		new_sprites.set_animation_speed(anim, skins[0].animation_speeds[anim])
		new_sprites.set_animation_loop(anim, skins[0].animation_loops[anim])
		var frame_count = old_sprites.get_frame_count(anim)
		if len(_regions[anim]) > 0:
			frame_count = len(_regions[anim])
		
		for frame in frame_count:
			var tex = old_sprites.get_frame_texture(anim, frame)
			var new_tex := AtlasTexture.new()
			if anim in textures:
				new_tex.atlas = textures[anim] # ImageTexture
				var _region = tex.region
				if len(_regions[anim]) > 0:
					_region = _regions[anim][frame]
				#new_tex.margin = tex.margin
				new_tex.region = _region
			else:
				new_tex = tex
			new_sprites.add_frame(anim, new_tex)
	#var err = ResourceSaver.save(skins[0], base_dir + "/luigi/%s/skin_settings.tres" % power)
	#print(err)
	return new_sprites
