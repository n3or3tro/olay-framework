package olay

import "base:runtime"
import lua "vendor:lua/5.1"

// ---- registration ----

lua_register_all :: proc(L: ^lua.State) {
	lua.register(L, "text_button",     lua_text_button)
	lua.register(L, "button",          lua_button)
	lua.register(L, "text",            lua_text)
	lua.register(L, "icon",            lua_icon)
	lua.register(L, "icon_button",     lua_icon_button)
	lua.register(L, "begin_container", lua_begin_container)
	lua.register(L, "end_container",   lua_end_container)

	lua_push_enum_Semantic_Color_Token(L)
	lua_push_enum_Box_Size_Type(L)
	lua_push_enum_Layout_Direction(L)
	lua_push_enum_Alignment(L)
	lua_push_enum_Position_Floating_Type(L)
	lua_push_enum_Overflow_Mode(L)
	lua_push_enum_Text_Alignment(L)
}

// ---- helpers ----

lua_push_signals :: proc(L: ^lua.State, s: Box_Signals) {
	lua.newtable(L)
	lua.pushboolean(L, b32(s.clicked));        lua.setfield(L, -2, "clicked")
	lua.pushboolean(L, b32(s.double_clicked)); lua.setfield(L, -2, "double_clicked")
	lua.pushboolean(L, b32(s.right_clicked));  lua.setfield(L, -2, "right_clicked")
	lua.pushboolean(L, b32(s.hovering));       lua.setfield(L, -2, "hovering")
	lua.pushboolean(L, b32(s.pressed));        lua.setfield(L, -2, "pressed")
	lua.pushboolean(L, b32(s.released));       lua.setfield(L, -2, "released")
	lua.pushboolean(L, b32(s.dragged_over));   lua.setfield(L, -2, "dragged_over")
	lua.pushboolean(L, b32(s.dropped_on));     lua.setfield(L, -2, "dropped_on")
	lua.pushboolean(L, b32(s.scrolled_up));    lua.setfield(L, -2, "scrolled_up")
	lua.pushboolean(L, b32(s.scrolled_down));  lua.setfield(L, -2, "scrolled_down")
}

// Read helpers: must only be called after getfield/rawgeti has pushed the value.
@(private="file")
read_int :: proc(L: ^lua.State) -> int {
	if lua.isnumber(L, -1) do return int(lua.L_checkinteger(L, -1))
	return 0
}
@(private="file")
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

	get(L, idx, "color");        config.color        = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "text_color");   config.text_color   = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "glow_color");   config.glow_color   = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)
	get(L, idx, "border_color"); config.border_color = Semantic_Color_Token(read_int(L)); lua.pop(L, 1)

	get(L, idx, "corner_radius"); config.corner_radius = read_int(L); lua.pop(L, 1)
	get(L, idx, "edge_softness"); config.edge_softness = read_int(L); lua.pop(L, 1)
	get(L, idx, "z_index");       config.z_index       = read_int(L); lua.pop(L, 1)
	get(L, idx, "font_size");     config.font_size     = u32(read_int(L)); lua.pop(L, 1)

	// size: { {type, amount}, {type, amount} }
	lua.getfield(L, idx, "size")
	if lua.type(L, -1) == .TABLE {
		lua.rawgeti(L, -1, lua.Integer(1))
		if lua.type(L, -1) == .TABLE {
			lua.rawgeti(L, -1, lua.Integer(1)); config.size[0].type   = Box_Size_Type(read_int(L)); lua.pop(L, 1)
			lua.rawgeti(L, -1, lua.Integer(2)); config.size[0].amount = read_f32(L);                lua.pop(L, 1)
		}
		lua.pop(L, 1)
		lua.rawgeti(L, -1, lua.Integer(2))
		if lua.type(L, -1) == .TABLE {
			lua.rawgeti(L, -1, lua.Integer(1)); config.size[1].type   = Box_Size_Type(read_int(L)); lua.pop(L, 1)
			lua.rawgeti(L, -1, lua.Integer(2)); config.size[1].amount = read_f32(L);                lua.pop(L, 1)
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
		lua.getfield(L, -1, "left");   l = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "top");    t = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "right");  r = read_int(L); lua.pop(L, 1)
		lua.getfield(L, -1, "bottom"); b = read_int(L); lua.pop(L, 1)
		return
	}
	{l, t, r, b := read_ltrb(L, idx, "padding"); config.padding = {l, t, r, b}}
	{l, t, r, b := read_ltrb(L, idx, "margin");  config.margin  = {l, t, r, b}}
	{l, t, r, b := read_ltrb(L, idx, "border");  config.border  = {l, t, r, b}}

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

	lua.getfield(L, idx, "direction");            layout.direction            = Layout_Direction(read_int(L)); lua.pop(L, 1)
	lua.getfield(L, idx, "gap_horizontal");       layout.gap_horizontal       = read_int(L);                  lua.pop(L, 1)
	lua.getfield(L, idx, "gap_vertical");         layout.gap_vertical         = read_int(L);                  lua.pop(L, 1)
	lua.getfield(L, idx, "alignment_horizontal"); layout.alignment_horizontal = Alignment(read_int(L));       lua.pop(L, 1)
	lua.getfield(L, idx, "alignment_vertical");   layout.alignment_vertical   = Alignment(read_int(L));       lua.pop(L, 1)

	return layout
}

