/*
Contains platform-independant code that's used by all platform / renderer backends when using Olay with it's 
standalone application integration.
*/

package olay
import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:sys/windows"
import "vendor:kb_text_shape"

PERF_PROFILE :: #config(perf_profile, false)
MEM_PROFILE :: #config(mem_profile, false)
PLATFORM_SDL2 :: #config(platform_sdl2, true)
PLATFORM_SDL3 :: #config(platform_sdl3, false)
PLATFORM_WIN32 :: #config(platform_win32, true)
PLATFORM_X11 :: #config(platform_x11, false)
PLATFORM_WAYLAND :: #config(platform_wayland, false)
PLATFORM_MACOS :: #config(platform_macos, false)
PLATFORM_IOS :: #config(platform_ios, false)
PLATFORM_ANDROID :: #config(platform_android, false)


print :: fmt.print
println :: fmt.println
printf :: fmt.printf
printfln :: fmt.printfln
aprintf :: fmt.aprintf
tprintf :: fmt.tprintf
tprintfln :: fmt.aprintfln

when PLATFORM_SDL2 {
	App :: App_SDL2
} else when PLATFORM_WIN32 {
	App :: App_Win32
} else {
	App :: int
}

ui_state: ^UI_State
app: ^App


App_Base :: struct {
	// This is a dead end for internationalization and will need to be fixed at some point, lest we're stuck with english.
	ui_state:               ^UI_State,
	maximized:              bool,
	wx:                     int,
	wy:                     int,
	running:                bool,
	memory_profiler:        Memory_Profiler,
	selected_track:         int,
	last_undo_commit_frame: u64,
}

Memory_Profiler :: struct {
	tracking_allocators: map[string]^mem.Tracking_Allocator,
	og_heap_allocator:   mem.Allocator,
	allocations:         map[string][dynamic]mem.Tracking_Allocator_Entry,
}

@(export)
app_memory :: proc() -> rawptr {
	return app
}

@(export)
app_memory_size :: proc() -> int {
	return size_of(App)
}

@(export)
app_should_run :: proc() -> bool {
	return app.running
}

@(export)
app_hot_reload :: proc(mem: rawptr) {
	app      = (^App)(mem)
	ui_state = app.ui_state
	font_init(&ui_state.font_state)
	icons_init(&ui_state.icon_state)
	when ODIN_OS == .Windows && PLATFORM_SDL2 {
		resubclass_wndproc()
	} else when ODIN_OS == .Windows && PLATFORM_WIN32 {
		app_win32_post_reload()
	}
}

@(export)
app_reload_colors :: proc(mem: rawptr, color_file_path: string) {
	app = (^App)(mem)
	delete(app.ui_state.dark_theme)
	data, err := os.read_entire_file_from_path(color_file_path, context.temp_allocator)
	assert(err == os.General_Error.None)
	app.ui_state.dark_theme = parse_json_token_color_mapping(data)
}

@(export)
app_reset_state :: proc() {
	ui_state.n_chars_stored   = 0
	ui_state.char_queue       = {}
	ui_state.keys_held        = {}
	ui_state.mouse            = {}
	ui_state.mouse_last_frame = {}

	free(app.ui_state.quad_vbuffer)
	free(app.ui_state.quad_vabuffer)
	delete_dynamic_array(app.ui_state.color_stack)
	for key, val in app.ui_state.box_cache {
		delete(key)
		delete(val.children)
		free(val)
	}
	delete_map(app.ui_state.box_cache)

	delete(app.ui_state.font_state.rendered_glyph_cache)
	delete(app.ui_state.font_state.shaped_string_cache)
	delete(app.ui_state.font_state.atlas.bitmap_buffer)
	kb_text_shape.FreeFont(&app.ui_state.font_state.kb.font, context.allocator)
	for parent in app.ui_state.parents_stack {
		free(parent)
	}
	delete(app.ui_state.parents_stack)
	delete(app.ui_state.dark_theme)
	free(app.ui_state)
}

@(export)
app_shutdown :: proc() {
	when ODIN_OS == .Windows {
		windows.CoUninitialize()
	}
	free(app.ui_state.quad_vbuffer)
	free(app.ui_state.quad_vabuffer)
	delete_dynamic_array(app.ui_state.color_stack)
	for key, val in app.ui_state.box_cache {
		delete(key)
		// if str, ok := val.data.(^string); ok {
		// 	delete(str^)
		// }
		delete(val.children)
		free(val)
	}
	delete_map(app.ui_state.box_cache)

	delete(ui_state.font_state.rendered_glyph_cache)
	delete(ui_state.font_state.shaped_string_cache)
	delete(ui_state.font_state.atlas.bitmap_buffer)
	kb_text_shape.FreeFont(&ui_state.font_state.kb.font, context.allocator)
	for parent in ui_state.parents_stack {
		free(parent)
	}
	delete(ui_state.parents_stack)
	delete(ui_state.dark_theme)
	free(app.ui_state)
	free(app)
	// free_all(context.allocator)
	free_all(context.temp_allocator)
}

