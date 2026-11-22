"""Replay existing CellStyle Yost and NSCLC inputs. Write aggregate measurements only."""
import csv
import os
import subprocess
import sys
from pathlib import Path

source = Path(os.environ.get("CELLSTYLE", Path.home() / "git/cellstyle")) / "design_evidence"
out = Path("benchmarks/rc")
inputs = [("Yost", "cs-yost-full-bands", "yost-bcc-tcell-bands"),
          ("NSCLC", "cs-nsclc-bands", "nsclc-tnk-bands")]
with (out / "real-memory.csv").open("w") as f:
    writer = csv.writer(f, lineterminator="\n")
    writer.writerow(["dataset","peak_mib_full_replay"])
    for name, dataset, reference in inputs:
        p = subprocess.Popen(["Rscript","--vanilla",str(out/"real.R"),name,
                              f"/tmp/{dataset}/cells.csv.gz",str(source/reference),str(out)])
        _, status, usage = os.wait4(p.pid,0)
        p.returncode = os.waitstatus_to_exitcode(status)
        if p.returncode:
            raise SystemExit(p.returncode)
        writer.writerow([name,round(usage.ru_maxrss/(1048576 if sys.platform=="darwin" else 1024),1)])
