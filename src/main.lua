local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local pack = require "ejoy2d.simplepackage"

local shader = require "dawn_shader"
local scene = require "dawn_scene"

-- init
local function init()
	pack.load {
		pattern = fw.WorkDir.."package/?",
		"dawn",
	}

	shader:init()
	scene:init()
end

init()

-- game callback
local game = {}

function game.update()
	scene:update()
end

function game.drawframe()
	ej.clear(0xff000000)
	scene:draw()
end

local last_x, last_y
function game.touch(what, x, y)
	if what == "BEGIN" then
		scene:pause_time(true)
	elseif what == "END" then
		scene:pause_time(false)
	elseif what == "MOVE" then
		local dx = x - last_x
		local dy = y - last_y
		if math.abs(dx) > math.abs(dy) then
			scene:shift_time(dx)
		else
			scene:shift_speed(dy)
		end
	end

	last_x = x
	last_y = y
end

function game.message(...)
end

function game.handle_error(...)
end

function game.on_resume()
end

function game.on_pause()
end

ej.start(game)
