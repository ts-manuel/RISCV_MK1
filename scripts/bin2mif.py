################################################
# File: bin2vhdl.py
#
# Converts bynary file into .mif
# memory initializatio file understood by Quartus
#
#
################################################

import sys
import getopt



def main(argv):
   inputfile = ''
   outputfile = ''

   try:
      opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print('bin2vhdl.py <inputfile> -o <outputfile>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print('bin2vhdl.py <inputfile> -o <outputfile>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
         
   convert(inputfile, outputfile)



def convert(inputfile, outputfile):
   with open(inputfile, "rb") as input, open(outputfile, "w") as output:
      data = bytearray(input.read())
      offset = 0

      output.write('DEPTH = {0};\n'.format(int(len(data)/4)))
      output.write('WIDTH = 32;\n')
      output.write('ADDRESS_RADIX = HEX;\n')
      output.write('DATA_RADIX = HEX;\n')
      output.write('CONTENT\n')
      output.write('BEGIN\n')

      while offset < len(data) :
         output.write('{:08x}'.format(int(offset/4)))
         output.write(' : ')
         output.write('{:02x}'.format(data[offset + 3]))
         output.write('{:02x}'.format(data[offset + 2]))
         output.write('{:02x}'.format(data[offset + 1]))
         output.write('{:02x}'.format(data[offset + 0]))
         output.write(';\n')
         offset += 4

      output.write('END;\n')


if __name__ == "__main__":
   main(sys.argv[1:])