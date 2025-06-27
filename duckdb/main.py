import duckdb


data = duckdb.read_csv(
    "data/18-06-2025_NEGOCIOSAVISTA.txt",
    sep=";",
    parallel=True, #False para single thread
)


data2 = duckdb.sql("select MAX(CAST(replace(PrecoNegocio, ',', '.') AS FLOAT)) AS max_price, "
    "MIN(CAST(replace(PrecoNegocio, ',', '.') AS FLOAT)) AS min_price, "
    "SUM(CAST(replace(PrecoNegocio, ',', '.') AS FLOAT) * QuantidadeNegociada) / SUM(QuantidadeNegociada) AS average_weighted_price "
    "FROM data "
    "WHERE CodigoInstrumento = 'WDON25'"
)

final_values = data2.fetchall()


#print(f"{final_values[0][0]:.2f},{final_values[0][1]:.2f},{final_values[0][2]:.2f}")
