package util

import "core:fmt"
import "core:odin"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"
import str "core:strings"
import lua "vendor:lua/5.1"

print :: fmt.print
println :: fmt.println
printf :: fmt.printf
printfln :: fmt.printfln
aprintf :: fmt.aprintf
tprintf :: fmt.tprintf
tprintfln :: fmt.tprintfln
tprintln :: fmt.tprintln

Proc_Argument :: struct {
	name: string,
	type: Type_Info,
}

Proc_Result :: Proc_Argument
Global_Variable :: Proc_Argument

Struct_Field :: struct {
	name: string,
	type: Type_Info,
}

Proc_Description :: struct {
	name:    string,
	args:    [dynamic]Proc_Argument,
	results: [dynamic]Proc_Result,
}

Struct_Description :: struct {
	name:   string,
	// identifier_in_source: string, // The struct name or var name from the source.
	fields: [dynamic]Struct_Field,
}

Type_Kind :: enum {
	Int,
	Float,
	Bool,
	String,
	Dynamic_Array,
	Fixed_Array,
	Map,
	Pointer,
	Struct,
	Unsupported,
}

Type_Info :: struct {
	kind:           Type_Kind,
	lua_annotation: string, // can pass this straight through to Lua.
	odin_type_name: string, // sometimes we need the precise type instead of just 'Number' or 'Float'
	// These aren't used unless the type requires them.
	elem:           ^Type_Info, // For compound types like arrays.
	key:            ^Type_Info, // for maps
	value:          ^Type_Info, // for maps
}

target_procs: map[string]Proc_Description
target_structs: map[string]Struct_Description
target_global_variables: map[string]Global_Variable
already_registered_structs: map[string]bool
target_proxy_types: map[string]Type_Info
// Kinda jank to keep file_contents global, but we move.
file_contents: string
package_name: string

generate :: proc(dir_path: string, lua_out_path: string, odin_out_path: string) -> (ok: bool, err: string) {
	dir_info, derr := os.read_directory_by_path(dir_path, 0, context.allocator)
	assert(derr == os.General_Error.None, tprintf("{}", derr))

	in_paths: [dynamic]string
	for f in dir_info {
		if f.type == .Regular && str.has_suffix(f.name, ".odin") do append(&in_paths, f.fullpath)
	}

	odin_file, oerr := os.open(odin_out_path, {.Read, .Write, .Create, .Trunc})
	assert(oerr == os.General_Error.None)

	lua_file, lerr := os.open(lua_out_path, {.Read, .Write, .Create, .Trunc})
	assert(lerr == os.General_Error.None)

	package_name = find_package_name(in_paths[0])

	os.write_string(odin_file, tprintf("package {}\n", package_name))
	os.write_string(odin_file, "import lua \"vendor:lua/5.1\"\n")
	os.write_string(odin_file, "import \"core:strings\"\n")

	// We build an AST for each file in the provided directory, walk_ast, traverses the AST and
	// for each node calls 'process_node()' which basically builds up some data structures that allow
	// us to later write out our Odin FFI and lua type defs.
	for path in in_paths {
		// clear(&target_global_variables)
		// clear(&target_procs)
		// clear(&target_structs)

		data, err := os.read_entire_file_from_path(path, context.allocator)
		assert(err == os.General_Error.None)
		file_contents = str.clone_from_bytes(data)

		p: parser.Parser
		file: ast.File
		file.src      = file_contents
		file.fullpath = path
		file.derived  = &file
		parser.parse_file(&p, &file)

		walk_ast(&file)
		// We're relying on global variables, so after generate() is called we assume
		// it succeeded and we can just read the results from our global data.v
	}

	/*At this point we have all the data we need to generate Odin FFI procs and Lua bindings.*/

	collect_proxy_types()

	for proxy_name, type in target_proxy_types {
		write_proxy_handlers(odin_file, proxy_name, type)
	}

	for struct_name, struct_info in target_structs {
		write_struct_metatable_index(odin_file, struct_info)
		write_struct_metatable_newindex(odin_file, struct_info)
	}

	os.write_string(odin_file, "register_metatables :: proc(L: ^lua.State) {\n")
	for proxy_name, _ in target_proxy_types {
		write_proxy_metatable_registration(odin_file, proxy_name)
	}
	for struct_name, struct_info in target_structs {
		write_metatable_registrations(odin_file, struct_info)
	}
	os.write_string(odin_file, "}\n")


	for struct_name, struct_info in target_structs {
		write_out_lua_struct(lua_file, struct_info)
	}

	for proc_name, proc_info in target_procs {
		write_out_odin_ffi_proc(odin_file, proc_info)
		write_out_lua_proc(lua_file, proc_info)
	}

	write_proc_registrations(odin_file)
	write_global_var_accessors(odin_file)
	return true, ""
}

