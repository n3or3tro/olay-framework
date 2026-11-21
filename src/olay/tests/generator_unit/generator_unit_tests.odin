#+feature dynamic-literals
package generator_unit_tests

import app "../../../../util"
import "base:runtime"
import "core:fmt"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"
import "core:path/filepath"
import "core:strings"
import "core:testing"

scratch_proc_info: app.Proc_Description
scratch_array_type: app.Type_Info
scratch_map_type: app.Type_Info
scratch_struct_type: app.Type_Info

emit_scratch_proc_output :: proc(file: ^os.File) {
	app.write_out_lua_proc(file, scratch_proc_info)
}

emit_scratch_value_output :: proc(file: ^os.File) {
	app.emit_lua_write_value(file, scratch_array_type, "values")
	app.emit_lua_read_value(file, scratch_map_type, "mapping", "3")
	app.emit_lua_write_value(file, scratch_struct_type, "node")
}

emit_scratch_metatable_output :: proc(file: ^os.File) {
	app.write_metatable_registrations(file, app.target_structs["Parent"])
}

emit_scratch_globals_output :: proc(file: ^os.File) {
	app.write_global_var_accessors(file)
}

parse_source :: proc(source: string, file_name := "fixture.odin") -> ast.File {
	p: parser.Parser
	file: ast.File
	app.file_contents = source
	file.src          = source
	file.fullpath     = file_name
	file.derived      = &file
	parser.parse_file(&p, &file)
	return file
}

find_value_decl :: proc(file: ^ast.File, name: string) -> ^ast.Value_Decl {
	for stmt in file.decls {
		if decl, ok := stmt.derived.(^ast.Value_Decl); ok {
			if len(decl.names) > 0 {
				if ident, ok := decl.names[0].derived.(^ast.Ident); ok && ident.name == name {
					return decl
				}
			}
		}
	}
	return nil
}

reset_generator_state :: proc() {
	delete(app.target_procs)
	delete(app.target_structs)
	delete(app.target_global_variables)
	delete(app.already_registered_structs)
	app.target_procs               = make(map[string]app.Proc_Description)
	app.target_structs             = make(map[string]app.Struct_Description)
	app.target_global_variables    = make(map[string]app.Global_Variable)
	app.already_registered_structs = make(map[string]bool)
	app.file_contents              = ""
	app.package_name               = ""
}

make_temp_dir :: proc(t: ^testing.T) -> string {
	dir, err := os.make_directory_temp("", "olay-generator-unit-*", context.allocator)
	if !testing.expect_value(t, err, nil) do return ""
	return dir
}

cleanup_temp_dir :: proc(dir: string) {
	lua_path, _     := filepath.join({dir, "out.lua"}, context.temp_allocator)
	odin_path, _    := filepath.join({dir, "out.odin"}, context.temp_allocator)
	fixture_path, _ := filepath.join({dir, "fixture.odin"}, context.temp_allocator)
	scratch_path, _ := filepath.join({dir, "scratch.txt"}, context.temp_allocator)
	_                = os.remove(lua_path)
	_                = os.remove(odin_path)
	_                = os.remove(fixture_path)
	_                = os.remove(scratch_path)
	_                = os.remove(dir)
	delete(dir)
}

write_and_read_output :: proc(t: ^testing.T, emit: proc(_: ^os.File), file_name := "scratch.txt") -> string {
	dir := make_temp_dir(t)
	if dir == "" do return ""
	defer cleanup_temp_dir(dir)

	path, join_err := filepath.join({dir, file_name}, context.temp_allocator)
	if !testing.expect_value(t, join_err, runtime.Allocator_Error.None) do return ""
	file, err := os.open(path, {.Read, .Write, .Create, .Trunc})
	if !testing.expect_value(t, err, nil) do return ""
	emit(file)
	_ = os.close(file)

	data, read_err := os.read_entire_file_from_path(path, context.allocator)
	if !testing.expect_value(t, read_err, nil) do return ""
	return string(data)
}

@(test)
test_find_package_name_reads_first_package_line :: proc(t: ^testing.T) {
	dir := make_temp_dir(t)
	if dir == "" do return
	defer cleanup_temp_dir(dir)

	path, join_err := filepath.join({dir, "fixture.odin"}, context.temp_allocator)
	if !testing.expect_value(t, join_err, runtime.Allocator_Error.None) do return
	source    := "// comment\npackage test_fixture\nvalue := 1\n"
	write_err := os.write_entire_file_from_string(path, source)
	if !testing.expect_value(t, write_err, nil) do return

	testing.expect_value(t, app.find_package_name(path), "test_fixture")
}

