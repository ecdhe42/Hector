y = 40
x = 100
xp = 32

a = 0x6000
b = 0x6000 + 0x1900

invert_l = []

with open("afond_bitmap_ptr.asm", "w") as f:
    for z in range(12):
        l = []

        x = 100
        ptr = a

        if z < 13:
            x_delta = (25 - z)*64/26 - 32
            nb = round(y*x_delta/x)
            l.extend([ptr]*nb)
            x += x_delta
            ptr = b if ptr == a else a
            x_delta = 32
            nb = min(12, round(y*x_delta/x))
            l.extend([ptr]*nb)
            x += x_delta
        else:
            ptr = b if ptr == a else a
            x_delta = round((25 - z)*64/26)
            nb = round(y*x_delta/x)
            l.extend([ptr]*nb)
            x += x_delta

        ptr = b if ptr == a else a

        while len(l) < 100:
            nb = min(12, max(round(y*xp/x), 1))
            l.extend([ptr]*nb)
            x += xp
            ptr = b if ptr == a else a

        print(''.join(['X' if val == a else '.' for val in l]))
        l = l[:100]
        l.reverse()
        invert_l.append([a if val == b else b for val in l])

        for i in range(100):
            l[i] = l[i] + 64*i


        l2 = []
        for val in l:
            l2.append(str(int(val/256)))
            l2.append(str(val % 256))

        f.write('    db ' + ','.join(l2) + '\n')


    for l in invert_l:
        print(''.join(['X' if val == a else '.' for val in l]))
        for i in range(100):
            l[i] = l[i] + 64*i

        l2 = []
        for val in l:
            l2.append(str(int(val/256)))
            l2.append(str(val % 256))

        f.write('    db ' + ','.join(l2) + '\n')
