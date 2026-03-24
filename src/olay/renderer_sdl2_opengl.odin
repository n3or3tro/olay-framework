package olay

import gl "vendor:OpenGL"

gl_render_ui_background_to_fbo :: proc(rect_rendering_data: [dynamic]Rect_Render_Data) {
	gl.UseProgram(ui_state.quad_shader_program)
	gl.BindFramebuffer(gl.FRAMEBUFFER, ui_state.fbo_id_offscreen_ui)

	arena, scratch := arena_allocator_new("render-background-to-fbo")
	defer arena_allocator_destroy(arena, scratch)
	background_rendering_data := make([dynamic]Rect_Render_Data, 0, int(f64(len(rect_rendering_data)) * 0.7), scratch)
	for data in rect_rendering_data {
		if .Frosted_Glass not_in data.ui_flags {
			append(&background_rendering_data, data)
		}
	}
	n_rects := u32(len(background_rendering_data))
	populate_vbuffer_with_rects(
		ui_state.quad_vbuffer, // ui_state.quad_vabuffer,
		0,
		raw_data(background_rendering_data),
		n_rects * size_of(Rect_Render_Data),
	)
	gl_clear_screen()
	gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, i32(n_rects))
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
}

gl_render_blur_pass :: proc() {
	gl_clear_screen()
	gl.Disable(gl.BLEND)
	gl.BindFramebuffer(gl.FRAMEBUFFER, ui_state.fbo_id_blurred_ui)
	gl.ActiveTexture(gl.TEXTURE2)
	gl.BindTexture(gl.TEXTURE_2D, ui_state.tex_id_offscreen_ui)
	gl.UseProgram(ui_state.blur_shader_program)
	set_shader_vec2(ui_state.blur_shader_program, "texel_size", {1.0 / f32(app.wx), 1.0 / f32(app.wy)})
	gl.Uniform1i(gl.GetUniformLocation(ui_state.blur_shader_program, "scene_texture"), 2)
	// Doesn't really matter which draw call, we just need the shader to run.
	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4)
	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Enable(gl.BLEND)
}

gl_clear_screen :: proc() {
	color := ui_state.dark_theme[.Inverse_On_Surface]
	gl.ClearColor(color.r, color.g, color.b, color.a)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

gl_render_ui :: proc(rect_rendering_data: [dynamic]Rect_Render_Data) {
	if ui_state.frame_num == 0 {
		return
	}
	gl_clear_screen()
	gl.UseProgram(ui_state.quad_shader_program)

	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, ui_state.tex_id_font_atlas)

	// gl.ActiveTexture(gl.TEXTURE1)
	// gl.BindTexture(gl.TEXTURE_2D, ui_state.tex_id_freq_spectrum)

	gl.ActiveTexture(gl.TEXTURE2)
	gl.BindTexture(gl.TEXTURE_2D, ui_state.tex_id_blurred_ui)

	// gl.ActiveTexture(gl.TEXTURE3)
	// gl.BindTexture(gl.TEXTURE_2D, ui_state.tex_id_freq_response)

	n_rects := u32(len(rect_rendering_data))
	populate_vbuffer_with_rects(
		ui_state.quad_vbuffer, // ui_state.quad_vabuffer,
		0,
		raw_data(rect_rendering_data),
		n_rects * size_of(Rect_Render_Data),
	)
	gl.DrawArraysInstanced(gl.TRIANGLE_STRIP, 0, 4, i32(n_rects))
}

gl_setup_for_quads :: proc(shader_program: ^u32) {
	//odinfmt:disable
	gl.BindVertexArray(ui_state.quad_vabuffer^)
	// bind_shader(shader_program^)

	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, top_left))
	gl.VertexAttribDivisor(0, 1)
	enable_layout(0)

	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, bottom_right))
	enable_layout(1)
	gl.VertexAttribDivisor(1, 1)

	// Trying to pass in a [4]vec4 for colors was fucky, so did this. Should clean up later.
	gl.VertexAttribPointer(2, 4, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, tl_color))
	enable_layout(2)
	gl.VertexAttribDivisor(2, 1)

	gl.VertexAttribPointer(3, 4, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, tr_color))
	enable_layout(3)
	gl.VertexAttribDivisor(3, 1)

	gl.VertexAttribPointer(4, 4, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, bl_color))
	enable_layout(4)
	gl.VertexAttribDivisor(4, 1)

	gl.VertexAttribPointer(5, 4, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, br_color))
	enable_layout(5)
	gl.VertexAttribDivisor(5, 1)

	gl.VertexAttribPointer(6, 1, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, corner_radius))
	enable_layout(6)
	gl.VertexAttribDivisor(6, 1)

	gl.VertexAttribPointer(7, 1, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, edge_softness))
	enable_layout(7)
	gl.VertexAttribDivisor(7, 1)

	gl.VertexAttribPointer(8, 1, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, border_thickness))
	enable_layout(8)
	gl.VertexAttribDivisor(8, 1)

	gl.VertexAttribPointer(9, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, texture_top_left))
	enable_layout(9)
	gl.VertexAttribDivisor(9, 1)

	gl.VertexAttribPointer(10, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, texture_bottom_right))
	enable_layout(10)
	gl.VertexAttribDivisor(10, 1)

	gl.VertexAttribIPointer(11, 1, gl.UNSIGNED_INT, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, ui_flags))
	enable_layout(11)
	gl.VertexAttribDivisor(11, 1)

	gl.VertexAttribPointer(12, 1, gl.INT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, font_size))
	enable_layout(12)
	gl.VertexAttribDivisor(12, 1)

	gl.VertexAttribPointer(13, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, clip_tl))
	enable_layout(13)
	gl.VertexAttribDivisor(13, 1)

	gl.VertexAttribPointer(14, 2, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, clip_br))
	enable_layout(14)
	gl.VertexAttribDivisor(14, 1)

	gl.VertexAttribPointer(15, 1, gl.FLOAT, false, size_of(Rect_Render_Data), offset_of(Rect_Render_Data, rotation_radians))
	enable_layout(15)
	gl.VertexAttribDivisor(15, 1)

	//odinfmt:enable
}
