local libos = require "libos"
local utils = require "utils"

-- file templates
local TEMPLATE_BODY = [[
return {

%s
}
]]

local TEMPLATE_LABEL = [[
{
	type = "label",
	id = %d,
	export = "default_label",
	width = 200,
	height = 100,
	font = "",
	align = 0,
	size = 16,
	color = 0xffffffff,
	noedge = true,
},
]]

local TEMPLATE_PICTURE = [[
{
	type = "picture",
	id = %d,
	export = "%s",
	{
		tex = %d,
		src = { %d, %d, %d, %d, %d, %d, %d, %d },
		screen = { %d, %d, %d, %d, %d, %d, %d, %d },
	},
},
]]

local TEMPLATE_ANIMATION = [[
{
	type = "animation",
	id = %d,
	export = "%s",
	component = {
%s	},
%s
},
]]

-- ejoy2d package
local pkg_mt = {}
pkg_mt.__index = pkg_mt

function pkg_mt:add_img(img)
	table.insert(self.sheets, img)  -- treat image as sheet with a single rect
	local item = {}
	item.type = "picture"
	item.id = self:_next_id()
	item.data = {#self.sheets, {0,0}, {img.w,img.h}, {img.ox,img.oy}}
	self.items[img.name] = item
end

function pkg_mt:add_sheet(sheet)
	table.insert(self.sheets, sheet)
	for _,v in ipairs(sheet.imgs) do
		local item = {}
		item.type = "picture"
		item.id = self:_next_id()
		item.data = {#self.sheets, v.pos, v.size, v.offset}  -- texid, pos, size, offset
		self.items[v.name] = item
	end
end

function pkg_mt:add_anim(anim)  -- image name sequence
	local item = {}
	item.type = "animation"
	item.id = self:_next_id()
	item.data = anim.actions  -- frames
	self.items[anim.name] = item
end

function pkg_mt:save(path)
	-- save image sheet
	for i,v in ipairs(self.sheets) do
		local picture_path = string.format("%s/%s.%d", path, self.name, i)
		v:save(picture_path, false)
	end

	-- save description file
	local body = string.format(TEMPLATE_LABEL, self:_next_id())
	for k,v in pairs(self.items) do
		if v.type == "picture" then
			body = body..self:_serialize_picture(v.id, k, v.data)
		end
	end
	for k,v in pairs(self.items) do
		if v.type == "animation" then
			body = body..self:_serialize_animation(v.id, k, v.data)
		end
	end

	local all = string.format(TEMPLATE_BODY, body)
	local lua_path = string.format("%s/%s.lua", path, self.name)
	libos:writefile(lua_path, all)

	utils:logf("ejoy2d package <%s> saved", self.name)
end

function pkg_mt:_serialize_picture(id, name, data)
	local pos = data[2]
	local size = data[3]
	local offset = data[4]

	local tex = data[1]

	local sl = pos[1]
	local sr = pos[1] + size[1]
	local st = pos[2]
	local sb = pos[2] + size[2]

	local dl = (-size[1]/2 + offset[1]) * 16  -- left = (-w/2 + ox) * 16
	local dr = (size[1]/2 + offset[1]) * 16
	local dt = (-size[2]/2 + offset[2]) * 16
	local db = (size[2]/2 + offset[2]) * 16

	return string.format(TEMPLATE_PICTURE, id, name, tex,
		sl, st, sl, sb, sr, sb, sr, st,
		dl, dt, dl, db, dr, db, dr, dt)
end

function pkg_mt:_serialize_animation(id, name, data)
	local com2idx = {}
	local idx2com = {}

	local str_a = ""  -- action section

	for _,act in ipairs(data) do
		local frame_list = {}
		for _,frm in ipairs(act) do  -- multiple frames in one action
			local com_list = {}
			for _,com in ipairs(frm) do  -- multiple components in one frame
				if not com2idx[com.name] then
					table.insert(idx2com, com.name)
					com2idx[com.name] = #idx2com - 1  -- idx base 0
				end

				local idx_only = true

				local str_com = string.format("{ index = %d, ", com2idx[com.name])
				if com.scale or com.rot or com.trans then
					idx_only = false
					local mat = utils:create_matrix(com.scale, com.rot, com.trans)
					str_com = str_com..string.format("mat = { %d, %d, %d, %d, %d, %d }, ",
						mat[1], mat[2], mat[3], mat[4], mat[5], mat[6])
				end
				if com.color then
					idx_only = false
					str_com = str_com..string.format("color = 0x%08x", com.color)
				end
				if com.additive then
					idx_only = false
					str_com = str_com..string.format("additive = 0x%08x", com.additive)
				end
				str_com = str_com.."}"

				if idx_only then
					table.insert(com_list, tostring(com2idx[com.name]))  -- simple component without attributes
				else
					table.insert(com_list, str_com)
				end
			end
			local str_f = string.format("\t\t{ %s },", table.concat(com_list, ", "))
			table.insert(frame_list, str_f)
		end
		str_a = string.format("\t{\n%s\n\t},", table.concat(frame_list, "\n"))
	end

	local str_c = ""  -- component section
	for _,com in ipairs(idx2com) do
		local item = self.items[com]
		assert(item, "item <"..com.."> not exist, refered in animation <"..self.name..">")
		str_c = string.format("%s\t\t{ id = %d },\n", str_c, item.id)  -- one component one line
	end

	return string.format(TEMPLATE_ANIMATION, id, name, str_c, str_a)
end

function pkg_mt:_next_id()
	local ret = self._id
	self._id = self._id + 1
	return ret
end

-- ejoy2d package module
local M = {}

function M:new_pkg(name)
	local pkg = {}
	pkg._id = 0
	pkg.name = name
	pkg.sheets = {}
	pkg.items = {}  -- name:item
	return setmetatable(pkg, pkg_mt)
end

return M