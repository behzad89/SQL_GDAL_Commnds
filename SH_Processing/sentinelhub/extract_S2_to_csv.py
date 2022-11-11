import argparse
import logging
import multiprocessing
import os
import sys
from functools import partial

import coloredlogs
import numpy as np
import pandas as pd
import rasterio as rio
from dask.distributed import Client
from rasterio.plot import reshape_as_image, reshape_as_raster
from rasterio.windows import Window, bounds, from_bounds

# client = Client(threads_per_worker=1, n_workers=1)


logger = logging.getLogger(__name__)
coloredlogs.install(
    fmt="%(levelname)s:%(message)s",
    level="INFO",
    level_styles=dict(
        info=dict(color="white"), error=dict(color="red"), warning=dict(color="yellow")
    ),
)


def _get_index(array):
    return np.nonzero(array[1, ...])


def _get_coord_X(index, offset, size):
    return index * size + offset + (size / 2)


def _get_coord_Y(index, offset, size):
    return index * (-1 * size) + offset - (size / 2)


def _get_blocks(in_path):
    src = rio.open(in_path)
    windows = [window for ji, window in src.block_windows()]
    src.close()
    return windows


def raster2csv(window, input_path, output_path, labels):
    src = rio.open(input_path)
    Px_size = src.transform[0]
    minx, miny, maxx, maxy = bounds(window, src.transform)
    img_block = src.read(window=window)

    (y_index, x_index) = _get_index(img_block)
    x_coords = _get_coord_X(x_index, minx, Px_size)
    y_coords = _get_coord_Y(y_index, maxy, Px_size)
    X = pd.Series(x_coords)
    Y = pd.Series(y_coords)
    CC_number = (
        np.floor(Y / Px_size) * 100000 + np.floor(X / Px_size)
    ).convert_dtypes()

    df_coords = pd.DataFrame(
        {
            "X": X.astype("float32", copy=False),
            "Y": Y.astype("float32", copy=False),
            "CC_number": CC_number.astype("int", copy=False),
        }
    )

    if len(df_coords) > 0:
        df_values = pd.DataFrame(
            reshape_as_image(img_block).reshape(-1, 11), columns=labels
        )
        df_values = df_values[(df_values.T != 0).any()].reset_index(drop=True)
        df = pd.concat([df_coords, df_values], axis=1)
        df.to_csv(f"{output_path}/{minx}_{miny}.csv", index=False)

    src.close()


def main():
    """
    Convert one or multiple raster images to a Pandas dataframe and export results as CSV file.
    maintaner: Behzad Valipour Sh. <bvs@collectivecrunch.com>
    Date: 20.05.2022
    """

    parser = argparse.ArgumentParser(description="Raster2CSV")

    parser.add_argument(
        "--input_path", help="Path to the location of the raster", type=str
    )
    parser.add_argument(
        "--output_path", help="Path to the location of the raster", type=str
    )
    parser.add_argument(
        "--season", help="For which season the mosaic prepared", type=str
    )

    args = parser.parse_args()
    input_path = args.input_path
    output_path = args.output_path
    season = args.season

    if input_path is None:
        logger.error("Please enter the path to raster!")
        sys.exit()

    if output_path is None:
        logger.error("Please enter the path to save the CSVs!")
        sys.exit()

    if season is None:
        logger.error("Please enter the season the mosaic prepared!")
        sys.exit()

    labels = [
        "season_red",
        "season_green",
        "season_blue",
        "season_red_e1",
        "season_red_e2",
        "season_red_e3",
        "season_nir1",
        "season_nir2",
        "season_swir1",
        "season_swir2",
        "cloudless",
    ]

    labels_ = [string.replace("season", season) for string in labels]
    windows = _get_blocks(input_path)

    with multiprocessing.Pool(processes=30) as pool:
        func_partial = partial(
            raster2csv, input_path=input_path, output_path=output_path, labels=labels_
        )
        pool.map(func_partial, windows)


#     func_partial = partial(
#         raster2csv, input_path=input_path, output_path=output_path, labels=labels_
#     )
#     client.map(func_partial, windows)


if __name__ == "__main__":
    main()