// ---- widget bindings ----

// text_button(label, config, id?) -> signals
lua_text_button :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	label  := string(lua.L_checkstring(L, 1))
	config := lua_read_box_config(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	lua_push_signals(L, text_button(label, config, id))
	return 1
}

// button(config, id?) -> signals
lua_button :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	config := lua_read_box_config(L, 1)
	id     := ""
	if lua.isstring(L, 2) do id = string(lua.tostring(L, 2))
	lua_push_signals(L, button(config, id))
	return 1
}

// text(label, config, id?) -> signals
lua_text :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	label  := string(lua.L_checkstring(L, 1))
	config := lua_read_box_config(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))
	lua_push_signals(L, text(label, config, id))
	return 1
}

// icon(codepoint, hover_text, config, id?) -> signals
lua_icon :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	glyph      := rune(lua.L_checkinteger(L, 1))
	hover_text := string(lua.L_checkstring(L, 2))
	config     := lua_read_box_config(L, 3)
	id         := ""
	if lua.isstring(L, 4) do id = string(lua.tostring(L, 4))
	lua_push_signals(L, icon(glyph, hover_text, config, id))
	return 1
}

// icon_button(codepoint, hover_text, config, id?) -> signals
lua_icon_button :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	glyph      := rune(lua.L_checkinteger(L, 1))
	hover_text := string(lua.L_checkstring(L, 2))
	config     := lua_read_box_config(L, 3)
	id         := ""
	if lua.isstring(L, 4) do id = string(lua.tostring(L, 4))
	lua_push_signals(L, icon_button(glyph, hover_text, config, id))
	return 1
}

// begin_container(config, child_layout, id?, callback?) -> signals
// Without callback: must be followed by end_container(signals).
// With callback:    callback runs immediately, container closed automatically.
lua_begin_container :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
	config := lua_read_box_config(L, 1)
	layout := lua_read_child_layout(L, 2)
	id     := ""
	if lua.isstring(L, 3) do id = string(lua.tostring(L, 3))

	if config.max_size == {0, 0} do config.max_size = {app.wx, app.wy}
	box     := box_from_cache({}, config, "", id)
	box_open_children(box, layout)
	signals := box_signals(box)

	if lua.isfunction(L, 4) {
		lua.pushvalue(L, 4)
		lua.pcall(L, 0, 0, 0)
		box_regular_close_children(signals)
	}

	lua_push_signals(L, signals)
	// Push box pointer as lightuserdata so end_container can close it correctly.
	lua.pushlightuserdata(L, box)
	return 2
}

// end_container(box_ptr)
// box_ptr is the second return value from begin_container.
lua_end_container :: proc "c" (L: ^lua.State) -> i32 {
	context = runtime.default_context()
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

lua_push_enum_Box_Size_Type :: proc(L: ^lua.State) {
	for v in Box_Size_Type {
		name := tprintf("Size_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
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

lua_push_enum_Text_Alignment :: proc(L: ^lua.State) {
	for v in Text_Alignment {
		name := tprintf("TextAlign_%v\x00", v)
		lua.pushinteger(L, lua.Integer(v))
		lua.setglobal(L, cstring(raw_data(transmute([]u8)name)))
	}
}
