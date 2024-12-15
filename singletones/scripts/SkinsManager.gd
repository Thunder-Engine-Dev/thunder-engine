extends Node

const CONFIG_SKIN_SETTINGS = "skin_settings.tres"
const CONFIG_SUIT_TWEAKS = "suit_tweaks.json"
const FOLDER_SUIT_IMAGES = "textures"
const FOLDER_SUIT_SOUNDS = "sounds"
const FOLDER_GLOBAL_SOUNDS = "_global_sounds"
const CONFIG_GLOBAL_SKIN_TWEAKS = "global_skin_tweaks"

signal skins_loaded
signal skins_load_failed

var current_skin: String = ""

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"

var custom_textures: Dictionary
var custom_sprite_frames: Dictionary
var skins: Dictionary
var misc_textures: Dictionary
var misc_sounds: Dictionary
var custom_nicknames: Dictionary
var custom_story_text: Dictionary
var suit_tweaks: Dictionary
var suit_sounds: Dictionary


func _init() -> void:
	var _tex: String = load_external_textures()
	print_rich(_tex)


func _ready() -> void:
	current_skin = SettingsManager.settings.skin
	SettingsManager.settings_updated.connect(_update_current_skin_from_settings)
	
	# Saving animation sprite frames
	#var err = ResourceSaver.save(base_sprite_frames, base_dir + "/animation.tres", ResourceSaver.FLAG_RELATIVE_PATHS)
	#print(err)


func _update_current_skin_from_settings() -> void:
	current_skin = SettingsManager.settings.skin


## Returns SpriteFrames of a player suit with skin (if available)
func apply_player_skin(_suit) -> SpriteFrames:
	if SkinsManager.custom_sprite_frames.has(SkinsManager.current_skin):
		return SkinsManager.get_custom_sprite_frames(_suit.animation_sprites, SkinsManager.current_skin, _suit.name)
	return _suit.animation_sprites


## Main method to load all skins
func load_external_textures() -> String:
	print(base_dir)
	
	# Skip if there are no skins
	if !DirAccess.dir_exists_absolute(base_dir):
		skins_load_failed.emit()
		return "Skipped loading custom textures"
	
	var dir_access = DirAccess.open(base_dir)
	if !dir_access:
		skins_load_failed.emit()
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
	suit_tweaks = {}
	suit_sounds = {}
	
	var directories: PackedStringArray = DirAccess.get_directories_at(base_dir)
	for i in directories:
		dir_access.change_dir(base_dir + "/" + i)
		
		# Initiating a skin in dictionaries
		misc_textures[i] = {}
		misc_sounds[i] = {}
		custom_nicknames[i] = i.left(15)
		custom_story_text[i] = CharacterManager.DEFAULT_STORY_TEXT.duplicate()
		suit_tweaks[i] = {}
		suit_sounds[i] = {}
		
		# Loading miscellaneous textures and configs
		_load_misc_files(dir_access, i)
		
		# Initiating animations
		var _anims: PackedStringArray = DirAccess.get_directories_at(base_dir + "/" + i)
		var _sounds_index: int = _anims.find(FOLDER_GLOBAL_SOUNDS)
		if _sounds_index != -1:
			_anims.remove_at(_sounds_index)
		custom_sprite_frames[i] = {}
		skins[i] = {}
		out.append("[color=yellow]" + str(i) + "[/color] Anims: [color=cyan]" + "[/color], [color=cyan]".join(_anims) + "[/color].")
		
		# Loading textures and setting up sprite frames
		custom_textures[i] = _load_animations(dir_access, i, _anims)
		# Loading global sounds
		misc_sounds[i] = _load_sounds(dir_access, "%s/%s/%s" % [base_dir, i, FOLDER_GLOBAL_SOUNDS])
		
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
	skins_loaded.emit()
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
		# Ignoring everything that's not png, txt or json
		if !file_ext in ["png", "txt", "json"]:
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
				
		# If it's JSON, then check what name it has, and load only valid files to memory
		elif file_ext == "json":
			
			if j.get_basename().to_lower() == CONFIG_GLOBAL_SKIN_TWEAKS:
				var _out: String = _open_file_as_json(file_path)
				if !_out: continue
				var _json: Variant = JSON.parse_string(_out)
				if !_json || !_json is Dictionary:
					print(file_path + ": Not a valid JSON.")
					continue
				print(i, " Global skin tweaks loaded")
				misc_textures[i][CONFIG_GLOBAL_SKIN_TWEAKS] = _load_json(_json, CharacterManager.DEFAULT_GLOBAL_SKIN_TWEAKS)


