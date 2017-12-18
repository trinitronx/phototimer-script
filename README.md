# phototimer-scripts

Helper scripts to process [phototimer][1] images


# Usage


    ./phototimer-images-to-mp4.sh ./path/to/phototimer  /path/to/output.mp4 [true]
    
    $1    path to directory containing phototimer images/*
    
    $2    path to output mp4 file
           NOTE: This will overwrite the output file without asking!
    
    $3    Pass 'true' to add time & date stamp to bottom left of all image frames before transcoding.
           NOTE: This is an irreversible process and will overwrite the original images!
                 It is recommended to run this on a copy of the originals
    
    The phototimer directory should have strftime pattern:
      'images/%YYYY/%M/%d/%H/%YYYY_%M_%d_%H_%r.jpg'
    
    Example:
      'images/2017/6/9/18/2017_6_9_18_1497034611561.jpg'
    
    Note that this script is very minimal and will NOT handle every ordering case correctly
    
    It will also overwrite /path/to/output.mp4 without asking!

# License

[GPLv3][gplv3]

[1]: https://github.com/alexellis/phototimer
[gplv3]: https://choosealicense.com/licenses/gpl-3.0/

