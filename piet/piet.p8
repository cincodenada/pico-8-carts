pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vim: sw=2 ts=2 sts=2 noet foldmethod=marker foldmarker=-->8,---
-- w/h: 0x0 = 1 cel
function hex(n,d) return sub(tostr(n,true),5,6) end
function packhv(hv) return hv.val+shl(hv.hue,4) end
function unpackhv(hv) return {val=band(hv,0x0f), hue=lshr(band(hv,0xf0),4)} end
function hashloc(loc) return tostr(loc.x).."#"..tostr(loc.y) end
function pbtn(i) return (not prompt.just_ended and btn(i)) end

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

prompt = {
	text = "",
	answer = nil,
	callback = nil,
	just_ended = false,
}
function prompt:show(text, callback)
	local wrapped = wrap(text, 62)
	wrapped.text = wrapped.text.."z=yes / x=no"
	wrapped.lines += 1

	self.text = wrapped.text
	self.halfheight = wrapped.lines*3
	self.answer = nil
	self.callback = callback
end

function prompt:draw()
	if(not self:active()) return
	view:save_camera()
	rectfill(32,64-self.halfheight,95,64+self.halfheight,5)
	rect(31,64-self.halfheight-1,96,64+self.halfheight+1,4)
	print(self.text, 33, 64-self.halfheight+1)
	view:load_camera()
end

function prompt:check()
	if(btnp(4) or btnp(5)) then
		self.answer = btnp(4)
		self.text = ""
		self.callback()
		self.answer = nil
		self.callback = nil
		self.just_ended = true
		return true
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

numhues=6
numvals=4
colormap={
	15,10,11,6,12,14,
	8,9,3,13,1,2
}

funcmap={
	'n/a','push','pop',
	'add','sub','mul',
	'div','mod','not',
	'gt','ptr','sw',
	'dup','roll','#in',
	'cin','#out','cout'
}

---
-->8
-- generate pico-8 color <-> hv lookup tables
col2hv = {}
hv2col = {}
for curhue=1,numhues do
	local colors = {
		colormap[curhue] + shl(colormap[curhue],4),
		colormap[curhue] + shl(colormap[curhue+numhues],4),
		colormap[curhue+numhues] + shl(colormap[curhue],4),
		colormap[curhue+numhues] + shl(colormap[curhue+numhues],4)
	}
	col2hv[colors[1]] = {hue=curhue-1,val=0}
	col2hv[colors[2]] = {hue=curhue-1,val=1}
	col2hv[colors[3]] = {hue=curhue-1,val=1}
	col2hv[colors[4]] = {hue=curhue-1,val=2}
	
	hv2col[curhue-1] = {}
	hv2col[curhue-1][0] = colors[1]
	hv2col[curhue-1][1] = colors[2]
	hv2col[curhue-1][2] = colors[4]
	-- add black/white
	hv2col[curhue-1][3] = 7*(1-band(curhue/(numhues/2),0x01))
end
col2hv[0x00] = {hue=3,val=3} -- black
col2hv[0x77] = {hue=0,val=3} -- white

