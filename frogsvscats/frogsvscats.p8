pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- frogs vs. cats v1.1.1
-- by joel bradshaw
-- vim: sw=2 ts=2 sts=2 noet foldmethod=marker foldmarker=-->8,---
function class(superclass)
	local cls = {}
	cls.next_id, cls.__index = 0, cls
	superclass = superclass or {}
	function superclass.__call(cls, ...)
		local c = {}
		setmetatable(c, cls)
		c.id = cls.next_id
		cls.next_id += 1
		c:constructor(...)
		return c
	end
	setmetatable(cls, superclass)
	return cls
end
function super(parent, self, ...)
	if(not self) return getmetatable(parent)
	getmetatable(parent).constructor(self, ...)
end

function wrap(text, width)
	local charwidth = flr(width/4)
	local actual_width = 0
	text = text.." "
	local curline, word = "","",""
	local lines = {}
	local pos = 1
	while(pos <= #text) do
		local curlet = sub(text,pos,pos)
		if(curlet == " ") then
			if(#curline + #word > charwidth) then
				add(lines, curline)
				curline=""
				-- back up so we re-process the space next line
				pos -= 1
			elseif(#curline + #word == charwidth) then
				add(lines, curline..word)
				curline=""
				word = ""
			else
				curline = curline..word.." "
				word = ""
			end
		elseif(curlet == "\n") then
			if(#curline + #word > charwidth) then
				add(lines, curline)
				add(lines, word)
			else
				add(lines, curline..word)
			end
			curline=""
			word=""
		else
			word = word..curlet
			-- if we have a word that's too long, just break it
			if(curline == "" and #word == charwidth) then
				add(lines, word)
				word=""
			end
		end
		pos += 1
	end
	if(curline!="") add(lines, curline)
	-- trim terminal spaces
	local final_lines = {}
	for l in all(lines) do
		if(sub(l,#l,#l) == " " or sub(l,#l,#l) =="\n") then
			add(final_lines, sub(l,1,#l-1))
		else
			add(final_lines, l)
		end
	end
	return final_lines
end

local credits = {
	roles = {
		"game programming",
		"game design",
		"high-quality programmer art",
		"top-notch animation",
		"map design",
		"story writing",
		"ux testing",
		"alpha testers",
		"beta testers",
		"people who actually\ndidn't test much, really",
	},
	extra_roles = {
		{"emotional support","myka dubay","anna barton"},
		{"inspiration and reference code","finn aka @relsqui"},
	},
	name = "joel bradshaw",
	countdown = nil,
	top=128,
}

local lore = {
	areas = {
		{
			id = 1,
			mapid = 1,
			intro = "you're in an open field. you can see far from here.",
			short = "an open field",
			links = {
				-- default: n/s/e/w
				north = 2,
				south = 5,
				east = 4,
				up = "the sun. it hurts your eyes. maybe you should try another door.",
			},
		},
		{
			id = 2,
			mapid = 2,
			short = "a small stream. it looks refreshing.",
			intro = "you're near a nice stream. it babbles peacefully.",
			links = {
				south = 1,
				east = 3,
			},
			items = {
				{"blue key",39,13,3,1,"the water is nice and cool on your froggy feet. you peer down idly and notice something shiny. you pick it up."},
			},
		},
		{
			id = 3,
			mapid = 3,
			short = "a flowery meadow",
			intro = "it's a clearing in a forest. the meadow makes you feel calm.",
			links = {
				south = 4,
				west = 2,
			},
			items = {},
		},
		{
			id = 4,
			mapid = 3,
			bg = 1,
			short = "a forest. not too dark...yet.",
			intro = "you're in the midst of some dense woods. is it getting darker?",
			links = {
				north=3,
				west=1,
				east=6,
			},
			items = {
				{"green key",55,15,3,1,"you peer into the weeds and notice something shiny. it's a key!"},
			},
		},
		{
			id = 5,
			bg = 0,
			mapid = 3,
			short = "a cave. kinda creepy.",
			intro = "you are in a rough cave. it gets dark very quickly. you hear dripping water towards the back.",
			links = {
				north=1,
				grate=8,
			},
			items = {},
		},
		{
			id = 6,
			mapid = 4,
			bg = 1,
			short = "the gate to a large castle",
			intro = "as you get closer, you realize you were mistaken. per the large sign over the gate, it is actually a catsle beyond this gate",
			links = {
				west=4,
			},
			items = {
				{"silver key",65,15,2,1,"you find a small crack in the wall. further inspection reveals a glint. you reach in and pull out a key!"},
			},
		},
		{
			id = 7,
			mapid = 3,
			bg = 0,
			short = "a dark, narrow tunnel",
			intro = "you seem to have emerged in some sort of dungeon! judging by the feline-themed decor, you guess you are underneath the catsle that you approached earlier",
			links = {
				tunnel=8
			},
			items = {
				{"locked chest",55,15,3,1,"you see a big oak chest. it seems pretty immune to brute force. there are holes in the side, but not large enough to see anything."},
			},
		},
		{
			id = 8,
			mapid = 3,
			bg = 0,
			short = "an ample tunnel",
			intro = "you're in a dark subterranean room lit dimly by torches, somehow still alight.",
			links = {
				tunnel = 7,
				grate = 5,
			},
			items = {
				{"an old scroll",55,15,3,1,"it seems to be blank. could the developer have run out of time to do anything with it?"},
			},
		},
	},
	maps = {
		-- all coords in blocks!
		{
			x=0,y=0,w=32,
			px=22,py=10,
			cats = {{25,11}},
			doors = {{22,12},{18,9},{11,7},{5,9},{28,16}},
			text_offset = 0,
		},
		{
			x=32,y=0,w=16,
			px=6,py=13,
			cats = {{39,13}},
			doors = {{33,4},{33,10},{45,13}},
			text_offset = 4,
		},
		-- boring base map
		{
			x=48,y=0,w=16,
			px=52,py=15,
			cats={{61,15},{55,12}},
			doors={{49,15},{55,12},{60,15}},
			text_offset = 0,
		},
		-- catsle
		{
			x=64,y=0,w=16,
			px=74,py=15,
			cats = {
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
				{64 + flr(rnd(13)),flr(rnd(20))},
			},
			doors={{78,15}},
			text_offset = 0,
		},
		-- cave
		{
			x=80,y=0,w=16,
			px=88,py=15,
			text_offset = 0,
		},
	},
}

local game = {
	x=0, y=0,
	texts = {},
	to_scoot = 0,
	debug_blocks = {},
	cats = {},
	doors = {},
	debug = "",
	cameras = {},
	cur_area = nil,
	cur_map = nil,
}
function game:reset()
	self.player = player(0,120)
	self:load_area(1)
	-- override area text and player position for first play
  self.texts ={{msg="you wake up in a bright field. you attempt to walk forward, but find that you feel a little...hoppy.\nahead, you see\nmovement in the\ndistance.",x=0}}
	self.player.x=0
	self.player.y=120
end
function game:save_camera() add(self.cameras, peek4(0x5f28)) camera() end
function game:load_camera() poke4(0x5f28, self.cameras[#self.cameras]) self.cameras[#self.cameras] = nil end
function game:xmin() return self.cur_map.x*8 end
function game:xmax() return self.cur_map.x*8+self.cur_map.w*8-1 end
-- this should probably be its own object
-- but we're in crunch time
function game:load_area(id, from_door)
	local a = lore.areas[id]
	local m = lore.maps[a.mapid]
	self.cur_area, self.cur_map = a, m

	self.cats = {}
	for c in all(m.cats) do
		add(self.cats, cat(c[1]*8,c[2]*8))
	end
	-- more cats?!
	if(a.cats) then
		for c in all(a.cats) do
			add(self.cats, cat(c[1]*8,c[2]*8))
		end
	end

	self.doors = {}
	self.cur_map.doors = game:find_doors()
	local dooridx = 1 -- todo: randomize
	local player_door = nil
	for label,info in pairs(a.links) do
		self:add_door(label, info, dooridx)
		if(label == from_door) player_door = self.doors[dooridx]
		dooridx += 1
	end

	self:load_items()

	self.x = m.x*8
	local text = {msg=a.intro, col=7, x=self.x}
	if(m.text_offset) then
		text.x += m.text_offset*8
		text.w = 127-m.text_offset*8
	end
	self.texts = {text}
	self.to_scoot = 0

	if(player_door) then
		game.player.x = player_door.x
		game.player.y = player_door.y
	else
		game.player.x = self.x+m.px*8
		game.player.y = m.py*8
	end
end
function game:find_doors()
	doors = {}
	for x=self.cur_area.x,self.cur_area.x+self.cur_area.w-1 do
		for y=self.cur_area.y,self.cur_area.y+15 do
			if(mget(x,y)==190) add(doors, {x,y+1})
		end
	end
	return doors
end
function game:load_items()
	self.items = {}
	for info in all(self.cur_area.items) do
		local i = exists(info[2]*8,info[3]*8,info[4]*8,info[5]*8)
		i.name = info[1]
		i.message = info[6]
		add(self.items, i)
	end
end
function game:add_door(label,di,idx)
		local dc = self.cur_map.doors[idx]
		add(self.doors, door(dc[1]*8,dc[2]*8,label,di))
end
function game:show_message(msg, duration, bg)
	local m = {
		msg=msg,
		x=max(self.x,self:xmin() + self.cur_map.text_offset*8),
	}
	if(duration) m.duration=duration*30
	m.w = 127-(m.x-self.x)
	m.bg = bg
	add(self.texts, m)
end
function game:inspect_door(d)
	-- todo: properly conditionalize these
	local where
	if(d.label == "north" or
	   d.label == "south" or
	   d.label == "east" or
	   d.label == "west" or
	   d.label == "up") then
		where = d.label
	else
		where = "at the "..d.label
	end
	self.texts = {
		{msg="you look "..where..". you see "..d.text, col=7, x=self.x},
	}
	if(d.label != "up") then
		-- todo: properly conditionalize this
		add(self.texts,{msg="press o/x again to enter", col=7, x=self.x+5})
	end
end
function game:enter_door(d)
	if(d.label == "grate" and not d.unlocked) then
		if(self.player:has_item("silver key")) then
			game:show_message("you try the silver key in the grate. it opens with a loud creak. there's an old musty culvert behind it that's plenty wide for a frog to fit through.")
			d.unlocked = true
		else
			game:show_message("the grate doesn't budge. you sweep away some debris and spy a keyhole that seems promising.")
			return
		end
	end
	if(d.link.area) then
		local ld = d.link.door
		-- if not n/s/e/w, they should be matching pairs
		if(not ld) ld=d.label
		self:load_area(d.link.area, ld)
	end
end
function game:update()
	self.debug_blocks = {}
	self.debug = ""
	self.player:update()
	for c in all(self.cats) do
		c:update()
	end
	if(self.to_scoot != 0) then
		self.cur_move = nil
		self.next_move = nil
		self.x += sgn(self.to_scoot)
		self.to_scoot -= sgn(self.to_scoot)
	end
	camera(self.x,0)
end
function game:draw()
	local bg = self.cur_area.bg or 12
	cls(bg)
	map(0,0,0,0,128,32,1+4)
	foreach(self.doors, function(t) t:draw() end)
	self.player:draw()
	for c in all(self.cats) do c:draw() end
	for i in all(self.items) do i:draw() end
	cury = 1
	for t in all(self.texts) do
		if(not t.duration or t.duration > 0) then
			local tw = t.w
			if(not tw) tw=127
			local c = t.col
			if(not c) c=7

			local lines = wrap(t.msg,tw)
			for l in all(lines) do
				rectfill(t.x,cury-1,t.x+#l*4,cury+5,bg)
				print(l,t.x+1,cury,c)
				cury += 6
			end

			if(t.duration) t.duration -= 1
		end
	end
	if(self.debug!="") game:draw_debug()
end
function game:dbg(txt)
	self.debug = self.debug..txt.."\n"
end
function game:draw_debug()
	for b in all(self.debug_blocks) do
		spr(240+b.s,b.x*8,b.y*8)
	end
	if(#self.debug > 0) then
		self:save_camera()
		camera(0,0)
		rectfill(0,0,128,50,0)
		print(self.debug,1,0,7)
		self:load_camera()
	end
end
function game:scoot(dist)
	if(self.x + dist < self:xmin()) then
		dist = self:xmin() - self.x
	elseif(self.x + dist > self:xmax()) then
		dist = self:xmax()-self.x
	end
	self.to_scoot = dist
end
function game:get_colliding(x,y,w,h)
	if(not y) then
		-- convert from bb
		local bb = x
		x,y,x2,y2 = bb.w,bb.n,bb.e,bb.s
	else
		if(not w) w=1
		if(not h) h=1
		x2 = x+w-1
		y2 = y+h-1
	end
	local colliding = {}
	for cx=flr(x/8),flr(x2/8) do
		for cy=flr(y/8),flr(y2/8) do
			local cs = mget(cx, cy)
			if(fget(cs, 0)) then
				add(game.debug_blocks,{x=cx,y=cy,s=1})
				add(colliding, {x=cx,y=cy})
			else
				add(game.debug_blocks,{x=cx,y=cy,s=0})
			end
		end
	end
	
	if #colliding == 0 then
		return nil
	else
		return colliding
	end
end
function game:player_door()
	for d in all(self.doors) do
		if(d:intersects(self.player)) return d
	end
end
function game:player_item()
	for i in all(self.items) do
		if(i:intersects(self.player)) return i
	end
end


-- position is 1px below lower-left corner of sprite ("on the ground")
sprite = class()
function sprite:constructor(w, h, frames)
	if(type(frames) == "number") frames = {frames}
	self.w, self.h, self.frames = w, h, frames
	self.cur_frame = 0
	self.facing = 1
end
function sprite:frame() return flr(self.cur_frame) end
function sprite:draw(x, y)
	local flipped = (self.facing==-1)
	local fidx = self:frame()+1
	-- todo: this should be speed-dependendent and doesn't work
	--local adj = self:adj(fidx)
	--x += adj.x - 1
	--y += adj.y + 1
	spr(self.frames[fidx], x, y-self.h*8, self.w, self.h, flipped)
end
function sprite:move_frame(howmany)
	if(howmany < 0) stop("not supported!")
	if(#self.frames == 5) printh(self.cur_frame.."+"..howmany.."frames")
	self.last_frame = self.cur_frame
	self.just_looped = false
	self.cur_frame += howmany
	-- manually set to zero to deal with fractional stuff
	if(self.cur_frame >= #self.frames) then
		self.cur_frame = 0
		self.just_looped = true
	end
end
function sprite:set_frame(towhat)
	if(towhat < #self.frames) then
		if(towhat < self.cur_frame) then
			-- hmm
			self.just_looped = true
		end
		self.cur_frame = towhat
	end
end
function sprite:entered(frame)
	return (self:frame() >= frame and (flr(self.last_frame) < frame or self.just_looped))
end
-- this only works for 2x2 sprites!
-- flags store how much the sprite should move
-- to stay with animation per frame
--
-- this gets our adjustment for this frame
function sprite:adj(n)
	-- sprite with adjustment data is the lower-left sprite
	local adjsprite = self.frames[n] + 16
	local flagbyte = fget(adjsprite)
	return {
		x=flr(shr(shl(flagbyte, 8), 12))*self.facing,
		y=shr(shl(flagbyte, 12), 12)
	}
end
function sprite:cur_sprite()
	return self.frames[self:frame()+1]
end
function sprite:flag(n)
	-- for now only support top row
	local subidx = flr(n/8)
	return fget(self:cur_sprite() + subidx, n%8)
end

exists = class()
function exists:constructor(x,y,w,h)
	self.x, self.y, self.w, self.h  = x, y, w, h
end
function exists:center()
	return {
		x=self.x + self.w/2,
		y=self.y - self.h/2
	}
end
-- returns boundaries, idx are buttons (lrud)
function exists:b(idx)
	if(idx == 0 or idx=='w') return flr(self.x)
	if(idx == 1 or idx=='e') return flr(self.x+self.w-1)
	if(idx == 2 or idx=='n') return flr(self.y-self.h)
	if(idx == 3 or idx=='s') return flr(self.y-1)
end
function exists:contains_x(p) return (p >= self:b(0) and p <= self:b(1)) end
function exists:contains_y(p) return (p >= self:b(2) and p <= self:b(3)) end
function exists:bb()
	local c = self:center()
	return {
		w=self:b(0),
		e=self:b(1),
		n=self:b(2),
		s=self:b(3),
		cx=flr(c.x),
		cy=flr(c.y),
	}
end
function exists:intersects(other)
	local me = self:bb()
	local them = other:bb()
	-- maybe not super efficient
	-- but should do the trick
	if((
	    (self:contains_x(them.e) or self:contains_x(them.w))
	     and (self:contains_y(them.n) or self:contains_y(them.s))
	   ) or (
	    (other:contains_x(me.e) or other:contains_x(me.w))
	     and (other:contains_y(me.n) or other:contains_y(me.s))
	   )) then
		return true
	end
	return false
end
function exists:draw()
	if(false) then
		local bb=self:bb()
		rect(bb.w,bb.n,bb.e,bb.s,8)
	end
end

visible = class(exists)
function visible:constructor(x,y,sprite)
	self.sprite = sprite
	super(visible, self, x, y, self.sprite.w*8, self.sprite.h*8)
end
function visible:draw()
	self.sprite:draw(self.x, self.y)
	super(visible).draw(self)
end

door = class(visible)
function door:constructor(x,y,label,info)
	super(door, self, x, y, sprite(2, 4, 142))
	self.info = info
	self.label = label
	if(type(info) == "number") then
		local ref = lore.areas[info]
		self.text = ref.short
		self.link = {area=info}
	elseif(type(info) == "string") then
		self.text = info
		self.link = {}
	else
		self.text = info[1]
		self.link = {area=info[2],door=info[3]}
	end
	if(not self.link.door) self.link.door = self:get_link()
	self.label_offset = flr(rnd(2))
end
function door:get_link()
	if(self.label == "north") return "south"
	if(self.label == "south") return "north"
	if(self.label == "east") return "west"
	if(self.label == "west") return "east"
end
function door:draw()
	pal(14,0)
	super(door).draw(self)
	pal(14,14)
	if(self.label) do
		local width=#self.label*4
		local halfw = max(width/2, 2*4)
		local bb = self:bb()
		rectfill(
			bb.cx-flr(halfw)-2,bb.n+2,
			bb.cx+ceil(halfw),bb.n+10,15
		)
		rect(
		  bb.cx-flr(halfw)-2,bb.n+2,
			bb.cx+ceil(halfw)+1,bb.n+10,4
		)
		print(self.label,bb.cx-flr(width/2)+self.label_offset,bb.n+4,5)
	end
end

entity = class(visible)
function entity:constructor(...)
	super(entity, self, ...)
	self.cur_move = nil
	self.next_move = nil
	self.anim_state = {
		active = false,
		looping = false,
		frame = 0,
	}
	self.frame_slow = {}
	self.slow = 1
end
function entity:update()
	self.collided = false
	self.hit_edge = false
	self:update_pos()
	self:update_anim()
	self:check_collisions()
	self:update_speed()
end
function entity:update_pos()
	if(self.next_move and not self.cur_move) then
		self.cur_move = self.next_move
		self.next_move = nil
	end
	if(self.cur_move) then
		self.x += self.cur_move.vx/self.slow
		self.y += self.cur_move.vy/self.slow
	else
		if(self:is_floating()) self.y += 1.5
	end

	if(self.x < game:xmin()) then
		self.x = game:xmin()
		self.hit_edge=true
	elseif(self.x+self.w >= game:xmax()) then
		self.x = game:xmax()-self.w
		self.hit_edge=true
	end
end
function entity:update_speed()
	-- if we have limits check them
	if(self.cur_move) then
		if(self.cur_move.dx) then
			self.cur_move.dx -= abs(self.cur_move.vx/self.slow)
			if(self.cur_move.dx <= 0) self.cur_move.vx = 0
		end
		if(self.cur_move.dy) then
			self.cur_move.dy -= abs(self.cur_move.vy/self.slow)
			if(self.cur_move.dy <= 0) self.cur_move.vy = 0
		end
		if(self.cur_move.vx == 0 and self.cur_move.vy == 0) self.cur_move = nil
	end
end
function entity:update_anim()
	if(self.anim_state.active) then
		self.sprite:move_frame(self:fpf()/self.slow)

		if(not self.anim_state.looping and self.sprite:entered(0)) then
			self.anim_state.active = false
			-- frame slows on one-shots expire
			self.frame_slow = {}
		end
	end
end
function entity:set_frame_slow(first, last, slow)
	for n=first,last do
		self.frame_slow[n] = slow
	end
end
function entity:fpf()
	-- flag 8 is 2-frame sprites
	local frame_slow = 1
	if(self.frame_slow[self.sprite:frame()]) then
		frame_slow = self.frame_slow[self.sprite:frame()]
	elseif(self.sprite:flag(8)) then
		frame_slow = 2
	end

	return self:base_fpf()/frame_slow
end
function entity:base_fpf()
	if(self.cur_move) then
		return abs(self.cur_move.vx)
	else
		return 1
	end
end
function entity:animate(looping)
	self.anim_state.active = true
	self.anim_state.looping = looping
end
-- relative to facing!
function entity:move(dx,dy)
	self.x += dx*self.sprite.facing
	self.y += dy
end
function entity:add_move(dx,dy,vx,vy)
	if(not self.next_move) self.next_move = { dx=abs(dx), dy=abs(dy), vx=vx*self.sprite.facing, vy=vy, x0=self.x, y0=self.y }
end
function entity:replace_move(dx,dy,vx,vy)
	self.cur_move = { dx=abs(dx), dy=abs(dy), vx=vx*self.sprite.facing, vy=vy, x0=self.x, y0=self.y }
end
function entity:is_floating()
	return not game:get_colliding(self.x,self.y,self.w)
end
function entity:check_collisions()
	-- resolve gravity first
	local bb = self:bb()
	local cblock = game:get_colliding(bb)
	if(cblock) then
		cblock = cblock[1]
		-- if we're not moving (aka falling)
		-- or, we're moving down otherwise
		if(not self.cur_move or (self.cur_move.vx == 0 and self.cur_move.vy >= 0)) then
			-- if we fell through a floor, deal with that first
			if(self:contains_y(cblock.y*8)) then
				self.y=cblock.y*8
			end
		end
	end

	-- then check to see if we're still colliding
	bb = self:bb()
	cblock = game:get_colliding(bb)
	if(cblock) then
		cblock = cblock[1]
		self.collided = true
		--printh("cb:"..cblock.y.."/"..(cblock.y*8).." sy:"..self.y.." bb.s:"..bb.s,"log")
		-- we only bump up for gravity
		if(self:contains_y(cblock.y*8+7)) then
			--self.y=cblock.y*8+8+self.h
		end

		if(self.cur_move and self.cur_move.vx != 0) then
			if(self:contains_x(cblock.x*8)) then
				self.x=cblock.x*8-self.w-1
			elseif(self:contains_x(cblock.x*8+7)) then
				self.x=cblock.x*8+7+1
			end
		end
	end

	-- if(self.collided) sfx(1)
end

tinyfriend = class(entity)
function tinyfriend:constructor(x,y)
	super(tinyfriend, self,
		x, y, sprite(1, 1, 224))
	self:animate(true)
end
function tinyfriend:update()
	super(tinyfriend).update(self)
	if(not self:is_floating()) self.cur_move = {vy=-2,vx=0,dy=10}
end

cat = class(entity)
function cat:constructor(x,y)
	super(cat, self,
		x, y, sprite(2, 2, {64,66,68,70,72}))
	self:animate(true)
end
function cat:update()
	if(self:is_floating()) then
		self.cur_move = nil
	else
		if(not self.cur_move) self.cur_move = {vx=0.5,vy=0}
	end

	-- turn around at edges of ground
	if(self.cur_move) then
		if(self.cur_move.vx < 0) then
			if(not game:get_colliding(self.x-1,self.y)) self.cur_move.vx *= -1
		elseif(self.cur_move.vx > 0) then
			if(not game:get_colliding(self.x+self.w,self.y)) self.cur_move.vx *= -1
		end
	end

	super(cat).update(self)

	-- turn around if we hit things or the edge
	if(self.cur_move) then
		if(self.collided or self.hit_edge) self.cur_move.vx *= -1
		self.sprite.facing = sgn(self.cur_move.vx)
	end
end

frog = class(entity)
function frog:constructor(x,y)
	super(frog, self,
		x, y, sprite(2, 2, {0,2,4,6,8,10,12,14,32,34,36,38,40,42,44}))
end
function frog:base_fpf() return 1 end
function frog:jump(dir)
	if(self:is_floating()) return
	if(self.jumping and not self.leaping) then
		if(dir == self.sprite.facing) then
			self.next_jump = dir
		else
			self.next_jump = nil
		end
		return
	end
	if(dir) self.sprite.facing = dir
	self.jumping = true

	self:animate(false)
	sfx(0)
end
function frog:update_jump()
	if(self.jumping) then
		-- manage start/end of jump
		if(self.sprite:entered(5)) then
			-- start movement
			-- if we're gonna run into something, make it a leap
			local jump_x = 16
			local jump_y = 8
			if(game:get_colliding(self.x + jump_x*self.sprite.facing, self:b('n'), self.w, self.h)) then
				if(not game:get_colliding(self.x + jump_x*self.sprite.facing, self:b('n') - jump_y, self.h)) then
					self.leaping = true
				end
			end
			if(self.leaping) then
				if(self.leaping_up) then
					self:set_frame_slow(5,10,4)
					self:replace_move(0,24,0,-2)
				else
					self:replace_move(16,8,1.5,-1)
				end
			else
				self:replace_move(16,0,1.5,0)
			end
		end

		if(self.sprite:entered(13) and self.next_jump and not self:is_floating()) then
			self:reset_jump()
			self.sprite:set_frame(4)
			-- un-reset this one, we're still jumping
			self.jumping = true
			sfx(0)
		elseif(self.sprite:entered(0)) then
			self:reset_jump()
		end
	end
end
function frog:leap(up)
	if(self:is_floating()) return
	self.leaping = true
	if(up) self.leaping_up = true
	self:jump()
end
function frog:reset_jump()
	self.jumping = false
	self.next_jump = false
	self.leaping = false
	self.leaping_up = false
end

player = class(frog)
function player:constructor(...)
	super(player, self, ...)
	self.last_door = nil
	self.items = {}
end
function player:update()
	if(btnp(0)) self:jump(-1)
	if(btnp(1)) self:jump(1)
	if(btnp(2)) self:leap(true)

	if(btnp(4)) self:inspect()

	if(false) then
		next_area = game.cur_area.id+1
		if(next_area > #lore.areas) next_area = 1
		game:load_area(next_area)
	end

	super(player).update(self)
	self:update_jump()

	if(self.y - self.sprite.h > 127) then
		sfx(2)
	-- only start player at the very beginning the first time
		game:reset(200)
		return
	end

	if(self.x > game.x + 128-self.w) then
		game:scoot(self.w)
	elseif(self.x < game.x+self.w) then
		game:scoot(-self.w)
	end
end
function player:inspect()
	-- could probably be more efficient
	-- and use sprite flags here but ehhh
	local found_something = false
	local door = game:player_door()
	if(door) then
		found_something = true
		if(self.last_door == door) then
			-- go in
			game:enter_door(door)
		else
			self.last_door = door
			game:inspect_door(door)
		end
	end
	local item = game:player_item()
	if(item) then
		found_something = true
		game:show_message(item.message, 5)
		if(item.name == "locked chest") then
			if(self:has_item("blue key")) then
				game:show_message("you unlocked the chest! inside is a very sad small frog! you're a hero!")
				add(game.cats, tinyfriend(self.x+self.w, self.y-8))
				credits.countdown = 7*30
			else
				if(self:has_item("blue key")) game:show_message("you try the blue key, but the lock doesn't budge")
				if(self:has_item("green key")) game:show_message("you try your green key, but the chest is unyielding")
				game:show_message("it's pretty locked.")
			end
		else
			game:show_message("you found a "..item.name.."!", 5)
			add(self.items, item)
		end
	end
	if(not found_something) then
		game:show_message("there doesn't seem to be anything here.", 3, true)
	end
end
function player:has_item(name)
	for i in all(self.items) do
		if(i.name == name) return true
	end
	return false
end

function _init()
	credits:init()
	game:reset()
end

function _update()
	game:update()
end

function _draw()
	if(credits.countdown and credits.countdown <= 0) then
		credits:draw()
	else
		game:draw()
		if(credits.countdown) then
			credits.countdown -= 1
		end
	end
end

function credits:init()
	self.lines = {}
	for a in all(self.roles) do
		add(self.lines, a)
		add(self.lines, self.name)
		add(self.lines, "")
	end
	for a in all(self.extra_roles) do
		add(self.lines, a[1])
		for i=2,#a do
			add(self.lines, a[i])
		end
		add(self.lines, "")
	end
end
function credits:draw()
	cls()
	camera(0,0)
	self.top -= 0.75
	local y = self.top
	local wrote_something = true
	local line_num = 0
	for a in all(self.lines) do
		if(y < 128) then
			print(a, 64-#a*4/2, y+line_num*6, 7)
			wrote_something = true
			line_num+=1
		end
	end
	if(y+line_num*6) < 0 then
		self.countdown = nil
		game:reset()
	end
end

__gfx__
000000000000000000000000000000000000000000000bb000000000000000000000000000077bb0000000000000770000000000000077000000000000007700
0000000000000000000000000000bb00000000000077bbbb0000000000077bb00000000000771bbb00000000007771b000000000007771b00000bbbb007771b0
000000000000bb0000000000077bbbb0000000000071bbb70000000000071bbb0000000000bbbb77000000000071bbbb00bbbbbbbb71bbbb00bbbbbbbb71bbbb
00000000077bbbb000000000071bbb70000000000bbbbb700000000000bbbbb700000000bbbbb77000000bbbbbbbbbbb0b33bbbbbbbbbbbb0b33bbbbbbbbbbbb
00000000071bbb7000000000bbbbb70000000000bbbbb77000000000bbbbbb77000000bbbbbb7700000bbbbbbbbb777003333bbbbbbb777003333bbbbbbb7770
00000000bbbbb7000000000bbbbb77000000000bbbbbb700000000bbbbbbb7000000bbbbbbbb700000b33bbbbbb7700033333bbbbb77700003333bb7bb777000
0000000bbbbb7700000000bbbbbb7000000000bbbbbbb70000000bbbbbbbb700000b33bbbbbb7000003333bbbbb7000033333b777370000033333b7773700000
000000bbbbbb700000000bbbbbbb70000000bbbbbbbb70000000bbbbbbbb700000b3333bbb777000033333bb7377000033333777733000003333377773300000
0000bbbbbbbb70000000bbbbbbb70000000bbbbbbbb37000000bbbbbbbbb70000033333bbb770000033333b77337000033330007733000003333000073300000
000bbbbbbbb77000000bbbbbbb370000000bbbbbbbb3700000bbb333bb7370000333333b7370000033333b777330000033300000330000003330000033000000
000bbbbbbb370000000bbbbbbb37000000b3333bbb73300000b33333b7733000333333b773300000333300000330000033000000330000003300000033000000
00b333bbb337000000b333bbb73300000333333bb773300003333333777330003333000003300000333000000330000033000000330000003300000033000000
0333333b733000000333333b77330000333333337700330033333000000333003330000000330000333000000030000033300000330000003330000033000000
33333333773300003333333370030000333333000000330033300000000033000333000000330000033300000033000003300000300000000333000330000000
33333333003330003333333300033000033333300000330003333300000033000033300000030000003300000000000003300000000000000033000000000000
03333333300333000333333330033300033333330000033000333330000003000003330000000000000330000000000000300000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbbb000077000000bb0000000000000000000007700000000000077bb000000000000770000000000000007700000000000007770000000000000770bb0
00333bbbbb07771b000bbbbbb00007700000bbbb007771b0000000007771bbb0000000007771bb000000000000771bb00000000000771b00000000000071bbbb
003333bbbbb71bbb00033bbbbb07771b00bbbbbbbb71bbbb0000000071bbb7700000000071bbbbb0000000000071bbbb00000000bbbbbbbb000000000bbbbb77
033333bbbbbbbbbb003333bbbbb71bbb0b33bbbbbbbbbbbb000bbbbbbbbb770000000bbbbbbbb770000000bbbbbbbb770000000bbbbbbb770000000bbbbbb770
333333bbbbbbb770003333bbbbbbbbbb03333bbbbbbbb77000b33bbbbbb77000000bbbbbbbbb770000000bbbbbbbb770000000bbbbbbb770000000bbbbbb7700
33333b777bb77700033333bbbbbbb77003333bbbbbbb77000b3333bbbbb7000000b33bbbbbb770000000bbbbbbbb77000000bbbbbbbb770000000bbbbbbb7000
3330000777370000033333777bbb7700333333bbbbb77000033333bbbb7700000b3333bbbbb77000000bbbbbbbbb7000000bbbbbbbbb7000000bbbbbbbb77000
330000007733000033333b777733700033333b7777330000333333bbb3370000033333bbbbb7700000bbb33bbbb77000000bbbbbbbbb700000bbbbbbbb770000
330000000733000033300000773300003333b7777333000033333bbb73300000333333bbbb33000000b33333bb33000000b3333bbb37000000bbbbbbb3370000
330000000330000033000000033000003300000003300000333bb7777330000033333bbb7733000003333333bb3300000333333bbb3300000b33333bb3370000
3330000003300000333000000330000033300000033000003333000003300000333bbb7773300000033333337733000033333337773300000333333b73330000
03300000033000000333000033000000033300000330000003333000033000003333000003300000033330000033000033333300003300003333333370330000
00000000033000000033000033000000003330000330000000333000003300000033300000330000033333000033000003333330000330000333333300333000
00000000030000000000000003300000000333000033000000033300000300000003333000033000003333300003300000333333000033000003333330003300
50000000000050000500000000000000005000000000000005000000000000005000000000005000500000000000500000000000000000000000000000000000
50000000000555500500000000005000005000000000000005000000000050005000000000055550500000000005555000000000000000000000000000000000
500000000055715e050000000005555000500000000050000500000000055550500000000055715e500000000055715e00000000000000000000000000000000
5500000000555555050000000055715e0550000000055550050000000055715e5500000000555555550000000055555500000000000000000000000000000000
05000000005555500500000000555555050000000055715e05000000005555550500000000555550050000000055555000000000000000000000000000000000
05000000055555000500000000555550050000000055555505000000005555500500000005555500050000000555550000000000000000000000000000000000
05555555555555000555555555555500055555555555555005555555555555000555555555555500055555555555550000000000000000000000000000000000
05555555555555000555555555555500055555555555550005555555555555000555555555555500055555555555550000000000000000000000000000000000
05665555555556000566555555555600056655555555550005665555555565000566555555556500056655555555560000000000000000000000000000000000
06666555555566000666655555556600066665555556650006666555555665000666655555566500066665555555660000000000000000000000000000000000
06666555555566000666655555556600066665555566600006666555556660000666655555566000066665555555660000000000000000000000000000000000
06660555555066000666655555566000006665555566000000666555556600000066655555566000066605555550660000000000000000000000000000000000
06660000000006000066600000066000000666000660000000666000006000000066600000066000066600000000060000000000000000000000000000000000
00660000000006000006600000060000000066000600000000066600006600000006600000006000006600000000060000000000000000000000000000000000
00660000000006000000770000060000000006600600000000006600000770000000600000007700006600000000060000000000000000000000000000000000
00077000000007700000000000077000000000770770000000000770000000000000770000000000000770000000077000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb444444444411c1111c1111111111144444444444000000005555555555565555000000000000000000000000000000000000000000000000
bbbbbbbbbbb4bbbb4444444444441c11c1c11c1c1111444444444444000000006555555556566655000000000000000000000000000000000000000000000000
4b4bbb4b4b44bb444444444444441111111111c11144444444444444000300006655555556555555000000000000000000000000000000000000000000000000
4444b44444444b44444444444444441111111111444444444444444430030bb05555666556555555000000000000000000000000000000004444444444444444
444444444444444444444444444444444444444444444444444444443303bb005556556655566655000000000000000000000000000000004ffffffffffffff4
444444444444444444444444444444444444444444444444444444440303b0005555555555655555000000000000000000000000000000004f5ffffffff5f5f4
44444444444444444444444444444444444444444444444444444444033b33005666655555555555000000000000000000000000000000004f5ff55ff5f5f5f4
44444444444444444444444444444444444444444444444444444444003b30006555555555556665000000000000000000000000000000004ff5ffff55fff5f4
00000000000000000000000000000000006545000065550006550000655555555555666555555555000000000000000000000000000000004ff5f55ff5f55ff4
00000000000000000000000000000000006555000065550006550000655555555555555566665555000000000000000000000000000000004ffffffffffffff4
00000000000000000000000000000000006555000064550006550000655555555555555555555565000000000000000000000000000000004444444444444444
00055500055500555500555000555000006555000065550006550000655555500066655000555655000000000000000000000000000000000440000000000440
00055500055500555500555000555000006555000065540006550000565660000000000000005655000000000000000000000000000000000440000000000440
00055555555555555555555555555000006455000065540006550000555600000000000000005655000000000000000000000000000000000440000000000440
00055555555555555555555555555000006455000065550006550000555600000000000000005565000000000000000000000000000000000440053635500440
00055555555555555555555555555000006555000065550006550000555000000000000000000555000000000000000000000000000000000445633635365440
00055555555655555655555555555000006555000065550006550000555000000000000000000655000000000000000000000000000000000436635335365540
0005555556655666565556565555500000655500006555000655000055500000000000000000065500000000000000000000000000000000053363e3ee365550
00055555555555555555655555555000006555000064550006550000555000000000000000000555000000000000000000000000000000000653eee3e33e6650
00055555655555555555555555555000006555000064550006550000560000000000000000000565000000000000000000000000000000006653eeeee3ee3656
000055555665556656665565555500000065550000645500065500006500000000000000000005560000000000000000000000000000000056633eeeeeeee333
0000055555556555555555655550000000655500006555000655000065000000000000000000005600000000000000000000000000000000555e3eeeeeeee655
0000005555555666565556555500000000655500006544000655000065000000000000000000005600000000000000000000000000000000666e3eeeeeeee555
0000000566655555556565555000000000654500006545000655000056500000000000000000056500000000000000000000000000000000335e3eeeeeeee565
0000000055556555555655550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000633eeeeeeeeee665
0000000056655565566556660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000563eeeeeeeeee555
0000000065555656555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556eeeeeeeeee533
0000000055555555655555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000655eeeeeeeeee336
0000000056556655566555660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000633eeeeeeeeee666
0000000055565555555565550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000335eeeeeeeeee555
0000000065655555555556660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666eeeeeeeeee566
0000000055556656666555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000566eeeeeeeeee566
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b1b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb3bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa0088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a880000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a808000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a800800080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a800080080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a800008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a000000a800000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa0088888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7c7cc77c7c7ccccc7cccc77cc77c7c7cccccc77cc77c7c7c777c7c7ccccccccc7c7cc77c7c7cccccc77c777c777ccccc777cccccc77c777c7c7c777cccccccc
c7c7c7c7c7c7ccccc7ccc7c7c7c7c7c7ccccc7ccc7c7c7c7cc7cc7c7ccccccccc7c7c7c7c7c7ccccc7ccc7ccc7ccccccc7c7ccccc7ccc7c7c7c7c7cccccccccc
c777c7c7c7c7ccccc7ccc7c7c7c7c77cccccc777c7c7c7c7cc7cc777ccccccccc777c7c7c7c7ccccc777c77cc77cccccc777ccccc7ccc777c7c7c77ccccccccc
ccc7c7c7c7c7ccccc7ccc7c7c7c7c7c7ccccccc7c7c7c7c7cc7cc7c7ccccccccccc7c7c7c7c7ccccccc7c7ccc7ccccccc7c7ccccc7ccc7c7c777c7cccccccccc
c777c77ccc77ccccc777c77cc77cc7c7ccccc77cc77ccc77cc7cc7c7cc7cccccc777c77ccc77ccccc77cc777c777ccccc7c7cccccc77c7c7cc7cc777cc7ccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7c7c777c77cc77cc777cccccc77c777c777c777c777c7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7c7cc7cc7c7c7c7c7c7ccccc7ccc7c7c7ccc7ccc7c7c7c7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c77ccc7cc7c7c7c7c777ccccc7ccc77cc77cc77cc777c777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7c7cc7cc7c7c7c7c7c7ccccc7ccc7c7c7ccc7ccc7ccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c7c7c777c7c7c777c7c7cccccc77c7c7c777c777c7ccc777cc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc777c777c777cc77cc77cccccc77ccc7c7c7ccccc777cc77c777c777c77cccccc777cc77ccccc777c77cc777c777c777ccccccccccccccccccccccccccc
cccccc7c7c7c7c7ccc7ccc7ccccccc7c7cc7cc7c7ccccc7c7c7ccc7c7cc7cc7c7cccccc7cc7c7ccccc7ccc7c7cc7cc7ccc7c7ccccccccccccccccccccccccccc
cccccc777c77cc77cc777c777ccccc7c7cc7ccc7cccccc777c7ccc777cc7cc7c7cccccc7cc7c7ccccc77cc7c7cc7cc77cc77cccccccccccccccccccccccccccc
cccccc7ccc7c7c7ccccc7ccc7ccccc7c7cc7cc7c7ccccc7c7c7c7c7c7cc7cc7c7cccccc7cc7c7ccccc7ccc7c7cc7cc7ccc7c7ccccccccccccccccccccccccccc
cccccc7ccc7c7c777c77cc77cccccc77cc7ccc7c7ccccc7c7c777c7c7c777c7c7cccccc7cc77cccccc777c7c7cc7cc777c7c7ccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc44444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4ffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4f555f555ff55f555ff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4f5fff5f5f5ffff5fff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4f55ff555f555ff5fff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4f5fff5f5fff5ff5fff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4f555f5f5f55fff5fff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc4ffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccc44444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc44cc536355cc44ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc44563363536544ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc43663533536554ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc53363030036555ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccc65300030330665ccccccccccccccccccccccccccccccccccccc444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccc
cccccccc6653000003003656cccccccccccccccccccccccccccccccccccc4ffffffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc5663300000000333cccccccccccccccccccccccccccccccccccc4ff55ff55f5f5f555f5f5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc5550300000000655cccccccccccccccccccccccccccccccccccc4f5fff5f5f5f5ff5ff5f5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc6660300000000555cccccccccccccccccccccccccccccccccccc4f555f5f5f5f5ff5ff555ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc3350300000000565cccccccccccccccccccccccccccccccccccc4fff5f5f5f5f5ff5ff5f5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc6330000000000665cccccccccccccccccccccccccccccccccccc4f55ff55fff55ff5ff5f5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc5630000000000555cccccccccccccccccccccccccccccccccccc4ffffffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccc5560000000000533cccccccccccccccccccccccccccccccccccc444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccc
cccccccc6550000000000336ccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc6330000000000666ccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc3350000000000555ccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc6660000000000566ccccccccccccccccccccccccccccccccccccccccc44cc536355cc44ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc5660000000000566ccccccccccccccccccccccccccccccccccccccccc44563363536544ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbccccccccbbbbbbbbccccccccccccccccc43663533536554ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccbbbbbbbbbbb4bbbbbbbbbbbbccccccccbbbbbbbbccccccccccccccccc53363030036555ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc4b4bbb4b4b44bb444b4bbb4bcccccccc4b4bbb4bccccccccccccccccc65300030330bb5ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc4444b44444444b444444b444cccccccc4444b444cccccccccccccccc66530000077bbbb6cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc444444444444444444444444cccccccc44444444cccccccccccccccc56633000071bbb73cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc444444444444444444444444cccccccc44444444cccccccccccccccc55503000bbbbb755cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc444444444444444444444444cccccccc44444444cccccccccccccccc6660300bbbbb7755cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc444444444444444444444444cccccccc44444444cccccccccccccccc335030bbbbbb7565cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc44444444bbbbbbbbcccccccc6330bbbbbbbb7665cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc44444444bbbbbbbbcccccccc563bbbbbbbb77555cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444b4bbb4bcccccccc556bbbbbbb370533cccccccccccccc44444444444444444444cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444444b444cccccccc65b333bbb3370336cccccccccccccc4ffffffffffffffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444cccccccc6333333b73300666cccccccccccccc4fffff5f5f555ffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444cccccccc3333333377330555cccccccccccccc4fffff5f5f5f5ffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444cccccccc3333333300333566cccccccccccccc4fffff5f5f555ffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444cccccccc5333333330033366cccccccccccccc4fffff5f5f5ffffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc4ffffff55f5ffffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccc4ffffffffffffffffff4cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc44444444444444444b4bbb4b4b4bbb4b4b4bbb4b4b4bbb4bcccccc44444444444444444444cccccccccccccc
cccccccccccccccccccccccccccccccccccccccc44444444444444444444b4444444b4444444b4444444b444ccccccccc44cccccccccc44ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444ccccccccc44cccccccccc44ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444ccccccccc44cccccccccc44ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444ccccccccc44cc536355cc44ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc444444444444444444444444444444444444444444444444ccccccccc44563363536544ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc5ccccccccccc5cccccccccccccccccccccccccccccccccccc43663533536554ccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc5555cccccccccc5cccccccccccccccccccccccccccccccccccc53363030036555ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccce51755ccccccccc5cccccccccccccccccccccccccccccccccccc65300030330665ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc555555cccccccc55ccccccccccccccccccccccccccccccccccc6653000003003656cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc55555cccccccc5cccccccccccccccccccccccccccccccccccc5663300000000333cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc55555ccccccc5cccccccccccccccccccccccccccccccccccc5550300000000655cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc5555555555555cccccccccccccccccccccccccccccccccccc6660300000000555cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc5555555555555cccccccccccccccccccccccccccccccccccc3350300000000565cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6555555555665cccccccccccccccccccccccccccccccccccc6330000000000665cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6655555556666cccccccccccccccccccccccccccccccccccc5630000000000555cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6655555556666cccccccccccccccccccccccccccccccccccc5560000000000533cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc66c555555c666cccccccccccccccccccccccccccccccccccc6550000000000336cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6ccccccccc666cccccccccccccccccccccccccccccccccccc6330000000000666cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6ccccccccc66ccccccccccccccccccccccccccccccccccccc3350000000000555cccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc6ccccccccc66ccccccccccccccccccccccccccccccccccccc6660000000000566cccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc77cccccccc77cccccccccccccccccccccccccccccccccccccc5660000000000566cccccccccccccccc
ccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ccccccccccccccccccccccccbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbb4bbbbbbbbbbbbbbb4bbbbbbbbbbbbbbb4bbbbbbb4bbbb
cccccccccccccccccccccccc4b44bb444b44bb444b44bb444b44bb444b44bb444b44bb444b44bb444b44bb444b4bbb4b4b44bb444b4bbb4b4b44bb444b44bb44
cccccccccccccccccccccccc44444b4444444b4444444b4444444b4444444b4444444b4444444b4444444b444444b44444444b444444b44444444b4444444b44
cccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
ccccccccccccccccbbbbbbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
ccccccccccccccccbbb4bbbb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc4b44bb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc44444b4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccccccccccc4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
ccccccccbbbbbbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
ccccccccbbb4bbbb4444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc4b44bb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc44444b444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
cccccccc444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
bbbbbbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
bbb4bbbb444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
4b44bb44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444b44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444

__gff__
00000000000000000000000100010001000000001000100010002001310111010001000000000000000000000000000000011000f000f000f0000000f000f00000000000000000000000000000000000100020002000100010000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010303030004010100000000080804040404040404010101000000000808040404040404040100010000000008080404040400000000000000000000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000008e8f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000009e9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000081aeaf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000082bebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000828181000000000000000000000000000000000000000000000000000000000090919293000000000090919293000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000008282000000000000000000000000000000000000000000000000000000000000a0a1a2a30000000000a0a1a2a3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000828e8f0000000000000000000000000000000000000000000000000000000000b0b1b2b30000000000b0b1b2b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000808180008000000000000000000000000000000000829e9f000000000000000000000000000000000000000000000000000000000000a1b2b1a1a1a1b1a2b1a1a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000828000000000000000000000000000000082aeaf00000000000000000000000000000000000000008e8f0000000000000000b1b1a1b2b1b2b2a1a2a2b100000000888889888988888988888889888889880000000000000000000000000000000000000000000000000000000000000000
000000000081808181810000000000828280808080000000000000000000000082bebf0000000000000000008e8f0000000000000000009e9f0000000000000000a1a294959495949495a1a200000000889798989898989898989899888988880000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000008282810000000000000000009e9f000000000000000000aeaf0000000000000000a1a2a4a59594959495a1a200000000970000000000000000000000989899890000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000828282810000000000000000aeaf0000008e8f00000000bebf0087008e8f000000a2b2a4a4a5a4a5a4a5b1b200000000a78e8f0000000000000000008e8f00990000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000081818181818181818081808181818100000000828282828100000000000000bebf0081009e9f0000008080808080009e9f000000a1b2949594959495a5a2b100000000a79e9f0000000000000000009e9f00a90000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000081828282828282828282828282828282000000008282828282828283848582828282808200aeaf000000000000000000aeaf000000a1b19495a4a5a4a595a1a200000000a7aeaf000000000000000000aeaf00a90000000000000000000000000000000000000000000000000000000000000000
00000000000000000000008182828282828282828282828282828282000000008282828282828282828282828282828200bebf000000008787870000bebf000000a1b2a4a5a4a5a4a4a5b1b200000000a7bebf000000000000000000bebf00a90000000000000000000000000000000000000000000000000000000000000000
8081808180818080808181828282828282828282828282828282828200000000828282828282828282828282828282828081808081808081808180808081808081818180808080808080808080818180888888888888888888888888888888880000000000000000000000000000000000000000000000000000000000000000
8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000127500c7500975008750077500775008750097500e75014750197502375025700237002b7002a70030500305002f5002f5002f5002e5002c5002b5002550006700087000870000500005000050000500
000000000c1700c1700b1700a17009170081700817006170051700117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400003c5533c5533c5533b5533955336553335532d5532e5533055332553325532f5532a5532355321553215532355325553265532555323553225531e5531b553185530f5530455301553005030050300503
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000
00 00000000