find_package_name :: proc(file_path: string) -> string {
	data, err := os.read_entire_file_from_path(file_path, context.allocator)
	assert(err == os.General_Error.None)

	file_contents := str.clone_from_bytes(data)
	lines         := str.split(file_contents, "\n")
	for line in lines {
		// May be kind of brittle
		if str.starts_with(line, "package ") {
			tokens := str.split(line, " ")
			if len(tokens) != 2 do continue
			return tokens[1]
		}
	}
	panic(tprintf("couldn't find package name in {}", file_path))
}

// Takes the raw odin AST node of a type (proc arg/ret value, struct field, etc),
// and gives us back an intermediate representation that we can use
// to generate both the Lua LSP files and the FFI C stubs.
classify_type :: proc(expr: ^ast.Expr) -> Type_Info {
	#partial switch t in expr.derived {
	case ^ast.Ident:
		switch t.name {
		case "int", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64":
			return {kind = .Int, lua_annotation = "integer", odin_type_name = t.name}
		case "f32", "f64":
			return {kind = .Float, lua_annotation = "number", odin_type_name = t.name}
		case "bool", "b8", "b16", "b32":
			return {kind = .Bool, lua_annotation = "boolean", odin_type_name = t.name}
		case "string":
			return {kind = .String, lua_annotation = "string", odin_type_name = "string"}
		case "rawptr":
			return {kind = .Pointer, lua_annotation = "userdata", odin_type_name = "rawptr"}
		case:
			return {kind = .Struct, lua_annotation = t.name, odin_type_name = t.name}
		}
	// Not sure the allocations here are neccessary ?
	case ^ast.Dynamic_Array_Type:
		elem := new(Type_Info)
		elem^ = classify_type(t.elem)
		return {
			kind = .Dynamic_Array,
			lua_annotation = tprintf("%s[]", elem.lua_annotation),
			odin_type_name = tprintf("[dynamic]{}", elem.odin_type_name),
			elem = elem,
		}
	case ^ast.Array_Type:
		elem := new(Type_Info)
		elem^ = classify_type(t.elem)
		n    := get_source_from_node(t.len)
		return {
			kind = .Fixed_Array,
			lua_annotation = tprintf("%s[]", elem.lua_annotation),
			odin_type_name = tprintf("[{}]{}", n, elem.odin_type_name),
			elem = elem,
		}
	case ^ast.Map_Type:
		key := new(Type_Info); key^ = classify_type(t.key)
		val := new(Type_Info); val^ = classify_type(t.value)
		return {
			kind = .Map,
			lua_annotation = tprintf("table<%s, %s>", key.lua_annotation, val.lua_annotation),
			odin_type_name = tprintf("map[{}]{}", key.odin_type_name, val.odin_type_name),
			key = key,
			value = val,
		}
	case ^ast.Pointer_Type:
		elem := new(Type_Info)
		elem^ = classify_type(t.elem)
		return {
			kind = .Pointer,
			lua_annotation = "userdata",
			odin_type_name = tprintf("^{}", elem.odin_type_name),
			elem = elem,
		}
	case ^ast.Comp_Lit:
		return classify_type(t.type)
	case ^ast.Basic_Lit:
		#partial switch t.tok.kind {
		case .String:
			return {kind = .String, lua_annotation = "string", odin_type_name = "string"}
		case .Integer:
			return {kind = .Int, lua_annotation = "integer", odin_type_name = "int"}
		case .Float:
			return {kind = .Float, lua_annotation = "number", odin_type_name = "f64"}
		}
	}
	return Type_Info{kind = .Unsupported}
}

get_source_from_node :: proc(node: ^ast.Node) -> string {
	return file_contents[node.pos.offset:node.end.offset]
}

walk_ast :: proc(file: ^ast.File) {
	visit :: proc(v: ^ast.Visitor, node: ^ast.Node) -> ^ast.Visitor {
		process_node(node)
		return v
	}
	visitor := ast.Visitor {
		visit = visit,
	}
	ast.walk(&visitor, file)
}

