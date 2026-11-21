package lua_bindings_tests

import app "../lua_fixture"
import "core:fmt"
import "core:testing"
import lua "vendor:lua/5.1"

// ============================================================================
// Helpers
// ============================================================================

make_test_lua_state :: proc() -> ^lua.State {
	if app.app == nil {
		app.app = new(app.App)
	}
	app.app.lua_odin_context = context

	L := lua.L_newstate()
	lua.L_openlibs(L)
	app.register_metatables(L)
	app.register_procs(L)
	app.register_globals(L)
	return L
}

run_lua :: proc(t: ^testing.T, L: ^lua.State, script: string, loc := #caller_location) -> bool {
	cstr := fmt.ctprintf("{}", script)
	if lua.L_dostring(L, cstr) != 0 {
		err := string(lua.tostring(L, -1))
		lua.pop(L, 1)
		fmt.printf("Lua error at %v: %s\n", loc, err)
		testing.fail(t)
		return false
	}
	return true
}

push_struct_global :: proc(L: ^lua.State, name: cstring, ptr: rawptr, metatable_name: cstring) {
	lua.pushvalue(L, lua.GLOBALSINDEX)
	lua.pushlstring(L, name, uint(len(string(name))))
	ud := (^rawptr)(lua.newuserdata(L, size_of(rawptr)))
	ud^ = ptr
	lua.L_getmetatable(L, metatable_name)
	lua.setmetatable(L, -2)
	lua.rawset(L, -3)
	lua.pop(L, 1)
}

// ============================================================================
// Globals — primitives
// ============================================================================

@(test)
test_global_int :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for i in 0 ..< 5 {
		val_lua := i * 100 + 1
		if !run_lua(t, L, fmt.tprintf("g_fix_int = {}", val_lua)) {return}
		testing.expect_value(t, app.g_fix_int, val_lua)

		val_odin     := i * 100 + 2
		app.g_fix_int = val_odin
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(g_fix_int == {}, 'expected {} got ' .. tostring(g_fix_int))", val_odin, val_odin),
		) {return}
	}
}

@(test)
test_global_i32 :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for i in 0 ..< 5 {
		val_lua := i32(i * 100 + 1)
		if !run_lua(t, L, fmt.tprintf("g_fix_i32 = {}", val_lua)) {return}
		testing.expect_value(t, app.g_fix_i32, val_lua)

		val_odin     := i32(i * 100 + 2)
		app.g_fix_i32 = val_odin
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(g_fix_i32 == {}, 'expected {} got ' .. tostring(g_fix_i32))", val_odin, val_odin),
		) {return}
	}
}

@(test)
test_global_f32 :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for i in 0 ..< 5 {
		val_lua := f32(i) * 1.5 + 1.0
		if !run_lua(t, L, fmt.tprintf("g_fix_f32 = {}", val_lua)) {return}
		testing.expect(
			t,
			app.g_fix_f32 == f32(val_lua),
			fmt.tprintf("f32 write: expected %v got %v", val_lua, app.g_fix_f32),
		)

		val_odin     := f32(i) * 1.5 + 2.0
		app.g_fix_f32 = val_odin
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"assert(math.abs(g_fix_f32 - {}) < 0.01, 'f32 read mismatch: ' .. tostring(g_fix_f32))",
				val_odin,
			),
		) {return}
	}
}

@(test)
test_global_f64 :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for i in 0 ..< 5 {
		val_lua := f64(i) * 10.5 + 1.0
		if !run_lua(t, L, fmt.tprintf("g_fix_f64 = {}", val_lua)) {return}
		testing.expect(
			t,
			app.g_fix_f64 == val_lua,
			fmt.tprintf("f64 write: expected %v got %v", val_lua, app.g_fix_f64),
		)

		val_odin     := f64(i) * 10.5 + 2.0
		app.g_fix_f64 = val_odin
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"assert(math.abs(g_fix_f64 - {}) < 0.001, 'f64 read mismatch: ' .. tostring(g_fix_f64))",
				val_odin,
			),
		) {return}
	}
}

