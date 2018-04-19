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
			-- make sure to push out the primary axis
			-- if we're not equivalent
			self.x = check.x
			self.y = check.y
		else
			-- if neither of the above, we're chopped liver
			return
		end
	end
	-- if we made it here, we're better
	self.x = check.x
	self.y = check.y
end

function get_exit(state)
	-- exit cmp is determined by dp/cc
	--     -1    1
	-- 0 -y +x +y +x
	-- 1 +y +x +y -x
	-- 2 +y -x -y -x
	-- 3 -y -x -y +x
	local last = {}
	local cur = {}
	local next = {}
	local block_nums = {}
	max_block:init(state)
	cur[hashloc(state)] = state
	local block_color = packhv(image:getpx(max_block))
	local block_size = 1
	local numloops = 1
	while(true) do
		local new_px = 0
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