// Get the name and arg / proc names and types.
process_proc :: proc(derived: ^ast.Value_Decl) {
	proc_lit, ok := derived.values[0].derived.(^ast.Proc_Lit)
	if !ok do return

	name_ident := derived.names[0].derived.(^ast.Ident)
	proc_name  := name_ident.name
	proc_description := Proc_Description {
		name = proc_name,
	}

	if proc_lit.type.params != nil {
		for param in proc_lit.type.params.list {
			// Need to iter names incase you have like proc(a, b: int) instead of proc(a: int, b: int).
			for name in param.names {
				append(
					&proc_description.args,
					Proc_Argument{name = get_source_from_node(name), type = classify_type(param.type)},
				)
			}
		}
	}

	if proc_lit.type.results != nil {
		for result in proc_lit.type.results.list {
			if len(result.names) > 0 {
				for name in result.names {
					append(
						&proc_description.results,
						Proc_Result{name = get_source_from_node(name), type = classify_type(result.type)},
					)
				}
			} else {
				append(&proc_description.results, Proc_Result{name = "", type = classify_type(result.type)})
			}
		}
	}
	target_procs[proc_name] = proc_description
}

// Get the name and field names/types of a struct.
process_struct :: proc(derived: ^ast.Value_Decl) {
	struct_lit, ok := derived.values[0].derived.(^ast.Struct_Type)
	if !ok do return

	if struct_lit.poly_params != nil do panic("cannot translate generic structs")
	name_ident  := derived.names[0].derived.(^ast.Ident)
	struct_name := name_ident.name
	struct_description := Struct_Description {
		name = struct_name,
	}

	for field in struct_lit.fields.list {
		for name in field.names {
			append(
				&struct_description.fields,
				Struct_Field{name = get_source_from_node(name), type = classify_type(field.type)},
			)
		}
	}
	target_structs[struct_name] = struct_description
}

process_global_var :: proc(derived: ^ast.Value_Decl, is_assignment := false) {
	// var_name := get_source_from_node(derived.names[0])
	// type     := is_assignment ? classify_type(derived.type)
}

// Finds and collects procedures & structs that were tagged for translation.
process_node :: proc(node: ^ast.Node) {
	if node == nil do return
	#partial switch decleration in node.derived {
	case ^ast.Value_Decl:
		if len(decleration.values) > 1 {
			println("Metaprogram cannot parse multipart assignments")
			return
		}
		// Variable declerations (i.e. NOT assignments) have no RHS values.
		if len(decleration.values) == 0 {
			if has_attribute(decleration.attributes[:], "lua_global") {
				name := get_source_from_node(decleration.names[0])
				target_global_variables[name] = Global_Variable {
					name = name,
					type = classify_type(decleration.type),
				}
			}
		} else {
			#partial switch value_type in decleration.values[0].derived {
			case ^ast.Proc_Lit:
				if !has_attribute(decleration.attributes[:], "lua_proc") do return
				process_proc(decleration)
			case ^ast.Struct_Type:
				if !has_attribute(decleration.attributes[:], "lua_data") do return
				process_struct(decleration)
			// This is a catch all that will catch global varialbe asisgnment statements, unfortunatley
			// I think it will also catch normal assignments, so you could technically expose some local variable
			// into Luas global namespace if you tag them with @lua_global which would cause issues.
			// Something to look at later...
			case:
				if has_attribute(decleration.attributes[:], "lua_global") {
					name := get_source_from_node(decleration.names[0])
					target_global_variables[name] = Global_Variable {
						name = name,
						type = classify_type(decleration.values[0]),
					}
				}
			}
		}
	}
}

has_attribute :: proc(attributes: []^ast.Attribute, name: string) -> bool {
	for attribute in attributes {
		for elem in attribute.elems {
			if ident, ok := elem.derived.(^ast.Ident); ok && ident.name == name {
				return true
			}
		}
	}
	return false
}

// Writes into LSP file for LSP support of exported structs / types.
write_out_lua_struct :: proc(file: ^os.File, struct_info: Struct_Description) {
	os.write_string(file, tprintfln("---@class {}", struct_info.name))
	for field in struct_info.fields {
		os.write_string(file, tprintfln("---@field {}	{}", field.name, field.type.lua_annotation))
	}
	os.write_string(file, "\n")
}

