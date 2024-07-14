class Gear:
    def __init__(self):
        self.rpms = []
        self.next = None
        self.prev = None

    def str(self):
        return '    db ' + ',  '.join([rpm.str() for rpm in self.rpms])

class RPM:
    def __init__(self, rpm, speed, acc):
        self.rpm = rpm
        self.speed = speed
        self.speed_hi = int((speed - speed % 100) / 100)
        speed -= self.speed_hi * 100
        self.speed_mid = int((speed - speed % 10) / 10)
        self.speed_low = speed - self.speed_mid * 10
        self.speed_hi *= 5
        self.speed_mid *= 5
        self.speed_low *= 5
        self.acc = acc
        self.next = 0
        self.prev = 0

    def str(self):
        return '%d,%d,%d,%d,%d,%d,%d,%d' % (self.rpm, self.speed_hi, self.speed_mid, self.speed_low, self.next, self.prev, self.acc, self.speed)

accel = [None, 0, 4, 8, 8, 4, 2, 1, 0]

gears = []
speed = 0

for gear in range(5):
    gear = Gear()
    gears.append(gear)
    for rpm in range(1,9):
        speed += 10
        rpm_info = RPM(rpm, speed, accel[rpm])
        gear.rpms.append(rpm_info)
    speed -= 50

for i in range(1,4):
    prev_gear = gears[i-1]
    curr_gear = gears[i]
    prev_gear.next = curr_gear
    curr_gear.prev = prev_gear

for i in range(4):
    gear = gears[i]
    next_gear = gears[i+1]
    for rpm in gear.rpms:
        rpm.next = 0
        curr_speed = rpm.speed
        for next_rpm in next_gear.rpms:
            if next_rpm.speed == rpm.speed:
                rpm.next = (8 - rpm.rpm + next_rpm.rpm) * 8
                break

for i in range(1, 5):
    gear = gears[i]
    prev_gear = gears[i-1]
    for rpm in gear.rpms:
        rpm.prev = (i - 1) * 64 + 56
        curr_speed = rpm.speed
        for prev_rpm in prev_gear.rpms:
            if prev_rpm.speed == rpm.speed:
                rpm.prev = (i - 1) * 64 + (prev_rpm.rpm-1) * 8
                break

gears[0].rpms[0].acc = 8
gears[0].rpms[1].acc = 8

for gear in gears:
    print(gear.str())
