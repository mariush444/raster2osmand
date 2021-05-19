#!/bin/bash
# version 0.1 alpha
#
# convert raster maps
# OZI .map .ozf2
# GeoTiff GeoPDF
# to tiles in directoriy for OSMAND

# dir definitions
dir_main=dir_main
dir_tmp=${dir_main//_main/_tmp}

# Color Variables
green='\e[32m'
blue='\e[34m'
red='\e[31m'
clear='\e[0m'

# Color Functions
ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}

echo -ne "
creation of tiles for OSMAND (all files included subdirecories)
$(ColorGreen '1)') Ozi *.map
$(ColorGreen '2)') GeoTiff and GeoPDF *.tif *.pdf
$(ColorGreen '3)') Russian military maps calibrated in Ozi *.map - (001m/500k/200k/100k/050k/010k)
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read answer
        case $answer in
	        1) declare -a my_array=( "*.map")  ;;
	        2) declare -a my_array=( "*.tif" "*.pdf" )  ;;
            3) declare -a my_array=( "001m*.map" "500k*.map" "200k*.map" "100k*.map" "050k*.map" "010k*.map" ) ;;
            0) exit 0 ;;
            *) echo -e $red"Wrong option."$clear ;; #; menu;;
        esac

#delete old temp files if they exists
if test -f  tmp.tif; then rm tmp.tif; fi
if test -f  tmp.vrt; then rm tmp.vrt; fi
if test -d  dir_tmp; then rm -rf dir_tmp; fi

for i in "${my_array[@]}"
do
 for f in $(find . -name "$i")
    do
    gdalwarp -overwrite  -of GTiff $f tmp.tif
    gdal_translate -of vrt -expand rgba tmp.tif tmp.vrt
    gdal2tiles.py --xyz tmp.vrt $dir_tmp
    if test -f  tmp.vrt; then rm tmp.vrt; fi
    if test -f  tmp.tif; then rm tmp.tif; fi

# if dir_tmp doesn't exists it means there were errors during creation
    if test -d  dir_tmp; then
    echo "rsync started"
# copy files to existinf sets of tiles
    rsync -a --ignore-existing --remove-source-files $dir_tmp/ $dir_main/

# overwrite smaller by bigger files only
        echo "overwrite started"
        for f_tmp in $(find $dir_tmp/ -name '*.png')
            do
            f_main=${f_tmp//_tmp/_main}
            if [[ $(stat -c%s $f_main)  -lt  $(stat -c%s $f_tmp) ]]; then \cp $f_tmp $f_main ; fi
            done
        rm -rf dir_tmp
    fi
    done
done

# change png -> png.tile - OSMAND needs this
find $dir_main/ -iname "*.png" -exec rename .png .png.tile '{}' \;
