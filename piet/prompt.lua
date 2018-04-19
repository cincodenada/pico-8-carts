-->8
function pbtn(i) return (not prompt.just_ended and btn(i)) end
function prompt:show(text, callback)
	self.callback = callback
	self:set_text(text)
end

function prompt:set_text(text)
	local wrapped = wrap(text, 62)
	if(self.callback) then
		wrapped.text = wrapped.text.."z=yes / x=no"
	else
		wrapped.text = wrapped.text.."z to dismiss"
	end
	wrapped.lines += 1

	self.text = wrapped.text
	self.halfheight = wrapped.lines*3
end

function prompt:draw()
	if(not self:active()) return
	view:save_camera()
	rectfill(32,64-self.halfheight,95,64+self.halfheight,5)
	rect(31,64-self.halfheight-1,96,64+self.halfheight+1,4)
	print(self.text, 33, 64-self.halfheight+1,7)
	view:load_camera()
end

function prompt:check()
	if(btnp(4) or btnp(5)) then
		if(self.callback) self.callback(btnp(4))
		self.text = ""
		self.callback = nil
		self.update_callback = nil
		self.just_ended = true
		return true
	elseif(self.update_callback) then
		local pressed = nil
		for b=0,3 do
			if(btnp(b)) pressed = b break
		end
		if(pressed) self.update_callback(pressed)
	end
	return false
end

-- clear button pressed once they're released
function prompt:update_buttons()
	if(not btn(4) and not btn(5)) then
		self.just_ended = false
	end
end

function prompt:active()
	return (self.text!="")
end

