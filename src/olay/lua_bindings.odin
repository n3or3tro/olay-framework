package olay

import str "core:strings"
import lua "vendor:lua/5.1"

// ---- registration ----

lua_register_all :: proc(L: ^lua.State) {
	lua.register(L, "text_button", lua_text_button)
	lua.register(L, "button", lua_button)
	lua.register(L, "text", lua_text)
	lua.register(L, "icon", lua_icon)
	lua.register(L, "icon_button", lua_icon_button)
	lua.register(L, "begin_container", lua_begin_container)
	lua.register(L, "end_container", lua_end_container)
	lua.register(L, "line", lua_line)
	lua.register(L, "hover_help_text", lua_hover_help_text)
	lua.register(L, "vertical_slider", lua_vertical_slider)
	lua.register(L, "edit_number_box", lua_edit_number_box)
	lua.register(L, "edit_text_box", lua_edit_text_box)
	lua.register(L, "circular_knob", lua_circular_knob)
	lua.register(L, "begin_draggable_window", lua_begin_draggable_window)
	lua.register(L, "end_draggable_window", lua_end_draggable_window)
	lua.register(L, "begin_virtual_list", lua_begin_virtual_list)
	lua.register(L, "end_virtual_list", lua_end_virtual_list)

	lua_push_enum_Box_Flag(L)
	lua_push_enum_Semantic_Color_Token(L)
	lua_push_size_type_integers(L)
	lua_push_size_shorthands(L)
	lua_push_enum_Layout_Direction(L)
	lua_push_enum_Alignment(L)
	lua_push_enum_Position_Floating_Type(L)
	lua_push_enum_Overflow_Mode(L)
	lua_push_enum_Text_Alignment(L)
}

// ---- helpers ----

lua_push_signals :: proc(L: ^lua.State, s: Box_Signals) {
	lua.newtable(L)
	lua.pushboolean(L, b32(s.clicked)); lua.setfield(L, -2, "clicked")
	lua.pushboolean(L, b32(s.double_clicked)); lua.setfield(L, -2, "double_clicked")
	lua.pushboolean(L, b32(s.right_clicked)); lua.setfield(L, -2, "right_clicked")
	lua.pushboolean(L, b32(s.hovering)); lua.setfield(L, -2, "hovering")
	lua.pushboolean(L, b32(s.pressed)); lua.setfield(L, -2, "pressed")
	lua.pushboolean(L, b32(s.released)); lua.setfield(L, -2, "released")
	lua.pushboolean(L, b32(s.dragged_over)); lua.setfield(L, -2, "dragged_over")
	lua.pushboolean(L, b32(s.dropped_on)); lua.setfield(L, -2, "dropped_on")
	lua.pushboolean(L, b32(s.scrolled_up)); lua.setfield(L, -2, "scrolled_up")
	lua.pushboolean(L, b32(s.scrolled_down)); lua.setfield(L, -2, "scrolled_down")
	lua.pushlightuserdata(L, s.box); lua.setfield(L, -2, "box_ptr")
}

// Read helpers: must only be called after getfield/rawgeti has pushed the value.
@(private = "file")
read_int :: proc(L: ^lua.State) -> int {
	if lua.isnumber(L, -1) do return int(lua.L_checkinteger(L, -1))
	return 0
}
@(private = "file")
read_f32 :: proc(L: ^lua.State) -> f32 {
	if lua.isnumber(L, -1) do return f32(lua.L_checknumber(L, -1))
	return 0
}

