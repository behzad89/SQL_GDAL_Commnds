import argparse
import logging
import os
from typing import Optional

import boto3
import h3pandas
import numpy as np
import pandas as pd
import s3fs
import xarray as xr
from botocore import UNSIGNED
from botocore.config import Config

# Constants
logger = logging.getLogger(__name__)
BUCKET = "era5-pds"
# OUTPUT = "training/Jua_Task/{FILE}]"


def _download_from_s3(bucket: str, file_path: str, output_path: str):
    """Download the files from the S3 bucket"""
    # Create an S3 access object
    s3 = boto3.client("s3", config=Config(signature_version=UNSIGNED))
    # Download the required file
    s3.download_file(Bucket=bucket, Key=file_path, Filename=output_path)


def _read_obj_from_s3(s3path: str):
    # e.g. s3path = 'era5-pds/2022/05/data/precipitation_amount_1hour_Accumulation.nc'
    fs_s3 = s3fs.S3FileSystem(anon=True)
    remote_file_obj = fs_s3.open(s3path, mode='rb')
    return remote_file_obj    


def convert_netCDF_to_parquet(file_path, output_path: str, timestamp_filter: Optional[tuple] = None, resolution: int = 10):
    """Convert the downloaded netCDF file to parquet """

    # Read file & extract corrosponding info
    logger.info("Reading climate file from %s",BUCKET)
    ds = xr.open_dataset(file_path,engine='h5netcdf')
    variable_name = list(ds.keys())[1]
    list_coords = list(ds.coords)

    if timestamp_filter is not None:
        logger.info("Filtering datestampe between %s-%s", timestamp_filter[0], timestamp_filter[1])
        filter = {list_coords[2]: slice(
            timestamp_filter[0], timestamp_filter[1])}
        ds = ds.sel(filter)

    latitudes = ds[list_coords[0]].values
    longitudes = ds[list_coords[1]].values
    times = ds[list_coords[2]].values
    ds_values = ds[variable_name].values

    # Convert to DataFrame
    logger.info("Converting data to DataFrame")
    times_grid, latitudes_grid, longitudes_grid = [
        x.flatten() for x in np.meshgrid(times, latitudes, longitudes, indexing='ij')]
    df = pd.DataFrame({
        'time': times_grid,
        'latitude': latitudes_grid,
        'longitude': longitudes_grid,
        'precipitation_amount_1hour_Accumulation': ds_values.flatten()})

    # Apply spatial index
    logger.info("Apply Spatial Index")
    dfh3 = df.h3.geo_to_h3(resolution=resolution, lat_col="latitude", lng_col="longitude")
    return dfh3.to_parquet(output_path)


def main():
    parser = argparse.ArgumentParser(description="Transform the data into the Apache Parquet datasource")

    parser.add_argument("--file_name", help="The file name e.g. precipitation_amount_1hour_Accumulation.nc",type=str, required=True)
    parser.add_argument("--date", help="Timestamp of data as YYYY_MM",type=str, required=True)
    parser.add_argument("--fileter_date", nargs=2,metavar=('StartDate', 'EndDate'), help="Filtering by timestamp.",type=str, default=(None,None))
    parser.add_argument("--resolution", help="Hierarchical geospatial index of your choice.",type=int,default=10,required=False)
    parser.add_argument("--output_path", help="Path to save the parquet file.",type=str,required=True)

    args = parser.parse_args()
    FILE = args.file_name
    StartDate, EndDate = args.fileter_date
    RESOLUTION = args.resolution
    OUTPATH = args.output_path
    DATE = args.date

    KEY = f"{DATE.split('-')[0]}/{DATE.split('-')[1]}/data/{FILE}"

    # FILE_PATH = _read_obj_from_s3(os.path.join(BUCKET, KEY))
    FILE_PATH = _read_obj_from_s3(BUCKET+'/'+KEY)
    convert_netCDF_to_parquet(FILE_PATH, OUTPATH, (StartDate, EndDate), RESOLUTION)
    
    logger.info("File was save in %s",OUTPATH)

if __name__ == "__main__":
    main()

# download_from_s3(BUCKET, KEY, OUTPUT)


# required args: year, month, file_name, start, resolution

# s3://era5-pds/2022/05/data/precipitation_amount_1hour_Accumulation.nc.
