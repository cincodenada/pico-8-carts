pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- frogs vs. cats v1.1.2
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
		"people who actually\ndidn't test much, really",
	},
	extra_roles = {
		{"emotional support","myka dubay","anna barton"},
		{"inspiration and reference code","finn aka @relsqui"},
		{"beta testers","friendly ludum dare participants"},
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
			mapid = 5,
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
			mapid = 5,
			bg = 0,
			short = "a dark, narrow tunnel",
			intro = "you seem to have emerged in some sort of dungeon! judging by the feline-themed decor, you guess you are underneath the catsle that you approached earlier",
			links = {
				tunnel=8
			},
			items = {
				{"locked chest",93,15,2,1,"you see a big oak chest. it seems pretty immune to brute force. there are holes in the side, but not large enough to see anything.",96},
			},
		},
		{
			id = 8,
			mapid = 5,
			bg = 0,
			short = "an ample tunnel",
			intro = "you're in a dark subterranean room lit dimly by torches, somehow still alight.",
			links = {
				tunnel = 7,
				grate = 5,
			},
			items = {
				{"an old scroll",87,15,3,1,"it seems to be blank. could the developer have run out of time to do anything with it?"},
			},
		},
		{
			id = 9,
			mapid = 6,
			intro = "\n\n\
⬅️➡️: hop around\
 ⬆️ : jump up onto platforms\
❎/z: inspect your location\
use doors to enter commands",
			-- for the label image, also shift right by 1px
			--intro="\n\n\n  a text-adventure platformer\n   created for ludum dare 41",
			links = {
				start = 1,
			},
			door_msg = {
				start = "\n\n",
			}
		}
	},
	maps = {
		-- all coords in blocks!
		{
			x=12,y=0,w=31,
			px=12,py=15,
			cats = {{37,11}},
			text_offset = 0,
		},
		{
			x=44,y=0,w=16,
			px=45,py=10,
			cats = {{51,13}},
			text_offset = 4,
		},
		-- boring base map
		{
			x=60,y=0,w=16,
			px=64,py=15,
			cats={{73,15},{67,12}},
			text_offset = 0,
		},
		-- catsle
		{
			x=76,y=0,w=16,
			px=86,py=15,
			cats = {
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
				{76 + flr(rnd(13)),flr(rnd(20))},
			},
			doors={{90,15}},
			text_offset = 0,
		},
		-- cave
		{
			x=92,y=0,w=16,
			px=100,py=15,
			text_offset = 0,
		},
		-- intro screen
		{
			x=0,y=0,w=16,
			px=0,py=15,
			text_offset = 1,
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
	sounds = {
		-- for silly hop sounds
		--hop = {0,3,4,5,6,7,8,9},
		hop = 0,
		leap = 10,
		bump = 1,
		die = 2,
		door = 11,
		nope = 12,
		creak = 13,
		win = 14,
		get = 15,
		tinyhop = 16,
	}
}
function game:reset()
	self.player = player(0,120)
	self:load_area(9)
end
function game:save_camera() add(self.cameras, peek4(0x5f28)) camera() end
function game:load_camera() poke4(0x5f28, self.cameras[#self.cameras]) self.cameras[#self.cameras] = nil end
function game:xmin() return self.cur_map.x*8 end
function game:xmax() return self.cur_map.x*8+self.cur_map.w*8-1 end
function game:play_sound(which)
	local sound = self.sounds[which]
	if(type(sound) == "table") then
		local idx = flr(rnd(#sound))+1
		sound = sound[idx]
	end
	sfx(sound)
end
-- this should probably be its own object
-- but we're in crunch time
function game:load_area(id, from_door, player_pos)
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
	if(not self.cur_map.doors) self.cur_map.doors = {}
	for d in all(game:find_doors()) do
		add(self.cur_map.doors, d)
	end
	local dooridx = 1 -- todo: randomize
	local player_door = nil
	for label,info in pairs(a.links) do
		self:add_door(label, info, dooridx)
		if(label == from_door) player_door = self.doors[dooridx]
		dooridx += 1
	end

	self:load_items()

	if(player_pos) then
		game.player.x = player_pos.x
		game.player.y = player_pos.y
	else
		if(player_door) then
			game.player.x = player_door.x
			game.player.y = player_door.y
		else
			game.player.x = m.px*8
			game.player.y = m.py*8
		end
	end
	
	self.x = m.x*8
	self.to_scoot = 0
	-- insta-scoot at beginning of the level
	self:insta_scoot()

	if(self.cur_area.id == 1 and not self.has_started) then
		-- override area text for first play
		self.texts ={{msg="you wake up in a bright field. you attempt to walk forward, but find that you feel a little...hoppy.\nahead, you see\nmovement in the\ndistance.",x=self.x}}
		self.has_started = true
	else
		local text = {msg=a.intro, col=7, x=self.x}
		if(m.text_offset) then
			text.x += m.text_offset*8
			text.w = 127-m.text_offset*8
		end
		self.texts = {text}
	end
end
function game:insta_scoot()
	local scoot = game.player:needs_scoot()
	if(scoot) then
		if(scoot > 0) then
			self.x = min(8*(self.cur_map.x+self.cur_map.w), game.player.x - 16*8 + game.player.w*1.5)
		else
			self.x = max(self.cur_map.x*8, game.player.x - game.player.w*0.5)
		end
	end
end
function game:find_doors()
	doors = {}
	for x=self.cur_map.x,self.cur_map.x+self.cur_map.w-1 do
		for y=self.cur_map.y,self.cur_map.y+15 do
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
		if(info[7]) then
			i.sprite = sprite(i.w/8, i.h/8, {info[7]})
		end
	end
end
function game:add_door(label,di,idx)
		local dc = self.cur_map.doors[idx]
		add(self.doors, door(dc[1]*8,dc[2]*8,label,di))
end
function game:show_message(msg, duration, bg)
	-- don't add duplicate texts
	for t in all(self.texts) do
		if(t.msg == msg) return
	end

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
	self.texts = {}
	local doormsg = ""
	if(self.cur_area.door_msg and self.cur_area.door_msg[d.label]) then
		doormsg = self.cur_area.door_msg[d.label]
	else
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
		doormsg = "you look "..where..". you see "..d.text
	end
	if(doormsg != "") add(self.texts, {msg=doormsg, col=7, x=self.x})

	if(d.label != "up") then
		-- todo: properly conditionalize this
		add(self.texts,{msg="press ❎/z again to enter", col=7, x=self.x+5})
	end
end
function game:enter_door(d)
	if(d.label == "grate" and not d.unlocked and self.cur_area.id==5) then
		if(not d.swept) then
			game:show_message("the grate doesn't budge. you sweep away some debris and spy a keyhole that seems promising.")
			d:sweep()
		end
		if(self.player:has_item("silver key")) then
			game:show_message("you try the silver key in the grate. it opens with a loud creak. there's an old musty culvert behind it that's plenty wide for a frog to fit through.")
			self:play_sound("creak")
			d:unlock()
		else
			if(self.player:has_item("blue key")) game:show_message("you try the blue key, but the lock doesn't budge",5)
			if(self.player:has_item("green key")) game:show_message("you try your green key, but it doesn't even fit",5)
			self:play_sound("nope")
		end
		return
	end
	if(d.link.area) then
		local ld = d.link.door
		-- if not n/s/e/w, they should be matching pairs
		if(not ld) ld=d.label
		self:play_sound("door")
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
	if(self.cur_area.id == 9) then
		-- title screen
		pal(7,10)
		spr(192,8*1.5,-2,13,2)
		pal(7,1)
	end
	self:draw_texts(bg)
	pal(7,7)
	self.player:draw()
	for c in all(self.cats) do c:draw() end
	for i in all(self.items) do i:draw() end
	if(self.debug!="") game:draw_debug()

end
function game:draw_texts(bg)
	cury = 1
	local did_timeout = false
	local to_remove = {}
	for idx,t in pairs(self.texts) do
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

			if(t.duration and not did_timeout) then
				t.duration -= 1
				did_timeout = true
			end
		else
			if(t.duration) add(to_remove, idx)
		end
	end
	for idx in all(to_remove) do
		self.texts[idx] = nil
	end
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
		dist = self:xmax() - self.x
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
		if(i:intersects(self.player) and not self.player:has_item(i.name)) return i
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
	if(self.sprite) self.sprite:draw(self.x, self.y)
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
	self.unlocked = false
	self.swept = false
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
function door:sweep()
	self.swept = true
end
function door:unlock()
	self.unlocked = true
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

	-- if(self.collided) game:play_sound("bump")
end

tinyfriend = class(entity)
function tinyfriend:constructor(x,y)
	super(tinyfriend, self,
		x, y, sprite(1, 1, 224))
	self:animate(true)
end
function tinyfriend:update()
	super(tinyfriend).update(self)
	if(not self:is_floating()) then
		self.cur_move = {vy=-2,vx=0,dy=10}
		game:play_sound("tinyhop")
	end
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
	if(self.leaping_up) then
		game:play_sound("leap")
	else
		game:play_sound("hop")
	end
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
			if(self.leaping_up) then
				game:play_sound("leap")
			else
				game:play_sound("hop")
			end
			self.next_jump = false
			self.sprite:set_frame(4)
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
		game:play_sound("die")
	-- only start player at the very beginning the first time
		game:reset(200)
		return
	end

	local scoot = self:needs_scoot()
	if(scoot) game:scoot(self.w*scoot)
end
function player:needs_scoot()
	if(self.x > game.x + 128-self.w) then
		return 1
	elseif(self.x < game.x+self.w) then
		return -1
	end
	return false
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
		game:show_message(item.message, 10)
		if(item.name == "locked chest") then
			if(self:has_item("blue key")) then
				if(self:has_item("green key")) game:show_message("you try your green key, but the chest is unyielding",5)
				game:show_message("you try the blue key and it unlocks the chest! inside is a very sad small frog! you're a hero!")
				add(game.cats, tinyfriend(self.x+self.w, self.y-8))
				game:play_sound("win")
				credits.countdown = 10*30
			else
				if(self:has_item("green key")) game:show_message("you try your green key, but the chest is unyielding",5)
				game:play_sound("nope")
				game:show_message("it's pretty locked.",5)
			end
		else
			game:show_message("you found a "..item.name.."!", 5)
			add(self.items, item)
			game:play_sound("get")
		end
	end
	if(not found_something) then
		game:show_message("there doesn't seem to be anything here.", 3, true)
		game:play_sound("nope")
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
00444444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444499994444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5555559aa95555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999999999999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49444444444444940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49444444444444940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49999999999999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb444444444411c1111c1111111111144444444444000000005555555555565555555655550000000000000000000000000000000000000000
bbbbbbbbbbb4bbbb4444444444441c11c1c11c1c1111444444444444000000006555555556566655566556660000000000000000000000000000000000000000
4b4bbb4b4b44bb444444444444441111111111c11144444444444444000300006655555556555555555555550000000000000000000000000000000000000000
4444b44444444b44444444444444441111111111444444444444444430030bb05555666556555555655555550000000000000000000000004444444444444444
444444444444444444444444444444444444444444444444444444443303bb005556556655566655566555660000000000000000000000004ffffffffffffff4
444444444444444444444444444444444444444444444444444444440303b0005555555555655555555560700000000000000000000000004f5ffffffff5f5f4
44444444444444444444444444444444444444444444444444444444033b33005666655555555555555556660000000000000000000000004f5ff55ff5f5f5f4
44444444444444444444444444444444444444444444444444444444003b30006555555555556665666555550000000000000000000000004ff5ffff55fff5f4
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
00777777700000000000000000000000000000000000000000000000000000000000000077777000000000000000000000000000000000000000000000000000
00777000000000000000000000000000000000000000000000000000000000000000000770000700000000000000000000000000000000000000000000000000
00777000007777770000077770000077777000777770000077700070077777000000007770000000777770077777770077777000000000000000000000000000
00777777007770007000770007000770000707700007000077700070770000700000007770000007770007000777000770000700000000000000000000000000
00777000007770007007770000707770000007700000000077700070770000000000007770000007770007000777000770000000000000000000000000000000
00777000007777770007770000707770007700777000000077700070077700000000007770000007777777000777000077700000000000000000000000000000
00777000007770007007770000707770000700077700000077700070007770000000007770000007770007000777000007770000000000000000000000000000
00777000007770000707770000707770000700007770000077700700000777000000007770000007770007000777000000777000000000000000000000000000
00777000007770000707770000707770000700000077000077707000000007700000007770000007770007000777000000007700000000000000000000000000
00777000007770000700770007000770000707000077000077770000700007707700000770000707770007000777000700007700000000000000000000000000
00777000007770000700077770000077777000777770000077700000077777007700000077777007770007000777000077777000000000000000000000000000
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
ccccccccccccccaaaaaaacccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaaaaccccccccccccccccccccccccccccccccccccccc
ccccccccccccccaaaccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccaaccccacccccccccccccccccccccccccccccccccccccc
ccccccccccccccaaacccccaaaaaacccccaaaacccccaaaaacccaaaaacccccaaacccaccaaaaaccccccccaaacccccccaaaaaccaaaaaaaccaaaaaccccccccccccccc
ccccccccccccccaaaaaaccaaacccacccaacccacccaaccccacaaccccaccccaaacccacaaccccacccccccaaaccccccaaacccacccaaacccaaccccacccccccccccccc
ccccccccccccccaaacccccaaacccaccaaaccccacaaaccccccaacccccccccaaacccacaaccccccccccccaaaccccccaaacccacccaaacccaaccccccccccccccccccc
ccccccccccccccaaacccccaaaaaacccaaaccccacaaacccaaccaaacccccccaaacccaccaaaccccccccccaaaccccccaaaaaaacccaaaccccaaaccccccccccccccccc
ccccccccccccccaaacccccaaacccaccaaaccccacaaaccccacccaaaccccccaaacccacccaaacccccccccaaaccccccaaacccacccaaacccccaaacccccccccccccccc
ccccccccccccccaaacccccaaaccccacaaaccccacaaaccccaccccaaacccccaaaccacccccaaaccccccccaaaccccccaaacccacccaaaccccccaaaccccccccccccccc
ccccccccccccccaaacccccaaaccccacaaaccccacaaaccccaccccccaaccccaaacaccccccccaacccccccaaaccccccaaacccacccaaaccccccccaacccccccccccccc
ccccccccccccccaaacccccaaaccccaccaacccacccaaccccacaccccaaccccaaaaccccaccccaacaacccccaaccccacaaacccacccaaacccaccccaacccccccccccccc
ccccccccccccccaaacccccaaaccccacccaaaacccccaaaaacccaaaaacccccaaaccccccaaaaaccaaccccccaaaaaccaaacccacccaaaccccaaaaaccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccc111ccccc111c111c1c1c111ccccc111c11cc1c1c111c11cc111c1c1c111c111ccccc111c1ccc111c111c111cc11c111c111c111c111ccccccccccc
cccccccccc1c1cccccc1cc1ccc1c1cc1cccccc1c1c1c1c1c1c1ccc1c1cc1cc1c1c1c1c1ccccccc1c1c1ccc1c1cc1cc1ccc1c1c1c1c111c1ccc1c1ccccccccccc
cccccccccc111cccccc1cc11ccc1ccc1cc111c111c1c1c1c1c11cc1c1cc1cc1c1c11cc11cccccc111c1ccc111cc1cc11cc1c1c11cc1c1c11cc11cccccccccccc
cccccccccc1c1cccccc1cc1ccc1c1cc1cccccc1c1c1c1c111c1ccc1c1cc1cc1c1c1c1c1ccccccc1ccc1ccc1c1cc1cc1ccc1c1c1c1c1c1c1ccc1c1ccccccccccc
cccccccccc1c1cccccc1cc111c1c1cc1cccccc1c1c111cc1cc111c1c1cc1ccc11c1c1c111ccccc1ccc111c1c1cc1cc1ccc11cc1c1c1c1c111c1c1ccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc11c111c111c111c111c111c11cccccc111cc11c111ccccc1ccc1c1c11cc1c1c111ccccc11cc111c111c111ccccc1c1c11cccccccccccccccc
cccccccccccccc1ccc1c1c1ccc1c1cc1cc1ccc1c1ccccc1ccc1c1c1c1ccccc1ccc1c1c1c1c1c1c111ccccc1c1c1c1c1c1c1ccccccc1c1cc1cccccccccccccccc
cccccccccccccc1ccc11cc11cc111cc1cc11cc1c1ccccc11cc1c1c11cccccc1ccc1c1c1c1c1c1c1c1ccccc1c1c111c11cc11cccccc111cc1cccccccccccccccc
cccccccccccccc1ccc1c1c1ccc1c1cc1cc1ccc1c1ccccc1ccc1c1c1c1ccccc1ccc1c1c1c1c1c1c1c1ccccc1c1c1c1c1c1c1ccccccccc1cc1cccccccccccccccc
ccccccccccccccc11c1c1c111c1c1cc1cc111c111ccccc1ccc11cc1c1ccccc111cc11c111cc11c1c1ccccc111c1c1c1c1c111ccccccc1c111ccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ffffffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4fff55f555f555f555f555f4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ff5ffff5ff5f5f5f5ff5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ff555ff5ff555f55fff5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ffff5ff5ff5f5f5f5ff5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ff55fff5ff5f5f5f5ff5ff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc4ffffffffffffffffffffff4cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44cccccccccc44ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44cc536355cc44ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc44563363536544ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc43663533536554ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc53363030036555ccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc65300030330665ccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6653000003003656cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5663300000000333cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5550300000000655cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6660300000000555cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3350300000000565cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6330000000000665cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5630000000000555cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5560000000000533cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6550000000000336cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6330000000000666cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc3350000000000555cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6660000000000566cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5660000000000566cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbb4bbbbcccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4b4bbb4b4b4bbb4b4b4bbb4b4b44bb44cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc4444b4444444b4444444b44444444b44cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccc44444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccbbbb77ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccc7bbb17ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc7bbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc77bbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc7bbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc7bbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc77bbbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc73bbbbbbbccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc733bbb333bcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc337b333333ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc337733333333cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc333cc33333333cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc333cc33333333ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccbbbbbbbbbbb4bbbbbbbbbbbbbbb4bbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4b4bbb4b4b44bb444b4bbb4b4b44bb444b4bbb4bcccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444b44444444b444444b44444444b444444b444cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc4444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccbbbbbbbb4444444444444444444444444444444444444444bbbbbbbbcccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccbbb4bbbb4444444444444444444444444444444444444444bbbbbbbbcccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc4b44bb4444444444444444444444444444444444444444444b4bbb4bcccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc44444b4444444444444444444444444444444444444444444444b444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccc44444444444444444444444444444444444444444444444444444444cccccccccccccccccccccccccccccccccccccccc
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb44444444444444444444444444444444444444444444444444444444bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb4bbbbbbbbbbbb44444444444444444444444444444444444444444444444444444444bbb4bbbbbbbbbbbbbbb4bbbbbbbbbbbbbbb4bbbb
4b4bbb4b4b4bbb4b4b44bb444b4bbb4b444444444444444444444444444444444444444444444444444444444b44bb444b4bbb4b4b44bb444b4bbb4b4b44bb44
4444b4444444b44444444b444444b4444444444444444444444444444444444444444444444444444444444444444b444444b44444444b444444b44444444b44
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444

__gff__
00000000000000000000000100010001000000001000100010002001310111010001000000000000000000000000000000011000f000f000f0000000f000f00000000000000000000000000000000000100020002000100010000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010303030004010104000000080804040404040404010101000000000808040404040404040100010000000008080404040400000000000000000000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008e8f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009e9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081aeaf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000008e8f00000000000000000000000000000000000082bebf000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000009e9f000000000000000000000000000000000000828181000000000000000000000000000000000000000000000000000000000090919293000000000090919293000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000008e8f00000000aeaf000000008e8f0000000000000000000000008282000000000000000000000000000000000000000000000000000000000000a0a1a2a30000000000a0a1a2a3000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008e8f00000000000000009e9f00000000bebf000000009e9f000000000000000000000000828e8f0000000000000000000000000000000000000000000000000000000000b0b1b2b30000000000b0b1b2b3000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000009e9f0000000000000000aeaf00000080818000800000aeaf000000000000000000000000829e9f000000000000000000000000000000000000000000000000000000000000a1b2b1a1a1a1b1a2b1a1a200000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000aeaf0000000000000000bebf00000000000000828000bebf00008e8f000000000000000082aeaf00000000000000000000000000000000000000008e8f0000000000000000b1b1a1b2b1b2b2a1a2a2b100000000888889888988888988888889888889880000000000000000000000000000000000000000
0000000000000000bebf0000000000000081808181810000000000828280808080009e9f000000000000000082bebf0000000000000000008e8f0000000000000000009e9f0000000000000000a1a294959495949495a1a200000000889798989898989898989899888988880000000000000000000000000000000000000000
00000000000000808080810000000000000000000000000000000000000000000000aeaf00000000000000008282810000000000000000009e9f000000000000000000aeaf0000000000000000a1a2a4a59594959495a1a200000000970000000000000000000000989899890000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000bebf0000000000000000828282810000000000000000aeaf0000008e8f00000000bebf0087008e8f000000a2b2a4a4a5a4a5a4a5b1b200000000a78e8f0000000000000000008e8f00990000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000081818181818181818081808181818100000000828282828100000000000000bebf0081009e9f0000008080808080009e9f000000a1b2949594959495a5a2b100000000a79e9f0000000000000000009e9f00a90000000000000000000000000000000000000000
00000000008081808180000000000000000000000000000081828282828282828282828282828282000000008282828282828283848582828282808200aeaf000000000000000000aeaf0000008a899495a4a5a4a595a1a200000000a7aeaf000000000000000000aeaf00a90000000000000000000000000000000000000000
00000000818282828282800000000000000000000000008182828282828282828282828282828282000000008282828282828282828282828282828200bebf000000008787870000bebf000000a1b2a4a5a4a5a4a4a5b1b200000000a7bebf000000000000000000bebf00a90000000000000000000000000000000000000000
8080818082828282828282818081808180818080808181828282828282828282828282828282828200000000828282828282828282828282828282828081808081808081808180808081808081818180808080808080808080818180888888888888888888888888888888880000000000000000000000000000000000000000
8080000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000127500c7500975008750077500775008750097500e75014750197502375025700237002b7002a70030500305002f5002f5002f5002e5002c5002b5002550006700087000870000500005000050000500
000000000c1700c1700b1700a17009170081700817006170051700117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000145533c5533c5533b5533955336553335532d5532e5533055332553325532f5532a5532355321553215532355325553265532555323553225531e5531b553185530f5530455301553005030050300503
0000000014050140501405013050110500d0500c0500c050110501904020030240302403024020250202602026020260202603000000000000000000000000000000000000000000000000000000000000000000
000000002b7502a1502a15028150231501c150151500f1500d1500a1500a1500b1500f15015150171501715016150151501715018150181500010000100001000010000100001000010000100001000000000000
00000000093500935009350093500a3500d35011350163501d3502c35033350003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0000000021550215502155022550215502055020550205501f5501e5501b5501955015550135501a5501d55022550275502a55000500005000050000500005000050000500005000050000500005000050000500
000000002775027750227501f7501f7501c7501975016750107500c7500c7500d7500f75015750197501b7501c7501c750167500a750007000070000700007000070000700007000070000700007000070000700
000000001d1501f1501f1502015020150211502115021150211501f1501c1501a1501715011150111501315014150141501515016150171501d15028150001000010000100001000010000100001000010000100
00000000277502875028750287502775025750207501e750147500e7500a750067500775007750087500d75019750247503175000700007000070000700007000070000700007000070000700007000070000700
000000000f7500e7500c7500b7500a7500a750097500a7500a7500a7500a7500a75009750097500975009750097500a7500b750107501175014750187501c7502175023750267502775028750007000070000700
01040000200331d0331903317033150331403314033140331403315033180331c03320033220332303324033240331d00321003250032600325003220031f0031c003190031700317003180031a0031e00323003
010100000b4520b4520b4520b4520040200402004020040200402004020a4520a4520a4520a4520a4520040200402004020040200402004020040200402004020040200402004020040200402004020040200402
010300003815538155301552f15530155301550e105091051310511105101050f1050f1050f105101051410500105001050010500105001050010500105001050010500105001050010500105001050010500105
00050000187521875218752187521675216752177521b7521d7521e7521f7521f7521f7521f7521f7521d7521e752217522275224752247522475224752247522475224752247522475224752247522033200702
000000001c3501c3501c3501d3501d3501e3501f350203502235024350263502a3502d3502d350003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010100001e521185211552114521135211352114521155211a52120521255212f52125501235012b5012a50130501305012f5012f5012f5012e5012c5012b5012550106501085010850100501005010050100501
01030000115510f5510d5510d5510d5511055112551165511a5511f55118501005010050100001000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

