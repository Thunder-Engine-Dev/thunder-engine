extends RichTextLabel
class_name InputRichTextLabel
## Fills this [RichTextLabel] with the current keyboard / gamepad bindings.[br]
## Write tokens in [member text], e.g. [code]press {m_jump} to jump, {m_run} to run[/code].[br]
## Legacy [code]%s[/code] placeholders still work: set [member actions] in left-to-right order.
## [br][br]
## Subclasses can change [member input_template] before [code]super._ready()[/code] or call [method update_text].

## Used only for [code]%s[/code] placeholders, in left-to-right order.
@export var actions: PackedStringArray = []
@export var separator: String = " / "
## Display size of gamepad icons. [code]em[/code] is relative to visible text height (FontVariation scale included).
@export var icon_height: String = "1em"
## Keyboard names get a [code] key[/code] suffix, matching old sign copy.
@export var keyboard_as_button: bool = false
## Same as [Label.uppercase]: visible text is capitalized, BBCode image tags are left intact.
@export var uppercase: bool = false:
	set(value):
		if uppercase == value:
			return
		uppercase = value
		if is_node_ready():
			update_text()

## Source string with [code]{action}[/code] / [code]%s[/code] tokens. Captured from [member text] on ready if empty.
var input_template: String

var _token_regex: RegEx
var _img_regex: RegEx

const ICON_CELL_TO_TEXT := 1.3


func _ready() -> void:
	bbcode_enabled = true
	#texture_filter = TEXTURE_FILTER_NEAREST
	if input_template.is_empty():
		input_template = text
	_token_regex = RegEx.create_from_string("\\{([A-Za-z0-9_]+)\\}")
	_img_regex = RegEx.create_from_string("(?i)\\[img[^\\]]*\\][^\\[]*\\[/img\\]")
	
	Thunder._connect(SettingsManager.settings_saved, update_text)
	Thunder._connect(SettingsManager.settings_updated, update_text)
	Thunder._connect(SettingsManager.settings_loaded, update_text)
	Thunder._connect(SettingsManager.device_changed, update_text.unbind(1))
	Thunder._connect(Input.joy_connection_changed, update_text.unbind(2))
	update_text()


func update_text() -> void:
	if input_template.is_empty():
		return
	
	var parsed := _replace_tokens(input_template)
	for action in actions:
		var idx := parsed.find("%s")
		if idx < 0:
			break
		parsed = parsed.substr(0, idx) + _format_action(action) + parsed.substr(idx + 2)
	
	if uppercase:
		parsed = _uppercase_preserving_images(parsed)
	text = parsed


func _replace_tokens(src: String) -> String:
	var result := src
	var seen: Dictionary = {}
	for matched in _token_regex.search_all(src):
		var action := matched.get_string(1)
		if action in seen:
			continue
		seen[action] = true
		if (
			!InputMap.has_action(action)
			&& !SettingsManager.settings.controls.has(action)
			&& !SettingsManager.settings.controls_joypad.has(action)
		):
			continue
		result = result.replace("{%s}" % action, _format_action(action))
	return result


func _format_action(action: StringName) -> String:
	var formatted := Thunder.input.get_input_rich_text(action, separator, _resolved_icon_size())
	if keyboard_as_button && SettingsManager.device_keyboard && !formatted.to_lower().ends_with("key"):
		formatted += " key"
	return formatted


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


## Snap to 16 or 32 so a 32x32 source scales by an integer factor
func _sharp_icon_px(target: float) -> int:
	var cell := Thunder.input.GAMEPAD_ICON_CELL
	if target >= float(cell) * 0.75:
		return cell
	@warning_ignore("integer_division")
	return maxi(cell / 2, 8)


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


func _uppercase_preserving_images(src: String) -> String:
	var images: PackedStringArray = []
	var out := ""
	var pos := 0
	for matched in _img_regex.search_all(src):
		out += src.substr(pos, matched.get_start() - pos).to_upper()
		out += "\uFFFC%d\uFFFC" % images.size()
		images.append(matched.get_string())
		pos = matched.get_end()
	out += src.substr(pos).to_upper()
	
	for i in images.size():
		out = out.replace("\uFFFC%d\uFFFC" % i, images[i])
	return out
