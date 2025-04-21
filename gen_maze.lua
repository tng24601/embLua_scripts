-- define a 2D array
local MAZE_ROW = 12
local MAZE_COL = 18
local MAZE_START_ROW = math.floor(MAZE_ROW / 2)
local MAZE_START_COL = math.floor(MAZE_COL / 2)
-- Maze class
function Maze()
	return setmetatable({
		left = {}, -- lett wall
		bottom = {}, -- bottom wall
		used_stack = {}, -- a stack record the cell path visited
		used_map = {}, -- a 2D map to mark which cells are visited
		init = function(self)
			for r = 1, MAZE_ROW do
				self.left[r] = {}
				self.bottom[r] = {}
				self.used_map[r] = {}
				for c = 1, MAZE_COL do
					self.left[r][c] = "|"
					self.bottom[r][c] = "_"
					self.used_map[r][c] = " " -- space is not used. X is used
				end
			end
		end,
		push = function(self, rc)
			table.insert(self.used_stack, rc)
			self:using(rc) -- interestingly you can call a not yet defined method
		end,
		pop = function(self)
			return table.remove(self.used_stack)
		end,
		print = function(self)
			print(string.rep("_", 2 * MAZE_COL) .. "\n")
			for r = 1, MAZE_ROW do
				for c = 1, MAZE_COL do
					print(self.left[r][c])
					print(self.bottom[r][c])
				end
				print("|\n")
			end
		end,
		-- mark a cell is used
		using = function(self, rc)
			self.used_map[rc[1]][rc[2]] = "X"
		end,
		-- return true if the cell is used/visited
		is_used = function(self, rc)
			return self.used_map[rc[1]][rc[2]] == "X"
		end,
		next = function(self, rc)
			local r = rc[1] -- rc is a tuple
			local c = rc[2]
			local first_dir = math.floor(math.random() * 4) -- 0, 1, 2, 3 -> up, right, down, left
			for i = 0, 3 do
				local dir = (first_dir + i) % 4
				if dir == 0 then
					if (r ~= 1) and self.bottom[r - 1][c] == "_" and not (self:is_used({ r - 1, c })) then
						self.bottom[r - 1][c] = " "
						self:push({ r - 1, c })
						-- self:using({ r - 1, c })
						return { r - 1, c }
					end
				elseif dir == 1 then
					if (c ~= MAZE_COL) and self.left[r][c + 1] == "|" and not (self:is_used({ r, c + 1 })) then
						self.left[r][c + 1] = " "
						self:push({ r, c + 1 })
						-- self:using({ r, c + 1 })
						return { r, c + 1 }
					end
				elseif dir == 2 then
					if (r ~= MAZE_ROW) and self.bottom[r][c] == "_" and not (self:is_used({ r + 1, c })) then
						self.bottom[r][c] = " "
						self:push({ r + 1, c })
						-- self:using({ r + 1, c })
						return { r + 1, c }
					end
				else
					if (c ~= 1) and self.left[r][c] == "|" and not (self:is_used({ r, c - 1 })) then
						self.left[r][c] = " "
						self:push({ r, c - 1 })
						-- self:using({ r, c - 1 })
						return { r, c - 1 }
					end
				end
			end -- for
			-- all 4 directions are occupied, backtrack
			table.remove(self.used_stack)
			return self.used_stack[#self.used_stack]
		end,
	}, {
		__index = function(self, key)
			return rawget(self.used_stack, key)
		end,
	})
end
-- end of Maze class
-- main
math.randomseed(uc.gettick())
local next_cell = { MAZE_START_ROW, MAZE_START_COL }
local m = Maze()
m:init()
m:push(next_cell)
m:using(next_cell)
m:print()
while true do
	next_cell = m:next(next_cell)
	print(string.char(27) .. "[H" .. "\n") -- home
	print(next_cell[1], next_cell[2], "\n")
	m:print()
	if next_cell[1] == MAZE_START_ROW and next_cell[2] == MAZE_START_COL then
		m:print()
		break
	end
	-- local tmp = io.read("*l")
end