@(test)
test_global_bool :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for i in 0 ..< 5 {
		val_lua := (i % 2) == 0
		if !run_lua(t, L, fmt.tprintf("g_fix_bool = {}", val_lua)) {return}
		testing.expect_value(t, app.g_fix_bool, val_lua)

		val_odin      := (i % 2) == 1
		app.g_fix_bool = val_odin
		if !run_lua(t, L, fmt.tprintf("assert(g_fix_bool == {}, 'bool mismatch')", val_odin)) {return}
	}
}

@(test)
test_global_string :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	lua_vals  := [5]string{"alpha", "beta", "gamma", "delta", "epsilon"}
	odin_vals := [5]string{"one", "two", "three", "four", "five"}

	for i in 0 ..< 5 {
		if !run_lua(t, L, fmt.tprintf("g_fix_string = '{}'", lua_vals[i])) {return}
		testing.expect_value(t, app.g_fix_string, lua_vals[i])

		app.g_fix_string = odin_vals[i]
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(g_fix_string == '{}', 'string mismatch: ' .. tostring(g_fix_string))", odin_vals[i]),
		) {return}
	}
}

@(test)
test_global_init_values :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(t, L, "assert(g_fix_init_int == 42, 'init_int wrong: ' .. tostring(g_fix_init_int))") {return}
	if !run_lua(t, L, "assert(g_fix_init_str == 'hello', 'init_str wrong: ' .. tostring(g_fix_init_str))") {return}
	if !run_lua(
		t,
		L,
		"assert(math.abs(g_fix_init_float - 3.14) < 0.001, 'init_float wrong: ' .. tostring(g_fix_init_float))",
	) {return}
}

@(test)
test_global_rawptr :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	target          := 999
	app.g_fix_rawptr = &target
	if !run_lua(t, L, "assert(g_fix_rawptr ~= nil, 'g_fix_rawptr should be non-nil userdata')") {return}

	app.g_fix_rawptr = nil
}

// ============================================================================
// Globals — fixed array
// ============================================================================

@(test)
test_global_fixed_array :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for cycle in 0 ..< 5 {
		base := cycle * 10
		if !run_lua(
			t,
			L,
			fmt.tprintf("g_fix_arr = {{{}, {}, {}, {}}}", base + 1, base + 2, base + 3, base + 4),
		) {return}
		testing.expect_value(t, app.g_fix_arr[0], base + 1)
		testing.expect_value(t, app.g_fix_arr[1], base + 2)
		testing.expect_value(t, app.g_fix_arr[2], base + 3)
		testing.expect_value(t, app.g_fix_arr[3], base + 4)

		base2        := cycle * 10 + 5
		app.g_fix_arr = {base2, base2 + 1, base2 + 2, base2 + 3}
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local a = g_fix_arr; assert(a[1]=={} and a[2]=={} and a[3]=={} and a[4]=={}, 'arr mismatch')",
				base2,
				base2 + 1,
				base2 + 2,
				base2 + 3,
			),
		) {return}
	}
}

// ============================================================================
// Globals — dynamic array
// ============================================================================

@(test)
test_global_dynamic_array :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for cycle in 0 ..< 5 {
		base := cycle * 10
		if !run_lua(t, L, fmt.tprintf("g_fix_dyn = {{{}, {}, {}}}", base + 1, base + 2, base + 3)) {return}
		testing.expect_value(t, len(app.g_fix_dyn), 3)
		testing.expect_value(t, app.g_fix_dyn[0], base + 1)
		testing.expect_value(t, app.g_fix_dyn[1], base + 2)
		testing.expect_value(t, app.g_fix_dyn[2], base + 3)

		clear(&app.g_fix_dyn)
		base2 := cycle * 10 + 5
		append(&app.g_fix_dyn, base2, base2 + 1)
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local d = g_fix_dyn; assert(#d == 2 and d[1]=={} and d[2]=={}, 'dyn mismatch')",
				base2,
				base2 + 1,
			),
		) {return}
	}
}

