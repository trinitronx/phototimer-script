#!/bin/bash
###
### phototimer-images-to-mp4.sh - Convert directory of time-lapse phototimer .jpg files into frame-timestamped .mp4
###
### Author: James Cuzella [@trinitronx](https://github.com/trinitronx/)
### Copyright (C) 2016  James Cuzella
### License: see the LICENSE file
###
SCRIPT="$0"

show_license_boilerplate() {
  local author='James Cuzella'
  echo "" >&2
  cat <<EOF >&2
${0}  Copyright (C) $(date +%Y)  ${author}
This program comes with ABSOLUTELY NO WARRANTY; for details type '${0} -l'.
This is free software, and you are welcome to redistribute it
under certain conditions; See 'LICENSE' file for details.
EOF
  echo "" >&2
}

show_license() {
 local path_to_license="$(dirname $(basename ${SCRIPT}))/LICENSE"
 echo "" >&2
 cat $path_to_license >&2
 echo "" >&2
}

# Function to show help text
show_help() {
  show_license_boilerplate

  cat << EOF >&2
Usage: ${SCRIPT} [-h] [-l] [-t] (-i input_phototimer_dir | ./path/to/phototimer )  (-o /path/to/output.mp4 | /path/to/output.mp4 )

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

EOF
}


# parse options (if any exist)
while getopts "hlvnti:o:" opt; do
    case "$opt" in
        h) show_help
           exit 1
           ;;
        l) show_license
           exit 1
           ;;
        v) DEBUG='true'
           # Output verbose debug messages
           ;;
        n) DRY_RUN='echo DRY RUN:'
           # If variable set, it adds echo prefix to all processing commands
           ;;
        t) TIMESTAMP_FRAMES='true'
           # If variable set, it adds echo prefix to all processing commands
           ;;
        i) INPUT_DIR=$OPTARG
           ;;
        o) OUTPUT_FILE=$OPTARG
           ;;
        *) show_help
           exit 1
           ;;
    esac
done
# Now remove the parsed options
shift $(( OPTIND - 1 ))

# Leftover arguments are numbered positional parameters
# If -i and -o flags are not passed, use first 2 positional parameters as input & output
PHOTOTIMER_DIR="${INPUT_DIR:-${1}}"
OUTPUT_MP4="${OUTPUT_FILE:-${2}}"

# 
# Error handling before we start...
if [ -z "$PHOTOTIMER_DIR" -o ! -d "$PHOTOTIMER_DIR/images" ]; then
    show_help
    echo "ERROR: Input file path must be a directory containing phototimer 'images/*' dir!" >&2
    exit 1
fi

if [ -z "$OUTPUT_MP4" ] || ! echo "$OUTPUT_MP4" | grep -Eq '.mp4$'; then
    show_help
    echo "ERROR: Output file $OUTPUT_MP4 must be an .mp4 file!" >&2
    exit 1
fi

if ( ! which ffmpeg 2>&1 >/dev/null ); then
  show_help
  echo "ERROR: Could not find ffmpeg command line utility installed on this system!" >&2
  echo "ERROR: ffmpeg is required to be in your \$PATH when using this script!" >&2
  echo "" >&2
  exit 1
fi

num_files=$(find ${PHOTOTIMER_DIR}/images/ -type f -iname '*.jpg' | wc -l | awk '{ print $1 }')
num_digits=$(echo -ne $num_files | wc -m | awk '{ print $1 }')

# This samples the first file only to detect number of paths
# It is an optimization to avoid having to deal with files with differing number of fields
# making the assumption that the phototimer app is generating them uniformly all the time
# If your source images are not all uniform in their file path naming scheme & field numbering, this logic falls apart,
# and sorting is more difficult given any arbitrary PHOTOTIMER_DIR path.
# The sed handles de-duplicating unnecessary slashes in the path to avoid field numbering issues
# The awk prints the number of fields minus 1 (the filename itself)
# This field numbering scheme is origin 1 just like `sort` uses for `-k`

