package olay

/*
This is just an example file with some bogus structs and function to see how well
we can use our metaprogram to generate lua bindings for them.
*/

// bogus_global_state: Bogus_State

@(lua_data)
Internal_Struct :: struct {
	field1: int,
	field2: int,
}

@(lua_data)
Bogus_State :: struct {
	val_name:      string,
	val_float:     f32,
	val_int:       int,
	val_fixed_arr: [24]int,
	val_dict:      map[string]int,
	val_dict2:     map[f64]^int,
	val_dyn_arr:   [dynamic]string,
	val_struct:    Internal_Struct,
}

@(lua_proc)
func_a :: proc(a: int, b: string, c: [dynamic]int) -> (named_return_val: f64) {
	printfln("hello from func-a")
}

@(lua_proc)
func_b :: proc(a, b: string) -> int {
	printfln("hello from func-a")
}

@(lua_proc)
func_c :: proc(a: map[string]int, b: map[rawptr]string) -> map[string]f64 {
	printfln("hello from func-a")
	return {}
}
