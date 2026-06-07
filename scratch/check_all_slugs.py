import urllib.request
import urllib.error
import re
import time

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

# Known overrides for the /en/articles/ path
OVERRIDES = {
    'cd': ['congo-dr', 'dr-congo'],
    'ci': ['cote-divoire', 'cote-d-ivoire'],
}

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

def check_slug(code, slug):
    url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            html = response.read().decode('utf-8', errors='ignore')
            og_image = re.search(r'<meta property="og:image" content="(.*?)"', html)
            img = og_image.group(1) if og_image else None
            return True, url, img
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False, url, 404
        return False, url, e.code
    except Exception as e:
        return False, url, str(e)

results = {}
success_count = 0

print("Starting verification...")
for idx, (code, slug) in enumerate(TEAM_SLUGS.items(), 1):
    print(f"[{idx}/62] Testing {code.upper()} (slug: {slug})...")
    slugs_to_try = [slug]
    if code in OVERRIDES:
        for alt in OVERRIDES[code]:
            if alt not in slugs_to_try:
                slugs_to_try.append(alt)
                
    success = False
    last_err = None
    final_url = None
    final_img = None
    
    for s in slugs_to_try:
        ok, tested_url, res = check_slug(code, s)
        if ok:
            success = True
            final_url = tested_url
            final_img = res
            print(f"  SUCCESS: {tested_url} -> {res}")
            break
        else:
            last_err = res
            print(f"  FAILED: {tested_url} -> {res}")
            time.sleep(0.2)
            
    if success:
        success_count += 1
        results[code] = {
            "status": "success",
            "url": final_url,
            "img": final_img
        }
    else:
        results[code] = {
            "status": "failed",
            "error": last_err
        }
    time.sleep(0.5)

print(f"\nVerification completed: {success_count}/62 successful.")
with open("scratch/slugs_check_results.json", "w") as f:
    json.dump(results, f, indent=2)