func _load_sounds(dir_access: DirAccess, dir_path: String) -> Dictionary:
	var loaded: Dictionary = {}
	if !DirAccess.dir_exists_absolute(dir_path):
		print("Global sounds skipped: " + dir_path)
		return loaded
	dir_access.change_dir(dir_path)
	var _misc_files: PackedStringArray = dir_access.get_files()
	for j in _misc_files:
		if j.get_extension().to_lower() != "ogg":
			continue
		var file_path: String = dir_access.get_current_dir() + "/" + j
		# Accepting syntax "blahblah_#", where # is a number from 0 to 9
		var is_array: bool = j.get_basename().left(-1).ends_with("_") && j.get_basename().right(1).is_valid_int()
		
		var arrayed_filename: String = j.get_basename().left(-2)
		# If it's OGG, then load to memory under "misc_sounds" variable
		# Only loads as an array
		if !is_array:
			arrayed_filename = j.get_basename()
		if !arrayed_filename in loaded:
			loaded[arrayed_filename] = []
		var file = AudioStreamOggVorbis.load_from_file(file_path)
		loaded[arrayed_filename].append(file)
	return loaded


func _load_animations(dir_access: DirAccess, i: String, _anims: PackedStringArray) -> Dictionary:
	var loaded: Dictionary = {}
	loaded = {}
	var errored: PackedStringArray = []
	for j in _anims:
		var file_path: String = base_dir + "/" + i + "/" + j
		if !FileAccess.file_exists(file_path + "/" + CONFIG_SKIN_SETTINGS):
			print("No %s found at %s. Skipping" % [CONFIG_SKIN_SETTINGS, file_path])
			continue
		if !DirAccess.dir_exists_absolute(file_path + "/" + FOLDER_SUIT_IMAGES):
			errored.append("No %s folder found at %s." % [FOLDER_SUIT_IMAGES, file_path])
			continue
		
		dir_access.change_dir(file_path + "/" + FOLDER_SUIT_IMAGES)
		dir_access.list_dir_begin()
		
		var file_name: String = dir_access.get_next()
		loaded[j] = {}
		
		while file_name != "":
			var file_ext: String = file_name.get_extension().to_lower()
			# Loading external skin textures to cache
			if !dir_access.current_is_dir() && file_ext == "png":
				var texture_name: String = file_name.trim_suffix("." + file_ext)
				
				var file: Image = Image.load_from_file(file_path + "/" + FOLDER_SUIT_IMAGES + "/" + file_name)
				var file_texture: ImageTexture = ImageTexture.create_from_image(file)
				#print(i + "/" + j + "/" + file_name)
				loaded[j][texture_name] = file_texture
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
		
		dir_access.change_dir(file_path)
		dir_access.list_dir_begin()
		file_name = dir_access.get_next()
		while file_name != "":
			# Loading skin settings (regions, loops etc.) to cache
			if !dir_access.current_is_dir() && file_name == CONFIG_SKIN_SETTINGS:
				var _skin = ResourceLoader.load(file_path + "/" + CONFIG_SKIN_SETTINGS, "Resource", ResourceLoader.CACHE_MODE_REPLACE)
				if (
					!_skin || !"animation_regions" in _skin ||
					!"animation_loops" in _skin ||
					!"animation_speeds" in _skin ||
					!"name" in _skin
				):
					errored.append(file_path + "/" + CONFIG_SKIN_SETTINGS + " is invalid.")
					file_name = dir_access.get_next()
					continue
				
				skins[i][_skin.name] = _skin
			# Loading Suit Tweaks to "suit_tweaks" variable
			elif !dir_access.current_is_dir() && file_name == CONFIG_SUIT_TWEAKS:
				var _out: String = _open_file_as_json(file_path + "/" + CONFIG_SUIT_TWEAKS)
				if !_out: continue
				var _json = JSON.parse_string(_out)
				if !_json || !_json is Dictionary:
					errored.append(file_path + "/" + CONFIG_SUIT_TWEAKS + " is invalid.")
					file_name = dir_access.get_next()
					continue
				
				suit_tweaks[i][j] = _load_json(_json, CharacterManager.DEFAULT_SUIT_TWEAKS)
			file_name = dir_access.get_next()
		
		dir_access.list_dir_end()
		
		var suit_sounds_path: String = file_path + "/" + FOLDER_SUIT_SOUNDS
		if DirAccess.dir_exists_absolute(suit_sounds_path):
			suit_sounds[i][j] = _load_sounds(dir_access, suit_sounds_path)
			if suit_sounds[i][j]:
				print("Suit %s: %s loaded." % [j, FOLDER_SUIT_SOUNDS])
	
	if !errored.is_empty():
		OS.alert("
".join(errored), "Player Skin Load Error")
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
	var _temp_sprites = old_sprites.duplicate()
	if CharacterManager.get_suit_tweak("look_up_animation", "", power):
		_temp_sprites.add_animation("look_up")
	if CharacterManager.get_suit_tweak("stomp_animation", "", power):
		_temp_sprites.add_animation("stomp")
	if CharacterManager.get_suit_tweak("separate_run_animation", "", power):
		_temp_sprites.add_animation("p_run")
		_temp_sprites.add_animation("p_jump")
		_temp_sprites.add_animation("p_fall")
	if CharacterManager.get_suit_tweak("idle_animation", "", power):
		_temp_sprites.add_animation("idle")
	
	for anim in _temp_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		var errored: PackedStringArray = []
		for dict_check in ["animation_regions", "animation_speeds", "animation_loops"]:
			if !anim in skins[current_skin][power][dict_check]:
				errored.append(
					str(current_skin) + ": Animation '" + anim + "' is not present in " + dict_check
				)
				continue
		if !errored.is_empty():
			OS.alert("
".join(errored), "Player Skin Load Error")
			return old_sprites
		new_sprites.set_animation_speed(anim, skins[current_skin][power].animation_speeds[anim])
		new_sprites.set_animation_loop(anim, skins[current_skin][power].animation_loops[anim])
		var frame_count = _temp_sprites.get_frame_count(anim)
		if len(_regions[anim]) > 0:
			frame_count = len(_regions[anim])
		
		for frame in frame_count:
			var tex = _temp_sprites.get_frame_texture(anim, frame)
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

# To allow comments in JSON, using //
func _open_file_as_json(file_path: String) -> String:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var out_string: String = ""
	if !file:
		print("Error upon opening skin JSON file")
		return out_string
	while !file.eof_reached():
		var _line: String = file.get_line()
		if _line.find("//"):
			out_string += _line.get_slice("//", 0) + "
"
	return out_string

# For nested objects in JSON
func _load_json(_json, _default) -> Dictionary:
	var _loaded = _default.duplicate(true)
	for key in _json.keys():
		if key in _loaded:
			var value = _json[key]
			if value is Dictionary:
				#load_to[key] = {}
				for dict_key in value.keys():
					if dict_key in value:
						_loaded[key][dict_key] = value[dict_key]
			else:
				_loaded[key] = value
	return _loaded
