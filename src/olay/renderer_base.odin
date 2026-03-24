package olay
import ft "../third-party/freetype"
import "base:intrinsics"
import hm "core:container/handle_map"
import "core:math"
import "core:sort"
import "core:time"
import "core:unicode/utf8"

Handle :: hm.Handle64
Texture_Handle :: distinct Handle
Render_Target_Handle :: distinct Handle

PI :: math.PI

Font_Size :: enum {
	xs = 0,
	s  = 1,
	m  = 2,
	l  = 3,
	xl = 4,
}

UI_Element_Type :: enum {
	Regular,
	Text,
	Waveform_Data,
	Circle,
	Fader_Knob,
	Audio_Spectrum,
	Background = 15,
}

// These must appear in the same order as they do in the shader. A bit annoying but eh
// the alternative is to give an explicit integer value to each variant, but even those
// must be synced with the value you give them in the shader.
UI_Render_Flag :: enum u32 {
	Regular,
	Font,
	Waveform_Data,
	Circle,
	Circle_Knob,
	Audio_Spectrum,
	Frosted_Glass,
	Glow,
	Knob_Indicator,
	Frequency_Response,
	Background = 15,
}

Rect_Render_Data :: struct {
	top_left:             Vec2_f32,
	bottom_right:         Vec2_f32,
	texture_top_left:     Vec2_f32,
	texture_bottom_right: Vec2_f32,
	tl_color:             Vec4_f32,
	tr_color:             Vec4_f32,
	bl_color:             Vec4_f32,
	br_color:             Vec4_f32,
	corner_radius:        f32,
	edge_softness:        f32,
	border_thickness:     f32,
	ui_flags:             bit_set[UI_Render_Flag;u32],
	font_size:            Font_Size,
	clip_tl:              Vec2_f32,
	clip_br:              Vec2_f32,
	rotation_radians:     f32,
}

// Kind of the default data when turning an abstract box into an opengl rect.
get_default_rendering_data :: proc(box: Box) -> Rect_Render_Data {
	color := ui_state.dark_theme[box.config.color]
	data: Rect_Render_Data = {
		top_left         = {f32(box.top_left.x), f32(box.bottom_right.y)},
		bottom_right     = {f32(box.bottom_right.x), f32(box.bottom_right.y)},
		// idrk the winding order for colors, this works tho.
		tl_color         = color,
		tr_color         = color,
		bl_color         = color,
		br_color         = color,
		corner_radius    = 0,
		edge_softness    = 0,
		border_thickness = 1000000,
		// clip_tl          = box.clipping_container.top_left,
		// clip_br          = box.clipping_container.bottom_right,
	}
	return data
}

@(private = "file")
box_coord_to_vec2f32 :: proc(coord: [2]int) -> Vec2_f32 {
	return Vec2_f32{f32(coord.x), f32(coord.y)}
}


Boxes_Rendering_Data :: struct {
	additional_data: [dynamic]Rect_Render_Data,
	box:             Maybe(Rect_Render_Data),
	overlay:         Maybe(Rect_Render_Data),
	outer_shadow:    Maybe(Rect_Render_Data),
	inner_shadow:    Maybe(Rect_Render_Data),
	text_cursor:     Maybe(Rect_Render_Data),
}


@(private = "file")
distance :: proc(a, b: [2]$T) -> f32 where intrinsics.type_is_numeric(T) {
	// distance = sqrt((x2 - x1)² + (y2 - y1)²)
	return math.sqrt((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y))
}

