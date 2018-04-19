#!/usr/bin/env python
from PIL import Image
from PIL.ImageColor import getrgb
import sys
import os.path

#FFCCAA (255, 204, 170) peach
#FFEC27 (255, 236, 39) yellow
#00E436 (0, 228, 54) green
#C2C3C7 (194, 195, 199) light-gray
#29ADFF (41, 173, 255) blue
#FF77A8 (255, 119, 168) pink
#FF004D (255, 0, 77) red
#FFA300 (255, 163, 0) orange
#008751 (0, 135, 81) dark-green
#83769C (131, 118, 156) indigo
#1D2B53 (29, 43, 83) dark-blue
#7E2553 (126, 37, 83) dark-purple

#5F574F (95, 87, 79) dark-gray
#000000 (0, 0, 0) black
#AB5236 (171, 82, 54) brown
#FFF1E8 (255, 241, 232) white
color_map = {
  "#FFC0C0": ["#FFCCAA", "#FFCCAA"],
  "#FFFFC0": ["#FFEC27", "#FFEC27"],
  "#C0FFC0": ["#00E436", "#00E436"],
  "#C0FFFF": ["#C2C3C7", "#C2C3C7"],
  "#C0C0FF": ["#29ADFF", "#29ADFF"],
  "#FFC0FF": ["#FF77A8", "#FF77A8"],
  "#FF0000": ["#FFCCAA", "#FF004D"],
  "#FFFF00": ["#FFEC27", "#FFA300"],
  "#00FF00": ["#00E436", "#008751"],
  "#00FFFF": ["#C2C3C7", "#83769C"],
  "#0000FF": ["#29ADFF", "#1D2B53"],
  "#FF00FF": ["#FF77A8", "#7E2553"],
  "#C00000": ["#FF004D", "#FF004D"],
  "#C0C000": ["#FFA300", "#FFA300"],
  "#00C000": ["#008751", "#008751"],
  "#00C0C0": ["#83769C", "#83769C"],
  "#0000C0": ["#1D2B53", "#1D2B53"],
  "#C000C0": ["#7E2553", "#7E2553"],
  "#FFFFFF": ["#FFFFFF", "#FFFFFF"],
  "#000000": ["#000000", "#000000"],
}

rgb_map = {
    getrgb(k): [getrgb(c) for c in v] for k, v in color_map.items()
}
black = rgb_map[(0,0,0)]
gray = (95,87,79)
brown = (171,82,54)

infile = sys.argv[1]
outfile = "{}.pico8{}".format(*os.path.splitext(infile))

source = Image.open(infile)
(w, h) = source.size

out = Image.new('RGB', ((w+1)*2, h+1), brown)
out.paste(source.resize((w*2,h)))
pixels = out.load()
for x in range(w*2):
  for y in range(h):
    # This is slow yeah but we're not doing huge things
    px = pixels[x,y]
    pixels[x,y] = rgb_map.get(px, black)[x%2]

out.save(outfile)
