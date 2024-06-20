from PIL import Image

img = Image.open('explosion.png')

def get_color(val):
    if val == (0, 0, 0, 255):
        return 0
    if val == (255, 255, 255, 255):
        return 3
    if val == (255, 242, 0, 255):
        return 2
    if val == (63, 72, 204, 255):
        return 2
    if val == (237, 28, 36, 255):
        return 1
    if val == (255, 6, 0, 255):
        return 1
    print("Unknown value", val)

for y in range(img.height):
    row = []
    colors = [0, 0, 0, 0]
    for x in range(0, img.width, 4):
        val1 = get_color(img.getpixel((x+3, y)))
        val2 = get_color(img.getpixel((x+2, y)))
        val3 = get_color(img.getpixel((x+1, y)))
        val4 = get_color(img.getpixel((x, y)))
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)

    print('    db ' + ','.join([str(val) for val in row]))

    # mask
    row = []
    for x in range(0, img.width, 4):
        val1 = 3 if get_color(img.getpixel((x+3, y))) == 0 else 0
        val2 = 3 if get_color(img.getpixel((x+2, y))) == 0 else 0
        val3 = 3 if get_color(img.getpixel((x+1, y))) == 0 else 0
        val4 = 3 if get_color(img.getpixel((x, y))) == 0 else 0
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)

    print('    db ' + ','.join([str(val) for val in row]))