@(export)
app_store_tracking_allocator :: proc(name: string, allocator: ^mem.Tracking_Allocator) {
	app.memory_profiler.tracking_allocators[name] = allocator
}

@(export)
app_store_og_allocator :: proc(allocator: mem.Allocator) {
	app.memory_profiler.og_heap_allocator = allocator
}

@(export)
// Trigger a build of the DLL and hot reload it in, keeping existing state.
app_wants_reload :: proc() -> bool {
	return ui_state.keys_held[Scancode.F5]
}

@(export)
// I.e. fully reset state as if you just launched the app.
// Won't trigger a rebuild of the DLL.
app_wants_restart :: proc() -> bool {
	return ui_state.keys_held[Scancode.F1]
}

// Support for up to 255 mouse buttons. Cast an int to type `Mouse_Button` to use things outside the
// options presented here.
Mouse_Button :: enum {
	Left,
	Right,
	Middle,
	Max = 255,
}

Event :: union {
	Event_Close_Window_Requested,
	Event_Key_Went_Down,
	Event_Key_Went_Up,
	Event_Mouse_Move,
	Event_Mouse_Wheel,
	Event_Mouse_Button_Went_Down,
	Event_Mouse_Button_Went_Up,
	Event_Screen_Resize,
	Event_Window_Focused,
	Event_Window_Unfocused,
	Event_Window_Scale_Changed,
}

Event_Key_Went_Down :: struct {
	key: Keyboard_Key,
}

Event_Key_Went_Up :: struct {
	key: Keyboard_Key,
}

Event_Mouse_Button_Went_Down :: struct {
	button: Mouse_Button,
}

Event_Mouse_Button_Went_Up :: struct {
	button: Mouse_Button,
}

Event_Close_Window_Requested :: struct {}

Event_Mouse_Move :: struct {
	position: Vec2_f32,
}

Event_Mouse_Wheel :: struct {
	delta: f32,
}

// Reports the new size of the drawable game area
Event_Screen_Resize :: struct {
	width, height: int,
}

// You can also use `k2.get_window_scale()`
Event_Window_Scale_Changed :: struct {
	scale: f32,
}

Event_Window_Focused :: struct {}

Event_Window_Unfocused :: struct {}

// ================================ KEYBOARD HANDLING STUFF =================================

/*Karl has this as his base keyboard type, but I've copied SDL, so I chucked here in this windows specific file 
for now, but we might adopt it to be our own base Keybaord key struct */
// Based on Raylib / GLFW
Keyboard_Key :: enum {
	None          = 0,

	// Numeric keys (top row)
	N0            = 48,
	N1            = 49,
	N2            = 50,
	N3            = 51,
	N4            = 52,
	N5            = 53,
	N6            = 54,
	N7            = 55,
	N8            = 56,
	N9            = 57,

	// Letter keys
	A             = 65,
	B             = 66,
	C             = 67,
	D             = 68,
	E             = 69,
	F             = 70,
	G             = 71,
	H             = 72,
	I             = 73,
	J             = 74,
	K             = 75,
	L             = 76,
	M             = 77,
	N             = 78,
	O             = 79,
	P             = 80,
	Q             = 81,
	R             = 82,
	S             = 83,
	T             = 84,
	U             = 85,
	V             = 86,
	W             = 87,
	X             = 88,
	Y             = 89,
	Z             = 90,

	// Special characters
	Apostrophe    = 39,
	Comma         = 44,
	Minus         = 45,
	Period        = 46,
	Slash         = 47,
	Semicolon     = 59,
	Equal         = 61,
	Left_Bracket  = 91,
	Backslash     = 92,
	Right_Bracket = 93,
	Backtick      = 96,

	// Function keys, modifiers, caret control etc
	Space         = 32,
	Escape        = 256,
	Enter         = 257,
	Tab           = 258,
	Backspace     = 259,
	Insert        = 260,
	Delete        = 261,
	Right         = 262,
	Left          = 263,
	Down          = 264,
	Up            = 265,
	Page_Up       = 266,
	Page_Down     = 267,
	Home          = 268,
	End           = 269,
	Caps_Lock     = 280,
	Scroll_Lock   = 281,
	Num_Lock      = 282,
	Print_Screen  = 283,
	Pause         = 284,
	F1            = 290,
	F2            = 291,
	F3            = 292,
	F4            = 293,
	F5            = 294,
	F6            = 295,
	F7            = 296,
	F8            = 297,
	F9            = 298,
	F10           = 299,
	F11           = 300,
	F12           = 301,
	Left_Shift    = 340,
	Left_Control  = 341,
	Left_Alt      = 342,
	Left_Super    = 343,
	Right_Shift   = 344,
	Right_Control = 345,
	Right_Alt     = 346,
	Right_Super   = 347,
	Menu          = 348,

	// Numpad keys
	NP_0          = 320,
	NP_1          = 321,
	NP_2          = 322,
	NP_3          = 323,
	NP_4          = 324,
	NP_5          = 325,
	NP_6          = 326,
	NP_7          = 327,
	NP_8          = 328,
	NP_9          = 329,
	NP_Decimal    = 330,
	NP_Divide     = 331,
	NP_Multiply   = 332,
	NP_Subtract   = 333,
	NP_Add        = 334,
	NP_Enter      = 335,
	NP_Equal      = 336,
}

