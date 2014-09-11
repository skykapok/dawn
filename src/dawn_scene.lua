local ej = require "ejoy2d"

local sw = 768
local sh = 1024

local SKY_PCT = 0.6

local SKY_TEX_W = 2
local SKY_TEX_H = 100

local M = {}

function M:init()
	self.v_sky = ej.sprite("dawn", "sky")
	self.v_sky.program = "sky"
	self.v_sky.program_param.top = { 0.537, 0.725, 0.816, 1 }
	self.v_sky.program_param.bottom = { 0.792, 0.843, 0.859, 1 }

	self.v_sky:ps(sw/2, sh*SKY_PCT/2)
	self.v_sky:sr(sw/SKY_TEX_W, sh*SKY_PCT/SKY_TEX_H)
end

function M:update()
end

function M:draw()
	self.v_sky:draw()
end

return M