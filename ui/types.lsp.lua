---@meta

-- ---- Primitive aliases ----

---@alias Semantic_Color_Token  integer
---@alias Box_Size_Type         integer
---@alias Layout_Direction      integer
---@alias Alignment             integer
---@alias Position_Floating_Type integer
---@alias Overflow_Mode         integer
---@alias Text_Alignment        integer

-- ---- Box_Size_Type enum integers (Size_Kind_*) ----
-- Use when building a [2]Box_Size manually:
-- e.g. size = { {Size_Kind_Fixed, 200}, {Size_Kind_Fit_Children, 0} }

Size_Kind_Fit_Children          = 0
Size_Kind_Fit_Children_And_Grow = 1
Size_Kind_Fit_Text              = 2
Size_Kind_Fit_Text_And_Grow     = 3
Size_Kind_Grow                  = 4
Size_Kind_Fixed                 = 5
Size_Kind_Percent               = 6


-- ---- Size shorthands ([2]Box_Size constants, both axes) ----
-- Mirrors the Odin constants. Use directly as the size field.
-- e.g. size = Size_Fit_Text


---@type {[1]: Box_Size, [2]: Box_Size}
Size_Fit_Children               = { { Size_Kind_Fit_Children, 1 }, { Size_Kind_Fit_Children, 1 } }
---@type {[1]: Box_Size, [2]: Box_Size}
Size_Fit_Children_And_Grow      = { { Size_Kind_Fit_Children_And_Grow, 1 }, { Size_Kind_Fit_Children_And_Grow, 1 } }
---@type {[1]: Box_Size, [2]: Box_Size}
Size_Grow                       = { { Size_Kind_Grow, 1 }, { Size_Kind_Grow, 1 } }
---@type {[1]: Box_Size, [2]: Box_Size}
Size_Fit_Text                   = { { Size_Kind_Fit_Text, 1 }, { Size_Kind_Fit_Text, 1 } }
---@type {[1]: Box_Size, [2]: Box_Size}
Size_Fit_Text_And_Grow          = { { Size_Kind_Fit_Text_And_Grow, 1 }, { Size_Kind_Fit_Text_And_Grow, 1 } }

-- ---- Box_Flag bitmask constants (Flag_*) ----
-- Combine with bit.bor(): e.g. bit.bor(Flag_Frosted, Flag_Scrollable)

Flag_Clickable                  = 0
Flag_Scrollable                 = 1
Flag_Scrollbar                  = 2
Flag_View_Scroll                = 3
Flag_Draw                       = 4
Flag_Line                       = 5
Flag_Draw_Text                  = 6
Flag_Draw_Icon                  = 7
Flag_Text_Center                = 8
Flag_Text_Left                  = 9
Flag_Text_Right                 = 10
Flag_Edit_Text                  = 11
Flag_Track_Step                 = 12
Flag_Draw_Border                = 13
Flag_Draw_Background            = 14
Flag_Drop_Shadow                = 15
Flag_Clip_Children              = 16
Flag_Hot_Animation              = 17
Flag_Ignore_Parent_Disabled     = 18
Flag_Active_Animation           = 19
Flag_Draggable                  = 20
Flag_Drag_Drop_Source           = 21
Flag_Drag_Drop_Sink             = 22
Flag_Fixed_Width                = 23
Flag_Floating_X                 = 24
Flag_No_Offset                  = 25
Flag_Frosted                    = 26
Flag_Glow                       = 27
Flag_Knob_Ring                  = 28
Flag_Emit_Light                 = 29

-- ---- Enum: Layout_Direction ----
-- Globals are prefixed with Dir_

Dir_Horizontal                  = 0
Dir_Vertical                    = 1

-- ---- Enum: Alignment ----
-- Globals are prefixed with Align_

Align_Start                     = 0
Align_Center                    = 1
Align_End                       = 2
Align_Space_Around              = 3
Align_Space_Between             = 4

-- ---- Enum: Text_Alignment ----
-- Globals are prefixed with TextAlign_

Text_Align_Center               = 0
Text_Align_Start                = 1
Text_Align_End                  = 2

-- ---- Enum: Position_Floating_Type ----
-- Globals are prefixed with Float_

Float_Not_Floating              = 0
Float_Relative_Root             = 1
Float_Relative_Parent           = 2
Float_Relative_Other            = 3
Float_Top_Center                = 4
Float_Top_Left                  = 5
Float_Top_Right                 = 6
Float_Bottom_Center             = 7
Float_Bottom_Left               = 8
Float_Bottom_Right              = 9
Float_Center_Center             = 10
Float_Center_Left               = 11
Float_Center_Right              = 12
Float_Absolute_Pixel            = 13

