-->8
function view:init()
	self.size[2] = palette.top
end
function view:gridsize() return self.pxsize+2 end
function view:pxdim()
	return {
		x=flr(self.size[1]/(view:gridsize())),
		y=flr(self.size[2]/(view:gridsize()))
	}
end
function view:push_sel() self.prevsel = tcopy(self.sel) end
function view:set_sel(x,y) self.sel.x = x self.sel.y = y end
function view:inc_sel(x,y) self:set_sel(self.sel.x+x,self.sel.y+y) end
-- ensure sel is on nicely on screen
function view:recenter()
	-- deal with sel size
	if(self.sel.w<0) self.sel.w=0
	if(self.sel.h<0) self.sel.h=0

	if(self.sel.w>image.w-1) self.sel.w=image.w-1
	if(self.sel.h>image.h-1) self.sel.h=image.h-1

	if(self.sel.x+self.sel.w>image.w-1) self.sel.x=image.w-self.sel.w-1
	if(self.sel.y+self.sel.h>image.h-1) self.sel.y=image.h-self.sel.h-1
	--
	-- image limits
	if(self.sel.x < 0) self.sel.x=0
	if(self.sel.y < 0) self.sel.y=0
	if(self.sel.x >= image.w) self.sel.x=image.w-1
	if(self.sel.y >= image.h) self.sel.y=image.h-1

	-- view limits
	-- only one of these can happen at a time since we only move orthogonally
	local px = self:pxdim()

	-- todo: don't depend on set() to sanity check us here, it's wasteful
	if(self.sel.x < self.nw.x+flr(px.x*0.25)) self:set(self.sel.x-flr(px.x*0.25), self.nw.y)
	if(self.sel.y < self.nw.y+flr(px.y*0.25)) self:set(self.nw.x,self.sel.y-flr(px.y*0.25))
	if(self.sel.x >= self.nw.x+ceil(px.x*0.75)) self:set(self.sel.x-ceil(px.x*0.75), self.nw.y)
	if(self.sel.y >= self.nw.y+ceil(px.y*0.75)) self:set(self.nw.x, self.sel.y-ceil(px.y*0.75))
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
	-- sanity checks
	if(x < 0) x=0
	if(y < 0) y=0
	if(x+self:pxdim().x > image.w) x=image.w-self:pxdim().x
	if(y+self:pxdim().y > image.h) y=image.h-self:pxdim().y

	self.nw = {x=x,y=y}
	camera(x*view:gridsize(), y*view:gridsize())
end


