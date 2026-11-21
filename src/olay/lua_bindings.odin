package olay
import "core:strings"
import lua "vendor:lua/5.1"
lua_dyn_string_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {lua.pushnil(L); return 1}
	lua.pushlstring(L, cstring(raw_data(arr^[idx])), uint(len(arr^[idx])))
	return 1
}
lua_dyn_string_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {return 0}
	arr^[idx] = strings.clone(string(lua.tostring(L, 3)))
	return 0
}
lua_dyn_string_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(arr^)))
	return 1
}
lua_map_string_f64_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m       := (^^map[string]f64)(lua.touserdata(L, 1))^
	key     := strings.clone(string(lua.tostring(L, 2)))
	val, ok := m^[key]
	if !ok {lua.pushnil(L); return 1}
	lua.pushnumber(L, lua.Number(val))
	return 1
}
lua_map_string_f64_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m   := (^^map[string]f64)(lua.touserdata(L, 1))^
	key := strings.clone(string(lua.tostring(L, 2)))
	m^[key] = f64(lua.L_checknumber(L, 3))
	return 0
}
lua_map_string_f64_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m := (^^map[string]f64)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(m^)))
	return 1
}
lua_farr_4_int_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[4]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {lua.pushnil(L); return 1}
	lua.pushinteger(L, lua.Integer(arr^[idx]))
	return 1
}
lua_farr_4_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[4]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {return 0}
	arr^[idx] = int(lua.L_checkinteger(L, 3))
	return 0
}
lua_farr_4_int_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[4]int)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(arr^)))
	return 1
}
lua_map_rawptr_string_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m       := (^^map[rawptr]string)(lua.touserdata(L, 1))^
	key     := (rawptr)(lua.touserdata(L, 2))
	val, ok := m^[key]
	if !ok {lua.pushnil(L); return 1}
	lua.pushlstring(L, cstring(raw_data(val)), uint(len(val)))
	return 1
}
lua_map_rawptr_string_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m   := (^^map[rawptr]string)(lua.touserdata(L, 1))^
	key := (rawptr)(lua.touserdata(L, 2))
	m^[key] = strings.clone(string(lua.tostring(L, 3)))
	return 0
}
lua_map_rawptr_string_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m := (^^map[rawptr]string)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(m^)))
	return 1
}
lua_map_string_int_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m       := (^^map[string]int)(lua.touserdata(L, 1))^
	key     := strings.clone(string(lua.tostring(L, 2)))
	val, ok := m^[key]
	if !ok {lua.pushnil(L); return 1}
	lua.pushinteger(L, lua.Integer(val))
	return 1
}
lua_map_string_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m   := (^^map[string]int)(lua.touserdata(L, 1))^
	key := strings.clone(string(lua.tostring(L, 2)))
	m^[key] = int(lua.L_checkinteger(L, 3))
	return 0
}
lua_map_string_int_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m := (^^map[string]int)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(m^)))
	return 1
}
lua_dyn_int_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {lua.pushnil(L); return 1}
	lua.pushinteger(L, lua.Integer(arr^[idx]))
	return 1
}
lua_dyn_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {return 0}
	arr^[idx] = int(lua.L_checkinteger(L, 3))
	return 0
}
lua_dyn_int_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(arr^)))
	return 1
}
lua_farr_24_int_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[24]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {lua.pushnil(L); return 1}
	lua.pushinteger(L, lua.Integer(arr^[idx]))
	return 1
}
lua_farr_24_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[24]int)(lua.touserdata(L, 1))^
	idx := int(lua.L_checkinteger(L, 2)) - 1
	if idx < 0 || idx >= len(arr^) {return 0}
	arr^[idx] = int(lua.L_checkinteger(L, 3))
	return 0
}
lua_farr_24_int_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	arr := (^^[24]int)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(arr^)))
	return 1
}
lua_map_f64_int_ptr_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m       := (^^map[f64]^int)(lua.touserdata(L, 1))^
	key     := f64(lua.L_checknumber(L, 2))
	val, ok := m^[key]
	if !ok {lua.pushnil(L); return 1}
	lua.pushlightuserdata(L, val)
	return 1
}
lua_map_f64_int_ptr_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m   := (^^map[f64]^int)(lua.touserdata(L, 1))^
	key := f64(lua.L_checknumber(L, 2))
	m^[key] = (^int)(lua.touserdata(L, 3))
	return 0
}
lua_map_f64_int_ptr_len :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	m := (^^map[f64]^int)(lua.touserdata(L, 1))^
	lua.pushinteger(L, lua.Integer(len(m^)))
	return 1
}
lua_Bogus_State_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	s   := (^^Bogus_State)(lua.touserdata(L, 1))^
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "val_name":
		lua.pushlstring(L, cstring(raw_data(s.val_name)), uint(len(s.val_name)))
	case "val_float":
		lua.pushnumber(L, lua.Number(s.val_float))
	case "val_int":
		lua.pushinteger(L, lua.Integer(s.val_int))
	case "val_fixed_arr":
		(^^[24]int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.val_fixed_arr
		lua.L_getmetatable(L, "farr_24_int")
		lua.setmetatable(L, -2)
	case "val_dict":
		(^^map[string]int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.val_dict
		lua.L_getmetatable(L, "map_string_int")
		lua.setmetatable(L, -2)
	case "val_dict2":
		(^^map[f64]^int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.val_dict2
		lua.L_getmetatable(L, "map_f64_int_ptr")
		lua.setmetatable(L, -2)
	case "val_dyn_arr":
		(^^[dynamic]string)(lua.newuserdata(L, size_of(rawptr)))^ = &s.val_dyn_arr
		lua.L_getmetatable(L, "dyn_string")
		lua.setmetatable(L, -2)
	case "val_struct":
		(^^Internal_Struct)(lua.newuserdata(L, size_of(rawptr)))^ = &s.val_struct
		lua.L_getmetatable(L, "Internal_Struct")
		lua.setmetatable(L, -2)
	case:
		lua.pushnil(L)
	}
	return 1
}
lua_Bogus_State_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	s   := (^^Bogus_State)(lua.touserdata(L, 1))^
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "val_name":
		s.val_name = strings.clone(string(lua.tostring(L, 3)))
	case "val_float":
		s.val_float = f32(lua.L_checknumber(L, 3))
	case "val_int":
		s.val_int = int(lua.L_checkinteger(L, 3))
	case "val_fixed_arr":
		for _i in 0 ..< len(s.val_fixed_arr) {
			lua.rawgeti(L, 3, lua.Integer(_i + 1))
			s.val_fixed_arr[_i] = int(lua.L_checkinteger(L, -1))
			lua.pop(L, 1)
		}
	case "val_dict":
		clear(&s.val_dict)
		lua.pushnil(L)
		for lua.next(L, 3) != 0 {
			s.val_dict[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
			lua.pop(L, 1)
		}
	case "val_dict2":
		clear(&s.val_dict2)
		lua.pushnil(L)
		for lua.next(L, 3) != 0 {
			s.val_dict2[f64(lua.L_checknumber(L, -2))] = (^int)(lua.touserdata(L, -1))
			lua.pop(L, 1)
		}
	case "val_dyn_arr":
		clear(&s.val_dyn_arr)
		for _i in 0 ..< int(lua.objlen(L, 3)) {
			lua.rawgeti(L, 3, lua.Integer(_i + 1))
			append(&s.val_dyn_arr, strings.clone(string(lua.tostring(L, -1))))
			lua.pop(L, 1)
		}
	case "val_struct":
	}
	return 0
}
lua_Internal_Struct_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	s   := (^^Internal_Struct)(lua.touserdata(L, 1))^
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "field1":
		lua.pushinteger(L, lua.Integer(s.field1))
	case "field2":
		lua.pushinteger(L, lua.Integer(s.field2))
	case:
		lua.pushnil(L)
	}
	return 1
}
lua_Internal_Struct_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	s   := (^^Internal_Struct)(lua.touserdata(L, 1))^
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "field1":
		s.field1 = int(lua.L_checkinteger(L, 3))
	case "field2":
		s.field2 = int(lua.L_checkinteger(L, 3))
	}
	return 0
}
register_metatables :: proc(L: ^lua.State) {
	lua.L_newmetatable(L, "dyn_string")
	lua.pushcfunction(L, lua_dyn_string_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_dyn_string_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_dyn_string_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "map_string_f64")
	lua.pushcfunction(L, lua_map_string_f64_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_map_string_f64_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_map_string_f64_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "farr_4_int")
	lua.pushcfunction(L, lua_farr_4_int_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_farr_4_int_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_farr_4_int_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "map_rawptr_string")
	lua.pushcfunction(L, lua_map_rawptr_string_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_map_rawptr_string_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_map_rawptr_string_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "map_string_int")
	lua.pushcfunction(L, lua_map_string_int_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_map_string_int_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_map_string_int_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "dyn_int")
	lua.pushcfunction(L, lua_dyn_int_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_dyn_int_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_dyn_int_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "farr_24_int")
	lua.pushcfunction(L, lua_farr_24_int_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_farr_24_int_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_farr_24_int_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "map_f64_int_ptr")
	lua.pushcfunction(L, lua_map_f64_int_ptr_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_map_f64_int_ptr_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pushcfunction(L, lua_map_f64_int_ptr_len)
	lua.setfield(L, -2, "__len")
	lua.pop(L, 1)

	lua.L_newmetatable(L, "Internal_Struct")
	lua.pushcfunction(L, lua_Internal_Struct_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_Internal_Struct_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pop(L, 1) // pop the metatable off the stack.

	lua.L_newmetatable(L, "Bogus_State")
	lua.pushcfunction(L, lua_Bogus_State_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_Bogus_State_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.pop(L, 1) // pop the metatable off the stack.

}
lua_func_b :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	a        := strings.clone(string(lua.tostring(L, 1)))
	b        := strings.clone(string(lua.tostring(L, 2)))
	_result0 := func_b(a, b)
	lua.pushinteger(L, lua.Integer(_result0))
	return 1
}
lua_func_c :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	a: map[string]int
	clear(&a)
	lua.pushnil(L)
	for lua.next(L, 1) != 0 {
		a[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
		lua.pop(L, 1)
	}
	b: map[rawptr]string
	clear(&b)
	lua.pushnil(L)
	for lua.next(L, 2) != 0 {
		b[(rawptr)(lua.touserdata(L, -2))] = strings.clone(string(lua.tostring(L, -1)))
		lua.pop(L, 1)
	}
	_result0 := func_c(a, b)
	lua.newtable(L)
	for _k, _v in _result0 {
		lua.pushlstring(L, cstring(raw_data(_k)), uint(len(_k)))
		lua.pushnumber(L, lua.Number(_v))
		lua.rawset(L, -3)
	}
	return 1
}
lua_func_a :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	a := int(lua.L_checkinteger(L, 1))
	b := strings.clone(string(lua.tostring(L, 2)))
	c: [dynamic]int
	clear(&c)
	for _i in 0 ..< int(lua.objlen(L, 3)) {
		lua.rawgeti(L, 3, lua.Integer(_i + 1))
		append(&c, int(lua.L_checkinteger(L, -1)))
		lua.pop(L, 1)
	}
	_result0 := func_a(a, b, c)
	lua.pushnumber(L, lua.Number(_result0))
	return 1
}
lua_register_all :: proc(L: ^lua.State) {
	lua.register(L, "func_b", lua_func_b)
	lua.register(L, "func_c", lua_func_c)
	lua.register(L, "func_a", lua_func_a)
}
lua_globals_index :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "global_data_6":
		lua.pushinteger(L, lua.Integer(global_data_6))
	case "global_data_1":
		lua.pushinteger(L, lua.Integer(global_data_1))
	case "global_data_7":
		(^^[4]int)(lua.newuserdata(L, size_of(rawptr)))^ = &global_data_7
		lua.L_getmetatable(L, "farr_4_int")
		lua.setmetatable(L, -2)
	case "global_data_2":
		lua.pushlstring(L, cstring(raw_data(global_data_2)), uint(len(global_data_2)))
	case "global_data_3":
		lua.pushlstring(L, cstring(raw_data(global_data_3)), uint(len(global_data_3)))
	case "global_data_4":
		lua.pushnumber(L, lua.Number(global_data_4))
	case "global_data_5":
		lua.pushinteger(L, lua.Integer(global_data_5))
	case:
		lua.pushnil(L)
	}
	return 1
}
lua_globals_newindex :: proc "c" (L: ^lua.State) -> i32 {
	context = app.lua_odin_context
	key := string(lua.L_checkstring(L, 2))
	switch key {
	case "global_data_6":
		global_data_6 = int(lua.L_checkinteger(L, 3))
	case "global_data_1":
		global_data_1 = int(lua.L_checkinteger(L, 3))
	case "global_data_7":
		for _i in 0 ..< len(global_data_7) {
			lua.rawgeti(L, 3, lua.Integer(_i + 1))
			global_data_7[_i] = int(lua.L_checkinteger(L, -1))
			lua.pop(L, 1)
		}
	case "global_data_2":
		global_data_2 = strings.clone(string(lua.tostring(L, 3)))
	case "global_data_3":
		global_data_3 = strings.clone(string(lua.tostring(L, 3)))
	case "global_data_4":
		global_data_4 = f64(lua.L_checknumber(L, 3))
	case "global_data_5":
		global_data_5 = int(lua.L_checkinteger(L, 3))
	}
	return 0
}
register_globals :: proc(L: ^lua.State) {
	lua.pushvalue(L, lua.GLOBALSINDEX)
	lua.newtable(L)
	lua.pushcfunction(L, lua_globals_index)
	lua.setfield(L, -2, "__index")
	lua.pushcfunction(L, lua_globals_newindex)
	lua.setfield(L, -2, "__newindex")
	lua.setmetatable(L, -2)
	lua.pop(L, 1)
}
