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

	-- debug goes here to take advantage of camera reset
	color(7)
	print(view.sel.x.."x"..view.sel.y.."+"..view.nw.x.."x"..view.nw.y)
	print(view:pxdim().x.."x"..view:pxdim().y)
	local cur_color=image:getpx(view.sel)
	print(cur_color.val.."/"..cur_color.hue)

	local bgcolor=5
	if(paint_mode > 0) bgcolor=4
	-- clear background
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

	-- no funcs from black/white blocks
	if(self.curhv.val!=numvals-1) then
		self:draw_funcs()
	end

	if(edit_mode == 3) then
		wrapped = wrap(output, self.wing_width)
		print(wrapped.text, 0, self.top+1, 7)
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
			local numstr = printbig(stack[sp])
			local numlen = #tostr(numstr)
			if(x+numlen*4 < 128) then
				print(numstr, x, self.top+1+r*6)
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
