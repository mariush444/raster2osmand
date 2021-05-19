# raster2osmand
convert raster files like
- OZI .map (.ozf2)
- GeoTiff and GeoPDF
to tiles in directoriy for OSMAND 

This is bash scirpt.
Prerequest:
gdalwarp gdal_translate gdal2tiles.py should be already installed in OS.

Just start file from command line and choose option.
Script grabs all files from directory and subdiretories and converts them and collects into one directory of tiles

Then user can copy to OSMAND's tiles directory on mobile device.

