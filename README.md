# What is it

This is a repository for lua scripts running on szieke's embLua ported to STM32H723 board. The project is still buggy and evolving.

# The hardware

The hardware is a STM32H723 board with a ST-Link V2 and a USB RS-232 board. They are all available in Aliexpress at very low cost.

![{Connection}](image/connect.png)

# The script files

ssed.lua is a lua script that provides a simple editor running on embLua. The script depends on api provided by a pecial version of "uc" module (firmware) that provides uc.getch(), uc.loadfile(), uc.savefile(). 

gen_maze.lua is a lua script to generate a maze. It is to test using setmetatable() for OOP style coding in lua. 
