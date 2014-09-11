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

function game.touch(what, x, y)
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