@(test)
test_classify_type_handles_supported_forms :: proc(t: ^testing.T) {
	file := parse_source(
		`package test_fixture
primitive_int: int
primitive_float: f32
primitive_bool: bool
primitive_string: string
primitive_ptr: ^int
fixed_values: [4]int
dynamic_values: [dynamic]string
mapping: map[string]f64
literal_number := 42
literal_text := "hello"
literal_float := 3.14
struct_value: Some_Struct
`,
	)

	int_decl        := find_value_decl(&file, "primitive_int")
	float_decl      := find_value_decl(&file, "primitive_float")
	bool_decl       := find_value_decl(&file, "primitive_bool")
	string_decl     := find_value_decl(&file, "primitive_string")
	ptr_decl        := find_value_decl(&file, "primitive_ptr")
	fixed_decl      := find_value_decl(&file, "fixed_values")
	dynamic_decl    := find_value_decl(&file, "dynamic_values")
	map_decl        := find_value_decl(&file, "mapping")
	int_lit_decl    := find_value_decl(&file, "literal_number")
	string_lit_decl := find_value_decl(&file, "literal_text")
	float_lit_decl  := find_value_decl(&file, "literal_float")
	struct_decl     := find_value_decl(&file, "struct_value")

	int_info        := app.classify_type(int_decl.type)
	float_info      := app.classify_type(float_decl.type)
	bool_info       := app.classify_type(bool_decl.type)
	string_info     := app.classify_type(string_decl.type)
	ptr_info        := app.classify_type(ptr_decl.type)
	fixed_info      := app.classify_type(fixed_decl.type)
	dynamic_info    := app.classify_type(dynamic_decl.type)
	map_info        := app.classify_type(map_decl.type)
	int_lit_info    := app.classify_type(int_lit_decl.values[0])
	string_lit_info := app.classify_type(string_lit_decl.values[0])
	float_lit_info  := app.classify_type(float_lit_decl.values[0])
	struct_info     := app.classify_type(struct_decl.type)

	testing.expect_value(t, int_info.kind, app.Type_Kind.Int)
	testing.expect_value(t, int_info.lua_annotation, "integer")
	testing.expect_value(t, float_info.kind, app.Type_Kind.Float)
	testing.expect_value(t, bool_info.kind, app.Type_Kind.Bool)
	testing.expect_value(t, string_info.kind, app.Type_Kind.String)
	testing.expect_value(t, ptr_info.kind, app.Type_Kind.Pointer)
	testing.expect_value(t, ptr_info.odin_type_name, "^int")
	testing.expect_value(t, fixed_info.kind, app.Type_Kind.Fixed_Array)
	testing.expect_value(t, fixed_info.lua_annotation, "integer[]")
	testing.expect_value(t, fixed_info.odin_type_name, "[4]int")
	testing.expect_value(t, dynamic_info.kind, app.Type_Kind.Dynamic_Array)
	testing.expect_value(t, dynamic_info.lua_annotation, "string[]")
	testing.expect_value(t, map_info.kind, app.Type_Kind.Map)
	testing.expect_value(t, map_info.lua_annotation, "table<string, number>")
	testing.expect_value(t, int_lit_info.kind, app.Type_Kind.Int)
	testing.expect_value(t, string_lit_info.kind, app.Type_Kind.String)
	testing.expect_value(t, float_lit_info.kind, app.Type_Kind.Float)
	testing.expect_value(t, struct_info.kind, app.Type_Kind.Struct)
	testing.expect_value(t, struct_info.lua_annotation, "Some_Struct")
}

@(test)
test_process_proc_collects_grouped_params_and_results :: proc(t: ^testing.T) {
	reset_generator_state()
	file := parse_source(
		`package test_fixture
@(lua_proc)
sample_proc :: proc(a, b: int, label: string, values: [dynamic]int) -> int {
	return a + b
}
`,
	)

	decl := find_value_decl(&file, "sample_proc")
	if !testing.expect(t, decl != nil, "expected sample_proc declaration") do return
	app.process_proc(decl)

	testing.expect(t, "sample_proc" in app.target_procs, "expected sample_proc to be recorded")
	proc_info := app.target_procs["sample_proc"]
	testing.expect_value(t, len(proc_info.args), 4)
	if len(proc_info.args) != 4 do return
	testing.expect_value(t, proc_info.args[0].name, "a")
	testing.expect_value(t, proc_info.args[1].name, "b")
	testing.expect_value(t, proc_info.args[2].name, "label")
	testing.expect_value(t, proc_info.args[3].type.kind, app.Type_Kind.Dynamic_Array)
	testing.expect_value(t, len(proc_info.results), 1)
	if len(proc_info.results) != 1 do return
	testing.expect_value(t, proc_info.results[0].name, "")
	testing.expect_value(t, proc_info.results[0].type.kind, app.Type_Kind.Int)
}