// Writes into LSP file for LSP support of exported functions.
write_out_lua_proc :: proc(file: ^os.File, proc_info: Proc_Description) {
	for arg in proc_info.args {
		os.write_string(file, tprintfln("---@param {} {}", arg.name, arg.type.lua_annotation))
	}

	if len(proc_info.results) > 0 {
		os.write_string(file, tprintf("---@return "))
		for result, i in proc_info.results {
			os.write_string(file, tprintf("{}", result.type.lua_annotation))
			if i != len(proc_info.results) - 1 {
				os.write_string(file, tprintf(", "))
			} else {
				os.write_string(file, "\n")
			}
		}
	}

	os.write_string(file, tprintf("function {}(", proc_info.name))
	for arg, i in proc_info.args {
		os.write_string(file, tprintf("{}", arg.name))
		if i != len(proc_info.args) - 1 {
			os.write_string(file, tprintf(", "))
		} else {
			os.write_string(file, ") end\n\n")
		}
	}
}

primitive_value_emit_push :: proc(f: ^os.File, type: Type_Info, value_expr: string) {
	#partial switch type.kind {
	case .Int:
		os.write_string(f, tprintf("lua.pushinteger(L, lua.Integer({}))\n", value_expr))
	case .Float:
		os.write_string(f, tprintf("lua.pushnumber(L, lua.Number({}))\n", value_expr))
	case .Bool:
		os.write_string(f, tprintf("lua.pushboolean(L, b32({}))\n", value_expr))
	case .String:
		os.write_string(
			f,
			tprintf("lua.pushlstring(L, cstring(raw_data({})), uint(len({})))\n", value_expr, value_expr),
		)
	case .Pointer:
		os.write_string(f, tprintf("lua.pushlightuserdata(L, {})\n", value_expr))
	case .Unsupported:
		panic("Trying to writeout fixed-array but the type of the elems was .Unsupported :(")
	case:
		panic(tprintf("ahhhh shiet. {}", type))
	}
}

// Returns a string expression for reading a primitive value from the Lua stack.
// Only valid for primitive types use emit_read_into for complex types.
primitive_value_emit_read :: proc(type: Type_Info, stack_pos: string) -> string {
	#partial switch type.kind {
	case .Int:
		return tprintf("{}(lua.L_checkinteger(L, {}))", type.odin_type_name, stack_pos)
	case .Float:
		return tprintf("{}(lua.L_checknumber(L, {}))", type.odin_type_name, stack_pos)
	case .Bool:
		return tprintf("{}(lua.toboolean(L, {}))", type.odin_type_name, stack_pos)
	case .String:
		return tprintf("strings.clone(string(lua.tostring(L, {})))", stack_pos)
	case .Pointer:
		return tprintf("({})(lua.touserdata(L, {}))", type.odin_type_name, stack_pos)
	case:
		panic(tprintf("primitive_value_emit_read called on non-primitive type: {}", type.kind))
	}
}

// Emits statements that push a value of any type onto the Lua stack.
// Symmetrical with emit_read_into.
// addressable: false for proc return values arrays/maps fall back to copying
// since they live on the Odin call stack and the pointer would dangle after return.
emit_lua_write_value :: proc(f: ^os.File, type: Type_Info, value_expr: string, addressable := true) {
	#partial switch type.kind {
	case .Int, .Float, .Bool, .String, .Pointer:
		primitive_value_emit_push(f, type, value_expr)
	case .Fixed_Array, .Dynamic_Array:
		if !addressable {
			os.write_string(f, tprintf("lua.createtable(L, i32(len({})), 0)\n", value_expr))
			os.write_string(f, tprintf("for _val, _idx in {} {{\n", value_expr))
			primitive_value_emit_push(f, type.elem^, "_val")
			os.write_string(f, "lua.rawseti(L, -2, i32(_idx) + 1)\n}\n")
			return
		}
		proxy_name := type_to_proxy_name(type)
		os.write_string(
			f,
			tprintf("(^^{})(lua.newuserdata(L, size_of(rawptr)))^ = &{}\n", type.odin_type_name, value_expr),
		)
		os.write_string(f, tprintf("lua.L_getmetatable(L, \"{}\")\n", proxy_name))
		os.write_string(f, "lua.setmetatable(L, -2)\n")
	case .Map:
		if !addressable {
			os.write_string(f, "lua.newtable(L)\n")
			os.write_string(f, tprintf("for _k, _v in {} {{\n", value_expr))
			primitive_value_emit_push(f, type.key^, "_k")
			primitive_value_emit_push(f, type.value^, "_v")
			os.write_string(f, "lua.rawset(L, -3)\n}\n")
			return
		}
		proxy_name := type_to_proxy_name(type)
		os.write_string(
			f,
			tprintf("(^^{})(lua.newuserdata(L, size_of(rawptr)))^ = &{}\n", type.odin_type_name, value_expr),
		)
		os.write_string(f, tprintf("lua.L_getmetatable(L, \"{}\")\n", proxy_name))
		os.write_string(f, "lua.setmetatable(L, -2)\n")
	case .Struct:
		os.write_string(
			f,
			tprintf("(^^{})(lua.newuserdata(L, size_of(rawptr)))^ = &{}\n", type.odin_type_name, value_expr),
		)
		os.write_string(f, tprintf("lua.L_getmetatable(L, \"{}\")\n", type.lua_annotation))
		os.write_string(f, "lua.setmetatable(L, -2)\n")
	case .Unsupported:
		panic(tprintf("emit_push_value: unsupported type for value {}", value_expr))
	}
}

