---@class Bogus_State
---@field val_name	string
---@field val_float	number
---@field val_int	integer
---@field val_fixed_arr	integer[]
---@field val_dict	table<string, integer>
---@field val_dict2	table<number, userdata>
---@field val_dyn_arr	string[]
---@field val_struct	Internal_Struct

---@class Internal_Struct
---@field field1	integer
---@field field2	integer

---@param a string
---@param b string
---@return integer
function func_b(a, b) end

---@param a table<string, integer>
---@param b table<userdata, string>
---@return table<string, number>
function func_c(a, b) end

---@param a integer
---@param b string
---@param c integer[]
---@return number
function func_a(a, b, c) end

