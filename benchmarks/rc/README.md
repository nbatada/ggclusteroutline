# v0.1.0 release-candidate validation

These are local macOS measurements on an Apple M5 MacBook Air (10 cores, 32 GB RAM, R 4.5.3). Geometries use all cells in each benchmark. The package includes the public 700-cell example so its feasibility gate can run after installation.

## PBMC and ggforce

`verify-pbmc.R` checks the package's default output on the full UMAP. Selecting Leiden 4 produces two polygons of combined area 1.578884, covering 48 selected and zero other cell centres. The split matches the two manual convex hulls to 1e-8 absolute area. The source data have no manual island variable in the geometry call. The actual ggforce 0.5.0 unpadded mark exported one polygon. [README figure generator](figure.R) · [full UMAP PDF](pbmc700.pdf)

## Real benchmark replay

`real.R` checks the SHA-256 of the exact compressed inputs prepared by the original CellStyle examples. It computes territory afresh from all coordinates and assignments. For each original label, it compares cell-centre inclusion against the saved **Python CellStyle** paths and the **ggforce SVG** paths using the same even–odd rule. Existing large-data ggforce polygons were reused for this replay. No large source matrices or per-patient tables are distributed here. See the source examples in CellStyle's `design_evidence/yost-bcc-tcell-bands` and `design_evidence/nsclc-tnk-bands` for derivation and the R/Python cross-check.

| Dataset | Requested / drawn | In own RC territory | In own ggforce hull | RC vs Python containment differences |
|---|---:|---:|---:|---:|
| Yost BCC | 23 / 23 | 22,515 / 33,106 | 33,106 / 33,106 | 1 / 761,438 |
| NSCLC | 18 / 14 | 395,316 / 622,791 | 622,791 / 622,791 | 0 / 11,210,238 |

The 256 × 256 grid, 97% mass and bandwidth equal to 1.2% of the original map span follow the CellStyle transfer experiment. The result measures fit to supplied labels on these embeddings. The Yost difference was a single cell in the cluster-2 comparison. A missing territory is a valid diagnostic. [Yost by cluster](Yost-containment.csv) · [NSCLC by cluster](NSCLC-containment.csv)

## Performance and memory

The [raw measurements](performance.csv) include all three repeats for each configuration. Input generation is deterministic and excluded from geometry time. Each repeat starts in a fresh R process. Cold and cached geometry include validation and key hashing. Build time uses frozen geometry plus all points. Draw time includes gtable construction and a 720 × 720 Cairo PNG draw. Peak RSS covers the entire child, including data generation, both geometry calls and point rendering. It is process memory, not geometry allocation. Some strict tight runs abstain; their vertex and drawn-group counts make this visible. The grid is fixed at 96 nodes per axis for this bounded test. At high K, a coarse grid can erase small territories. The measured grid is not a general recommendation.

A separate [supplied-component comparison](supplied-baseline.csv) uses the same 100k points and 100 annotated components for the package and a direct base convex hull plus ggplot2 path. Timings include geometry, build and rendering. This is the M0 relative overhead gate for already supplied components. The comparison does not apply that budget to density estimation or automatic island finding.

### Measured medians

| Cells | Labels | Method / selection | Groups drawn | Cold geometry (s) | Cache hit (s) | PNG draw (s) | Peak RSS (MiB) |
|---:|---:|---|---:|---:|---:|---:|---:|
| 100,000 | 100 | territory / all | 100 | 0.388 | 0.011 | 0.270 | 241 |
| 100,000 | 100 | tight / one | 0 | 0.231 | 0.011 | 0.259 | 224 |
| 100,000 | 100 | islands / all | 100 | 0.123 | 0.011 | 0.270 | 224 |
| 1,000,000 | 10 | territory / all | 10 | 1.195 | 0.108 | 2.417 | 692 |
| 1,000,000 | 10 | tight / one | 0 | 0.758 | 0.109 | 2.358 | 696 |
| 1,000,000 | 10 | islands / all | 10 | 0.718 | 0.110 | 2.340 | 646 |
| 100,000 | 1000 | territory / all | 149 | 3.956 | 0.012 | 0.271 | 241 |
| 100,000 | 1000 | tight / one | 0 | 1.538 | 0.012 | 0.262 | 226 |
| 100,000 | 1000 | islands / all | 1000 | 0.499 | 0.012 | 0.312 | 258 |

With supplied components, the package took 0.459 s versus 0.375 s for the direct reference (1.22×). Peak RSS was 1.00× the reference. Both are below the proposed 2× overhead ceilings. The zeroes above indicate real strict-mode abstentions. At 100,000 cells / 1,000 labels, 149 territories had sufficient support at this grid resolution; occupied-island mode drew all 1,000.

## Replay

Install the package first. For the optional checks and figures also install ggforce, xml2, svglite, patchwork, Cairo-enabled PNG support and Python 3. Run from the repository root:

```sh
Rscript --vanilla benchmarks/rc/verify-pbmc.R
Rscript --vanilla benchmarks/rc/figure.R
python3 benchmarks/rc/run-performance.py
python3 benchmarks/rc/run-baseline.py
```

For the licensed local CellStyle inputs, the following commands read the original files and write aggregate results only. Set `CELLSTYLE` to the existing checkout:

```sh
Rscript --vanilla benchmarks/rc/real.R Yost /tmp/cs-yost-full-bands/cells.csv.gz "$CELLSTYLE/design_evidence/yost-bcc-tcell-bands" benchmarks/rc
Rscript --vanilla benchmarks/rc/real.R NSCLC /tmp/cs-nsclc-bands/cells.csv.gz "$CELLSTYLE/design_evidence/nsclc-tnk-bands" benchmarks/rc
```

[Full-map Yost comparison](Yost-full-map.png) · [Full-map NSCLC comparison](NSCLC-full-map.png). Both figures show every observation with common limits across the three panels. The reference shows the stored benchmark partition, the second panel uses frozen ggforce vertices, and the third uses freshly computed package territories. Run `real-figures.R` with the same inputs and CellStyle checkout. [Fresh-process memory including full input reading and polygon comparison](real-memory.csv) was measured by `run-real.py`.
