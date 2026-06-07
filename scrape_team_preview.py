#!/usr/bin/env python3
"""
Fetch FIFA World Cup 2026 team profile images.
Extracts the digitalhub.fifa.com URL directly from each team's profile page —
no hardcoded UUIDs, no DAM search API needed.
"""

import urllib.request
import json
import os
import time
import re

OUTPUT_DIR = 'assets/team_profile_preview'
JSON_PATH  = 'assets/team_media.json'

TEAM_SLUGS = {
    'ar': 'argentina',        'au': 'australia',          'at': 'austria',
    'be': 'belgium',          'ba': 'bosnia-and-herzegovina', 'br': 'brazil',
    'bg': 'bulgaria',         'cv': 'cabo-verde',          'ca': 'canada',
    'cl': 'chile',            'co': 'colombia',            'cd': 'congo-dr',
    'hr': 'croatia',          'cu': 'curacao',             'cz': 'czechia',
    'dk': 'denmark',          'ec': 'ecuador',             'eg': 'egypt',
    'en': 'england',          'fr': 'france',              'de': 'germany',
    'gh': 'ghana',            'gr': 'greece',              'ht': 'haiti',
    'hu': 'hungary',          'ir': 'ir-iran',             'iq': 'iraq',
    'it': 'italy',            'jp': 'japan',               'jo': 'jordan',
    'kr': 'korea-republic',   'ma': 'morocco',             'mx': 'mexico',
    'nl': 'netherlands',      'nz': 'new-zealand',         'ng': 'nigeria',
    'no': 'norway',           'pa': 'panama',              'py': 'paraguay',
    'pe': 'peru',             'pl': 'poland',              'pt': 'portugal',
    'qa': 'qatar',            'ro': 'romania',             'sa': 'saudi-arabia',
    'sco': 'scotland',     'sn': 'senegal',             'rs': 'serbia',
    'za': 'south-africa',     'es': 'spain',               'se': 'sweden',
    'ch': 'switzerland',      'tn': 'tunisia',             'tr': 'turkiye',
    'ua': 'ukraine',          'uy': 'uruguay',             'us': 'usa',
    'uz': 'uzbekistan',       've': 'venezuela',           'dz': 'algeria',
    'ci': 'cote-divoire',     'cm': 'cameroon',
}

HEADERS = {
    'User-Agent': (
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
    ),
    'Accept': 'text/html,*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://www.fifa.com/',
}

# Captures every digitalhub transform URL found in the page HTML
DAM_RE = re.compile(
    r'digitalhub\.fifa\.com/transform/'
    r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
    r'/([^?"\'<\s\\]+)',
    re.IGNORECASE,
)


def fetch(url):
    try:
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.read()
    except Exception as e:
        print(f'    ✗ {e}')
        return None


def pick_best(matches):
    """
    Score each (uuid, filename) match and return the best profile image.
    Prefers 16x9 over 4x3; both beat anything that isn't a profile image.
    """
    def score(fname):
        f = fname.lower()
        return (
            ('profile' in f)  * 10 +
            ('16x9'   in f)  *  5 +
            ('4x3'    in f)  *  3 +
            ('graphic' in f) *  1
        )

    ranked = sorted(matches, key=lambda m: score(m[1]), reverse=True)
    uuid, fname = ranked[0]
    return (uuid, fname) if score(fname) > 0 else None


def build_url(uuid, filename):
    return (
        f'https://digitalhub.fifa.com/transform/{uuid}/{filename}'
        f'?io=transform:fill,height:630,width:1200&quality=85'
    )


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    media_map = json.load(open(JSON_PATH)) if os.path.exists(JSON_PATH) else {}

    for code, slug in TEAM_SLUGS.items():
        # Resume support: skip teams already successfully downloaded
        if media_map.get(code, {}).get('image_url'):
            print(f'[{code.upper():6s}] {slug} — already downloaded, skipping')
            continue

        profile_url = (
            f'https://www.fifa.com/en/tournaments/mens/worldcup/'
            f'canadamexicousa2026/articles/{slug}-team-profile-history'
        )
        print(f'[{code.upper():6s}] {slug}')

        html_bytes = fetch(profile_url)
        if not html_bytes:
            media_map[code] = {'profile_url': profile_url, 'image_url': None}
            with open(JSON_PATH, 'w') as f:
                json.dump(media_map, f, indent=2)
            time.sleep(0.5)
            continue

        # Unescape JSON-encoded forward slashes before matching.
        # Next.js embeds page data as JSON in __NEXT_DATA__ where URLs appear as
        # "digitalhub.fifa.com\/transform\/uuid\/filename" — the backslashes
        # prevent a plain regex from matching.
        html    = html_bytes.decode('utf-8', errors='replace').replace('\\/', '/')
        matches = DAM_RE.findall(html)
        result  = pick_best(matches) if matches else None

        if not result:
            print(f'         ✗ no profile image found in page HTML')
            media_map[code] = {'profile_url': profile_url, 'image_url': None}
            with open(JSON_PATH, 'w') as f:
                json.dump(media_map, f, indent=2)
            time.sleep(0.5)
            continue

        uuid, fname = result
        img_url     = build_url(uuid, fname)
        print(f'         → {fname}')

        img_data   = fetch(img_url)
        local_path = f'{OUTPUT_DIR}/{code}_preview.jpg'

        if img_data and len(img_data) > 5_000:
            with open(local_path, 'wb') as f:
                f.write(img_data)
            print(f'         ✓ saved ({len(img_data) // 1024} KB)')
            media_map[code] = {
                'profile_url': profile_url,
                'image_url':   local_path,
                'dam_url':     img_url,
            }
        else:
            print(f'         ✗ download failed or file too small')
            media_map[code] = {'profile_url': profile_url, 'image_url': None}

        with open(JSON_PATH, 'w') as f:
            json.dump(media_map, f, indent=2)
        time.sleep(1.0)

    print(f'\n✓ Done — {JSON_PATH}')
    missing = [c for c, v in media_map.items() if not v.get('image_url')]
    if missing:
        print(f'  Still missing: {", ".join(missing)}')


if __name__ == '__main__':
    main()