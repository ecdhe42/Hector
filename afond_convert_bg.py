from PIL import Image

img = Image.open('afond_bg2.png')

def get_color(val):
    if val == (0, 0, 0, 255) or val == (0, 0, 0):
        return 0
    if val == (255, 0, 0, 255) or val == (254, 0, 0):
        return 1
    if val[0] == 0 and val[2] == 0 and val[1] > 128:
        return 2
    if val[0] > 128 and val[1] > 128 and val[2] > 128:
        return 3
    print(val)
    return None

# 0: black
# 1: red
# 2: green
# 3: white
palette = [0, 2, 3, 1]

with open("rsc_afond_bg.asm", "wb") as o:

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
