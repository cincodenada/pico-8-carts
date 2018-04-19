-->8
-- generate pico-8 color <-> hv lookup tables
local col2hv = {}
local hv2col = {}
for curhue=0,numhues-1 do
	local colors = {
		colormap[curhue+1] + shl(colormap[curhue+1],4),
		colormap[curhue+1] + shl(colormap[curhue+1+numhues],4),
		colormap[curhue+1+numhues] + shl(colormap[curhue+1],4),
		colormap[curhue+1+numhues] + shl(colormap[curhue+1+numhues],4)
	}
	col2hv[colors[1]] = {hue=curhue,val=0}
	col2hv[colors[2]] = {hue=curhue,val=1}
	col2hv[colors[3]] = {hue=curhue,val=1}
	col2hv[colors[4]] = {hue=curhue,val=2}
	
	hv2col[curhue] = {}
	hv2col[curhue][0] = colors[1]
	hv2col[curhue][1] = colors[2]
	hv2col[curhue][2] = colors[4]
	-- add black/white
	hv2col[curhue][3] = 0x77*(1-flr(curhue/(numhues/2)))
end
col2hv[0x00] = {hue=3,val=3} -- black
col2hv[0x77] = {hue=0,val=3} -- white

-- translates a h/v pair to a fill color
-- with upper/lower nibble set properly
function getcol(px)
	return hv2col[px.hue][px.val]
end
