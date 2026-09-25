"""One-off export of the {pharmaverseraw} raw datasets to data/raw/*.csv.

The plan named an R script (tools/export_raw.R); R is not available in the
environment where this was run, so the .rda files are read with pyreadr.

Usage:
    git clone --depth 1 https://github.com/pharmaverse/pharmaverseraw <src>
    pip install pyreadr
    python tools/export_raw.py <src>

Output conventions (so SAS can read the files with a plain DATA step):
- column names kept exactly as in the source (e.g. IT.AETERM);
- R NA written as an empty field;
- numeric columns holding only whole numbers written without a trailing ".0".
"""
import glob
import os
import sys

import pyreadr

src = sys.argv[1] if len(sys.argv) > 1 else "pharmaverseraw"
out = os.path.join(os.path.dirname(__file__), "..", "data", "raw")
os.makedirs(out, exist_ok=True)

for path in sorted(glob.glob(os.path.join(src, "data", "*.rda"))):
    for name, df in pyreadr.read_r(path).items():
        for col in df.select_dtypes("float").columns:
            s = df[col].dropna()
            if (s == s.round()).all():
                df[col] = df[col].astype("Int64")
        df.to_csv(os.path.join(out, f"{name}.csv"), index=False, na_rep="")
        print(f"{name}: {df.shape[0]} rows, {df.shape[1]} columns")
