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

local NIGHT = {
	sky_far		= { 0.00, 0.00, 0.00, 1.00 },
	sky_near	= { 0.10, 0.10, 0.08, 1.00 },
	sea_far		= { 0.02, 0.02, 0.02, 1.00 },
	sea_near	= { 0.08, 0.08, 0.08, 1.00 },
	sea_spec	= { 0.15, 0.15, 0.15, 1.00 },
	sun_scale	= 1,
	sun_color	= { 0.00, 0.00, 0.00, 0.00 },
	glow_scale	= 1,
	glow_addi	= { 0.00, 0.00, 0.00, 0.00 },
}

local DAWN = {
	sky_far		= { 0.16, 0.52, 0.80, 1.00 },
	sky_near	= { 1.00, 0.80, 0.30, 1.00 },
	sea_far		= { 0.99, 0.85, 0.58, 1.00 },
	sea_near	= { 0.53, 0.43, 0.32, 1.00 },
	sea_spec	= { 1.00, 1.00, 0.60, 1.00 },
	sun_scale	= 1,
	sun_color	= { 0.92, 0.88, 0.74, 1.00 },
	glow_scale	= 3,
	glow_addi	= { 0.20, 0.20, 0.20, 1.00 },
}

local DAY = {
	sky_far		= { 0.17, 0.49, 0.71, 1.00 },
	sky_near	= { 0.60, 0.78, 0.88, 1.00 },
	sea_far		= { 0.70, 0.82, 0.91, 1.00 },
	sea_near	= { 0.06, 0.38, 0.53, 1.00 },
	sea_spec	= { 1.00, 1.00, 1.00, 1.00 },
	sun_scale	= 0.7,
	sun_color	= { 1.00, 1.00, 1.00, 1.00 },
	glow_scale	= 6,
	glow_addi	= { 1.00, 1.00, 1.00, 1.00 },
}

local SEQ = {
	NIGHT,		-- 00:00
	NIGHT,		-- 01:00
	NIGHT,		-- 02:00
	NIGHT,		-- 03:00
	NIGHT,		-- 04:00
	NIGHT,		-- 05:00
	DAWN,		-- 06:00
	DAY,		-- 07:00
	DAY,		-- 08:00
	DAY,		-- 09:00
	DAY,		-- 10:00
	DAY,		-- 11:00
	DAY,		-- 12:00
	DAY,		-- 13:00
	DAY,		-- 14:00
	DAY,		-- 15:00
	DAY,		-- 16:00
	DAY,		-- 17:00
	DAWN,		-- 18:00
	DAWN,		-- 19:00
	NIGHT,		-- 20:00
	NIGHT,		-- 21:00
	NIGHT,		-- 22:00
	NIGHT,		-- 23:00
	NIGHT,		-- 24:00 eq SEQ[1]
}

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


local M = {}

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

	-- objects
	self.v_sun = ej.sprite("dawn", "sun")
	self.v_moon = ej.sprite("dawn", "moon")
	self.v_glow = ej.sprite("dawn", "glow")

	-- init day
	self.v_time = 8

	self.v_t0x = 0  -- shader params
	self.v_t01 = 0
	self.v_t01_dir = 1
end

function M:update()
end

function M:draw()
	-- time
	self.v_time = self.v_time + 0.05
	if self.v_time > 24 then
		self.v_time = self.v_time - 24
	end

	local h = math.floor(self.v_time)
	local m = self.v_time - h
	print(string.format("%02d:%02d", h, m*60))

	local s1 = SEQ[h+1]
	local s2 = SEQ[h+2]

	-- sky
	self.v_sky.program_param.far = _mix4(s1.sky_far, s2.sky_far, m)
	self.v_sky.program_param.near = _mix4(s1.sky_near, s2.sky_near, m)

	-- sea
	self.v_sea.program_param.far = _mix4(s1.sea_far, s2.sea_far, m)
	self.v_sea.program_param.near = _mix4(s1.sea_near, s2.sea_near, m)
	self.v_sea.program_param.spec = _mix4(s1.sea_spec, s2.sea_spec, m)

	-- objects
	local ptw = math.pi / 12
	local x, y, s, c, gs, ga

	x = sw * (0.5 + math.cos((self.v_time-6)*ptw)*0.4)
	y = sh * SKY_PCT * (1 - math.sin((self.v_time-6)*ptw)*0.8)
	s = _mix1(s1.sun_scale, s2.sun_scale, m)
	c = _mixc(s1.sun_color, s2.sun_color, m)
	gs = _mix1(s1.glow_scale, s2.glow_scale, m)
	ga = _mixc(s1.glow_addi, s2.glow_addi, m)

	print(string.format("sun_color=0x%08x glow_additive=0x%08x", c, ga))

	self.v_sun:ps(x, y, s)
	self.v_sun.color = c
	self.v_glow:ps(x, y, gs)
	self.v_glow.additive = ga

	-- self.v_moon:ps(
	-- 	sw * (0.5 + math.cos((self.v_time-18)*ptw)*0.4),
	-- 	sh * SKY_PCT * (1.2 - math.sin((self.v_time-18)*ptw)*0.8),
	-- 	1 - 0.3 * math.sin((self.v_time-18)*ptw))

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
	self.v_glow:draw()
	self.v_sun:draw()
	-- self.v_moon:draw()
	self.v_sea:draw()
end

return M