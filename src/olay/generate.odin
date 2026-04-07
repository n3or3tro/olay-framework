package olay

import "core:fmt"
import "core:odin"
import "core:odin/ast"
import "core:odin/parser"
import "core:os"
import "core:strings"
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
file_contents: string

main :: proc() {
	generate({"./specific_app_stuff.odin"})
	// We're relying on global variables, so after generate() is called we assume
	// it succeeded and we can just read the results from our global data.

	for key, p in target_procs {
		printfln("{}: {}", key, p.results[:])
	}

	odin_file, oerr := os.open("./test_lua_ffi_bindings.odin", {.Read, .Write, .Create})
	assert(oerr == os.General_Error.None)

	lua_file, lerr := os.open("./test_struct_info.lua", {.Read, .Write, .Create})
	assert(lerr == os.General_Error.None)

	os.write_string(odin_file, "package olay\n")
	os.write_string(odin_file, "import lua \"vendor:lua/5.1\"\n")
	os.write_string(odin_file, "import \"core:strings\"\n")


	for struct_name, struct_info in target_structs {
		write_struct_metatable_index(odin_file, struct_info)
		write_struct_metatable_newindex(odin_file, struct_info)
	}

	os.write_string(odin_file, "register_metatables :: proc(L: ^lua.State) {\n")
	for struct_name, struct_info in target_structs {
		write_metatable_registrations(odin_file, struct_info)
	}
	os.write_string(odin_file, "}\n")


	for struct_name, struct_info in target_structs {
		write_out_lua_struct(lua_file, struct_info)
	}

	for proc_name, proc_info in target_procs {
		write_out_odin_ffi_proc(odin_file, proc_info)
	}
}

