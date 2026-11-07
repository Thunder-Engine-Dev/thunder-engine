extends RichTextLabel
class_name InputRichTextLabel
## Fills this [RichTextLabel] with the current keyboard / gamepad bindings.[br]
## Write tokens in [member text], e.g. [code]press {m_jump} to jump, {m_run} to run[/code].[br]
## Legacy [code]%s[/code] placeholders still work: set [member actions] in left-to-right order.[br][br]
## With [member show_keyboard_input_icons] the keyboard bindings are shown as inline key caps: the
## [code]keyboard_icon.png[/code] texture stretched through its middle column, arrow keys from
## [code]keyboard_icons_sheet.png[/code], and a compact uppercase label drawn into the cap.
## The cap background follows [member icon_height] like gamepad icons, while the label always keeps
## its native [member keyboard_icon_text_size] pixels; a cap grows wider than the icon when the label
## does not fit.[br][br]
## Subclasses can change [member input_template] before [code]super._ready()[/code] or call [method update_text].

## Same as [member Label.uppercase]: visible text is capitalized, BBCode image tags are left intact.
@export var uppercase: bool = false:
	set(value):
		if uppercase == value:
			return
		uppercase = value
		if is_node_ready():
			update_text()
@export_group("Input Display Settings")
## If [code]true[/code], both joypad variants of the input are shown through [member separator].
@export var show_additional_joy_buttons: bool = true
## No effect if [member show_additional_joy_buttons] is [code]false[/code].
@export var separator: String = " / "
## Display size of gamepad icons. [code]em[/code] is relative to visible text height (FontVariation scale included).
@export var icon_height: String = "1em"
## How far gamepad icons and keyboard key caps may be downscaled from the native 32 px cell.[br]
## [code]No downscale[/code] always keeps 32 px. The other presets snap the requested size down to the
## largest allowed size: [code]16x[/code] gives 32 or 16, [code]16x + 24x[/code] also gives 24,
## [code]16x + 20x + 24x + 28x[/code] gives 32 / 28 / 24 / 20 / 16.
@export_enum("No downscale:1", "16x:2", "16x + 24x:4", "16x + 20x + 24x + 28x:8") var icon_allow_downscale_to: int = 4:
	set(value):
		if icon_allow_downscale_to == value:
			return
		icon_allow_downscale_to = value
		if is_node_ready():
			update_text()
## Replaces keyboard key names with inline keyboard key caps while a keyboard is the active device.
@export var show_keyboard_input_icons: bool = false:
	set(value):
		if show_keyboard_input_icons == value:
			return
		show_keyboard_input_icons = value
		if is_node_ready():
			update_text()
## Pixel size of the default font label drawn into [member show_keyboard_input_icons] key caps.
## Independent of [member icon_height]: only the cap background is scaled, the label always keeps
## this physical size and the cap grows wider when the label does not fit.
@export var keyboard_icon_text_size: int = 11:
	set(value):
		if keyboard_icon_text_size == value:
			return
		keyboard_icon_text_size = value
		if is_node_ready():
			update_text()
## Color of the label baked into [member show_keyboard_input_icons] key caps.
@export var keyboard_icon_text_color: Color = Color("#687068"):
	set(value):
		if keyboard_icon_text_color == value:
			return
		keyboard_icon_text_color = value
		if is_node_ready():
			update_text()
## Keyboard names get a [code] key[/code] suffix. Ignored in [member show_keyboard_input_icons] mode.
@export var keyboard_as_button: bool = false
## Used only for [code]%s[/code] placeholders, in left-to-right order.
@export var actions: PackedStringArray = []

## Source string with [code]{action}[/code] / [code]%s[/code] tokens. Captured from [member text] on ready if empty.
var input_template: String

var _token_regex: RegEx
var _markup_regex: RegEx
var _placeholder_regex: RegEx
var _gamepad_image_regex: RegEx

const ICON_CELL_TO_TEXT := 1.3

