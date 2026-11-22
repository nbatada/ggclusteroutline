"""Run each benchmark in a fresh R process; ru_maxrss includes input, points and PNG."""
import csv
import os
from pathlib import Path
import subprocess
import sys
import tempfile

out = Path("benchmarks/rc/performance.csv")
design = [(10000, 1), (10000, 100), (100000, 100), (1000000, 10), (100000, 1000)]
with out.open("w") as handle:
    writer = csv.writer(handle, lineterminator="\n")
    writer.writerow("n k method scope cold_s cached_s build_s draw_s vertices drawn_groups repeat peak_mib".split())
    for n, k in design:
        for method, scope in [("territory", "all"), ("tight", "one"), ("islands", "all")]:
            for repetition in range(1, 4):
                with tempfile.TemporaryFile(mode="w+") as output:
                    p = subprocess.Popen(["Rscript", "--vanilla", "benchmarks/rc/performance.R",
                                          str(n), str(k), method, scope], stdout=output)
                    _, status, usage = os.wait4(p.pid, 0)
                    p.returncode = os.waitstatus_to_exitcode(status)
                    if p.returncode:
                        raise SystemExit(p.returncode)
                    output.seek(0)
                    fields = output.read().strip().splitlines()[-1].split(",")
                    assert len(fields) == 10
                    mib = usage.ru_maxrss / (1048576 if sys.platform == "darwin" else 1024)
                    writer.writerow([*fields, repetition, round(mib, 1)])
                    handle.flush()
