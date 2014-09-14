local ej = require "ejoy2d"

local sw = 768
local sh = 1024
-- local sw = 320
-- local sh = 568

local SKY_PCT = 0.6

local SKY_TEX_W = 1
local SKY_TEX_H = 1
local SEA_TEX_W = 64
local SEA_TEX_H = 64

local M = {}

function M:init()
	self.v_sky = ej.sprite("dawn", "blank")
	self.v_sky.program = "sky"
	self.v_sky.program_param.far = { 0.17, 0.49, 0.71, 1 }
	self.v_sky.program_param.near = { 0.60, 0.78, 0.88, 1 }

	self.v_sky:ps(sw/2, sh*SKY_PCT/2)
	self.v_sky:sr(sw/SKY_TEX_W, sh*SKY_PCT/SKY_TEX_H)

	self.v_sea = ej.sprite("dawn", "noise")
	self.v_sea.program = "sea"
	self.v_sea.program_param.far = { 0.70, 0.82, 0.91, 1 }
	self.v_sea.program_param.near = { 0.06, 0.38, 0.53, 1 }
	self.v_sea.program_param.spec = { 0.80, 0.80, 0.80, 1 }

	self.v_sea:ps(sw/2, sh*(1+SKY_PCT)/2)
	self.v_sea:sr(sw/SEA_TEX_W, sh*(1-SKY_PCT)/SEA_TEX_H)

	self.v_time = 0
end

function M:update()
end

function M:draw()
	self.v_time = self.v_time + 0.05
	self.v_sea.program_param.t = self.v_time

	self.v_sky:draw()
	self.v_sea:draw()
end

return M