# Inline keyboard key cap assets. The base cap is 32x32 with 16 px wide end caps;
# only the middle column is repeated to fit longer labels. The background is scaled to the resolved
# icon size, while the caption is rasterized at its native size into the final pixels. All base
# measurements below are in that 32 px geometry.
const KEYBOARD_ICON_TEXTURE := preload("res://engine/scenes/main_menu/textures/gamepad_icons/keyboard_icon.png")
const KEYBOARD_ICONS_SHEET := preload("res://engine/scenes/main_menu/textures/gamepad_icons/keyboard_icons_sheet.png")
const KEYBOARD_ICON_SIZE := 32
const KEYBOARD_ICON_CAP_WIDTH := 16
# A caption keeps at least 6 base px free on each side; a wider caption adds its native width plus
# that overlap to the display width. The overlap scales with the background: 6 * icon_px / 32 px per
# side (6 px at 32, 3 px at 16).
const KEYBOARD_ICON_TEXT_OVERLAP := 6.0
# The cap art has its bright top face centered at 14 px of the 32 px base height; the caption is
# centered on that face so it follows the scaled cap without changing its own pixel size.
const KEYBOARD_ICON_TEXT_CENTER_RATIO := 14.0 / 32.0
const KEYBOARD_ICON_CACHE_LIMIT := 64
# Sizes an icon may downscale to for each [member icon_allow_downscale_to] preset, largest first. The
# native 32 px cell is always available and is prepended when the allowed sizes are resolved.
const ICON_DOWNSCALE_SIZES := {
	1: [], # No downscale, 32 px only.
	2: [16],
	4: [24, 16],
	8: [28, 24, 20, 16],
}
# Above this fraction of the native cell the icon keeps the full cell size instead of being downscaled,
# so a request like "1.5em" (31 px) does not jump down to 24 px.
const ICON_FULL_SIZE_THRESHOLD := 0.88
# Sheet order from left to right.
const KEYBOARD_ARROW_REGIONS := [
	Rect2(0, 0, 32, 32), # Left
	Rect2(32, 0, 32, 32), # Up
	Rect2(64, 0, 32, 32), # Right
	Rect2(96, 0, 32, 32), # Down
]

# Key names (lower case, as reported by InputEventKey.as_text) shown as symbols.
const KEY_NAME_SYMBOLS := {
	"slash": "/",
	"backslash": "\\",
	"intlbackslash": "\\",
	"backslash2": "\\",
	"apostrophe": "'",
	"quoteleft": "`",
	"grave": "`",
	"quotedbl": "\"",
	"semicolon": ";",
	"comma": ",",
	"period": ".",
	"dot": ".",
	"minus": "-",
	"equal": "=",
	"bracketleft": "[",
	"bracketright": "]",
	"less": "<",
	"greater": ">",
	"bar": "|",
	"kp multiply": "*",
	"kp divide": "/",
	"kp subtract": "-",
	"kp add": "+",
	"kp period": ".",
	"special": "?",
	"unknown": "?",
	"section": "§"
}
## Key names that get a fixed compact caption instead of a plain upper case copy.
const KEY_NAME_CAPTIONS := {
	"windows": "META",
	"meta": "META",
	"command": "META",
	"cmd": "META",
	"super": "META",
	"return": "ENTER",
	"escape": "ESC",
	"backspace": "BKSP",
	"insert": "INS",
	"delete": "DEL",
	"pageup": "PGUP",
	"pagedown": "PGDN",
	"printscreen": "PRTSC",
	"numlock": "NUMLK",
	"scrolllock": "SCRLK",
	"capslock": "CAPS",
}

static var _keyboard_base_image: Image
static var _keyboard_icon_cache: Dictionary = {}
static var _keyboard_arrow_cache: Dictionary = {}
static var _gamepad_icon_cache: Dictionary = {}


func _ready() -> void:
	bbcode_enabled = true
	#texture_filter = TEXTURE_FILTER_NEAREST
	if input_template.is_empty():
		input_template = text
	_ensure_regexes()

	Thunder._connect(SettingsManager.settings_saved, update_text)
	Thunder._connect(SettingsManager.settings_updated, update_text)
	Thunder._connect(SettingsManager.settings_loaded, update_text)
	Thunder._connect(SettingsManager.device_changed, update_text.unbind(1))
	Thunder._connect(Input.joy_connection_changed, update_text.unbind(2))
	update_text()


