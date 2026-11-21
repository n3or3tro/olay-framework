package lua_fixture
import lua "vendor:lua/5.1"
import "core:strings"
lua_dyn_int_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }
lua.pushinteger(L, lua.Integer(arr^[idx]))
return 1
}
lua_dyn_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { return 0 }
arr^[idx] = int(lua.L_checkinteger(L, 3))
return 0
}
lua_dyn_int_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]int)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(arr^)))
return 1
}
lua_map_string_string_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]string)(lua.touserdata(L, 1))^
key := strings.clone(string(lua.tostring(L, 2)))
val, ok := m^[key]
if !ok { lua.pushnil(L); return 1 }
lua.pushlstring(L, cstring(raw_data(val)), uint(len(val)))
return 1
}
lua_map_string_string_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]string)(lua.touserdata(L, 1))^
key := strings.clone(string(lua.tostring(L, 2)))
m^[key] = strings.clone(string(lua.tostring(L, 3)))
return 0
}
lua_map_string_string_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]string)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(m^)))
return 1
}
lua_farr_4_int_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[4]int)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }
lua.pushinteger(L, lua.Integer(arr^[idx]))
return 1
}
lua_farr_4_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[4]int)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { return 0 }
arr^[idx] = int(lua.L_checkinteger(L, 3))
return 0
}
lua_farr_4_int_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[4]int)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(arr^)))
return 1
}
lua_map_string_int_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]int)(lua.touserdata(L, 1))^
key := strings.clone(string(lua.tostring(L, 2)))
val, ok := m^[key]
if !ok { lua.pushnil(L); return 1 }
lua.pushinteger(L, lua.Integer(val))
return 1
}
lua_map_string_int_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]int)(lua.touserdata(L, 1))^
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
lua_map_string_f64_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]f64)(lua.touserdata(L, 1))^
key := strings.clone(string(lua.tostring(L, 2)))
val, ok := m^[key]
if !ok { lua.pushnil(L); return 1 }
lua.pushnumber(L, lua.Number(val))
return 1
}
lua_map_string_f64_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m := (^^map[string]f64)(lua.touserdata(L, 1))^
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
lua_farr_8_f32_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[8]f32)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }
lua.pushnumber(L, lua.Number(arr^[idx]))
return 1
}
lua_farr_8_f32_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[8]f32)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { return 0 }
arr^[idx] = f32(lua.L_checknumber(L, 3))
return 0
}
lua_farr_8_f32_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[8]f32)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(arr^)))
return 1
}
lua_dyn_f64_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]f64)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }
lua.pushnumber(L, lua.Number(arr^[idx]))
return 1
}
lua_dyn_f64_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]f64)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { return 0 }
arr^[idx] = f64(lua.L_checknumber(L, 3))
return 0
}
lua_dyn_f64_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]f64)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(arr^)))
return 1
}
lua_dyn_string_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }
lua.pushlstring(L, cstring(raw_data(arr^[idx])), uint(len(arr^[idx])))
return 1
}
lua_dyn_string_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
idx := int(lua.L_checkinteger(L, 2)) - 1
if idx < 0 || idx >= len(arr^) { return 0 }
arr^[idx] = strings.clone(string(lua.tostring(L, 3)))
return 0
}
lua_dyn_string_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr := (^^[dynamic]string)(lua.touserdata(L, 1))^
lua.pushinteger(L, lua.Integer(len(arr^)))
return 1
}
lua_Fixture_Maps_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Maps)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_map_str_int":
(^^map[string]int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_map_str_int
lua.L_getmetatable(L, "map_string_int")
lua.setmetatable(L, -2)
case "f_map_str_f64":
(^^map[string]f64)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_map_str_f64
lua.L_getmetatable(L, "map_string_f64")
lua.setmetatable(L, -2)
case "f_map_str_str":
(^^map[string]string)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_map_str_str
lua.L_getmetatable(L, "map_string_string")
lua.setmetatable(L, -2)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Maps_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Maps)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_map_str_int":
clear(&s.f_map_str_int)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
s.f_map_str_int[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "f_map_str_f64":
clear(&s.f_map_str_f64)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
s.f_map_str_f64[strings.clone(string(lua.tostring(L, -2)))] = f64(lua.L_checknumber(L, -1))
lua.pop(L, 1)
}
case "f_map_str_str":
clear(&s.f_map_str_str)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
s.f_map_str_str[strings.clone(string(lua.tostring(L, -2)))] = strings.clone(string(lua.tostring(L, -1)))
lua.pop(L, 1)
}
}
return 0
}
lua_Fixture_Nested_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Nested)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "simple":
(^^Fixture_Simple)(lua.newuserdata(L, size_of(rawptr)))^ = &s.simple
lua.L_getmetatable(L, "Fixture_Simple")
lua.setmetatable(L, -2)
case "arrays":
(^^Fixture_Arrays)(lua.newuserdata(L, size_of(rawptr)))^ = &s.arrays
lua.L_getmetatable(L, "Fixture_Arrays")
lua.setmetatable(L, -2)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Nested_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Nested)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "simple":
case "arrays":
}
return 0
}
lua_Fixture_Simple_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Simple)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_int":
lua.pushinteger(L, lua.Integer(s.f_int))
case "f_i32":
lua.pushinteger(L, lua.Integer(s.f_i32))
case "f_i64":
lua.pushinteger(L, lua.Integer(s.f_i64))
case "f_u8":
lua.pushinteger(L, lua.Integer(s.f_u8))
case "f_u16":
lua.pushinteger(L, lua.Integer(s.f_u16))
case "f_u32":
lua.pushinteger(L, lua.Integer(s.f_u32))
case "f_u64":
lua.pushinteger(L, lua.Integer(s.f_u64))
case "f_f32":
lua.pushnumber(L, lua.Number(s.f_f32))
case "f_f64":
lua.pushnumber(L, lua.Number(s.f_f64))
case "f_bool":
lua.pushboolean(L, b32(s.f_bool))
case "f_b8":
lua.pushboolean(L, b32(s.f_b8))
case "f_b32":
lua.pushboolean(L, b32(s.f_b32))
case "f_string":
lua.pushlstring(L, cstring(raw_data(s.f_string)), uint(len(s.f_string)))
case "f_rawptr":
lua.pushlightuserdata(L, s.f_rawptr)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Simple_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Simple)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_int":
s.f_int = int(lua.L_checkinteger(L, 3))
case "f_i32":
s.f_i32 = i32(lua.L_checkinteger(L, 3))
case "f_i64":
s.f_i64 = i64(lua.L_checkinteger(L, 3))
case "f_u8":
s.f_u8 = u8(lua.L_checkinteger(L, 3))
case "f_u16":
s.f_u16 = u16(lua.L_checkinteger(L, 3))
case "f_u32":
s.f_u32 = u32(lua.L_checkinteger(L, 3))
case "f_u64":
s.f_u64 = u64(lua.L_checkinteger(L, 3))
case "f_f32":
s.f_f32 = f32(lua.L_checknumber(L, 3))
case "f_f64":
s.f_f64 = f64(lua.L_checknumber(L, 3))
case "f_bool":
s.f_bool = bool(lua.toboolean(L, 3))
case "f_b8":
s.f_b8 = b8(lua.toboolean(L, 3))
case "f_b32":
s.f_b32 = b32(lua.toboolean(L, 3))
case "f_string":
s.f_string = strings.clone(string(lua.tostring(L, 3)))
case "f_rawptr":
s.f_rawptr = (rawptr)(lua.touserdata(L, 3))
}
return 0
}
lua_Fixture_Arrays_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Arrays)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_fixed_int":
(^^[4]int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_fixed_int
lua.L_getmetatable(L, "farr_4_int")
lua.setmetatable(L, -2)
case "f_fixed_f32":
(^^[8]f32)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_fixed_f32
lua.L_getmetatable(L, "farr_8_f32")
lua.setmetatable(L, -2)
case "f_dyn_int":
(^^[dynamic]int)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_dyn_int
lua.L_getmetatable(L, "dyn_int")
lua.setmetatable(L, -2)
case "f_dyn_string":
(^^[dynamic]string)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_dyn_string
lua.L_getmetatable(L, "dyn_string")
lua.setmetatable(L, -2)
case "f_dyn_f64":
(^^[dynamic]f64)(lua.newuserdata(L, size_of(rawptr)))^ = &s.f_dyn_f64
lua.L_getmetatable(L, "dyn_f64")
lua.setmetatable(L, -2)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Arrays_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Arrays)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_fixed_int":
for _i in 0..<len(s.f_fixed_int) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
s.f_fixed_int[_i] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "f_fixed_f32":
for _i in 0..<len(s.f_fixed_f32) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
s.f_fixed_f32[_i] = f32(lua.L_checknumber(L, -1))
lua.pop(L, 1)
}
case "f_dyn_int":
clear(&s.f_dyn_int)
for _i in 0..<int(lua.objlen(L, 3)) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
append(&s.f_dyn_int, int(lua.L_checkinteger(L, -1)))
lua.pop(L, 1)
}
case "f_dyn_string":
clear(&s.f_dyn_string)
for _i in 0..<int(lua.objlen(L, 3)) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
append(&s.f_dyn_string, strings.clone(string(lua.tostring(L, -1))))
lua.pop(L, 1)
}
case "f_dyn_f64":
clear(&s.f_dyn_f64)
for _i in 0..<int(lua.objlen(L, 3)) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
append(&s.f_dyn_f64, f64(lua.L_checknumber(L, -1)))
lua.pop(L, 1)
}
}
return 0
}
lua_Fixture_Pointer_Fields_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Pointer_Fields)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_ptr":
lua.pushlightuserdata(L, s.f_ptr)
case "f_rawptr":
lua.pushlightuserdata(L, s.f_rawptr)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Pointer_Fields_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Pointer_Fields)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "f_ptr":
s.f_ptr = (^int)(lua.touserdata(L, 3))
case "f_rawptr":
s.f_rawptr = (rawptr)(lua.touserdata(L, 3))
}
return 0
}
lua_Fixture_Deep_Nest_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Deep_Nest)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "nested":
(^^Fixture_Nested)(lua.newuserdata(L, size_of(rawptr)))^ = &s.nested
lua.L_getmetatable(L, "Fixture_Nested")
lua.setmetatable(L, -2)
case:
lua.pushnil(L)
}
return 1
}
lua_Fixture_Deep_Nest_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^^Fixture_Deep_Nest)(lua.touserdata(L, 1))^
key := string(lua.L_checkstring(L, 2))
switch key {
case "nested":
}
return 0
}
register_metatables :: proc(L: ^lua.State) {
lua.L_newmetatable(L, "dyn_int")
lua.pushcfunction(L, lua_dyn_int_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_dyn_int_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_dyn_int_len)
lua.setfield(L, -2, "__len")
lua.pop(L, 1)

lua.L_newmetatable(L, "map_string_string")
lua.pushcfunction(L, lua_map_string_string_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_map_string_string_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_map_string_string_len)
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

lua.L_newmetatable(L, "map_string_int")
lua.pushcfunction(L, lua_map_string_int_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_map_string_int_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_map_string_int_len)
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

lua.L_newmetatable(L, "farr_8_f32")
lua.pushcfunction(L, lua_farr_8_f32_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_farr_8_f32_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_farr_8_f32_len)
lua.setfield(L, -2, "__len")
lua.pop(L, 1)

lua.L_newmetatable(L, "dyn_f64")
lua.pushcfunction(L, lua_dyn_f64_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_dyn_f64_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_dyn_f64_len)
lua.setfield(L, -2, "__len")
lua.pop(L, 1)

lua.L_newmetatable(L, "dyn_string")
lua.pushcfunction(L, lua_dyn_string_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_dyn_string_newindex)
lua.setfield(L, -2, "__newindex")
lua.pushcfunction(L, lua_dyn_string_len)
lua.setfield(L, -2, "__len")
lua.pop(L, 1)

lua.L_newmetatable(L, "Fixture_Maps")
lua.pushcfunction(L, lua_Fixture_Maps_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Maps_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

lua.L_newmetatable(L, "Fixture_Simple")
lua.pushcfunction(L, lua_Fixture_Simple_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Simple_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

lua.L_newmetatable(L, "Fixture_Arrays")
lua.pushcfunction(L, lua_Fixture_Arrays_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Arrays_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

lua.L_newmetatable(L, "Fixture_Nested")
lua.pushcfunction(L, lua_Fixture_Nested_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Nested_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

lua.L_newmetatable(L, "Fixture_Pointer_Fields")
lua.pushcfunction(L, lua_Fixture_Pointer_Fields_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Pointer_Fields_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

lua.L_newmetatable(L, "Fixture_Deep_Nest")
lua.pushcfunction(L, lua_Fixture_Deep_Nest_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Fixture_Deep_Nest_newindex)
lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.

}
lua_fixture_arr_len :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
arr: [dynamic]int
clear(&arr)
for _i in 0..<int(lua.objlen(L, 1)) {
lua.rawgeti(L, 1, lua.Integer(_i + 1))
append(&arr, int(lua.L_checkinteger(L, -1)))
lua.pop(L, 1)
}
_result0 := fixture_arr_len(arr)
lua.pushinteger(L, lua.Integer(_result0))
return 1
}
lua_fixture_no_args :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
fixture_no_args()
return 0
}
lua_fixture_multi_ret :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
x := int(lua.L_checkinteger(L, 1))
_result0, _result1 := fixture_multi_ret(x)
lua.pushinteger(L, lua.Integer(_result0))
lua.pushinteger(L, lua.Integer(_result1))
return 2
}
lua_fixture_map_passthrough :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
m: map[string]int
clear(&m)
lua.pushnil(L)
for lua.next(L, 1) != 0 {
m[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
_result0 := fixture_map_passthrough(m)
lua.newtable(L)
for _k, _v in _result0 {
lua.pushlstring(L, cstring(raw_data(_k)), uint(len(_k)))
lua.pushinteger(L, lua.Integer(_v))
lua.rawset(L, -3)
}
return 1
}
lua_fixture_concat :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
a := strings.clone(string(lua.tostring(L, 1)))
b := strings.clone(string(lua.tostring(L, 2)))
_result0 := fixture_concat(a, b)
lua.pushlstring(L, cstring(raw_data(_result0)), uint(len(_result0)))
return 1
}
lua_fixture_add :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
a := int(lua.L_checkinteger(L, 1))
b := int(lua.L_checkinteger(L, 2))
_result0 := fixture_add(a, b)
lua.pushinteger(L, lua.Integer(_result0))
return 1
}
register_procs :: proc(L: ^lua.State) {
lua.register(L, "fixture_arr_len", lua_fixture_arr_len)
lua.register(L, "fixture_no_args", lua_fixture_no_args)
lua.register(L, "fixture_multi_ret", lua_fixture_multi_ret)
lua.register(L, "fixture_map_passthrough", lua_fixture_map_passthrough)
lua.register(L, "fixture_concat", lua_fixture_concat)
lua.register(L, "fixture_add", lua_fixture_add)
}
lua_globals_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
key := string(lua.L_checkstring(L, 2))
switch key {
case "g_fix_f64":
lua.pushnumber(L, lua.Number(g_fix_f64))
case "g_fix_bool":
lua.pushboolean(L, b32(g_fix_bool))
case "g_fix_init_float":
lua.pushnumber(L, lua.Number(g_fix_init_float))
case "g_fix_arr":
(^^[4]int)(lua.newuserdata(L, size_of(rawptr)))^ = &g_fix_arr
lua.L_getmetatable(L, "farr_4_int")
lua.setmetatable(L, -2)
case "g_fix_string":
lua.pushlstring(L, cstring(raw_data(g_fix_string)), uint(len(g_fix_string)))
case "g_fix_int":
lua.pushinteger(L, lua.Integer(g_fix_int))
case "g_fix_i32":
lua.pushinteger(L, lua.Integer(g_fix_i32))
case "g_fix_init_str":
lua.pushlstring(L, cstring(raw_data(g_fix_init_str)), uint(len(g_fix_init_str)))
case "g_fix_rawptr":
lua.pushlightuserdata(L, g_fix_rawptr)
case "g_fix_map":
(^^map[string]int)(lua.newuserdata(L, size_of(rawptr)))^ = &g_fix_map
lua.L_getmetatable(L, "map_string_int")
lua.setmetatable(L, -2)
case "g_fix_f32":
lua.pushnumber(L, lua.Number(g_fix_f32))
case "g_fix_dyn":
(^^[dynamic]int)(lua.newuserdata(L, size_of(rawptr)))^ = &g_fix_dyn
lua.L_getmetatable(L, "dyn_int")
lua.setmetatable(L, -2)
case "g_fix_init_int":
lua.pushinteger(L, lua.Integer(g_fix_init_int))
case:
lua.pushnil(L)
}
return 1
}
lua_globals_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
key := string(lua.L_checkstring(L, 2))
switch key {
case "g_fix_f64":
g_fix_f64 = f64(lua.L_checknumber(L, 3))
case "g_fix_bool":
g_fix_bool = bool(lua.toboolean(L, 3))
case "g_fix_init_float":
g_fix_init_float = f64(lua.L_checknumber(L, 3))
case "g_fix_arr":
for _i in 0..<len(g_fix_arr) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
g_fix_arr[_i] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "g_fix_string":
g_fix_string = strings.clone(string(lua.tostring(L, 3)))
case "g_fix_int":
g_fix_int = int(lua.L_checkinteger(L, 3))
case "g_fix_i32":
g_fix_i32 = i32(lua.L_checkinteger(L, 3))
case "g_fix_init_str":
g_fix_init_str = strings.clone(string(lua.tostring(L, 3)))
case "g_fix_rawptr":
g_fix_rawptr = (rawptr)(lua.touserdata(L, 3))
case "g_fix_map":
clear(&g_fix_map)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
g_fix_map[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "g_fix_f32":
g_fix_f32 = f32(lua.L_checknumber(L, 3))
case "g_fix_dyn":
clear(&g_fix_dyn)
for _i in 0..<int(lua.objlen(L, 3)) {
lua.rawgeti(L, 3, lua.Integer(_i + 1))
append(&g_fix_dyn, int(lua.L_checkinteger(L, -1)))
lua.pop(L, 1)
}
case "g_fix_init_int":
g_fix_init_int = int(lua.L_checkinteger(L, 3))
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
