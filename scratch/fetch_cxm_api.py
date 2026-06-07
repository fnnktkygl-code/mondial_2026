import urllib.request
import json

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
cat_id = '4uvlj6vOoPQCT2hROuWX5r'

endpoints = [
    f"https://cxm-api.fifa.com/fifaplusweb/api/sections/{cat_id}",
    f"https://cxm-api.fifa.com/fifaplusweb/api/categories/{cat_id}",
    f"https://cxm-api.fifa.com/fifaplusweb/api/content/{cat_id}",
    f"https://cxm-api.fifa.com/fifaplusweb/api/playlists/{cat_id}",
    f"https://cxm-api.fifa.com/fifaplusweb/api/tag/{cat_id}",
]

for url in endpoints:
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            res_data = response.read().decode('utf-8', errors='ignore')
            print(f"SUCCESS: {url}")
            print(f"  Length: {len(res_data)}")
            # Try to parse as JSON and print keys
            try:
                js = json.loads(res_data)
                print(f"  Keys: {list(js.keys())}")
                if 'items' in js:
                    print(f"  Number of items: {len(js['items'])}")
                elif 'content' in js:
                    print(f"  Number of content items: {len(js['content'])}")
            except Exception as e:
                print("  Failed to parse JSON:", e)
    except Exception as e:
        print(f"FAILED: {url} -> {e}")