## Regexes are also needed when a subclass calls [method update_text] before [code]super._ready()[/code].
func _ensure_regexes() -> void:
	if _token_regex == null:
		_token_regex = RegEx.create_from_string("\\{([A-Za-z0-9_]+)\\}")
	if _markup_regex == null:
		_markup_regex = RegEx.create_from_string(
			"(?i)\\[img[^\\]]*\\][^\\[]*\\[/img\\]|\\[/?[A-Za-z][^\\]]*\\]"
		)
	if _placeholder_regex == null:
		_placeholder_regex = RegEx.create_from_string(
			"%s(\\d+)%s" % [_placeholder_char(), _placeholder_char_end()]
		)
	if _gamepad_image_regex == null:
		# Exact shape produced by Thunder.input.get_joy_icon_bbcode; anything else stays BBCode text.
		_gamepad_image_regex = RegEx.create_from_string(
			"\\[img width=(-?\\d+) height=(-?\\d+) region=(\\d+),(\\d+),(\\d+),(\\d+) align=([a-z_]+)\\]([^\\[\\]]+)\\[/img\\]"
		)


func update_text() -> void:
	if input_template.is_empty():
		return
	_ensure_regexes()

	if show_keyboard_input_icons && SettingsManager.device_keyboard:
		_render_keyboard_input_icons()
		return

	var parsed := _replace_tokens(input_template)
	for action in actions:
		var idx := parsed.find("%s")
		if idx < 0:
			break
		parsed = parsed.substr(0, idx) + _format_action(action) + parsed.substr(idx + 2)
	
	if uppercase:
		parsed = _uppercase_preserving_markup(parsed)
	_render_input_images(parsed)


func _replace_tokens(src: String) -> String:
	var result := src
	var seen: Dictionary = {}
	for matched in _token_regex.search_all(src):
		var action := matched.get_string(1)
		if action in seen:
			continue
		seen[action] = true
		if !_action_exists(action):
			continue
		result = result.replace("{%s}" % action, _format_action(action))
	return result


func _action_exists(action: String) -> bool:
	return (
		InputMap.has_action(action)
		|| SettingsManager.settings.controls.has(action)
		|| SettingsManager.settings.controls_joypad.has(action)
	)


func _format_action(action: StringName) -> String:
	var icon_size := _resolved_icon_size()
	var formatted: String
	if !show_additional_joy_buttons && !SettingsManager.device_keyboard:
		formatted = _first_joy_input_text(action, icon_size)
	else:
		formatted = Thunder.input.get_input_rich_text(action, separator, icon_size)
	if keyboard_as_button && SettingsManager.device_keyboard && !formatted.to_lower().ends_with("key"):
		formatted += " key"
	return formatted


## First joypad binding only, used when [member show_additional_joy_buttons] is [code]false[/code].
## Delegates to the engine for the "not set" fallback so the copy stays identical.
func _first_joy_input_text(action: StringName, icon_size: String) -> String:
	var indices: Array = SettingsManager.settings.controls_joypad.get(str(action), [])
	if indices.is_empty():
		return Thunder.input.get_joy_input_rich_text(action, separator, icon_size)
	return Thunder.input.get_joy_icon_bbcode(int(indices[0]), icon_size)


## Renders [param src], replacing the engine gamepad [code][img][/code] tags with inline runtime
## textures.[br]
## A BBCode image is drawn with the label's own texture filter, so a scaled 32 px sheet cell would be
## resampled with nearest-neighbour. The runtime texture is resized once with bilinear interpolation
## and then drawn 1:1, while the rest of the text and every other tag stay in the BBCode text. Strings
## without gamepad icons keep the plain [member text] assignment.
func _render_input_images(src: String) -> void:
	if _gamepad_image_regex == null:
		text = src
		return
	var matches := _gamepad_image_regex.search_all(src)
	if matches.is_empty():
		text = src
		return

	# Assigning the empty text also clears the stored BBCode, because manual stack edits are not
	# reflected in the [member text] property.
	text = ""
	var pos := 0
	for matched in matches:
		var chunk := src.substr(pos, matched.get_start() - pos)
		if !chunk.is_empty():
			append_text(chunk)
		var texture := _gamepad_icon_texture(matched)
		if texture == null:
			append_text(matched.get_string())
		else:
			var size := Vector2i(texture.get_width(), texture.get_height())
			add_image(texture, size.x, size.y, Color.WHITE, INLINE_ALIGNMENT_CENTER)
		pos = matched.get_end()
	var tail := src.substr(pos)
	if !tail.is_empty():
		append_text(tail)