num_filepath_fields=$(find ${PHOTOTIMER_DIR}/images/ -type f -iname '*.jpg' | head -n1 | sed s#//*#/#g | tr '/' ' ' | awk '{ print NF-1 }')

# This path has no filename at end, so no: NF-1, just NF

num_phototimer_dirpath_fields=$(echo -n ${PHOTOTIMER_DIR} | sed s#//*#/#g | tr '/' ' ' | awk '{ print NF }')

# /foo/bar/baz/phototimer/images/%YYYY/%M/%d/%H/%YYYY_%M_%d_%H_%r.jpg
# |----------------------|
#  phototimer_dirpath     
# |--------------------------------------------|--------------------|
#                        filepath_fields          filename
# sort_fields = abs(filepath_fields - phototimer_dirpath - 1)
# The -1 is to remove the 'images' field from the count so sort begins sorting on %YYYY

(( sort_num_fields = num_filepath_fields - num_phototimer_dirpath_fields - 1 ))

# Correction for how sort seems to count the leading empty field before the very first '/'
(( first_sort_pos = sort_num_fields + 1 ))
(( end_sort_pos = num_filepath_fields + 1 ))

# The num_filepath_fields should always be greater than num_phototimer_dirpath_fields
# However, the actual mathematical solution for number of fields is absolute value difference between:
#   |num_filepath_fields - num_phototimer_dirpath_fields|
# This should handle differences in relative size of each path, in the case that num_phototimer_dirpath_fields > num_filepath_fields
# for some strange reason.

# Absolute value function
abs() {
  [ $1 -lt 0 ] && echo $((-$1)) || echo $1
}
sort_num_fields=$(abs $sort_num_fields)


[ -n "$DEBUG" ] && echo "num_filepath_fields: $num_filepath_fields" >&2
[ -n "$DEBUG" ] && echo "num_files: $num_files" >&2
[ -n "$DEBUG" ] && echo "num_digits: $num_digits" >&2
[ -n "$DEBUG" ] && echo "printf: %0${num_digits}d" >&2

[ -n "$DEBUG" ] && echo "first_sort_pos: $first_sort_pos" >&2
[ -n "$DEBUG" ] && echo "end_sort_pos: $end_sort_pos" >&2

sort_field_flags=''
for n in $(seq $first_sort_pos $end_sort_pos); do
  sort_field_flags="${sort_field_flags} -k ${n},${n}g"
done

[ -n "$DEBUG" ] && echo "sort_field_flags: $sort_field_flags" >&2

[ ! -d ${PHOTOTIMER_DIR}/symlink_ordering/ ] && mkdir -p ${PHOTOTIMER_DIR}/symlink_ordering/

i=0
base_dir="$(echo -n "${PHOTOTIMER_DIR}" | sed s#//*#/#g)"
base_dir="${base_dir%%/}"

[ -n "$DEBUG" ] && echo "base_dir: $base_dir"

for x in $(find ${PHOTOTIMER_DIR}/images/ -type f -iname '*.jpg' | sed s#//*#/#g | sort -t '/' $sort_field_flags  ); do
  $DRY_RUN ln -sf "$x" "${base_dir}/symlink_ordering/$(printf "%0${num_digits}d" $i).jpg";
  (( i++ ));
done

## TODO: Make these command line options with defaults?
framerate=25
size=2048x1536
num_cpu=$(sysctl -n hw.ncpu)
(( filter_threads=num_cpu*2 ))

# Original
#contrast=1.2
#brightness=0.3
#saturation=2.0

# Meh?
#contrast=1.0
#brightness=0.907
#saturation=1.0

# Better, less gamma overwhitening
contrast=1.01
brightness=-0.090
saturation=1.6
gamma=3.7
gamma_weight=0.55


pushd ${PHOTOTIMER_DIR}/symlink_ordering/

if [[ "$TIMESTAMP_FRAMES" == 'true' ]]; then
  echo "INFO: Begin rendering date + timestamp to frames" >&2
  echo "WARN: This is an irreversible process and will overwrite the original images!" >&2
  echo "" >&2
  $DRY_RUN python ~/bin/phototimer-images-timestamp-overlay-multithreaded.py
fi

echo "INFO: Begin Encoding frames to x264 video" >&2
echo "WARN: Will overwrite $OUTPUT_MP4 without asking!" >&2

$DRY_RUN time ffmpeg -y -r $framerate  -pattern_type sequence -i "%0${num_digits}d.jpg" -s $size -vcodec libx264 -vf "eq=contrast=${contrast}:brightness=${brightness}:saturation=${saturation}:gamma=${gamma}:gamma_weight=${gamma_weight}" -threads $num_cpu -filter_threads $filter_threads  $OUTPUT_MP4

# No brightness correction
#$DRY_RUN time ffmpeg -y -r $framerate  -pattern_type sequence -i "%0${num_digits}d.jpg" -s $size -vcodec libx264 -threads $num_cpu -filter_threads $filter_threads  $OUTPUT_MP4

popd
