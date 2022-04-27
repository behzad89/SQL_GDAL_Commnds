import psycopg2
import geopandas as gpd
from geocube.api.core import make_geocube

# TODO: Pass this to .env file or cli arguments
_db_host = '*****'
_db_name = '****'
_db_port = 5432
_db_user = '*****'
_db_password = '******'
_db_schema = 'esri_demo'
_db_table = 'esri_cell_predictions_fi'


class DB:
    def __init__(self):
        self.conn = None
        self.geom = 'geometry'
        self.id = 'cc_cellnumber'

    def init_db(self, dbname=_db_name, user=_db_user, password=_db_password, host=_db_host,
                port=_db_port):
        try:
            connection_parameters = {
                'host': host,
                'port': port,
                'dbname': dbname,
                'user': user,
                'password': password
            }
            self.conn = psycopg2.connect(**connection_parameters)
        except psycopg2.DatabaseError:
            print('Could not connect to database {0} at {1} on port {2} with provided credentials.'
                  .format(dbname, host, port))
        except psycopg2.OperationalError as e:
            print('Could not connect to database {0} at {1} on port {2} with provided credentials.'
                  .format(dbname, host, port))

    def read_postgis(self, schema, table):
        return gpd.read_postgis(sql='''select
                                cc_cellnumber,
                                geometry,
                                bam_height_m,
                                bam_dbh_cm,
                                basal_area_m2_ha,
                                total_volume_m3_ha,
                                commercial_volume_m3_ha,
                                timber_volume_m3_ha,
                                fiber_volume_m3_ha,
                                pine_bam_height_m,
                                pine_bam_dbh_cm,
                                pine_basal_area_m2_ha,
                                pine_total_volume_m3_ha,
                                pine_commercial_volume_m3_ha,
                                pine_timber_volume_m3_ha,
                                pine_fiber_volume_m3_ha,
                                spruce_bam_height_m,
                                spruce_bam_dbh_cm,
                                spruce_basal_area_m2_ha,
                                spruce_total_volume_m3_ha,
                                spruce_commercial_volume_m3_ha,
                                spruce_timber_volume_m3_ha,
                                spruce_fiber_volume_m3_ha,
                                birch_bam_height_m,
                                birch_bam_dbh_cm,
                                birch_basal_area_m2_ha,
                                birch_total_volume_m3_ha,
                                birch_commercial_volume_m3_ha,
                                birch_timber_volume_m3_ha,
                                birch_fiber_volume_m3_ha,
                                other_deciduous_bam_height_m,
                                other_deciduous_bam_dbh_cm,
                                other_deciduous_basal_area_m2_ha,
                                other_deciduous_total_volume_m3_ha,
                                other_deciduous_commercial_volume_m3_ha,
                                other_deciduous_timber_volume_m3_ha,
                                other_deciduous_fiber_volume_m3_ha 
                                from {0}.{1}'''.format(schema, table),
                                con=self.conn, geom_col=self.geom, index_col=self.id)

    def output_raster(self, gdf):
        out_grid = make_geocube(vector_data=gdf, resolution=(-16, 16))
        return out_grid.rio.to_raster("test.tif")


if __name__ == '__main__':
    print("Test GeoCube rasterize...")
    gcube = DB()
    gcube.init_db()
    gcube.output_raster(gdf=gcube.read_postgis(schema=_db_schema, table=_db_table))

