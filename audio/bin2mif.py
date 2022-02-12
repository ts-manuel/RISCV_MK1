################################################
# File: bin2hex.py
#
# Converts bynary file into ASCII HEX
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

      output.write('SIZE: {0}\n'.format(len(data)))

      while offset < len(data) :
         output.write('{:02x}'.format(data[offset]))
         offset += 1

      output.write('\n')


if __name__ == "__main__":
   main(sys.argv[1:])