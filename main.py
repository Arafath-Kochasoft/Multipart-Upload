import sys

seek_part = int(sys.argv[1])
read_size = int(sys.argv[2])
part_num = int(sys.argv[3]) - 1
filename = sys.argv[4]

with open(filename, 'rb') as f:
  f.seek(seek_part*part_num)
  bin = f.read(read_size)
  # num = int.from_bytes(bin, 'big')
  with open('out.txt', 'wb') as fp:
    fp.write(bin)
