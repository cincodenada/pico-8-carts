-->8
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

function state:get_move()
	if(self.dp % 2==0) then
		return {x=1-self.dp, y=0}
	else
		return {x=0, y=2-self.dp}
	end
end

function state:next()
	local next = tcopy(self)
	next.attempts = 0
	local cur_exit = self:exit()
	move = self:get_move()
	next.x = cur_exit.exit.x + move.x
	next.y = cur_exit.exit.y + move.y
	next.last_value = cur_exit.count
	return next
end

function state:exit()
	local cur_exit = {}
	if(image:is_white(self)) then
		cur_exit.exit = self:slide()
	else
		cur_exit = self:color_exit()
	end
	return cur_exit
end

function state:slide()
	local cur = tcopy(state)
	local move = self:get_move()
	while(image:is_white(cur)) do
		cur.x += move.x
		cur.y += move.y
	end
	-- back up cause we entered another color
	cur.x -= move.x
	cur.y -= move.y
	return cur
end

function state:color_exit()
	max_block:init(self)
	return get_exit(self)
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

function stack:top()
	return self[#self]
end

function stack:swap(num)
	local top = self[#self]
	self[#self] = num
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
