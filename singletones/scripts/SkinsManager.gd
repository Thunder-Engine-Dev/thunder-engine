extends Node

const CONFIG_SKIN_SETTINGS = "skin_settings.tres"
const CONFIG_SUIT_TWEAKS = "suit_tweaks.json"
#const FOLDER_SUIT_IMAGES = "textures"
const FOLDER_SUIT_SOUNDS = "sounds"
const FOLDER_GLOBAL_SOUNDS = "_global_sounds"
const CONFIG_GLOBAL_SKIN_TWEAKS = "global_skin_tweaks"
const BAD_NAMES = [
	"object", "script", "_init", "_enter_tree", "_exit_tree", "_ready",
	"_process", "extends", "refcounted", "func ", "func()",
]
const SETTINGS_DICT_NAMES = [
	"animation_speeds", "animation_regions", "animation_loops", "animation_durations",
]

signal skins_loaded
signal skins_load_failed

var current_skin: String = ""

var base_dir: String = OS.get_executable_path().get_base_dir() + "/skins"
var _is_default_skin: bool = false
var _error_buffer: PackedStringArray = []

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
func apply_player_skin(_suit, force_errors: bool = false) -> SpriteFrames:
	if custom_sprite_frames.has(current_skin):
		return get_custom_sprite_frames(_suit.animation_sprites, current_skin, _suit.name, force_errors)
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
		# Skip hidden directories
		if i.begins_with("."):
			continue
		
		_is_default_skin = false
		# Overriding skin tweaks when no skin is loaded.
		# This can be disabled in Project Settings.
		if i == "none":
			if ProjectSettings.get_setting(
				"application/thunder_settings/allow_overriding_default_suit_tweaks_by_user",
				false
			):
				_is_default_skin = true
			else:
				continue
		
		dir_access.change_dir(base_dir + "/" + i)
		
		# Initiating a skin in dictionaries
		if !_is_default_skin:
			misc_textures[i] = {}
			misc_sounds[i] = {}
			custom_nicknames[i] = i.left(15)
			custom_story_text[i] = CharacterManager.DEFAULT_STORY_TEXT.duplicate()
		suit_tweaks[i] = {}
		if !_is_default_skin:
			suit_sounds[i] = {}
		
		# Loading miscellaneous textures and configs
		if !_is_default_skin:
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
		if !_is_default_skin:
		# Loading global sounds
			misc_sounds[i] = _load_sounds(dir_access, "%s/%s/%s" % [base_dir, i, FOLDER_GLOBAL_SOUNDS])
			var global_skin_tweaks = misc_textures[i].get("global_skin_tweaks")
			var _is_snd_flbck = true
			if global_skin_tweaks:
				_is_snd_flbck = global_skin_tweaks.get("load_sounds_from_siblings_on_fallback")
			if (suit_sounds[i] || misc_sounds[i]) && _is_snd_flbck:
				_apply_fallback_sounds(i)
		
		# Printing errors
		var comp_1 := PackedStringArray(skins[i].keys())
		comp_1.sort()
		var comp_2 := _anims
		comp_2.sort()
		if comp_1 != comp_2 && !_is_default_skin:
			out.append("[Skins Manager] [color=red]ALERT![/color] For [color=yellow]" + str(i) + """[/color], Some animations have not been loaded properly!
	[color=red]Found[/color]: [color=cyan]""" + "[/color], [color=cyan]".join(comp_2) + """[/color].
	[color=red]Loaded without errors[/color]: [color=cyan]""" + "[/color], [color=cyan]".join(comp_1) + "[/color].")
	
	# Final step
	dir_access.list_dir_end()
	out.append("Skins loaded!")
	skins_loaded.emit()
	return "\n".join(out)


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
		if file_ext == "png" && !_is_default_skin:
			if is_array && !arrayed_filename in misc_textures[i]:
				misc_textures[i][arrayed_filename] = []
			var img: Image = Image.load_from_file(file_path)
			var file := ImageTexture.create_from_image(img)
			if is_array:
				misc_textures[i][arrayed_filename].append(file)
			else:
				misc_textures[i][j.get_basename()] = file
		
		# If it's TXT, then check what name it has, and load only valid files to memory
		elif file_ext == "txt" && !_is_default_skin:
			# Name for HUD, variable "custom_nicknames"
			if j.get_basename().to_lower() == "name":
				var file = FileAccess.open(file_path, FileAccess.READ)
				custom_nicknames[i] = file.get_line().left(15)
				Console.print("[Skins Manager] " + i + " Custom nick: " + custom_nicknames[i])
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
					var loaded_line = file.get_line().left(50)
					if loaded_line.is_empty() && len(CharacterManager.DEFAULT_STORY_TEXT) > index:
						loaded_line = CharacterManager.DEFAULT_STORY_TEXT[index]
					custom_story_text[i][index] = loaded_line
				print(i, " Custom story text: ", custom_story_text[i])
				file.close()
				
		# If it's JSON, then check what name it has, and load only valid files to memory
		elif file_ext == "json":
			
			if j.get_basename().to_lower() == CONFIG_GLOBAL_SKIN_TWEAKS:
				var _out: String = _open_file_as_json(file_path)
				if !_out: continue
				var _json: Variant = JSON.parse_string(_out)
				if !_json || !_json is Dictionary:
					Console.print("[Skins Manager] " + file_path + ": Not a valid JSON.")
					continue
				print(i, " Global skin tweaks loaded")
				misc_textures[i][CONFIG_GLOBAL_SKIN_TWEAKS] = _load_json(_json, CharacterManager.DEFAULT_GLOBAL_SKIN_TWEAKS)


