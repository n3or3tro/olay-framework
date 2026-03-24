/*
This file contains all the relevant things a user would need if they wanted to use the olay in a standalone GUI 
desktop (and hopefully in the future, mobile applicaiton).

Ideally, nothing in this file should be compulsary for a user wanting to embed Olay into an existing application.
*/

package olay
import "core:fmt"
import "core:sys/windows"
import "core:time"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

App_SDL2 :: struct {
	using base:             App_Base,
	window:                 ^sdl.Window,
	windows_com_handle:     windows.HRESULT,
	win32_hwnd:             windows.HWND,
	win32_original_wndproc: windows.WNDPROC,
}

@(export)
app_create :: proc() -> ^App {
	if typeid_of(App) == typeid_of(int) {
		panicf("The only platform we support right now is SDL2.")
	}
	app = new(App)
	return app
}

@(export)
app_update :: proc() -> (all_good: bool) {
	if ui_state.frames_since_sleep >= 5 do ui_state.frames_since_sleep = 0
	ui_state.event_wait_timeout = 1_000_000_000
	dt_ms := (f64(time.now()._nsec) / 1_000_000) - ui_state.prev_frame_start_ms
	dt_ms  = min(dt_ms, 100)
	ui_state.prev_frame_start_ms = f64(time.now()._nsec) / 1_000_000
	animation_update_all(dt_ms / 1_000)
	start := time.now()._nsec
	// if register_resize() {
	// 	printfln("changing screen res to : {} x {}", app.wx, app.wy)
	// 	set_shader_vec2(ui_state.quad_shader_program, "screen_res", {f32(app.wx), f32(app.wy)})
	// }
	event: sdl.Event
	reset_mouse_state()
	show_context_menu, exit := &ui_state.context_menu.active, false
	// Sleep until an event arrives and unblocks us.
	// Skip the blocking wait when inside the Windows modal resize loop -- the WM_TIMER
	// is driving our frames and we must not block here or the resize stalls.
	if !is_resizing &&
	((ui_state.frames_since_sleep == 0 && sdl.WaitEventTimeout(&event, i32(ui_state.event_wait_timeout * 1_000))) || ui_state.frame_num < 5)
	{
		exit = sdl2_handle_input(event, app.ui_state)
		if exit do return false
	}

	// Poll for any other events that arrived with the unblocking event.
	for sdl.PollEvent(&event) {
		exit = sdl2_handle_input(event, app.ui_state)
		if exit {
			return false
		}
	}

	root := frame_begin()
	create_ui()
	rect_render_data := end_frame(root.box, context.temp_allocator)

	if ui_state.frame_num > 0 {
		gl_render_ui_background_to_fbo(rect_render_data)
		gl_render_blur_pass()
		gl_render_ui(rect_render_data)
	}

	sdl.GL_SwapWindow(app.window)

	when MEM_PROFILE {
		total_bytes_allocated := 0
		for name, allocator in app.memory_profiler.tracking_allocators {
			printfln("{} allocated %.2f MB", name, f64(allocator.current_memory_allocated) / 1_000_000.0)
			total_bytes_allocated += int(allocator.current_memory_allocated)
		}

		for key, alloc_list in app.memory_profiler.allocations {
			sub_total := 0
			for alloc in alloc_list {
				sub_total += alloc.size
			}
			printfln("{} allocated %.2f MB", key, f64(sub_total) / 1_000_000)
			total_bytes_allocated += sub_total
		}
		println("total memory allocated this frame: {}\n ", f64(total_bytes_allocated) / 1_000_000.0)
	}

	// We do this here instead of inside 'handle_input' because handle_input runs at the start of the frame,
	// and this data must live till the end of the frame.
	if !ui_state.mouse.left_pressed {
		ui_state.dragged_box = nil
		// Might want to shrink it if we're dragging around huge data one time,
		// and then never again...
		clear(&ui_state.dropped_data)
	}

	reset_ui_state()
	free_all(context.temp_allocator)
	ui_state.frame_num      += 1
	ui_state.n_chars_stored = {}
	// Probably need to add more stuff to clear here.
	if ui_state.changed_ui_screen {
		ui_state.last_hot_box     = nil
		ui_state.last_active_box  = nil
		ui_state.last_clicked_box = nil
		ui_state.right_clicked_on = nil
		ui_state.dragged_box      = nil
		ui_state.mouse_down_on    = nil
		// This doesn't reclaim the memory the map used to store the values.
		// Just resets the map's metadata so that memory can be overwritten.
		clear(&ui_state.frame_signals)
	}

	end := time.now()._nsec
	total_frame_time_ns := f64(end - start)

	ui_state.frames_since_sleep += 1
	return true
}

@(export)
app_init :: proc(first_run := true) -> ^App {
	app.ui_state           = new(UI_State)
	ui_state               = app.ui_state
	ui_state.parents_stack = make([dynamic]^Box)

	init_ui_state(900, 400)

	font_init(&ui_state.font_state)
	icons_init(&ui_state.icon_state)

	app.running = true

	// This a per thread thing that will persist across hot reloads, so we set it up once only
	when ODIN_OS == .Windows {
		if first_run {
			hr := windows.CoInitializeEx(nil, windows.COINIT.APARTMENTTHREADED)
			if !windows.SUCCEEDED(hr) {
				panic("failed 1")
			}
			app.windows_com_handle = hr
		}
	}
	w, h: i32
	sdl.GL_GetDrawableSize(app.window, &w, &h)
	printfln("{}x{}", w, h)

	sdl.GetWindowSize(app.window, &w, &h)
	printfln("{}x{}", w, h)
	return app
}

