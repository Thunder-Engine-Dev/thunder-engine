extends Node

var current_skin: String = ""

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"

var custom_textures: Dictionary
var custom_sprite_frames: Dictionary
var skins: Dictionary
var misc_textures: Dictionary
var misc_sounds: Dictionary
var custom_nicknames: Dictionary
var custom_story_text: Dictionary
var custom_settings: Dictionary

@onready var base_sprite_frames: SpriteFrames = preload("res://engine/objects/players/prefabs/animations/mario/animation_mario_super.tres")
@onready var animation_list: PackedStringArray = base_sprite_frames.get_animation_names()

func _init() -> void:
	var _tex: String = load_external_textures()
	print_rich(_tex)


func _ready() -> void:
	current_skin = SettingsManager.settings.skin
	SettingsManager.settings_updated.connect(_update_current_skin_from_settings)
#	print(animation_list)
	
	# Saving animation sprite frames
	#var err = ResourceSaver.save(base_sprite_frames, base_dir + "/animation.tres", ResourceSaver.FLAG_RELATIVE_PATHS)
	#print(err)


func _update_current_skin_from_settings() -> void:
	current_skin = SettingsManager.settings.skin


func apply_player_skin(_suit) -> SpriteFrames:
	if SkinsManager.custom_sprite_frames.has(SkinsManager.current_skin):
		return SkinsManager.get_custom_sprite_frames(_suit.animation_sprites, SkinsManager.current_skin, _suit.name)
	return _suit.animation_sprites


func load_external_textures() -> String:
	print(base_dir)
	
	# Skip if there are no skins
	if !DirAccess.dir_exists_absolute(base_dir):
		return "Skipped loading custom textures"
	
	var dir_access = DirAccess.open(base_dir)
	if !dir_access:
		return ""
	
	# Debug print
	var out: PackedStringArray = []
	
	# Removing everything from memory on initialization
	custom_textures = {}
	custom_sprite_frames = {}
	skins = {}
	misc_textures = {}
	misc_sounds = {}
	custom_nicknames = {}
	custom_story_text = {}
	custom_settings = {}
	
	var directories: PackedStringArray = DirAccess.get_directories_at(base_dir)
	for i in directories:
		dir_access.change_dir(base_dir + "/" + i)
		
		# Initiating a skin in dictionaries
		misc_textures[i] = {}
		misc_sounds[i] = {}
		custom_nicknames[i] = i.left(15)
		custom_story_text[i] = CharacterManager.DEFAULT_STORY_TEXT.duplicate()
		custom_settings[i] = {}
		# Loading miscellaneous textures, voice lines, and sound effects
		_load_misc_files(dir_access, i)
		
		# Initiating animations
		var _anims: PackedStringArray = DirAccess.get_directories_at(base_dir + "/" + i)
		custom_sprite_frames[i] = {}
		skins[i] = {}
		out.append("[color=yellow]" + str(i) + "[/color] Anims: [color=cyan]" + "[/color], [color=cyan]".join(_anims) + "[/color].")
		# Loading textures and setting up sprite frames
		custom_textures[i] = _load_animations(dir_access, i, _anims)
		
		# Printing errors
		var comp_1 := PackedStringArray(skins[i].keys())
		comp_1.sort()
		var comp_2 := _anims
		comp_2.sort()
		if comp_1 != comp_2:
			out.append("[Skins Manager] [color=red]ALERT![/color] For [color=yellow]" + str(i) + """[/color], Some animations have not been loaded properly!
	[color=red]Found[/color]: [color=cyan]""" + "[/color], [color=cyan]".join(comp_2) + """[/color].
	[color=red]Loaded without errors[/color]: [color=cyan]""" + "[/color], [color=cyan]".join(comp_1) + "[/color].")
	
	# Final step
	dir_access.list_dir_end()
	out.append("Skins loaded!")
	return "
".join(out)


