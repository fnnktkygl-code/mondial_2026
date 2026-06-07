import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def debug_head(slug):
    url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8', errors='ignore')
            print(f"\n--- DEBUG HEAD FOR {slug.upper()} ---")
            print("HTML length:", len(html))
            
            # Print head section
            head_match = re.search(r'<head>(.*?)</head>', html, re.DOTALL | re.IGNORECASE)
            if head_match:
                head_content = head_match.group(1)
                print("Head content length:", len(head_content))
                # Find all meta tags in head
                meta_tags = re.findall(r'<meta[^>]*>', head_content, re.IGNORECASE)
                print(f"Found {len(meta_tags)} meta tags in head:")
                for tag in meta_tags:
                    print("  ", tag)
            else:
                print("No head section found!")
                
            # Search for any og: or image or twitter: in the whole HTML
            print("\nSearching for og: or twitter: in whole HTML:")
            for m in re.finditer(r'og:|twitter:|property="|name="', html, re.IGNORECASE):
                start = max(0, m.start() - 30)
                end = min(len(html), m.end() + 70)
                print(f"Match at {m.start()}: ...{html[start:end].strip()}...")
                
    except Exception as e:
        print(f"ERROR: {e}")

debug_head("morocco")
