# Independent checks of M0 evidence

The architect replayed the four-method visual study in a separate scratch directory. Its 33 static outputs (inputs, figures, numerical results and version record) matched byte for byte. The field, stress and resize scripts reproduced all 16 CSV, PNG and SVG outputs in another scratch directory. The field PDF was rendered and visually inspected. Performance timings vary across runs. A separate replay reproduced all 21 native-layer timing configurations and their exported vertex counts, and completed all seven fresh-process memory cases.

Run `Rscript --vanilla research/review/check-exports.R` after the visual benchmark (xml2 and sp required). It reads actual SVG point and outline coordinates, checks that the relative locations of the points agree across methods, and counts target observations inside or on the emitted paths. It distinguishes open polylines from closed regions. The boundary tolerance is 0.02 SVG units to accommodate the two-decimal coordinate export. The even–odd rule handles holes. [Export counts](svg-coverage.csv)

An earlier narrow-grid density render produced two open lines. Treating them as polygons gave a spurious area and coverage. Run `Rscript --vanilla research/review/domain.R` with ggdensity 1.0.1 to reproduce the check. With the original ±2.8 domain both paths terminate on the grid boundary. With ±4 the estimator emits one closed contour. The matched plate uses the latter domain for all methods. [Path endpoints](domain.csv)

These checks concern reproducibility, plotting geometry and scope. The scientist's visual decision remains open.

A separate read-only reviewer inspected the plate, source records, specifications and raw tables. They independently reconciled the 100k/100 timing, vertices and memory values and the 199/200 HDR coverage. Their review used saved outputs; their default R library lacked ggforce. The architect performed the isolated executable replays described above using the temporary audit libraries. Scientist acceptance is pending.
