# raster2osmand
converter of raster files like
- OZI .map (.ozf2/jpg/gif/png)
- GeoTiff and GeoPDF

for OSMAND

**raster2tile.sh** script converts all raster files stored in directory and subdirectories
to tiles in directoriy supported by OSMAND (zoom x y)

This is bash interactive scirpt.
Prerequest: (gdal 3.2) should be already installed in OS.
used commands: gdalwarp gdal_translate gdal2tiles.py

Just start file from command line and choose options.
Then user can copy created the directory to OSMAND's tiles directory on mobile device.

**tile2sqlite.sh** script converts tiles in directoriy supported by OSMAND (zoom x y)
(e.g. prepered by raster2tile.sh) to sqlitedb file supported by OSMAND

This is bash scirpt.
Prerequest: (sqlite 3.8.6) should be already installed in OS.
used commands: readfile


Just start file from command line with directory name that should be converted into sqlitedb.
Then user can copy the file to OSMAND's tiles directory on mobile device.

