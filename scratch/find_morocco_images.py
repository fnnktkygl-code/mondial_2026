import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def find_images(slug):
    url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8', errors='ignore')
            # Extract digitalhub images
            images = re.findall(r'https://digitalhub\.fifa\.com/transform/[^\s"\'}]+', html)
            clean_images = set()
            for img in images:
                clean = img.split('?')[0].split('&')[0].replace('&amp;', '')
                clean_images.add(clean)
                
            print(f"\n--- IMAGES FOR {slug.upper()} ({len(clean_images)} found) ---")
            # Filter images that contain the slug
            matching = [img for img in clean_images if slug in img.lower()]
            print("Matching team name:")
            for img in sorted(matching):
                print("  ", img)
                
            # Filter images that contain 'profile'
            profiles = [img for img in clean_images if 'profile' in img.lower()]
            print("Matching 'profile':")
            for img in sorted(profiles)[:10]:
                print("  ", img)
    except Exception as e:
        print("Error:", e)

find_images("morocco")
find_images("switzerland")
