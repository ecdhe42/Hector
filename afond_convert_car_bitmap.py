from PIL import Image

def get_color(val):
    if val == 0:
        return 0
    if val == 1:
        return 0
    if val == 2:
        return 1
    if val == 3:
        return 2
    if val == 4:
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
    if val == 0:
        return 3
    if val == 1 or val == 2 or val == 3:
        return 0
    if val == (0, 0, 0, 0):
        return 3
    return 0
    print(val)

# 0: black
# 1: red
# 2: green
# 3: white

def convert_car():
    img = Image.open('afond_car1.png')

    with open("rsc_afond_car.asm", "wb") as o:
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

        for y in range(int(len(db) / 20)):
            line = '    db ' + ','.join(db[y*20:y*20+20]) + '\r\n'
            o.write(line.encode())

def convert_competing_cars():
    img1 = Image.open('afond_car_s1.png')
    img2 = Image.open('afond_car_s2.png')
    img3 = Image.open('afond_car_s3.png')

    imgs = [img3, img2, img1]

    with open("rsc_afond_cars_others.asm", "wb") as o:
        db = []

        for idx, img in enumerate(imgs):
            o.write(('bitmap_cars_others' + str(idx) + ':\r\n').encode())
            for y in range(img.height):
                for x in range(0, img.width, 4):
                    val1 = get_mask_color(img.getpixel((x+3, y)))
                    val2 = get_mask_color(img.getpixel((x+2, y)))
                    val3 = get_mask_color(img.getpixel((x+1, y)))
                    val4 = get_mask_color(img.getpixel((x, y)))
                    val = val1*16*4 + val2*16 + val3*4 + val4
#                    db.append(str(val))

                    val1 = get_color(img.getpixel((x+3, y)))
                    val2 = get_color(img.getpixel((x+2, y)))
                    val3 = get_color(img.getpixel((x+1, y)))
                    val4 = get_color(img.getpixel((x, y)))
                    val = val1*16*4 + val2*16 + val3*4 + val4
                    db.append(str(val))

            for y in range(int(len(db) / 16)):
                line = '    db ' + ','.join(db[y*16:y*16+16]) + '\r\n'
                o.write(line.encode())

convert_competing_cars()
