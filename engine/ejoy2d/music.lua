local audio = require "audio"
local ad = require "oal.decode"

local M = {
  is_close = false,
  _cur_playing_file_path = false,
  _cur_loop = false,
}

local function _gen_ios_hd_func()
  local cur_file_path = false
  local hd_ios = ad.decode_hardware_ios
  local m = {}

  function m.load(file_path)
    hd_ios.load(file_path)
    cur_file_path = file_path
  end 

  function m.play(file_path, loop)
    if file_path ~= cur_file_path then
      m.load(file_path)
    end
    hd_ios.play(loop or false)
  end

  function m.stop()
    hd_ios.stop()
  end
  return m
end

local function _gen_oal_hd_func()
  local music_group = audio:create_group()
  local music_handle = false
  local m = {}
  local cur_file_path = false

  function m.load(file_path)
    if file_path ~= cur_file_path then
      audio:unload(file_path)
    end
    audio:load(file_path)
  end

  function m.play(file_path, loop)
    if file_path ~= cur_file_path then
      m.load(file_path)
    end
    music_handle = music_group:add(file_path, loop)
    music_group:play(music_handle)
  end

  function m.stop()
    if music_handle then
      music_group:stop(music_handle)
    end
  end

  return m
end


local bg_t = ad.decode_hardware_ios and "ios_hd" or "oal"
local _bg_music_handles = {
  ["ios_hd"] = _gen_ios_hd_func(),
  ["oal"]    = _gen_oal_hd_func(),
}

local _cur_bg_handle = _bg_music_handles[bg_t]
assert(_cur_bg_handle, bg_t)



function M.load(file_path)
  _cur_bg_handle.load(file_path)
end

function M.play(file_path, loop)
  M._cur_playing_file_path = file_path
  M._cur_loop = loop
  
  if M.is_close then
    return
  end
  _cur_bg_handle.play(file_path, loop)
end


function M.stop()
  _cur_bg_handle.stop()
end


function M.open()
  local file_path = M._cur_playing_file_path
  local loop = M._cur_loop
  M.is_close = false
  if file_path then
    _cur_bg_handle.play(file_path, loop)
  end
end

function M.close()
  _cur_bg_handle.stop()
  M.is_close = true
end


return M
