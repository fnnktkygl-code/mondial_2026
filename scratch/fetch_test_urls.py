import urllib.request
import re
import urllib.error

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def check_url(slug):
    # Try different URL patterns
    patterns = [
        f"https://www.fifa.com/en/articles/{slug}-team-profile-history",
        f"https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/{slug}-team-profile-history"
    ]
    
    for url in patterns:
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=5) as response:
                html = response.read().decode('utf-8', errors='ignore')
                og_image = re.search(r'<meta property="og:image" content="(.*?)"', html)
                img = og_image.group(1) if og_image else "No og:image"
                print(f"SUCCESS: {url} -> {img}")
                return True
        except urllib.error.HTTPError as e:
            print(f"FAILED {e.code}: {url}")
        except Exception as e:
            print(f"ERROR: {url} -> {e}")
    return False

print("Checking Senegal:")
check_url("senegal")

print("\nChecking England:")
check_url("england")

print("\nChecking Scotland:")
check_url("scotland")

print("\nChecking Curacao:")
check_url("curacao")
