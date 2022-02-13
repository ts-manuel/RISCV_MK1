################################################
#  File: codec.py
#
#
#
#  Usage: codec.py [OPTIONS]
#
#  -d and -a options are mutually exclusive
#
#  Option            Meaning
#  -i <inputfile>    Input file path (required)
#  -o <outputfile>   Output file path (required)
#  -s <start frame>  Frame from where to start encoding / decoding
#  -n <num frames>   Number of frames to encode / decode
#  -d                Decode input file (default is encode)
#  -p                Show preview when encoding / decoding
#  -a                Analize input video
#
#  Encoder:
#     input file format:   .mp4
#     out file format:     binary
#
#  Decoder:
#     input file format:   binary
#     output file format:  .mp4
#
#  Analize:
#     input file format:   .mp4
#     output file format:  .csv
#
#
#  Encoded file format: (multibyte values are little endian)
#     Offset   Size     Description
#     0        [16bit]  width
#     2        [16bit]  height
#     4        [8bit]   fps
#     5        [8bit]   -
#     6        [8bit]   -
#     7        [8bit]   -
#     8...N    [8bit]   compressed data        
#
#
################################################

import sys
import getopt
import struct
import cv2 as cv
import numpy as np




def main(argv):
   inputfile = ''
   outputfile = ''
   op_decode = False
   op_preview = False
   op_analize = False
   start_frame = 0
   num_frames = -1
   try:
      opts, args = getopt.getopt(argv, "hdpai:o:s:n:")
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
      elif opt == '-s':
         start_frame = int(arg, 10)
      elif opt == '-n':
         num_frames = int(arg, 10)
      elif opt == '-d':
         op_decode = True
      elif opt == '-p':
         op_preview = True
      elif opt == '-a':
         op_analize = True

   if inputfile == '' or outputfile == '':
      print ('Error: input or output file not set')
      exit(1)

   if op_decode:
      decode(inputfile, outputfile, start_frame, num_frames, op_preview)
   elif op_analize:
      analize(inputfile, outputfile)
   else:
      encode(inputfile, outputfile, start_frame, num_frames, op_preview)




def encode(input_file, output_file, start_frame, num_frames, op_preview):
   frame_counter = 0
   capture = cv.VideoCapture(cv.samples.findFileOrKeep(input_file))
   if not capture.isOpened():
      print('Unable to open: ' + input_file)
      exit(1)

   with open(output_file, "wb") as output:
      width  = int(capture.get(cv.CAP_PROP_FRAME_WIDTH))
      height = int(capture.get(cv.CAP_PROP_FRAME_HEIGHT))
      fps    = int(capture.get(cv.CAP_PROP_FPS))

      #Write header
      output.write(struct.pack("<HHBBBB", width, height, fps, 0, 0, 0))
 
      #Write data
      while (num_frames < 0) or (frame_counter < start_frame + num_frames):
         ret, frame = capture.read()
         if ret is False:
            break

         frame_counter += 1

         if frame_counter > start_frame:
            output.write(encode_frame(frame, width, height))
            
            if op_preview:
               cv.rectangle(frame, (10, 2), (100,20), (255,255,255), -1)
               cv.putText(frame, str(frame_counter), (15, 15), cv.FONT_HERSHEY_SIMPLEX, 0.5 , (0,0,0))
               cv.imshow('Frame', frame)
               
               keyboard = cv.waitKey(1)
               if keyboard == 'q' or keyboard == 27:
                  break

      output.close()




def encode_frame(frame, width, height):
   output = bytearray()

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




def decode(input_file, output_file, start_frame, num_frames, op_preview):
   with open(input_file, "rb") as input:
      bytestream = bytearray(input.read())
      frame_counter = 0
      offset = 8

      #Read header
      width, height, fps = struct.unpack_from("<HHB", bytestream)
      
      fourcc = cv.VideoWriter_fourcc('m', 'p', '4', 'v')
      writer = cv.VideoWriter(output_file, fourcc, fps, (width,height))
      if not writer.isOpened():
         print('Unable to open: ' + output_file)
         exit(1)

      print('decoding: ', input_file)
      print('width...: ', width)
      print('height..: ', height)
      print('fps.....: ', fps)

      while (num_frames < 0) or (frame_counter < start_frame + num_frames):
         frame, byte_count = decode_frame(bytestream, offset)
         if byte_count == 0 :
            break

         frame_counter += 1
         offset += byte_count

         if frame_counter > start_frame:
            writer.write(frame)

            if op_preview:
               cv.rectangle(frame, (10, 2), (100,20), (255,255,255), -1)
               cv.putText(frame, str(frame_counter), (15, 15), cv.FONT_HERSHEY_SIMPLEX, 0.5 , (0,0,0))
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




def print_usage():
   print(
'''
Usage: codec.py [OPTIONS]

-d and -a options are mutually exclusive

Option            Meaning
-i <inputfile>    Input file path (required)
-o <outputfile>   Output file path (required)
-s <start frame>  Frame from where to start encoding / decoding
-n <num frames>   Number of frames to encode / decode
-d                Decode input file (default is encode)
-p                Show preview when encoding / decoding
-a                Analize input video

Encoder:
   input file format:   .mp4
   out file format:     binary

Decoder:
   input file format:   binary
   output file format:  .mp4

Analize:
   input file format:   .mp4
   output file format:  .csv
'''
)




if __name__ == "__main__":
   main(sys.argv[1:])