#!/bin/bash

if [[ $# -eq 0 ]]; then
 echo "Usage: $0 ./path/to/phototimer  /path/to/output.mp4 [true]" >&2
 echo "" >&2
 echo "\$1    path to directory containing phototimer images/*" >&2
 echo "" >&2
 echo "\$2    path to output mp4 file" >&2
 echo "       NOTE: This will overwrite the output file without asking!" >&2
 echo "" >&2
 echo "\$3    Pass 'true' to add time & date stamp to bottom left of all image frames before transcoding." >&2
 echo "       NOTE: This is an irreversible process and will overwrite the original images!" >&2
 echo "             It is recommended to run this on a copy of the originals" >&2
 echo "" >&2
 echo "The phototimer directory should have strftime pattern: " >&2
 echo "  'images/%YYYY/%M/%d/%H/%YYYY_%M_%d_%H_%r.jpg'" >&2
 echo "" >&2
 echo "Example: " >&2
 echo "  'images/2017/6/9/18/2017_6_9_18_1497034611561.jpg'" >&2
 echo "" >&2
 echo "Note that this script is very minimal and will NOT handle every ordering case correctly"
 echo "" >&2
 echo "It will also overwrite /path/to/output.mp4 without asking!" >&2
 exit 1
fi


PHOTOTIMER_DIR=$1
OUTPUT_MP4=$2
TIMESTAMP_FRAMES=$3
#DRY_RUN='echo DRY RUN:'
#DEBUG='true'

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
  python ~/bin/phototimer-images-timestamp-overlay-multithreaded.py
fi

echo "INFO: Begin Encoding frames to x264 video" >&2
echo "WARN: Will overwrite $OUTPUT_MP4 without asking!" >&2

$DRY_RUN time ffmpeg -y -r $framerate  -pattern_type sequence -i "%0${num_digits}d.jpg" -s $size -vcodec libx264 -vf "eq=contrast=${contrast}:brightness=${brightness}:saturation=${saturation}:gamma=${gamma}:gamma_weight=${gamma_weight}" -threads $num_cpu -filter_threads $filter_threads  $OUTPUT_MP4

# No brightness correction
#$DRY_RUN time ffmpeg -y -r $framerate  -pattern_type sequence -i "%0${num_digits}d.jpg" -s $size -vcodec libx264 -threads $num_cpu -filter_threads $filter_threads  $OUTPUT_MP4

popd
