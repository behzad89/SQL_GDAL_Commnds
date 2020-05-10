-- New version of the script is available in the extract_pixel_values_from_db.sql

-- Creation of the separate tables
SELECT x,y,val as ymonstd_january, geom As geom
into soilmoisture.ymonstd_1
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,1) AS dp
) As foo;

-- ---------------------------------------------------
SELECT x,y,val as ymonstd_february, geom As geom
into soilmoisture.ymonstd_2
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,2) AS dp
) As foo;
-- ------------------------------------------------------
SELECT x,y,val as ymonstd_march, geom As geom
into soilmoisture.ymonstd_3
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,3) AS dp
) As foo;

-- -----------------------------------------------------
SELECT x,y,val as ymonstd_april, geom As geom
into soilmoisture.ymonstd_4
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,4) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_may, geom As geom
into soilmoisture.ymonstd_5
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,5) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_june, geom As geom
into soilmoisture.ymonstd_6
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,6) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_july, geom As geom
into soilmoisture.ymonstd_7
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,7) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_august, geom As geom
into soilmoisture.ymonstd_8
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,8) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_september, geom As geom
into soilmoisture.ymonstd_9
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,9) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_october, geom As geom
into soilmoisture.ymonstd_10
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,10) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_november, geom As geom
into soilmoisture.ymonstd_11
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,11) AS dp
) As foo;
-- -----------------------------------------------------
SELECT x,y,val as ymonstd_december, geom As geom
into soilmoisture.ymonstd_12
FROM (
SELECT dp.*
FROM soilmoisture.uerra_harmonie_nordics_sm_l3_ymonstd,
     LATERAL ST_PixelAsPolygons(rast,12) AS dp
) As foo;
-- Adding the ID column
alter table soilmoisture.ymonstd_1 add column fid_std serial not null primary key;

-- Joining tables together
select ymonstd_1.fid_std, ymonstd_1.ymonstd_january,ymonstd_2.ymonstd_february,ymonstd_3.ymonstd_march,
       ymonstd_4.ymonstd_april,ymonstd_5.ymonstd_may,ymonstd_6.ymonstd_june,
       ymonstd_7.ymonstd_july,ymonstd_8.ymonstd_august,ymonstd_9.ymonstd_september,
       ymonstd_10.ymonstd_october, ymonstd_11.ymonstd_november, ymonstd_12.ymonstd_december
       --,ymonstd_1.geom
into soilmoisture.ymonstd_l3
from soilmoisture.ymonstd_1
join soilmoisture.ymonstd_2 on ymonstd_1.x = ymonstd_2.x and ymonstd_1.y = ymonstd_2.y
join soilmoisture.ymonstd_3 on ymonstd_1.x = ymonstd_3.x and ymonstd_1.y = ymonstd_3.y
join soilmoisture.ymonstd_4 on ymonstd_1.x = ymonstd_4.x and ymonstd_1.y = ymonstd_4.y
join soilmoisture.ymonstd_5 on ymonstd_1.x = ymonstd_5.x and ymonstd_1.y = ymonstd_5.y
join soilmoisture.ymonstd_6 on ymonstd_1.x = ymonstd_6.x and ymonstd_1.y = ymonstd_6.y
join soilmoisture.ymonstd_7 on ymonstd_1.x = ymonstd_7.x and ymonstd_1.y = ymonstd_7.y
join soilmoisture.ymonstd_8 on ymonstd_1.x = ymonstd_8.x and ymonstd_1.y = ymonstd_8.y
join soilmoisture.ymonstd_9 on ymonstd_1.x = ymonstd_9.x and ymonstd_1.y = ymonstd_9.y
join soilmoisture.ymonstd_10 on ymonstd_1.x = ymonstd_10.x and ymonstd_1.y = ymonstd_10.y
join soilmoisture.ymonstd_11 on ymonstd_1.x = ymonstd_11.x and ymonstd_1.y = ymonstd_11.y
join soilmoisture.ymonstd_12 on ymonstd_1.x = ymonstd_12.x and ymonstd_1.y = ymonstd_12.y

-- Creation of one table
select ymonmean_l3.*,ymonstd_l3.*,  ymonmin_l3.*, ymonmax_l3.*
into soilmoisture.uerra_harmonie_nordics_sm_l3
from soilmoisture.ymonmax_l3
join soilmoisture.ymonmin_l3 on ymonmax_l3.fid_max = ymonmin_l3.fid_min
join soilmoisture.ymonmean_l3 on ymonmax_l3.fid_max = ymonmean_l3.fid_mean
join soilmoisture.ymonstd_l3 on ymonmax_l3.fid_max = ymonstd_l3.fid_std;

-- Modifying the created table

alter table soilmoisture.uerra_harmonie_nordics_sm_l3 drop column fid_max;
alter table soilmoisture.uerra_harmonie_nordics_sm_l3 drop column fid_std;
alter table soilmoisture.uerra_harmonie_nordics_sm_l3 drop column fid_min;
alter table soilmoisture.uerra_harmonie_nordics_sm_l3 rename column fid_mean to fid;

alter table soilmoisture.uerra_harmonie_nordics_sm_l3 add primary key (fid);
SELECT Populate_Geometry_Columns('soilmoisture.uerra_harmonie_nordics_sm_l3'::regclass);