-- ---- Enum: Overflow_Mode ----
-- Globals are prefixed with Overflow_

Overflow_Visible                = 0
Overflow_Auto                   = 1
Overflow_Scroll                 = 2
Overflow_Hidden                 = 3

-- ---- Enum: Semantic_Color_Token ----
-- Globals are prefixed with Color_

-- Material design semantic tokens
Color_Primary                   = 0
Color_On_Primary                = 1
Color_Primary_Container         = 2
Color_On_Primary_Container      = 3
Color_Secondary                 = 4
Color_On_Secondary              = 5
Color_Secondary_Container       = 6
Color_On_Secondary_Container    = 7
Color_Tertiary                  = 8
Color_On_Tertiary               = 9
Color_Tertiary_Container        = 10
Color_On_Tertiary_Container     = 11
Color_Error                     = 12
Color_On_Error                  = 13
Color_Error_Container           = 14
Color_On_Error_Container        = 15
Color_Warning                   = 16
Color_On_Warning                = 17
Color_Warning_Container         = 18
Color_On_Warning_Container      = 19
Color_Background                = 20
Color_On_Background             = 21
Color_Surface                   = 22
Color_On_Surface                = 23
Color_Surface_Variant           = 24
Color_On_Surface_Variant        = 25
Color_Surface_Dim               = 26
Color_Surface_Bright            = 27
Color_Surface_Container_Lowest  = 28
Color_Surface_Container_Low     = 29
Color_Surface_Container         = 30
Color_Surface_Container_High    = 31
Color_Surface_Container_Highest = 32
Color_Outline                   = 33
Color_Outline_Variant           = 34
Color_Inverse_Surface           = 35
Color_Inverse_On_Surface        = 36
Color_Inverse_Primary           = 37
Color_Scrim                     = 38
Color_Shadow                    = 39
Color_Inactive                  = 40
Color_On_Inactive               = 41

