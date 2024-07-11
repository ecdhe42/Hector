from PIL import Image

img = Image.open('afond_car1.png')

def get_color(val):
    if val == 1:
        return 1
    if val == 2:
        return 0
    if val == 0:
        return 0
    if val == 3:
        return 3
    if val == (0, 0, 0, 0):
        return 0
    if val == (0, 0, 0, 255):
        return 0
    if val == (255, 0, 0, 255):
        return 1
    if val == (0, 255, 0, 255) or val == (0, 255, 0, 246):
        return 2
    if val == (255, 255, 255, 255):
        return 3
    if val == (38, 0, 255, 255):
        return 2
    if val == (255, 6, 0, 255):
        return 1
    print(val)

def get_mask_color(val):
    if val == (0, 0, 0, 0):
        return 3
    return 0
    if val == 1:
        return 0
    if val == 2:
        return 3
    if val == 0:
        return 0
    if val == 3:
        return 0
    print(val)

# 0: black
# 1: red
# 2: green
# 3: white
palette = [0, 2, 3, 1]

with open("rsc_afond_car.asm", "wb") as o:

    mask_db = []
    db = []

    for y in range(img.height):
        for x in range(0, img.width, 4):
            val1 = get_mask_color(img.getpixel((x+3, y)))
            val2 = get_mask_color(img.getpixel((x+2, y)))
            val3 = get_mask_color(img.getpixel((x+1, y)))
            val4 = get_mask_color(img.getpixel((x, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))

            val1 = get_color(img.getpixel((x+3, y)))
            val2 = get_color(img.getpixel((x+2, y)))
            val3 = get_color(img.getpixel((x+1, y)))
            val4 = get_color(img.getpixel((x, y)))
            val = val1*16*4 + val2*16 + val3*4 + val4
            db.append(str(val))

#    for y in range(int(len(mask_db) / 20)):
#        line = '    db ' + ','.join(mask_db[y*20:y*20+20]) + '\r\n'
#        o.write(line.encode())
#
#    o.write(b"\r\n")

    for y in range(int(len(db) / 20)):
        line = '    db ' + ','.join(db[y*20:y*20+20]) + '\r\n'
        o.write(line.encode())