// Emits statements that read a value of any type from the Lua stack into a variable named dest_expr.
// stack_pos is a string like "3" or "-1" referring to the Lua stack index to read from.
emit_lua_read_value :: proc(f: ^os.File, type: Type_Info, dest_expr: string, stack_pos: string) {
	#partial switch type.kind {
	case .Int, .Float, .Bool, .String, .Pointer:
		os.write_string(f, tprintf("{} = {}\n", dest_expr, primitive_value_emit_read(type, stack_pos)))
	case .Fixed_Array:
		os.write_string(f, tprintf("for _i in 0..<len({}) {{\n", dest_expr))
		os.write_string(f, tprintf("lua.rawgeti(L, {}, lua.Integer(_i + 1))\n", stack_pos))
		os.write_string(f, tprintf("{}[_i] = {}\n", dest_expr, primitive_value_emit_read(type.elem^, "-1")))
		os.write_string(f, "lua.pop(L, 1)\n}\n")
	case .Dynamic_Array:
		os.write_string(f, tprintf("clear(&{})\n", dest_expr))
		os.write_string(f, tprintf("for _i in 0..<int(lua.objlen(L, {})) {{\n", stack_pos))
		os.write_string(f, tprintf("lua.rawgeti(L, {}, lua.Integer(_i + 1))\n", stack_pos))
		os.write_string(f, tprintf("append(&{}, {})\n", dest_expr, primitive_value_emit_read(type.elem^, "-1")))
		os.write_string(f, "lua.pop(L, 1)\n}\n")
	case .Map:
		os.write_string(f, tprintf("clear(&{})\n", dest_expr))
		os.write_string(f, tprintf("lua.pushnil(L)\nfor lua.next(L, {}) != 0 {{\n", stack_pos))
		os.write_string(
			f,
			tprintf(
				"{}[{}] = {}\n",
				dest_expr,
				primitive_value_emit_read(type.key^, "-2"),
				primitive_value_emit_read(type.value^, "-1"),
			),
		)
		os.write_string(f, "lua.pop(L, 1)\n}\n")
	case .Struct:
	// struct fields are accessed via their own metatable � no bulk read needed
	case .Unsupported:
		panic(tprintf("emit_read_into: unsupported type for dest {}", dest_expr))
	}
}

write_struct_metatable_index :: proc(f: ^os.File, struct_info: Struct_Description) {
	write_struct :: proc(f: ^os.File, struct_info: Struct_Description) {
		for field in struct_info.fields {
			os.write_string(f, tprintf("case \"{}\":\n", field.name))
			#partial switch field.type.kind {
			case .Unsupported:
				panic("Maybe this should of happened ? maybe it should not have ? not sure, we panic :)")
			case:
				emit_lua_write_value(f, field.type, tprintf("s.{}", field.name))
			}
		}
	}

	os.write_strings(f, tprintf("lua_{}_index :: proc \"c\" (L: ^lua.State) -> i32 ", struct_info.name), "{\n")
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintfln("s := (^^{})(lua.touserdata(L, 1))^", struct_info.name))
	os.write_string(f, "key := string(lua.L_checkstring(L, 2))\n")
	os.write_string(f, "switch key {\n")

	write_struct(f, struct_info)

	os.write_string(f, "case:\nlua.pushnil(L)\n")
	os.write_string(f, "}\n")
	os.write_string(f, "return 1\n}\n")
}

