import urllib.request
import urllib.error
import re
import json
import os
import time

# List of all 48 qualified team codes mapped to their correct slug
TEAM_SLUGS = {
    'mx': 'mexico', 'de': 'germany', 'us': 'usa', 'en': 'england',
    'ca': 'canada', 'jp': 'japan', 'fr': 'france', 'br': 'brazil',
    'sn': 'senegal', 'ar': 'argentina', 'ma': 'morocco', 'es': 'spain',
    'pt': 'portugal', 'nl': 'netherlands', 'be': 'belgium',
    'hr': 'croatia', 'uy': 'uruguay', 'co': 'colombia', 'kr': 'korea-republic',
    'se': 'sweden', 'ch': 'switzerland', 'dz': 'algeria',
    'eg': 'egypt', 'tn': 'tunisia', 'gh': 'ghana', 'ci': 'cote-divoire',
    'ec': 'ecuador',
    'au': 'australia', 'nz': 'new-zealand', 'sa': 'saudi-arabia', 'ir': 'ir-iran',
    'tr': 'turkiye', 'cz': 'czech-republic', 'at': 'austria',
    'za': 'south-africa', 'ba': 'bosnia-and-herzegovina', 'cd': 'congo-dr',
    'cu': 'curacao', 'cv': 'cabo-verde', 'sco': 'scotland', 'ht': 'haiti',
    'iq': 'iraq', 'jo': 'jordan', 'no': 'norway', 'pa': 'panama',
    'py': 'paraguay', 'qa': 'qatar', 'uz': 'uzbekistan'
}

# Slugs to try as alternatives
ALTERNATIVES = {
    'cd': ['congo-dr', 'dr-congo', 'democratic-republic-of-the-congo'],
    'ci': ['cote-divoire', 'cote-d-ivoire'],
    'us': ['usa', 'united-states'],
    'ir': ['ir-iran', 'iran'],
}

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def get_html_with_retries(url, max_retries=3):
    for attempt in range(1, max_retries + 1):
        req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
        try:
            with urllib.request.urlopen(req, timeout=15) as response:
                return response.read().decode('utf-8', errors='ignore')
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return "404"
            print(f"  HTTP Error {e.code} on attempt {attempt} for URL: {url}")
        except Exception as e:
            print(f"  Error {e} on attempt {attempt} for URL: {url}")
        
        if attempt < max_retries:
            sleep_time = attempt * 2
            print(f"  Retrying in {sleep_time}s...")
            time.sleep(sleep_time)
            
    return None

def extract_og_image(html):
    # Try finding standard og:image or twitter:image or name=image tags
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
    # Find all digitalhub URLs in HTML
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
    names_map = {
        'ci': ['ivory-coast', 'ivorycoast', 'cote-d-ivoire', 'cote-divoire'],
        'cd': ['congo-dr', 'dr-congo', 'democratic-republic-of-the-congo'],
        'kr': ['korea', 'south-korea', 'korea-republic'],
        'us': ['usa', 'united-states'],
        'cv': ['cabo-verde', 'cape-verde'],
        'ir': ['iran', 'ir-iran'],
    }
    if code in names_map:
        search_terms.extend(names_map[code])
        
    # Priority 1: contains "team-profile" and search term
    for u in sorted(clean_urls):
        u_lower = u.lower()
        if 'team-profile' in u_lower or 'team_profile' in u_lower:
            for term in search_terms:
                if term in u_lower:
                    return u
                    
    # Priority 2: contains "profile" and search term
    for u in sorted(clean_urls):
        u_lower = u.lower()
        if 'profile' in u_lower:
            for term in search_terms:
                if term in u_lower:
                    return u
                    
    # Priority 3: contains "team-profile"
    for u in sorted(clean_urls):
        u_lower = u.lower()
        if 'team-profile' in u_lower or 'team_profile' in u_lower:
            return u
            
    # Priority 4: contains search term
    for u in sorted(clean_urls):
        u_lower = u.lower()
        for term in search_terms:
            if term in u_lower:
                return u
                
    # Priority 5: generic non-fallback
    for u in sorted(clean_urls):
        if 'generic' not in u_lower and 'fallback' not in u_lower:
            return u
            
    return None

