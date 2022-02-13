################################################
# File: bin2hex.py
#
#
#  Converts bynary file into ASCII HEX
#
#
#  Usage: bin2hex.py [OPTIONS]
#
#
#  Option            Meaning
#  -h                Help
#  -i <inputfile>    Input file path (required)
#  -o <outputfile>   Output file path (required)
#
#
################################################

import sys
import getopt




def main(argv):
   inputfile = ''
   outputfile = ''

   try:
      opts, args = getopt.getopt(argv, "hi:o:")
   except getopt.GetoptError:
      print('Error: invalid parameter, -h for help')
      exit(1)
   for opt, arg in opts:
      if opt == '-h':
         print_usage()
         exit()
      elif opt == "-i":
         inputfile = arg
      elif opt == "-o":
         outputfile = arg

   if inputfile == '' or outputfile == '':
      print ('Error: input or output file not set')
      exit(1)
         
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




def print_usage():
   print(
'''
Usage: bin2hex.py [OPTIONS]


Option            Meaning
-h                Help
-i <inputfile>    Input file path (required)
-o <outputfile>   Output file path (required)
'''
   )




if __name__ == "__main__":
   main(sys.argv[1:])