// Returned as a bit_set by `get_held_modifiers`
Modifier :: enum {
	Control,
	Alt,
	Shift,
	Super,
}

MODIFIERS_NONE :: bit_set[Modifier]{}

// Pulled straight from `vendor:sdl2/sdl_scancodes.odin`
NUM_SCANCODES :: 512

Scancode :: enum i32 {
	UNKNOWN            = 0,
	A                  = 4,
	B                  = 5,
	C                  = 6,
	D                  = 7,
	E                  = 8,
	F                  = 9,
	G                  = 10,
	H                  = 11,
	I                  = 12,
	J                  = 13,
	K                  = 14,
	L                  = 15,
	M                  = 16,
	N                  = 17,
	O                  = 18,
	P                  = 19,
	Q                  = 20,
	R                  = 21,
	S                  = 22,
	T                  = 23,
	U                  = 24,
	V                  = 25,
	W                  = 26,
	X                  = 27,
	Y                  = 28,
	Z                  = 29,
	NUM1               = 30,
	NUM2               = 31,
	NUM3               = 32,
	NUM4               = 33,
	NUM5               = 34,
	NUM6               = 35,
	NUM7               = 36,
	NUM8               = 37,
	NUM9               = 38,
	NUM0               = 39,
	RETURN             = 40,
	ESCAPE             = 41,
	BACKSPACE          = 42,
	TAB                = 43,
	SPACE              = 44,
	MINUS              = 45,
	EQUALS             = 46,
	LEFTBRACKET        = 47,
	RIGHTBRACKET       = 48,
	BACKSLASH          = 49,
	NONUSHASH          = 50,
	SEMICOLON          = 51,
	APOSTROPHE         = 52,
	GRAVE              = 53,
	COMMA              = 54,
	PERIOD             = 55,
	SLASH              = 56,
	CAPSLOCK           = 57,
	F1                 = 58,
	F2                 = 59,
	F3                 = 60,
	F4                 = 61,
	F5                 = 62,
	F6                 = 63,
	F7                 = 64,
	F8                 = 65,
	F9                 = 66,
	F10                = 67,
	F11                = 68,
	F12                = 69,
	PRINTSCREEN        = 70,
	SCROLLLOCK         = 71,
	PAUSE              = 72,
	INSERT             = 73,
	HOME               = 74,
	PAGEUP             = 75,
	DELETE             = 76,
	END                = 77,
	PAGEDOWN           = 78,
	RIGHT              = 79,
	LEFT               = 80,
	DOWN               = 81,
	UP                 = 82,
	NUMLOCKCLEAR       = 83,
	KP_DIVIDE          = 84,
	KP_MULTIPLY        = 85,
	KP_MINUS           = 86,
	KP_PLUS            = 87,
	KP_ENTER           = 88,
	KP_1               = 89,
	KP_2               = 90,
	KP_3               = 91,
	KP_4               = 92,
	KP_5               = 93,
	KP_6               = 94,
	KP_7               = 95,
	KP_8               = 96,
	KP_9               = 97,
	KP_0               = 98,
	KP_PERIOD          = 99,
	NONUSBACKSLASH     = 100,
	APPLICATION        = 101,
	POWER              = 102,
	KP_EQUALS          = 103,
	F13                = 104,
	F14                = 105,
	F15                = 106,
	F16                = 107,
	F17                = 108,
	F18                = 109,
	F19                = 110,
	F20                = 111,
	F21                = 112,
	F22                = 113,
	F23                = 114,
	F24                = 115,
	EXECUTE            = 116,
	HELP               = 117,
	MENU               = 118,
	SELECT             = 119,
	STOP               = 120,
	AGAIN              = 121,
	UNDO               = 122,
	CUT                = 123,
	COPY               = 124,
	PASTE              = 125,
	FIND               = 126,
	MUTE               = 127,
	VOLUMEUP           = 128,
	VOLUMEDOWN         = 129,
	/* not sure whether there's a reason to enable these */
	/*     LOCKINGCAPSLOCK = 130,  */
	/*     LOCKINGNUMLOCK = 131, */
	/*     LOCKINGSCROLLLOCK = 132, */
	KP_COMMA           = 133,
	KP_EQUALSAS400     = 134,
	INTERNATIONAL1     = 135,
	INTERNATIONAL2     = 136,
	INTERNATIONAL3     = 137,
	INTERNATIONAL4     = 138,
	INTERNATIONAL5     = 139,
	INTERNATIONAL6     = 140,
	INTERNATIONAL7     = 141,
	INTERNATIONAL8     = 142,
	INTERNATIONAL9     = 143,
	LANG1              = 144,
	LANG2              = 145,
	LANG3              = 146,
	LANG4              = 147,
	LANG5              = 148,
	LANG6              = 149,
	LANG7              = 150,
	LANG8              = 151,
	LANG9              = 152,
	ALTERASE           = 153,
	SYSREQ             = 154,
	CANCEL             = 155,
	CLEAR              = 156,
	PRIOR              = 157,
	RETURN2            = 158,
	SEPARATOR          = 159,
	OUT                = 160,
	OPER               = 161,
	CLEARAGAIN         = 162,
	CRSEL              = 163,
	EXSEL              = 164,
	KP_00              = 176,
	KP_000             = 177,
	THOUSANDSSEPARATOR = 178,
	DECIMALSEPARATOR   = 179,
	CURRENCYUNIT       = 180,
	CURRENCYSUBUNIT    = 181,
	KP_LEFTPAREN       = 182,
	KP_RIGHTPAREN      = 183,
	KP_LEFTBRACE       = 184,
	KP_RIGHTBRACE      = 185,
	KP_TAB             = 186,
	KP_BACKSPACE       = 187,
	KP_A               = 188,
	KP_B               = 189,
	KP_C               = 190,
	KP_D               = 191,
	KP_E               = 192,
	KP_F               = 193,
	KP_XOR             = 194,
	KP_POWER           = 195,
	KP_PERCENT         = 196,
	KP_LESS            = 197,
	KP_GREATER         = 198,
	KP_AMPERSAND       = 199,
	KP_DBLAMPERSAND    = 200,
	KP_VERTICALBAR     = 201,
	KP_DBLVERTICALBAR  = 202,
	KP_COLON           = 203,
	KP_HASH            = 204,
	KP_SPACE           = 205,
	KP_AT              = 206,
	KP_EXCLAM          = 207,
	KP_MEMSTORE        = 208,
	KP_MEMRECALL       = 209,
	KP_MEMCLEAR        = 210,
	KP_MEMADD          = 211,
	KP_MEMSUBTRACT     = 212,
	KP_MEMMULTIPLY     = 213,
	KP_MEMDIVIDE       = 214,
	KP_PLUSMINUS       = 215,
	KP_CLEAR           = 216,
	KP_CLEARENTRY      = 217,
	KP_BINARY          = 218,
	KP_OCTAL           = 219,
	KP_DECIMAL         = 220,
	KP_HEXADECIMAL     = 221,
	LCTRL              = 224,
	LSHIFT             = 225,
	LALT               = 226,
	LGUI               = 227,
	RCTRL              = 228,
	RSHIFT             = 229,
	RALT               = 230,
	RGUI               = 231,
	MODE               = 257,
	AUDIONEXT          = 258,
	AUDIOPREV          = 259,
	AUDIOSTOP          = 260,
	AUDIOPLAY          = 261,
	AUDIOMUTE          = 262,
	MEDIASELECT        = 263,
	WWW                = 264,
	MAIL               = 265,
	CALCULATOR         = 266,
	COMPUTER           = 267,
	AC_SEARCH          = 268,
	AC_HOME            = 269,
	AC_BACK            = 270,
	AC_FORWARD         = 271,
	AC_STOP            = 272,
	AC_REFRESH         = 273,
	AC_BOOKMARKS       = 274,
	BRIGHTNESSDOWN     = 275,
	BRIGHTNESSUP       = 276,
	DISPLAYSWITCH      = 277,
	KBDILLUMTOGGLE     = 278,
	KBDILLUMDOWN       = 279,
	KBDILLUMUP         = 280,
	EJECT              = 281,
	SLEEP              = 282,
	APP1               = 283,
	APP2               = 284,
	AUDIOREWIND        = 285,
	AUDIOFASTFORWARD   = 286,
	NUM_SCANCODES      = 512,
}