func _load_misc_files(dir_access: DirAccess, i: String):
	# "i" here means the skin name
	var _misc_files: PackedStringArray = dir_access.get_files()
	for j in _misc_files:
		# "j" here means the name of current file
		var file_path: String = base_dir + "/" + i + "/" + j
		# Accepting syntax "blahblah_#", where # is a number from 0 to 9
		var is_array: bool = j.get_basename().left(-1).ends_with("_") && j.get_basename().right(1).is_valid_int()
		var file_ext: String = j.get_extension().to_lower()
		# Ignoring everything that's not png, ogg or txt
		if !file_ext in ["png", "ogg", "txt"]:
			continue
		
		var arrayed_filename: String = j.get_basename().left(-2)
		# If it's PNG, then load to memory under "misc_textures" variable
		# Can load as a texture object, or as an array
		if file_ext == "png":
			if is_array && !arrayed_filename in misc_textures[i]:
				misc_textures[i][arrayed_filename] = []
			var img: Image = Image.load_from_file(file_path)
			var file := ImageTexture.create_from_image(img)
			if is_array:
				misc_textures[i][arrayed_filename].append(file)
			else:
				misc_textures[i][j.get_basename()] = file
		
		# If it's OGG, then load to memory under "misc_sounds" variable
		# Only loads as an array
		elif file_ext == "ogg":
			if !is_array:
				arrayed_filename = j.get_basename()
			if !arrayed_filename in misc_sounds[i]:
				misc_sounds[i][arrayed_filename] = []
			var file = AudioStreamOggVorbis.load_from_file(file_path)
			misc_sounds[i][arrayed_filename].append(file)
		
		# If it's TXT, then check what name it has, and load only valid files to memory
		elif file_ext == "txt":
			# Name for HUD, variable "custom_nicknames"
			if j.get_basename().to_lower() == "name":
				var file = FileAccess.open(file_path, FileAccess.READ)
				custom_nicknames[i] = file.get_line().left(15)
				print(i, " Custom nick: ", custom_nicknames[i])
				file.close()
			# For story text, includes pronouns and basic description about the player skin
			# Variable "custom_story_text"
			elif j.get_basename().to_lower() == "story":
				var file = FileAccess.open(file_path, FileAccess.READ)
				var _line = file.get_line().left(15)
				if _line:
					custom_story_text[i][0] = _line
				var index: int = 0
				while !file.eof_reached():
					index += 1
					if len(custom_story_text[i]) < index + 1:
						custom_story_text[i].resize(index + 1)
					custom_story_text[i][index] = file.get_line().left(50)
				print(i, " Custom story text: ", custom_story_text[i])
				file.close()
				


func _load_animations(dir_access: DirAccess, i: String, _anims: PackedStringArray):
	var loaded: Dictionary = {}
	loaded = {}
	for j in _anims:
		var file_path: String = base_dir + "/" + i + "/" + j
		dir_access.change_dir(file_path)
		dir_access.list_dir_begin()
		if !dir_access.file_exists(file_path + "/skin_settings.tres"):
			print("No skin settings found at " + file_path + ". Skipping")
			continue
		var file_name: String = dir_access.get_next()
		loaded[j] = {}
		#custom_sprite_frames[i][j] = null
		while file_name != "":
			var file_ext: String = file_name.get_extension().to_lower()
			# Loading external skin textures to cache
			if !dir_access.current_is_dir() && file_ext == "png":
				var texture_name: String = file_name.trim_suffix("." + file_ext)
				
				var file: Image = Image.load_from_file(file_path + "/" + file_name)
				var file_texture: ImageTexture = ImageTexture.create_from_image(file)
				#print(i + "/" + j + "/" + file_name)
				loaded[j][texture_name] = file_texture
			# Loading skin settings (regions, loops etc.) to cache
			elif !dir_access.current_is_dir() && file_name == "skin_settings.tres":
				var _skin = ResourceLoader.load(file_path + "/skin_settings.tres", "Resource", ResourceLoader.CACHE_MODE_REPLACE)
				if (
					!_skin || !"animation_regions" in _skin ||
					!"animation_loops" in _skin ||
					!"animation_speeds" in _skin ||
					!"name" in _skin
				):
					OS.alert(file_path + "/skin_settings.tres is invalid.", "Player Skin Load Error")
					file_name = dir_access.get_next()
					continue
				
				skins[i][_skin.name] = _skin
			
			file_name = dir_access.get_next()
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
	if !current_skin in skins || !power in skins[current_skin]: return old_sprites
	
	var new_sprites := SpriteFrames.new()
	var _regions: Dictionary = skins[current_skin][power].animation_regions
	for anim in old_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		new_sprites.set_animation_speed(anim, skins[current_skin][power].animation_speeds[anim])
		new_sprites.set_animation_loop(anim, skins[current_skin][power].animation_loops[anim])
		var frame_count = old_sprites.get_frame_count(anim)
		if len(_regions[anim]) > 0:
			frame_count = len(_regions[anim])
		
		for frame in frame_count:
			var tex = old_sprites.get_frame_texture(anim, frame)
			var new_tex := AtlasTexture.new()
			if anim in textures:
				new_tex.atlas = textures[anim] # ImageTexture
				var _region: Rect2 = tex.region if tex else Rect2()
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
