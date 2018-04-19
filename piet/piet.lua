-- vim: sw=2 ts=2 sts=2 noet foldmethod=marker foldmarker=-->8,---
-- w/h: 0x0 = 1 cel
require('util')

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
require('hvmap')

------------------------
-- object declarations
------------------------

local state = {x=0, y=0, dp=0, cc=-1, toggle=0, attempts=0}
local stack = {}
local output = ""
local max_block = {x=nil,y=nil}

local next_loop = {funcs = {}}

require("declarations")

-------------------------
-- object methods
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

require("image")
require("prompt")

require("view")
require("palette")

cartdata('cincodenada_piet')
image:load(0x0000, 38, 5, 2, 1, 64)
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
		step()
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
require("state")
require("max_block")

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
		stack:push(shr(future.last_value,16))
	elseif(op == "pop") then
		stack:pop()
	elseif(op == "dup") then
		stack:push(stack:top())
	elseif(op == "add") then
		local top = stack:pop()
		stack[#stack] += top
	elseif(op == "sub") then
		local top = stack:pop()
		stack[#stack] -= top
	elseif(op == "mul") then
		local a = stack:pop()
		local b = stack:pop()
		stack:push(shl(a,8)*shl(b,8))
	elseif(op == "div") then
		local dividend = stack:pop()
		local divisor = stack:pop()
		if(divisor>0) then
			stack:push(shr(dividend/divisor,16))
		end
	elseif(op == "mod") then
		local dividend = stack:pop()
		local divisor = stack:pop()
		if(divisor>0) then
			-- Do a manual modulo cause stupid numbers
			local quotient = shr(dividend/divisor,16)
			stack:push(quotient - shl(quotient,8)*shl(top,8))
		end
	elseif(op == "not") then
		local top = stack:pop()
		if(top == 0) then
			stack:push(1)
		else
			stack:push(0)
		end
	elseif(op == "gt") then
		local b = stack:pop()
		local a = stack:pop()
		if(a > b) then
			stack:push(1)
		else
			stack:push(0)
		end
	elseif(op == "ptr") then
		local rot = stack:pop()
		state.dp += rot
		state.dp %= 4
	elseif(op == "sw") then
		local tog = stack:pop()
		if(abs(tog) % 2 == 1) state.cc = -state.cc
	elseif(op == "cout") then
		output = output..chr(shl(stack[#stack],16))
		stack[#stack] = nil
	elseif(op == "#out") then
		output = output..printbig(stack[#stack])
		stack[#stack] = nil
	elseif(op == "roll") then
		local rolls = shl(stack:pop(),16)
		-- Easier on my brain to work with depth-1
		local depth = shl(stack:pop(),16)-1
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