write_struct_metatable_newindex :: proc(f: ^os.File, struct_info: Struct_Description) {
	write_struct :: proc(f: ^os.File, struct_info: Struct_Description) {
		for field in struct_info.fields {
			os.write_string(f, tprintf("case \"{}\":\n", field.name))
			#partial switch field.type.kind {
			case .Struct:
			// No-op � writes go through the child's own __newindex metatable
			case .Unsupported:
				panic("Unsupported type in newindex generation")
			case:
				emit_lua_read_value(f, field.type, tprintf("s.{}", field.name), "3")
			}
		}
	}

	setup :: proc(f: ^os.File, struct_info: Struct_Description) {
		os.write_strings(f, tprintf("lua_{}_newindex :: proc \"c\" (L: ^lua.State) -> i32 ", struct_info.name), "{\n")
		os.write_string(f, "context = app.lua_odin_context\n")
		os.write_string(f, tprintfln("s := (^^{})(lua.touserdata(L, 1))^", struct_info.name))
		os.write_string(f, "key := string(lua.L_checkstring(L, 2))\n")
		os.write_string(f, "switch key {\n")
	}

	setup(f, struct_info)
	write_struct(f, struct_info)

	os.write_string(f, "}\n")
	os.write_string(f, "return 0\n}\n")
}

write_out_odin_ffi_proc :: proc(file: ^os.File, proc_info: Proc_Description) {
	os.write_string(file, tprintf("lua_{} :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proc_info.name))
	os.write_string(file, "context = app.lua_odin_context\n")

	for arg, i in proc_info.args {
		#partial switch arg.type.kind {
		case .Int, .Float, .Bool, .String, .Pointer:
			os.write_string(
				file,
				tprintf("{} := {}\n", arg.name, primitive_value_emit_read(arg.type, tprintf("{}", i + 1))),
			)
		case:
			// complex types: declare zero value first, then fill via emit_read_into
			os.write_string(file, tprintf("{}: {}\n", arg.name, arg.type.odin_type_name))
			emit_lua_read_value(file, arg.type, arg.name, tprintf("{}", i + 1))
		}
	}

	if len(proc_info.results) == 0 {
		os.write_string(file, tprintf("{}(", proc_info.name))
	} else if len(proc_info.results) == 1 {
		os.write_string(file, tprintf("_result0 := {}(", proc_info.name))
	} else {
		for i in 0 ..< len(proc_info.results) {
			os.write_string(file, tprintf("_result{}{}", i, i < len(proc_info.results) - 1 ? ", " : ""))
		}
		os.write_string(file, tprintf(" := {}(", proc_info.name))
	}
	for arg, i in proc_info.args {
		os.write_string(file, tprintf("{}{}", arg.name, i < len(proc_info.args) - 1 ? ", " : ""))
	}
	os.write_string(file, ")\n")

	for result, i in proc_info.results {
		emit_lua_write_value(file, result.type, tprintf("_result{}", i), false)
	}

	os.write_string(file, tprintf("return {}\n}}\n", len(proc_info.results)))
}

write_proc_registrations :: proc(f: ^os.File) {
	os.write_string(f, "lua_register_all :: proc(L: ^lua.State) {\n")
	for proc_name, _ in target_procs {
		os.write_string(f, tprintf("\tlua.register(L, \"{}\", lua_{})\n", proc_name, proc_name))
	}
	os.write_string(f, "}\n")
}

// If any struct has a child struct inside it, that child struct must be registered first.
write_metatable_registrations :: proc(f: ^os.File, struct_info: Struct_Description) {
	if struct_info.name in already_registered_structs do return
	// Need to register nested child structs before registering parent struct.
	for field in struct_info.fields {
		if field.type.kind == .Struct {
			write_metatable_registrations(f, target_structs[field.type.lua_annotation])
			already_registered_structs[field.type.odin_type_name] = true
		}
	}
	os.write_string(f, tprintfln("lua.L_newmetatable(L, \"{}\")", struct_info.name))
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_index)", struct_info.name))
	os.write_string(f, "lua.setfield(L, -2, \"__index\")\n")
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_newindex)", struct_info.name))
	os.write_string(f, "lua.setfield(L, -2, \"__newindex\")\n")
	os.write_string(f, "lua.pop(L, 1) // pop the metatable off the stack.\n\n")
}

