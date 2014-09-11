-- utils module
local M = {
	logf = function (...) end
}

function M:_logf(...)
	print("[SCRIPT] "..string.format(...))
end

function M:enable_log()
	self.logf = self._logf
end

function M:check_ext(file_name, ext)
	return string.find(file_name, ext, 1, true) == #file_name - #ext + 1
end

function M:trim_slash(path)
	if path[#path] == "\\" or path[#path] == "/" then
		return string.sub(path, 1, -2)
	else
		return path
	end
end

function M:_matrix_identity()
	return {1, 0, 0, 1, 0, 0}
end

-- ejoy2d uses a 2x3 row-major matrix (the third column is 0,0,1)
function M:_matrix_multiply(m1, m2)
	return {
		m1[1]*m2[1] + m1[2]*m2[3],
		m1[1]*m2[2] + m1[2]*m2[4],
		m1[3]*m2[1] + m1[4]*m2[3],
		m1[3]*m2[2] + m1[4]*m2[4],
		m1[5]*m2[1] + m1[6]*m2[3] + m2[5],
		m1[5]*m2[2] + m1[6]*m2[4] + m2[6],
	}
end

function M:create_matrix(scale, rot, trans)
	local s = self:_matrix_identity()
	local r = self:_matrix_identity()
	local t = self:_matrix_identity()

	if scale then
		s[1] = scale[1]
		s[4] = scale[2]
	end

	if rot then
		local rad = math.rad(rot)  -- rot is in degree
		local cos = math.cos(rad)
		local sin = math.sin(rad)
		r[1] = cos
		r[2] = sin
		r[3] = -sin
		r[4] = cos
	end

	if trans then
		t[5] = trans[1]
		t[6] = trans[2]
	end

	local ret = self:_matrix_multiply(self:_matrix_multiply(s, r), t)
	ret[1] = math.floor(ret[1] * 1024)  -- ejoy2d uses "fix-point" number
	ret[2] = math.floor(ret[2] * 1024)
	ret[3] = math.floor(ret[3] * 1024)
	ret[4] = math.floor(ret[4] * 1024)
	ret[5] = math.floor(ret[5] * 16)
	ret[6] = math.floor(ret[6] * 16)

	return ret
end

return M