def download_image_with_retries(url, local_path, max_retries=3):
    for attempt in range(1, max_retries + 1):
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = resp.read()
                with open(local_path, 'wb') as f:
                    f.write(data)
                return True
        except Exception as e:
            print(f"  Image download error {e} on attempt {attempt} for URL: {url}")
            if attempt < max_retries:
                time.sleep(attempt * 2)
    return False

def main():
    json_path = 'assets/team_media.json'
    
    # Load existing media map
    if os.path.exists(json_path):
        with open(json_path, 'r') as f:
            media_map = json.load(f)
    else:
        media_map = {}

    print(f"Starting crawl for {len(TEAM_SLUGS)} teams using verified endpoint format...")
    os.makedirs('assets/logos', exist_ok=True)

    success_count = 0
    total = len(TEAM_SLUGS)
    
    for idx, (code, default_slug) in enumerate(TEAM_SLUGS.items(), 1):
        # We preserve Germany's manually set cropped image
        if code == 'de':
            print(f"[{idx}/{total}] Skipping DE (Germany) to keep the manually selected preview.")
            success_count += 1
            continue

        # Skip if already cached and exists locally
        if code in media_map and media_map[code].get("image_url") and os.path.exists(media_map[code]["image_url"]):
            print(f"[{idx}/{total}] Already cached for {code.upper()}, skipping.")
            success_count += 1
            continue

        print(f"[{idx}/{total}] Processing {code.upper()}...")
        
        # Build list of slugs to test
        slugs_to_try = [default_slug]
        if code in ALTERNATIVES:
            for alt in ALTERNATIVES[code]:
                if alt not in slugs_to_try:
                    slugs_to_try.append(alt)

        html = None
        final_url = None
        
        for slug in slugs_to_try:
            url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
            print(f"  Trying: {url}")
            res = get_html_with_retries(url)
            if res == "404":
                print(f"  404 Not Found for slug: {slug}")
                continue
            elif res:
                html = res
                final_url = url
                break
            time.sleep(0.5)

        if not html:
            print(f"  FAILED to fetch article for {code.upper()} (tried all slugs)")
            continue

        # Try to find standard image meta tag
        img_url = extract_og_image(html)
        if not img_url:
            print("  Standard og:image tag not found, using robust candidate extraction...")
            img_url = find_image_fallback(html, code, slugs_to_try[0])
            
        if not img_url:
            print(f"  og:image meta tag not found for {code.upper()}")
            # fallback to generic image
            img_url = "https://digitalhub.fifa.com/transform/032a70c6-594c-4b5a-9545-0c96383708a0/fifapls_fallbackimage_1200x630"
            
        print(f"  Found image URL: {img_url}")

        # Guess extension from URL
        ext = 'jpg'
        if '.png' in img_url.lower():
            ext = 'png'
        elif '.webp' in img_url.lower():
            ext = 'webp'
            
        local_filename = f"{code}_preview.{ext}"
        local_path = f"assets/logos/{local_filename}"
        
        # Download the image
        print(f"  Downloading to {local_path}...")
        download_ok = download_image_with_retries(img_url, local_path)
        
        if download_ok:
            # Update the JSON entry
            # If the entry already exists, we preserve it, but update profile_url and image_url
            if code not in media_map:
                media_map[code] = {
                    "profile_url": final_url,
                    "media_url": None
                }
            else:
                # If profile_url is currently a Map or String, overwrite with the verified URL
                media_map[code]["profile_url"] = final_url
                
            media_map[code]["image_url"] = f"assets/logos/{local_filename}"
            success_count += 1
            print(f"  SUCCESS: Saved and updated in JSON.")
        else:
            print(f"  FAILED to download image for {code.upper()}")

        # Write progress to JSON at each step to prevent data loss
        with open(json_path, 'w') as f:
            json.dump(media_map, f, indent=2)

        # Brief pause between teams to prevent rate limiting
        time.sleep(1.0)

    print(f"\nCompleted! Successfully downloaded previews for {success_count}/{total} teams.")

if __name__ == '__main__':
    main()
