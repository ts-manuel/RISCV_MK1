#
# File: codec.py
#
# Video Encoder / Decoder
#
#
#

import sys
import getopt
import cv2 as cv
import numpy as np

def main(argv):
   inputfile = ''
   outputfile = ''
   op_decode = False
   op_trace = False
   op_analize = False
   try:
      opts, args = getopt.getopt(argv,"hedtai:o:",["ifile=","ofile="])
   except getopt.GetoptError:
      print('test.py -i <inputfile> -o <outputfile>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print('test.py -i <inputfile> -o <outputfile>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
      elif opt == '-d':
         op_decode = True
      elif opt == '-t':
         op_trace = True
      elif opt == '-a':
         op_analize = True
   print ('Input file is "', inputfile)
   print ('Output file is "', outputfile)

   if op_decode:
      decode(inputfile, outputfile, op_trace)
   elif op_analize:
      analize(inputfile, outputfile)
   else:
      encode(inputfile, outputfile, op_trace)



def encode(input_file, output_file, op_trace):
   capture = cv.VideoCapture(cv.samples.findFileOrKeep(input_file))
   if not capture.isOpened():
      print('Unable to open: ' + input_file)
      exit(0)

   output = open(output_file, "wb")
   if not output.writable():
      print('Unable to open: ' + output_file)
      exit(0)

   #last_frame = np.zeros((240,320,3), np.uint8)

   while True:
      ret, frame = capture.read()
      if ret is False:
         break

      #tmp = frame
      #frame = frame - last_frame
      #last_frame = tmp
      output.write(encode_frame(frame))
      
      if op_trace:
         cv.rectangle(frame, (10, 2), (100,20), (255,255,255), -1)
         cv.putText(frame, str(capture.get(cv.CAP_PROP_POS_FRAMES)), (15, 15), cv.FONT_HERSHEY_SIMPLEX, 0.5 , (0,0,0))
         cv.imshow('Frame', frame)
         
         keyboard = cv.waitKey(1)
         if keyboard == 'q' or keyboard == 27:
            break

   output.close()



def encode_frame(frame):
   output = bytearray()

   #Get frame height and width to access pixels
   height, width, channels = frame.shape

   for y in range(0, height) :
      encode_white = False
      counter = 0

      for x in range(0, width) :
         r = int.from_bytes(frame[y,x,0], 'little')
         g = int.from_bytes(frame[y,x,1], 'little')
         b = int.from_bytes(frame[y,x,2], 'little')
         a = (r + g + b) / 3
         pixel = a > 127

         if pixel == encode_white :
            counter += 1
            if counter == 255 :
               output.append(counter)
               counter = 0
               encode_white = not encode_white
         else :
            output.append(counter)
            counter = 1
            encode_white = not encode_white

      if counter > 0 :
         output.append(counter)

   return output


def encode_frame_delta(frame, last_frame) :
   frame -= last_frame






def decode(input_file, output_file, op_trace):
   fourcc = cv.VideoWriter_fourcc('m', 'p', '4', 'v')
   writer = cv.VideoWriter(output_file, fourcc, 24, (320,240))
   counter = 0
   offset = 0

   with open(input_file, "rb") as input:
      bytestream = bytearray(input.read())
      while True :
         frame, byte_count = decode_frame(bytestream, offset)
         if byte_count == 0 :
            break

         writer.write(frame)
         counter += 1
         offset += byte_count

         if op_trace:
            cv.rectangle(frame, (10, 2), (100,20), (255,255,255), -1)
            cv.putText(frame, str(counter), (15, 15), cv.FONT_HERSHEY_SIMPLEX, 0.5 , (0,0,0))
            cv.imshow('Frame', frame)

            keyboard = cv.waitKey(1)
            if keyboard == 'q' or keyboard == 27:
               break

   writer.release()



def decode_frame(input, offset):
   frame = np.zeros((240,320,3), np.uint8)
   byte_count = 0
   y = 0

   while len(input) > offset + byte_count:
      
      pixel = 0
      x = 0
      
      while x < 320 and len(input) > offset + byte_count :
         val = input[offset + byte_count]
         byte_count += 1

         for i in range(0, val) :
            frame[y,x, 0] = pixel
            frame[y,x, 1] = pixel
            frame[y,x, 2] = pixel
            x += 1

         if pixel == 0 :
            pixel = 255
         else :
            pixel = 0

      x = 0
      y += 1

      if y == 240 :
         return frame, byte_count
   
   return frame, 0



def analize(input_file, output_file):
   with open(input_file, "rb") as input, open(output_file, "w") as output:
      bytestream = bytearray(input.read())
      output.write('frame,ratio,%0xff,%0x00,min,max,avg\n')
      frame_counter = 0
      offset = 0

      while True :
         ratio, high, low, min, max, avg, byte_count = analize_frame(bytestream, offset)
         if byte_count == 0 :
            break

         output.write("{0},{1},{2},{3},{4},{5},{6}\n".format(frame_counter, ratio, high, low, min, max, avg))
         frame_counter += 1
         offset += byte_count


def analize_frame(input, offset):
   byte_count = 0
   high = 0
   low = 0
   min = np.Infinity
   max = 0
   avg = 0
   y = 0

   while len(input) > offset + byte_count :
      x = 0
      
      while x < 320 and len(input) > offset + byte_count :
         val = input[offset + byte_count]
         x += val
         byte_count += 1

         if val == 255 :
            high += 1
         elif val == 0 :
            low += 1
         else :
            avg += val

         if val < min and val != 0 :
            min = val
         if val > max and val != 255 :
            max = val

      x = 0
      y += 1

      if y == 240 :
         ratio = (320*240/8) / byte_count
         avg /= byte_count
         high /= byte_count
         low /= byte_count
         return ratio, high, low, min, max, avg, byte_count
   
   return 0, 0, 0, 0, 0, 0, 0



if __name__ == "__main__":
   main(sys.argv[1:])