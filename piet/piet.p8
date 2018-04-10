pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vim: sw=2 ts=2 sts=2 noet foldmethod=marker foldmarker=-->8,---
-- w/h: 0x0 = 1 cel
function hex(n,d) return sub(tostr(n,true),5,6) end
function packhv(hv) return hv.val+shl(hv.hue,4) end
function unpackhv(hv) return {val=band(hv,0x0f), hue=lshr(band(hv,0xf0),4)} end
function hashloc(loc) return tostr(loc.x).."#"..tostr(loc.y) end

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

function load_image(mem_start,w,h,gs,memwidth)
	for y=0,h-1 do
		for x=0,w-1 do
			px=y*gs*memwidth/2+x*gs/2
			curval = peek(mem_start+px)
			mset(x,y,packhv(col2hv[curval]))
		end
	end
end

function save_image(mem_start,w,h)
	for y=0,h-1 do
		for x=0,w-1 do
			px=y*w+x
			poke(mem_start+px,mget(x,y))
		end
	end
end

function getpx(px)
	if(px.x < 0 or px.x >= imw or
	   px.y < 0 or px.y >= imh) then
		-- edges are treated as black
		return {val=3,hue=4}
	else
		return unpackhv(mget(px.x, px.y))
	end
end

function setpx(sel,px)
	for x=sel.x,sel.x+sel.w do
		for y=sel.y,sel.y+sel.h do
			mset(x,y,packhv(px))
		end
	end
	save_image(save_start, imw, imh)
end

-- translates a h/v pair to a fill color
-- with upper/lower nibble set properly
function getcol(px)
	return hv2col[px.hue][px.val]
end

---
-->8
sel=mksel(0,0)
prevsel=tcopy(sel)
solidpat=0x0000
midpat=0xa5a5
pxsize=6
gridsize=pxsize+2
save_start=0x0000
imw=14
imh=14

paint_mode=0
cur_color={val=3, hue=1}

-- running variables
local state = {x=0, y=0, dp=0, cc=0, toggle=0}
local stack = {}
local output = ""

menuitem(1, "run program", function() edit_mode=3 end)

cartdata('cincodenada_piet')
load_image(save_start, imw, imh, 6, 128)

-- 0 = not editing
-- 1 = changing selection
-- 2 = editing colors
-- 3 = running
edit_mode=0

function _update()
	--local prevsel={}
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
		cur_color=getpx(sel)
	end
	if(btn(4)) then
		if(edit_mode==2) then
			-- exit edit mode
			edit_mode=-1
		elseif(edit_mode==0) then
			-- enter selection edit mode
			prevsel=tcopy(sel)
			edit_mode=1
		end
	else
		if(edit_mode==1) then
			-- just finished selection
			if(teq(sel,prevsel)) then
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
			local px = getpx(sel)
			
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
			
			setpx(sel,px)
		else
			if(btnp(0)) sel.x-=1
			if(btnp(1)) sel.x+=1
			if(btnp(2)) sel.y-=1
			if(btnp(3)) sel.y+=1

			setpx(sel,cur_color)
		end
	elseif (edit_mode==1) then
		if(btnp(0)) sel.w-=1
		if(btnp(1)) sel.w+=1
		if(btnp(2)) sel.h-=1
		if(btnp(3)) sel.h+=1

		if(sel.w<0) sel.w=0
		if(sel.h<0) sel.h=0

		if(sel.w>imw-1) sel.w=imw-1
		if(sel.h>imh-1) sel.h=imh-1
	elseif (edit_mode==0) then
		if(btnp(0)) sel.x-=1
		if(btnp(1)) sel.x+=1
		if(btnp(2)) sel.y-=1
		if(btnp(3)) sel.y+=1

		if(sel.x<0) sel.x=0
		if(sel.y<0) sel.y=0
	end
	
	if(sel.x+sel.w>imw-1) then sel.x=imw-sel.w-1 end
	if(sel.y+sel.h>imh-1) then sel.y=imh-sel.h-1 end
end

function _draw()
	-- cls()
	gridwidth=flr(128/(pxsize+2))
	for x=0,gridwidth do
		for y=0,gridwidth-4 do
			draw_px(mksel(x,y))
		end
	end
	if(paint_mode==1) then
		draw_px(sel,cur_color)
	end

	--draw_palette()
	
	local framecolor=5
	-- yellow frame for editing
	if(edit_mode > 1) framecolor=4
	
	-- draw selection rectangle
	draw_frame(sel,gridsize,framecolor)

	blockinfo = get_exit(sel)
	col = hv2col[blockinfo.color.hue][blockinfo.color.val]
	bgcol = flr(shr(col, 4))
	if(band(col, 0xf) == bgcol) then
		bgcol = 0
	end
	print("███",0,0,bgcol)
	print("bs:"..blockinfo.count,0,0,col)
