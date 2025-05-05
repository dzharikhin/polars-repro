import pathlib

import polars as pl

if __name__ == "__main__":
    schema = dict([("row_id", pl.DataType.from_python(str)), *((f"value{i}", pl.DataType.from_python(float)) for i in range(48 * 48 * 10))])
    data1_file = pathlib.Path("data/data1.csv")
    with data1_file.open(mode="wt") as data1_file_descriptor:
        for index_value in range(3):
            data1_file_descriptor.write(f"r{index_value}{"," * (len(schema) - 1)}\n")
    data1 = pl.scan_csv(
        data1_file,
        schema=schema,
        has_header=False,
    )
    data2 = pl.LazyFrame(
        [],
        schema=schema,
    )
    whole_data = data1.update(data2, on="row_id", how="left", include_nulls=False)
    merged_data_file = pathlib.Path("data/merged_data.csv")
    merged_data = whole_data.collect(engine="streaming")
    merged_data.write_csv(merged_data_file)
