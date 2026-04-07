package olay
import lua "vendor:lua/5.1"
import "core:strings"
lua_Internal_Struct_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^Internal_Struct)(lua.touserdata(L, 1))
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
s := (^Internal_Struct)(lua.touserdata(L, 1))
key := string(lua.L_checkstring(L, 2))
switch key {
case "field1":
s.field1 = int(lua.L_checkinteger(L, 3))
case "field2":
s.field2 = int(lua.L_checkinteger(L, 3))
}
return 0
}
lua_Bogus_State_index :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^Bogus_State)(lua.touserdata(L, 1))
key := string(lua.L_checkstring(L, 2))
switch key {
case "val_name":
lua.pushlstring(L, cstring(raw_data(s.val_name)), uint(len(s.val_name)))
case "val_float":
lua.pushnumber(L, lua.Number(s.val_float))
case "val_int":
lua.pushinteger(L, lua.Integer(s.val_int))
case "val_fixed_arr":
lua.createtable(L, i32(len(s.val_fixed_arr)), 0)
for val, idx in s.val_fixed_arr{
lua.pushinteger(L, lua.Integer(val))
lua.rawseti(L, -2, i32(idx) + 1)
}
case "val_dict":
lua.newtable(L)
for key, value in s.val_dict {
lua.pushlstring(L, cstring(raw_data(key)), uint(len(key)))
lua.pushinteger(L, lua.Integer(value))
lua.rawset(L, -3)
}
case "val_dict2":
lua.newtable(L)
for key, value in s.val_dict2 {
lua.pushnumber(L, lua.Number(key))
lua.pushlightuserdata(L, value)
lua.rawset(L, -3)
}
case "val_dyn_arr":
lua.createtable(L, i32(len(s.val_dyn_arr)), 0)
for val, idx in s.val_dyn_arr{
lua.pushlstring(L, cstring(raw_data(val)), uint(len(val)))
lua.rawseti(L, -2, i32(idx) + 1)
}
case "val_struct":
lua.pushlightuserdata(L, &s.val_struct)
lua.L_getmetatable(L, "Internal_Struct")
lua.setmetatable(L, -2)
case:
lua.pushnil(L)
}
return 1
}
lua_Bogus_State_newindex :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
s := (^Bogus_State)(lua.touserdata(L, 1))
key := string(lua.L_checkstring(L, 2))
switch key {
case "val_name":
s.val_name = strings.clone(string(lua.tostring(L, 3)))
case "val_float":
s.val_float = f32(lua.L_checknumber(L, 3))
case "val_int":
s.val_int = int(lua.L_checkinteger(L, 3))
case "val_fixed_arr":
n := int(lua.objlen(L, 3))
for i in 0..<n {
lua.rawgeti(L, 3, lua.Integer(i + 1))
s.val_fixed_arr[i] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "val_dict":
delete(s.val_dict)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
s.val_dict[strings.clone(string(lua.tostring(L, -2)))] = int(lua.L_checkinteger(L, -1))
lua.pop(L, 1)
}
case "val_dict2":
delete(s.val_dict2)
lua.pushnil(L)
for lua.next(L, 3) != 0 {
s.val_dict2[f64(lua.L_checknumber(L, -2))] = (^int)(lua.touserdata(L, -1))
lua.pop(L, 1)
}
case "val_dyn_arr":
clear(&s.val_dyn_arr)
n := int(lua.objlen(L, 3))
for i in 0..<n {
lua.rawgeti(L, 3, lua.Integer(i + 1))
append(&s.val_dyn_arr, strings.clone(string(lua.tostring(L, -1))))
lua.pop(L, 1)
}
case "val_struct":
}
return 0
}
register_metatables :: proc(L: ^lua.State) {
lua.L_newmetatable(L, "Internal_Struct")
lua.pushcfunction(L, lua_Internal_Struct_index)
lua.setfield(L, -2, "__index")
lua.pushcfunction(L, lua_Internal_Struct_newindex)

lua.setfield(L, -2, "__newindex")
lua.pop(L, 1) // pop the metatable off the stack.
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
lua_func_c :: proc "c" (L: ^lua.State) -> i32 {
context = app.lua_odin_context