// ============================================================================
// Globals — map
// ============================================================================

@(test)
test_global_map :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	for cycle in 0 ..< 5 {
		base := cycle * 10
		if !run_lua(t, L, fmt.tprintf("g_fix_map = {{a={}, b={}}}", base + 1, base + 2)) {return}
		testing.expect_value(t, app.g_fix_map["a"], base + 1)
		testing.expect_value(t, app.g_fix_map["b"], base + 2)

		clear(&app.g_fix_map)
		base2 := cycle * 10 + 5
		app.g_fix_map["x"] = base2
		app.g_fix_map["y"] = base2 + 1
		if !run_lua(
			t,
			L,
			fmt.tprintf("local m = g_fix_map; assert(m.x=={} and m.y=={}, 'map mismatch')", base2, base2 + 1),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Simple (all scalar fields)
// ============================================================================

@(test)
test_struct_simple_scalars :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Simple
	push_struct_global(L, "fs", &s, "Fixture_Simple")

	for cycle in 0 ..< 5 {
		base := cycle * 100

		if !run_lua(t, L, fmt.tprintf("fs.f_int = {}", base + 1)) {return}
		testing.expect_value(t, s.f_int, base + 1)

		if !run_lua(t, L, fmt.tprintf("fs.f_i32 = {}", base + 2)) {return}
		testing.expect_value(t, s.f_i32, i32(base + 2))

		if !run_lua(t, L, fmt.tprintf("fs.f_f32 = {}", f32(base) + 0.5)) {return}
		testing.expect(
			t,
			s.f_f32 == f32(base) + 0.5,
			fmt.tprintf("f_f32: expected %v got %v", f32(base) + 0.5, s.f_f32),
		)

		if !run_lua(t, L, fmt.tprintf("fs.f_f64 = {}", f64(base) + 1.5)) {return}
		testing.expect(
			t,
			s.f_f64 == f64(base) + 1.5,
			fmt.tprintf("f_f64: expected %v got %v", f64(base) + 1.5, s.f_f64),
		)

		if !run_lua(t, L, fmt.tprintf("fs.f_bool = {}", cycle % 2 == 0)) {return}
		testing.expect_value(t, s.f_bool, cycle % 2 == 0)

		if !run_lua(t, L, fmt.tprintf("fs.f_string = 'cycle{}'", cycle)) {return}
		testing.expect_value(t, s.f_string, fmt.tprintf("cycle{}", cycle))

		if !run_lua(t, L, fmt.tprintf("fs.f_i64 = {}", i64(base + 3))) {return}
		testing.expect_value(t, s.f_i64, i64(base + 3))

		if !run_lua(t, L, fmt.tprintf("fs.f_u8 = {}", u8(cycle * 10 + 1))) {return}
		testing.expect_value(t, s.f_u8, u8(cycle * 10 + 1))

		if !run_lua(t, L, fmt.tprintf("fs.f_u16 = {}", u16(base + 4))) {return}
		testing.expect_value(t, s.f_u16, u16(base + 4))

		if !run_lua(t, L, fmt.tprintf("fs.f_u32 = {}", u32(base + 5))) {return}
		testing.expect_value(t, s.f_u32, u32(base + 5))

		if !run_lua(t, L, fmt.tprintf("fs.f_u64 = {}", u64(base + 6))) {return}
		testing.expect_value(t, s.f_u64, u64(base + 6))

		if !run_lua(t, L, fmt.tprintf("fs.f_b8 = {}", cycle % 2 == 1)) {return}
		testing.expect_value(t, s.f_b8, b8(cycle % 2 == 1))

		if !run_lua(t, L, fmt.tprintf("fs.f_b32 = {}", cycle % 2 == 0)) {return}
		testing.expect_value(t, s.f_b32, b32(cycle % 2 == 0))

		s.f_rawptr = &s.f_int
		if !run_lua(t, L, "assert(fs.f_rawptr ~= nil, 'f_rawptr should be non-nil')") {return}

		s.f_int = base + 50
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(fs.f_int == {}, 'f_int read: ' .. tostring(fs.f_int))", base + 50),
		) {return}

		s.f_string = fmt.tprintf("odin{}", cycle)
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(fs.f_string == 'odin{}', 'f_string read: ' .. tostring(fs.f_string))", cycle),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Arrays
// ============================================================================

@(test)
test_struct_arrays :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Arrays
	push_struct_global(L, "fa", &s, "Fixture_Arrays")

	for cycle in 0 ..< 5 {
		base := cycle * 10

		if !run_lua(t, L, fmt.tprintf("fa.f_fixed_int = {{{},{},{},{}}}", base + 1, base + 2, base + 3, base + 4)) {
			return
		}
		testing.expect_value(t, s.f_fixed_int[0], base + 1)
		testing.expect_value(t, s.f_fixed_int[3], base + 4)

		s.f_fixed_int = {base + 5, base + 6, base + 7, base + 8}
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local a=fa.f_fixed_int; assert(a[1]=={} and a[4]=={}, 'fixed_int mismatch')",
				base + 5,
				base + 8,
			),
		) {return}

		if !run_lua(t, L, fmt.tprintf("fa.f_dyn_int = {{{},{}}}", base + 10, base + 11)) {return}
		testing.expect_value(t, len(s.f_dyn_int), 2)
		testing.expect_value(t, s.f_dyn_int[0], base + 10)
		testing.expect_value(t, s.f_dyn_int[1], base + 11)

		clear(&s.f_dyn_int)
		append(&s.f_dyn_int, base + 20, base + 21, base + 22)
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local d=fa.f_dyn_int; assert(#d==3 and d[1]=={} and d[3]=={}, 'dyn_int mismatch')",
				base + 20,
				base + 22,
			),
		) {return}

		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"fa.f_fixed_f32 = {{{},{},{},{},{},{},{},{}}}",
				f32(base + 1),
				f32(base + 2),
				f32(base + 3),
				f32(base + 4),
				f32(base + 5),
				f32(base + 6),
				f32(base + 7),
				f32(base + 8),
			),
		) {return}
		testing.expect(t, s.f_fixed_f32[0] == f32(base + 1), fmt.tprintf("f_fixed_f32[0]: got %v", s.f_fixed_f32[0]))
		testing.expect(t, s.f_fixed_f32[7] == f32(base + 8), fmt.tprintf("f_fixed_f32[7]: got %v", s.f_fixed_f32[7]))

		s.f_fixed_f32 = {
			f32(base + 11),
			f32(base + 12),
			f32(base + 13),
			f32(base + 14),
			f32(base + 15),
			f32(base + 16),
			f32(base + 17),
			f32(base + 18),
		}
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local a=fa.f_fixed_f32; assert(a[1]=={} and a[8]=={}, 'fixed_f32 mismatch')",
				f32(base + 11),
				f32(base + 18),
			),
		) {return}

		if !run_lua(t, L, fmt.tprintf("fa.f_dyn_string = {{'str{}a', 'str{}b'}}", base, base)) {return}
		testing.expect_value(t, len(s.f_dyn_string), 2)
		testing.expect_value(t, s.f_dyn_string[0], fmt.tprintf("str{}a", base))
		testing.expect_value(t, s.f_dyn_string[1], fmt.tprintf("str{}b", base))

		clear(&s.f_dyn_string)
		append(&s.f_dyn_string, fmt.tprintf("odin_{}a", cycle), fmt.tprintf("odin_{}b", cycle))
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local d=fa.f_dyn_string; assert(#d==2 and d[1]=='odin_{}a' and d[2]=='odin_{}b', 'dyn_string mismatch')",
				cycle,
				cycle,
			),
		) {return}

		if !run_lua(t, L, fmt.tprintf("fa.f_dyn_f64 = {{{}, {}}}", f64(base + 1), f64(base + 2))) {return}
		testing.expect_value(t, len(s.f_dyn_f64), 2)
		testing.expect_value(t, s.f_dyn_f64[0], f64(base + 1))
		testing.expect_value(t, s.f_dyn_f64[1], f64(base + 2))

		clear(&s.f_dyn_f64)
		append(&s.f_dyn_f64, f64(base + 20), f64(base + 21))
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local d=fa.f_dyn_f64; assert(#d==2 and d[1]=={} and d[2]=={}, 'dyn_f64 mismatch')",
				f64(base + 20),
				f64(base + 21),
			),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Maps