## Inline texture for one gamepad [code][img][/code] match. The sheet region is cut out and resized
## with bilinear interpolation to the requested size, so the icon is sampled 1:1 on screen. Native
## size cells skip the resize and keep the atlas region untouched. Cached per path, region and size.
func _gamepad_icon_texture(matched: RegExMatch) -> Texture2D:
	var region := Rect2i(
		int(matched.get_string(3)),
		int(matched.get_string(4)),
		int(matched.get_string(5)),
		int(matched.get_string(6))
	)
	var size := Vector2i(int(matched.get_string(1)), int(matched.get_string(2)))
	var path := matched.get_string(8)
	if size.x <= 0 || size.y <= 0 || region.size.x <= 0 || region.size.y <= 0:
		return null

	var key := "%s|%d,%d,%d,%d|%dx%d" % [
		path, region.position.x, region.position.y, region.size.x, region.size.y, size.x, size.y
	]
	var cached: Texture2D = _gamepad_icon_cache.get(key)
	if cached != null:
		return cached

	var texture: Texture2D = ResourceLoader.load(path, "Texture2D")
	if texture == null:
		return null

	var result: Texture2D
	if size == region.size:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(region)
		result = atlas
	else:
		var image: Image = texture.get_image()
		if image == null:
			return null
		var piece := image.get_region(region)
		if piece.get_format() != Image.FORMAT_RGBA8:
			piece.convert(Image.FORMAT_RGBA8)
		piece.resize(size.x, size.y, Image.INTERPOLATE_BILINEAR)
		result = ImageTexture.create_from_image(piece)

	if _gamepad_icon_cache.size() >= KEYBOARD_ICON_CACHE_LIMIT:
		_gamepad_icon_cache.clear()
	_gamepad_icon_cache[key] = result
	return result


#region Keyboard icon mode

## Rebuilds the label from [member input_template] as text runs and inline key cap images.
## [method RichTextLabel.append_text] and [method RichTextLabel.add_image] are used because a runtime
## [ImageTexture] has no resource path for a BBCode [code][img][/code] tag. No child nodes are created.
func _render_keyboard_input_icons() -> void:
	var segments := _icon_segments(input_template)
	# Assigning the empty text also clears the stored BBCode, because manual stack edits are not
	# reflected in the [member text] property.
	text = ""
	for segment in segments:
		if segment is StringName:
			_render_keyboard_icon(StringName(segment))
			continue
		var chunk: String = segment
		if uppercase:
			chunk = _uppercase_preserving_markup(chunk)
		if !chunk.is_empty():
			append_text(chunk)


func _render_keyboard_icon(action: StringName) -> void:
	var label := _keyboard_icon_label(action)
	if label.is_empty():
		var fallback := Thunder.input.get_input_rich_text(action)
		if uppercase:
			fallback = _uppercase_preserving_markup(fallback)
		if !fallback.is_empty():
			append_text(fallback)
		return

	var arrow := _keyboard_arrow_index(label)
	if arrow >= 0:
		var icon_px := _resolved_icon_px()
		var arrow_texture := _keyboard_arrow_texture(arrow, icon_px)
		if arrow_texture != null:
			# The cell is already resized to the display size, so no resampling happens at draw time.
			add_image(
				arrow_texture,
				icon_px,
				icon_px,
				Color.WHITE,
				INLINE_ALIGNMENT_CENTER
			)
			return

	var texture := _keyboard_icon_texture(label, _resolved_icon_px())
	if texture == null:
		if !label.is_empty():
			append_text(label)
		return
	# The texture is already built at the final pixel size, so the caption inside it keeps its native
	# text size instead of being stretched with the cap background.
	add_image(
		texture,
		texture.get_width(),
		texture.get_height(),
		Color.WHITE,
		INLINE_ALIGNMENT_CENTER
	)


## Splits [param src] into plain text pieces and [StringName] action pieces, keeping the original order.
func _icon_segments(src: String) -> Array:
	var found: Array[StringName] = []
	var result := src
	var seen: Dictionary = {}
	for matched in _token_regex.search_all(src):
		var action := matched.get_string(1)
		if action in seen:
			continue
		seen[action] = true
		if !_action_exists(action):
			continue
		result = result.replace("{%s}" % action, _placeholder(found.size()))
		found.append(StringName(action))

	var action_index := 0
	while action_index < actions.size():
		var idx := result.find("%s")
		if idx < 0:
			break
		result = result.substr(0, idx) + _placeholder(found.size()) + result.substr(idx + 2)
		found.append(StringName(actions[action_index]))
		action_index += 1

	var segments: Array = []
	var pos := 0
	for matched in _placeholder_regex.search_all(result):
		if matched.get_start() > pos:
			segments.append(result.substr(pos, matched.get_start() - pos))
		var index := matched.get_string(1).to_int()
		if index >= 0 && index < found.size():
			segments.append(found[index])
		pos = matched.get_end()
	if pos < result.length():
		segments.append(result.substr(pos))
	return segments


