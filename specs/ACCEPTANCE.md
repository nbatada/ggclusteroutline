# Acceptance contract (thresholds to finalize after M0 measurements)
P0 correctness: no errors for valid degenerate groups; polygons valid and closed; disjoint islands preserved when justified; group association and facet isolation exact; no mutation of input; deterministic repeat runs; output visually legible at small publication sizes; SVG/PDF export inspection.
P0 visuals: scientist reviews 2–4 controlled methods per difficult case with identical points, colors, axes and sizes. Record selected/rejected designs and reasons in design_evidence/. No universal superiority claims without measurements.
P1 performance: compare geometry time, ggplot build time, render time, peak memory, and exported polygon complexity at N=1e4,1e5,1e6 and K=1,10,100,1000 where feasible. Explicit hardware, versions, seeds, repeated runs. Targets chosen after baseline audit.
P1 cache: identical inputs hit, changed membership/coordinates/params miss, version invalidates; bounded memory; cached and fresh geometry equal; hash cost measured.
Compatibility: multiple ggplot2 releases as practical; CRAN R CMD check; examples and testthat; snapshot images checked with tolerance and manual review.
Stop conditions: competitor already satisfies objectives; impossible visual case without user choice; memory/runtime explosion; unsupported transformations; ambiguous data semantics. Report rather than hide.
