require("ffi")

func_b("hey", "there")

local btn_config = {
    size = Size_Fit_Text_And_Grow,
    color = Color_Amber_700,
    padding = { top = 20, bottom = 20, right = 10, left = 10 },
    text_justify = { Text_Align_Center, Text_Align_Center }
}

local some_panel = function()
    local _, a = begin_container(
        {

        },
        {
            direction = Dir_Vertical
        },
        nil,
        nil,
        function()
            text_button(
                "waht the what heya",
                btn_config,
                nil,
                0
            )
            local sigs = text_button(
                "there",
                btn_config,
                nil,
                0
            )
            local new_val = circular_knob(
                "my knob",
                knob_value,
                0, 100,
                {
                },
                nil,
                75,
                nil
            )
            knob_value = new_val
        end
    )
end

local a, b, c, d, ptr = begin_draggable_window(
    "my first lua window",
    {
        direction = Dir_Vertical,
    }
)

some_panel()
some_panel()
some_panel()
edit_text_box(
    some_string,
    {
        color = Color_Emerald_500,
        size = { { Size_Kind_Fixed, 150 }, { Size_Kind_Fixed, 70 } }
    },
    nil, nil
)
end_draggable_window(ptr)