func _load_sounds(dir_access: DirAccess, dir_path: String) -> Dictionary:
	var loaded: Dictionary = {}
	if !DirAccess.dir_exists_absolute(dir_path):
		Console.print("[Skins Manager] Global sounds skipped: " + dir_path)
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
	#var _show_help_in_error: bool
	for j in _anims:
		var file_path: String = base_dir + "/" + i + "/" + j
		var file_name: String
		var do_not_load_animations: bool = false
		if !_is_default_skin:
			if !FileAccess.file_exists(file_path + "/" + CONFIG_SKIN_SETTINGS):
				Console.print("[Skins Manager] No %s found at %s. Skipping" % [CONFIG_SKIN_SETTINGS, file_path])
				do_not_load_animations = true
			#if !DirAccess.dir_exists_absolute(file_path + "/" + FOLDER_SUIT_IMAGES):
			#	errored.append("No %s folder found at %s." % [FOLDER_SUIT_IMAGES, file_path])
			#	_show_help_in_error = true
			#	continue
		
			#dir_access.change_dir(file_path + "/" + FOLDER_SUIT_IMAGES)
			#dir_access.list_dir_begin()
			
			#file_name = dir_access.get_next()
			#dir_access.list_dir_end()
			loaded[j] = {}
		
		dir_access.change_dir(file_path)
		dir_access.list_dir_begin()
		file_name = dir_access.get_next()
		while file_name != "":
			if dir_access.current_is_dir():
				file_name = dir_access.get_next()
				continue
			var file_ext: String = file_name.get_extension().to_lower()
			# Loading Suit Tweaks to "suit_tweaks" variable
			if file_name == CONFIG_SUIT_TWEAKS:
				var err = _load_suit_tweaks(i, j, file_path)
				if err:
					errored.append(err)
			
			if do_not_load_animations:
				file_name = dir_access.get_next()
				continue
				
			# Loading external skin textures to cache
			if file_ext == "png" && !_is_default_skin:
				var texture_name: String = file_name.trim_suffix("." + file_ext)
				
				var file: Image = Image.load_from_file(file_path + "/" + file_name)
				var file_texture: ImageTexture = ImageTexture.create_from_image(file)
				#print(i + "/" + j + "/" + file_name)
				loaded[j][texture_name] = file_texture
			
			# Loading skin settings (regions, loops etc.) to cache
			elif file_name == CONFIG_SKIN_SETTINGS && !_is_default_skin:
				var _skin: PlayerSkin = _load_skin_settings(file_path + "/" + CONFIG_SKIN_SETTINGS, j)
				
				if !_skin:
					errored.append(file_path + "/" + CONFIG_SKIN_SETTINGS + " is invalid.")
					file_name = dir_access.get_next()
					continue
				
				skins[i][j] = _skin
			file_name = dir_access.get_next()
		
		dir_access.list_dir_end()
	
	for j in _anims:
		if _is_default_skin: break
		var suit_sounds_path: String = base_dir + "/" + i + "/" + j + "/" + FOLDER_SUIT_SOUNDS
		if DirAccess.dir_exists_absolute(suit_sounds_path):
			suit_sounds[i][j] = _load_sounds(dir_access, suit_sounds_path)
			if suit_sounds[i][j]:
				Console.print("[Skins Manager] Suit %s: %s loaded." % [j, FOLDER_SUIT_SOUNDS])
	
	if !errored.is_empty():
		#if _show_help_in_error:
			#errored.append("")
			#errored.append(
				#"The skin used may be of an older version. Please refer to the skin guide to convert the skin to the current version."
			#)
		OS.alert("
".join(errored), "Player Skin Load Error")
	return loaded


func _load_suit_tweaks(skin, power, file_path: String) -> String:
	if _is_default_skin && power != "_all_suits": return ""
	var _out: String = _open_file_as_json(file_path + "/" + CONFIG_SUIT_TWEAKS)
	if !_out: return ""
	var _json = JSON.parse_string(_out)
	if !_json || !_json is Dictionary:
		return file_path + "/" + CONFIG_SUIT_TWEAKS + " is invalid."
	
	if power == "_all_suits":
		for suit in CharacterManager.MARIO_SUITS.keys():
			suit_tweaks[skin][suit] = _load_json(_json, CharacterManager.DEFAULT_SUIT_TWEAKS)
		return ""
	suit_tweaks[skin][power] = _load_json(_json, CharacterManager.DEFAULT_SUIT_TWEAKS)
	return ""


func get_custom_sprite_frames(old_sprites: SpriteFrames, skin_name: String, power: String, force_err: bool = false) -> SpriteFrames:
	var custom_tex: Dictionary = {}
	
	# Loading cached sprite frames, if exist
	if custom_sprite_frames.has(skin_name) && custom_sprite_frames[skin_name].has(power):
		return custom_sprite_frames[skin_name][power]

	# Loading custom power textures
	if custom_textures[skin_name].has(power):
		custom_tex = custom_textures[skin_name][power]
	
	# Loading external sprite frames to cache
	var new_sprites: SpriteFrames = new_custom_sprite_frames(old_sprites, custom_tex, power, force_err) #load_sprite_frames(skin_name, power)
	if !skin_name in custom_sprite_frames:
		custom_sprite_frames[skin_name] = {}
	custom_sprite_frames[skin_name][power] = new_sprites
	if new_sprites:
		return new_sprites
	
	# Fallback
	push_warning('[Skins Manager] Textures for power "%s" do not exist.' % power)
	#if force_errors:
	#	OS.alert('[Skins Manager] Textures for suit "%s" do not exist.' % power, skin_name)
	return old_sprites


func _apply_fallback_sounds(i: String) -> void:
	dupe_if_no_sound("block_bump", "enemy_bump", i, true)
	dupe_if_no_sound("fall", "fall_death", i, true)
	dupe_if_no_sound("bonus_activate", "hud_acceptance", i, true)
	dupe_if_no_sound("menu_start_song", "level_cutscene_song", i, true, "", false)
	dupe_if_no_sound("hud_pause_close", "menu_enter", i, true, "", false)
	for j in suit_sounds[i]:
		dupe_if_no_sound("powerup_no_transform", "powerup", i, false, j, false)
		dupe_if_no_sound("pipe_in", "pipe_out", i, false, j)
		dupe_if_no_sound("hurt", "pipe_in", i, false, j, false)
		dupe_if_no_snd_mix("kick", "enemy_kick", i, j)

func dupe_if_no_sound(replace: String, with: String, skin: String, global: bool, power: String = "", vice_versa: bool = true) -> void:
	var dict: Dictionary = misc_sounds[skin] if global else suit_sounds[skin][power]
	var sfx_with = dict.get(with)
	var sfx_rep = dict.get(replace)
	if (!sfx_with && !sfx_rep) || (sfx_with && sfx_rep): return
	if !sfx_with && sfx_rep:
		if !vice_versa: return
		sfx_with = dict.get(replace)
		replace = with
	if global:
		misc_sounds[skin][replace] = sfx_with
	else:
		suit_sounds[skin][power][replace] = sfx_with

func dupe_if_no_snd_mix(suit_replace: String, global_with: String, skin: String, power: String) -> void:
	var dict_global: Dictionary = misc_sounds[skin]
	var dict_suit: Dictionary = suit_sounds[skin][power]
	var sfx_with = dict_global.get(global_with)
	if !sfx_with: return
	if dict_suit.get(suit_replace): return
	misc_sounds[skin][suit_replace] = sfx_with

func dupe_if_no_anim(anim_from: StringName, anim_to: StringName, sk_setts: PlayerSkin) -> PlayerSkin:
	if !anim_from in sk_setts.animation_regions || !anim_from in sk_setts.animation_speeds || !anim_from in sk_setts.animation_loops:
		return sk_setts
	if !anim_to in sk_setts.animation_regions || !anim_to in sk_setts.animation_speeds || !anim_to in sk_setts.animation_loops:
		sk_setts.animation_regions[anim_to] = sk_setts.animation_regions[anim_from]
		sk_setts.animation_speeds[anim_to] = sk_setts.animation_speeds[anim_from]
		sk_setts.animation_loops[anim_to] = sk_setts.animation_loops[anim_from]
		Console.print("[Skins Manager] Fallback " + anim_from + " was applied to " + anim_to)
	return sk_setts

func _apply_fallback_anims(sk_setts: PlayerSkin) -> PlayerSkin:
	sk_setts = dupe_if_no_anim( &"swim", &"hold_swim", sk_setts)
	sk_setts = dupe_if_no_anim( &"default", &"crouch", sk_setts)
	sk_setts = dupe_if_no_anim( &"crouch", &"slide", sk_setts)
	sk_setts = dupe_if_no_anim( &"crouch", &"grab", sk_setts)
	sk_setts = dupe_if_no_anim( &"warp", &"win", sk_setts)
	sk_setts = dupe_if_no_anim( &"walk", &"hold_walk", sk_setts)
	sk_setts = dupe_if_no_anim( &"default", &"hold_default", sk_setts)
	sk_setts = dupe_if_no_anim( &"jump", &"fall", sk_setts)
	sk_setts = dupe_if_no_anim( &"jump", &"hold_jump", sk_setts)
	sk_setts = dupe_if_no_anim( &"fall", &"hold_fall", sk_setts)
	sk_setts = dupe_if_no_anim( &"hold_default", &"hold_crouch", sk_setts)
	sk_setts = dupe_if_no_anim( &"attack", &"attack_air", sk_setts)
	return sk_setts
	

func new_custom_sprite_frames(old_sprites: SpriteFrames, textures: Dictionary, power: String, force_err: bool = false) -> SpriteFrames:
	if !old_sprites: return null
	if textures.is_empty(): return old_sprites
	if !current_skin in skins || !power in skins[current_skin]: return old_sprites
	
	var new_sprites := SpriteFrames.new()
	var _regions: Dictionary = skins[current_skin][power].animation_regions
	var _temp_sprites: SpriteFrames = old_sprites.duplicate()
	if CharacterManager.get_suit_tweak("look_up_animation", "", power):
		_temp_sprites.add_animation("look_up")
		_temp_sprites.add_animation("hold_look_up")
	#if CharacterManager.get_suit_tweak("stomp_animation", "", power):
	#	_temp_sprites.add_animation("stomp")
	if CharacterManager.get_suit_tweak("separate_run_animation", "", power):
		_temp_sprites.add_animation("p_run")
		_temp_sprites.add_animation("p_jump")
		_temp_sprites.add_animation("p_fall")
	if CharacterManager.get_suit_tweak("idle_animation", "", power):
		_temp_sprites.add_animation("idle")
	
	if !force_err:
		skins[current_skin][power] = _apply_fallback_anims(skins[current_skin][power])
	_error_buffer = []
	
	var _player_skin: PlayerSkin = skins[current_skin][power]
	
	for anim in _temp_sprites.get_animation_names():
		if anim != "default":
			new_sprites.add_animation(anim)
		for dict_check in ["animation_regions", "animation_speeds", "animation_loops"]:
			if !anim in _player_skin[dict_check]:
				_error_buffer.append(
					"%s: Animation '%s' is not present in %s" % [str(power), anim, dict_check]
				)
				continue
		if !_error_buffer.is_empty():
			if force_err:
				continue
			else:
				break
		new_sprites.set_animation_speed(anim, _player_skin.animation_speeds[anim])
		new_sprites.set_animation_loop(anim, _player_skin.animation_loops[anim])
		var count_durations: bool = "animation_durations" in _player_skin && _player_skin.animation_durations
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
			var frame_dur: float = 1.0
			if count_durations && anim in _player_skin.animation_durations:
				if frame < len(_player_skin.animation_durations[anim]):
					frame_dur = _player_skin.animation_durations[anim][frame]
			new_sprites.add_frame(anim, new_tex, frame_dur)
	#var err = ResourceSaver.save(skins[0], base_dir + "/luigi/%s/skin_settings.tres" % power)
	#print(err)
	
	if !_error_buffer.is_empty():
		_error_buffer.append("")
		_error_buffer.append("Please fix animations using the skin editor, or manually edit a file at %s/%s/%s using text editor" % [str(current_skin), str(power), CONFIG_SKIN_SETTINGS])
		OS.alert("
".join(_error_buffer), str(current_skin) + " Player Skin Load Error")
		return old_sprites
	return new_sprites

# To allow comments in JSON, using //
func _open_file_as_json(file_path: String) -> String:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	var out_string: String = ""
	if !file:
		Console.print("[Skins Manager] Error upon opening skin JSON file")
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

# We are parsing the file manually to avoid malicious code execution, while still maintaining
# compatibility with old skins! Although any mention of scripts is now ignored.
func _load_skin_settings(path: String, power: String) -> PlayerSkin:
	var output := PlayerSkin.new()
	var file = FileAccess.open(path, FileAccess.READ)
	if !file:
		Console.print("[color=red][Skins Manager] Error accessing skin settings at:
	%s[/color]" % path)
		return null
	if file.get_length() > 2_097_152:
		Console.print("[color=red][Skins Manager] Error: File is larger than the limit of 2 MB:
	%s[/color]" % path)
		return null
	
	var reading_buffer: String
	var dict_index_buffer: Dictionary = {}
	
	while !file.eof_reached():
		var line = file.get_line()
		if reading_buffer.is_empty():
			for i in SETTINGS_DICT_NAMES:
				if line.begins_with(i) && !i in dict_index_buffer:
					reading_buffer = i
					dict_index_buffer[reading_buffer] = []
		if reading_buffer.is_empty():
			continue
		var starting_pos: int
		if len(dict_index_buffer[reading_buffer]) == 0:
			var ind_start = line.find("{")
			if ind_start >= 0:
				dict_index_buffer[reading_buffer].append(file.get_position() - len(line) + ind_start - 1)
				starting_pos = ind_start
		if len(dict_index_buffer[reading_buffer]) == 1:
			var ind_start = line.find("}", starting_pos)
			if ind_start >= 0:
				dict_index_buffer[reading_buffer].append(file.get_position() - len(line) + ind_start - 1)
				reading_buffer = ""
				continue
	
	for i in dict_index_buffer:
		if len(dict_index_buffer[i]) != 2:
			print("Array size mismatch: %s" % i)
			continue
		file.seek(dict_index_buffer[i][0])
		
		var dict_str: String = file.get_buffer(dict_index_buffer[i][1] - dict_index_buffer[i][0]).get_string_from_utf8()
		if !dict_str: continue
		
		dict_str += "}"
		var clean_dict: String = dict_str
		for bad_string in BAD_NAMES:
			clean_dict = clean_dict.replacen(bad_string, "")
		var parsed = str_to_var(clean_dict)
		#print(parsed)
		if parsed && parsed is Dictionary:
			output[i] = parsed
		else:
			Console.print("[color=orange][Skins Manager] Warning: %s: Field %s is invalid. Loaded defaults.[/color]" % [power, i])
	
	output.name = power
	return output
