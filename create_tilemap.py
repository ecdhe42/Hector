import xml.etree.ElementTree as ET 

tree = ET.parse("henon1.tmx")
root = tree.getroot()

tiles = [str(int(val)-1) for val in root.findall('./layer/data')[0].text.split(',')]

with open("henon1_tilemap.asm", "w") as f:
    for idx in range(0, len(tiles), 16):
        values = tiles[idx:idx+16]
        f.write('    db ' + ','.join(values) + '\r\n')
