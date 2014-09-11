-- container for rects
local bin_mt = {}
bin_mt.__index = bin_mt

local function _debug(...)
	-- print("[BPDEBUG] "..string.format(...))
end

function bin_mt:_find_node(w, h)
	local node = {}  -- result
	local best_ssf = false
	local best_lsf = false

	for _,v in ipairs(self.free) do
		if v.w >= w and v.h >= h then
			local dw = math.abs(v.w - w)
			local dh = math.abs(v.h - h)
			local ssf = math.min(dw, dh)  -- short side fit
			local lsf = math.max(dw, dh)  -- long side fit

			if not best_ssf or
				ssf < best_ssf or
				(ssf == best_ssf and lsf < best_lsf) then
				node.x = v.x  -- record the best node
				node.y = v.y
				node.w = w
				node.h = h
				best_ssf = ssf
				best_lsf = lsf
			end
		end
	end

	return node
end

function bin_mt:_free_contain(node, skip)
	for _,v in ipairs(self.free) do
		if v ~= skip then  -- our node is splited from this freenode, skip it
			if v.x <= node.x and
				v.x + v.w >= node.x + node.w and
				v.y <= node.y and
				v.y + v.h >= node.y + node.h then
				return true
			end
		end
	end

	return false
end

function bin_mt:_split_free(freenode, node, splits)
	_debug("split free node(%d,%d,%d,%d)", freenode.x, freenode.y, freenode.w, freenode.h)

	if node.x > freenode.x + freenode.w or
		node.x + node.w <= freenode.x or
		node.y > freenode.y + freenode.h or
		node.y + node.h <= freenode.y then
		_debug("\tno intersects")
		return false
	end

	if node.y > freenode.y then  -- try top
		local n = {}
		n.x = freenode.x
		n.y = freenode.y
		n.w = freenode.w
		n.h = node.y - freenode.y
		if not self:_free_contain(n, freenode) then
			table.insert(splits, n)
			_debug("\ttop(%d,%d,%d,%d) splited", n.x, n.y, n.w, n.h)
		else
			_debug("\ttop area is covered by other freenode")
		end
	end

	if node.y + node.h < freenode.y + freenode.h then  -- try bottom
		local n = {}
		n.x = freenode.x
		n.y = node.y + node.h
		n.w = freenode.w
		n.h = (freenode.y + freenode.h) - (node.y + node.h)
		if not self:_free_contain(n, freenode) then
			table.insert(splits, n)
			_debug("\tbottom(%d,%d,%d,%d) splited", n.x, n.y, n.w, n.h)
		else
			_debug("\tbottom area is covered by other freenode")
		end
	end

	if node.x > freenode.x then  -- try left
		local n = {}
		n.x = freenode.x
		n.y = freenode.y
		n.w = node.x - freenode.x
		n.h = freenode.h
		if not self:_free_contain(n, freenode) then
			table.insert(splits, n)
			_debug("\tleft(%d,%d,%d,%d) splited", n.x, n.y, n.w, n.h)
		else
			_debug("\tleft area is covered by other freenode")
		end
	end

	if node.x + node.w < freenode.x + freenode.w then  -- try right
		local n = {}
		n.x = node.x + node.w
		n.y = freenode.y
		n.w = (freenode.x + freenode.w) - (node.x + node.w)
		n.h = freenode.h
		if not self:_free_contain(n, freenode) then
			table.insert(splits, n)
			_debug("\tright(%d,%d,%d,%d) splited", n.x, n.y, n.w, n.h)
		else
			_debug("\tright area is covered by other freenode")
		end
	end

	return true
end

function bin_mt:insert(w, h)
	_debug("***** insert new rect(%d,%d) *****", w, h)

	local node = self:_find_node(w, h)
	if not node.h then return end  -- not found
	_debug("found new node(%d,%d,%d,%d)", node.x, node.y, node.w, node.h)

	local splits = {}
	local i = 1
	while i <= #self.free do  -- split free node into small pieces
		if self:_split_free(self.free[i], node, splits) then
			table.remove(self.free, i)
		else
			i = i + 1
		end
	end

	for i,v in ipairs(splits) do
		table.insert(self.free, v)
	end

	return node
end

-- binpacking algorithm module
local M = {}

function M:new_bin(w, h)
	local node = {x=0, y=0, w=w, h=h}
	local bin = {}
	bin.free = {node}  -- free node list
	return setmetatable(bin, bin_mt)
end

return M