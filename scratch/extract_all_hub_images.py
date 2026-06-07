import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
url = 'https://www.fifa.com/en/cat/4uvlj6vOoPQCT2hROuWX5r'

req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
try:
    with urllib.request.urlopen(req, timeout=15) as response:
        html = response.read().decode('utf-8', errors='ignore')
        print("HTML length:", len(html))
        
        # Search for any digitalhub image URLs
        # They usually look like https://digitalhub.fifa.com/transform/...
        img_urls = re.findall(r'https://digitalhub\.fifa\.com/transform/[^\s"\'}]+', html)
        print("Total Digitalhub image URLs found:", len(img_urls))
        
        # Standardize and deduplicate
        clean_urls = set()
        for img in img_urls:
            # remove query parameters like width, focuspoint, quality
            clean = img.split('?')[0].split('&')[0].replace('&amp;', '')
            clean_urls.add(clean)
            
        print("Deduplicated clean URLs:", len(clean_urls))
        for img in sorted(clean_urls):
            print("  ", img)
            
except Exception as e:
    print("Error:", e)
