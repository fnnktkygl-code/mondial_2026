import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
url = 'https://www.fifa.com/en/articles/morocco-team-profile-history'

req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
try:
    with urllib.request.urlopen(req, timeout=10) as response:
        html = response.read().decode('utf-8', errors='ignore')
        print("HTML length:", len(html))
        
        # Print all meta tags
        meta_tags = re.findall(r'<meta[^>]*>', html)
        print("Total meta tags:", len(meta_tags))
        print("Some meta tags:")
        for tag in meta_tags[:40]:
            print("  ", tag)
            
        # Search for any image URLs on digitalhub.fifa.com
        img_urls = re.findall(r'https://digitalhub\.fifa\.com/[^\s"\'}]+', html)
        print("\nDigitalhub URLs found:", len(img_urls))
        for img in sorted(set(img_urls))[:20]:
            print("  ", img)
            
except Exception as e:
    print("Error:", e)
