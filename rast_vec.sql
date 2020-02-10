select * from vec_data.pnt;

-- Checking & Changing the coordinate system
select st_srid(geom) from vec_data.pnt;

alter table vec_data.plygon_2 alter column geom --Modifying the column
type geometry(multipolygon,32632)
using st_transform(geom,32632)

select st_transform(geom,32632) from vec_data.pnt; --Creating the new table

-- Creating a buffer
drop table vec_data.qlayer;
select st_buffer(geom,300) as buffer
into vec_data.qlayer
from vec_data.pnt
where id = 1;

-- Calculation the area
select st_area(buffer)::numeric from vec_data.qlayer;

-- Selection of the vactors which completely inside
drop table vec_data.qlayer;
select vec_data.plgon.*
into vec_data.qlayer
from vec_data.plgon, vec_data.plygon_2
where st_contains(plgon.geom, plygon_2.geom);


-- Calculation of the distance betwwen different objects
drop table vec_data.qlayer;
select st_distance(pnt.geom,plgon.geom)::integer as distance, pnt.id as pnt_id,
plgon.id as plgn_id, pnt.geom as geom
into vec_data.qlayer
from vec_data.pnt, vec_data.plgon;

-- Changing the coordinate system of the raster
select st_srid(rast) from rast_data.rast;

select st_transform(rast,32632) into rast_data.new_rast from rast_data.rast;

--alter table rast_data.rast rename column st_transform to rast;

-- Converting the pixels to polygons
drop table rast_data.qlayer;
SELECT x,y,val, geom As geom
into rast_data.qlayer
FROM (
SELECT dp.*
FROM rast_data.rast, LATERAL ST_PixelAsPolygons(rast,1) AS dp
) As foo where val > 0

select rast_data.qlayer.val as val_1, rast_data.qlayer_2.val as val_2, rast_data.qlayer.geom
into rast_data.qlayer_3
from rast_data.qlayer join rast_data.qlayer_2
on rast_data.qlayer_2.x = rast_data.qlayer.x and rast_data.qlayer_2.y = rast_data.qlayer.y

-- Selection of the pixels which are inside the polygons
drop table rast_data.qlayer_new
select rast_data.qlayer.*,plgon.number
into rast_data.qlayer_new
from rast_data.qlayer, vec_data.plgon
where st_intersects(qlayer.geom,plgon.geom);



-- Calculation the value of a point from 4 closest surrounded points
select pnt_temp.id, pnt_temp.geom, sum(c.temp*(1/c.dist))/sum((1/c.dist)) as temp_value,
avg(c.dist) as avg_dist
from vec_data.pnt_temp
cross join lateral(
        select temp, temp.geom <-> pnt_temp.geom as dist
        from vec_data.temp
        order by temp.geom <-> pnt_temp.geom
        limit 4
        ) c
group by pnt_temp.id,pnt_temp.geom

-- Register and add constraint to the table
select Populate_Geometry_columns('schema.table'::regclass)

-- Counting the number of the column
select count(*) from information_schema where table_name = 'table_name'
