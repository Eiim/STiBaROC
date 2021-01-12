local internet = require("internet")
local component = require("component")
local event = require("event")
local unicode = require("unicode")
local text = require("text")
local keyboard = require("keyboard")
local json = dofile(os.getenv("HOME") .. "/json.lua")
local gpu = component.gpu
local pageNum = 1
local posts
local scroll = 1
local maxScroll = 82
local mainScroll = 1
local screen = "main"
local postData
local postNums = {}

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
	local ua = {["User-Agent"] = "STiBaROC/0.0.2"}
	res = internet.request("https://api.stibarc.com/"..ept, nil, ua)
	local con = ""
	for chunk in res do con = con..chunk end
	return con
end

function quit(text)
	if text then print(text) end
	gpu.setActiveBuffer(0)
	gpu.setBackground(0, true)
	gpu.setForeground(1, true)
	os.exit()
end

if not pcall(function() unicode.wlen("t") end) then quit("Unicode not initialized!") end -- Unicode sometimes fails to initialize, catch it early

gpu.setResolution(160, 50)
								 -- 0 is black by default
gpu.setPaletteColor(1, 0xF0F0F0) -- White
gpu.setPaletteColor(2, 0x98DFF3) -- Light blue
gpu.setPaletteColor(3, 0x49B9CA) -- Medium blue
gpu.setPaletteColor(4, 0x28646E) -- Dark blue
gpu.setPaletteColor(5, 0xFF7E54) -- Orange
gpu.setPaletteColor(6, 0xFF9F54) -- Light orange
gpu.setPaletteColor(7, 0xFFCE4F) -- Yellow
component.gpu.freeAllBuffers()
local mainBuf = component.gpu.allocateBuffer(156, 120)
if mainBuf == nil then
	print("Can't allocate buffer, trying again")
	component.gpu.freeAllBuffers()
	mainBuf = component.gpu.allocateBuffer(156, 120)
	if mainBuf == nil then
		quit("Failed to allocate buffer! Is something else consuming vram?")
	end
end

-- #Define functions#

-- Get posts
function loadMain()
	posts = json.decode(sget("v2/getposts.sjs"))
	postNums = {}
	local n = 0

	for k,v in pairs(posts) do
		if k~="totalposts" then
			n = n+1
			postNums[n] = k
		end
	end
	table.sort(postNums, function(a, b) return tonumber(a) > tonumber(b) end)
end

-- Render posts
function renderMain()
	gpu.setActiveBuffer(mainBuf)

	gpu.setBackground(1, true)
	gpu.setForeground(0, true)
	for p = 1, 20, 1 do
		post = posts[postNums[p]]
		gpu.fill(1, ((p-1)*6)+1, 156, 5, " ")
		gpu.set(2, ((p-1)*6)+2, post["title"])
		gpu.set(2+unicode.wlen(post["title"]), ((p-1)*6)+2, " by "..post["poster"])
		if post["verified"] then
			gpu.set(2+unicode.wlen(post["title"])+4+unicode.wlen(post["poster"]), ((p-1)*6)+2, " ☑")
		end
		if unicode.wlen(post["content"]) > 154 then
			gpu.set(2, ((p-1)*6)+3, unicode.wtrunc(post["content"], 151).."...")
		else
			gpu.set(2, ((p-1)*6)+3, post["content"])
		end
		local linLen = 0
		if post["upvotes"] + post["downvotes"] <= 10 then
			gpu.fill(2, ((p-1)*6)+4, post["upvotes"], 1, "▲")
			linLen = post["upvotes"]
			gpu.fill(2+linLen, ((p-1)*6)+4, post["downvotes"], 1, "▼")
			linLen = linLen + post["downvotes"]
		else
			local updvstr = "+"..tostring(post["upvotes"])..",-"..tostring(post["upvotes"])
			gpu.set(2, ((p-1)*6)+4, updvstr)
			linLen = unicode.wlen(updvstr)
		end
		if post["comments"] > 0 then
			gpu.set(4+linLen, ((p-1)*6)+4, post["comments"].." comments")
		end
	end
	gpu.setBackground(2, true)
	for p = 1, 20, 1 do
		gpu.fill(1, ((p-1)*6)+6, 156, 1, " ")
	end
	maxScroll = 82
end

-- Load post data
function loadPost(postNum)
	postData = json.decode(sget("v2/getpost.sjs?id="..postNum))
end

