# -*- coding: utf-8 -*-
"""Phototimer Images Timestamp Overlay

    Adds a timestamp based on millisecond unix epoch at end of image name:
      2017_6_9_8_1496995329075.jpg
                   \_ unix epoch * 1000
"""

import multiprocessing
import threading
import os
import sys
import pytz
import traceback
try:
   import Queue as queue
except ImportError:
   try:
      import queue
   except ImportError:
      from multiprocessing import Queue as queue
import logging

from PIL import Image
from PIL import ImageFont
from PIL import ImageDraw
from datetime import datetime

POOLSIZE = multiprocessing.cpu_count()


class ThreadTimestamper(threading.Thread):
    """
       ThreadTimestamper:
            Process multiple images off a queue in multithreaded fashion.
            Pull file timestamp off of symlink target's filename.
            Adds a timestamp using Pillow (PIL) based on millisecond unix epoch at end of image name
            For example:
                2017_6_9_8_1496995329075.jpg
                             \_ unix epoch * 1000
    """
    def __init__(self, file_queue):
        threading.Thread.__init__(self)
        self.q = file_queue
        if sys.platform.startswith('win') or sys.platform.startswith('cygwin'):
            FONTDIRS = [ os.path.join(os.environ['WINDIR'], 'Fonts') ]
            self.font_name = "Helvetica.ttf"
        elif sys.platform.startswith('darwin'):
            FONTDIRS = [ os.path.join("System", "Library", "Fonts") ]
            self.font_name = "HelveticaNeue.dfont"
        else: # linux, *bsd and everything else
            # [see below, commit suicide and develop this bit]
            FONTDIRS = [ os.path.join(os.path.sep, "usr", "share", "fonts") ]
            self.font_name = os.path.join("truetype", "fonts-beng-extra", "JamrulNormal.ttf")
#        self.font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.dfont", 72)
#        self.fontsmall = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.dfont", 32)
        self.font = ImageFont.truetype(os.path.join(FONTDIRS[0], self.font_name), 72)
        self.fontsmall = ImageFont.truetype(os.path.join(FONTDIRS[0], self.font_name), 32)
        self.fontcolor = (238, 161, 6)
        self.counter = 0
        self.update_interval = 10
        self.timezone_name = 'US/Mountain' # TODO: Probably make this argument or detect it
        self.timezone = pytz.timezone(self.timezone_name)

    def run(self):
        # Change to while True for long-running daemonized style worker thread with unlimited input
        while not self.q.empty():
            try:
                inpfile = self.q.get_nowait()
            except queue.Empty:
                logging.info("STOP thread run() DONE EMPTY QUEUE!!!")
                return
            try:
                self.workermethod(inpfile)
            except:
                logging.error("Error processing image {0}".format(inpfile))
                logging.error(traceback.format_exc())
            finally:
                # Always mark tasks done, even if exceptions thrown!
                # Otherwise queue.join() deadlocks waiting for last task(s) to
                # be done
                self.q.task_done()
            if self.counter % self.update_interval == 0:
                logging.info("Image {0} complete".format(self.counter))
        logging.info("STOP thread run() DONE!!!")
        return
    def workermethod(self, i):
        '''
           Worker method for processing a file off queue
        '''
        # logging.debug('start running thread')
        self.counter += 1
        if self.counter % self.update_interval == 0:
            logging.info("Image {0}: {1}".format(self.counter, i))
        real_filename = os.readlink(i)
        splitup = real_filename.split("_")
        unix_epoch_timestamp = splitup[-1].split(".")[0]

        file_datetime = datetime.fromtimestamp(float(unix_epoch_timestamp) / 1000)
        #file_datetime = file_datetime.replace(tzinfo=self.timezone)
        file_datetime = self.timezone.localize(file_datetime)
        date = file_datetime.strftime('%Y-%m-%d')
        tformatted = file_datetime.strftime('%I:%M:%S.%f %p %z %Z')

        # Open the image and resize it to HD format
        # 720p (1280x720 px)
        # 1080p (1920x1080 px)
        # RPi   (2048x1536 px) <-- Captured by phototimer
        # widthtarget = 1920
        # heighttarget = 1080
        img = Image.open(i)
        # downsample_ratio = float(widthtarget) / float(img.width)
        # img_downsampled = img.resize((widthtarget, int(round(img.height*downsample_ratio))),
        #                              resample=Image.LANCZOS)
        # img_downsampled = img_downsampled.crop((0, 0, widthtarget, heighttarget))

        # get a drawing context
        # draw = ImageDraw.Draw(img_downsampled)
        draw = ImageDraw.Draw(img)
        draw.text((0, img.height-150), date, self.fontcolor, font=self.fontsmall)
        draw.text((0, img.height-120), tformatted, self.fontcolor, font=self.font)
        # Save the output file to the symlink target filename
        img.save(real_filename)
        # logging.debug('stop running thread')

# Go through each file in current directory
def main():
    """
        Main function entrypoint.

        Set up a file queue and start thread processing!
    """
    logging.basicConfig(level=logging.INFO,
                        format='(%(threadName)-10s) %(message)s',
                       )
    # pylint: disable=C0103
    q = queue.Queue()
    for file_name in os.listdir(os.getcwd()):
        if file_name.endswith(".jpg"):
            q.put(file_name, False)
    # pylint: disable=W0612
    threadpool = [ThreadTimestamper(q) for t in range(POOLSIZE)]
    for thread in threadpool:
        thread.start()
    # block until all tasks are done
    q.join()

if __name__ == "__main__":
    main()
