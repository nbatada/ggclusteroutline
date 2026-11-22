import csv
import os
import subprocess
import sys
import tempfile

with open("benchmarks/rc/supplied-baseline.csv","w") as f:
    out = csv.writer(f,lineterminator="\n")
    out.writerow(["implementation","n","groups","repeat","total_s","peak_mib"])
    for i in range(3):
        for method in ["base","package"]:
            with tempfile.TemporaryFile(mode="w+") as stdout:
                p = subprocess.Popen(["Rscript","--vanilla","benchmarks/rc/frozen-baseline.R",method],stdout=stdout)
                _, status, usage = os.wait4(p.pid,0)
                p.returncode = os.waitstatus_to_exitcode(status)
                if p.returncode:
                    raise SystemExit(p.returncode)
                stdout.seek(0)
                seconds = float(stdout.read().strip().splitlines()[-1])
                out.writerow([method,100000,100,i+1,seconds,
                              round(usage.ru_maxrss/(1048576 if sys.platform=="darwin" else 1024),1)])