// sets circumstantial (hovering, clicked, etc) rendering data like radius, borders, etc
/* Returns:
1st: The render data for the passed in box.
2nd: A list of related things like borders, shadows, etc.
3rd: An overlay (for example to grey out a disabled track)
*/
get_boxes_rendering_data :: proc(box: Box, allocator := context.allocator) -> Boxes_Rendering_Data {
	additional_render_data := make([dynamic]Rect_Render_Data, context.temp_allocator)
	result := Boxes_Rendering_Data {
		additional_data = additional_render_data,
	}

	color := ui_state.dark_theme[box.config.color]

	if .Line in box.flags {
		// A bit of trig to work shit out for the line. Since top_left and bottom_right,
		// form a rectangle, we can cut it in half to get 2 equal triangles and use
		// basic trig to work out the rotation angle to pass to the GPU.
		start  := box.config.line_start
		end    := box.config.line_end
		center := (start + end) * 0.5
		// Classic pythagoras.
		length    := distance(start, end)
		angle     := math.atan2(end.y - start.y, end.x - start.x)
		thickness := f32(box.config.line_thickness)

		// In the rest of our UI: box.tl < box.br is always true. This doesn't hold for
		// lines where start < end isn't always true. Thus we must construct a valid quad
		// for our line from scratch based on the other things we know about the line.
		half_size    := Vec2_f32{length / 2, thickness / 2}
		top_left     := center - half_size
		bottom_right := center + half_size

		line_render_data: Rect_Render_Data = {
			top_left         = top_left,
			bottom_right     = bottom_right,
			tl_color         = color,
			tr_color         = color,
			bl_color         = color,
			br_color         = color,
			corner_radius    = f32(box.config.corner_radius),
			edge_softness    = f32(box.config.edge_softness),
			border_thickness = 100000,
			rotation_radians = angle,
			// clip_tl          = box.clipping_container.top_left,
			// clip_br          = box.clipping_container.bottom_right,
		}
		result.box = line_render_data
		return result
	}

	box_render_data: Rect_Render_Data = {
		top_left         = box_coord_to_vec2f32(box.top_left),
		bottom_right     = box_coord_to_vec2f32(box.bottom_right),
		// idrk the winding order for colors, this works tho.
		tl_color         = color,
		tr_color         = color,
		bl_color         = color,
		br_color         = color,
		corner_radius    = f32(box.config.corner_radius),
		edge_softness    = f32(box.config.edge_softness),
		border_thickness = 100000,
		clip_tl          = vec2_f32(box.clip_tl),
		clip_br          = vec2_f32(box.clip_br),
	}
	if .Glow in box.flags do box_render_data.ui_flags += {.Glow}
	if .Frosted in box.flags do box_render_data.ui_flags += {.Frosted_Glass}

	if box.parent != nil && box.parent.config.overflow_y != .Visible {
		box_render_data.clip_tl = vec2_f32(box.parent.top_left)
		box_render_data.clip_br = vec2_f32(box.parent.bottom_right)
	}

	// Cheap and dirty way to anti alias non squared off edges. Not as good as real anti-aliasing of course.
	if box_render_data.corner_radius > 0 && box_render_data.edge_softness == 0 {
		box_render_data.edge_softness = 0.7
	}

	if box.disabled {
		// Color selection here is iffy, we can't always use some complement of the base color,
		// because different siblings can have different colors, but you want the 'disabled' look to
		// be uniform. For now we'll just pick a random color.
		color := Color_RGBA{0, 0, 0, -0.17} + ui_state.dark_theme[Semantic_Color_Token.Inactive]
		data := Rect_Render_Data {
			tl_color     = color,
			tr_color     = color,
			bl_color     = color,
			br_color     = color,
			top_left     = vec2_f32(box.top_left),
			bottom_right = vec2_f32(box.bottom_right),
		}
		result.overlay = data
	}

	if .Drop_Shadow in box.flags {
		// Create drop shadow for depth
		shadow_color := Vec4_f32{0, 0, 0, 0.5}
		// shadow_color := Vec4_f32{0.8, 0.1, 0.5, 1}
		shadow := Rect_Render_Data {
			top_left         = box_coord_to_vec2f32(box.top_left) + {0, 3}, // Offset for shadow
			bottom_right     = box_coord_to_vec2f32(box.bottom_right) + {7, 7},

			// vec3 col_bl = vec3(0.8, 0.1, 0.5);    // Bottom-Right: Pink/Magenta
			tl_color         = shadow_color,
			tr_color         = shadow_color,
			bl_color         = shadow_color,
			br_color         = shadow_color,
			corner_radius    = box_render_data.corner_radius,
			edge_softness    = 3, // Soft shadow
			border_thickness = 10000,
		}
		result.outer_shadow = shadow
	}

	if box.signals.hovering && .Clickable in box.flags {
		// Create frosted glass overlay.
		if .Hot_Animation in box.flags && !box.signals.pressed {
			glass_overlay := Rect_Render_Data {
				top_left         = box_coord_to_vec2f32(box.top_left),
				bottom_right     = box_coord_to_vec2f32(box.bottom_right),
				// Graident from semi-transparent white to transparent at bottom
				tl_color         = {1, 1, 1, 0.05},
				tr_color         = {1, 1, 1, 0.05},
				bl_color         = {1, 1, 1, 0.4},
				br_color         = {1, 1, 1, 0.4},
				corner_radius    = f32(box.config.corner_radius),
				edge_softness    = 1.5, // subtle glow
				border_thickness = 10000,
			}

			// Create drop shadow for depth
			shadow := Rect_Render_Data {
				top_left         = box_coord_to_vec2f32(box.top_left) + {4, 4}, // Offset for shadow
				bottom_right     = box_coord_to_vec2f32(box.bottom_right) + {4, 4},
				tl_color         = {0, 0, 0, 0.3},
				tr_color         = {0, 0, 0, 0.3},
				bl_color         = {0, 0, 0, 0.6},
				br_color         = {0, 0, 0, 0.6},
				corner_radius    = box_render_data.corner_radius,
				edge_softness    = 3.0, // Soft shadow
				border_thickness = 10000,
			}
			result.outer_shadow = shadow
			result.overlay      = glass_overlay
		} else if .Active_Animation in box.flags && box.signals.pressed {
			glass_overlay := Rect_Render_Data {
				top_left         = box_coord_to_vec2f32(box.top_left),
				bottom_right     = box_coord_to_vec2f32(box.bottom_right),
				// Graident from semi-transparent white to transparent at bottom
				tl_color         = {1, 1, 1, 0.2},
				tr_color         = {1, 1, 1, 0.2},
				bl_color         = {1, 1, 1, 0.05},
				br_color         = {1, 1, 1, 0.05},
				corner_radius    = f32(box.config.corner_radius),
				edge_softness    = 1.5, // subtle glow
				border_thickness = 10000,
			}
			result.overlay = glass_overlay

			// Inner shadow (render AFTER the main element)
			inner_shadow := Rect_Render_Data {
				top_left         = box_coord_to_vec2f32(box.top_left),
				bottom_right     = box_coord_to_vec2f32(box.bottom_right),
				tl_color         = {0, 0, 0, 0.3},
				tr_color         = {0, 0, 0, 0.2},
				bl_color         = {0, 0, 0, 0.2},
				br_color         = {0, 0, 0, 0.15},
				corner_radius    = box_render_data.corner_radius,
				edge_softness    = 3.0,
				border_thickness = 10000,
			}
			result.inner_shadow = inner_shadow
			// Darken the main element
			// box_render_data.tl_color *= 0.9
			// box_render_data.tr_color *= 0.9
			// box_render_data.bl_color *= 0.9
			// box_render_data.br_color *= 0.9
		}
	}
	// ------ These come after adding the main rect data since they have a higher 'z-order'.

	text_cursor_render: {
		// Uses some heuristic time based property to determine if text cursor
		// should be showing or not. Ultimately achieving blinking.
		should_render_text_cursor :: proc() -> bool {
			time_in_ms := time.now()._nsec / 1_000_000
			// On for 0.5 second, off for a 0.5 a second
			return (time_in_ms % (800)) < 500
		}
		// Tells you where the cursor should render. This function will need to be updated
		// when we include various types of text positioning, right now all text is centered by default.
		calc_cursor_pos :: proc(box: Box, text: string) -> int {
			editor_state := ui_state.text_editors_state[box.id]
			cursor_pos   := min(editor_state.selection[0], len(text))
			substr_len   := font_get_strings_rendered_len(text[0:cursor_pos], box.config.font_size)
			// Calculate offset gap between left edge of box and start of rendered text.
			half_gap := (box.width - font_get_strings_rendered_len(text, box.config.font_size)) / 2
			return box.top_left.x + half_gap + substr_len
		}
		// Add cursor inside text box. Blinking is kinda jank right now.
		if .Edit_Text in box.flags &&
		should_render_text_cursor()             &&
		ui_state.last_active_box != nil          &&
		ui_state.last_active_box.id == box.id
		{
			// box_data_string := box_data_as_string(box.data, context.temp_allocator)
			color        := Color_RGBA{0, 0.5, 1, 1}
			cursor_x_pos := f32(calc_cursor_pos(box, box.text))
			cursor_data := Rect_Render_Data {
				top_left         = {cursor_x_pos, f32(box.top_left.y)},
				bottom_right     = {cursor_x_pos + 2.4, f32(box.bottom_right.y)},
				bl_color         = color,
				tl_color         = color,
				br_color         = color,
				tr_color         = color,
				border_thickness = 300,
				corner_radius    = 0,
			}
			result.text_cursor = cursor_data
		}
	}

	// Need to figure out how to make my SDL hollow stuff work with independantly sized sides of a border.
	// Previously you could just have borders on or off
	if has_border(box.config.border) {
		color := ui_state.dark_theme[box.config.border_color]

		if box.config.border.left > 0 {
			left_border                 := Rect_Render_Data{}
			left_border.top_left         = vec2_f32(box.top_left)
			left_border.bottom_right     = {
				left_border.top_left.x + f32(box.config.border.left),
				f32(box.bottom_right.y),
			}
			left_border.tl_color         = color
			left_border.tr_color         = color
			left_border.bl_color         = color
			left_border.br_color         = color
			left_border.border_thickness = 100
			left_border.clip_tl          = box_render_data.clip_tl
			left_border.clip_br          = box_render_data.clip_br
			append(&result.additional_data, left_border)
		}
		if box.config.border.right > 0 {
			right_border                 := Rect_Render_Data{}
			right_border.top_left         = vec2_f32(
				[2]int{box.bottom_right.x - box.config.border.right, box.top_left.y},
			)
			right_border.bottom_right     = vec2_f32(box.bottom_right)
			right_border.tl_color         = color
			right_border.tr_color         = color
			right_border.bl_color         = color
			right_border.br_color         = color
			right_border.border_thickness = 100
			right_border.clip_tl          = box_render_data.clip_tl
			right_border.clip_br          = box_render_data.clip_br
			append(&result.additional_data, right_border)
		}
		if box.config.border.top > 0 {
			top_border                 := Rect_Render_Data{}
			top_border.top_left         = vec2_f32(box.top_left)
			top_border.bottom_right     = top_border.top_left + vec2_f32([2]int{box.width, box.config.border.top})
			top_border.tl_color         = color
			top_border.tr_color         = color
			top_border.bl_color         = color
			top_border.br_color         = color
			top_border.border_thickness = 100
			// top_border.edge_softness =
			top_border.clip_tl = box_render_data.clip_tl
			top_border.clip_br = box_render_data.clip_br
			append(&result.additional_data, top_border)
		}
		if box.config.border.bottom > 0 {
			bottom_border                 := Rect_Render_Data{}
			bottom_border.top_left         = vec2_f32(
				[2]int{box.top_left.x, box.bottom_right.y - box.config.border.bottom},
			)
			bottom_border.bottom_right     = vec2_f32(box.bottom_right)
			bottom_border.tl_color         = color
			bottom_border.tr_color         = color
			bottom_border.bl_color         = color
			bottom_border.br_color         = color
			bottom_border.border_thickness = 100
			bottom_border.clip_tl          = box_render_data.clip_tl
			bottom_border.clip_br          = box_render_data.clip_br
			append(&result.additional_data, bottom_border)
		}

	}

	if metadata, ok := box.metadata.(Metadata_Knob); ok {
		if .Knob_Ring in box.flags {
			normalized_value := map_range(metadata.min, metadata.max, 0, 1, metadata.val)
			if metadata.logarithmic && metadata.min > 0 {
				normalized_value = f32(
					math.ln(f64(metadata.val) / f64(metadata.min)) / math.ln(f64(metadata.max) / f64(metadata.min)),
				)
			}
			data      := box_render_data
			gap: f32 = 2
			thickness: f32 = 5
			extension := gap * thickness
			arc_meta_data := Rect_Render_Data {
				bl_color         = data.bl_color,
				br_color         = data.br_color,
				tl_color         = data.tl_color,
				tr_color         = data.tr_color,
				top_left         = data.top_left - {extension, extension},
				bottom_right     = data.bottom_right + {extension, extension},
				// Co-opted by knob ring to indicate the thickness of the ring.
				border_thickness = thickness,
				ui_flags         = {.Knob_Indicator},
				texture_top_left = {normalized_value, 0},
			}
			append(&result.additional_data, arc_meta_data)
		}
	}

	if .Draw in box.flags {
		result.box = box_render_data
	}

	return result
}