static func _placeholder_char() -> String:
	return String.chr(1)


static func _placeholder_char_end() -> String:
	return String.chr(2)


static func _placeholder(index: int) -> String:
	return "%s%d%s" % [_placeholder_char(), index, _placeholder_char_end()]


## Compact upper case caption for [param action], or an empty string when the action has no keyboard key.
## Modifier combinations keep every part, e.g. [code]Ctrl+Z[/code] becomes [code]CTRL+Z[/code].
func _keyboard_icon_label(action: StringName) -> String:
	var raw := Thunder.input.get_input_rich_text(action).strip_edges()
	if raw.is_empty() || raw.begins_with("<"):
		return ""
	# SettingsManager.get_key_label appends " button" to the key name.
	if raw.ends_with(" button"):
		raw = raw.substr(0, raw.length() - " button".length()).strip_edges()
	if raw.is_empty():
		return ""

	var parts: PackedStringArray = []
	for part in raw.split("+", true):
		var _name := part.strip_edges()
		if !_name.is_empty():
			parts.append(_compact_key_caption(_name))
	return "+".join(parts)


## One key name as a symbol or compact upper case caption.
func _compact_key_caption(_name: String) -> String:
	var key_name := _name.to_lower()
	if KEY_NAME_SYMBOLS.has(key_name):
		return KEY_NAME_SYMBOLS[key_name]
	if KEY_NAME_CAPTIONS.has(key_name):
		return KEY_NAME_CAPTIONS[key_name]
	return _name.to_upper()


## Sheet index of a plain arrow key caption, or [code]-1[/code] for any other key or modifier combo.
func _keyboard_arrow_index(label: String) -> int:
	match label.to_lower():
		"left":
			return 0
		"up":
			return 1
		"right":
			return 2
		"down":
			return 3
	return -1


## Arrow key cap from [member KEYBOARD_ICONS_SHEET] at [param icon_px]. The 32 px cell is cut out and
## resized once per size with bilinear interpolation, so the icon is drawn 1:1 instead of being
## resampled by the label's texture filter. The native cell skips the resize.
func _keyboard_arrow_texture(index: int, icon_px: int) -> Texture2D:
	if index < 0 || index >= KEYBOARD_ARROW_REGIONS.size():
		return null
	var size := maxi(icon_px, 1)
	var key := "arrow|%d|%d" % [index, size]
	var cached: Texture2D = _keyboard_arrow_cache.get(key)
	if cached != null:
		return cached

	var region: Rect2 = KEYBOARD_ARROW_REGIONS[index]
	var result: Texture2D
	if roundi(region.size.x) == size && roundi(region.size.y) == size:
		var atlas := AtlasTexture.new()
		atlas.atlas = KEYBOARD_ICONS_SHEET
		atlas.region = region
		result = atlas
	else:
		var image: Image = KEYBOARD_ICONS_SHEET.get_image()
		if image == null:
			return null
		image = image.duplicate()
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		var piece := image.get_region(Rect2i(region))
		piece.resize(size, size, Image.INTERPOLATE_BILINEAR)
		result = ImageTexture.create_from_image(piece)

	if _keyboard_arrow_cache.size() >= KEYBOARD_ICON_CACHE_LIMIT:
		_keyboard_arrow_cache.clear()
	_keyboard_arrow_cache[key] = result
	return result


## Cached final-pixel key cap texture for [param label] at [param icon_px]. The texture is built at
## the exact display size, so the caption is never scaled with the background. The key covers the
## label, display size, text size and color.
func _keyboard_icon_texture(label: String, icon_px: int) -> Texture2D:
	var key := "cap|%s|%d|%d|%s" % [
		label, icon_px, keyboard_icon_text_size, keyboard_icon_text_color.to_html(true)
	]
	var cached: Texture2D = _keyboard_icon_cache.get(key)
	if cached != null:
		return cached

	var built := _build_keyboard_icon(label, icon_px)
	if built == null:
		return null
	if _keyboard_icon_cache.size() >= KEYBOARD_ICON_CACHE_LIMIT:
		_keyboard_icon_cache.clear()
	_keyboard_icon_cache[key] = built
	return built


