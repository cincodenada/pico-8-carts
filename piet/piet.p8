pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
x=0
y=0
solidpat=0x0000
midpat=0xa5a5
pxsize=6
gridsize=pxsize+2
editing=0

numhues=6
colormap={
  8,9,3,1,13,2,
  15,10,11,12,6,14
}

function getpx(x,y)
  local curval = mget(x,y)
  
  print("getpx")
  print(curval)
  local row = band(curval,0x0f)
  local col = lshr(band(curval,0xf0),4)
  print(row)
  print(col)

  return {val = row, hue = col}
end

function setpx(x,y,px)
  mset(x,y,px.val + shl(px.hue,4))
end

function getcol(px)
  if(px.val==0) then
    // easy, 0/1 to either
    // white (7) or black(0)
    return 7*(1-band(px.hue/3,0x01))
  else
    // proper colors
    print("getcolor")
    // rows to get fg/bg colors
    local rowa = band(lshr(px.val-1,1),0xf)
    local rowb = band(lshr(px.val,1),0xf)
    
    print(px.hue)
    print(px.val)
    print(rowa)
    print(rowb)
    
    // get colors from map
    local cola = colormap[rowa*numhues+px.hue+1]
    local colb = colormap[rowb*numhues+px.hue+1]
    return cola + shl(colb, 4)
  end
end

function _update()
  if(btnp(4)) editing=1-editing

  if(editing==1) then
    local px = getpx(x,y)
    
    // handle moving from hues
    // to black/white and back
    local hueinc=1
    if(px.val==0) hueinc=3
            
    if(btnp(0)) px.hue-=hueinc
    if(btnp(1)) px.hue+=hueinc
    if(btnp(2)) px.val-=1
    if(btnp(3)) px.val+=1
    
    px.val %= 4
    px.hue %= 6
    
    setpx(x,y,px)
  else
    if(btnp(0)) x-=1
    if(btnp(1)) x+=1
    if(btnp(2)) y-=1
    if(btnp(3)) y+=1
  end
  
  if(x<0) x=0
  if(y<0) y=0
  
  if(x>127) then x=127 end
  if(y>63) then y=63 end
end

function _draw()
  cls()
  local framecolor=5
  // yellow frame for editing
  if(editing==1) framecolor=4
  
  local px = getpx(x,y)
  if(px.val==2) then
    // middle row
    fillp(midpat)
  else
    fillp(solidpat)
  end
  
  rectfill(
    x*gridsize,
    y*gridsize,
    (x+1)*gridsize-1,
    (y+1)*gridsize-1,
    getcol(px)
  )
  fillp(solidpat)
  rect(
    x*gridsize,
    y*gridsize,
    (x+1)*gridsize-1,
    (y+1)*gridsize-1,
    framecolor
  )
end
__gfx__
0088993311dd22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0088993311dd22000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008f9a3b1cd62e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f8a9b3c16de2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffaabbcc66ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ffaabbcc66ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