collect_render_data_from_ui_tree :: proc(
	root: ^Box,
	render_data_allocator := context.allocator,
) -> [dynamic]Rect_Render_Data {
	arena, scratch := arena_allocator_new("collect-render-data-box-tree-to-list")
	defer arena_allocator_destroy(arena, scratch)
	box_list := box_tree_to_list_complex(root, scratch)
	// Must use a stable sort.
	sort.merge_sort_proc(box_list[:], proc(a, b: ^Box) -> int {
		if a.z_index < b.z_index {
			return -1
		} else if a.z_index > b.z_index {
			return 1
		} else {
			return 0
		}
	})

	render_data := make([dynamic]Rect_Render_Data, render_data_allocator)
	for box in box_list {
		boxes_render_data := get_boxes_rendering_data(box^, scratch)
		if shadow, ok := boxes_render_data.outer_shadow.(Rect_Render_Data); ok {
			append(&render_data, shadow)
		}

		// Some boxes may not need to be rendered themselves, but their related data to that box may need to be rendered.
		// Hence the conditional.
		if box_data, ok := boxes_render_data.box.(Rect_Render_Data); ok {
			append(&render_data, box_data)
		}

		for data in boxes_render_data.additional_data {
			append(&render_data, data)
		}


		if inner_shadow, ok := boxes_render_data.inner_shadow.(Rect_Render_Data); ok {
			append(&render_data, inner_shadow)
		}

		draw_text: if .Draw_Text in box.flags {
			text              := utf8.string_to_runes(box.text, scratch)
			shaped_glyphs     := font_segment_and_shape_text(&ui_state.font_state.kb.font, text)
			glyph_render_info := font_get_render_info(shaped_glyphs[:], box.config.font_size, nil, nil, scratch)
			glyph_rects       := get_text_quads(box^, glyph_render_info[:], scratch)
			for rect in glyph_rects {
				append(&render_data, rect)
			}
		}

		draw_icon: if .Draw_Icon in box.flags {
			glyph_index := ft.get_char_index(ui_state.icon_state.freetype.face, u32(box.icon_rune))
			buf         := [1]Glyph{Glyph{glyph = {Id = u16(glyph_index)}, pos = {0, 0}}}
			render_info := font_get_render_info(
				buf[:],
				box.config.font_size,
				ui_state.icon_state.freetype.face,
				&ui_state.icon_state.rendered_glyph_cache,
				context.temp_allocator,
			)
			rects := get_text_quads(box^, render_info[:], context.temp_allocator)
			for rect in rects {
				append(&render_data, rect)
			}
		}

		if text_cursor, ok := boxes_render_data.text_cursor.(Rect_Render_Data); ok {
			append(&render_data, text_cursor)
		}

		if overlay, ok := boxes_render_data.overlay.(Rect_Render_Data); ok {
			append(&render_data, overlay)
		}
	}
	return render_data
}