@(test)
test_process_struct_collects_fields_and_types :: proc(t: ^testing.T) {
	reset_generator_state()
	file := parse_source(
		`package test_fixture
@(lua_data)
Example :: struct {
	left, right: int,
	title: string,
	values: [dynamic]f64,
}
`,
	)

	decl := find_value_decl(&file, "Example")
	if !testing.expect(t, decl != nil, "expected Example declaration") do return
	app.process_struct(decl)

	struct_info := app.target_structs["Example"]
	testing.expect_value(t, len(struct_info.fields), 4)
	if len(struct_info.fields) != 4 do return
	testing.expect_value(t, struct_info.fields[0].name, "left")
	testing.expect_value(t, struct_info.fields[1].name, "right")
	testing.expect_value(t, struct_info.fields[2].type.kind, app.Type_Kind.String)
	testing.expect_value(t, struct_info.fields[3].type.kind, app.Type_Kind.Dynamic_Array)
}

@(test)
test_process_node_collects_only_tagged_declarations :: proc(t: ^testing.T) {
	reset_generator_state()
	file := parse_source(
		`package test_fixture
@(lua_data)
Tagged_Struct :: struct {
	field: int,
}

@(lua_global)
tagged_global: int

@(lua_global)
tagged_initialized := "hello"

@(lua_proc)
tagged_proc :: proc(value: int) -> int {
	return value
}

untagged_global := 99
`,
	)

	for stmt in file.decls {
		app.process_node(stmt)
	}

	testing.expect(t, "Tagged_Struct" in app.target_structs, "expected tagged struct")
	testing.expect(t, "tagged_global" in app.target_global_variables, "expected tagged global without initializer")
	testing.expect(t, "tagged_initialized" in app.target_global_variables, "expected tagged initialized global")
	testing.expect(t, "tagged_proc" in app.target_procs, "expected tagged proc")
	testing.expect(t, !("untagged_global" in app.target_global_variables), "did not expect untagged global")
}

@(test)
test_write_out_lua_proc_emits_annotations_and_signature :: proc(t: ^testing.T) {
	scratch_proc_info = app.Proc_Description {
		name    = "combine",
		args    = {
			{name = "count", type = {kind = .Int, lua_annotation = "integer", odin_type_name = "int"}},
			{
				name = "labels",
				type = {kind = .Dynamic_Array, lua_annotation = "string[]", odin_type_name = "[dynamic]string"},
			},
		},
		results = {{name = "", type = {kind = .Bool, lua_annotation = "boolean", odin_type_name = "bool"}}},
	}

	output := write_and_read_output(t, emit_scratch_proc_output)
	if output == "" do return

	testing.expect(t, strings.contains(output, "---@param count integer"), "missing integer annotation")
	testing.expect(t, strings.contains(output, "---@param labels string[]"), "missing array annotation")
	testing.expect(t, strings.contains(output, "---@return boolean"), "missing return annotation")
	testing.expect(t, strings.contains(output, "function combine(count, labels) end"), "missing function signature")
}

@(test)
test_emit_lua_value_helpers_write_expected_snippets :: proc(t: ^testing.T) {
	scratch_array_type = app.Type_Info {
		kind           = .Dynamic_Array,
		lua_annotation = "integer[]",
		odin_type_name = "[dynamic]int",
		elem           = &app.Type_Info{kind = .Int, lua_annotation = "integer", odin_type_name = "int"},
	}
	scratch_map_type = app.Type_Info {
		kind           = .Map,
		lua_annotation = "table<string, number>",
		odin_type_name = "map[string]f64",
		key            = &app.Type_Info{kind = .String, lua_annotation = "string", odin_type_name = "string"},
		value          = &app.Type_Info{kind = .Float, lua_annotation = "number", odin_type_name = "f64"},
	}
	scratch_struct_type = app.Type_Info {
		kind           = .Struct,
		lua_annotation = "Child",
		odin_type_name = "Child",
	}

	output := write_and_read_output(t, emit_scratch_value_output)
	if output == "" do return

	testing.expect(
		t,
		strings.contains(output, "lua.L_getmetatable(L, \"dyn_int\")"),
		"missing array proxy metatable lookup",
	)
	testing.expect(t, strings.contains(output, "clear(&mapping)"), "missing map clear")
	testing.expect(t, strings.contains(output, "for lua.next(L, 3) != 0"), "missing map iteration")
	testing.expect(t, strings.contains(output, "lua.L_getmetatable(L, \"Child\")"), "missing struct metatable lookup")
}

