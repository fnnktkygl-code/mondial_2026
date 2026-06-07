import urllib.request
import urllib.error
import re
import json
import time

# List of all 62 team codes mapped to their default FIFA article slug guess
TEAM_SLUGS = {
    'mx': 'mexico', 'de': 'germany', 'us': 'usa', 'en': 'england',
    'ca': 'canada', 'jp': 'japan', 'fr': 'france', 'br': 'brazil',
    'sn': 'senegal', 'ar': 'argentina', 'ma': 'morocco', 'es': 'spain',
    'it': 'italy', 'pt': 'portugal', 'nl': 'netherlands', 'be': 'belgium',
    'hr': 'croatia', 'uy': 'uruguay', 'co': 'colombia', 'kr': 'korea-republic',
    'cm': 'cameroon', 'ng': 'nigeria', 'se': 'sweden', 'ch': 'switzerland',
    'dk': 'denmark', 'pl': 'poland', 'ua': 'ukraine', 'dz': 'algeria',
    'eg': 'egypt', 'tn': 'tunisia', 'gh': 'ghana', 'ci': 'cote-d-ivoire',
    'cl': 'chile', 'pe': 'peru', 'ec': 'ecuador', 've': 'venezuela',
    'au': 'australia', 'nz': 'new-zealand', 'sa': 'saudi-arabia', 'ir': 'ir-iran',
    'tr': 'turkiye', 'gr': 'greece', 'cz': 'czech-republic', 'at': 'austria',
    'ro': 'romania', 'hu': 'hungary', 'bg': 'bulgaria', 'rs': 'serbia',
    'za': 'south-africa', 'ba': 'bosnia-and-herzegovina', 'cd': 'democratic-republic-of-the-congo',
    'cu': 'curacao', 'cv': 'cabo-verde', 'sco': 'scotland', 'ht': 'haiti',
    'iq': 'iraq', 'jo': 'jordan', 'no': 'norway', 'pa': 'panama',
    'py': 'paraguay', 'qa': 'qatar', 'uz': 'uzbekistan'
}

# Slugs to try if the default guess returns 404
ALTERNATIVES = {
    'us': ['united-states', 'usa'],
    'ir': ['iran', 'ir-iran'],
    'cz': ['czechia', 'czech-republic'],
    'cd': ['dr-congo', 'democratic-republic-of-the-congo'],
    'cv': ['cape-verde', 'cabo-verde'],
}

USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

def get_html(url):
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            return response.read().decode('utf-8', errors='ignore')
    except urllib.error.HTTPError as e:
        return None
    except Exception as e:
        return None

def fetch_media_for_team(code, default_slug):
    slugs_to_try = [default_slug]
    if code in ALTERNATIVES:
        for alt in ALTERNATIVES[code]:
            if alt not in slugs_to_try:
                slugs_to_try.append(alt)

    html = None
    final_url = None
    for slug in slugs_to_try:
        url = f"https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/{slug}-team-profile-history"
        print(f"Trying: {url} ...")
        html = get_html(url)
        if html:
            final_url = url
            break
        # Brief pause to avoid aggressive scraping rate-limiting
        time.sleep(0.5)

    if not html:
        print(f"FAILED to fetch team profile for: {code}")
        return None

    # Search for media/cat collection or watch links in the HTML
    # Collection URL: https://www.fifa.com/en/cat/4uvlj6vOoPQCT2hROuWX5r
    # Watch URL: https://www.fifa.com/en/watch/...
    cat_match = re.search(r'https?://www\.fifa\.com/en/cat/[a-zA-Z0-9]+', html)
    watch_match = re.search(r'https?://www\.fifa\.com/en/watch/[a-zA-Z0-9]+', html)

    media_url = None
    if cat_match:
        media_url = cat_match.group(0)
    elif watch_match:
        media_url = watch_match.group(0)

    # If no media link is found on page, fallback to a search pattern or generic watch link
    return {
        'profile_url': final_url,
        'media_url': media_url
    }

def main():
    results = {}
    total = len(TEAM_SLUGS)
    count = 0

    # Let's run a quick batch
    for code, default_slug in TEAM_SLUGS.items():
        count += 1
        print(f"\n[{count}/{total}] Processing {code.upper()}...")
        media_info = fetch_media_for_team(code, default_slug)
        if media_info:
            results[code] = media_info
            print(f"SUCCESS: Profile -> {media_info['profile_url']}, Media -> {media_info['media_url']}")
        else:
            # Standard pattern fallback if offline or blocked
            slug = default_slug
            results[code] = {
                'profile_url': f"https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/{slug}-team-profile-history",
                'media_url': None
            }
        
        # Save progress at each step
        with open('assets/team_media.json', 'w') as f:
            json.dump(results, f, indent=2)

    print("\nDONE! Media links saved to assets/team_media.json")

if __name__ == '__main__':
    main()
