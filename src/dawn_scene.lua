local ej = require "ejoy2d"
local CONFIG = require "dawn_config"

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

local function _mix1(c1, c2, f)
	return c1*(1-f) + c2*f
end

local function _mix4(c1, c2, f)
	return {
		c1[1]*(1-f) + c2[1]*f,
		c1[2]*(1-f) + c2[2]*f,
		c1[3]*(1-f) + c2[3]*f,
		c1[4]*(1-f) + c2[4]*f,
	}
end

local function _mixc(c1, c2, f)
	local c = _mix4(c1, c2, f)
	return
		math.floor(c[4]*255) * math.pow(2, 24) +
		math.floor(c[1]*255) * math.pow(2, 16) +
		math.floor(c[2]*255) * math.pow(2, 8) +
		math.floor(c[3]*255)
end

function M:init()
	-- sky
	self.v_sky = ej.sprite("dawn", "blank")
	self.v_sky.program = "sky"
	self.v_sky:ps(sw*0.5, sh*SKY_PCT*0.5)
	self.v_sky:sr(sw/SKY_TEX_W, sh*SKY_PCT/SKY_TEX_H)

	-- sea
	self.v_sea = ej.sprite("dawn", "noise")
	self.v_sea.program = "sea"
	self.v_sea:ps(sw*0.5, sh*(1+SKY_PCT)*0.5)
	self.v_sea:sr(sw/SEA_TEX_W, sh*(1-SKY_PCT)/SEA_TEX_H)

	-- sun
	self.v_sun = ej.sprite("dawn", "sun")
	self.v_sun_glow = ej.sprite("dawn", "glow")
	self.v_sun_glow.program = "glow"

	-- moon
	self.v_moon = ej.sprite("dawn", "moon")
	self.v_moon_glow = ej.sprite("dawn", "glow")
	self.v_moon_glow.program = "glow"

	-- init day
	self.v_time = 16

	self.v_t0x = 0  -- shader params
	self.v_t01 = 0
	self.v_t01_dir = 1
end

function M:update()
end

function M:draw()
	-- time
	self.v_time = self.v_time + 0.02
	if self.v_time > 24 then
		self.v_time = self.v_time - 24
	end

	local h = math.floor(self.v_time)
	local m = self.v_time - h
	print(string.format("%02d:%02d", h, m*60))

	local s1 = CONFIG[h+1]
	local s2 = CONFIG[h+2]

	-- sky
	self.v_sky.program_param.far = _mix4(s1.sky_far, s2.sky_far, m)
	self.v_sky.program_param.near = _mix4(s1.sky_near, s2.sky_near, m)

	-- sea
	self.v_sea.program_param.far = _mix4(s1.sea_far, s2.sea_far, m)
	self.v_sea.program_param.near = _mix4(s1.sea_near, s2.sea_near, m)
	self.v_sea.program_param.spec = _mix4(s1.sea_spec, s2.sea_spec, m)

	-- objects
	local ptw = math.pi / 12
	local rx = sw * 0.45
	local ry = sh * 0.45
	local x, y, s, c, gs, gc

	x = sw*0.5 + math.cos((self.v_time-6)*ptw)*rx
	y = sh*SKY_PCT*1.1 - math.sin((self.v_time-6)*ptw)*ry
	s = _mix1(s1.sun_scale, s2.sun_scale, m)
	c = _mixc(s1.sun_color, s2.sun_color, m)
	gs = _mix1(s1.sun_glow_scale, s2.sun_glow_scale, m)
	gc = _mixc(s1.sun_glow_color, s2.sun_glow_color, m)
	self.v_sun:ps(x, y, s)
	self.v_sun.color = c
	self.v_sun_glow:ps(x, y, gs)
	self.v_sun_glow.color = gc

	x = sw*0.5 + math.cos((self.v_time-18)*ptw)*rx
	y = sh*SKY_PCT*1.1 - math.sin((self.v_time-18)*ptw)*ry
	s = _mix1(s1.moon_scale, s2.moon_scale, m)
	c = _mixc(s1.moon_color, s2.moon_color, m)
	gs = _mix1(s1.moon_glow_scale, s2.moon_glow_scale, m)
	gc = _mixc(s1.moon_glow_color, s2.moon_glow_color, m)
	self.v_moon:ps(x, y, s)
	self.v_moon.color = c
	self.v_moon_glow:ps(x, y, gs)
	self.v_moon_glow.color = gc

	-- update shader param
	local d = 0.05
	self.v_t0x = self.v_t0x + d
	self.v_t01 = self.v_t01 + d*self.v_t01_dir
	if self.v_t01 > 1 or self.v_t01 < 0 then
		self.v_t01_dir = -self.v_t01_dir
	end

	self.v_sea.program_param.t = self.v_t0x

	-- draw
	self.v_sky:draw()
	self.v_sun_glow:draw()
	self.v_sun:draw()
	self.v_moon_glow:draw()
	self.v_moon:draw()
	self.v_sea:draw()
end

return M