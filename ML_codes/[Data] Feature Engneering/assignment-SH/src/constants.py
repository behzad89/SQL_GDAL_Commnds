# SH constants
API_ENDPOINT = "https://services.sentinel-hub.com/api/v1/process"

RAW_DICT_S2 = {
    "input":
        {
            "bounds": {},
            "data": []
        },
    "output":
        {
            "responses": [ {
                "identifier": "default",
                "format": {
                    "type": "image/tiff"
                },
                "logo": False
            } ]
        }
    }

DATA_S2 = {
    "dataFilter":
        {
            "timeRange": {},
        },
    "type": "S2L1C"
}

# Evalscripts
EVALSCRIPT_NDVI = """
    //VERSION=3
    function setup() {
        return {
            input: [
                {
                    bands: ["B04", "B08"],
                    units: ["REFLECTANCE", "REFLECTANCE"]
                }
            ],
            output: {bands: 1, sampleType: "FLOAT32"}
        };
    }
    function evaluatePixel(sample) {
        let ndvi = index(sample.B08, sample.B04);
        return [ndvi];
    }
"""


