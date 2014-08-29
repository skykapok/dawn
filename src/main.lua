local ej = require "ejoy2d"

local game = {}

function game.update()
end

function game.drawframe()
	ej.clear(0xff008080)
end

function game.touch(what, x, y)
    print("touch", what, x, y)
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