## Uniform scale from the base [constant KEYBOARD_ICON_SIZE] geometry to [param icon_px].
func _keyboard_icon_scale(icon_px: int) -> float:
	return float(icon_px) / float(KEYBOARD_ICON_SIZE)


## Draws the key cap at the final display size: the 16 px end caps are scaled by [param scale] and
## the remaining width repeats the 1 px middle column. The caption is drawn afterwards at its native
## size, so only this background follows [member icon_height].
func _draw_keyboard_icon_background(image: Image, base: Image, _scale: float) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var cap_width := maxi(roundi(float(KEYBOARD_ICON_CAP_WIDTH) * _scale), 1)
	var left_width := mini(cap_width, width)
	var right_width := mini(cap_width, width - left_width)

	var left := base.get_region(Rect2i(0, 0, KEYBOARD_ICON_CAP_WIDTH, KEYBOARD_ICON_SIZE))
	left.resize(left_width, height, Image.INTERPOLATE_BILINEAR)
	image.blit_rect(left, Rect2i(0, 0, left_width, height), Vector2i.ZERO)

	var middle_width := width - left_width - right_width
	if middle_width > 0:
		var middle := base.get_region(Rect2i(KEYBOARD_ICON_CAP_WIDTH, 0, 1, KEYBOARD_ICON_SIZE))
		middle.resize(middle_width, height, Image.INTERPOLATE_BILINEAR)
		image.blit_rect(middle, Rect2i(0, 0, middle_width, height), Vector2i(left_width, 0))

	if right_width > 0:
		var right := base.get_region(
			Rect2i(KEYBOARD_ICON_CAP_WIDTH, 0, KEYBOARD_ICON_SIZE - KEYBOARD_ICON_CAP_WIDTH, KEYBOARD_ICON_SIZE)
		)
		right.resize(right_width, height, Image.INTERPOLATE_BILINEAR)
		image.blit_rect(right, Rect2i(0, 0, right_width, height), Vector2i(width - right_width, 0))


## Builds a key cap [param icon_px] pixels tall. The background is scaled to that height, but the
## caption is rasterized at [member keyboard_icon_text_size] native pixels and centered on the cap
## face. The width is [code]max(icon_px, ceil(text_width + 2 * scaled_overlap))[/code], so a short
## caption stays at the base icon width and a long one widens the middle column only.
func _build_keyboard_icon(label: String, icon_px: int) -> Texture2D:
	var base := _get_keyboard_base_image()
	var font := _keyboard_icon_font()
	if base == null || font == null:
		return null

	var height := maxi(icon_px, 1)
	var text_size := maxi(1, keyboard_icon_text_size)
	var _scale := _keyboard_icon_scale(height)
	var overlap := KEYBOARD_ICON_TEXT_OVERLAP * _scale
	var text_width := _keyboard_label_width(font, text_size, label)
	var width := maxi(height, ceili(text_width + overlap * 2.0))

	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	_draw_keyboard_icon_background(image, base, _scale)
	_draw_keyboard_icon_label(image, font, text_size, label, keyboard_icon_text_color)
	return ImageTexture.create_from_image(image)


static func _get_keyboard_base_image() -> Image:
	if _keyboard_base_image != null:
		return _keyboard_base_image
	var image: Image = KEYBOARD_ICON_TEXTURE.get_image()
	if image == null:
		push_error("[InputRichTextLabel] Keyboard icon texture has no CPU image data.")
		return null
	image = image.duplicate()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	_keyboard_base_image = image
	return _keyboard_base_image


## Standard Godot default font (Open Sans SemiBold), not the RichTextLabel theme font.
func _keyboard_icon_font() -> Font:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		font = get_theme_font(&"normal_font")
	return font