/*
Returns the quads which we will sample the font pixels into. 
This is probably where I'd implement subpixel positioning and stuff, but for now
we just naively wrap to the nearest int.
*/

// NOTE! character quads aren't positioned correctly, refer to claude chat as to how
// we can fix it.
get_text_quads :: proc(
	box: Box,
	glyph_buffer: []Glyph_Render_Info,
	allocator := context.allocator,
) -> [dynamic]Rect_Render_Data {
	// Calculate baseline: (for now we just center text on both axis inside the box)
	tallest_char         := font_get_glyphs_tallest_glyph(glyph_buffer)
	rendered_len         := font_get_glyphs_rendered_len(glyph_buffer)
	vertical_diff_half   := (box.height - int(tallest_char)) / 2
	horizontal_diff_half := (box.width - int(rendered_len)) / 2
	// Really only the first point in baseline, which is all we need.
	baseline_x, baseline_y: int
	switch box.config.text_justify.x {
	case .Center:
		baseline_x = box.top_left.x + int(horizontal_diff_half)
	case .Start:
		baseline_x = box.top_left.x + box.config.padding.left
	case .End:
		baseline_x = box.bottom_right.x - (box.config.padding.right + rendered_len)
	}
	switch box.config.text_justify.y {
	case .Center:
		// baseline_y = box.top_left.y + int(vertical_diff_half)
		baseline_y = box.bottom_right.y - int(vertical_diff_half)
	case .Start:
		baseline_y = box.top_left.y + box.config.padding.top
	case .End:
		baseline_y = box.bottom_right.y - (box.config.padding.bottom + tallest_char)
	}
	pen_x := baseline_x
	// Doesn't need to be dynamically sized but static allocated size may confuse user.
	glyph_rects  := make([dynamic]Rect_Render_Data, len(glyph_buffer), allocator)
	atlas_width  := ui_state.font_state.atlas.row_width
	atlas_height := ui_state.font_state.atlas.num_rows
	for glyph, i in glyph_buffer {
		cache_record := glyph.cache_record
		final_x      := math.round(f32(baseline_x) + glyph.pos.x)
		final_y      := math.round(f32(baseline_y) + glyph.pos.y)
		descent      := cache_record.height - cache_record.bearing_y // Descent below baseline.
		tex_tl_x     := f32(cache_record.atlas_x) / f32(atlas_width)
		tex_tl_y     := f32(cache_record.atlas_y) / f32(atlas_height)
		tex_br_x     := f32(cache_record.atlas_x + cache_record.width) / f32(atlas_width)
		tex_br_y     := f32(cache_record.atlas_y + cache_record.height) / f32(atlas_height)
		// text_color := get_text_color_from_base(box.config.color)
		text_color := ui_state.dark_theme[box.config.text_color]
		data := Rect_Render_Data {
			top_left             = {final_x + f32(cache_record.bearing_x), final_y - f32(cache_record.bearing_y)},
			bottom_right         = {
				final_x + f32(cache_record.bearing_x + cache_record.width),
				final_y + f32(descent),
			},
			texture_top_left     = Vec2_f32{tex_tl_x, tex_tl_y},
			texture_bottom_right = Vec2_f32{tex_br_x, tex_br_y},
			border_thickness     = 500,
			tl_color             = text_color,
			tr_color             = text_color,
			bl_color             = text_color,
			br_color             = text_color,
			ui_flags             = {.Font},
			clip_tl              = vec2_f32(box.clip_tl),
			clip_br              = vec2_f32(box.clip_br),
		}
		// Set clipping rect for text.
		// if box.parent != nil && box.parent.config.overflow_y != .Visible {
		// 	data.clip_tl = vec2_f32(box.parent.top_left)
		// 	data.clip_br = vec2_f32(box.parent.bottom_right)
		// }
		glyph_rects[i] = data
	}


	return glyph_rects
}


