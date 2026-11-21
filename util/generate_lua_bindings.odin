package util

import "core:fmt"
import "core:os"


main :: proc() {
	if len(os.args) != 4 {
		fmt.println("Usage Error !")
		fmt.println("Correct Usage: ./generate-bindings.exe <in_dir_path> <lua_out_file.lua> <odin_out_file.odin>")
	}

	dir       := os.args[1]
	lua_path  := os.args[2]
	odin_path := os.args[3]
	generate(dir, lua_path, odin_path)
}