// ============================================================================

@(test)
test_struct_maps :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Maps
	push_struct_global(L, "fm", &s, "Fixture_Maps")

	for cycle in 0 ..< 5 {
		base := cycle * 10

		if !run_lua(t, L, fmt.tprintf("fm.f_map_str_int = {{k1={}, k2={}}}", base + 1, base + 2)) {return}
		testing.expect_value(t, s.f_map_str_int["k1"], base + 1)
		testing.expect_value(t, s.f_map_str_int["k2"], base + 2)

		clear(&s.f_map_str_int)
		s.f_map_str_int["p"] = base + 50
		s.f_map_str_int["q"] = base + 51
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"local m=fm.f_map_str_int; assert(m.p=={} and m.q=={}, 'map_str_int mismatch')",
				base + 50,
				base + 51,
			),
		) {return}

		if !run_lua(t, L, fmt.tprintf("fm.f_map_str_f64 = {{k1={}, k2={}}}", f64(base + 1), f64(base + 2))) {return}
		testing.expect_value(t, s.f_map_str_f64["k1"], f64(base + 1))
		testing.expect_value(t, s.f_map_str_f64["k2"], f64(base + 2))

		clear(&s.f_map_str_f64)
		s.f_map_str_f64["m"] = f64(base + 9)
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(fm.f_map_str_f64.m == {}, 'f_map_str_f64.m mismatch')", f64(base + 9)),
		) {return}

		if !run_lua(t, L, fmt.tprintf("fm.f_map_str_str = {{p='key{}p', q='key{}q'}}", base, base)) {return}
		testing.expect_value(t, s.f_map_str_str["p"], fmt.tprintf("key{}p", base))
		testing.expect_value(t, s.f_map_str_str["q"], fmt.tprintf("key{}q", base))

		clear(&s.f_map_str_str)
		s.f_map_str_str["n"] = fmt.tprintf("oval_{}", cycle)
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(fm.f_map_str_str.n == 'oval_{}', 'f_map_str_str.n mismatch')", cycle),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Nested (2-level)
// ============================================================================

