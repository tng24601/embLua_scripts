local line = {}
local mode = "n"
local cur_row = 1
local cur_col = 1
local need_quit = false
local need_screen_update = false
local need_line_update = false
local key_msg = ""
local debug_count = 0

local WIN_ROW = 25
local TAB_STR = "  "
local STATUS_ROW = WIN_ROW + 1
local buf_start_row = 1

local COL_GREEN = 32
local COL_WHITE = 37

-- ANSI Escape codes
local function ansi_printxy(r, c, s)
	print(string.format("\27[%d;%dH%s", r, c, s))
end

local function ansi_movexy(r, c)
	print(string.format("\27[%d;%dH", r, c))
end

local function ansi_clrscr()
	print("\27[2J")
end

local function ansi_home()
	print("\27[H")
end

local function ansi_clreol()
	print("\27[K")
end

local function ansi_color(fg)
	print(string.format("\27[%dm", fg))
end

local function getline()
	if (#line == 0) or (line[cur_row + buf_start_row - 1] == nil) then
		return ""
	else
		return string.gsub(line[cur_row + buf_start_row - 1], "\t", TAB_STR)
	end
end

local function setline(ln)
	line[cur_row + buf_start_row - 1] = ln
end

local function getlinelen()
	if line[cur_row + buf_start_row - 1] == nil then
		return 0
	end
	return #line[cur_row + buf_start_row - 1]
end

local function update_status_line()
	-- update cursor
	local char_under_cursor
	if #line == 0 then
		char_under_cursor = " "
		cur_col = 1
	else
		char_under_cursor = string.sub(getline(), cur_col, cur_col)
	end

	if char_under_cursor == "" then
		char_under_cursor = " " -- append mode cursor
	end

	local mode_str
	if mode == "n" then
		mode_str = "NORMAL"
	elseif mode == "i" then
		mode_str = "INSERT"
	elseif mode == "A" then
		mode_str = "APPEND"
	elseif mode == ":" then
		mode_str = "COMMAND"
	elseif mode == "d" then
		mode_str = "DELETE"
	else
		mode_str = "ERROR"
	end
	ansi_printxy(
		STATUS_ROW,
		1,
		string.format(
			"%5d,%-5d (%5d) %-10s \27[%dm%s\27[%dm",
			cur_row,
			cur_col,
			buf_start_row,
			key_msg,
			COL_GREEN,
			mode_str,
			COL_WHITE
		)
	)
end

local function update_line(i)
	need_line_update = false
	if (i + buf_start_row - 1) > #line then
		ansi_printxy(i, 1, "")
	else
		local line_notab = string.gsub(line[i + buf_start_row - 1], "\t", TAB_STR)
		ansi_printxy(i, 1, line_notab)
	end
	ansi_clreol()
end

local function update_screen()
	need_screen_update = false
	ansi_home()
	for i = 1, WIN_ROW do
		update_line(i)
	end
	if cur_col <= 0 then
		cur_col = 1
	end
end

local function mv_cursor_right()
	if cur_col <= getlinelen() then
		cur_col = cur_col + 1
	end
	need_line_update = true
end

local function mv_cursor_left()
	if cur_col >= 2 then
		cur_col = cur_col - 1
	end
	need_line_update = true
end

local function mv_cursor_up()
	if cur_row >= 2 then
		cur_row = cur_row - 1
	end
	need_line_update = true
end

local function mv_cursor_down()
	if cur_row < #line then
		cur_row = cur_row + 1
	end
	need_line_update = true
end

local function scroll_up()
	if buf_start_row > 1 then
		buf_start_row = buf_start_row - 1
	end
	need_screen_update = true
end

local function scroll_down()
	if buf_start_row < #line - WIN_ROW + 1 then
		buf_start_row = buf_start_row + 1
	end
	need_screen_update = true
end

local function handle_delete(key)
	if key == string.byte("d") then
		table.remove(line, cur_row + buf_start_row - 1)
		if cur_row > #line then -- deleted last line, set to last line
			cur_row = #line
		end
		cur_col = 1
	end
	need_screen_update = true
	mode = "n"
end

local function handle_insert(key)
	if key == 0x1b then
		mode = "n"
	elseif key == 0x08 then -- backspace
		if cur_col >= 2 then
			setline(string.sub(getline(), 0, cur_col - 2) .. string.sub(getline(), cur_col))
			-- mv_cursor_right()
			if cur_col <= 0 then
				cur_col = 1
			else
				cur_col = cur_col - 1
			end
		end
	elseif key == 0x0d then
		local after_CR = string.sub(getline(), cur_col)
		setline(string.sub(getline(), 0, cur_col - 1))
		table.insert(line, cur_row + buf_start_row, after_CR)
		buf_start_row = buf_start_row + 1
		cur_col = 1
	else
		setline(string.sub(getline(), 0, cur_col - 1) .. string.char(key) .. string.sub(getline(), cur_col))
		mv_cursor_right()
	end
end

local function handle_colon(fn, key)
	if key == string.byte("w") then
		local flines = ""
		for _, v in pairs(line) do
			flines = flines .. v .. "\n"
		end
		local bytewrite = uc.savefile(fn, flines)
		key_msg = "Wrote " .. bytewrite
		flines = ""
		collectgarbage()
	elseif key == string.byte("q") then
		need_quit = true
	end
	mode = "n"
end

local function handle_norm(key)
	if key == string.byte("i") then
		mode = "i"
	elseif key == string.byte("d") then
		mode = "d"
	elseif key == string.byte("h") then
		mv_cursor_left()
	elseif key == string.byte("l") then
		mv_cursor_right()
	elseif key == string.byte("k") then
		if cur_row == 1 then -- at top
			scroll_up()
		else
			mv_cursor_up()
		end
		if cur_col > getlinelen() then
			cur_col = getlinelen()
		end
	elseif key == string.byte("j") then
		if cur_row < WIN_ROW then
			mv_cursor_down()
		else
			scroll_down()
		end
		if cur_col > getlinelen() then
			cur_col = getlinelen()
		end
	elseif key == string.byte("x") then
		setline(string.sub(getline(), 1, cur_col - 1) .. string.sub(getline(), cur_col + 1))
		if cur_col > getlinelen() then
			cur_col = getlinelen()
		end
		if cur_col <= 0 then
			cur_col = 1
		end
		need_line_update = true
	elseif key == string.byte("J") then
		local merged = getline() .. line[cur_row + buf_start_row]
		table.remove(line, cur_row + buf_start_row - 1)
		table.remove(line, cur_row + buf_start_row - 1)
		table.insert(line, cur_row + buf_start_row - 1, merged)
		need_screen_update = true
	elseif key == string.byte(":") then
		mode = ":"
	end
end

function getstr()
	local res = ""
	while true do
		local c = uc.getch()
		if c == 13 then
			return res
		else
			print(string.char(c))
			res = res .. string.char(c)
		end
	end
end

--- Main ---
print("Fname?\n")
local fn = getstr()

local fline = uc.loadfile(fn)
for s in string.gmatch(fline, "([^\n]+)") do
	table.insert(line, s)
end
fline = ""
collectgarbage()

key_msg = fn

ansi_color(COL_WHITE)
ansi_clrscr()
update_screen()
update_status_line()
ansi_movexy(cur_row, cur_col)

while true do
	local key_code = uc.getch()
	if mode == "n" then
		handle_norm(key_code)
	elseif mode == "i" then
		handle_insert(key_code)
	elseif mode == "d" then
		handle_delete(key_code)
	elseif mode == ":" then
		handle_colon(fn, key_code)
	else
		mode = "n"
	end

	if need_screen_update then
		update_screen()
	end
	if need_line_update then
		update_line(cur_row)
	end
	-- update_screen()
	update_status_line()
	ansi_movexy(cur_row, cur_col)
	if need_quit then
		break
	end
end
