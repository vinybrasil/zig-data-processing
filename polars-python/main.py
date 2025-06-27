# comente para multithread

# import os
# os.environ["POLARS_MAX_THREADS"] = "1" 

import polars as pl


expression1 = (
    pl.scan_csv(
        "data/18-06-2025_NEGOCIOSAVISTA.txt",
        separator=";",
    )
    .select(["CodigoInstrumento", "PrecoNegocio", "QuantidadeNegociada"])
    .filter(pl.col("CodigoInstrumento") == "WDON25")
)

data = expression1.collect()
data2 = data.with_columns(pl.col("PrecoNegocio").str.replace(',', '.').cast(pl.Float64))

max_price = data2['PrecoNegocio'].max()
min_price = data2['PrecoNegocio'].min()
average_weighted_price = (data2['PrecoNegocio'] * data2['QuantidadeNegociada']).sum()/ (data2['QuantidadeNegociada']).sum()

print(f'{max_price:.2f},{min_price:.2f},{average_weighted_price:.2f}')

