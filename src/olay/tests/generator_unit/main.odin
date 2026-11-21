package generator_unit_tests

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
		{"test_find_package_name_reads_first_package_line", test_find_package_name_reads_first_package_line},
		{"test_classify_type_handles_supported_forms", test_classify_type_handles_supported_forms},
		{"test_process_proc_collects_grouped_params_and_results", test_process_proc_collects_grouped_params_and_results},
		{"test_process_struct_collects_fields_and_types", test_process_struct_collects_fields_and_types},
		{"test_process_node_collects_only_tagged_declarations", test_process_node_collects_only_tagged_declarations},
		{"test_write_out_lua_proc_emits_annotations_and_signature", test_write_out_lua_proc_emits_annotations_and_signature},
		{"test_emit_lua_value_helpers_write_expected_snippets", test_emit_lua_value_helpers_write_expected_snippets},
		{"test_write_metatable_registrations_orders_nested_structs", test_write_metatable_registrations_orders_nested_structs},
		{"test_write_global_var_accessors_emits_switch_cases", test_write_global_var_accessors_emits_switch_cases},
		{"test_generate_creates_expected_artifacts", test_generate_creates_expected_artifacts},
	}

	run_count := 0
	fail_count := 0
	for test in tests {
		if !should_run_test(test.name) do continue
		run_count += 1
		if !run_named_test(test) {
			fail_count += 1
		}
	}

	if run_count == 0 {
		fmt.eprintln("No generator unit tests matched the provided filters.")
		os.exit(1)
	}

	if fail_count > 0 {
		fmt.eprintfln("{} of {} generator unit tests failed.", fail_count, run_count)
		os.exit(1)
	}

	fmt.printfln("All {} generator unit tests passed.", run_count)
}
