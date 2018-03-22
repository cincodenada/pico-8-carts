pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
x=0
y=0
midpat=0xaaaa
pxsize=2
gridsize=pxsize+2
editing=0

numhues=6
colormap={
  8,9,3,1,13,2,
  15,10,11,12,6,14
}

function getpx(x,y)
  curval = mget(x,y)
  
  print("getpx")
  print(curval)
  row = band(curval,0x0f)
  col = lshr(curval,4)
  print(row)
  print(col)

  return {y = row, x = col}
end

function setpx(x,y,px)
  mset(x,y,px.y + shl(px.x,4))
end

function getcol(px)
  if(px.y==0) then
    return 7*(1-px.x)
  else
    print("getcolor")
    local rowa = lshr(px.y-1,1)
    local rowb = lshr(px.y,1)
    
    print(px.x)
    print(px.y)
    print(rowa)
    print(rowb)
    
    local cola = colormap[rowa*numhues+px.x+1]
    local colb = colormap[rowb*numhues+px.x+1]
    return cola + shl(colb, 4)
  end
end

function _update()
  if(btnp(4)) editing=1-editing

  if(editing==1) then
    local px = getpx(x,y)
    
    if(btnp(0)) px.x+=1
    if(btnp(1)) px.x-=1
    if(btnp(2)) px.y+=1
    if(btnp(3)) px.y-=1
    
    if(px.y==0) then
      px.x %= 2
    else
      px.x %= 6
    end
    
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
	 if(editing==0) then
	   framecolor=7
	 else
	   framecolor=10
	 end
	 
	 rectfill(
	   x*gridsize,
    y*gridsize,
    (x+1)*gridsize-1,
    (y+1)*gridsize-1,
    getcol(getpx(x,y))
	 )
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
