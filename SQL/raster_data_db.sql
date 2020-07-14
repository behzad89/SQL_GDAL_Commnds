-- Working with raster data in the DB --

-- Extract the pixel values for the all the pixel
-- Extract the pixel value for all the pixels with coordinates
-- extract the pixel value for specific points
-- Convert pixels to polygons



-- Extract the pixel values for the all the pixel
SELECT x, y, ST_Value(rast, 1, x, y) As red,
	ST_Value(rast, 2, x, y) As green, ST_Value(rast, 3, x, y) As blue
FROM terramonitor.terramonitor_ee_fall_10m CROSS JOIN
generate_series(1, 1000) As x CROSS JOIN generate_series(1, 1000) As y
WHERE x <= ST_Width(rast) AND y <= ST_Height(rast);

-- Extract the pixel value for all the pixels with coordinates
SELECT x, y, ST_AsText(ST_PixelAspoint(rast, x, y))
    , ST_Value(rast, 1, x, y) As red,
	ST_Value(rast, 2, x, y) As green, ST_Value(rast, 3, x, y) As blue,
       ST_Value(rast, 4, x, y) As nir
FROM terramonitor.terramonitor_ee_fall_10m CROSS JOIN
generate_series(1,1000) As x CROSS JOIN generate_series(1,1000) As y
WHERE x <= ST_Width(rast) AND y <= ST_Height(rast);

-- extract the pixel value for specific points
SELECT ST_AsText(geom) as geom,
       ST_Value(rast, 1, point.geom ) As red,
       ST_Value(rast, 2, x, y) As green, ST_Value(rast, 3, x, y) As blue,
       ST_Value(rast, 4, x, y) As nir
FROM point, terramonitor.terramonitor_ee_fall_10m
WHERE ST_Intersects(rast,point.geom)
 and ST_Value(rast, 1, point.geom ) is not null;

-- Convert pixels to polygons
SELECT x,y,val as ymonstd_january, ST_AsText(geom) As geom
FROM (
SELECT dp.*
FROM terramonitor.terramonitor_ee_fall_10m,
     LATERAL ST_PixelAsPolygons(rast,1) AS dp
) As foo;