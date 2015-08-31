local oal = require "oal"
local source_state = oal.source_state

local ad = require "oal.decode"


local SOURCE_LIMIT = 32
assert(SOURCE_LIMIT >0 and SOURCE_LIMIT <= 0x7f) -- th source region [0, 0x7f]


local M = {
  load_map = {},
  playing_source = {},
}


local group_mt = {}
group_mt.__index = group_mt


function M:_set_playing(file_path)
  local playing_source = self.playing_source
  if not playing_source[file_path] then
    playing_source[file_path] = setmetatable({}, {__mode = "kv"})
  end
end


local function _suffix(s)
  return string.gsub(s, "^.+%.(.+)$", "%1")
end


local support_type = {
  ["caf"] = function (file_path)
    return ad.decode_tools(file_path, "caf")
  end,
  ["mp3"] = function (file_path)
    return ad.decode_tools(file_path, "mp3")
  end,
  ["wav"] = function (file_path)
    return ad.decode_wav(file_path)
  end,
}

function M:load(file_path, file_type)
  file_type = file_type or _suffix(file_path)
  local func = support_type[file_type]
  if not func then
    error("cannot load "..file_path)
  end

  local entry = self.load_map[file_path]
  if not entry then
    local info = func(file_path)
    print("load: "..tostring(info))
    local buffer_id = oal.create_bufferid()
    oal.buffer_bind(buffer_id, info)
    entry = {
      -- info = info,  -- for collect garbage
      buffer_id = buffer_id,
    }
    self.load_map[file_path] = entry
    self:_set_playing(file_path)
  end
end


function M:unload(file_path)
  local entry = self.load_map[file_path]
  local source_map = self.playing_source[file_path]
  if not entry then
    return
  end

  for k,v in pairs(source_map) do
    k:clear()
    source_map[k] = nil
  end

  self.load_map[file_path] = nil
end


function M:listen_position(x, y, z)
  oal.listen_position(x, y, z)
end


function M:cur_playing_count(file_path)
  local count = 0
  local playing_source = M.playing_source
  local info = playing_source[file_path]
  if info then
    for source_id, v in pairs(info) do
      if v and source_id:state() == source_state.playing then
        count = count + 1
      end
    end
  end
  return count
end


function M:create_group(source_count)
  source_count = source_count or 1

  if source_count > SOURCE_LIMIT then 
    error("source count is too big.(>.."..tostring(source_count)..")")
  end

  local raw = {
    source_count = source_count,
    source_list = {},
    cur_indx = 1,
    is_close = false,
  }

  local source_list = raw.source_list
  for i=1,source_count do
    source_list[i] = {
      idx = i,
      file = false,
      source_id = oal.create_source(),
      version = 0,
    }
  end

  return setmetatable(raw, group_mt)
end


local function _update_version(version)
  return (version+1) & 0x00ffffff -- region [0, 0x00ffffff]
end


local function _gen_handle(idx, version)
  return idx << 24 | version
end


local function _unpack_handle(handle)
  local version = handle & 0x00ffffff
  local idx = handle >> 24
  return idx, version
end

--------------- group  -------------------

function group_mt:_get_source_handle()
  local cur_indx = self.cur_indx
  local source_count = self.source_count
  local ret = self.source_list[cur_indx]
  self.cur_indx = cur_indx % source_count + 1

  return ret
end


function group_mt:add(file_path, loop, pitch, gain, max_distance)
  pitch = pitch or 1.0
  max_distance = max_distance or 100.0
  gain = gain or 1.0
  loop = loop or false

  local playing_source = M.playing_source
  local entry = M.load_map[file_path]
  if entry then
    local group_handle = self:_get_source_handle()
    local version = group_handle.version
    local source_id = group_handle.source_id

    version = _update_version(version)
    group_handle.version = version
    local file = group_handle.file
    group_handle.file = file_path

    if file then
      playing_source[file][source_id] = nil
    end
    playing_source[file_path][source_id] = true

    oal.source_set(source_id, entry.buffer_id, pitch, max_distance, gain, loop)
    return _gen_handle(group_handle.idx, version)
  end
end


local function _audio_op(self, op, handle, ...)
  if self.is_close then 
    return 
  end

  local idx, version = _unpack_handle(handle)
  local group_handle = self.source_list[idx]

  if not group_handle or  
     group_handle.version ~= version or 
     not M.load_map[group_handle.file]
    then
    -- print("_audio_op false:", op, handle, version, group_handle.version)
    return false 
  end

  local source_id = group_handle.source_id
  source_id[op](source_id, ...)
  return true
end


function group_mt:stop(handle)
  return _audio_op(self, "stop", handle)
end


function group_mt:open()
  self.is_close = false
end

function group_mt:close()
  for i,handle in ipairs(self.source_list) do
    handle.source_id:stop()
  end
  self.is_close = true
end


function group_mt:rewind(handle)
  return _audio_op(self, "rewind", handle)
end


function group_mt:pause(handle)
  return _audio_op(self, "pause", handle)
end


function group_mt:play(handle)
  return _audio_op(self, "play", handle)
end


function group_mt:position(handle, x, y, z)
  return _audio_op(self, "position", handle, x, y, z)
end


function group_mt:volume(handle, v)
  return _audio_op(self, "volume", handle, v)
end


return M