function mksel(x,y,...)
	local sel={x=x,y=y,w=0,h=0}
	local args = {...}
	if (#args > 0)	then
		sel.w = arg[1]
		sel.h = arg[2]
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

-- Stored in map data
-- 128x64 bytes
image = {
	w=16,
	h=16,
	max_bytes=0x2000,
	mem_start=0x1000,
	max_w=128,
	max_h=64,
}
function image:load(mem_start,w,h,gs,memwidth)
	self.w=w
	self.h=h
	for y=0,h-1 do
		for x=0,w-1 do
			px=y*gs*memwidth/2+x*gs/2
			curval = peek(mem_start+px)
			mset(x,y,packhv(col2hv[curval]))
		end
	end
end

function image:save(mem_start)
	for y=0,self.h-1 do
		for x=0,self.w-1 do
			px=y*self.w+x
			poke(mem_start+px,mget(x,y))
		end
	end
end

function image:add_row(before)
	if(self.h == self.max_h) return false

	for y=self.h,before+1,-1 do
		for x=0,self.w-1 do
			-- TODO: Use bigger copy functions
			mset(x,y,mget(x,y-1))
		end
	end
	black = packhv({hue=3,val=5})
	for x=0,self.w-1 do
		mset(x,before,black)
	end

	self.h += 1
end

function image:add_col(before)
	if(self.w == self.max_w) return false

	for x=self.w,before+1,-1 do
		for y=0,self.h-1 do
			-- TODO: Use bigger copy functions
			mset(x,y,mget(x-1,y))
		end
	end
	black = packhv({hue=3,val=5})
	for y=0,self.h-1 do
		mset(before,y,black)
	end

	self.w += 1
end

function image:getpx(px)
	if(px.x < 0 or px.x >= image.w or
	   px.y < 0 or px.y >= image.h) then
		-- edges are treated as black
		return {val=3,hue=4}
	else
		return unpackhv(mget(px.x, px.y))
	end
end

function image:setpx(sel,px)
	for x=sel.x,sel.x+sel.w do
		for y=sel.y,sel.y+sel.h do
			mset(x,y,packhv(px))
		end
	end
	self:save(save_start)
end

-- translates a h/v pair to a fill color
-- with upper/lower nibble set properly
function getcol(px)
	return hv2col[px.hue][px.val]
end

---
-->8
view = {
	nw = {x=0,y=0},
	pxsize = 2,
	sel = mksel(0,0),
	cameras = {},
}
function view:gridsize() return self.pxsize+2 end
function view:gridwidth() return flr(128/(view:gridsize())) end
function view:push_sel() self.prevsel = tcopy(self.sel) end
function view:set_sel(x,y) self.sel.x = x self.sel.y = y end
function view:inc_sel(x,y) self.sel.x += x self.sel.y += y end
function view:reset()
	self.sel = mksel(0,0)
	camera()
	self.prevsel = tcopy(self.sel)
	self.nw = {x=0,y=0}
end
function view:save_camera() add(self.cameras, peek4(0x5f28)) camera() end
function view:load_camera() poke4(0x5f28, self.cameras[#self.cameras]) self.cameras[#self.cameras] = nil end
function view:set(x,y) self.nw = {x=x,y=y} camera(x*view:gridsize(), y*view:gridsize()) end

solidpat=0x0000
midpat=0xa5a5
save_start=0x0000

paint_mode=0
cur_color={val=3, hue=1}

-- running variables
local state = {x=0, y=0, dp=0, cc=-1, toggle=0, attempts=0}
local stack = {}
local output = ""

menuitem(1, "run program", function() state:reset() edit_mode=3 end)

cartdata('cincodenada_piet')
image:load(save_start, imw, imh, 2, 128)

-- 0 = not editing
-- 1 = changing selection
-- 2 = editing colors
-- 3 = running
edit_mode=0

fake_state = {dp=0, cc=-1}

function _update()
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
			if(btnp(0)) view.inc_sel(-1,0)
			if(btnp(1)) view.inc_sel(1,0)
			if(btnp(2)) view.inc_sel(0,-1)
			if(btnp(3)) view.inc_sel(0,1)

			image:setpx(view.sel,cur_color)
		end
	elseif (edit_mode==1) then
		if(btnp(0)) view.sel.w-=1
		if(btnp(1)) view.sel.w+=1
		if(btnp(2)) view.sel.h-=1
		if(btnp(3)) view.sel.h+=1

		if(view.sel.w<0) view.sel.w=0
		if(view.sel.h<0) view.sel.h=0

		if(view.sel.w>image.w-1) view.sel.w=image.w-1
		if(view.sel.h>image.h-1) view.sel.h=image.h-1
	elseif (edit_mode==0) then
		if(btnp(0)) view.sel.x-=1
		if(btnp(1)) view.sel.x+=1
		if(btnp(2)) view.sel.y-=1
		if(btnp(3)) view.sel.y+=1

		-- image limits
		if(view.sel.x < 0) prompt:show("do you want to add a column?", add_col) view.sel.x=0
		if(view.sel.y < 0) prompt:show("do you want to add a row?", add_row) view.sel.y=0
		if(view.sel.x >= image.w) view.sel.x=image.w-1
		if(view.sel.y >= image.h) view.sel.y=image.h-1

		-- view limits
		-- only one of these can happen at a time since we only move orthogonally
		if(view.sel.x >= view.nw.x+view:gridwidth()-1) view:set(view.sel.x-view:gridwidth()+1, view.nw.y)
		if(view.sel.y >= view.nw.y+view:gridwidth()-1) view:set(view.nw.x, view.sel.y-view:gridwidth()+1)
		if(view.sel.x < view.nw.x) view:set(view.sel.x, view.nw.y)
		if(view.sel.y < view.nw.y) view:set(view.nw.x,view.sel.y)
	end
	
	if(view.sel.x+view.sel.w>image.w-1) then view.sel.x=image.w-view.sel.w-1 end
	if(view.sel.y+view.sel.h>image.h-1) then view.sel.y=image.h-view.sel.h-1 end
end

function add_col()
	if(prompt.answer) then
		if(view.sel.x==0) then
			image:add_col(0)
		else
			image:add_col(image.w)
		end
	end
end

function add_row()
	if(prompt.answer) then
		if(view.sel.y==0) then
			image:add_row(0)
		else
			image:add_row(image.h)
		end
	end
end

function _draw()
	cls()
	for x=view.nw.x,view.nw.x+view:gridwidth() do
		for y=view.nw.y,view.nw.y+view:gridwidth() do
			draw_px(mksel(x,y))
		end
	end
	if(paint_mode==1) then
		draw_px(view.sel,cur_color)
	end

	print(view.sel.x.."x"..view.sel.y.."+"..view.nw.x.."x"..view.nw.y,7)

	draw_palette()
	
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

function draw_palette()
	view:save_camera()
	local size=4
	-- 1 char on each side
	-- plus 1px padding/side
	local tot_w=numhues*size+2*4+2
	-- one line top/bottom
	-- plus 1px padding/side
	local tot_h=numvals*size+2*6+2

	if (view.sel.y > 128/view:gridsize()/2) then
		top = 0
	else
		top = 128-tot_h
	end

	local bgcolor=5
	if(paint_mode > 0) bgcolor=4
	rectfill(
		128/2-tot_w/2,
		top,
		128/2+tot_w/2-1,
		top+tot_h,
		bgcolor
	)
		
	local offx=128/2-(numhues*size/2)
	local offy=top + 7
	for r=0,numvals-1 do
		for c=0,numhues-1 do
			draw_codel(mksel(c,r),size,{val = r, hue = c},offx,offy)
		end
	end
	
	local curhv = image:getpx(view.sel)
	draw_dot(mksel(curhv.hue,curhv.val),size,5,offx,offy)

	if(curhv.val==numvals-1) then
		-- todo
	else
		--print(curhv.hue..curhv.val,8,26,5)
		for x=-1,1 do
			for y=-1,1 do
				if (abs(x+y)==1) then
					local cmp=mksel(view.sel.x+x,view.sel.y+y)
					local cmphv=image:getpx(cmp)
					func = get_func(curhv, cmphv)
					if(x==0) then
						posy=offy-6+(numvals*size+7)*(y+1)/2
						posx=128/2-#func*2
						print(func,posx,posy,7)
					else
						posy=offy+9-#func*3
						posx=offx-4+(numhues*size+5)*(x+1)/2
						for c=0,3 do
							print(sub(func,c+1,c+1),posx,posy+c*6,7)
						end
					end
				end
			end
		end
	end

	if(edit_mode == 3) then
		print(output, 0, top)
		charwidth = flr(((128-tot_w)/2-1)/4)
		local left=128/2+tot_w/2+1
		local sp = #stack
		for r=0,4 do
			x = left
			while true do
				if(sp==0) break
				local numlen = #tostr(stack[sp])
				if(x+numlen*4 < 128) then
					print(stack[sp], x, top+r*6)
					x += numlen*4 + 2
					sp-=1
				else
					break
				end
			end
			if(sp==0) break
		end
	end

	print("",0,0)
	view:load_camera()
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

max_block = {x=nil,y=nil}

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
	view.set_sel(state.x, state.y)
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
00000000000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000000000000000000000
00000000000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000000000
0000000000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000000000
00000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000000000
0000000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000000000
000000000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000000000
00000000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000000000
00000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000000000
0000000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000000000
000000000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000000000
00000000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000000000
00000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000000000
0000000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000000000
000000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000000000
00000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000000000
0000000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000000000000000
000000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000000000000000
00000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000000000
0000000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000000000
000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000
00000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000
000000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000000000
00000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000000000
0000000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000000000
000000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000000000
00000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000
0000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000
00000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000
0000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000
000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000
00000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
00008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000
0000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000
00008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000
0000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f
f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00
00f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800
00008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000
0000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000
00008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000
0000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
0000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f000000
000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8000000
000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f00000000
00000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f800000000
00000000008f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f0000000000
0000000000f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f8f80000000000
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