-- Render a post
function renderPost()
	gpu.setActiveBuffer(mainBuf)
	gpu.setBackground(2, true)
	gpu.fill(1, 1, 156, 120, " ")
	local postText = text.detab(postData["content"], 4)
	gpu.setBackground(1, true)
	gpu.setForeground(0, true)
	gpu.fill(1, 1, 156, 4, " ")
	gpu.set(2, 2, postData["title"].." by "..postData["poster"])
	if postData["verified"] then
		gpu.set(8+unicode.wlen(postData["title"])+unicode.wlen(postData["poster"]), 2, "☑")
	end
	gpu.set(2, 3, "Posted "..postData["postdate"])
	local postLines = 4
	local linLen = 0
	if(#postText > 0) then
		postLines = postLines + 1
		for c in postText:gmatch"." do
			if linLen == 0 then
				gpu.fill(1, postLines, 156, 1, " ")
			end
			if c == "\n" then
				postLines = postLines + 1
				linLen = 0
			else
				if linLen >= 154 then
					postLines = postLines + 1
					linLen = 0
					gpu.fill(1, postLines, 156, 1, " ")
				end
				gpu.set(2+linLen, postLines, c)
				linLen = linLen + 1
			end
		end
	end
	postLines = postLines + 1
	gpu.fill(1, postLines, 156, 3, " ")
	postLines = postLines + 1
	if postData["upvotes"] + postData["downvotes"] <= 10 then
		gpu.fill(2, postLines, postData["upvotes"], 1, "▲")
		gpu.fill(2+postData["upvotes"], postLines, postData["downvotes"], 1, "▼")
	else
		local updvstr = "+"..tostring(postData["upvotes"])..",-"..tostring(postData["upvotes"])
		gpu.set(2, postLines, updvstr)
	end
	postLines = postLines + 3
	if postData["comments"] ~= nil then
		for i = 1, math.floor((120-postLines)/5), 1 do
			local com = postData["comments"][tostring(i)]
			if com == nil then
				break
			else
				gpu.fill(1, postLines, 156, 4, " ")
				gpu.set(2, postLines+1, com["poster"])
				if com["verified"] then
					gpu.set(3+unicode.wlen(com["poster"]), postLines+1, "☑")
				end
				if #com["content"] > 154 then
					gpu.set(2, postLines+2, unicode.wtrunc(com["content"], 151).."...")
				else
					gpu.set(2, postLines+2, com["content"])
				end
				postLines = postLines + 5
			end
		end
	end
	maxScroll = math.max(0, postLines-38)
end

-- Draw logo
function renderLogo()
	gpu.setActiveBuffer(0)

	gpu.setForeground(1 , true)
	gpu.setBackground(2, true)
	gpu.fill(1, 1, 160, 12 , " ")

	local logx = 37
	gpu.setBackground(5, true) -- Orange
	gpu.set(logx+6, 2, "      ") -- 3x2
	gpu.set(logx+14, 2, "                ") -- 8x2
	gpu.set(logx+2, 3, "              ") -- 7x2 (3o)
	gpu.set(logx+2, 4, "            ") -- 6x2 (1o)
	gpu.set(logx+16, 4, "              ") -- 7x2 (1o)
	gpu.set(logx+2, 5, "        ") -- 4x2 (1o)
	gpu.set(logx+2, 6, "          ") -- 5x2 (2o)
	gpu.set(logx+4, 7, "          ") -- 5x2 (1o)
	gpu.set(logx+12, 8, "  ") -- 1x2
	gpu.set(logx, 9, "              ") -- 7x2 (1o)
	gpu.set(logx, 10, "            ") -- 6x2 (4o)
	gpu.set(logx+2, 11, "        ") -- 4x2
	gpu.set(logx+20, 11, "    ") -- 2x2
	gpu.fill(logx+18, 4, 6, 7, " ") -- T stem
	gpu.fill(logx+28, 4, 4, 8, " ") -- i stem

	gpu.setBackground(1, true) -- White
	gpu.set(logx+6, 3, "      ") -- 3x2
	gpu.set(logx+16, 3, "            ") -- 6x2
	gpu.fill(logx+4, 4, 2, 2, " ") -- S left vert
	gpu.set(logx+6, 6, "    ") -- 2x2
	gpu.fill(logx+10, 7, 2, 3, " ") -- S right vert
	gpu.set(logx+2, 10, "        ") -- 4x2
	gpu.fill(logx+20, 4, 2, 7, " ") -- T vert

	gpu.setBackground(7, true) -- Yellow
	gpu.set(logx+30, 2, "  ")
	gpu.set(logx+28, 3, "      ")
	gpu.set(logx+30, 4, "  ")

	gpu.setBackground(6, true) -- Light Orange
	gpu.fill(logx+34, 2, 8, 10, " ") -- Main B
	gpu.set(logx+42, 3, "  ") -- Corner of B
	gpu.fill(logx+42, 4, 4, 7, " ") -- Right B
	gpu.fill(logx+46, 5, 6, 7, " ") -- Main a
	gpu.fill(logx+52, 6, 2, 6, " ") -- Right a
	gpu.fill(logx+54, 2, 6, 10, " ") -- Left R
	gpu.fill(logx+60, 2, 2, 8, " ") -- Right R 1
	gpu.fill(logx+62, 2, 2, 9, " ") -- Right R 2
	gpu.fill(logx+64, 3, 2, 9, " ") -- Right R 3
	gpu.fill(logx+66, 4, 2, 8, " ") -- Right R 4
	gpu.fill(logx+68, 5, 4, 6, " ") -- Left C
	-- C top
	gpu.set(logx+72, 5, "  ")
	gpu.set(logx+70, 4, "            ")
	gpu.set(logx+78, 5, "  ")
	gpu.set(logx+72, 3, "          ")
	gpu.set(logx+74, 2, "      ")
	--C bottom
	gpu.set(logx+70, 11, "  ")
	gpu.fill(logx+72, 9, 4, 3, " ")
	gpu.fill(logx+76, 8, 4, 3, " ")

	gpu.setBackground(1, true) -- White
	gpu.fill(logx+36, 3, 2, 8, " ") -- B left
	gpu.fill(logx+38, 6, 4, 2, " ") -- B middle
	gpu.set(logx+38, 3, "    ") -- B top
	gpu.set(logx+40, 4, "    ") -- B top
	gpu.set(logx+42, 5, "  ") -- B top
	gpu.set(logx+38, 10, "    ") -- B bottom
	gpu.set(logx+40, 8, "    ") -- B bottom
	gpu.set(logx+42, 9, "  ") -- B bottom
	gpu.set(logx+48, 6, "    ") -- 2x2 
	gpu.set(logx+46, 7, "    ") -- 2x2
	gpu.set(logx+46, 8, "  ") -- 1x2
	gpu.set(logx+46, 9, "    ") -- 2x2
	gpu.set(logx+48, 10, "      ") -- 3x2
	gpu.fill(logx+52, 7, 2, 3, " ") -- a vert
	gpu.fill(logx+56, 3, 2, 8, " ") -- R vert
	gpu.set(logx+58, 3, "      ") -- 3x2
	gpu.set(logx+62, 4, "    ") -- 2x2
	gpu.set(logx+64, 5, "  ") -- 1x2
	gpu.set(logx+62, 6, "    ") -- 2x2
	gpu.set(logx+58, 7, "        ") -- 4x2
	gpu.set(logx+58, 8, "      ") -- 3x2
	gpu.set(logx+62, 9, "    ") -- 2x2
	gpu.set(logx+64, 10, "  ") -- 1x2
	-- C
	gpu.set(logx+74, 3, "      ") -- 3x2
	gpu.set(logx+72, 4, "  ") -- 1x2
	gpu.set(logx+78, 4, "  ") -- 1x2
	gpu.set(logx+70, 5, "  ") -- 1x2
	gpu.fill(logx+68, 6, 2, 3, " ") -- C left
	gpu.set(logx+70, 9, "  ") -- 1x2
	gpu.set(logx+76, 9, "  ") -- 1x2
	gpu.set(logx+70, 10, "      ") -- 3x2
end

-- #Run functions#

gpu.setActiveBuffer(0)
gpu.setBackground(2, true)
gpu.fill(1, 13, 2, 38, " ")
gpu.fill(159, 13, 2, 38, " ")

renderLogo()

loadMain()
renderMain()

gpu.bitblt(0, 3, 13, 156, 38, mainBuf, scroll, 1)

gpu.setForeground(0, true)
gpu.setBackground(1, true)

gpu.setActiveBuffer(0)

while true do
	local id, _, a, b = event.pullMultiple("touch", "key_down", "interrupted")
	if id == "interrupted" then
		quit()
	elseif id == "key_down" then
		if b == keyboard.keys.down and scroll <= maxScroll then
			scroll = scroll + 1
			if screen == "main" then mainScroll = mainScroll + 1 end
			gpu.bitblt(0, 3, 13, 156, 38, mainBuf, scroll, 1)
		elseif b == keyboard.keys.up and scroll > 1 then
			scroll = scroll - 1
			if screen == "main" then mainScroll = mainScroll - 1 end
			gpu.bitblt(0, 3, 13, 156, 38, mainBuf, scroll, 1)
		elseif b == keyboard.keys.left and screen == "post" then
			loadMain()
			renderMain()
			gpu.setActiveBuffer(0)
			scroll = mainScroll
			gpu.bitblt(0, 3, 13, 156, 38, mainBuf, mainScroll, 1)
			screen = "main"
		end
	elseif id == "touch" then
		if screen == "main" and a > 2 and a < 159 and b > 12 and (b-14+scroll) % (6) < 5 then
			loadPost(postNums[1+math.floor((scroll+b-14)/6)])
			renderPost()
			scroll = 1
			gpu.bitblt(0, 3, 13, 156, 38, mainBuf, scroll, 1)
			screen = "post"
			gpu.setActiveBuffer(0)
		elseif screen ~= "main" and a > 38 and a < 81 and b > 1 and b < 12 then
			loadMain()
			renderMain()
			scroll = 1
			gpu.bitblt(0, 3, 13, 156, 38, mainBuf, scroll, 1)
			screen = "main"
			gpu.setActiveBuffer(0)
		end
	end
end