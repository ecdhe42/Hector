from PIL import Image

img = Image.open('font.png')

def get_color(val):
    if val == 1:
        return 3
    if val == 2:
        return 1
    if val == 0:
        return 0
    if val == 3:
        return 2
    if val == (0, 0, 0, 255) or val == (0,0,0):
        return 0
    if val == (255, 0, 0, 255):
        return 1
    if val == (255, 242, 0, 255):
        return 2
    if val == (255, 255, 255, 255) or val == (255,255,255):
        return 3
    if val == (38, 0, 255, 255):
        return 2
    if val == (255, 6, 0, 255):
        return 1
    print(val)

# 0: black
# 1: red
# 2: green
# 3: white
palette = [0, 2, 3, 1]

with open("rsc_font.asm", "wb") as o:

    db = []

    for x in range(0, img.width, 8):
        for y in range(16,24):
            val1 = get_color(img.getpixel((x+3, y)))
            val2 = get_color(img.getpixel((x+2, y)))
            val3 = get_color(img.getpixel((x+1, y)))
            val4 = get_color(img.getpixel((x, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))
            val1 = get_color(img.getpixel((x+7, y)))
            val2 = get_color(img.getpixel((x+6, y)))
            val3 = get_color(img.getpixel((x+5, y)))
            val4 = get_color(img.getpixel((x+4, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))

    for x in range(0, 56, 8):
        for y in range(24,32):
            val1 = get_color(img.getpixel((x+3, y)))
            val2 = get_color(img.getpixel((x+2, y)))
            val3 = get_color(img.getpixel((x+1, y)))
            val4 = get_color(img.getpixel((x, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))
            val1 = get_color(img.getpixel((x+7, y)))
            val2 = get_color(img.getpixel((x+6, y)))
            val3 = get_color(img.getpixel((x+5, y)))
            val4 = get_color(img.getpixel((x+4, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))

    for y in range(int(len(db) / 16)):
        line = '    db ' + ','.join(db[y*16:y*16+16]) + '\r\n'
        o.write(line.encode())
