import PIL
from PIL import Image, ImageDraw

img = Image.new("RGB", (256,231))

def get_color(val):
    if val == col0:
        return 0
    if val == col1:
        return 1
    if val == col2:
        return 2
    if val == col3:
        return 3
    print(val)

col0 = PIL.ImageColor.getrgb("#000000")     # black
col1 = PIL.ImageColor.getrgb("#FF0000")     # red
col2 = PIL.ImageColor.getrgb("#00FF00")     # green
col3 = PIL.ImageColor.getrgb("#FFFFFF")     # white

draw = ImageDraw.Draw(img)
draw.rectangle([(0,0),(255,199)], col2)                             # Draw the grass (image #1)
draw.polygon([(120,0), (10,99), (240,99), (120,0)], col0)           # Draw the pavement (image #1)
draw.polygon([(120,0), (10,99), (30,99), (120,0)], col3)            # Draw the left white curb (image #1)
draw.polygon([(120,0), (220,99), (240,99), (120,0)], col3)          # Draw the right white curb (image #2)
draw.polygon([(120,100), (10,199), (240,199), (120,100)], col0)     # Draw the pavement (image #2)
draw.polygon([(120,100), (10,199), (30,199), (120,100)], col1)      # Draw the left red curb (image #2)
draw.polygon([(120,100), (220,199), (240,199), (120,100)], col1)    # Draw the right red curb (image #2)
draw.polygon([(120,101), (118,199), (126,199), (120,101)], col3)    # Draw the middle white line (image #2)
img.show()

with open("rsc_afond.asm", "wb") as o:

    db = []

    for y in range(img.height):
        for x in range(0, img.width, 4):
            val1 = get_color(img.getpixel((x+3, y)))
            val2 = get_color(img.getpixel((x+2, y)))
            val3 = get_color(img.getpixel((x+1, y)))
            val4 = get_color(img.getpixel((x, y)))
#            palette[data[idx+6]]
#            val2 = palette[data[idx+4]]
#            val3 = palette[data[idx+2]]
#            val4 = palette[data[idx]]

            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))

    for y in range(int(len(db) / 64)):
        line = '    db ' + ','.join(db[y*64:y*64+64]) + '\r\n'
        o.write(line.encode())
