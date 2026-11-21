package lua_bindings_tests

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:testing"

Local_Test :: struct {
	name: string,
	run:  proc(^testing.T),
}

test_logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	t := (^testing.T)(logger_data)
	if level >= .Error {
		t.error_count += 1
		fmt.eprintfln("%s (%v:%v)", text, location.file_path, location.line)
	}
}

should_include_known_failures :: proc() -> bool {
	for arg in os.args[1:] {
		if arg == "-include-known-failures" {
			return true
		}
	}
	return false
}

is_known_failing_test :: proc(name: string) -> (known: bool, reason: string) {
	return false, ""
}

should_run_test :: proc(name: string) -> bool {
	filters := 0
	for arg in os.args[1:] {
		if strings.starts_with(arg, "-") do continue
		filters += 1
		if strings.contains(name, arg) {
			return true
		}
	}
	return filters == 0
}

run_named_test :: proc(test: Local_Test) -> bool {
	if !should_run_test(test.name) do return true

	fmt.printfln("RUN  {}", test.name)
	t: testing.T
	context.logger = {
		procedure = test_logger_proc,
		data = &t,
		lowest_level = .Debug,
	}

	test.run(&t)

	if testing.failed(&t) {
		fmt.printfln("FAIL {}", test.name)
		return false
	}

	fmt.printfln("PASS {}", test.name)
	return true
}

main :: proc() {
	tests := []Local_Test{
		{"test_global_int", test_global_int},
		{"test_global_i32", test_global_i32},
		{"test_global_f32", test_global_f32},
		{"test_global_f64", test_global_f64},
		{"test_global_bool", test_global_bool},
		{"test_global_string", test_global_string},
		{"test_global_rawptr", test_global_rawptr},
		{"test_global_init_values", test_global_init_values},
		{"test_global_fixed_array", test_global_fixed_array},
		{"test_global_dynamic_array", test_global_dynamic_array},
		{"test_global_map", test_global_map},
		{"test_struct_simple_scalars", test_struct_simple_scalars},
		{"test_struct_arrays", test_struct_arrays},
		{"test_struct_maps", test_struct_maps},
		{"test_struct_nested", test_struct_nested},
		{"test_struct_deep_nest", test_struct_deep_nest},
		{"test_struct_pointer_fields", test_struct_pointer_fields},
		{"test_proc_add", test_proc_add},
		{"test_proc_concat", test_proc_concat},
		{"test_proc_arr_len", test_proc_arr_len},
		{"test_proc_map_passthrough", test_proc_map_passthrough},
		{"test_proc_multi_ret", test_proc_multi_ret},
		{"test_proc_no_args", test_proc_no_args},
		{"test_cross_boundary_stress", test_cross_boundary_stress},
	}

	run_count := 0
	fail_count := 0
	skip_count := 0
	for test in tests {
		if !should_run_test(test.name) do continue
		if known, reason := is_known_failing_test(test.name); known && !should_include_known_failures() {
			skip_count += 1
			fmt.printfln("SKIP {} ({})", test.name, reason)
			continue
		}
		run_count += 1
		if !run_named_test(test) {
			fail_count += 1
		}
	}

	if run_count == 0 {
		fmt.eprintln("No Lua binding tests matched the provided filters.")
		os.exit(1)
	}

	if fail_count > 0 {
		fmt.eprintfln("{} of {} Lua binding tests failed. {} skipped.", fail_count, run_count, skip_count)
		os.exit(1)
	}

	fmt.printfln("All {} Lua binding tests passed. {} skipped.", run_count, skip_count)
}
