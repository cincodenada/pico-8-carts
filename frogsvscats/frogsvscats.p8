pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
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

-- position is 1px below lower-left corner of sprite ("on the ground")
sprite = class()
function sprite:constructor(w, h, frames, offset)
	self.w, self.h, self.frames, self.offset = w, h, frames, offset
	self.cur_frame = 0
	self.facing = 1
end
function sprite:draw(x, y)
	local flipped = (self.facing==-1)
	local f = flr(self.cur_frame)+1
	spr(self.frames[f], x-self:adj(f), y-self.h*8, self.w, self.h, flipped)
end
function sprite:move_frame(howmany)
	self.cur_frame += howmany
	self.cur_frame %= #self.frames
end
function sprite:adj(n)
	if(self.offset[n]) return self.offset[n]
	return 0
end

entity = class()
function entity:constructor(x, y, sprite)
	self.x, self.y, self.sprite = x, y, sprite
end
function entity:draw()
	self.sprite:draw(self.x, self.y)
end

frog = class(entity)
function frog:constructor(x,y)
	getmetatable(frog).constructor(self, x, y,
		sprite(2, 2,
			{0,2,4,6,8,10,12,14,32,34,36,38,40,42,44,42,44},
			{0,0,0,0,1,1,2,1,0,1,-1,-1,-1,0,-1,0}
		)
	)
end

player = class(frog)
function player:constructor(...)
	getmetatable(player).constructor(self, ...)
end
function player:update()
	if(btnp(0)) self:jump(-1)
	if(btnp(1)) self:jump(1)

	if(self.jumping) then
		self.sprite:move_frame(0.5)
		if(self.sprite.cur_frame >=5 and self.sprite.cur_frame <=8) self.x += 1
		if(self.sprite.cur_frame == 0) self.jumping = false
	end
end
function player:jump(dir)
	if(self.jumping) return
	self.sprite.facing = dir
	self.jumping = true
end

local game = {}
function game:reset()
	self.player = player(0,120)
end
function game:update()
	self.player:update()
end
function game:draw()
	self.player:draw()
end

function _init()
	game:reset()
end

function _update()
	game:update()
end

function _draw()
	cls()
	game:draw()
end

__gfx__
000000000000000000000000000000000000000000000bb000000000000000000000000000077bb0000000000000770000000000000077000000000000000000
0000000000000000000000000000bb00000000000077bbbb0000000000077bb00000000000771bbb00000000007771b000000000007771b00000bbb000007700
000000000000bb0000000000077bbbb0000000000071bbb70000000000071bbb0000000000bbbb77000000000071bbbb00bbbbbbbb71bbbb00bbbbbb007771b0
00000000077bbbb000000000071bbb70000000000bbbbb700000000000bbbbb700000000bbbbb77000000bbbbbbbbbbb0b33bbbbbbbbbbbb0b33bbbbbb71bbbb
00000000071bbb7000000000bbbbb70000000000bbbbb77000000000bbbbbb77000000bbbbbb7700000bbbbbbbbb777003333bbbbbbb777003333bbbbbbbbbbb
00000000bbbbb7000000000bbbbb77000000000bbbbbb700000000bbbbbbb7000000bbbbbbbb700000b33bbbbbb7700033333bbbbb77700003333bbbbbbb7770
0000000bbbbb7700000000bbbbbb7000000000bbbbbbb70000000bbbbbbbb700000b33bbbbbb7000003333bbbbb7000033333b777370000033333b77bb777000
000000bbbbbb700000000bbbbbbb70000000bbbbbbbb70000000bbbbbbbb700000b3333bbb777000033333bb7377000033333777733000003333377773700000
0000bbbbbbbb70000000bbbbbbb70000000bbbbbbbb37000000bbbbbbbbb70000033333bbb770000033333b77337000033330007733000003333000773300000
000bbbbbbbb70000000bbbbbbb370000000bbbbbbbb3700000bbb333bb7370000333333b7370000033333b777330000033300000330000003330000073300000
000bbbbbbb370000000bbbbbbb37000000b3333bbb73300000b33333b7733000333333b773300000333300000330000033000000330000003300000033000000
00b333bbb337000000b333bbb73300000333333bb773300003333333777330003333000003300000333000000330000033000000330000003300000033000000
0333333b733000000333333b77330000333333337700330033333000000333003330000000330000333000000030000033300000330000003330000033000000
33333333773300003333333370030000333333000000330033300000000033000333000000330000033300000033000003300000300000000333000033000000
33333333000330003333333300033000033333300000330003333330000033000033300000030000003300000000000003300000000000000033000030000000
03333333300333000333333330033300033333330000033000333333000003000003330000000000003330000000000000300000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbbb000077000000bb0000000000000000000007700000000000077bb00000000000077000000000000000770000000000000077000000000000000bb00
00333bbbbb07771b000bbbbbb00007700000bbbb007771b0000000007771bbb0000000007771bb000000000000771bb00000000000771b0000000000077bbbb0
003333bbbbb71bbb00033bbbbb07771b00bbbbbbbb71bbbb0000000071bbb7700000000071bbbbb0000000000071bbbb00000000bbbbbbbb00000000071bbb70
033333bbbbbbbbbb003333bbbbb71bbb0b33bbbbbbbbbbbb000bbbbbbbbb770000000bbbbbbbb770000000bbbbbbbb770000000bbbbbbb7700000000bbbbb700
333333bbbbbbb770003333bbbbbbbbbb03333bbbbbbbbb7000b33bbbbbb77000000bbbbbbbbb770000000bbbbbbbb770000000bbbbbbb7700000000bbbbb7700
33333b777bb77700033333bbbbbbb77003333bbbbbbb77700b3333bbbbb7000000b33bbbbbb770000000bbbbbbbb77000000bbbbbbbb7700000000bbbbbb7000
3330000777370000033333777bbb7700333333bbbbb77700033333bbbb7700000b3333bbbbb77000000bbbbbbbbb7000000bbbbbbbbb70000000bbbbbbbb7000
330000007733000033333b777733700033333b7777330000333333bbb3370000033333bbbbb7700000bbb33bbbb77000000bbbbbbbb77000000bbbbbbbb70000
330000000733000033300000773300003333b7777333000033333bbb73300000333333bbbb33000000b33333bb33000000b3333bbb370000000bbbbbbb370000
330000000330000033000000033000003300000003300000333bb7777330000033333bbb7733000003333333bb3300000333333bbb33000000b333bbb3370000
3330000003300000333000000330000033300000033000003333000003300000333bbb7773300000033333337733000033333337773300000333333b73300000
03300000033000000333000033000000033300000330000003333000033000003333000003300000033330000033000033333300003300003333333377330000
00000000033000000033000033000000003330000330000000333000003300000033300000330000033333000033000003333330000330003333333300033000
00000000030000000000000003300000000333000033000000033300000300000003333000033000003333300003300000333333000033000333333330033300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bb3bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb3bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb00bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333433330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43433343434433440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44443444444443440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