end

---
-->8
function draw_px(sel,...)
	local args = {...}
	if(#args > 0) then
		col=args[1]
	else
		col=getpx(sel)
	end

	draw_codel(sel,gridsize,col,0,0)
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
	local size=4
	-- 1 char on each side
	-- plus 1px padding/side
	local tot_w=numhues*size+2*4+2
	-- one line top/bottom
	-- plus 1px padding/side
	local tot_h=numvals*size+2*6+2

	if (sel.y > 128/gridsize/2) then
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
	
	local curhv = getpx(sel)
	draw_dot(mksel(curhv.hue,curhv.val),size,5,offx,offy)

	if(curhv.val==numvals-1) then
		-- todo
	else
		--print(curhv.hue..curhv.val,8,26,5)
		for x=-1,1 do
			for y=-1,1 do
				if (abs(x+y)==1) then
					local cmp=mksel(sel.x+x,sel.y+y)
					local cmphv=getpx(cmp)
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

function state:next()
	local next = tcopy(self)
	if(self.dp % 2==0) then
		next.x += 1-self.dp
	else
		next.y += 2-self.dp
	end
	return next
end

function stack:pop()
	local top = self[#self]
	self[#self] = nil
	return top
end

function stack:push(val)
	self[#self+1] = val
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

function get_exit(start)
	last = {}
	cur = {}
	next = {}
	cur[hashloc(start)] = start
	exit = start
	block_color = packhv(getpx(start))
	block_size = 1
	numloops = 0
	rectfill(0,128-4*gridsize,127,127,0)
	while(true) do
		new_px = 0
		for k,loc in pairs(cur) do
			for dx=-1,1 do
				for dy=-1,1 do
					if(abs(dx+dy)==1) then
						local check = {x=loc.x+dx,y=loc.y+dy}
						if packhv(getpx(check)) == block_color then
							local hash = hashloc(check)
							if last[hash] == nil and cur[hash] == nil and next[hash] == nil then
								next[hash] = check
								new_px+=1
							end
						end
					end
				end
			end
		end
		if (new_px == 0) break
		block_size += new_px
		curstr = ""
		for k,loc in pairs(cur) do
			curstr = curstr..loc.x.."/"..loc.y.." "
		end
		print(curstr,0,128-3*gridsize+6*numloops,7)
		last = cur
		cur = next
		next = {}
		numloops += 1
		if (numloops > 5) break
	end

	return {
		count = block_size,
		exit = exit,
		color = unpackhv(block_color),
	}
end

---
-->8
function step()
	local future = state:next()

	from = getpx(state)
	to = getpx(future)

	op = get_func(from, to)
	if(op == "push") then
		stack:push(get_val(from))
	elseif(op == "pop") then
		stack:pop()
	elseif(op == "dup") then
		stack[#stack+1] = stack[#stack]
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
	elseif(op == "stop") then
		future.x = state.x
		future.y = state.y
		if(toggle==0) then
			future.cc = 1-future.cc
		else
			future.dp = (future.dp+1)%4
		end
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
	sel = mksel(state.x, state.y)
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
ffffff8f8f8f888888999999222222dddddd1111112e2e2ed6d6d69a9a9a2e2e2effffffaaaaaa88888800000000000000000000000000000000000000000000
fffffff8f8f8888888999999222222dddddd111111e2e2e26d6d6da9a9a9e2e2e2ffffffaaaaaa88888800000000000000000000000000000000000000000000
ffffff8f8f8f888888999999222222dddddd1111112e2e2ed6d6d69a9a9a2e2e2effffffaaaaaa88888800000000000000000000000000000000000000000000
fffffff8f8f8888888999999222222dddddd111111e2e2e26d6d6da9a9a9e2e2e2ffffffaaaaaa88888800000000000000000000000000000000000000000000
ffffff8f8f8f888888999999222222dddddd1111112e2e2ed6d6d69a9a9a2e2e2effffffaaaaaa88888800000000000000000000000000000000000000000000
fffffff8f8f8888888999999222222dddddd111111e2e2e26d6d6da9a9a9e2e2e2ffffffaaaaaa88888800000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000ffffff00000000000000000000000000000000000000000000
000000333333dddddd9999992222221c1c1c3b3b3b333333bbbbbb666666aaaaaaeeeeee0000008f8f8f00000000000000000000000000000000000000000000
000000333333dddddd999999222222c1c1c1b3b3b3333333bbbbbb666666aaaaaaeeeeee000000f8f8f800000000000000000000000000000000000000000000
000000333333dddddd9999992222221c1c1c3b3b3b333333bbbbbb666666aaaaaaeeeeee0000008f8f8f00000000000000000000000000000000000000000000
000000333333dddddd999999222222c1c1c1b3b3b3333333bbbbbb666666aaaaaaeeeeee000000f8f8f800000000000000000000000000000000000000000000
000000333333dddddd9999992222221c1c1c3b3b3b333333bbbbbb666666aaaaaaeeeeee0000008f8f8f00000000000000000000000000000000000000000000
000000333333dddddd999999222222c1c1c1b3b3b3333333bbbbbb666666aaaaaaeeeeee000000f8f8f800000000000000000000000000000000000000000000
0000001c1c1c000000000000000000000000000000000000000000000000000000ffffff0000009a9a9a00000000000000000000000000000000000000000000
000000c1c1c1000000000000000000000000000000000000000000000000000000ffffff000000a9a9a900000000000000000000000000000000000000000000
0000001c1c1c000000000000000000000000000000000000000000000000000000ffffff0000009a9a9a00000000000000000000000000000000000000000000
000000c1c1c1000000000000000000000000000000000000000000000000000000ffffff000000a9a9a900000000000000000000000000000000000000000000
0000001c1c1c000000000000000000000000000000000000000000000000000000ffffff0000009a9a9a00000000000000000000000000000000000000000000
000000c1c1c1000000000000000000000000000000000000000000000000000000ffffff000000a9a9a900000000000000000000000000000000000000000000
000000d6d6d6000000111111d6d6d6bbbbbbffffff222222eeeeee8f8f8f000000cccccc0000003b3b3b00000000000000000000000000000000000000000000
0000006d6d6d0000001111116d6d6dbbbbbbffffff222222eeeeeef8f8f8000000cccccc000000b3b3b300000000000000000000000000000000000000000000
000000d6d6d6000000111111d6d6d6bbbbbbffffff222222eeeeee8f8f8f000000cccccc0000003b3b3b00000000000000000000000000000000000000000000
0000006d6d6d0000001111116d6d6dbbbbbbffffff222222eeeeeef8f8f8000000cccccc000000b3b3b300000000000000000000000000000000000000000000
000000d6d6d6000000111111d6d6d6bbbbbbffffff222222eeeeee8f8f8f000000cccccc0000003b3b3b00000000000000000000000000000000000000000000
0000006d6d6d0000001111116d6d6dbbbbbbffffff222222eeeeeef8f8f8000000cccccc000000b3b3b300000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb0000008f8f8f00000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb000000f8f8f800000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb0000008f8f8f00000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb000000f8f8f800000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb0000008f8f8f00000000000000000000000000000000000000000000
000000666666000000dddddd000000000000000000000000000000888888000000bbbbbb000000f8f8f800000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd0000001c1c1c00000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd000000c1c1c100000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd0000001c1c1c00000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd000000c1c1c100000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd0000001c1c1c00000000000000000000000000000000000000000000
000000dddddd000000cccccc000000000000777777000000000000ffffff000000dddddd000000c1c1c100000000000000000000000000000000000000000000
0000002222220000002e2e2e000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
000000222222000000e2e2e2000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
0000002222220000002e2e2e000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
000000222222000000e2e2e2000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
0000002222220000002e2e2e000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
000000222222000000e2e2e2000000777777777777777777000000aaaaaa000000999999000000eeeeee00000000000000000000000000000000000000000000
0000009999990000001c1c1c000000000000bbbbbb0000000000009a9a9a00000033333300000066666600000000000000000000000000000000000000000000
000000999999000000c1c1c1000000000000bbbbbb000000000000a9a9a900000033333300000066666600000000000000000000000000000000000000000000
0000009999990000001c1c1c000000000000bbbbbb0000000000009a9a9a00000033333300000066666600000000000000000000000000000000000000000000
000000999999000000c1c1c1000000000000bbbbbb000000000000a9a9a900000033333300000066666600000000000000000000000000000000000000000000
0000009999990000001c1c1c000000000000bbbbbb0000000000009a9a9a00000033333300000066666600000000000000000000000000000000000000000000
000000999999000000c1c1c1000000000000bbbbbb000000000000a9a9a900000033333300000066666600000000000000000000000000000000000000000000
000000888888000000dddddd0000000000003333336666661c1c1c3b3b3b000000888888000000d6d6d600000000000000000000000000000000000000000000
000000888888000000dddddd000000000000333333666666c1c1c1b3b3b30000008888880000006d6d6d00000000000000000000000000000000000000000000
000000888888000000dddddd0000000000003333336666661c1c1c3b3b3b000000888888000000d6d6d600000000000000000000000000000000000000000000
000000888888000000dddddd000000000000333333666666c1c1c1b3b3b30000008888880000006d6d6d00000000000000000000000000000000000000000000
000000888888000000dddddd0000000000003333336666661c1c1c3b3b3b000000888888000000d6d6d600000000000000000000000000000000000000000000
000000888888000000dddddd000000000000333333666666c1c1c1b3b3b30000008888880000006d6d6d00000000000000000000000000000000000000000000
0000008f8f8f000000cccccc000000000000000000000000000000000000000000ffffff0000001c1c1c00000000000000000000000000000000000000000000
000000f8f8f8000000cccccc000000000000000000000000000000000000000000ffffff000000c1c1c100000000000000000000000000000000000000000000
0000008f8f8f000000cccccc000000000000000000000000000000000000000000ffffff0000001c1c1c00000000000000000000000000000000000000000000
000000f8f8f8000000cccccc000000000000000000000000000000000000000000ffffff000000c1c1c100000000000000000000000000000000000000000000
0000008f8f8f000000cccccc000000000000000000000000000000000000000000ffffff0000001c1c1c00000000000000000000000000000000000000000000
000000f8f8f8000000cccccc000000000000000000000000000000000000000000ffffff000000c1c1c100000000000000000000000000000000000000000000
0000002e2e2e0000002e2e2e1c1c1cd6d6d63b3b3b1c1c1c8f8f8f2e2e2e9a9a9a8f8f8f00000066666600000000000000000000000000000000000000000000
000000e2e2e2000000e2e2e2c1c1c16d6d6db3b3b3c1c1c1f8f8f8e2e2e2a9a9a9f8f8f800000066666600000000000000000000000000000000000000000000
0000002e2e2e0000002e2e2e1c1c1cd6d6d63b3b3b1c1c1c8f8f8f2e2e2e9a9a9a8f8f8f00000066666600000000000000000000000000000000000000000000
000000e2e2e2000000e2e2e2c1c1c16d6d6db3b3b3c1c1c1f8f8f8e2e2e2a9a9a9f8f8f800000066666600000000000000000000000000000000000000000000
0000002e2e2e0000002e2e2e1c1c1cd6d6d63b3b3b1c1c1c8f8f8f2e2e2e9a9a9a8f8f8f00000066666600000000000000000000000000000000000000000000
000000e2e2e2000000e2e2e2c1c1c16d6d6db3b3b3c1c1c1f8f8f8e2e2e2a9a9a9f8f8f800000066666600000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000eeeeee000000000000000000000000000000000000000000000000000000000000000000aaaaaa00000000000000000000000000000000000000000000
000000222222ffffff9a9a9ad6d6d62e2e2e9a9a9a8f8f8f2222221111118888883333339999999a9a9a00000000000000000000000000000000000000000000
000000222222ffffffa9a9a96d6d6de2e2e2a9a9a9f8f8f8222222111111888888333333999999a9a9a900000000000000000000000000000000000000000000
000000222222ffffff9a9a9ad6d6d62e2e2e9a9a9a8f8f8f2222221111118888883333339999999a9a9a00000000000000000000000000000000000000000000
000000222222ffffffa9a9a96d6d6de2e2e2a9a9a9f8f8f8222222111111888888333333999999a9a9a900000000000000000000000000000000000000000000
000000222222ffffff9a9a9ad6d6d62e2e2e9a9a9a8f8f8f2222221111118888883333339999999a9a9a00000000000000000000000000000000000000000000
000000222222ffffffa9a9a96d6d6de2e2e2a9a9a9f8f8f8222222111111888888333333999999a9a9a900000000000000000000000000000000000000000000
