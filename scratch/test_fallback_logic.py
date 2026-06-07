import urllib.request
import re

USER_AGENT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'

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
        if 'generic' not in u.lower() and 'fallback' not in u.lower():
            return u
            
    return None

def test_team(code, slug):
    url = f"https://www.fifa.com/en/articles/{slug}-team-profile-history"
    req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode('utf-8', errors='ignore')
            img = find_image_fallback(html, code, slug)
            print(f"RESULT: {code.upper()} (slug: {slug}) -> IMAGE: {img}")
    except Exception as e:
        print(f"ERROR: {code.upper()} -> {e}")

test_team("ma", "morocco")
test_team("ch", "switzerland")
test_team("kr", "korea-republic")
test_team("pa", "panama")
