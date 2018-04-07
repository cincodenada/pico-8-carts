pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- vim: sw=2 ts=2 sts=2 noet
-- w/h: 0x0 = 1 cel
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

function save_image(mem_start,w,h)
	for y=0,h-1 do
		for x=0,w-1 do
			px=y*w+x
			poke(mem_start+px,mget(x,y))
		end
	end
end

function load_image(mem_start,w,h)
	for y=0,h-1 do
		for x=0,w-1 do
			px=y*w+x
			mset(x,y,peek(mem_start+px))
		end
	end
end

sel=mksel(0,0)
prevsel=tcopy(sel)
solidpat=0x0000
midpat=0xa5a5
pxsize=6
gridsize=pxsize+2
save_start=0x5e00
imw=16
imh=16

cartdata('cincodenada_piet')
load_image(save_start, imw, imh)

-- 0 = not editing
-- 1 = changing selection
-- 2 = editing colors
edit_mode=0

numhues=6
numvals=4
colormap={
	15,10,11,12,6,14,
	8,9,3,1,13,2
}

funcmap={
	'n/a','push','pop',
	'add','sub','mul',
	'div','mod','not',
	'gt','ptr','sw',
	'dup','roll','in_n',
	'in_c','out_n','out_c'
}

function getpx(sel)
	local curval = mget(sel.x,sel.y)
	
	-- print("getpx")
	-- print(curval)
	local row = band(curval,0x0f)
	local col = lshr(band(curval,0xf0),4)
	-- print(row)
	-- print(col)

	return {val = row, hue = col}
end

function setpx(sel,px)
	for x=sel.x,sel.x+sel.w do
		for y=sel.y,sel.y+sel.h do
			mset(x,y,px.val + shl(px.hue,4))
		end
	end
	save_image(save_start, imw, imh)
end

function getcol(px)
	if(px.val==numvals-1) then
		-- easy, 0/1 to either
		-- white (7) or black(0)
		return 7*(1-band(px.hue/(numhues/2),0x01))
	else
		-- proper colors
		-- print("getcolor")
		-- rows to get fg/bg colors
		local rowa = band(lshr(px.val,1),0xf)
		local rowb = band(lshr(px.val+1,1),0xf)
		
		-- print(px.hue)
		-- print(px.val)
		-- print(rowa)
		-- print(rowb)
		
		-- get colors from map
		local cola = colormap[rowa*numhues+px.hue+1]
		local colb = colormap[rowb*numhues+px.hue+1]
		return cola + shl(colb, 4)
	end
end

function _update()
	--local prevsel={}
	if(btn(4)) then
		if(edit_mode==2) then
			-- Exit edit mode
			edit_mode=-1
		elseif(edit_mode==0) then
			-- Enter selection edit mode
			prevsel=tcopy(sel)
			edit_mode=1
		end
	else
		if(edit_mode==1) then
			-- Just finished selection
			if(teq(sel,prevsel)) then
				-- If we didn't change size, edit
				edit_mode = 2
			else
				-- Otherwise, back to normal
				edit_mode = 0
			end
		elseif(edit_mode==-1) then
			edit_mode = 0
		end
	end

	if(edit_mode==2) then
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

function draw_px(sel)
	draw_codel(sel,gridsize,getpx(sel),0,0)
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

function _draw()
	cls()
	gridwidth=flr(128/(pxsize+2))
	for x=0,gridwidth do
		for y=0,gridwidth do
			draw_px(mksel(x,y))
		end
	end

	draw_palette()
	
	local framecolor=5
	-- yellow frame for editing
	if(edit_mode > 1) framecolor=4
	
	-- draw selection rectangle
	draw_frame(sel,gridsize,framecolor)

	print("sel:"..sel.w.."x"..sel.h.."+"..sel.x.."x"..sel.y)
	print("prevsel:"..prevsel.w.."x"..prevsel.h.."+"..prevsel.x.."x"..prevsel.y)
	print("E:"..edit_mode)
end

function draw_palette()
	local size=4
	-- 1 char on each side
	-- plus 1px padding/side
	local tot_w=numhues*size+2*4+2
	-- one line top/bottom
	-- plus 1px padding/side
	local tot_h=numvals*size+2*6+2

	rectfill(
		128/2-tot_w/2,
		128-tot_h,
		128/2+tot_w/2-1,
		127,
		5
	)
		
	local offx=128/2-(numhues*size/2)
	local offy=128-(numvals*size+7)
	for r=0,numvals-1 do
		for c=0,numhues-1 do
			draw_codel(mksel(c,r),size,{val = r, hue = c},offx,offy)
		end
	end
	
	local curhv = getpx(sel)
	draw_dot(mksel(curhv.hue,curhv.val),size,5,offx,offy)

	if(curhv.val==numvals-1) then
		-- TODO
	else
		print(curhv.hue..curhv.val,8,26,5)
		for x=-1,1 do
			for y=-1,1 do
				if (x!=0 or y!=0) then
					local cmp=mksel(sel.x+x,sel.y+y)
					local cmphv=getpx(cmp)
					if(cmphv.val==numvals-1) then
						if(cmphv.hue<numhues/2) then
							func="pass"
						else
							func="stop"
						end
					else
						local diffh=(cmphv.hue-curhv.hue)
						if(diffh<0) diffh+=numhues
						local diffv=(cmphv.val-curhv.val)
						if(diffv<0) diffv+=numvals-1

						print(cmphv.hue..cmphv.val,(x+1)*8,20+(y+1)*6,5)

						func=funcmap[diffh*numvals+diffv+1]
					end
					if(x==0) then
						posy=offy-6+(numvals*size+7)*(y+1)/2
						posx=128/2-4*2
						print(func,posx,posy,7)
					else
						posy=offy
						posx=offx-4+(numhues*size+5)*(x+1)/2
						for c=0,3 do
							print(sub(func,c+1,1),posx,posy+c*6,7)
						end
					end
				end
			end
		end
	end
	print("",0,0)
end

__gfx__
0088993311dd22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088993311dd22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008f9a3b1cd62e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f8a9b3c16de2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffaabbcc66ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffaabbcc66ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