SCANCODE_UNKNOWN :: Scancode.UNKNOWN

SCANCODE_A :: Scancode.A
SCANCODE_B :: Scancode.B
SCANCODE_C :: Scancode.C
SCANCODE_D :: Scancode.D
SCANCODE_E :: Scancode.E
SCANCODE_F :: Scancode.F
SCANCODE_G :: Scancode.G
SCANCODE_H :: Scancode.H
SCANCODE_I :: Scancode.I
SCANCODE_J :: Scancode.J
SCANCODE_K :: Scancode.K
SCANCODE_L :: Scancode.L
SCANCODE_M :: Scancode.M
SCANCODE_N :: Scancode.N
SCANCODE_O :: Scancode.O
SCANCODE_P :: Scancode.P
SCANCODE_Q :: Scancode.Q
SCANCODE_R :: Scancode.R
SCANCODE_S :: Scancode.S
SCANCODE_T :: Scancode.T
SCANCODE_U :: Scancode.U
SCANCODE_V :: Scancode.V
SCANCODE_W :: Scancode.W
SCANCODE_X :: Scancode.X
SCANCODE_Y :: Scancode.Y
SCANCODE_Z :: Scancode.Z

SCANCODE_1 :: Scancode.NUM1
SCANCODE_2 :: Scancode.NUM2
SCANCODE_3 :: Scancode.NUM3
SCANCODE_4 :: Scancode.NUM4
SCANCODE_5 :: Scancode.NUM5
SCANCODE_6 :: Scancode.NUM6
SCANCODE_7 :: Scancode.NUM7
SCANCODE_8 :: Scancode.NUM8
SCANCODE_9 :: Scancode.NUM9
SCANCODE_0 :: Scancode.NUM0

