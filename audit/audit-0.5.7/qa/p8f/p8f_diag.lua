local function dump(tag)
  local props = {"current-vo","hwdec-current","video-params","video-out-params","osd-dimensions","frame-drop-count","decoder-frame-drop-count","vo-delayed-frame-count","estimated-vf-fps","container-fps","display-fps","time-pos","duration","seekable","partially-seekable","android-surface-size","wid","gpu-context","current-gpu-context","vo-passes","mistimed-frame-count","video-sync","opengl-es","fbo-format","gpu-dumb-mode"}
  for _, p in ipairs(props) do
    local v = mp.get_property(p)
    if p == "vo-passes" and v then v = string.sub(v, 1, 600) end
    mp.msg.info("P8FDIAG " .. tag .. " " .. p .. "=" .. tostring(v))
  end
end
mp.add_timeout(24, function()
  dump("t24")
  local r1 = mp.commandv("screenshot-to-file", "/sdcard/YomiHub/p8f_win.jpg", "window")
  local r2 = mp.commandv("screenshot-to-file", "/sdcard/YomiHub/p8f_vid.jpg", "video")
  mp.msg.info("P8FDIAG shots " .. tostring(r1) .. " " .. tostring(r2))
end)
