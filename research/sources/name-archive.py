"""Check the archived names in addition to the live index and public GitHub query."""
import re
from urllib.request import urlopen

url = "https://cran.r-project.org/src/contrib/Archive/"
with urlopen(url, timeout=45) as response:
    body = response.read().decode()
names = re.findall(r'href="([A-Za-z][A-Za-z0-9.]*)/"', body)
assert len(names) > 1000, "archive index appears incomplete"
matches = [name for name in names if name.lower() == "ggclusteroutline"]
print(f"CRAN archive index {url}\nParsed package directories: {len(names)}\nCase-insensitive matches: {matches}")
