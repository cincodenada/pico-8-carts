function image:get(x,y)
	return peek(y*self.w+x+self.header_size)
end
function image:set(x,y,val)
	return poke(y*self.w+x+self.header_size,val)
end
function image:load(mem_start,w,h,gw,gh,memwidth)
	self.w=w
	self.h=h
	for y=0,h-1 do
		for x=0,w-1 do
			-- gs/2 cause 2px per byte
			byte=y*gh*memwidth+x*gw/2
			curval = peek(mem_start+byte)
			image:set(x,y,packhv(col2hv[curval]))
		end
	end
	-- Add sentinel value
	poke(0x0000,5)
	-- Add dimensions
	poke(0x3000,w)
	poke(0x3001,h)
end

function image:init()
	local flags = unpackhv(peek(0x0000))
	-- 4 and 5 are not used in our Piet images
	-- And also are not valid values
	-- So we use val=5 in the first byte
	-- to signal that it is h/v data
	-- Upper nibble reserved for future use
	if(flags.val != 5) then
		-- Try loading external image data
		-- Images must be bordered left/right by black
		-- With thickness equal to their gridheight
		local size = image:find_size()
		image:load(0x0000, size.x, size.y, size.w, size.h, 128)
	end
	self.w = peek(0x3000)
	self.h = peek(0x3001)
end

function image:find_size()
	local x,y = 0,0
	local w,h = 1,1
	-- find first brown pixels
	while(self:getpx(x,0).val != 4) do
		x += 1
	end
	while(self:getpx(0,y).val != 4) do
		y += 1
	end
	while(self:getpx(x,x+w) == 4) do
		w += 1
	end
	while(self:getpx(y,y+w) == 4) do
		y += 1
	end
	return {x=x,y=y,w=w,h=h}
end

function image:save()
	local mem_start = 0x0000
	--for y=0,self.h-1 do
	--	for x=0,self.w-1 do
	--		px=y*self.w+x
	--		poke(mem_start+px,mget(x,y))
	--	end
	--end
	cstore()
end

function image:will_fit(w,h)
	return w*h <= self.max_w*self.max_h
end

function image:set_size(w,h)
	-- doesn't do any resizing of data!
	poke(0x3000,w)
	poke(0x3001,h)
	self.w=w
	self.h=h
end

function image:resize(doit)
	if(doit and prompt:active()) then
		local success = self:do_resize(self.resize_vals)
		if(not success) next_loop:append(function() prompt:show("image too big!") end)
	else
		prompt:show("", function(doit) image:resize(doit) end)
		self.resize_vals = {0,0,0,0}
		self.cur_resize = 0
		prompt.update_callback = function(p) self:update_resize(p) end
		self:update_resize(nil)
	end
end

function image:update_resize(pressed)
	if(pressed == 0) then
		self.resize_vals[self.cur_resize+1] -= 1
	elseif(pressed == 1) then
		self.resize_vals[self.cur_resize+1] += 1
	elseif(pressed == 2) then
		self.cur_resize -=1
	elseif(pressed == 3) then
		self.cur_resize +=1
	end
	self.cur_resize %= 4
	local resize_text = {
		"left:   ",
		"right:  ",
		"top:    ",
		"bottom: "
	}
		
	p = "resize image\n"
	for i=1,4 do
		np=""
		if(self.resize_vals[i] > 0) np="+"

		if(i == self.cur_resize+1) then
			p = p..resize_text[i].."➡️"..np..self.resize_vals[i].."⬅️\n"
		else
			p = p..resize_text[i].."⬅️"..np..self.resize_vals[i].."➡️\n"
		end
	end
	prompt:set_text(p)
end

function image:do_resize(dims)
	-- dims = l r t b
	new_w = self.w + dims[1] + dims[2]
	new_h = self.h + dims[3] + dims[4]
	if(not self:will_fit(new_w, new_h)) return false
	-- todo: confirm destroying non-bw data
	-- for now, just read into ram
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- todo: use bigger copy functions
			imgdata[y][x] = image:get(x,y)
		end
	end

	local od = {self.w,self.h}
	self:set_size(new_w,new_h)

	local black = packhv({hue=5,val=3})
	dx = -dims[1]
	dy = -dims[3]
	for y=0,self.h-1 do
		for x=0,self.w-1 do
			if(x<dims[1] or y<dims[3]) then
				image:set(x,y,black)
			elseif(x+dx>=od[1] or y+dy>=od[2]) then
				image:set(x,y,black)
			else
				image:set(x,y,imgdata[y+dy][x+dx])
			end
		end
	end

	return true
end

function image:add_row(before)
	if(not self:will_fit(self.w, self.h+1)) return false
	-- for now, just read into ram
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- todo: use bigger copy functions
			imgdata[y][x] = image:get(x,y)
		end
	end

	self:set_size(self.w,self.h+1)

	local black = packhv({hue=5,val=3})
	for y=0,self.h-1 do
		for x=0,self.w-1 do
			if(y==before) then
				image:set(x,y,black)
			elseif(y > before) then
				image:set(x,y+1,imgdata[y][x])
			else
				image:set(x,y,imgdata[y][x])
			end
		end
	end
end

function image:add_col(before)
	if(not self:will_fit(self.w, self.h+1)) return false
	-- for now, just read into ram
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- todo: use bigger copy functions
			imgdata[y][x] = image:get(x,y)
		end
	end

	self:set_size(self.w+1,self.h)

	local black = packhv({hue=5,val=3})
	for y=0,self.h-1 do
		for x=0,self.w-1 do
			if(x==before) then
				image:set(x,y,black)
			elseif(x > before) then
				image:set(x,y,imgdata[y][x-1])
			else
				image:set(x,y,imgdata[y][x])
			end
		end
	end
end

function image:getpx(px)
	if(px.x < 0 or px.x >= self.w or
	   px.y < 0 or px.y >= self.h) then
		-- edges are treated as black
		return {val=3,hue=4}
	else
		return unpackhv(image:get(px.x, px.y))
	end
end

function image:setpx(sel,px)
	for x=sel.x,sel.x+sel.w do
		for y=sel.y,sel.y+sel.h do
			image:set(x,y,packhv(px))
		end
	end
end

function image:is_white(sel)
	local px = self:getpx(sel)
	return (px.val == 3 and px.hue < 3)
end

function image:is_black(sel)
	local px = self:getpx(sel)
	return (px.val == 3 and px.hue >= 3)
end
