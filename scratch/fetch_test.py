import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
url = 'https://www.fifa.com/en/cat/4uvlj6vOoPQCT2hROuWX5r'

req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
try:
    with urllib.request.urlopen(req, timeout=10) as response:
        html = response.read().decode('utf-8', errors='ignore')
        
        print("Searching for category ID:")
        for m in re.finditer(r'4uvlj6vOoPQCT2hROuWX5r', html):
            start = max(0, m.start() - 100)
            end = min(len(html), m.end() + 100)
            print(f"Match at {m.start()}: ...{html[start:end]}...")
            
        print("\nSearching for API endpoints:")
        for m in re.finditer(r'cxm-api', html):
            start = max(0, m.start() - 100)
            end = min(len(html), m.end() + 100)
            print(f"Match at {m.start()}: ...{html[start:end]}...")
            
        # Let's see if there's any page content or list of JSON objects
        # We look for scripts containing project/article metadata
        print("\nSearching for script tags containing JSON data:")
        scripts = re.findall(r'<script[^>]*>(.*?)</script>', html, re.DOTALL)
        for idx, script in enumerate(scripts):
            if 'window[' in script or '{' in script:
                if 'tournaments' in script or 'articles' in script or 'preview' in script:
                    print(f"Script {idx}: length {len(script)}")
                    # print first 500 chars of JSON
                    print(script[:500])
except Exception as e:
    print("Error:", e)
