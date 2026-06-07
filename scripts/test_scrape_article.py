import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
url = "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/senegal-team-profile-history"

req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
try:
    with urllib.request.urlopen(req, timeout=10) as response:
        html = response.read().decode('utf-8', errors='ignore')
        
    # Extract paragraphs using regex
    paragraphs = re.findall(r'<p[^>]*>(.*?)</p>', html, re.DOTALL)
    print(f"Found {len(paragraphs)} paragraphs:")
    for i, p in enumerate(paragraphs[:15]):
        # Strip HTML tags
        clean_p = re.sub(r'<[^>]+>', '', p).strip()
        if len(clean_p) > 20:
            print(f"\n[{i}] {clean_p}")
except Exception as e:
    print(f"Error: {e}")