SCANCODE_RETURN :: Scancode.RETURN
SCANCODE_ESCAPE :: Scancode.ESCAPE
SCANCODE_BACKSPACE :: Scancode.BACKSPACE
SCANCODE_TAB :: Scancode.TAB
SCANCODE_SPACE :: Scancode.SPACE

SCANCODE_MINUS :: Scancode.MINUS
SCANCODE_EQUALS :: Scancode.EQUALS
SCANCODE_LEFTBRACKET :: Scancode.LEFTBRACKET
SCANCODE_RIGHTBRACKET :: Scancode.RIGHTBRACKET
SCANCODE_BACKSLASH :: Scancode.BACKSLASH
SCANCODE_NONUSHASH :: Scancode.NONUSHASH
SCANCODE_SEMICOLON :: Scancode.SEMICOLON
SCANCODE_APOSTROPHE :: Scancode.APOSTROPHE
SCANCODE_GRAVE :: Scancode.GRAVE
SCANCODE_COMMA :: Scancode.COMMA
SCANCODE_PERIOD :: Scancode.PERIOD
SCANCODE_SLASH :: Scancode.SLASH

SCANCODE_CAPSLOCK :: Scancode.CAPSLOCK

SCANCODE_F1 :: Scancode.F1
SCANCODE_F2 :: Scancode.F2
SCANCODE_F3 :: Scancode.F3
SCANCODE_F4 :: Scancode.F4
SCANCODE_F5 :: Scancode.F5
SCANCODE_F6 :: Scancode.F6
SCANCODE_F7 :: Scancode.F7
SCANCODE_F8 :: Scancode.F8
SCANCODE_F9 :: Scancode.F9
SCANCODE_F10 :: Scancode.F10
SCANCODE_F11 :: Scancode.F11
SCANCODE_F12 :: Scancode.F12

SCANCODE_PRINTSCREEN :: Scancode.PRINTSCREEN
SCANCODE_SCROLLLOCK :: Scancode.SCROLLLOCK
SCANCODE_PAUSE :: Scancode.PAUSE
SCANCODE_INSERT :: Scancode.INSERT
SCANCODE_HOME :: Scancode.HOME
SCANCODE_PAGEUP :: Scancode.PAGEUP
SCANCODE_DELETE :: Scancode.DELETE
SCANCODE_END :: Scancode.END
SCANCODE_PAGEDOWN :: Scancode.PAGEDOWN
SCANCODE_RIGHT :: Scancode.RIGHT
SCANCODE_LEFT :: Scancode.LEFT
SCANCODE_DOWN :: Scancode.DOWN
SCANCODE_UP :: Scancode.UP

