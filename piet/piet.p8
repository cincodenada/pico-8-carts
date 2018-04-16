pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vim: sw=2 ts=2 sts=2 noet foldmethod=marker foldmarker=-->8,---
-- w/h: 0x0 = 1 cel
function hex(n,d) return sub(tostr(n,true),5,6) end
function packhv(hv) return hv.val+shl(hv.hue,4) end
function unpackhv(hv) return {val=band(hv,0x0f), hue=lshr(band(hv,0xf0),4)} end
function hashloc(loc) return tostr(loc.x).."#"..tostr(loc.y) end

function wrap(text, width)
	local charwidth = width/4
	text = text.." "
	local output, curline, word = "","",""
	local pos,lines = 1,1
	while(pos <= #text) do
		local curlet = sub(text,pos,pos)
		if(curlet == " ") then
			if(#curline + #word > charwidth) then
				output = output..curline.."\n"
				curline=""
				lines += 1
				-- back up so we re-process the space next line
				pos -= 1
			elseif(#curline + #word == charwidth) then
				output = output..curline..word.."\n"
				curline=""
				lines += 1
				word = ""
			else
				curline = curline..word.." "
				word = ""
			end
		elseif(curlet == "\n") then
			if(#curline + #word > charwidth) then
				output = output..curline.."\n"
				lines+=1
				output = output..word.."\n"
			else
				output = output..curline..word.."\n"
			end
			curline=""
			word=""
			lines+=1
		else
			-- If we have a word that's too long, just break it
			if(#curline == "" and #word == charwidth) then
				output = output..#word.."\n"
				word=""
				lines += 1
			end
			word = word..curlet
		end
		pos += 1
	end
	if(curline!="") output = output..curline.."\n"
	return {text=output, lines=lines}
end

local numhues,numvals = 6,4
local colormap={
	15,10,11,6,12,14,
	8,9,3,13,1,2
}

local funcmap={
	'n/a','push','pop',
	'add','sub','mul',
	'div','mod','not',
	'gt','ptr','sw',
	'dup','roll','#in',
	'cin','#out','cout'
}

local solidpat=0x0000
local midpat=0xa5a5

local cur_color={val=3, hue=1}
-- 0 = not editing
-- 1 = changing selection
-- 2 = editing colors
-- 3 = running
local edit_mode=0
local paint_mode=0

local fake_state = {dp=0, cc=-1}

---
-->8
-- generate pico-8 color <-> hv lookup tables
local col2hv = {}
local hv2col = {}
for curhue=0,numhues-1 do
	local colors = {
		colormap[curhue+1] + shl(colormap[curhue+1],4),
		colormap[curhue+1] + shl(colormap[curhue+1+numhues],4),
		colormap[curhue+1+numhues] + shl(colormap[curhue+1],4),
		colormap[curhue+1+numhues] + shl(colormap[curhue+1+numhues],4)
	}
	col2hv[colors[1]] = {hue=curhue,val=0}
	col2hv[colors[2]] = {hue=curhue,val=1}
	col2hv[colors[3]] = {hue=curhue,val=1}
	col2hv[colors[4]] = {hue=curhue,val=2}
	
	hv2col[curhue] = {}
	hv2col[curhue][0] = colors[1]
	hv2col[curhue][1] = colors[2]
	hv2col[curhue][2] = colors[4]
	-- add black/white
	hv2col[curhue][3] = 0x77*(1-flr(curhue/(numhues/2)))
end
col2hv[0x00] = {hue=3,val=3} -- black
col2hv[0x77] = {hue=0,val=3} -- white

function mksel(x,y,...)
	local sel={x=x,y=y,w=0,h=0}
	local args = {...}
	if (#args > 0)	then
		sel.w = args[1]
		sel.h = args[2]
	end
	return sel
end

function tcopy(table)
	local out={}
	for k,v in pairs(table) do
		out[k] = v
	end
	return out
end

function teq(a,b)
	if(#a != #b) return false
	for k,v in pairs(a) do
		if(a[k] != b[k]) return false
	end
	return true
end

------------------------
-- Object declarations
------------------------

local state = {x=0, y=0, dp=0, cc=-1, toggle=0, attempts=0}
local stack = {}
local output = ""
local max_block = {x=nil,y=nil}

local next_loop = {funcs = {}}

-- Stored in sprite + aux data
-- 128x128 pixels (2 per byte)
-- 64x128 bytes
-- plus map-only data of 128x32
-- For a total of 128x96 bytes
local image = {
	w=64,
	h=64,
	max_bytes=0x2000,
	mem_start=0x0000,
	max_w=64,
	max_h=128,
}

local prompt = {
	text = "",
	callback = nil,
	update_callback = nil,
	just_ended = false,
}

local view = {
	nw = {x=0,y=0},
	pxsize = 2,
	sel = mksel(0,0),
	cameras = {},
	size = {128,128}
}

local palette = {
	pxsize = 4,
	top = 0,
}


-------------------------
-- Object methods
-------------------------
function next_loop:append(func)
	add(self.funcs, func)
end
function next_loop:run()
	for f in all(self.funcs) do
		f()
	end
	self.funcs = {}
end

function image:get(x,y)
	return peek(y*self.w+x)
end
function image:set(x,y,val)
	return poke(y*self.w+x,val)
end
function image:load(mem_start,w,h,gs,memwidth)
	self.w=w
	self.h=h
	for y=0,h-1 do
		for x=0,w-1 do
			-- gs/2 cause 2px per byte
			byte=y*gs*memwidth+x*gs/2
			curval = peek(mem_start+byte)
			image:set(x,y,packhv(col2hv[curval]))
		end
	end
	poke(0x3000,w)
	poke(0x3001,h)
end

function image:init()
	self.w = peek(0x3000)
	self.h = peek(0x3001)
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
	-- Doesn't do any resizing of data!
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
			p = p..resize_text[i]..">"..np..self.resize_vals[i].."<\n"
		else
			p = p..resize_text[i].."<"..np..self.resize_vals[i]..">\n"
		end
	end
	prompt:set_text(p)
end

function image:do_resize(dims)
	-- dims = l r t b
	new_w = self.w + dims[1] + dims[2]
	new_h = self.h + dims[3] + dims[4]
	if(not self:will_fit(new_w, new_h)) return false
	-- TODO: Confirm destroying non-bw data
	-- For now, just read into RAM
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- TODO: Use bigger copy functions
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
	-- For now, just read into RAM
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- TODO: Use bigger copy functions
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
	-- For now, just read into RAM
	local imgdata = {}
	for y=0,self.h-1 do
		imgdata[y] = {}
		for x=0,self.w-1 do
			-- TODO: Use bigger copy functions
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

function pbtn(i) return (not prompt.just_ended and btn(i)) end
function prompt:show(text, callback)
	self.callback = callback
	self:set_text(text)
end

function prompt:set_text(text)
	local wrapped = wrap(text, 62)
	if(self.callback) then
		wrapped.text = wrapped.text.."z=yes / x=no"
	else
		wrapped.text = wrapped.text.."z to dismiss"
	end
	wrapped.lines += 1

	self.text = wrapped.text
	self.halfheight = wrapped.lines*3
end

function prompt:draw()
	if(not self:active()) return
	view:save_camera()
	rectfill(32,64-self.halfheight,95,64+self.halfheight,5)
	rect(31,64-self.halfheight-1,96,64+self.halfheight+1,4)
	print(self.text, 33, 64-self.halfheight+1,7)
	view:load_camera()
end

function prompt:check()
	if(btnp(4) or btnp(5)) then
		if(self.callback) self.callback(btnp(4))
		self.text = ""
		self.callback = nil
		self.update_callback = nil
		self.just_ended = true
		return true
	elseif(self.update_callback) then
		local pressed = nil
		for b=0,3 do
			if(btnp(b)) pressed = b break
		end
		if(pressed) self.update_callback(pressed)
	end
	return false
end

-- Clear button pressed once they're released
function prompt:update_buttons()
	if(not btn(4) and not btn(5)) then
		self.just_ended = false
	end
end

function prompt:active()
	return (self.text!="")
end

-- translates a h/v pair to a fill color
-- with upper/lower nibble set properly
function getcol(px)
	return hv2col[px.hue][px.val]
end

---
-->8
function view:init()
	self.size[2] = palette.top
end
function view:gridsize() return self.pxsize+2 end
function view:pxdim()
	return {
		x=ceil(self.size[1]/(view:gridsize())),
		y=ceil(self.size[2]/(view:gridsize()))
	}
end
function view:push_sel() self.prevsel = tcopy(self.sel) end
function view:set_sel(x,y) self.sel.x = x self.sel.y = y end
function view:inc_sel(x,y) self:set_sel(self.sel.x+x,self.sel.y+y) end
-- Ensure sel is on nicely on screen
function view:recenter()
	-- Deal with sel size
	if(self.sel.w<0) self.sel.w=0
	if(self.sel.h<0) self.sel.h=0

	if(self.sel.w>image.w-1) self.sel.w=image.w-1
	if(self.sel.h>image.h-1) self.sel.h=image.h-1

	if(self.sel.x+self.sel.w>image.w-1) then self.sel.x=image.w-self.sel.w-1 end
	if(self.sel.y+self.sel.h>image.h-1) then self.sel.y=image.h-self.sel.h-1 end
	--
	-- image limits
	if(self.sel.x < 0) prompt:show("do you want to add a column?", add_col) self.sel.x=0
	if(self.sel.y < 0) prompt:show("do you want to add a row?", add_row) self.sel.y=0
	if(self.sel.x >= image.w) prompt:show("do you want to add a column?", add_col) self.sel.x=image.w-1
	if(self.sel.y >= image.h) prompt:show("do you want to add a row?", add_row) self.sel.y=image.h-1

	-- view limits
	-- only one of these can happen at a time since we only move orthogonally
	local px = self:pxdim()
	-- TODO: Don't depend on set() to sanity check us here, it's wasteful
	if(self.sel.x >= self.nw.x+ceil(px.x*0.75)) self:set(self.sel.x-ceil(px.x*0.75), self.nw.y)
	if(self.sel.y >= self.nw.y+ceil(px.y*0.75)) self:set(self.nw.x, self.sel.y-ceil(px.y*0.75))
	if(self.sel.x < self.nw.x+flr(px.x*0.25)) self:set(self.sel.x-flr(px.x*0.25), self.nw.y)
	if(self.sel.y < self.nw.y+flr(px.y*0.25)) self:set(self.nw.x,self.sel.y-flr(px.y*0.25))
end
function view:reset()
	self.sel = mksel(0,0)
	camera()
	self.prevsel = tcopy(self.sel)
	self.nw = {x=0,y=0}
end
function view:save_camera() add(self.cameras, peek4(0x5f28)) camera() end
function view:load_camera() poke4(0x5f28, self.cameras[#self.cameras]) self.cameras[#self.cameras] = nil end
function view:set(x,y)
	-- Sanity checks
	if(x < 0 or y < 0) return false
	if(x+self:pxdim().x > image.w) return false
	if(y+self:pxdim().y > image.h) return false

	self.nw = {x=x,y=y}
	camera(x*view:gridsize(), y*view:gridsize())
end

function palette:init()
	-- 2 char on each side
	-- plus 1px padding/side
	self.tot_w=numhues*self.pxsize+4*4+2
	-- 2 lines top/bottom
	-- plus 1px padding/side
	self.tot_h=numvals*self.pxsize+4*6+2
	self.wing_width = flr((128-self.tot_w)/2-1)

	self.top = 128-self.tot_h

	self.offx=128/2-(numhues*self.pxsize/2)
	self.offy=self.top + self.tot_h/2 - (numvals*self.pxsize/2)
end
function palette:draw()
	view:save_camera()

	-- Debug goes here to take advantage of camera reset
	print(view.sel.x.."x"..view.sel.y.."+"..view.nw.x.."x"..view.nw.y,0,0,7)

	local bgcolor=5
	if(paint_mode > 0) bgcolor=4
	-- Clear background
	rectfill(0, self.top, 128, 128, 0)
	rectfill(
		128/2-self.tot_w/2,
		self.top,
		128/2+self.tot_w/2-1,
		self.top+self.tot_h,
		bgcolor
	)
		
	for r=0,numvals-1 do
		for c=0,numhues-1 do
			draw_codel(mksel(c,r),self.pxsize,{val = r, hue = c},self.offx,self.offy)
		end
	end
	
	self.curhv = image:getpx(view.sel)
	draw_dot(mksel(self.curhv.hue,self.curhv.val),self.pxsize,5,self.offx,self.offy)

	-- No funcs from black/white blocks
	if(self.curhv.val!=numvals-1) then
		self:draw_funcs()
	end

	if(edit_mode == 3) then
		print(output, 0, self.top, 7)
		self:draw_stack()
	end

	view:load_camera()
end
function palette:draw_stack()
	local charwidth = flr(self.wing_width/4)
	local left=128/2+self.tot_w/2+1
	local sp = #stack
	for r=0,4 do
		x = left
		while true do
			if(sp==0) break
			local numlen = #tostr(stack[sp])
			if(x+numlen*4 < 128) then
				print(stack[sp], x, self.top+1+r*6)
				x += numlen*4 + 2
				sp-=1
			else
				break
			end
		end
		if(sp==0) break
	end
end
function palette:draw_funcs()
	--print(curhv.hue..curhv.val,8,26,5)
	for x=-1,1 do
		for y=-1,1 do
			if (abs(x+y)==1) then
				local cmp=mksel(view.sel.x+x,view.sel.y+y)
				local cmphv=image:getpx(cmp)
				local func = get_func(self.curhv, cmphv)
				local revfunc = get_func(cmphv, self.curhv)
				if(x==0) then
					rely = self.offy+(numvals*self.pxsize-5)*(y+1)/2
					nudgey = 6*y
					print(func,128/2-#func*2,rely+nudgey*2,7)
					print(revfunc,128/2-#revfunc*2,rely+nudgey,7)
				else
					relx=self.offx+(numvals*self.pxsize+5)*(x+1)/2
					nudgex = 4*x
					posy=self.offy+9-#func*3
					for c=1,#func do
						print(sub(func,c,c),relx+nudgex*2,posy+(c-1)*6,7)
					end
					posy=self.offy+9-#revfunc*3
					for c=1,#revfunc do
						print(sub(revfunc,c,c),relx+nudgex,posy+(c-1)*6,7)
					end
				end
			end
		end
	end
end

cartdata('cincodenada_piet')
--image:load(0x0000, 64, 64, 2, 64)
image:init()
palette:init()
-- view:init() must be after palette:init()
-- so it knows how much space to leave
view:init()

menuitem(1, "run program", function() state:reset() edit_mode=3 end)
menuitem(2, "save program", function() image:save() end)
menuitem(3, "resize program", function() image:resize() end)

function _update()
	next_loop:run()

	if(prompt:active()) then
		prompt:check()
		-- don't respond to input while prompting
		return
	end
	prompt:update_buttons()

	if(btnp(4)) fake_state.dp = (fake_state.dp + 1)%4
	if(btnp(5)) fake_state.cc = -fake_state.cc

	if(edit_mode == 3) then
		if(btnp(4)) then
			step()
		elseif(btnp(5)) then
			edit_mode=0
		end
		return
	end

	if(btnp(5)) then
		paint_mode=1-paint_mode
		cur_color=image:getpx(view.sel)
	end
	if(pbtn(4)) then
		if(edit_mode==2) then
			-- exit edit mode
			edit_mode=-1
		elseif(edit_mode==0) then
			-- enter selection edit mode
			view:push_sel()
			edit_mode=1
		end
	else
		if(edit_mode==1) then
			-- just finished selection
			if(teq(view.sel,view.prevsel)) then
				-- if we didn't change size, edit
				edit_mode = 2
			else
				-- otherwise, back to normal
				edit_mode = 0
			end
		elseif(edit_mode==-1) then
			edit_mode = 0
		end
	end

	if(edit_mode==2) then
		if(paint_mode==0) then
			local px = image:getpx(view.sel)
			
			-- handle moving from hues
			-- to black/white and back
			local hueinc=1
			if(px.val==numvals-1) hueinc=numhues/2
			
			if(btnp(0)) px.hue-=hueinc
			if(btnp(1)) px.hue+=hueinc
			if(btnp(2)) px.val-=1
			if(btnp(3)) px.val+=1
			
			px.val %= 4
			px.hue %= 6
			
			image:setpx(view.sel,px)
		else
			if(btnp(0)) view:inc_sel(-1,0)
			if(btnp(1)) view:inc_sel(1,0)
			if(btnp(2)) view:inc_sel(0,-1)
			if(btnp(3)) view:inc_sel(0,1)

			image:setpx(view.sel,cur_color)
		end
	elseif (edit_mode==1) then
		if(btnp(0)) view.sel.w-=1
		if(btnp(1)) view.sel.w+=1
		if(btnp(2)) view.sel.h-=1
		if(btnp(3)) view.sel.h+=1
	elseif (edit_mode==0) then
		if(btnp(0)) view.sel.x-=1
		if(btnp(1)) view.sel.x+=1
		if(btnp(2)) view.sel.y-=1
		if(btnp(3)) view.sel.y+=1
	end

	view:recenter()
end

function add_col(doit)
	if(doit) then
		if(view.sel.x==0) then
			image:add_col(0)
		else
			image:add_col(image.w)
		end
	end
end

function add_row(doit)
	if(doit) then
		if(view.sel.y==0) then
			image:add_row(0)
		else
			image:add_row(image.h)
		end
	end
end

function _draw()
	cls()
	for x=view.nw.x,view.nw.x+view:pxdim().x-1 do
		for y=view.nw.y,view.nw.y+view:pxdim().y-1 do
			draw_px(mksel(x,y))
		end
	end
	if(paint_mode==1) then
		draw_px(view.sel,cur_color)
	end

	palette:draw()
	
	local framecolor=5
	local pcolor=4
	-- yellow frame for editing
	if(edit_mode > 1) framecolor=4 pcolor=5
	
	-- draw selection rectangle
	draw_frame(view.sel,view:gridsize(),framecolor)
	if(edit_mode == 3) draw_pointer(view.sel,view:gridsize(),pcolor)

	prompt:draw()
end

---
-->8
function draw_px(sel,...)
	local args = {...}
	local col
	if(#args > 0) then
		col=args[1]
	else
		col=image:getpx(sel)
	end

	draw_codel(sel,view:gridsize(),col,0,0)
end

function draw_codel(sel,gs,col,offx,offy)
	if(col.val==1) then
		-- middle row
		fillp(midpat)
	else
		fillp(solidpat)
	end
	
	rectfill(
		sel.x*gs+offx,
		sel.y*gs+offy,
		(sel.x+1)*gs-1+offx,
		(sel.y+1)*gs-1+offy,
		getcol(col)
	)

	-- reset fillpat
	fillp(solidpat)
end

function draw_frame(sel,gs,col)
	local w, h = sel.w+1, sel.h+1
	rect(
		sel.x*gs,
		sel.y*gs,
		(sel.x+w)*gs-1,
		(sel.y+h)*gs-1,
		col
	)
end

function draw_pointer(sel,gs,col)
	local info = state:dpinfo()
	local r = (gs-1)/2
	lstart = {x=sel.x*gs+r, y=sel.y*gs+r}
	lstart[info.axes[1]] += r*info.dirs[1]
	lend = tcopy(lstart)
	lend[info.axes[2]] += r*info.dirs[2]
	if(gs % 2 == 0) lstart[info.axes[2]] += 0.5*info.dirs[2]
	line(lstart.x, lstart.y, lend.x, lend.y, col)
end


function draw_dot(sel,gs,col,offx,offy)
	rect(
		sel.x*gs+flr(gs/2)-1+offx,
		sel.y*gs+flr(gs/2)-1+offy,
		sel.x*gs+flr(gs/2)+offx,
		sel.y*gs+flr(gs/2)+offy,
		col
	)
end

---
-->8
function chr(num)
	local control="\b\t\n\v\f\r"
	local chars=" !\"#$%&'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
	if(num >= 8 and num <= 13) then
		return sub(control,num-7,num-7)
	elseif(num >= 32 and num <= 126) then
		return sub(chars,num-31,num-31)
	else
		return "x"
	end
end

function state:reset()
	self.x=0
	self.y=0
	self.dp=0
	self.cc=-1
	self.toggle=0
	self.attempts=0
	while(#stack > 0) do
		stack[#stack]=nil
	end
	output = ""
	view:reset()
end

function state:next()
	local next = tcopy(self)
	next.attempts = 0
	max_block:init(self)
	blockinfo = get_exit(self)
	next.x = blockinfo.exit.x
	next.y = blockinfo.exit.y
	next.last_value = blockinfo.count
	if(self.dp % 2==0) then
		next.x += 1-self.dp
	else
		next.y += 2-self.dp
	end
	return next
end

function state:dpinfo()
	local info = {}
	if(self.dp % 2 == 0) then
		info.axes = {'x','y'}
		info.dirs = {1-self.dp}
		add(info.dirs, info.dirs[1]*self.cc)
	else
		info.axes = {'y','x'}
		info.dirs = {2-self.dp}
		add(info.dirs, -info.dirs[1]*self.cc)
	end
	return info
end

function stack:pop()
	local top = self[#self]
	self[#self] = nil
	return top
end

function stack:push(val)
	add(self, val)
end

function stack:roll(depth, dir)
	local tmp
	if(dir == -1) then
		tmp = self[#self-depth]
		for i=#self-depth,#self-1 do
			self[i] = self[i+1]
		end
		self[#self] = tmp
	else
		tmp = self[#self]
		for i=#self,#self-depth+1,-1 do
			self[i] = self[i-1]
		end
		self[#self-depth] = tmp
	end
end

function max_block:init(state)
	self.info = state:dpinfo()
	self.x = state.x
	self.y = state.y
end

function max_block:check(check)
	for i=1,2 do
		local a = self.info.axes[i]
		if check[a] == self[a] then
			-- continue
		elseif sgn(check[a] - self[a]) == self.info.dirs[i] then
			-- Make sure to push out the primary axis
			-- if we're not equivalent
			self.x = check.x
			self.y = check.y
		else
			-- If neither of the above, we're chopped liver
			return
		end
	end
	-- If we made it here, we're better
	self.x = check.x
	self.y = check.y
end

function get_exit(state)
	-- Exit cmp is determined by dp/cc
	--     -1    1
	-- 0 -y +x +y +x
	-- 1 +y +x +y -x
	-- 2 +y -x -y -x
	-- 3 -y -x -y +x
	last = {}
	cur = {}
	next = {}
	block_nums = {}
	max_block:init(state)
	cur[hashloc(state)] = state
	block_color = packhv(image:getpx(state))
	block_size = 1
	numloops = 1
	while(true) do
		new_px = 0
		block_nums[numloops] = {}
		for k,loc in pairs(cur) do
			for dx=-1,1 do
				for dy=-1,1 do
					if(abs(dx+dy)==1) then
						local check = {x=loc.x+dx,y=loc.y+dy}
						if packhv(image:getpx(check)) == block_color then
							local hash = hashloc(check)
							if last[hash] == nil and cur[hash] == nil and next[hash] == nil then
								next[hash] = check
								new_px+=1
								add(block_nums[numloops], check)
								max_block:check(check)
							end
						end
					end
				end
			end
		end
		if (new_px == 0) break
		block_size += new_px
		last = cur
		cur = next
		next = {}
		numloops += 1
	end

	return {
		count = block_size,
		exit = max_block,
	}
end

---
-->8
function step()
	local future = state:next()

	from = image:getpx(state)
	to = image:getpx(future)

	op = get_func(from, to)
	if(op == "stop") then
		state.attempts += 1
		if state.attempts > 8 then
			edit_mode=0
			return
		end

		if(state.toggle==0) then
			state.cc = -state.cc
		else
			state.dp = (future.dp+1)%4
		end
		state.toggle = 1-state.toggle
		return
	end

	if(op == "push") then
		stack:push(future.last_value)
	elseif(op == "pop") then
		stack:pop()
	elseif(op == "dup") then
		add(stack, stack[#stack])
	elseif(op == "add") then
		local top = stack:pop()
		stack[#stack] += top
	elseif(op == "sub") then
		local top = stack:pop()
		stack[#stack] -= top
	elseif(op == "mul") then
		local top = stack:pop()
		stack[#stack] *= top
	elseif(op == "div") then
		local top = stack:pop()
		if(top>0) then
			stack[#stack] = flr(stack[#stack]/top)
		end
	elseif(op == "cout") then
		output = output..chr(stack[#stack])
		stack[#stack] = nil
	elseif(op == "roll") then
		local rolls = stack:pop()
		-- Easier on my brain to work with depth-1
		local depth = stack:pop()-1
		if(depth > 0 and depth <= #stack) then
			if(rolls < 0) then
				local dir = -1
				rolls = -rolls
			end
			for n=1,rolls do
				stack:roll(depth, dir)
			end
		end
	end

	state = future
	view:set_sel(state.x, state.y)
	view:recenter()
end

function get_val(px)
	-- For our test prog this is fine
	return 1
end

function get_func(from, to)
	local func="????"
	if(to.val==numvals-1 or from.val==numvals-1) then
		if(to.hue<numhues/2) then
			func="pass"
		else
			func="stop"
		end
	else
		local diffh=(to.hue-from.hue)
		if(diffh<0) diffh+=numhues
		local diffv=(to.val-from.val)
		if(diffv<0) diffv+=numvals-1

		func=funcmap[diffh*(numvals-1)+diffv+1]
	end

	return func
end

__gfx__
20353535353533333333333333333333333333333333333333333333333333331010101010101010101010103333333333333333333333333333333333333333
33333333333335353535353535353535353535353535353535353535353535353520353535353533333333333333333333333333333333333333333333101010
10101010101010101010101010101010103333333333333333333333333333333333333333333335353535353535353535353535353535353535353535353535
35352035353535353333333333333333333333333333333333333333101010101010101010101010101010101010101010101010333333333333333333333333
33333333333333333535353535353535353535353535353535353535353535353535352035353535353333333333333333333333333333333333101010101010
10101010101010101010101010101010101010101010101033333333333333333333333333333333333535353535353535353535353535353535353535353535
35353535203535353535333333333333333333333333333333331010101010101010101010101010101010101010101010101010101010101010333333333333
33333333333333333333353535353535353535353535353535353535353535353535353535203535353535333333333333333333333333333310101010101010
10101010101010101010101010101010101010101010101010101010103333333333333333333333333333353535353535353535353535353535353535353535
35353535353520353535353533333333333333333333333333101010101010101010101010101010101010101010101010101010101010101010101010101033
33333333333333333333333335353535353535353535353535353535353535353535353535353520353535353533333333333333333333331010101010101010
10101010101010101010101010101010101010101010101010101010101010101010333333333333333333333335353535353535353535353535353535353535
35353535353535352035353535353333333333333333333310101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010333333333333333333333535353535353535353535353535353535353535353535353535352035353535353333333333333333331010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010103333333333333333333535353535353535353535353535353535
35353535353535353535203535353535333333333333333310101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010103333333333333333353535353535353535353535353535353535353535353535353535203535353535333333333333331010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333333353535353535353535353535353535
35353535353535353535353520353535353533333333333333101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010103333333333333335353535353535353535353535353535353535353535353535353520353535353533333333333310101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333335353535353535353535353535
35353535353535353535353535352035353535353333333333101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101033333333333535353535353535353535353535353535353535353535353535352035353535353333333333101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333535353535353535353535
35353535353535353535353535353535203535353535333333331010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101033333333353535353535353535353535353535353535353535353535353535203535353535333333101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010333333353535353535353535
35353535353535353535353535353535353520353535353533333310101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101033333335353535353535353535353535353535353535353535353535353520353535353533333310101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333335353535353535
35353535353535353535353535353535353535352035353535353333101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101033333535353535353535353535353535353535353535353535353535352035353535353333101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333535353535
35353535353535353535353535353535353535353535203535353535331010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101033353535353535353535353535353535353535353535353535353535203535353535331010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033353535
35353535353535353535353535353535353535353535353520353535353533101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010103335353535353535353535353535353535353535353535353535353520353535353533
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010103335
35353535353535353535353535353535353535353535353535352000042532321010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010103535353535353535353535353535353535353535353535353535353535353535
35101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10353535353535353535353535353535353535353535353535353535353535353535101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010353535353535353535353535353535353535353535353535353535353535
35353510101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101035353535353535353535353535353535353535353535353535353535353535353510101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101035353535353535353535353535353535353535353535353535353535
35353535351010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010103535353535353535353535353535353535353535353535353535353535353535351010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010103535353535353535353535353535353535353535353535353535
35353535353535101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010353535353535353535353535353535353535353535353535353535353535353535101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010353535353535353535353535353535353535353535353535
35353535353535353510101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101035353535353535353535353535353535353535353535353535353535353535353510101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101035351111113535353535353535353535353535351111
11353510353535353535351010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010102032111111112125102405202000102420050532111111112110103535353535353310101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010333535111111353535353535353535353535353535
11111135351035353535353535331010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101033353535353535353535353535353535353535353535353535353535353535353535331010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033353535353535353535353535353535353535
35353535353535353535353535353533101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010103335353535353535353535353535353535353535353535353535353535353535353533331010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010333335353535353535353535353535353535
35353535353535353535353535353535353333101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101033333535353535353535353535353535353535353535353535353535353535353535353333331010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010103333333535353535353535353535353535
35353535353535353535353535353535353535333333101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010333333353535353535353535353535353535353535353535353535353535353535353535333333101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010333333353535353535353535353535
35353535353535353535353535353535353535353533333333101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010103333333335353535353535353535353535353535353535353535353535353535353535353533333333331010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010333333333335353535353535353535
35353535353535353535353535353535353535353535353333333333101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101033333333333535353535353535353535353535353535353535353535353535353535353535353333333333331010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010103333333333333535353535353535
35353535353535353535353535353535353535353535353535333333333333331010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101033333333333333353535353535353535353535353535353535353535353535353535353535353535333333333333
33101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333333353535353535
35353535353535353535353535353535353535353535353535353533333333333333331010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010333333333333333335353535353535353535353535353535353535353535353535353535353535353533333333
33333333331010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333333333335353535
35353535353535353535353535353535353535353535353535353535353333333333333333333310101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010333333333333333333333535353535353535353535353535353535353535353535353535353535353535353333
33333333333333333310101010101010101010101010101010101010101010101010101010101010101010101010101010101033333333333333333333333535
35353535353535353535353535353535353535353535353535353535353535333333333333333333333333331010101010101010101010101010101010101010
10101010101010101010101010101010101033333333333333333333333333353535353535353535353535353535353535353535353535353535353535353535
33333333333333333333333333331010101010101010101010101010101010101010101010101010101010101010101010103333333333333333333333333333
35353535353535353535353535353535353535353535353535353535353535353533333333333333333333333333333333101010101010101010101010101010
10101010101010101010101010101010103333333333333333333333333333333335353535353535353535353535353535353535353535353535353535353535
35353333333333333333333333333333333333101010101010101010101010101010101010101010101010101010101010333333333333333333333333333333
33333535353535353535353535353535353535353535353535353535353535353535353333333333333333333333333333333333333333101010101010101010
10101010101010101010101010101033333333333333333333333333333333333333333535353535353535353535353535353535353535353535353535353535
35353535333333333333333333333333333333333333333333331010101010101010101010101010101010101010333333333333333333333333333333333333
33333333353535353535353535353535353535353535353535353535353535353535353535333333333333333333333333333333333333333333333333333310
10101010101010101010103333333333333333333333333333333333333333333333333333353535353535353535353535353535353535353535353535353535
10101010101010101010103333333333333333333333333333333333333333333333333333353535353535353535353535353535353535353535353535353535
00000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000
0000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000
0000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000000000
000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000000000
000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000
00000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000
000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000
00000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000
00000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000
0000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000
0000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000000000000000
000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000000000000000
000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000
00000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000
00000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000
0000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000
000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000
00000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000
00000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000
0000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000
000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000000000
00000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000000000
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000
0000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000
00000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000
0000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000000000
000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000000000000000000000
__gff__
6140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
