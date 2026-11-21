package lua_fixture

import "core:strings"

// ============================================================================
// Test fixture for the Lua binding metaprogram.
// The metaprogram reads these tagged definitions and generates FFI glue code.
// The runtime tests then exercise the generated bindings end-to-end.
//
// Unsupported: Maybe, generic structs, pointer-to-another-global, enums.
// ============================================================================

// --- Structs -----------------------------------------------------------------

@(lua_data)
Fixture_Simple :: struct {
	f_int:    int,
	f_i32:    i32,
	f_i64:    i64,
	f_u8:     u8,
	f_u16:    u16,
	f_u32:    u32,
	f_u64:    u64,
	f_f32:    f32,
	f_f64:    f64,
	f_bool:   bool,
	f_b8:     b8,
	f_b32:    b32,
	f_string: string,
	f_rawptr: rawptr,
}

@(lua_data)
Fixture_Arrays :: struct {
	f_fixed_int:  [4]int,
	f_fixed_f32:  [8]f32,
	f_dyn_int:    [dynamic]int,
	f_dyn_string: [dynamic]string,
	f_dyn_f64:    [dynamic]f64,
}

@(lua_data)
Fixture_Maps :: struct {
	f_map_str_int: map[string]int,
	f_map_str_f64: map[string]f64,
	f_map_str_str: map[string]string,
}

@(lua_data)
Fixture_Nested :: struct {
	simple: Fixture_Simple,
	arrays: Fixture_Arrays,
}

@(lua_data)
Fixture_Deep_Nest :: struct {
	nested: Fixture_Nested,
}

@(lua_data)
Fixture_Pointer_Fields :: struct {
	f_ptr:    ^int,
	f_rawptr: rawptr,
}

// --- Global variables --------------------------------------------------------

@(lua_global)
g_fix_int: int

@(lua_global)
g_fix_i32: i32

@(lua_global)
g_fix_f32: f32

@(lua_global)
g_fix_f64: f64

@(lua_global)
g_fix_bool: bool

@(lua_global)
g_fix_string: string

@(lua_global)
g_fix_rawptr: rawptr

@(lua_global)
g_fix_arr: [4]int

@(lua_global)
g_fix_dyn: [dynamic]int

@(lua_global)
g_fix_map: map[string]int

@(lua_global)
g_fix_init_int := 42

@(lua_global)
g_fix_init_str := "hello"

@(lua_global)
g_fix_init_float := 3.14

// --- Procs -------------------------------------------------------------------

@(lua_proc)
fixture_no_args :: proc() {
}

@(lua_proc)
fixture_add :: proc(a: int, b: int) -> int {
	return a + b
}

@(lua_proc)
fixture_concat :: proc(a: string, b: string) -> string {
	return strings.concatenate({a, b})
}

@(lua_proc)
fixture_arr_len :: proc(arr: [dynamic]int) -> int {
	return len(arr)
}

@(lua_proc)
fixture_map_passthrough :: proc(m: map[string]int) -> map[string]int {
	return m
}

@(lua_proc)
fixture_multi_ret :: proc(x: int) -> (int, int) {
	return x * 2, x * 3
}