SCANCODE_NUMLOCKCLEAR :: Scancode.NUMLOCKCLEAR
SCANCODE_KP_DIVIDE :: Scancode.KP_DIVIDE
SCANCODE_KP_MULTIPLY :: Scancode.KP_MULTIPLY
SCANCODE_KP_MINUS :: Scancode.KP_MINUS
SCANCODE_KP_PLUS :: Scancode.KP_PLUS
SCANCODE_KP_ENTER :: Scancode.KP_ENTER
SCANCODE_KP_1 :: Scancode.KP_1
SCANCODE_KP_2 :: Scancode.KP_2
SCANCODE_KP_3 :: Scancode.KP_3
SCANCODE_KP_4 :: Scancode.KP_4
SCANCODE_KP_5 :: Scancode.KP_5
SCANCODE_KP_6 :: Scancode.KP_6
SCANCODE_KP_7 :: Scancode.KP_7
SCANCODE_KP_8 :: Scancode.KP_8
SCANCODE_KP_9 :: Scancode.KP_9
SCANCODE_KP_0 :: Scancode.KP_0
SCANCODE_KP_PERIOD :: Scancode.KP_PERIOD

SCANCODE_NONUSBACKSLASH :: Scancode.NONUSBACKSLASH
SCANCODE_APPLICATION :: Scancode.APPLICATION
SCANCODE_POWER :: Scancode.POWER
SCANCODE_KP_EQUALS :: Scancode.KP_EQUALS
SCANCODE_F13 :: Scancode.F13
SCANCODE_F14 :: Scancode.F14
SCANCODE_F15 :: Scancode.F15
SCANCODE_F16 :: Scancode.F16
SCANCODE_F17 :: Scancode.F17
SCANCODE_F18 :: Scancode.F18
SCANCODE_F19 :: Scancode.F19
SCANCODE_F20 :: Scancode.F20
SCANCODE_F21 :: Scancode.F21
SCANCODE_F22 :: Scancode.F22
SCANCODE_F23 :: Scancode.F23
SCANCODE_F24 :: Scancode.F24
SCANCODE_EXECUTE :: Scancode.EXECUTE
SCANCODE_HELP :: Scancode.HELP
SCANCODE_MENU :: Scancode.MENU
SCANCODE_SELECT :: Scancode.SELECT
SCANCODE_STOP :: Scancode.STOP
SCANCODE_AGAIN :: Scancode.AGAIN
SCANCODE_UNDO :: Scancode.UNDO
SCANCODE_CUT :: Scancode.CUT
SCANCODE_COPY :: Scancode.COPY
SCANCODE_PASTE :: Scancode.PASTE
SCANCODE_FIND :: Scancode.FIND
SCANCODE_MUTE :: Scancode.MUTE
SCANCODE_VOLUMEUP :: Scancode.VOLUMEUP
SCANCODE_VOLUMEDOWN :: Scancode.VOLUMEDOWN
SCANCODE_KP_COMMA :: Scancode.KP_COMMA
SCANCODE_KP_EQUALSAS400 :: Scancode.KP_EQUALSAS400

SCANCODE_INTERNATIONAL1 :: Scancode.INTERNATIONAL1
SCANCODE_INTERNATIONAL2 :: Scancode.INTERNATIONAL2
SCANCODE_INTERNATIONAL3 :: Scancode.INTERNATIONAL3
SCANCODE_INTERNATIONAL4 :: Scancode.INTERNATIONAL4
SCANCODE_INTERNATIONAL5 :: Scancode.INTERNATIONAL5
SCANCODE_INTERNATIONAL6 :: Scancode.INTERNATIONAL6
SCANCODE_INTERNATIONAL7 :: Scancode.INTERNATIONAL7
SCANCODE_INTERNATIONAL8 :: Scancode.INTERNATIONAL8
SCANCODE_INTERNATIONAL9 :: Scancode.INTERNATIONAL9
SCANCODE_LANG1 :: Scancode.LANG1
SCANCODE_LANG2 :: Scancode.LANG2
SCANCODE_LANG3 :: Scancode.LANG3
SCANCODE_LANG4 :: Scancode.LANG4
SCANCODE_LANG5 :: Scancode.LANG5
SCANCODE_LANG6 :: Scancode.LANG6
SCANCODE_LANG7 :: Scancode.LANG7
SCANCODE_LANG8 :: Scancode.LANG8
SCANCODE_LANG9 :: Scancode.LANG9

SCANCODE_ALTERASE :: Scancode.ALTERASE
SCANCODE_SYSREQ :: Scancode.SYSREQ
SCANCODE_CANCEL :: Scancode.CANCEL
SCANCODE_CLEAR :: Scancode.CLEAR
SCANCODE_PRIOR :: Scancode.PRIOR
SCANCODE_RETURN2 :: Scancode.RETURN2
SCANCODE_SEPARATOR :: Scancode.SEPARATOR
SCANCODE_OUT :: Scancode.OUT
SCANCODE_OPER :: Scancode.OPER
SCANCODE_CLEARAGAIN :: Scancode.CLEARAGAIN
SCANCODE_CRSEL :: Scancode.CRSEL
SCANCODE_EXSEL :: Scancode.EXSEL

