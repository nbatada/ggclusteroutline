#!/usr/bin/env python3
"""Measure RSS of fresh, one-case R competitor processes with os.wait4()."""

import csv
import os
import sys
import subprocess
from pathlib import Path

if sys.platform not in {"darwin", "linux"}:
    raise SystemExit("RSS units are supported here on macOS and Linux only")
CASES = [
    ("ggforce::geom_mark_hull", 10_000, 1),
    ("ggforce::geom_mark_hull", 10_000, 10),
    ("ggforce::geom_mark_hull", 100_000, 1),
    ("ggforce::geom_mark_hull", 100_000, 100),
    ("ggdensity::geom_hdr_lines", 10_000, 1),
    ("ggdensity::geom_hdr_lines", 10_000, 10),
    ("ggdensity::geom_hdr_lines", 100_000, 100),
]
RESULTS = Path("research/scaling/results")
RESULTS.mkdir(parents=True, exist_ok=True)

rows = []
for method, n, groups in CASES:
    command = ["Rscript", "research/scaling/benchmark_competitors.R", "--case", f"{method},{n},{groups}", "1"]
    process = subprocess.Popen(command)
    _, status, usage = os.wait4(process.pid, 0)
    process.returncode = os.waitstatus_to_exitcode(status)
    if process.returncode:
        raise SystemExit(process.returncode)
    rows.append({"method": method, "n": n, "groups": groups, "peak_rss_bytes": usage.ru_maxrss * (1 if sys.platform == "darwin" else 1024)})

with (RESULTS / "competitor_peak_rss.csv").open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=rows[0].keys(), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
