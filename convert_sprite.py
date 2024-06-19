from PIL import Image

img = Image.open('sprite.png')

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
    print("Unknown value", val)

for y in range(16):
    row = []
    colors = [0, 0, 0, 0]
    colors.extend([get_color(img.getpixel((x, y))) for x in range(8)])
    colors.extend([0, 0, 0, 0])
    for i in range(4):
        val1 = colors[4-i+3]
        val2 = colors[4-i+2]
        val3 = colors[4-i+1]
        val4 = colors[4-i]
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)
        val1 = colors[8-i+3]
        val2 = colors[8-i+2]
        val3 = colors[8-i+1]
        val4 = colors[8-i]
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)
        val1 = colors[12-i+3]
        val2 = colors[12-i+2]
        val3 = colors[12-i+1]
        val4 = colors[12-i]
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)

    print('    db ' + ','.join([str(val) for val in row]))

    # mask
    row = []
    for i in range(4):
        val1 = 3 if colors[4-i+3] == 0 else 0
        val2 = 3 if colors[4-i+2] == 0 else 0
        val3 = 3 if colors[4-i+1] == 0 else 0
        val4 = 3 if colors[4-i] == 0 else 0
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)
        val1 = 3 if colors[8-i+3] == 0 else 0
        val2 = 3 if colors[8-i+2] == 0 else 0
        val3 = 3 if colors[8-i+1] == 0 else 0
        val4 = 3 if colors[8-i] == 0 else 0
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)
        val1 = 3 if colors[12-i+3] == 0 else 0
        val2 = 3 if colors[12-i+2] == 0 else 0
        val3 = 3 if colors[12-i+1] == 0 else 0
        val4 = 3 if colors[12-i] == 0 else 0
        val = val1*16*4 + val2*16 + val3*4 + val4
        row.append(val)

    print('    db ' + ','.join([str(val) for val in row]))