SCANCODE_KP_00 :: Scancode.KP_00
SCANCODE_KP_000 :: Scancode.KP_000
SCANCODE_THOUSANDSSEPARATOR :: Scancode.THOUSANDSSEPARATOR
SCANCODE_DECIMALSEPARATOR :: Scancode.DECIMALSEPARATOR
SCANCODE_CURRENCYUNIT :: Scancode.CURRENCYUNIT
SCANCODE_CURRENCYSUBUNIT :: Scancode.CURRENCYSUBUNIT
SCANCODE_KP_LEFTPAREN :: Scancode.KP_LEFTPAREN
SCANCODE_KP_RIGHTPAREN :: Scancode.KP_RIGHTPAREN
SCANCODE_KP_LEFTBRACE :: Scancode.KP_LEFTBRACE
SCANCODE_KP_RIGHTBRACE :: Scancode.KP_RIGHTBRACE
SCANCODE_KP_TAB :: Scancode.KP_TAB
SCANCODE_KP_BACKSPACE :: Scancode.KP_BACKSPACE
SCANCODE_KP_A :: Scancode.KP_A
SCANCODE_KP_B :: Scancode.KP_B
SCANCODE_KP_C :: Scancode.KP_C
SCANCODE_KP_D :: Scancode.KP_D
SCANCODE_KP_E :: Scancode.KP_E
SCANCODE_KP_F :: Scancode.KP_F
SCANCODE_KP_XOR :: Scancode.KP_XOR
SCANCODE_KP_POWER :: Scancode.KP_POWER
SCANCODE_KP_PERCENT :: Scancode.KP_PERCENT
SCANCODE_KP_LESS :: Scancode.KP_LESS
SCANCODE_KP_GREATER :: Scancode.KP_GREATER
SCANCODE_KP_AMPERSAND :: Scancode.KP_AMPERSAND
SCANCODE_KP_DBLAMPERSAND :: Scancode.KP_DBLAMPERSAND
SCANCODE_KP_VERTICALBAR :: Scancode.KP_VERTICALBAR
SCANCODE_KP_DBLVERTICALBAR :: Scancode.KP_DBLVERTICALBAR
SCANCODE_KP_COLON :: Scancode.KP_COLON
SCANCODE_KP_HASH :: Scancode.KP_HASH
SCANCODE_KP_SPACE :: Scancode.KP_SPACE
SCANCODE_KP_AT :: Scancode.KP_AT
SCANCODE_KP_EXCLAM :: Scancode.KP_EXCLAM
SCANCODE_KP_MEMSTORE :: Scancode.KP_MEMSTORE
SCANCODE_KP_MEMRECALL :: Scancode.KP_MEMRECALL
SCANCODE_KP_MEMCLEAR :: Scancode.KP_MEMCLEAR
SCANCODE_KP_MEMADD :: Scancode.KP_MEMADD
SCANCODE_KP_MEMSUBTRACT :: Scancode.KP_MEMSUBTRACT
SCANCODE_KP_MEMMULTIPLY :: Scancode.KP_MEMMULTIPLY
SCANCODE_KP_MEMDIVIDE :: Scancode.KP_MEMDIVIDE
SCANCODE_KP_PLUSMINUS :: Scancode.KP_PLUSMINUS
SCANCODE_KP_CLEAR :: Scancode.KP_CLEAR
SCANCODE_KP_CLEARENTRY :: Scancode.KP_CLEARENTRY
SCANCODE_KP_BINARY :: Scancode.KP_BINARY
SCANCODE_KP_OCTAL :: Scancode.KP_OCTAL
SCANCODE_KP_DECIMAL :: Scancode.KP_DECIMAL
SCANCODE_KP_HEXADECIMAL :: Scancode.KP_HEXADECIMAL

SCANCODE_LCTRL :: Scancode.LCTRL
SCANCODE_LSHIFT :: Scancode.LSHIFT
SCANCODE_LALT :: Scancode.LALT
SCANCODE_LGUI :: Scancode.LGUI
SCANCODE_RCTRL :: Scancode.RCTRL
SCANCODE_RSHIFT :: Scancode.RSHIFT
SCANCODE_RALT :: Scancode.RALT
SCANCODE_RGUI :: Scancode.RGUI

SCANCODE_MODE :: Scancode.MODE

