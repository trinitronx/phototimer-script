# phototimer-scripts

Helper scripts to process [phototimer][1] images.

- *`phototimer-images-to-mp4.sh`*:
  - Sort a path of timestamped phototimer images by frame timestamp, create a symlinked directory structure. Then, optionally add a timestamp overlay to each frame. Finally convert into a time-lapse `.mp4` (x264) video.
- *`phototimer-images-timestamp-overlay-multithreaded.py`*:
  - Python helper script to add timestamp overlay to each frame.  Uses multithreading to speed up image processing.  Dependencies are listed in `requirements.txt`.
- *`phototimer-images-timestamp.py`*:
  - Alternate python helper script to add timestamp overlay to each frame.  Does *_NOT_* use multithreading.  Dependencies are listed in `requirements.txt`, minus `multithreading`.

## Sponsor

If you find this project useful and appreciate my work,
would you be willing to click one of the buttons below to Sponsor this project and help me continue?

- <noscript><a href="https://github.com/sponsors/trinitronx">:heart: Sponsor</a></noscript>
- <noscript><a href="https://liberapay.com/trinitronx/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a></noscript>
- <noscript><a href="https://paypal.me/JamesCuzella"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif" border="0" alt="Donate with PayPal" /></a></noscript>

Every little bit is appreciated! Thank you! 🙏


# Dependencies / Requirements

- *`phototimer-images-timestamp-overlay-multithreaded.py`*:
  - `python3`: `>= 3.7` preferred ([for threading bugfixes][2])
    - `os`
    - `datetime`
    - `threading`
  - `pip` packagess:
    - multiprocess
    - Pillow
    - pytz
- *`phototimer-images-timestamp.py`*:
  - `python3`
    - `os`
    - `datetime`
  - `pip` packagess:
    - Pillow
    - pytz
- *`phototimer-images-to-mp4.sh`*:
  - `bash`
  - `ffmpeg`
  - `find`
  - CPU core detection requires one of the following commands:
    - `sysctl -n hw.ncpu`
    - `nproc --all`

# Usage


    ./phototimer-images-to-mp4.sh  Copyright (C) 2017  James Cuzella
    This program comes with ABSOLUTELY NO WARRANTY; for details type './phototimer-images-to-mp4.sh -l'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; See 'LICENSE' file for details.
    
    Usage: ./phototimer-images-to-mp4.sh [-h] [-l] [-t] (-i input_phototimer_dir | ./path/to/phototimer )  (-o /path/to/output.mp4 | /path/to/output.mp4 )
    
    Sort a path of timestamped phototimer images by frame timestamp, create a symlinked directory structure, 
    optionally add a timestamp overlay to each frame, and convert into a time-lapse .mp4 (x264) video.
    
    All arguments except input directory and output file path are optional and have defaults.
    
    
        -h                              Help. Display this usage message and exit.
    
        -l                              Show LICENSE file and exit.
    
        -v                              Output verbose debug messages.
    
        -n                              Dry run.
                                        Echo all processing operations, but do not actually do anything.
    
        -t                              Add timestamp image overlay to each frame based on image naming scheme.
                                        The default configuration is to add time & date stamp to bottom left of 
                                        all image frames before transcoding.
                                        NOTE: This is an irreversible process and will edit & overwrite the original images!
                                              It is recommended to run this on a copy of the originals
                                        See Example below for timestamp file path naming scheme
    
        -i /path/to/phototimer/images/  Input path to directory containing time-lapse phototimer 'images/*'
    
        -o /path/to/output.mp4          Output filename to use for .mp4 time-lapse video
                                        NOTE: This script will overwrite the output file without asking!
    
    
        The phototimer directory should have strftime pattern: 
    
            'images/%YYYY/%M/%d/%H/%YYYY_%M_%d_%H_%r.jpg'
    
        Example:
    
            'images/2017/6/9/18/2017_6_9_18_1497034611561.jpg'
    
        Note that this script is very minimal and will NOT handle every ordering case correctly
    
        It will also overwrite /path/to/output.mp4 without asking!


# License

[GPLv3][gplv3]

[1]: https://github.com/alexellis/phototimer
[2]: https://codewithoutrules.com/2017/08/16/concurrency-python/
[gplv3]: https://choosealicense.com/licenses/gpl-3.0/

