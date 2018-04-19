function hex(n,d) return sub(tostr(n,true),5,6) end
function packhv(hv) return hv.val+shl(hv.hue,4) end
function unpackhv(hv) return {val=band(hv,0x0f), hue=lshr(band(hv,0xf0),4)} end
function hashloc(loc) return tostr(loc.x).."#"..tostr(loc.y) end

function printbig(val)
	local s = ""
	local v = abs(val)
	repeat
		s = shl(v % 0x0.000a, 16)..s
		v /= 10
	until (v==0)
	if (val<0) s = "-"..s
	return s
end

function wrap(text, width)
	local charwidth = width/4
	text = text.." "
	local output, curline, word = "","",""
	local pos,lines = 1,1
	while(pos <= #text) do
		local curlet = sub(text,pos,pos)
		if(curlet == " ") then
			if(#curline + #word > charwidth) then
				output = output..curline.."\n"
				curline=""
				lines += 1
				-- back up so we re-process the space next line
				pos -= 1
			elseif(#curline + #word == charwidth) then
				output = output..curline..word.."\n"
				curline=""
				lines += 1
				word = ""
			else
				curline = curline..word.." "
				word = ""
			end
		elseif(curlet == "\n") then
			if(#curline + #word > charwidth) then
				output = output..curline.."\n"
				lines+=1
				output = output..word.."\n"
			else
				output = output..curline..word.."\n"
			end
			curline=""
			word=""
			lines+=1
		else
			-- if we have a word that's too long, just break it
			if(#curline == "" and #word == charwidth) then
				output = output..#word.."\n"
				word=""
				lines += 1
			end
			word = word..curlet
		end
		pos += 1
	end
	if(curline!="") output = output..curline.."\n"
	return {text=output, lines=lines}
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

function mksel(x,y,...)
	local sel={x=x,y=y,w=0,h=0}
	local args = {...}
	if (#args > 0)	then
		sel.w = args[1]
		sel.h = args[2]
	end
	return sel
end

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