SCANCODE_AUDIONEXT :: Scancode.AUDIONEXT
SCANCODE_AUDIOPREV :: Scancode.AUDIOPREV
SCANCODE_AUDIOSTOP :: Scancode.AUDIOSTOP
SCANCODE_AUDIOPLAY :: Scancode.AUDIOPLAY
SCANCODE_AUDIOMUTE :: Scancode.AUDIOMUTE
SCANCODE_MEDIASELECT :: Scancode.MEDIASELECT
SCANCODE_WWW :: Scancode.WWW
SCANCODE_MAIL :: Scancode.MAIL
SCANCODE_CALCULATOR :: Scancode.CALCULATOR
SCANCODE_COMPUTER :: Scancode.COMPUTER
SCANCODE_AC_SEARCH :: Scancode.AC_SEARCH
SCANCODE_AC_HOME :: Scancode.AC_HOME
SCANCODE_AC_BACK :: Scancode.AC_BACK
SCANCODE_AC_FORWARD :: Scancode.AC_FORWARD
SCANCODE_AC_STOP :: Scancode.AC_STOP
SCANCODE_AC_REFRESH :: Scancode.AC_REFRESH
SCANCODE_AC_BOOKMARKS :: Scancode.AC_BOOKMARKS

SCANCODE_BRIGHTNESSDOWN :: Scancode.BRIGHTNESSDOWN
SCANCODE_BRIGHTNESSUP :: Scancode.BRIGHTNESSUP
SCANCODE_DISPLAYSWITCH :: Scancode.DISPLAYSWITCH
SCANCODE_KBDILLUMTOGGLE :: Scancode.KBDILLUMTOGGLE
SCANCODE_KBDILLUMDOWN :: Scancode.KBDILLUMDOWN
SCANCODE_KBDILLUMUP :: Scancode.KBDILLUMUP
SCANCODE_EJECT :: Scancode.EJECT
SCANCODE_SLEEP :: Scancode.SLEEP

SCANCODE_APP1 :: Scancode.APP1
SCANCODE_APP2 :: Scancode.APP2

SCANCODE_AUDIOREWIND :: Scancode.AUDIOREWIND
SCANCODE_AUDIOFASTFORWARD :: Scancode.AUDIOFASTFORWARD
// odinfmt: enable

scancode_to_rune :: proc(sc: Scancode) -> rune {
	#partial switch sc {
	case .A:
		return 'a'
	case .B:
		return 'b'
	case .C:
		return 'c'
	case .D:
		return 'd'
	case .E:
		return 'e'
	case .F:
		return 'f'
	case .G:
		return 'g'
	case .H:
		return 'h'
	case .I:
		return 'i'
	case .J:
		return 'j'
	case .K:
		return 'k'
	case .L:
		return 'l'
	case .M:
		return 'm'
	case .N:
		return 'n'
	case .O:
		return 'o'
	case .P:
		return 'p'
	case .Q:
		return 'q'
	case .R:
		return 'r'
	case .S:
		return 's'
	case .T:
		return 't'
	case .U:
		return 'u'
	case .V:
		return 'v'
	case .W:
		return 'w'
	case .X:
		return 'x'
	case .Y:
		return 'y'
	case .Z:
		return 'z'
	case .NUM1:
		return '1'
	case .NUM2:
		return '2'
	case .NUM3:
		return '3'
	case .NUM4:
		return '4'
	case .NUM5:
		return '5'
	case .NUM6:
		return '6'
	case .NUM7:
		return '7'
	case .NUM8:
		return '8'
	case .NUM9:
		return '9'
	case .NUM0:
		return '0'
	case .SPACE:
		return ' '
	case .MINUS:
		return '-'
	case .EQUALS:
		return '='
	case .LEFTBRACKET:
		return '['
	case .RIGHTBRACKET:
		return ']'
	case .BACKSLASH:
		return '\\'
	case .SEMICOLON:
		return ';'
	case .APOSTROPHE:
		return '\''
	case .GRAVE:
		return '`'
	case .COMMA:
		return ','
	case .PERIOD:
		return '.'
	case .SLASH:
		return '/'
	case .RETURN:
		return '\r'
	case .TAB:
		return '\t'
	case .KP_1:
		return '1'
	case .KP_2:
		return '2'
	case .KP_3:
		return '3'
	case .KP_4:
		return '4'
	case .KP_5:
		return '5'
	case .KP_6:
		return '6'
	case .KP_7:
		return '7'
	case .KP_8:
		return '8'
	case .KP_9:
		return '9'
	case .KP_0:
		return '0'
	case .KP_PERIOD:
		return '.'
	case .KP_DIVIDE:
		return '/'
	case .KP_MULTIPLY:
		return '*'
	case .KP_MINUS:
		return '-'
	case .KP_PLUS:
		return '+'
	case .KP_EQUALS:
		return '='
	}
	return 0
}
