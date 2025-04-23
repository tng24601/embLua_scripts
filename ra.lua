Data = {}
while true do
	local c = uc.getch()
	if c == 4 then
		break
	else
		Data = Data .. string.char(c)
	end
end