@(test)
test_struct_nested :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Nested
	push_struct_global(L, "fn_", &s, "Fixture_Nested")

	for cycle in 0 ..< 5 {
		base := cycle * 100

		if !run_lua(t, L, fmt.tprintf("fn_.simple.f_int = {}", base + 1)) {return}
		testing.expect_value(t, s.simple.f_int, base + 1)

		if !run_lua(t, L, fmt.tprintf("fn_.simple.f_string = 'nest{}'", cycle)) {return}
		testing.expect_value(t, s.simple.f_string, fmt.tprintf("nest{}", cycle))

		s.simple.f_int = base + 50
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(fn_.simple.f_int == {}, 'nested f_int: ' .. tostring(fn_.simple.f_int))", base + 50),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Deep_Nest (3-level)
// ============================================================================

@(test)
test_struct_deep_nest :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Deep_Nest
	push_struct_global(L, "fd", &s, "Fixture_Deep_Nest")

	for cycle in 0 ..< 5 {
		base := cycle * 100

		if !run_lua(t, L, fmt.tprintf("fd.nested.simple.f_int = {}", base + 1)) {return}
		testing.expect_value(t, s.nested.simple.f_int, base + 1)

		if !run_lua(t, L, fmt.tprintf("fd.nested.simple.f_bool = {}", cycle % 2 == 0)) {return}
		testing.expect_value(t, s.nested.simple.f_bool, cycle % 2 == 0)

		s.nested.simple.f_int = base + 77
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"assert(fd.nested.simple.f_int == {}, 'deep f_int: ' .. tostring(fd.nested.simple.f_int))",
				base + 77,
			),
		) {return}
	}
}

