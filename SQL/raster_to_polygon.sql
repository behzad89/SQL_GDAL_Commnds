-- Multi bands raster
-- Separate raster in DB


-- This script includes the way to conver the raster to polygon with old and new method with image with several bands

with january
as (
SELECT x,y,val as ymonspd_january, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,1) AS dp
) As foo
    ), february
as(
SELECT x,y,val as ymonspd_february, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,2) AS dp
) As foo
), march
as (
   SELECT x,y,val as ymonspd_march, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,3) AS dp
) As foo
    ),april
as (
    SELECT x,y,val as ymonspd_april, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,4) AS dp
) As foo
    ),may
as (
    SELECT x,y,val as ymonspd_may, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,5) AS dp
) As foo
    ),june
as (
    SELECT x,y,val as ymonspd_june, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,6) AS dp
) As foo
    ),july
as (
    SELECT x,y,val as ymonspd_july, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,7) AS dp
) As foo
    ),august
as (
    SELECT x,y,val as ymonspd_august, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,8) AS dp
) As foo
    ),september
as (
    SELECT x,y,val as ymonspd_september, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,9) AS dp
) As foo
    ),october
as (
    SELECT x,y,val as ymonspd_october, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,10) AS dp
) As foo
    ),november
as (
    SELECT x,y,val as ymonspd_november, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,11) AS dp
) As foo
    ),december
as (
    SELECT x,y,val as ymonspd_december, geom As geom
FROM (
SELECT dp.*
FROM behzad.wind_speed,
     LATERAL ST_PixelAsPolygons(rast,12) AS dp
) As foo
    )
select ymonspd_january, ymonspd_february,ymonspd_march,
       ymonspd_april, ymonspd_may, ymonspd_june, ymonspd_july,
       ymonspd_august, ymonspd_september, ymonspd_october,
       ymonspd_november, ymonspd_december, january.geom
into behzad.wind_spd_vec
from january
join february on january.x = february.x and january.y = february.y
join march on january.x = march.x and january.y = march.y
join april on january.x = april.x and january.y = april.y
join may on january.x = may.x and january.y = may.y
join june on january.x = june.x and january.y = june.y
join july on january.x = july.x and january.y = july.y
join august on january.x = august.x and january.y = august.y
join september on january.x = september.x and january.y = september.y
join october on january.x = october.x and january.y = october.y
join november on january.x = november.x and january.y = november.y
join december on january.x = december.x and january.y = december.y;

alter table behzad.wind_spd_vec add column fid serial not null primary key;
SELECT Populate_Geometry_Columns('behzad.wind_spd_vec'::regclass);


-- the same script with different data in DB
with dem 
as(
SELECT ogc_fid, geom as geom,
       ST_Value(rast, 1, sardinia_fire_archive.geom ) As dem_value
FROM fire_eu.sardinia_fire_archive, topography.dem_32632
WHERE ST_Intersects(rast,sardinia_fire_archive.geom)
 and ST_Value(rast, 1, sardinia_fire_archive.geom ) is not null
	),
aspect
as(
	SELECT ogc_fid, geom as geom,
       ST_Value(rast, 1, sardinia_fire_archive.geom ) As aspect_value
FROM fire_eu.sardinia_fire_archive, topography.aspect_32632
WHERE ST_Intersects(rast,sardinia_fire_archive.geom)
 and ST_Value(rast, 1, sardinia_fire_archive.geom ) is not null
),
slope
as(
	SELECT ogc_fid, geom as geom,
       ST_Value(rast, 1, sardinia_fire_archive.geom ) As slope_value
FROM fire_eu.sardinia_fire_archive, topography.slope_32632
WHERE ST_Intersects(rast,sardinia_fire_archive.geom)
 and ST_Value(rast, 1, sardinia_fire_archive.geom ) is not null
),
tpi
as(
SELECT ogc_fid, geom as geom,
       ST_Value(rast, 1, sardinia_fire_archive.geom ) As tpi_value
FROM fire_eu.sardinia_fire_archive, topography.tpi_32632
WHERE ST_Intersects(rast,sardinia_fire_archive.geom)
 and ST_Value(rast, 1, sardinia_fire_archive.geom ) is not null
),
tri
as(
SELECT ogc_fid, geom as geom,
       ST_Value(rast, 1, sardinia_fire_archive.geom ) As tri_value
FROM fire_eu.sardinia_fire_archive, topography.tri_32632
WHERE ST_Intersects(rast,sardinia_fire_archive.geom)
 and ST_Value(rast, 1, sardinia_fire_archive.geom ) is not null
)
select dem.ogc_fid, dem.dem_value, aspect.aspect_value, slope.slope_value,
tpi.tpi_value, tri.tri_value, dem.geom into topography.topograhic_point_data from dem 
join aspect on dem.ogc_fid=aspect.ogc_fid
join slope on dem.ogc_fid=slope.ogc_fid
join tpi on dem.ogc_fid=tpi.ogc_fid
join tri on dem.ogc_fid=tri.ogc_fid

-- Register and add constraint & primary key to the table
select Populate_Geometry_columns('topography.topograhic_point_data'::regclass)
alter table topography.topograhic_point_data add primary key (ogc_fid);
