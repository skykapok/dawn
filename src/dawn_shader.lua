local shader = require "ejoy2d.shader"

local vs = [[
attribute vec4 position;
attribute vec2 texcoord;
attribute vec4 color;

varying vec2 v_texcoord;
varying vec4 v_color;

void main() {
	gl_Position = position + vec4(-1,1,0,0);
	v_texcoord = texcoord;
	v_color = color;
}
]]

local sky_fs = [[
uniform sampler2D texture0;
uniform vec4 top;
uniform vec4 bottom;

varying vec2 v_texcoord;
varying vec4 v_color;

void main() {
	float f = texture2D(texture0, v_texcoord).r;
	gl_FragColor = mix(top, bottom, f);
}
]]

local M = {}

function M.init()
	shader.load("sky", sky_fs, vs, {top="4f", bottom="4f"})
end

return M