## Sum of glyph advances, matching the positions used while drawing the caption.
func _keyboard_label_width(font: Font, text_size: int, label: String) -> float:
	var ts := TextServerManager.get_primary_interface()
	if ts == null:
		return font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var rids := font.get_rids()
	if rids.is_empty():
		return font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var rid: RID = rids[0]
	var width := 0.0
	for i in label.length():
		var glyph := ts.font_get_glyph_index(rid, text_size, label.unicode_at(i), 0)
		if glyph == 0:
			continue
		width += ts.font_get_glyph_advance(rid, text_size, glyph).x
	return width


## Rasterizes [param label] with [TextServer] and blends it centered into [param image].
func _draw_keyboard_icon_label(image: Image, font: Font, text_size: int, label: String, color: Color) -> void:
	var ts := TextServerManager.get_primary_interface()
	if ts == null:
		return
	var rids := font.get_rids()
	if rids.is_empty():
		return
	var rid: RID = rids[0]
	var glyph_size := Vector2i(text_size, 0)

	var cap_glyph := ts.font_get_glyph_index(rid, text_size, 0x48, 0) # H
	ts.font_render_glyph(rid, glyph_size, cap_glyph)
	var cap_offset := ts.font_get_glyph_offset(rid, glyph_size, cap_glyph)
	var cap_box := ts.font_get_glyph_size(rid, glyph_size, cap_glyph)
	var ink_height := cap_box.y
	if ink_height <= 0.0:
		ink_height = ts.font_get_ascent(rid, text_size)
	# Center the glyph box on the cap face, which reads as the visual center of the key. The caption
	# keeps its native pixel size, so only the face position follows the scaled background.
	var center_y := float(image.get_height()) * KEYBOARD_ICON_TEXT_CENTER_RATIO
	var baseline := center_y - cap_offset.y - ink_height * 0.5

	var cursor := (float(image.get_width()) - _keyboard_label_width(font, text_size, label)) * 0.5
	var pages: Dictionary = {}

	for i in label.length():
		var code := label.unicode_at(i)
		var glyph := ts.font_get_glyph_index(rid, text_size, code, 0)
		if glyph == 0:
			continue
		ts.font_render_glyph(rid, glyph_size, glyph)

		var page_index := ts.font_get_glyph_texture_idx(rid, glyph_size, glyph)
		if !pages.has(page_index):
			var page: Image = ts.font_get_texture_image(rid, glyph_size, page_index)
			if page == null:
				continue
			page = page.duplicate()
			# Font pages store coverage in alpha for LA8 / RGBA8 and in the red channel for L8 / R8.
			var page_format := page.get_format()
			var coverage_in_alpha := page_format == Image.FORMAT_LA8 || page_format == Image.FORMAT_RGBA8
			if page_format != Image.FORMAT_RGBA8:
				page.convert(Image.FORMAT_RGBA8)
			pages[page_index] = { "image": page, "alpha": coverage_in_alpha }
		var page_data: Dictionary = pages[page_index]

		var uv := ts.font_get_glyph_uv_rect(rid, glyph_size, glyph)
		var region := Rect2i(
			Vector2i(roundi(uv.position.x), roundi(uv.position.y)),
			Vector2i(roundi(uv.size.x), roundi(uv.size.y))
		)
		if region.size.x > 0 && region.size.y > 0:
			var piece: Image = (page_data["image"] as Image).get_region(region)
			_tint_keyboard_glyph(piece, color, bool(page_data["alpha"]))
			var offset := ts.font_get_glyph_offset(rid, glyph_size, glyph)
			image.blend_rect(
				piece,
				Rect2i(Vector2i.ZERO, piece.get_size()),
				Vector2i(roundi(cursor + offset.x), roundi(baseline + offset.y))
			)
		cursor += ts.font_get_glyph_advance(rid, text_size, glyph).x


## Uses the glyph coverage channel, which is alpha for LA8 / RGBA8 pages and luminance for L8 pages.
func _tint_keyboard_glyph(piece: Image, color: Color, coverage_in_alpha: bool) -> void:
	for y in piece.get_height():
		for x in piece.get_width():
			var source := piece.get_pixel(x, y)
			var coverage := source.a if coverage_in_alpha else source.r
			piece.set_pixel(x, y, Color(color.r, color.g, color.b, coverage * color.a))

#endregion