@(test)
test_write_metatable_registrations_orders_nested_structs :: proc(t: ^testing.T) {
	reset_generator_state()
	app.target_structs["Child"] = {
		name   = "Child",
		fields = {{name = "value", type = {kind = .Int, lua_annotation = "integer", odin_type_name = "int"}}},
	}
	app.target_structs["Parent"] = {
		name   = "Parent",
		fields = {{name = "child", type = {kind = .Struct, lua_annotation = "Child", odin_type_name = "Child"}}},
	}

	output := write_and_read_output(t, emit_scratch_metatable_output)
	if output == "" do return

	child_idx  := strings.index(output, "lua.L_newmetatable(L, \"Child\")")
	parent_idx := strings.index(output, "lua.L_newmetatable(L, \"Parent\")")
	testing.expect(t, child_idx >= 0, "missing child registration")
	testing.expect(t, parent_idx >= 0, "missing parent registration")
	testing.expect(t, child_idx < parent_idx, "expected child registration before parent")
}

@(test)
test_write_global_var_accessors_emits_switch_cases :: proc(t: ^testing.T) {
	reset_generator_state()
	app.target_global_variables["answer"] = {
		name = "answer",
		type = {kind = .Int, lua_annotation = "integer", odin_type_name = "int"},
	}
	app.target_global_variables["title"] = {
		name = "title",
		type = {kind = .String, lua_annotation = "string", odin_type_name = "string"},
	}

	output := write_and_read_output(t, emit_scratch_globals_output)
	if output == "" do return

	testing.expect(t, strings.contains(output, "lua_globals_index :: proc"), "missing globals index proc")
	testing.expect(t, strings.contains(output, "case \"answer\":"), "missing answer case")
	testing.expect(t, strings.contains(output, "case \"title\":"), "missing title case")
	testing.expect(t, strings.contains(output, "lua_globals_newindex :: proc"), "missing globals newindex proc")
	testing.expect(t, strings.contains(output, "register_globals :: proc"), "missing register_globals proc")
}

@(test)
test_generate_creates_expected_artifacts :: proc(t: ^testing.T) {
	reset_generator_state()
	dir := make_temp_dir(t)
	if dir == "" do return
	defer cleanup_temp_dir(dir)

	fixture_path, fixture_join_err := filepath.join({dir, "fixture.odin"}, context.temp_allocator)
	lua_path, lua_join_err         := filepath.join({dir, "out.lua"}, context.temp_allocator)
	odin_path, odin_join_err       := filepath.join({dir, "out.odin"}, context.temp_allocator)
	if !testing.expect_value(t, fixture_join_err, runtime.Allocator_Error.None) do return
	if !testing.expect_value(t, lua_join_err, runtime.Allocator_Error.None) do return
	if !testing.expect_value(t, odin_join_err, runtime.Allocator_Error.None) do return

	source := `package generated_fixture
@(lua_data)
State :: struct {
	count: int,
	label: string,
}

@(lua_global)
global_count := 42

@(lua_proc)
increment :: proc(value: int) -> int {
	return value + 1
}
`
	write_err := os.write_entire_file_from_string(fixture_path, source)
	if !testing.expect_value(t, write_err, nil) do return

	ok, err_msg := app.generate(dir, lua_path, odin_path)
	if !testing.expect(t, ok, fmt.tprintf("generate returned error: %s", err_msg)) do return

	lua_data, lua_err   := os.read_entire_file_from_path(lua_path, context.allocator)
	odin_data, odin_err := os.read_entire_file_from_path(odin_path, context.allocator)
	if !testing.expect_value(t, lua_err, nil) do return
	if !testing.expect_value(t, odin_err, nil) do return

	lua_output  := string(lua_data)
	odin_output := string(odin_data)

	testing.expect(t, strings.contains(lua_output, "---@class State"), "missing Lua class annotation")
	testing.expect(t, strings.contains(lua_output, "function increment(value) end"), "missing Lua proc signature")
	testing.expect(t, strings.contains(odin_output, "package generated_fixture"), "missing generated package name")
	testing.expect(t, strings.contains(odin_output, "lua_State_index :: proc"), "missing struct index proc")
	testing.expect(t, strings.contains(odin_output, "lua_increment :: proc"), "missing proc bridge")
	testing.expect(t, strings.contains(odin_output, "lua_globals_index :: proc"), "missing globals accessor")
}
