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
