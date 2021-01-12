local internet = require("internet")
local component = require("component")
local json = dofile(os.getenv("HOME") .. "/json.lua")
local gpu = component.gpu
local w, h = gpu.getResolution()

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function sget(ept)
  local ua = {["User-Agent"] = "STiBaROC/0.1"}
  res = internet.request("https://api.stibarc.com/"..ept, nil, ua)
  local con = ""
  for chunk in res do con = con..chunk end
  return con
end

local headBuf = gpu.allocateBuffer()

gpu.setForeground(0x98DFF3)
gpu.setBackground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
gpu.setBackground(0x98DFF3)
gpu.fill(1, 1, 2, h/4, " ")

local posts = sget("getpost.sjs?id=3479")
print(dump(json.decode(posts)))