-- Tailwind palette (42-301)
Color_Slate_50                  = 42; Color_Slate_100 = 43; Color_Slate_200 = 44; Color_Slate_300 = 45
Color_Slate_400                 = 46; Color_Slate_500 = 47; Color_Slate_600 = 48; Color_Slate_700 = 49
Color_Slate_800                 = 50; Color_Slate_900 = 51; Color_Slate_950 = 52
Color_Gray_50                   = 53; Color_Gray_100 = 54; Color_Gray_200 = 55; Color_Gray_300 = 56
Color_Gray_400                  = 57; Color_Gray_500 = 58; Color_Gray_600 = 59; Color_Gray_700 = 60
Color_Gray_800                  = 61; Color_Gray_900 = 62; Color_Gray_950 = 63
Color_Zinc_50                   = 64; Color_Zinc_100 = 65; Color_Zinc_200 = 66; Color_Zinc_300 = 67
Color_Zinc_400                  = 68; Color_Zinc_500 = 69; Color_Zinc_600 = 70; Color_Zinc_700 = 71
Color_Zinc_800                  = 72; Color_Zinc_900 = 73; Color_Zinc_950 = 74
Color_Neutral_50                = 75; Color_Neutral_100 = 76; Color_Neutral_200 = 77; Color_Neutral_300 = 78
Color_Neutral_400               = 79; Color_Neutral_500 = 80; Color_Neutral_600 = 81; Color_Neutral_700 = 82
Color_Neutral_800               = 83; Color_Neutral_900 = 84; Color_Neutral_950 = 85
Color_Stone_50                  = 86; Color_Stone_100 = 87; Color_Stone_200 = 88; Color_Stone_300 = 89
Color_Stone_400                 = 90; Color_Stone_500 = 91; Color_Stone_600 = 92; Color_Stone_700 = 93
Color_Stone_800                 = 94; Color_Stone_900 = 95; Color_Stone_950 = 96
Color_Red_50                    = 97; Color_Red_100 = 98; Color_Red_200 = 99; Color_Red_300 = 100
Color_Red_400                   = 101; Color_Red_500 = 102; Color_Red_600 = 103; Color_Red_700 = 104
Color_Red_800                   = 105; Color_Red_900 = 106; Color_Red_950 = 107
Color_Orange_50                 = 108; Color_Orange_100 = 109; Color_Orange_200 = 110; Color_Orange_300 = 111
Color_Orange_400                = 112; Color_Orange_500 = 113; Color_Orange_600 = 114; Color_Orange_700 = 115
Color_Orange_800                = 116; Color_Orange_900 = 117; Color_Orange_950 = 118
Color_Amber_50                  = 119; Color_Amber_100 = 120; Color_Amber_200 = 121; Color_Amber_300 = 122
Color_Amber_400                 = 123; Color_Amber_500 = 124; Color_Amber_600 = 125; Color_Amber_700 = 126
Color_Amber_800                 = 127; Color_Amber_900 = 128; Color_Amber_950 = 129
Color_Yellow_50                 = 130; Color_Yellow_100 = 131; Color_Yellow_200 = 132; Color_Yellow_300 = 133
Color_Yellow_400                = 134; Color_Yellow_500 = 135; Color_Yellow_600 = 136; Color_Yellow_700 = 137
Color_Yellow_800                = 138; Color_Yellow_900 = 139; Color_Yellow_950 = 140
Color_Lime_50                   = 141; Color_Lime_100 = 142; Color_Lime_200 = 143; Color_Lime_300 = 144
Color_Lime_400                  = 145; Color_Lime_500 = 146; Color_Lime_600 = 147; Color_Lime_700 = 148
Color_Lime_800                  = 149; Color_Lime_900 = 150; Color_Lime_950 = 151
Color_Green_50                  = 152; Color_Green_100 = 153; Color_Green_200 = 154; Color_Green_300 = 155
Color_Green_400                 = 156; Color_Green_500 = 157; Color_Green_600 = 158; Color_Green_700 = 159
Color_Green_800                 = 160; Color_Green_900 = 161; Color_Green_950 = 162
Color_Emerald_50                = 163; Color_Emerald_100 = 164; Color_Emerald_200 = 165; Color_Emerald_300 = 166
Color_Emerald_400               = 167; Color_Emerald_500 = 168; Color_Emerald_600 = 169; Color_Emerald_700 = 170
Color_Emerald_800               = 171; Color_Emerald_900 = 172; Color_Emerald_950 = 173
Color_Teal_50                   = 174; Color_Teal_100 = 175; Color_Teal_200 = 176; Color_Teal_300 = 177
Color_Teal_400                  = 178; Color_Teal_500 = 179; Color_Teal_600 = 180; Color_Teal_700 = 181
Color_Teal_800                  = 182; Color_Teal_900 = 183; Color_Teal_950 = 184
Color_Cyan_50                   = 185; Color_Cyan_100 = 186; Color_Cyan_200 = 187; Color_Cyan_300 = 188
Color_Cyan_400                  = 189; Color_Cyan_500 = 190; Color_Cyan_600 = 191; Color_Cyan_700 = 192
Color_Cyan_800                  = 193; Color_Cyan_900 = 194; Color_Cyan_950 = 195
Color_Sky_50                    = 196; Color_Sky_100 = 197; Color_Sky_200 = 198; Color_Sky_300 = 199
Color_Sky_400                   = 200; Color_Sky_500 = 201; Color_Sky_600 = 202; Color_Sky_700 = 203
Color_Sky_800                   = 204; Color_Sky_900 = 205; Color_Sky_950 = 206
Color_Blue_50                   = 207; Color_Blue_100 = 208; Color_Blue_200 = 209; Color_Blue_300 = 210
Color_Blue_400                  = 211; Color_Blue_500 = 212; Color_Blue_600 = 213; Color_Blue_700 = 214
Color_Blue_800                  = 215; Color_Blue_900 = 216; Color_Blue_950 = 217
Color_Indigo_50                 = 218; Color_Indigo_100 = 219; Color_Indigo_200 = 220; Color_Indigo_300 = 221
Color_Indigo_400                = 222; Color_Indigo_500 = 223; Color_Indigo_600 = 224; Color_Indigo_700 = 225
Color_Indigo_800                = 226; Color_Indigo_900 = 227; Color_Indigo_950 = 228
Color_Violet_50                 = 229; Color_Violet_100 = 230; Color_Violet_200 = 231; Color_Violet_300 = 232
Color_Violet_400                = 233; Color_Violet_500 = 234; Color_Violet_600 = 235; Color_Violet_700 = 236
Color_Violet_800                = 237; Color_Violet_900 = 238; Color_Violet_950 = 239
Color_Purple_50                 = 240; Color_Purple_100 = 241; Color_Purple_200 = 242; Color_Purple_300 = 243
Color_Purple_400                = 244; Color_Purple_500 = 245; Color_Purple_600 = 246; Color_Purple_700 = 247
Color_Purple_800                = 248; Color_Purple_900 = 249; Color_Purple_950 = 250
Color_Fuchsia_50                = 251; Color_Fuchsia_100 = 252; Color_Fuchsia_200 = 253; Color_Fuchsia_300 = 254
Color_Fuchsia_400               = 255; Color_Fuchsia_500 = 256; Color_Fuchsia_600 = 257; Color_Fuchsia_700 = 258
Color_Fuchsia_800               = 259; Color_Fuchsia_900 = 260; Color_Fuchsia_950 = 261
Color_Pink_50                   = 262; Color_Pink_100 = 263; Color_Pink_200 = 264; Color_Pink_300 = 265
Color_Pink_400                  = 266; Color_Pink_500 = 267; Color_Pink_600 = 268; Color_Pink_700 = 269
Color_Pink_800                  = 270; Color_Pink_900 = 271; Color_Pink_950 = 272
Color_Rose_50                   = 273; Color_Rose_100 = 274; Color_Rose_200 = 275; Color_Rose_300 = 276
Color_Rose_400                  = 277; Color_Rose_500 = 278; Color_Rose_600 = 279; Color_Rose_700 = 280
Color_Rose_800                  = 281; Color_Rose_900 = 282; Color_Rose_950 = 283

