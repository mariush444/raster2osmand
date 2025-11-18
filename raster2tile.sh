#!/bin/bash
#
# source/author: https://github.com/mariush444?tab=repositories
# convert raster maps
# OZI .map .ozf2
# GeoTiff GeoPDF
# to tiles in directoriy for OSMAND

# dir definitions
dir_main=dir_main
dir_tmp=${dir_main//_main/_tmp}
PNG_Tiles='Y'
Counter=0
Zoom='Y'
Zoom_cmd=''

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
ColorRed(){
	echo -ne $red$1$clear
}
Ttaken(){
dt=$(echo "$2 - $1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
}

echo -ne "
creation of tiles for OSMAND (all files included subdirecories)
$(ColorGreen '1)') Ozi *.map
$(ColorGreen '2)') GeoTiff and GeoPDF *.tif *.pdf
$(ColorGreen '3)') Russian military maps calibrated in Ozi *.map with optimalization - (001m/500k/200k/100k/050k/010k)
$(ColorGreen '4)') Select file by yourself
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read answer
        case $answer in
            1) declare -a my_array=( "*.map")  ;;
            2) declare -a my_array=( "*.tif" "*.pdf" )  ;;
            3) declare -a my_array=( "001m*.map" "500k*.map" "200k*.map" "100k*.map" "050k*.map" "010k*.map" ) ;;
            4) read -p  "$(ColorRed 'select file or files e.g. map.pdf or *.tif: ')" my_file ; declare -a my_array=( "$my_file" )  ;;
            0) exit 0 ;;
            *) echo -e $red"Wrong option."$clear ;; #; menu;;
        esac

read -p  "$(ColorBlue 'OSMAND needs renaming png to png.tile. Should I do it? Y/n ')" PNG_Tiles ;
if [ $PNG_Tiles = 'Y' ] || [ $PNG_Tiles = 'y' ] ; then PNG_Tiles='Y' ; else PNG_Tiles='No' ; fi
echo $(ColorRed 'png -> png.tile - Your choise is: ') $PNG_Tiles

if [ $answer -eq 3 ] ; then
        read -p  "$(ColorBlue 'Do you want minimalized number of zooms and tiles? "n" means use default settings Y/n ')" Zoom ;
        if [ $Zoom = 'Y' ] || [ $Zoom = 'y' ] ; then Zoom='Y' ; else Zoom='No' ; fi
        echo $(ColorRed 'minimalization - Your choise is: ') $Zoom
fi

#delete old temp files if they exists
if test -f  tmp.tif; then rm tmp.tif; fi
if test -f  tmp.vrt; then rm tmp.vrt; fi
if test -d  $dir_tmp; then rm -rf $dir_tmp; fi
Tstart=`date +%s`
for i in "${my_array[@]}"
do
    if [ $Zoom = 'Y' ] ; then
        case $i in
        "001m*.map") Zoom_cmd='-z 9' ;;
        "500k*.map") Zoom_cmd='-z 10' ;;
        "200k*.map") Zoom_cmd='-z 11' ;;
        "100k*.map") Zoom_cmd='-z 12' ;;
        "050k*.map") Zoom_cmd='-z 13' ;;
        "010k*.map") Zoom_cmd='' ;;
        *) Zoom_cmd=''
        esac
    fi
 for f in $(find . -name "$i")
    do
# generally jpg and GeoPDF are proceed in different ways than GeoTiff and map/ozf2
    if [ `gdalinfo -nogcp -nomd -norat -noct -nofl  $f | grep ColorInterp=Palette | wc -l` -eq 0 ];
        then
        gdal2tiles.py --xyz -x $Zoom_cmd $f $dir_tmp
        else
        gdalwarp -overwrite  -of GTiff $f tmp.tif
        gdal_translate -of vrt -expand rgba tmp.tif tmp.vrt
        gdal2tiles.py --xyz -x $Zoom_cmd tmp.vrt $dir_tmp
        fi
# remove temp files
    if test -f  tmp.vrt; then rm tmp.vrt; fi
    if test -f  tmp.tif; then rm tmp.tif; fi

# if dir_tmp doesn't exists it means there were errors during creation
    if test -d  $dir_tmp; then
    echo $(ColorBlue 'rsync started')
# copy files to existinf sets of tiles
    rsync -a --ignore-existing --remove-source-files $dir_tmp/ $dir_main/
# overwrite smaller files by bigger ones only (no better idea for tiles at border were found by me)
        echo $(ColorBlue 'overwrite started')
        for f_tmp in $(find $dir_tmp/ -name '*.png')
            do
            f_main=${f_tmp//_tmp/_main}
            if [[ $(stat -c%s $f_main)  -lt  $(stat -c%s $f_tmp) ]]; then \cp $f_tmp $f_main ; fi
            done
        rm -rf $dir_tmp
        Counter=$((Counter+1))
        Tend=`date +%s`; Ttaken $Tstart $Tend
        echo "File #"$Counter " " $dd"d "$dh"h "$dm"m "$ds"s"
    fi
    done
done

# optimalization - delete file smaller than 10kB - generally they are rubbish
if [ $Zoom = 'Y' ] && test -d  $dir_main ; then  find $dir_main/ -iname "*.png" -size -10k -delete ; fi
# change png -> png.tile - OSMAND needs this
if [ $PNG_Tiles = 'Y' ] && test -d  $dir_main ; then  find $dir_main/ -iname "*.png" -exec rename .png .png.tile '{}' \; ; fi
# info at the end
if [ $Counter -eq 0 ] ; then echo $(ColorRed 'Nothing was done') ;
                        else
                        Tend=`date +%s`; Ttaken $Tstart $Tend
                        echo $(ColorRed 'finito - look into: ') $dir_main $(ColorRed ' -  Number of proceeded files: ') $Counter $(ColorRed ' - time consumed: ')$dd"d "$dh"h "$dm"m "$ds"s";
                        fi
