from PIL import Image
from PIL import ImageFont
from PIL import ImageDraw
import os
from datetime import datetime, tzinfo
import pytz
 
font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.dfont", 72)
fontsmall = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.dfont", 32)
fontcolor = (238,161,6)
counter = 0
# Go through each file in current directory
for i in os.listdir(os.getcwd()):
	if i.endswith(".jpg"):
		counter += 1
		# For debugging: limit how many images are processed:
		# if counter>10:
		# 	break
		print("Image {0}: {1}".format(counter, i))
		# Files are named like YYYY-MM-DD_hhmm.jpg
		# * Date is the first chunk before the underscore
		# * Time is always the first 4 characters after the "_"
		# splitup = i.split("_")
		# date = splitup[0]
		# t = splitup[1][0:4]
		# # Add colon to time
		# tformatted = t[0:2] + ":" + t[2:4]
		real_filename = os.readlink(i)
		splitup = real_filename.split("_")
		unix_epoch_timestamp = splitup[-1].split(".")[0]
		# print real_filename
		# print int(unix_epoch_timestamp / 1000)
		# print datetime.utcfromtimestamp(int(unix_epoch_timestamp / 1000))
		file_datetime = datetime.fromtimestamp(float(unix_epoch_timestamp) / 1000)
		file_datetime = file_datetime.replace(tzinfo=pytz.timezone('US/Mountain'))
		date = file_datetime.strftime('%Y-%m-%d')
		tformatted = file_datetime.strftime('%I:%M:%S.%f %p %z %Z')
 
		# Open the image and resize it to HD format
		# 720p (1280x720 px)
		# 1080p (1920x1080 px)
		widthtarget = 1920
		heighttarget = 1080
		img = Image.open(i)
		downSampleRatio = float(widthtarget) / float(img.width)
		imgDownSampled = img.resize( (widthtarget, int(round(img.height*downSampleRatio)) ), resample=Image.LANCZOS)
		imgDownSampled = imgDownSampled.crop((0,180,widthtarget, heighttarget+180))
 
		# get a drawing context
		draw = ImageDraw.Draw(imgDownSampled)
		draw.text((0,imgDownSampled.height-150), date, fontcolor, font=fontsmall)
		draw.text((0,imgDownSampled.height-120), tformatted, fontcolor, font=font)
		# draw.text((imgDownSampled.width-220,imgDownSampled.height-150), date, fontcolor, font=fontsmall)
		# draw.text((imgDownSampled.width-220,imgDownSampled.height-120), tformatted, fontcolor, font=font)
		# filename = "resized/" + i[0:-4] + "-resized.jpg"
		# imgDownSampled.save(filename)
		imgDownSampled.save(real_filename)
