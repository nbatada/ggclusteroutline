"""Refresh public upstream inventory. Full source checkouts stay in the scratch directory."""
import argparse
import csv
import gzip
import hashlib
import io
import json
import re
import tarfile
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

REPOS = {
    "ggforce": "thomasp85/ggforce", "ggalt": "hrbrmstr/ggalt",
    "ggdensity": "jamesotto852/ggdensity", "ggpubr": "kassambara/ggpubr",
    "ggunchull": "sajuukLyu/ggunchull", "concaveman": "joelgombin/concaveman",
    "sf": "r-spatial/sf", "isoband": "r-lib/isoband", "ggplot2": "tidyverse/ggplot2",
}

def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "ggclusteroutline-M0-source-audit"})
    with urllib.request.urlopen(req, timeout=60) as response:
        return response.read()

def api(path):
    return json.loads(fetch("https://api.github.com/" + path))

def write_csv(path, rows):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=rows[0], lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scratch", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    args.scratch.mkdir(parents=True, exist_ok=True)
    packages = gzip.decompress(fetch("https://cloud.r-project.org/src/contrib/PACKAGES.gz")).decode()
    cran = dict(re.findall(r"^Package: (\S+)\nVersion: (\S+)", packages, re.M))
    rows = []
    issues = []
    for pkg, repo in REPOS.items():
        meta = api("repos/" + repo)
        head = api(f"repos/{repo}/commits/{meta['default_branch']}")
        sha = head["sha"]
        archive = fetch(f"https://codeload.github.com/{repo}/tar.gz/{sha}")
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            for member in tar:
                path = Path(member.name)
                relative = Path(*path.parts[1:])
                if not member.isfile() or ".." in path.parts or relative.is_absolute():
                    continue
                if relative.name in {"DESCRIPTION", "LICENSE", "NAMESPACE"} or relative.parts[:1] in {("R",), ("tests",),("vignettes",),("inst",)}:
                    target = args.scratch / pkg / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(tar.extractfile(member).read())
        desc = (args.scratch / pkg / "DESCRIPTION").read_text()
        field = lambda key: re.search("^" + key + r": (.*)", desc, re.M).group(1)
        rows.append(dict(package=pkg, cran_index_version=cran.get(pkg,"absent"), head_version=field("Version"),
                         head_license=field("License"), upstream=repo, sha=sha,
                         commit_date=head["commit"]["committer"]["date"], archived=meta["archived"],
                         open_issues_including_prs=meta["open_issues_count"],
                         has_testthat_dir=(args.scratch/pkg/"tests/testthat").is_dir(),
                         source_sha256=hashlib.sha256(archive).hexdigest()))
        for item in api(f"repos/{repo}/issues?state=open&per_page=10"):
            if "pull_request" not in item:
                issues.append(dict(package=pkg, number=item["number"],title=item["title"],url=item["html_url"]))
    query = api("search/repositories?q=ggclusteroutline+in:name&per_page=100")
    name = dict(observed_utc=datetime.now(timezone.utc).isoformat(),
                cran_exact=cran.get("ggclusteroutline"), cran_casefold=[p for p in cran if p.lower()=="ggclusteroutline"],
                github_total=query["total_count"], github_incomplete=query["incomplete_results"],
                github_returned=[r["full_name"] for r in query["items"]])
    write_csv(args.output/"inventory.csv",rows)
    write_csv(args.output/"issues.csv",issues)
    (args.output/"name-search.json").write_text(json.dumps(name,indent=2)+"\n")

if __name__ == "__main__":
    main()