generate :: proc(paths: []string) -> (ok: bool, err: string) {
	path := paths[0]

	data, ferr := os.read_entire_file_from_path(path, context.temp_allocator)
	if ferr != os.General_Error.None {
		printfln("path: {}\nerr: {}", path, ferr)
		return false, fmt.tprintf("{}", ferr)
	}
	file_contents = strings.clone_from_bytes(data, context.temp_allocator)

	p: parser.Parser
	file: ast.File
	file.src      = file_contents
	file.fullpath = path
	file.derived  = &file
	parser.parse_file(&p, &file)

	walk_ast(&file)

	return true, ""
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
		return {kind = .Dynamic_Array, lua_annotation = tprintf("%s[]", elem.lua_annotation), elem = elem}
	case ^ast.Array_Type:
		elem := new(Type_Info)
		elem^ = classify_type(t.elem)
		return {kind = .Fixed_Array, lua_annotation = tprintf("%s[]", elem.lua_annotation), elem = elem}
	case ^ast.Map_Type:
		key := new(Type_Info); key^ = classify_type(t.key)
		val := new(Type_Info); val^ = classify_type(t.value)
		return {
			kind = .Map,
			lua_annotation = tprintf("table<%s, %s>", key.lua_annotation, val.lua_annotation),
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

// Finds and collects funcions & structs that were tagged for translation.
process_node :: proc(node: ^ast.Node) {
	if node == nil do return
	#partial switch decleration in node.derived {
	case ^ast.Value_Decl:
		if len(decleration.values) != 1 {
			panic("Metaprogram cannot parse multipart assignments")
		}
		#partial switch value_type in decleration.values[0].derived {
		case ^ast.Proc_Lit:
			if !has_attribute(decleration.attributes[:], "lua_proc") do return
			process_proc(decleration)
		case ^ast.Struct_Type:
			if !has_attribute(decleration.attributes[:], "lua_data") do return
			println("found tagged struct")
			process_struct(decleration)
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
		panic("ahhhh shiet.")
	}
}

// Returns a string expression that reads a value of the given type from the Lua stack.
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

write_struct_metatable_index :: proc(f: ^os.File, struct_info: Struct_Description) {
	// Pulled this out so we can call it recursively if we find a struct inside a struct.
	write_struct :: proc(f: ^os.File, struct_info: Struct_Description) {
		for field in struct_info.fields {
			os.write_string(f, tprintf("case \"{}\":\n", field.name))
			#partial switch field.type.kind {
			case .Int, .Float, .Bool, .String, .Pointer:
				write_out_primitive_struct_field(f, field)
			case .Fixed_Array, .Dynamic_Array:
				os.write_string(f, tprintfln("lua.createtable(L, i32(len(s.{})), 0)", field.name))
				os.write_strings(f, tprintf("for val, idx in s.{}", field.name), "{\n")
				primitive_value_emit_push(f, field.type.elem^, "val")
				os.write_string(f, "lua.rawseti(L, -2, i32(idx) + 1)\n")
				os.write_string(f, "}\n")
			case .Map:
				os.write_string(f, "lua.newtable(L)\n")
				os.write_string(f, tprintf("for key, value in s.{} {{\n", field.name))
				primitive_value_emit_push(f, field.type.key^, "key")
				primitive_value_emit_push(f, field.type.value^, "value")
				os.write_string(f, "lua.rawset(L, -3)\n")
				os.write_string(f, "}\n")
			case .Struct:
				os.write_string(f, tprintfln("lua.pushlightuserdata(L, &s.{})", field.name))
				os.write_string(f, tprintfln("lua.L_getmetatable(L, \"{}\")", field.type.lua_annotation))
				os.write_string(f, "lua.setmetatable(L, -2)\n")
			case .Unsupported:
				panic("Maybe this should of happened ? maybe it should not have ? not sure, we panic :)")
			}
		}
	}


	write_out_primitive_struct_field :: proc(f: ^os.File, field: Struct_Field) {
		primitive_value_emit_push(f, field.type, tprintf("s.{}", field.name))
	}

	setup :: proc(f: ^os.File, struct_info: Struct_Description) {
		os.write_strings(f, tprintf("lua_{}_index :: proc \"c\" (L: ^lua.State) -> i32 ", struct_info.name), "{\n")
		os.write_string(f, "context = app.lua_odin_context\n")
		os.write_string(f, tprintfln("s := (^{})(lua.touserdata(L, 1))", struct_info.name))
		os.write_string(f, "key := string(lua.L_checkstring(L, 2))\n")
		os.write_string(f, "switch key {\n")
	}

	setup(f, struct_info)
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
			case .Int, .Float, .Bool, .String, .Pointer:
				write_primitive_struct_field(f, field)
			case .Fixed_Array:
				os.write_string(f, "n := int(lua.objlen(L, 3))\n")
				os.write_string(f, "for i in 0..<n {\n")
				os.write_string(f, "lua.rawgeti(L, 3, lua.Integer(i + 1))\n")
				os.write_string(
					f,
					tprintf("s.{}[i] = {}\n", field.name, primitive_value_emit_read(field.type.elem^, "-1")),
				)
				os.write_string(f, "lua.pop(L, 1)\n")
				os.write_string(f, "}\n")
			case .Dynamic_Array:
				os.write_string(f, tprintfln("clear(&s.{})", field.name))
				os.write_string(f, "n := int(lua.objlen(L, 3))\n")
				os.write_string(f, "for i in 0..<n {\n")
				os.write_string(f, "lua.rawgeti(L, 3, lua.Integer(i + 1))\n")
				os.write_string(
					f,
					tprintf("append(&s.{}, {})\n", field.name, primitive_value_emit_read(field.type.elem^, "-1")),
				)
				os.write_string(f, "lua.pop(L, 1)\n")
				os.write_string(f, "}\n")
			case .Map:
				os.write_string(f, tprintfln("delete(s.{})", field.name))
				os.write_string(f, "lua.pushnil(L)\n")
				os.write_string(f, "for lua.next(L, 3) != 0 {\n")
				os.write_string(
					f,
					tprintf(
						"s.{}[{}] = {}\n",
						field.name,
						primitive_value_emit_read(field.type.key^, "-2"),
						primitive_value_emit_read(field.type.value^, "-1"),
					),
				)
				os.write_string(f, "lua.pop(L, 1)\n")
				os.write_string(f, "}\n")
			case .Struct:
			// No-op — writes go through the child's own __newindex metatable
			case .Unsupported:
				panic("Unsupported type in newindex generation")
			}
		}
	}


	write_primitive_struct_field :: proc(f: ^os.File, field: Struct_Field) {
		os.write_string(f, tprintf("s.{} = {}\n", field.name, primitive_value_emit_read(field.type, "3")))
	}

	setup :: proc(f: ^os.File, struct_info: Struct_Description) {
		os.write_strings(f, tprintf("lua_{}_newindex :: proc \"c\" (L: ^lua.State) -> i32 ", struct_info.name), "{\n")
		os.write_string(f, "context = app.lua_odin_context\n")
		os.write_string(f, tprintfln("s := (^{})(lua.touserdata(L, 1))", struct_info.name))
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
		os.write_string(
			file,
			tprintf("{} := {}\n", arg.name, primitive_value_emit_read(arg.type, tprintf("{}", i + 1))),
		)
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
		primitive_value_emit_push(file, result.type, tprintf("_result{}", i))
	}

	os.write_string(file, tprintf("return {}\n}}\n", len(proc_info.results)))
}

write_proc_registrations :: proc(f: ^os.File) {
	os.write_string(f, "lua_register_all :: proc(L: ^lua.State) {\n")
	os.write_string(f, "}\n")
	for proc_name, _ in target_procs {
		os.write_string(f, tprintf("lua.register(L, \"{}\", lua_{})", proc_name, proc_name))
	}
}

// If any struct has a child struct inside it, that child struct must be registered first.
write_metatable_registrations :: proc(f: ^os.File, struct_info: Struct_Description) {
	// Need to register nested child structs before registering parent struct.
	for field in struct_info.fields {
		if field.type.kind == .Struct {
			write_metatable_registrations(f, target_structs[field.type.lua_annotation])
		}
	}
	os.write_string(f, tprintfln("lua.L_newmetatable(L, \"{}\")", struct_info.name))
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_index)", struct_info.name))
	os.write_string(f, "lua.setfield(L, -2, \"__index\")\n")
	os.write_string(f, tprintfln("lua.pushcfunction(L, lua_{}_newindex)\n", struct_info.name))
	os.write_string(f, "lua.setfield(L, -2, \"__newindex\")\n")
	os.write_string(f, "lua.pop(L, 1) // pop the metatable off the stack.\n")
}