write_global_var_accessors :: proc(f: ^os.File) {
	// __index
	os.write_string(f, "lua_globals_index :: proc \"c\" (L: ^lua.State) -> i32 {\n")
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, "key := string(lua.L_checkstring(L, 2))\n")
	os.write_string(f, "switch key {\n")
	for _, gvar in target_global_variables {
		os.write_string(f, tprintf("case \"{}\":\n", gvar.name))
		emit_lua_write_value(f, gvar.type, gvar.name)
	}
	os.write_string(f, "case:\nlua.pushnil(L)\n")
	os.write_string(f, "}\n")
	os.write_string(f, "return 1\n}\n")

	// __newindex
	os.write_string(f, "lua_globals_newindex :: proc \"c\" (L: ^lua.State) -> i32 {\n")
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, "key := string(lua.L_checkstring(L, 2))\n")
	os.write_string(f, "switch key {\n")
	for _, gvar in target_global_variables {
		os.write_string(f, tprintf("case \"{}\":\n", gvar.name))
		emit_lua_read_value(f, gvar.type, gvar.name, "3")
	}
	os.write_string(f, "}\n")
	os.write_string(f, "return 0\n}\n")

	// Register on _G
	os.write_string(f, "register_globals :: proc(L: ^lua.State) {\n")
	os.write_string(f, "lua.pushvalue(L, lua.GLOBALSINDEX)\n")
	os.write_string(f, "lua.newtable(L)\n")
	os.write_string(f, "lua.pushcfunction(L, lua_globals_index)\n")
	os.write_string(f, "lua.setfield(L, -2, \"__index\")\n")
	os.write_string(f, "lua.pushcfunction(L, lua_globals_newindex)\n")
	os.write_string(f, "lua.setfield(L, -2, \"__newindex\")\n")
	os.write_string(f, "lua.setmetatable(L, -2)\n")
	os.write_string(f, "lua.pop(L, 1)\n}\n")
}

sanitize_type_name :: proc(name: string) -> string {
	ptr_count := 0
	for c in name {
		if c == '^' {
			ptr_count += 1
		} else {
			break
		}
	}

	base := name[ptr_count:]
	if ptr_count == 0 {
		return base
	}

	sb := str.builder_make(context.allocator)
	str.write_string(&sb, base)
	for _ in 0 ..< ptr_count {
		str.write_string(&sb, "_ptr")
	}
	return str.to_string(sb)
}

type_to_proxy_name :: proc(type: Type_Info) -> string {
	switch type.kind {
	case .Fixed_Array:
		inner := type.odin_type_name[1:]
		idx   := str.index_byte(inner, ']')
		n     := inner[:idx]
		elem  := sanitize_type_name(inner[idx + 1:])
		return tprintf("farr_{}_{}", n, elem)
	case .Dynamic_Array:
		return tprintf("dyn_{}", sanitize_type_name(type.elem.odin_type_name))
	case .Map:
		return tprintf(
			"map_{}_{}",
			sanitize_type_name(type.key.odin_type_name),
			sanitize_type_name(type.value.odin_type_name),
		)
	case .Int, .Float, .Bool, .String, .Pointer, .Struct, .Unsupported:
		panic("type_to_proxy_name called on non-compound type")
	}
	return ""
}

collect_proxy_types :: proc() {
	register :: proc(type: Type_Info) {
		#partial switch type.kind {
		case .Fixed_Array, .Dynamic_Array, .Map:
			target_proxy_types[type_to_proxy_name(type)] = type
		}
	}
	for _, s in target_structs {
		for field in s.fields {register(field.type)}
	}
	for _, gvar in target_global_variables {
		register(gvar.type)
	}
	for _, p in target_procs {
		for arg in p.args {register(arg.type)}
		for res in p.results {register(res.type)}
	}
}

