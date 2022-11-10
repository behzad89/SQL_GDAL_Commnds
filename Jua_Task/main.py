import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple

import boto3
import h3pandas
import numpy as np
import pandas as pd
import s3fs
import xarray as xr
from botocore import UNSIGNED
from botocore.config import Config

# Constants
BUCKET = "era5-pds"
DATE = "2022-05"
FILE = "precipitation_amount_1hour_Accumulation.nc"
KEY = f"{DATE.split('-')[0]}/{DATE.split('-')[1]}/data/{FILE}"
OUTPUT = "training/Jua_Task/{FILE}]"


def download_from_s3(bucket: str, file_path: str, output_path: str):
    """Download the files from the S3 bucket"""
    # Create an S3 access object
    s3 = boto3.client("s3", config=Config(signature_version=UNSIGNED))
    # Download the required file
    s3.download_file(Bucket=bucket, Key=file_path, Filename=output_path)


def _read_obj_from_s3(s3path: str) -> s3fs.core.S2File:

    fs_s3 = s3fs.S3FileSystem(anon=True)
    # s3path = 'era5-pds/2022/05/data/precipitation_amount_1hour_Accumulation.nc'
    remote_file_obj = fs_s3.open(s3path, mode='rb')
    return remote_file_obj


def convert_netCDF_to_dataframe(file_path: str, timestamp_filter: Optional[tuple] = None) -> pd.DataFrame:
    """Convert the downloaded netCDF file to """
    ds = xr.open_dataset(file_path)
    variable_name = list(ds.keys())[1]
    list_coords = list(ds.coords)

    if timestamp_filter is not None:
        filter = {list_coords[2]: slice(
            timestamp_filter[0], timestamp_filter[1])}
        ds = ds.sel(filter)

    latitudes = ds[list_coords[0]].values
    longitudes = ds[list_coords[1]].values
    times = ds[list_coords[2]].values
    ds_values = ds[variable_name]

    times_grid, latitudes_grid, longitudes_grid = [
        x.flatten() for x in np.meshgrid(times, latitudes, longitudes, indexing='ij')]
    df = pd.DataFrame({
        'time': times_grid,
        'latitude': latitudes_grid,
        'longitude': longitudes_grid,
        'precipitation_amount_1hour_Accumulation': ds_values.flatten()})

    return df


def _spatial_index(df: pd.DataFrame, resolution: int = 10) -> pd.DataFrame:
    dfh3 = df.h3.geo_to_h3(resolution=resolution,
                           lat_col="latitude", lng_col="longitude")
    return dfh3


def _save_to_parquet(df: pd.DataFrame, output_path: str):
    df.to_parquet(output_path)

# download_from_s3(BUCKET, KEY, OUTPUT)


# required args: year, month, file_name, start, resolution

# s3://era5-pds/2022/05/data/precipitation_amount_1hour_Accumulation.nc.