// Reads a Box_Config from a Lua table at stack index `idx`.
lua_read_box_config :: proc(L: ^lua.State, idx: i32) -> Box_Config {
	config: Box_Config
	if lua.type(L, idx) != .TABLE do return config

	get :: proc(L: ^lua.State, idx: i32, name: cstring) {
		lua.getfield(L, idx, name)
	}

	get(L, idx, "color"); config.color = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "text_color"); config.text_color = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "glow_color"); config.glow_color = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "border_color"); config.border_color = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)

	get(L, idx, "corner_radius"); config.corner_radius = read_int(L); lua.pop(L, 1)
	get(L, idx, "edge_softness"); config.edge_softness = read_int(L); lua.pop(L, 1)
	get(L, idx, "z_index"); config.z_index = read_int(L); lua.pop(L, 1)
	get(L, idx, "font_size"); config.font_size = u32(read_int(L)); lua.pop(L, 1)

	// size: { {type, amount}, {type, amount} }
	lua.getfield(L, idx, "size")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1))
		if lua.type(L, -1) == .TABLE {
			lua.rawgeti(L, -1, lua.Integer(1)); config.size[0].type = Box_Size_Type(read_int(L)); lua.pop(L, 1)
			lua.rawgeti(L, -1, lua.Integer(2)); config.size[0].amount = read_f32(L); lua.pop(L, 1)
		}
		lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2))
		if lua.type(L, -1) == .TABLE {
			lua.rawgeti(L, -1, lua.Integer(1)); config.size[1].type = Box_Size_Type(read_int(L)); lua.pop(L, 1)
			lua.rawgeti(L, -1, lua.Integer(2)); config.size[1].amount = read_f32(L); lua.pop(L, 1)
		}
		lua.pop(L, 1)
	}
	lua.pop(L, 1)

	// max_size / min_size: { w, h }
	lua.getfield(L, idx, "max_size")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1)); config.max_size[0] = read_int(L); lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2)); config.max_size[1] = read_int(L); lua.pop(L, 1)
	}
	lua.pop(L, 1)

	lua.getfield(L, idx, "min_size")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1)); config.min_size[0] = read_int(L); lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2)); config.min_size[1] = read_int(L); lua.pop(L, 1)
	}
	lua.pop(L, 1)

	// padding / margin / border: { left=, top=, right=, bottom= }
	read_ltrb :: proc(L: ^lua.State, idx: i32, name: cstring) -> (l, t, r, b: int) {
		lua.getfield(L, idx, name)
		defer lua.pop(L, 1)
		if lua.type(L, -1) != .TABLE do return
		lua.getfield(L, -1, "left"); l = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "top"); t = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "right"); r = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "bottom"); b = read_int(L); lua.pop(L, 1)
		return
	}
	{l, t, r, b    := read_ltrb(L, idx, "padding"); config.padding = {l, t, r, b}}
	{l, t, r, b   := read_ltrb(L, idx, "margin"); config.margin = {l, t, r, b}}
	{l, t, r, b   := read_ltrb(L, idx, "border"); config.border = {l, t, r, b}}

	get(L, idx, "floating_type"); config.floating_type = Position_Floating_Type(read_int(L)); lua.pop(L, 1)

	lua.getfield(L, idx, "floating_offset")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1)); config.floating_offset[0] = read_f32(L); lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2)); config.floating_offset[1] = read_f32(L); lua.pop(L, 1)
	}
	lua.pop(L, 1)

	get(L, idx, "overflow_x"); config.overflow_x = Overflow_Mode(read_int(L)); lua.pop(L, 1)
	get(L, idx, "overflow_y"); config.overflow_y = Overflow_Mode(read_int(L)); lua.pop(L, 1)

	lua.getfield(L, idx, "text_justify")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1)); config.text_justify[0] = Text_Alignment(read_int(L)); lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2)); config.text_justify[1] = Text_Alignment(read_int(L)); lua.pop(L, 1)
	}
	lua.pop(L, 1)

	return config
}

// Reads a Box_Child_Layout from a Lua table at stack index `idx`.
lua_read_child_layout :: proc(L: ^lua.State, idx: i32) -> Box_Child_Layout {
	layout: Box_Child_Layout
	if lua.type(L, idx) != .TABLE do return layout

	lua.getfield(L, idx, "direction"); layout.direction = Layout_Direction(read_int(L)); lua.pop(L, 1)
	lua.getfield(L, idx, "gap_horizontal"); layout.gap_horizontal = read_int(L); lua.pop(L, 1)
	lua.getfield(L, idx, "gap_vertical"); layout.gap_vertical = read_int(L); lua.pop(L, 1)
	lua.getfield(L, idx, "alignment_horizontal"); layout.alignment_horizontal = Alignment(read_int(L)); lua.pop(L, 1)
	lua.getfield(L, idx, "alignment_vertical"); layout.alignment_vertical = Alignment(read_int(L)); lua.pop(L, 1)

	return layout
}

// ---- helpers ----

lua_read_flags :: proc(L: ^lua.State, idx: i32) -> Box_Flags {
	return transmute(Box_Flags)(u32(lua.L_optinteger(L, idx, 0)))
}

// ---- widget bindings ----

// text_button(label, config, id?, flags?) -> signals
lua_text_button :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	label  := string(lua.L_checkstring(L, 1))
	config := lua_read_box_config(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	flags := lua_read_flags(L, 4)
	lua_push_signals(L, text_button(label, config, id, flags))
	return 1
}