-- ---- Struct types ----

---@class Box_Size
---@field [1] Box_Size_Type  e.g. Size_Fixed, Size_Grow, Size_Fit_Children
---@field [2] number         pixels for Fixed, ratio 0-1 for Percent/Grow, ignored for Fit_*

---@class Box_Padding
---@field left?   integer
---@field top?    integer
---@field right?  integer
---@field bottom? integer

---@class Box_Border
---@field left?   integer
---@field top?    integer
---@field right?  integer
---@field bottom? integer

---@class Box_Config
---@field color?           Semantic_Color_Token   Background color
---@field text_color?      Semantic_Color_Token
---@field glow_color?      Semantic_Color_Token
---@field border_color?    Semantic_Color_Token
---@field corner_radius?   integer
---@field edge_softness?   integer
---@field font_size?       integer
---@field z_index?         integer
---@field line_thickness?  integer
---@field border?          Box_Border
---@field padding?         Box_Padding            Space inside the box around children
---@field margin?          Box_Padding            Space outside the box
---@field size?            {[1]: Box_Size, [2]: Box_Size}   {x_size, y_size}
---@field max_size?        integer[]              {max_width, max_height}
---@field min_size?        integer[]              {min_width, min_height}
---@field floating_type?   Position_Floating_Type
---@field floating_offset? number[]               {x, y} ratio 0-1 from anchor
---@field text_justify?    Text_Alignment[]       {horizontal, vertical}
---@field overflow_x?      Overflow_Mode
---@field overflow_y?      Overflow_Mode

---@class Box_Child_Layout
---@field direction?            Layout_Direction
---@field gap_horizontal?       integer
---@field gap_vertical?         integer
---@field alignment_horizontal? Alignment
---@field alignment_vertical?   Alignment

---@class Box_Signals
---@field clicked        boolean
---@field double_clicked boolean
---@field right_clicked  boolean
---@field hovering       boolean
---@field pressed        boolean
---@field released       boolean
---@field dragged_over   boolean
---@field dropped_on     boolean
---@field scrolled_up    boolean
---@field scrolled_down  boolean
---@field box_ptr        userdata   Opaque pointer to the underlying Box; pass to hover_help_text etc.

---@class Slider_Signals
---@field track Box_Signals
---@field grip  Box_Signals

---@class Virtual_List_State
---@field first_visible integer   Index of first item to render (0-based, inclusive)
---@field last_visible  integer   Index of last item to render (0-based, inclusive)
---@field total_items   integer
---@field item_size     integer   Pixel height (or 0 if virtualization is disabled)
---@field direction     Layout_Direction
---@field box_ptr       userdata

-- ---- Widget functions ----

---@param label string
---@param config Box_Config
---@param id? string
---@param flags? integer  bit.bor(Flag_Frosted, Flag_Scrollable) etc.
---@return Box_Signals
function text_button(label, config, id, flags) end

---@param config Box_Config
---@param id? string
---@param flags? integer
---@return Box_Signals
function button(config, id, flags) end

