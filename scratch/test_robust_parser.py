import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def extract_og_image(html):
    # Find all meta tags
    meta_tags = re.findall(r'<meta\s+[^>]+>', html, re.IGNORECASE)
    for tag in meta_tags:
        # Check if it is og:image or twitter:image or name=image
        is_image_tag = (
            re.search(r'property\s*=\s*["\']og:image["\']', tag, re.IGNORECASE) or
            re.search(r'name\s*=\s*["\']og:image["\']', tag, re.IGNORECASE) or
            re.search(r'name\s*=\s*["\']image["\']', tag, re.IGNORECASE) or
            re.search(r'property\s*=\s*["\']twitter:image["\']', tag, re.IGNORECASE)
        )
        if is_image_tag:
            m = re.search(r'content\s*=\s*["\']([^"\']+)["\']', tag, re.IGNORECASE)
            if m:
                return m.group(1)
    return None

def test_team(slug):
    url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8', errors='ignore')
            img = extract_og_image(html)
            print(f"SLUG: {slug} -> IMAGE: {img}")
    except Exception as e:
        print(f"ERROR for {slug}: {e}")

print("Testing Morocco:")
test_team("morocco")

print("\nTesting Switzerland:")
test_team("switzerland")

print("\nTesting South Korea:")
test_team("korea-republic")

print("\nTesting Panama:")
test_team("panama")