// button(config, id?, flags?) -> signals
lua_button :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	config := lua_read_box_config(L, 1)
	id     := ""
	if lua.isstring(L, 2) do id = string(lua.tostring(L, 2))
	flags := lua_read_flags(L, 3)
	lua_push_signals(L, button(config, id, flags))
	return 1
}

// text(label, config, id?, flags?) -> signals
lua_text :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	label  := string(lua.L_checkstring(L, 1))
	config := lua_read_box_config(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	flags := lua_read_flags(L, 4)
	lua_push_signals(L, text(label, config, id, flags))
	return 1
}

// icon(codepoint, hover_text, config, id?, flags?) -> signals
lua_icon :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	glyph      := rune(lua.L_checkinteger(L, 1))
	hover_text := string(lua.L_checkstring(L, 2))
	config     := lua_read_box_config(L, 3)
	id         := ""
	if lua.isstring(L, 4) do id = string(lua.tostring(L, 4))
	flags := lua_read_flags(L, 5)
	lua_push_signals(L, icon(glyph, hover_text, config, id, flags))
	return 1
}

// icon_button(codepoint, hover_text, config, id?, flags?) -> signals
lua_icon_button :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	glyph      := rune(lua.L_checkinteger(L, 1))
	hover_text := string(lua.L_checkstring(L, 2))
	config     := lua_read_box_config(L, 3)
	id         := ""
	if lua.isstring(L, 4) do id = string(lua.tostring(L, 4))
	flags := lua_read_flags(L, 5)
	lua_push_signals(L, icon_button(glyph, hover_text, config, id, flags))
	return 1
}

// begin_container(config, child_layout, id?, box_flags?, callback?) -> signals, box_ptr
// Without callback: must be followed by end_container(box_ptr).
// With callback:    callback runs immediately, container closed automatically.
lua_begin_container :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	config := lua_read_box_config(L, 1)
	layout := lua_read_child_layout(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	box_flags := lua_read_flags(L, 4)

	if config.max_size == {0, 0} do config.max_size = {app.wx, app.wy}
	box := box_from_cache(box_flags, config, "", id)
	box_open_children(box, layout)
	signals := box_signals(box)

	if lua.isfunction(L, 5) {
		lua.pushvalue(L, 5)
		lua.pcall(L, 0, 0, 0)
		box_regular_close_children(signals)
	}

	lua_push_signals(L, signals)
	lua.pushlightuserdata(L, box)
	return 2
}

// end_container(box_ptr)
// box_ptr is the second return value from begin_container.
lua_end_container :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	box := (^Box)(lua.touserdata(L, 1))
	if box == nil do return 0
	signals: Box_Signals
	signals.box = box
	box_regular_close_children(signals)
	return 0
}

// ---- enum constants as Lua globals ----

