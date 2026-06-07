import urllib.request
import urllib.error
import re
import json
import os
import time

REMAINING_TEAMS = {
    'fr': 'france',
    'se': 'sweden',
    'ec': 'ecuador',
    'cz': 'czech-republic',
    'sco': 'scotland',
    'py': 'paraguay'
}

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def get_html_with_retries(url, max_retries=5):
    for attempt in range(1, max_retries + 1):
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                return response.read().decode('utf-8', errors='ignore')
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return "404"
            print(f"  HTTP Error {e.code} on attempt {attempt} for URL: {url}")
        except Exception as e:
            print(f"  Error {e} on attempt {attempt} for URL: {url}")
        
        if attempt < max_retries:
            sleep_time = attempt * 3
            print(f"  Retrying in {sleep_time}s...")
            time.sleep(sleep_time)
    return None

def extract_og_image(html):
    meta_tags = re.findall(r'<meta\s+[^>]+>', html, re.IGNORECASE)
    for tag in meta_tags:
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

def find_image_fallback(html, code, slug):
    urls = re.findall(r'https://digitalhub\.fifa\.com/transform/[^\s"\'}]+', html)
    clean_urls = set()
    for u in urls:
        clean = u.split('?')[0].split('&')[0].replace('&amp;', '')
        clean_urls.add(clean)
        
    search_terms = [
        slug.lower(),
        slug.lower().replace('-', ''),
        slug.lower().replace('-', '_')
    ]
    # Special cases
    if code == 'sco':
        search_terms.append('scotland')
        
    for u in sorted(clean_urls):
        u_lower = u.lower()
        if 'team-profile' in u_lower or 'team_profile' in u_lower:
            for term in search_terms:
                if term in u_lower:
                    return u
    for u in sorted(clean_urls):
        u_lower = u.lower()
        if 'profile' in u_lower:
            for term in search_terms:
                if term in u_lower:
                    return u
    return None

def download_image(url, local_path):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
            with open(local_path, 'wb') as f:
                f.write(data)
            return True
    except Exception as e:
        print(f"  Image download error: {e}")
    return False

def main():
    json_path = 'assets/team_media.json'
    
    with open(json_path, 'r') as f:
        media_map = json.load(f)

    print(f"Fetching remaining {len(REMAINING_TEAMS)} teams with high timeout...")
    os.makedirs('assets/logos', exist_ok=True)

    for code, slug in REMAINING_TEAMS.items():
        print(f"Processing {code.upper()} (slug: {slug})...")
        url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
        
        html = get_html_with_retries(url)
        if not html or html == "404":
            print(f"  FAILED to fetch article for {code.upper()}")
            continue

        img_url = extract_og_image(html)
        if not img_url:
            img_url = find_image_fallback(html, code, slug)
            
        if not img_url:
            img_url = "https://digitalhub.fifa.com/transform/032a70c6-594c-4b5a-9545-0c96383708a0/fifapls_fallbackimage_1200x630"
            
        print(f"  Found image URL: {img_url}")

        ext = 'jpg'
        if '.png' in img_url.lower():
            ext = 'png'
        elif '.webp' in img_url.lower():
            ext = 'webp'
            
        local_filename = f"{code}_preview.{ext}"
        local_path = f"assets/logos/{local_filename}"
        
        print(f"  Downloading to {local_path}...")
        if download_image(img_url, local_path):
            media_map[code]["profile_url"] = url
            media_map[code]["image_url"] = f"assets/logos/{local_filename}"
            print(f"  SUCCESS: Saved and updated in JSON.")
        else:
            print(f"  FAILED to download image for {code.upper()}")

        with open(json_path, 'w') as f:
            json.dump(media_map, f, indent=2)
            
        time.sleep(2.0)

if __name__ == '__main__':
    main()
