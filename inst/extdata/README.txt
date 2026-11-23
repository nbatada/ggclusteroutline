pbmc700.csv is the 700-row plotting table from the public Scanpy pbmc68k_reduced PBMC example (10x Genomics). x and y are the saved UMAP coordinates. NKG7 is expression from the stored raw slot. Numeric leiden IDs come from a separate weighted, undirected igraph Leiden partition of the stored graph, resolution 0.1, seed 17, two iterations. This example retains every row and omits barcodes.
https://scanpy.scverse.org/en/stable/generated/scanpy.datasets.pbmc68k_reduced.html

The underlying Fresh 68k PBMCs (Donor A) data are copyright 10x Genomics and licensed CC BY 4.0. Changes in this example include reduction to the Scanpy subset, plotting coordinates, a derived Leiden partition and selection of one expression feature.
https://www.10xgenomics.com/datasets/fresh-68-k-pbm-cs-donor-a-1-standard-1-1-0
https://creativecommons.org/licenses/by/4.0/
