#!/usr/bin/python
from struct import *
import Image

infile = open("out.vmem", "r")
outfile = open("out.bin", "w")

width = 32
height = 24
Bpp = 3

adr = 0
adr_start = (0x600000)/4
adr_end = adr_start+(width*height*Bpp)/4

im = Image.new('RGB', (width, height))

# im.putpixel((10,10),128)

x = 0
y = 0
color = [0,0,0,0]
c = 0

def putpixel(value):
    global x, y, c
    color[c] = value
    c = c+1
    if (c==Bpp):
        c = 0
        im.putpixel((x,y), tuple(color[0:3]))
        x = x+1
        if (x>=width):
            x = 0
            y = y+1


for line in infile.readlines():
    if line[0]=='/':
        continue
    value = int(line.strip(), 16)
    # print value
    # outfile.write(pack('l', value))
    if (adr>=adr_start and adr<adr_end):
        outfile.write(pack('I', value))
        putpixel((value>>24)&0xFF)
        putpixel((value>>16)&0xFF)
        putpixel((value>>8 )&0xFF)
        putpixel((value    )&0xFF)
        
    adr=adr+1

    # break
    
im2 = im.resize((width*8, height*8), Image.NEAREST)
im2.save('out.png')