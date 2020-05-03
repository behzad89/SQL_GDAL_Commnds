-- intersecting the raster using the polygon
select rid, rast into soilmoisture.test
from terramonitor.terramonitor_ee_fall_10m
where st_intersects(rast,
    ST_SetSRID(
        ST_GeomFromText(
            'POLYGON((2449372.994 8198942.494,2568666.616 8200781.823,2572345.274 8115384.407,2448847.472 8113807.839,2449372.994 8198942.494))'),3857));
