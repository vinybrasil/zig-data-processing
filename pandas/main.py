import pandas as pd

data = pd.read_csv(
    "data/18-06-2025_NEGOCIOSAVISTA.txt",
    sep=";",
    usecols=["CodigoInstrumento", "PrecoNegocio", "QuantidadeNegociada"],
)


data2 = data[data["CodigoInstrumento"] == "WDON25"]

data2.loc[:, "PrecoNegocio"] = data2["PrecoNegocio"].str.replace(",", ".").astype(float)


max_price = data2["PrecoNegocio"].max()
min_price = data2["PrecoNegocio"].min()
average_weighted_price = (
    data2["PrecoNegocio"] * data2["QuantidadeNegociada"]
).sum() / (data2["QuantidadeNegociada"]).sum()


print(f"{max_price:.2f},{min_price:.2f},{average_weighted_price:.2f}")
