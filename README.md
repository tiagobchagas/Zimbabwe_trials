
---

## Key figure

> Se o arquivo existe em `Plots/Map.jpg`, o GitHub renderiza automaticamente:

![Map of Zimbabwe trials](Plots/Map.jpg)

---

## Quick start (reproducibility)

1. **Requisitos**
   - R ≥ 4.3
   - Pacotes principais: `tidyverse`, `data.table`, `ggplot2`, `rmarkdown`, `patchwork`, `cowplot`, `readr`, `readxl`, `here`, `janitor`, `kableExtra`, e os pacotes usados no BPSI (listar aqui: `brms`/`rstanarm`/`bayesplot`/etc., conforme seu pipeline).

2. **Executar a análise**
   - Abra `Zimbabwe_trials.Rproj`
   - Rode/teça o `Zimbabwe_analysis.Rmd`:
     ```r
     rmarkdown::render("Zimbabwe_analysis.Rmd", clean = TRUE)
     ```
   - Figuras serão salvas em `Plots/` e objetos em `Saves/`.

3. **Reprodutibilidade**
   - Fixe versões de pacotes (ex.: via `renv`) e registre a sessão no final do Rmd:
     ```r
     sessionInfo()
     ```

---

## Data & code availability

- **Data**: colocar aqui o link/DOI (Figshare/Zenodo), se público.  
- **Code**: este repositório.

---

## How to cite

> Preprint/Manuscript (em revisão, BMC Plant Biology)

Chagas JTB, Araújo MS, Martinez M, Pavan JPS, Leles EP, Santos MF, Diers BW, Goldsmith P, Mwadzingeni L, Mukaro R, Henderson A, Mutimaamba C, Scaboo A, Pinheiro JB. *Leveraging probabilistic models to enhance cultivar recommendation in Zimbabwe*. BMC Plant Biology, in review, 2025.

---

## License

Specify a license (e.g., MIT, GPL-3.0). Example:

