total_bytes = 0

def write_bloc(k7, filename, where):
    global total_bytes
    with open(filename, "rb") as f:
        data = f.read()

    nb_bytes = len(data)
    bytes_high = int(nb_bytes / 256)
    bytes_low = nb_bytes % 256

    header = [5, 0, where, bytes_low, bytes_high, 0xFF]
    k7.write(bytes(header))
    for i in range(bytes_high):
        k7.write(bytes(1))
        k7.write(data[i*256:i*256+256])
#    k7.write(data)   
    k7.write(bytes([bytes_low]))
    k7.write(data[bytes_high*256:])
    total_bytes += nb_bytes
    total_bytes += 7

with open("hello.K7", "wb") as k7:
    write_bloc(k7, "olipix.bin", 0x4C)
    write_bloc(k7, "rsc.bin", 0x60)
    header = [5, 0, 0x4C, 0, 0xC0, 0xFD]
    k7.write(bytes(header))
    total_bytes += 7
    print(total_bytes)