@(export)
app_init_window :: proc() {
	sdl.Init({.EVENTS})
	window_flags := sdl.WINDOW_OPENGL | sdl.WINDOW_RESIZABLE | sdl.WINDOW_ALLOW_HIGHDPI
	app.window = sdl.CreateWindow(
		"n3or3tro-tracker",
		sdl.WINDOWPOS_UNDEFINED,
		sdl.WINDOWPOS_UNDEFINED,
		i32(WINDOW_WIDTH),
		i32(WINDOW_HEIGHT),
		window_flags,
	)
	if app.window == nil {
		panic("Failed to create window")
	}
	when ODIN_OS == .Windows {
		setup_custom_frame()
	}
}

@(export)
app_create_gl_context :: proc() {
	// Set OpenGL attributes after SDL initialization
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 4)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 1)
	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, gl.CONTEXT_CORE_PROFILE_BIT)
	sdl.GL_SetAttribute(.MULTISAMPLEBUFFERS, 1)
	sdl.GL_SetAttribute(.MULTISAMPLESAMPLES, 8)
	sdl.GL_SetAttribute(.ACCELERATED_VISUAL, 1)

	gl_context := sdl.GL_CreateContext(app.window)
	if gl_context == nil {
		panic("Failed to create OpenGL context")
	}
	sdl.GL_MakeCurrent(app.window, gl_context)

}

@(export)
app_load_gl_procs :: proc() {
	gl.load_up_to(4, 1, sdl.gl_set_proc_address)

	// Enable OpenGL settings
	gl.Hint(gl.LINE_SMOOTH_HINT, gl.NICEST)
	gl.Hint(gl.POLYGON_SMOOTH_HINT, gl.NICEST)
	gl.Enable(gl.LINE_SMOOTH)
	gl.Enable(gl.POLYGON_SMOOTH)
	gl.Enable(gl.MULTISAMPLE)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}


sdl2_handle_input :: proc(event: sdl.Event, ui_state: ^UI_State) -> (exit: bool) {
	// show_context_menu = ui_state.context_menu.active
	etype := event.type

	if etype == .QUIT {
		exit = true
	}

	if etype == .MOUSEMOTION {
		mouse_x, mouse_y: i32
		sdl.GetMouseState(&mouse_x, &mouse_y)
		x := int(event.motion.x)
		y := int(event.motion.y)
		// printfln("event.motion values: [{}, {}]", x, y)
		ui_state.mouse.pos.x = int(mouse_x)
		ui_state.mouse.pos.y = int(mouse_y)
		// printfln("GetMouseState values: [{}, {}]\n", app.mouse.pos.x, app.mouse.pos.y)
		if ([2]int{x, y} != ui_state.mouse.pos.xy) {
			println("fuaaaaaark ^^^^^^")
		}
	}

	// We cannot just rely on querying the current 'keys held down' for typing in input fields,
	// since order matters and querying some matrix of keys down does NOT preserve input order.
	// It would work for querying if we're in the state to trigger some keyboard shortcut however.
	if etype == .KEYDOWN {
		#partial switch event.key.keysym.sym {
		case .ESCAPE:
			ui_state.dragged_box = nil
		case:
			ui_state.char_queue[ui_state.n_chars_stored] = Scancode(event.key.keysym.scancode)
			ui_state.n_chars_stored += 1
			ui_state.keys_held[event.key.keysym.scancode] = true
		}
	}

	if etype == .KEYUP {
		ui_state.keys_held[event.key.keysym.scancode] = false
	}

	if etype == .MOUSEWHEEL {
		ui_state.mouse.wheel.x = cast(i8)event.wheel.x
		ui_state.mouse.wheel.y = cast(i8)event.wheel.y
		println("got mousewhell event, mouse wheel state is: {}", ui_state.mouse.wheel)
	}

	if etype == .MOUSEBUTTONDOWN {
		switch event.button.button {
		case sdl.BUTTON_LEFT:
			if !ui_state.mouse.left_pressed { 	// i.e. if left button wasn't pressed last frame
				ui_state.mouse.drag_start = ui_state.mouse.pos
				ui_state.mouse.dragging   = true
				ui_state.mouse.drag_done  = false
			}
			ui_state.mouse.left_pressed = true
		case sdl.BUTTON_RIGHT:
			ui_state.mouse.right_pressed = true
		}
	}

	if etype == .MOUSEBUTTONUP {
		switch event.button.button {
		case sdl.BUTTON_LEFT:
			if ui_state.mouse.left_pressed {
				ui_state.mouse.clicked = true
			}
			ui_state.mouse.left_pressed = false
			ui_state.mouse.drag_end     = ui_state.mouse.pos
			ui_state.mouse.dragging     = false
			ui_state.mouse.drag_done    = true

		case sdl.BUTTON_RIGHT:
			if ui_state.mouse.right_pressed { 	// i.e. A right click was performed.
				ui_state.mouse.right_clicked = true
				ui_state.context_menu.active = true
				ui_state.context_menu.pos    = Vec2_f32{f32(ui_state.mouse.pos.x), f32(ui_state.mouse.pos.y)}
			}
			ui_state.mouse.right_pressed = false
		}
	}
	return exit
}