func _resolved_icon_size() -> String:
	var h := icon_height.strip_edges()
	var target := _visual_text_height()
	if h.ends_with("em"):
		var ratio := h.substr(0, h.length() - 2).to_float()
		if ratio <= 0.0:
			ratio = 1.0
		target *= ratio
	elif h.ends_with("px"):
		target = h.substr(0, h.length() - 2).to_float()
	elif !h.is_empty() && h.is_valid_float():
		target = h.to_float()
	return str(_sharp_icon_px(target))


## [method _resolved_icon_size] as whole pixels for inline keyboard icons. Custom [code]em[/code] and
## [code]px[/code] values go through the same allowed downscale sizes the gamepad icons use.
func _resolved_icon_px() -> int:
	var resolved := _resolved_icon_size()
	if resolved.is_valid_int():
		return maxi(resolved.to_int(), 1)
	return KEYBOARD_ICON_SIZE


## Allowed display sizes for the current [member icon_allow_downscale_to], largest first. The 32 px
## cell is the native size; the preset lists the smaller sizes the icon may be snapped down to.
func _allowed_icon_sizes() -> Array:
	var cell := Thunder.input.GAMEPAD_ICON_CELL
	var downscales: Array = ICON_DOWNSCALE_SIZES.get(icon_allow_downscale_to, ICON_DOWNSCALE_SIZES[2])
	var sizes: Array = [cell]
	for _size in downscales:
		sizes.append(mini(int(_size), cell))
	return sizes


## Snaps [param target] down to the largest allowed icon size, so a 32x32 source is never stretched by
## a fractional factor. Near the native cell the full size is kept; below the smallest allowed size the
## smallest one wins. "No downscale" therefore always returns the 32 px cell.
func _sharp_icon_px(target: float) -> int:
	var sizes := _allowed_icon_sizes()
	var cell: int = sizes[0]
	if target >= float(cell) * ICON_FULL_SIZE_THRESHOLD:
		return cell
	for _size in sizes:
		if target >= float(_size):
			return int(_size)
	return int(sizes[sizes.size() - 1])


## Visible line height: squashed FontVariations use [code]font_size * y_scale[/code].
## Pixel fonts (Junebug) can ink taller than the em, so the larger value wins.
func _visual_text_height() -> float:
	var font: Font = get_theme_font(&"normal_font")
	var font_size: int = get_theme_font_size(&"normal_font_size")
	if font_size <= 0:
		font_size = get_theme_default_font_size()
	if font_size <= 0:
		font_size = 16
	
	var y_scale := 1.0
	if font is FontVariation:
		y_scale = absf((font as FontVariation).variation_transform.get_scale().y)
		if y_scale < 0.001:
			y_scale = 1.0
	
	# Ink is taken from the base font RID (unsquashed)
	var visual_em := float(font_size) * y_scale
	if font != null:
		var ink := _font_cap_ink_height(font, font_size)
		if ink > float(font_size):
			visual_em = ink
	
	return maxf(visual_em * ICON_CELL_TO_TEXT, 1.0)


func _font_cap_ink_height(font: Font, font_size: int) -> float:
	var ts := TextServerManager.get_primary_interface()
	if ts == null:
		return maxf(font.get_ascent(font_size), float(font_size))
	
	var rids := font.get_rids()
	if rids.is_empty():
		return maxf(font.get_ascent(font_size), 1.0)
	
	var rid: RID = rids[0]
	var _size := Vector2i(font_size, 0)
	var ink_h := 0.0
	for code in PackedInt32Array([0x48, 0x4D, 0x41, 0x58]): # H M A X
		var glyph := ts.font_get_glyph_index(rid, font_size, code, 0)
		if glyph == 0:
			continue
		ink_h = maxf(ink_h, absf(ts.font_get_glyph_size(rid, _size, glyph).y))
	
	if ink_h < 1.0:
		ink_h = font.get_ascent(font_size)
	return ink_h


## Same as [Label.uppercase], but BBCode tags and their resource paths keep their original case.
func _uppercase_preserving_markup(src: String) -> String:
	var markup: PackedStringArray = []
	var out := ""
	var pos := 0
	for matched in _markup_regex.search_all(src):
		out += src.substr(pos, matched.get_start() - pos).to_upper()
		out += "\uFFFC%d\uFFFC" % markup.size()
		markup.append(matched.get_string())
		pos = matched.get_end()
	out += src.substr(pos).to_upper()

	for i in markup.size():
		out = out.replace("\uFFFC%d\uFFFC" % i, markup[i])
	return out