lua_push_enum_Semantic_Color_Token :: proc(L: ^lua.State) {
	for v in Semantic_Color_Token {
		name := tprintf("Color_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

// All Box_Size_Type enum variants as Size_Kind_* integers.
// Used when building a [2]Box_Size manually:
// size = { {Size_Kind_Fixed, 200}, {Size_Kind_Fit_Children, 0} }
lua_push_size_type_integers :: proc(L: ^lua.State) {
	for v in Box_Size_Type {
		name := tprintf("Size_Kind_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

// [2]Box_Size shorthand constants matching the Odin compile-time constants.
// These set both axes at once. e.g. size = Size_Fit_Text
lua_push_size_shorthands :: proc(L: ^lua.State) {
	push :: proc(L: ^lua.State, name: cstring, x_type, y_type: Box_Size_Type, amount: f32 = 1) {
		lua.newtable(L)
		lua.newtable(L)
		lua.pushinteger(L, lua.Integer(x_type)); lua.rawseti(L, -2, 1)
		lua.pushnumber(L, lua.Number(amount)); lua.rawseti(L, -2, 2)
		lua.rawseti(L, -2, 1)
		lua.newtable(L)
		lua.pushinteger(L, lua.Integer(y_type)); lua.rawseti(L, -2, 1)
		lua.pushnumber(L, lua.Number(amount)); lua.rawseti(L, -2, 2)
		lua.rawseti(L, -2, 2)
		lua.setglobal(L, name)
	}
	push(L, "Size_Fit_Children", .Fit_Children, .Fit_Children)
	push(L, "Size_Fit_Children_And_Grow", .Fit_Children_And_Grow, .Fit_Children_And_Grow)
	push(L, "Size_Grow", .Grow, .Grow)
	push(L, "Size_Fit_Text", .Fit_Text, .Fit_Text)
	push(L, "Size_Fit_Text_And_Grow", .Fit_Text_And_Grow, .Fit_Text_And_Grow)
}

lua_push_enum_Layout_Direction :: proc(L: ^lua.State) {
	for v in Layout_Direction {
		name := tprintf("Dir_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

lua_push_enum_Alignment :: proc(L: ^lua.State) {
	for v in Alignment {
		name := tprintf("Align_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

lua_push_enum_Position_Floating_Type :: proc(L: ^lua.State) {
	for v in Position_Floating_Type {
		name := tprintf("Float_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

lua_push_enum_Overflow_Mode :: proc(L: ^lua.State) {
	for v in Overflow_Mode {
		name := tprintf("Overflow_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

// Each Flag_* is a power-of-two integer. Combine with bit.bor(Flag_Frosted, Flag_Scrollable).
lua_push_enum_Box_Flag :: proc(L: ^lua.State) {
	for v in Box_Flag {
		name := tprintf("Flag_%v\x00", v)
		lua.pushinteger(L, lua.Integer(1 << uint(v)))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

lua_push_enum_Text_Alignment :: proc(L: ^lua.State) {
	for v in Text_Alignment {
		name := tprintf("TextAlign_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}

// ---- new widget bindings ----

// line(config, id?, flags?) -> signals
lua_line :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	config := lua_read_box_config(L, 1)
	id     := ""
	if lua.isstring(L, 2) do id = string(lua.tostring(L, 2))
	flags := lua_read_flags(L, 3)
	lua_push_signals(L, line(config, id, flags))
	return 1
}

// hover_help_text(label, signals_table)
// signals_table must be a table returned by any widget binding (it has box_ptr).
lua_hover_help_text :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	label := string(lua.L_checkstring(L, 1))
	lua.getfield(L, 2, "box_ptr")
	box := (^Box)(lua.touserdata(L, -1))
	lua.pop(L, 1)
	if box == nil do return 0
	hover_help_text(label, box)
	return 0
}

// vertical_slider(value, min, max, config, id?, flags?) -> new_value, track_signals, grip_signals
lua_vertical_slider :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	value   := f32(lua.L_checknumber(L, 1))
	min_val := f32(lua.L_checknumber(L, 2))
	max_val := f32(lua.L_checknumber(L, 3))
	config  := lua_read_box_config(L, 4)
	id      := ""
	if lua.isstring(L, 5) do id = string(lua.tostring(L, 5))
	flags := lua_read_flags(L, 6)
	sigs  := vertical_slider(config, &value, min_val, max_val, id, flags)
	lua.pushnumber(L, lua.Number(value))
	lua_push_signals(L, sigs.track)
	lua_push_signals(L, sigs.grip)
	return 3
}

// edit_number_box(value, min, max, config, id?, flags?) -> new_value, signals
lua_edit_number_box :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	value   := int(lua.L_checkinteger(L, 1))
	min_val := int(lua.L_checkinteger(L, 2))
	max_val := int(lua.L_checkinteger(L, 3))
	config  := lua_read_box_config(L, 4)
	id      := ""
	if lua.isstring(L, 5) do id = string(lua.tostring(L, 5))
	flags := lua_read_flags(L, 6)
	sigs  := edit_number_box(config, &value, min_val, max_val, id, {}, flags)
	lua.pushinteger(L, lua.Integer(value))
	lua_push_signals(L, sigs)
	return 2
}

// edit_text_box(value, config, id?, flags?) -> new_value, signals
// Uses Generic_One_Line text box type.
lua_edit_text_box :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	lua_str := string(lua.L_checkstring(L, 1))
	config  := lua_read_box_config(L, 2)
	id      := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	flags := lua_read_flags(L, 4)
	// Clone to heap so edit_text_box can delete/replace it.
	local_str := str.clone(lua_str)
	sigs      := edit_text_box(config, .Generic_One_Line, &local_str, id, flags)
	// local_str is either the original clone (box not active) or a new clone (box active).
	// Either way push it to Lua (Lua copies it) then free the Odin allocation.
	lua.pushlstring(L, cast(cstring)raw_data(local_str), uint(len(local_str)))
	delete(local_str)
	lua_push_signals(L, sigs)
	return 2
}

// circular_knob(label, value, min, max, config, id?, knob_size?, logarithmic?, extra_flags?) -> new_value
lua_circular_knob :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	label   := string(lua.L_checkstring(L, 1))
	value   := f64(lua.L_checknumber(L, 2))
	min_val := f64(lua.L_checknumber(L, 3))
	max_val := f64(lua.L_checknumber(L, 4))
	config  := lua_read_box_config(L, 5)
	id      := ""
	if lua.isstring(L, 6) do id = string(lua.tostring(L, 6))
	knob_size := f32(60)
	if lua.isnumber(L, 7) do knob_size = f32(lua.L_checknumber(L, 7))
	logarithmic := false
	if lua.isboolean(L, 8) do logarithmic = bool(lua.toboolean(L, 8))
	extra_flags := lua_read_flags(L, 9)
	circular_knob(label, config, &value, min_val, max_val, logarithmic, id, knob_size, extra_flags)
	lua.pushnumber(L, lua.Number(value))
	return 1
}

// begin_draggable_window(title, child_layout, id?, extra_flags?) -> container_sigs, close_sigs, maximise_sigs, maximised, box_ptr
// Must be followed by end_draggable_window(box_ptr).
// The title bar is fully built inside this call; add your own children between begin/end.
lua_begin_draggable_window :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	title  := string(lua.L_checkstring(L, 1))
	layout := lua_read_child_layout(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	extra_flags := lua_read_flags(L, 4)
	container_sigs, close_sigs, maximise_sigs, maximised := draggable_window_begin(title, layout, id, extra_flags)
	lua_push_signals(L, container_sigs)
	lua_push_signals(L, close_sigs)
	lua_push_signals(L, maximise_sigs)
	lua.pushboolean(L, b32(maximised))
	lua.pushlightuserdata(L, container_sigs.box)
	return 5
}

// end_draggable_window(box_ptr)
// box_ptr is the 5th return value from begin_draggable_window.
lua_end_draggable_window :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	box := (^Box)(lua.touserdata(L, 1))
	if box == nil do return 0
	signals: Box_Signals
	signals.box = box
	box_regular_close_children(signals)
	return 0
}

// begin_virtual_list(config, child_layout, total_items, item_size, id?, flags?) -> state_table
// state_table fields: first_visible, last_visible (0-based), total_items, item_size, direction, box_ptr.
// Must be followed by end_virtual_list(state_table).
// item_size is in pixels (integer). Pass 0 to disable virtualization.
lua_begin_virtual_list :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	config      := lua_read_box_config(L, 1)
	layout      := lua_read_child_layout(L, 2)
	total_items := int(lua.L_checkinteger(L, 3))
	item_size_n := int(lua.L_checkinteger(L, 4))
	id          := ""
	if lua.isstring(L, 5) do id = string(lua.tostring(L, 5))
	flags := lua_read_flags(L, 6)
	state := virtual_list_begin(config, layout, total_items, item_size_n, id, flags)
	lua.newtable(L)
	lua.pushinteger(L, lua.Integer(state.first_visible)); lua.setfield(L, -2, "first_visible")
	lua.pushinteger(L, lua.Integer(state.last_visible)); lua.setfield(L, -2, "last_visible")
	lua.pushinteger(L, lua.Integer(state.total_items)); lua.setfield(L, -2, "total_items")
	lua.pushinteger(L, lua.Integer(state.item_size)); lua.setfield(L, -2, "item_size")
	lua.pushinteger(L, lua.Integer(state.direction)); lua.setfield(L, -2, "direction")
	lua.pushlightuserdata(L, state.container_signals.box); lua.setfield(L, -2, "box_ptr")
	return 1
}

// end_virtual_list(state_table)
// state_table is the table returned by begin_virtual_list.
lua_end_virtual_list :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	if lua.type(L, 1) != .TABLE do return 0

	lua.getfield(L, 1, "last_visible"); last_visible := int(lua.L_checkinteger(L, -1)); lua.pop(L, 1)
	lua.getfield(L, 1, "total_items"); total_items := int(lua.L_checkinteger(L, -1)); lua.pop(L, 1)
	lua.getfield(L, 1, "item_size"); item_size := int(lua.L_checkinteger(L, -1)); lua.pop(L, 1)
	lua.getfield(L, 1, "direction"); direction := Layout_Direction(lua.L_checkinteger(L, -1)); lua.pop(L, 1)
	lua.getfield(L, 1, "box_ptr"); box := (^Box)(lua.touserdata(L, -1)); lua.pop(L, 1)
	if box == nil do return 0

	state: Virtual_List_State
	state.last_visible          = last_visible
	state.total_items           = total_items
	state.item_size             = item_size
	state.direction             = direction
	state.container_signals.box = box
	virtual_list_end(state)
	return 0
}
