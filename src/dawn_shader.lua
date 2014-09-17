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
uniform vec4 far;
uniform vec4 near;

varying vec2 v_texcoord;
varying vec4 v_color;

void main() {
	float f = pow(v_texcoord.y, 0.5);
	gl_FragColor = mix(far, near, f);
}
]]

local sea_fs = [[
uniform sampler2D Texture0;
uniform highp float t;
uniform float t1;
uniform float sx;
uniform vec4 far;
uniform vec4 near;
uniform vec4 spec;
uniform vec4 refl;

varying vec2 v_texcoord;
varying vec4 v_color;

void main(void)
{
	vec2 tex_scale = vec2(0.5, 15.0);
	vec2 noise_speed = vec2(0.0, -0.08);

	vec2 tc = vec2(v_texcoord.x, pow(v_texcoord.y, 0.1));
	vec2 nc = fract(tc*tex_scale + t*noise_speed);

	vec4 noise = texture2D(Texture0, nc);
	float n = mix(noise.x, noise.y, t1);

	float w = (sin(tc.y*80.0 + n - t) + 1.0) * 0.5;
	w = abs(w - n*0.1);

	float x = n - pow(abs(tc.x-sx), 2.0) * 60.0;
	x = clamp(x, 0.0, 1.0);

	vec4 base = near * (1.0 + n*0.1);
	base.xyz += spec.xyz * (1.0 - pow(w, 0.15));
	base.xyz += refl.xyz * (1.0 - pow(w, x));
	gl_FragColor = mix(far, base, pow(tc.y, 3.0));
}
]]

local glow_fs = [[
uniform sampler2D texture0;

varying vec2 v_texcoord;
varying vec4 v_color;

void main() {
	vec4 tmp = texture2D(texture0, v_texcoord);
	gl_FragColor.xyz = clamp(tmp.xyz/tmp.w + v_color.xyz, 0.0, 1.0);
	gl_FragColor.w = 1.0;
	gl_FragColor *= tmp.w;
}
]]

local M = {}

function M.init()
	shader.load("sky", sky_fs, vs, {far="4f", near="4f"})
	shader.load("sea", sea_fs, vs,
		{
			t="1f", t1="1f",
			sx="1f",
			far="4f", near="4f", spec="4f", refl="4f"
		})
	shader.load("glow", glow_fs, vs)
end

return M