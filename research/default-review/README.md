# One-line default review · v0.1.1

The [comparison](default-comparison.png) uses the installed local v0.1.1 archive, SHA-256 `ed097be2afaf7f9601ee73536a959a65d12d1b4f4570bed894241ac5e9012290`. Each row shows the full point table with the same coordinates across panels. All geometry parameters use package defaults. The PBMC example selects Leiden 4. The other rows request all labels. The [script](compare.R) checks both atlas input hashes and records [counts from the built ggplot layers](counts.csv). Paths include point and segment primitives. Independent synthetic cloud, seed 293.

**Recommendation.** Hold publication pending a decision on the meaning of the default line. The strict default leaves both atlases blank. Islands draws every label but forms overlapping convex hulls across much of each map. Territory gives the clearest overview of the dominant regions and can omit dispersed cells or an entire label. At default settings territory drew 22/23 Yost and 13/18 NSCLC groups. The earlier benchmark used a different grid, bandwidth and mass. Its territory counts were 23/23 and 14/18.

The existing technical release audit applies to the original candidate. A change of default requires scientist approval of its coverage meaning, updated tests and documentation, and a new candidate check.