---@param label string
---@param config Box_Config
---@param id? string
---@param flags? integer
---@return Box_Signals
function text(label, config, id, flags) end

---@param codepoint integer   Unicode codepoint of the icon glyph
---@param hover_text string
---@param config Box_Config
---@param id? string
---@param flags? integer
---@return Box_Signals
function icon(codepoint, hover_text, config, id, flags) end

---@param codepoint integer
---@param hover_text string
---@param config Box_Config
---@param id? string
---@param flags? integer
---@return Box_Signals
function icon_button(codepoint, hover_text, config, id, flags) end

--- Open a container. Must be followed by end_container(box) unless a callback is provided.
---@param config Box_Config
---@param layout Box_Child_Layout
---@param id? string
---@param flags? integer
---@param callback? fun()   If provided, called immediately and container is auto-closed.
---@return Box_Signals, userdata
function begin_container(config, layout, id, flags, callback) end

--- Close a container opened by begin_container.
---@param box userdata   Second return value from begin_container
function end_container(box) end

---@param config Box_Config
---@param id? string
---@param flags? integer
---@return Box_Signals
function line(config, id, flags) end

--- Render a tooltip anchored below main_box. Call only when the widget is hovering.
---@param label string
---@param signals Box_Signals   Signals table from any widget (uses box_ptr field)
function hover_help_text(label, signals) end

--- Immediate-mode vertical slider. Pass current value in, get updated value back.
---@param value  number   Current slider value
---@param min    number
---@param max    number
---@param config Box_Config
---@param id?    string
---@param flags? integer
---@return number new_value, Box_Signals track_signals, Box_Signals grip_signals
function vertical_slider(value, min, max, config, id, flags) end

--- Immediate-mode integer number edit box. Pass current value in, get updated value back.
---@param value  integer  Current value
---@param min    integer
---@param max    integer
---@param config Box_Config
---@param id?    string
---@param flags? integer
---@return integer new_value, Box_Signals signals
function edit_number_box(value, min, max, config, id, flags) end

--- Immediate-mode single-line text edit box. Pass current string in, get updated string back.
---@param value  string   Current text
---@param config Box_Config
---@param id?    string
---@param flags? integer
---@return string new_value, Box_Signals signals
function edit_text_box(value, config, id, flags) end

--- Immediate-mode circular knob. Pass current value in, get updated value back.
---@param label        string
---@param value        number   Current value
---@param min          number
---@param max          number
---@param config       Box_Config
---@param id?          string
---@param knob_size?   number   Diameter in pixels (default 60)
---@param logarithmic? boolean  (default false)
---@param extra_flags? integer
---@return number new_value
function circular_knob(label, value, min, max, config, id, knob_size, logarithmic, extra_flags) end

--- Open a draggable floating window. The title bar (including close and maximise buttons) is
--- built internally. Add your own children between begin/end, then call end_draggable_window.
---@param title        string
---@param child_layout Box_Child_Layout   Layout for the user's children (not the title bar)
---@param id?          string
---@param extra_flags? integer
---@return Box_Signals container_signals, Box_Signals close_signals, Box_Signals maximise_signals, boolean maximised, userdata box_ptr
function begin_draggable_window(title, child_layout, id, extra_flags) end

--- Close a draggable window opened by begin_draggable_window.
---@param box_ptr userdata   5th return value from begin_draggable_window
function end_draggable_window(box_ptr) end

--- Open a virtualized scrollable list. Returns a state table with first_visible/last_visible
--- so the caller only renders the visible slice. Must be followed by end_virtual_list(state).
---@param config      Box_Config
---@param layout      Box_Child_Layout
---@param total_items integer
---@param item_size   integer   Fixed item height in pixels. Pass 0 to disable virtualization.
---@param id?         string
---@param flags?      integer
---@return Virtual_List_State
function begin_virtual_list(config, layout, total_items, item_size, id, flags) end

--- Close a virtual list opened by begin_virtual_list.
---@param state Virtual_List_State   Table returned by begin_virtual_list
function end_virtual_list(state) end

---@class Bogus_State
---@field val_name	string
---@field val_float	number
---@field val_int	integer
---@field val_fixed_arr	integer[]
---@field val_dict	table<string, integer>
---@field val_dict0	table<number, userdata>
---@field val_dyn_arr	string[]
---@field val_struct	Internal_Struct

---@class Internal_Struct
---@field field-1	integer
---@field field0	integer
