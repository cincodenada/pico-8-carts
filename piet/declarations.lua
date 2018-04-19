-- stored in sprite + aux data
-- 128x128 pixels (2 per byte)
-- 64x128 bytes
-- plus map-only data of 128x32
-- for a total of 128x96 bytes
image = {
	w=64,
	h=64,
	max_bytes=0x2000,
	mem_start=0x0000,
	max_w=64,
	max_h=128,
	header_size=3, -- for now this is constant
}

prompt = {
	text = "",
	callback = nil,
	update_callback = nil,
	just_ended = false,
}

view = {
	nw = {x=0,y=0},
	pxsize = 2,
	sel = mksel(0,0),
	cameras = {},
	size = {128,128}
}

palette = {
	pxsize = 4,
	top = 0,
}

