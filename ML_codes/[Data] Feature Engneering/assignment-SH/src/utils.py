# This script includes the required function to implement SH assignment
# Author: B.Valipour sh. <b.valipour.sh@gmail.com>
# Date 15.07.2022


# Generic imports

import math
import os
import sys
from itertools import combinations
from typing import List, Optional, Union

import geopandas
import numpy
import pandas
import rasterio
from rasterio import mask
from rasterio.merge import merge

# SH-related imports
from sentinelhub import (
    CRS,
    BBox,
    DataCollection,
    DownloadRequest,
    MimeType,
    SentinelHubCatalog,
    SentinelHubDownloadClient,
    SentinelHubRequest,
    SHConfig,
    bbox_to_dimensions,
    filter_times,
)

# Constants
import constants as cts


def fetch_ndvi_image(
    geom_path: str,
    crs: Union[int, str],
    resolution: int,
    start_date: pandas.Timestamp,
    end_date: pandas.Timestamp,
    out_dir: str,
    sh_config: SHConfig,
):

    """Fetch NDVI data from SentinelHUB ProcessAPI"""
    # preparing output directory
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    # Prepareing the request
    polygon = geopandas.read_file(geom_path)
    region_bounds = list(polygon.total_bounds)
    region_bbox = BBox(bbox=region_bounds, crs=CRS(crs))
    region_size = bbox_to_dimensions(region_bbox, resolution=resolution)

    evalscript_NDVI = cts.EVALSCRIPT_NDVI
    acq_dict = cts.RAW_DICT_S2
    acq_data_dict = cts.DATA_S2

    acq_dict["input"]["bounds"] = {
        "properties": {"crs": region_bbox.crs.opengis_string},
        "bbox": list(region_bbox),
    }

    acq_data_dict["dataFilter"]["timeRange"] = {
        "from": start_date.isoformat(),
        "to": end_date.isoformat(),
    }

    acq_dict["input"]["data"] = [acq_data_dict]
    acq_dict["output"]["width"] = region_size[0]
    acq_dict["output"]["height"] = region_size[1]
    acq_dict["evalscript"] = evalscript_NDVI

    # Send the request
    download_request = DownloadRequest(
        request_type="POST",
        url=cts.API_ENDPOINT,
        post_values=acq_dict,
        data_type=MimeType.TIFF,
        headers={"content-type": "application/json"},
        use_session=True,
    )

    client = SentinelHubDownloadClient(config=sh_config)
    data = client.download(download_request)

    # Save result
    h, w = data.shape
    b_count = 1
    minx, miny, maxx, maxy = region_bounds
    transform = rasterio.transform.from_bounds(minx, miny, maxx, maxy, w, h)
    profile = rasterio.profiles.Profile()
    profile.update(
        driver="GTiff",
        width=w,
        height=h,
        transform=transform,
        count=b_count,
        crs=rasterio.crs.CRS.from_epsg(crs),
        dtype="float32",
    )

    output_file = out_dir + "/ndvi.tif"
    with rasterio.open(output_file, "w", **profile) as target:
        target.write(numpy.expand_dims(data, 0))
    print("The image was saved!")


class image_stats:
    def __init__(self, shp_path: str, img_path: str):
        """Class to calculate the image stats based on the determined geometry file"""

        self.geom = geopandas.read_file(shp_path)
        self.src = rasterio.open(img_path)

    def get_statistics(self, id: Union[int, str]) -> tuple:

        if type(id) is int:
            shape = self.geom[self.geom.ID == id].geometry[id]
            out_image, _ = mask.mask(self.src, [shape], crop=True, nodata=-10)
            out_image = out_image.reshape(1, -1)
            out_mask = numpy.all(out_image == -10, axis=0)
            relevant_pixels = out_image[..., ~out_mask]
            output = relevant_pixels
        else:
            shape = self.geom[self.geom.LAND_TYPE == id]
            features = []
            for i in shape.iterrows():
                geom = i[1]["geometry"]
                out_image, _ = mask.mask(self.src, [geom], crop=True, nodata=-10)
                out_image = out_image.reshape(1, -1)
                out_mask = numpy.all(out_image == -10, axis=0)
                relevant_pixels = out_image[..., ~out_mask]
                features.append(relevant_pixels)

            concat_feat = numpy.concatenate(features, axis=1)
            output = concat_feat

        min_ndvi = round(output.min(), 6)
        max_ndvi = round(output.max(), 6)
        mean_ndvi = round(output.mean(), 6)
        std_ndvi = round(output.std(), 6)

        return (min_ndvi, max_ndvi, mean_ndvi, std_ndvi)

    def get_closest_pair(self, ids: List[int], creterias: List[str]) -> tuple:

        if type(creterias) is not list:
            raise TypeError(f"Creteria should be determined in a list")
        elif len(creterias) < 1:
            raise ValueError(f"Determine at least one creteria")
        elif len(creterias) > 2:
            raise ValueError(f"More than two creterias are not supported")
        else:
            if creterias[0] == "min":
                creteria_id_1 = 0
            elif creterias[0] == "max":
                creteria_id_1 = 1
            elif creterias[0] == "mean":
                creteria_id_1 = 2
            elif creterias[0] == "std":
                creteria_id_1 = 3

            if len(creterias) == 2:

                if creterias[1] == "min":
                    creteria_id_2 = 0
                elif creterias[1] == "max":
                    creteria_id_2 = 1
                elif creterias[1] == "mean":
                    creteria_id_2 = 2
                elif creterias[1] == "std":
                    creteria_id_2 = 3

                creteria_1_list = []
                creteria_2_list = []
                for i in ids:
                    stats = self.get_statistics(i)
                    creteria_1_list.append(stats[creteria_id_1])
                    creteria_2_list.append(stats[creteria_id_2])
                    creterias_list = [
                        i[0] + i[1]
                        for i in zip(
                            combinations(creteria_1_list, 2),
                            combinations(creteria_2_list, 2),
                        )
                    ]
                dict_values = {
                    k: i for i, k in zip(combinations(ids, 2), creterias_list)
                }
                output = dict_values[
                    min(
                        creterias_list,
                        key=lambda t: math.sqrt(
                            (t[0] - t[1]) ** 2 + (t[2] - t[3]) ** 2
                        ),
                    )
                ]
            else:
                creteria_ls = [self.get_statistics(i)[creteria_id_1] for i in ids]
                dict_values = {
                    k: i
                    for i, k in zip(combinations(ids, 2), combinations(creteria_ls, 2))
                }
                output = dict_values[
                    min(combinations(creteria_ls, 2), key=lambda t: abs(t[0] - t[1]))
                ]

        return output

