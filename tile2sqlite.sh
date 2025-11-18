#!/bin/sh
#
# source/author: https://github.com/mariush444?tab=repositories
# create sqlitedb for OSMAND from tiles stored in directory
# directory should hase structure needed by OSMAND. It means zoom x y
# tiles in directory can be prpered by raster2osmand script
#
#

if test -z $1 ; then echo 'Usage: tile2sqlite dir_name'; echo 'dir_name - directory that you want to convert to sqlitedb' ; exit ; fi
if test ! -d $1 ; then echo "Directory $1 was not found" ; exit ; fi
if test -f $1.sqlitedb; then mv $1.sqlitedb $1_$(date +"%F_%H:%M:%S").sqlitedb; fi
Counter=0
Tstart=`date +%s`
Ttaken(){
dt=$(echo "$2 - $1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
}
#list 1st level dirs as zoom
my_dirs+=( $(ls -d -v   $1/*/ | sed "s/$1\///g" | sed 's/\///g' | sort -n) )
last_element=${#my_dirs[*]}-1

#create & initialize tables in sqlite
sqlite3 -batch $1.sqlitedb <<EOF
.timeout 2000
CREATE TABLE "android_metadata" ("locale" TEXT); INSERT INTO android_metadata (locale) VALUES("en_US");
CREATE TABLE "info" ("minzoom" INTEGER, "maxzoom" INTEGER,"ellipsoid" INTEGER, "inverted_y" INTEGER, "timeSupported" BOOL, "tilenumbering" TEXT );
CREATE TABLE "tiles" ("x" INTEGER NOT NULL, "y" INTEGER NOT NULL, "z" INTEGER NOT NULL, "s" INTEGER, "image" BLOB, PRIMARY KEY("x","y","z"));
CREATE INDEX "IND" ON "tiles" ("x","y","z");
INSERT INTO info (minzoom,maxzoom,ellipsoid, inverted_y, timeSupported, tilenumbering) VALUES ( '${my_dirs[0]}' ,'${my_dirs[$last_element]}',0,0,0,'');
EOF

# read png or png.tile files and inser them to db
for IN in $(find $1/ -name '*.png*')
do
IN_FILE=$IN
IN=${IN//./\/}
arrIN=(${IN//\// })
sqlite3  -batch $1.sqlitedb "INSERT INTO tiles(x,y,z,image) VALUES('${arrIN[2]}', ${arrIN[3]} ,'${arrIN[1]}',readfile('$IN_FILE'));"
Tend=`date +%s`; Ttaken $Tstart $Tend
Counter=$((Counter+1))
echo "File #"$Counter " " $dd"d "$dh"h "$dm"m "$ds"s" $IN
done

echo 'finito - created file is: ' $1.sqlitedb