write_array_proxy_handlers :: proc(f: ^os.File, proxy_name: string, type: Type_Info) {
	// __index
	os.write_string(f, tprintf("lua_{}_index :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("arr := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, "idx := int(lua.L_checkinteger(L, 2)) - 1\n")
	os.write_string(f, "if idx < 0 || idx >= len(arr^) { lua.pushnil(L); return 1 }\n")
	primitive_value_emit_push(f, type.elem^, "arr^[idx]")
	os.write_string(f, "return 1\n}\n")
	// __newindex
	os.write_string(f, tprintf("lua_{}_newindex :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("arr := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, "idx := int(lua.L_checkinteger(L, 2)) - 1\n")
	os.write_string(f, "if idx < 0 || idx >= len(arr^) { return 0 }\n")
	os.write_string(f, tprintf("arr^[idx] = {}\n", primitive_value_emit_read(type.elem^, "3")))
	os.write_string(f, "return 0\n}\n")
	// __len
	os.write_string(f, tprintf("lua_{}_len :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("arr := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, "lua.pushinteger(L, lua.Integer(len(arr^)))\n")
	os.write_string(f, "return 1\n}\n")
}

write_map_proxy_handlers :: proc(f: ^os.File, proxy_name: string, type: Type_Info) {
	// __index
	os.write_string(f, tprintf("lua_{}_index :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("m := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, tprintf("key := {}\n", primitive_value_emit_read(type.key^, "2")))
	os.write_string(f, "val, ok := m^[key]\n")
	os.write_string(f, "if !ok { lua.pushnil(L); return 1 }\n")
	primitive_value_emit_push(f, type.value^, "val")
	os.write_string(f, "return 1\n}\n")
	// __newindex
	os.write_string(f, tprintf("lua_{}_newindex :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("m := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, tprintf("key := {}\n", primitive_value_emit_read(type.key^, "2")))
	os.write_string(f, tprintf("m^[key] = {}\n", primitive_value_emit_read(type.value^, "3")))
	os.write_string(f, "return 0\n}\n")
	// __len
	os.write_string(f, tprintf("lua_{}_len :: proc \"c\" (L: ^lua.State) -> i32 {{\n", proxy_name))
	os.write_string(f, "context = app.lua_odin_context\n")
	os.write_string(f, tprintf("m := (^^{})(lua.touserdata(L, 1))^\n", type.odin_type_name))
	os.write_string(f, "lua.pushinteger(L, lua.Integer(len(m^)))\n")
	os.write_string(f, "return 1\n}\n")
}

write_proxy_handlers :: proc(f: ^os.File, proxy_name: string, type: Type_Info) {
	switch type.kind {
	case .Fixed_Array, .Dynamic_Array:
		write_array_proxy_handlers(f, proxy_name, type)
	case .Map:
		write_map_proxy_handlers(f, proxy_name, type)
	case .Int, .Float, .Bool, .String, .Pointer, .Struct, .Unsupported:
		panic("write_proxy_handlers called on non-compound type")
	}
}

write_proxy_metatable_registration :: proc(f: ^os.File, proxy_name: string) {
	os.write_string(f, tprintfln("lua.L_newmetatable(L, \"{}\")", proxy_name))
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_index)", proxy_name))
	os.write_string(f, "lua.setfield(L, -2, \"__index\")\n")
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_newindex)", proxy_name))
	os.write_string(f, "lua.setfield(L, -2, \"__newindex\")\n")
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_len)", proxy_name))
	os.write_string(f, "lua.setfield(L, -2, \"__len\")\n")
	os.write_string(f, "lua.pop(L, 1)\n\n")
}

/*
Known limitations.

--------
Doing like:
var1 := 10
var2 := &var1

won't work because the metaprogram, as it's only doing 1 pass, doesn't know the type of var1. We could defer working out what var2 (and any & references)
point to until a second pass, at which point the type of the thing it points to will be known.
--------


--------
If you do something like:
var := some_package.Some_Struct. 
If some_package.Some_Struct isn't tagged, and therefore parsed by the metaprogram, then you won't get access to it's fields
from Lua. 

I think the solution here would be to actually traverse for the user and find the definition and create an associated metatable
just like we do for structs defined in the Odin file that's passed in. You could take this arbitrarilly deep, but you cannot 
proceed once you hit an opaque pointer in Odin; like you would if it's a rawptr representing a pointer to some data in a C lib.
--------


--------
All data needs to be from a single package. Metadata cannot reach into a package from which you import a struct from. 
In that case, the Lua bindings will just expose it as an opaque pointer that you can pass around, but you cannot reach into the fields
of that struct, nor read / write them.

Should be possible to implement this in the future, doing something like what OLS does to achieve 'go to definition', whenever we find a 
struct from another package.
--------
*/