@(private = "file")
// The material color palette generates text colors that go ontop of the base colors,
// so this function just pulls that out
get_text_color_from_base :: proc(color_token: Semantic_Color_Token) -> Color_RGBA {
	#partial switch color_token {
	case .Primary:
		return ui_state.dark_theme[.On_Primary]
	case .Secondary:
		return ui_state.dark_theme[.On_Secondary]
	case .Tertiary:
		return ui_state.dark_theme[.On_Tertiary]
	case .Background:
		return ui_state.dark_theme[.On_Background]
	case .Inactive:
		return ui_state.dark_theme[.On_Inactive]
	case .Error:
		return ui_state.dark_theme[.On_Error]
	case .Primary_Container:
		return ui_state.dark_theme[.On_Primary_Container]
	case .Secondary_Container:
		return ui_state.dark_theme[.On_Secondary_Container]
	case .Tertiary_Container:
		return ui_state.dark_theme[.On_Tertiary_Container]
	case .Error_Container:
		return ui_state.dark_theme[.On_Error_Container]
	case .Surface:
		return ui_state.dark_theme[.On_Surface]
	case .Surface_Variant:
		return ui_state.dark_theme[.On_Surface_Variant]
	case .Warning:
		return ui_state.dark_theme[.On_Warning]
	case .Warning_Container:
		return ui_state.dark_theme[.On_Warning_Container]
	case .Surface_Dim,
	     .Surface_Bright,
	     .Surface_Container_Lowest,
	     .Surface_Container_Low,
	     .Surface_Container,
	     .Surface_Container_High,
	     .Surface_Container_Highest:
		return ui_state.dark_theme[.On_Surface]
	case .Inverse_Surface:
		return ui_state.dark_theme[.Inverse_On_Surface]
	}
	// For Tailwind colors and anything else without a semantic On_X pairing,
	// derive text color from perceived luminance of the base.
	base      := ui_state.dark_theme[color_token]
	luminance := 0.299 * base.r + 0.587 * base.g + 0.114 * base.b
	if luminance > 0.5 {
		return Color_RGBA{0.1, 0.1, 0.1, 1}
	}
	return Color_RGBA{0.95, 0.95, 0.95, 1}
}