// ============================================================================
// Struct — Fixture_Pointer_Fields
// ============================================================================

@(test)
test_struct_pointer_fields :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)
	s: app.Fixture_Pointer_Fields
	push_struct_global(L, "fp", &s, "Fixture_Pointer_Fields")

	target := 999
	s.f_ptr = &target
	if !run_lua(t, L, "assert(fp.f_ptr ~= nil, 'f_ptr should be non-nil userdata')") {return}

	s.f_rawptr = &target
	if !run_lua(t, L, "assert(fp.f_rawptr ~= nil, 'f_rawptr should be non-nil userdata')") {return}
}

// ============================================================================
// Procs
// ============================================================================

@(test)
test_proc_add :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(t, L, "assert(fixture_add(3, 4) == 7, 'fixture_add(3,4) != 7')") {return}
	if !run_lua(t, L, "assert(fixture_add(0, 0) == 0, 'fixture_add(0,0) != 0')") {return}
	if !run_lua(t, L, "assert(fixture_add(-5, 10) == 5, 'fixture_add(-5,10) != 5')") {return}
}

@(test)
test_proc_concat :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(t, L, "assert(fixture_concat('foo', 'bar') == 'foobar', 'concat mismatch')") {return}
	if !run_lua(t, L, "assert(fixture_concat('', 'x') == 'x', 'concat empty mismatch')") {return}
}

@(test)
test_proc_arr_len :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(t, L, "assert(fixture_arr_len({1,2,3}) == 3, 'arr_len != 3')") {return}
	if !run_lua(t, L, "assert(fixture_arr_len({}) == 0, 'arr_len of empty != 0')") {return}
}

@(test)
test_proc_map_passthrough :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(
		t,
		L,
		`
		local r = fixture_map_passthrough({a=1, b=2})
		assert(r.a == 1 and r.b == 2, 'map_passthrough mismatch')
	`,
	) {return}
}

@(test)
test_proc_multi_ret :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(
		t,
		L,
		`
		local a, b = fixture_multi_ret(5)
		assert(a == 10, 'multi_ret first: ' .. tostring(a))
		assert(b == 15, 'multi_ret second: ' .. tostring(b))
	`,
	) {return}
}

@(test)
test_proc_no_args :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	if !run_lua(t, L, "fixture_no_args()") {return}
}

// ============================================================================
// Cross-boundary interleave stress test
// ============================================================================

@(test)
test_cross_boundary_stress :: proc(t: ^testing.T) {
	L := make_test_lua_state(); defer lua.close(L)

	s: app.Fixture_Simple
	push_struct_global(L, "stress_s", &s, "Fixture_Simple")

	for cycle in 0 ..< 10 {
		base := cycle * 1000

		if !run_lua(t, L, fmt.tprintf("g_fix_int = {}; stress_s.f_int = {}", base + 1, base + 2)) {return}
		testing.expect_value(t, app.g_fix_int, base + 1)
		testing.expect_value(t, s.f_int, base + 2)

		app.g_fix_int = base + 3
		s.f_int       = base + 4
		if !run_lua(
			t,
			L,
			fmt.tprintf(
				"assert(g_fix_int=={} and stress_s.f_int=={}, 'stress odin->lua cycle {}')",
				base + 3,
				base + 4,
				cycle,
			),
		) {return}

		if !run_lua(t, L, fmt.tprintf("g_fix_int = fixture_add(g_fix_int, {})", base + 10)) {return}
		expected_after_add := (base + 3) + (base + 10)
		testing.expect_value(t, app.g_fix_int, expected_after_add)

		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(g_fix_int == {}, 'post-add mismatch: ' .. tostring(g_fix_int))", expected_after_add),
		) {return}

		testing.expect_value(t, s.f_int, base + 4)
		if !run_lua(
			t,
			L,
			fmt.tprintf("assert(stress_s.f_int == {}, 'struct corrupted by global write')", base + 4),
		) {return}
	}
}
