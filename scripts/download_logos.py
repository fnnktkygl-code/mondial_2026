import urllib.request
import re
import os
import io
from PIL import Image
from concurrent.futures import ThreadPoolExecutor

mapping = {
    'ar': 'argentina',
    'at': 'austria',
    'au': 'australia',
    'ba': 'bosnia-and-herzegovina',
    'be': 'belgium',
    'br': 'brazil',
    'ca': 'canada',
    'cd': 'congo-dr',
    'ch': 'switzerland',
    'ci': 'cote-d-ivoire',
    'co': 'colombia',
    'cu': 'curacao',
    'cv': 'cabo-verde',
    'cz': 'czech-republic',
    'de': 'germany',
    'dz': 'algeria',
    'ec': 'ecuador',
    'eg': 'egypt',
    'en': 'england',
    'es': 'spain',
    'fr': 'france',
    'sco': 'scotland',
    'gh': 'ghana',
    'hr': 'croatia',
    'ht': 'haiti',
    'iq': 'iraq',
    'ir': 'iran',
    'jo': 'jordan',
    'jp': 'japan',
    'kr': 'south-korea',
    'ma': 'morocco',
    'mx': 'mexico',
    'nl': 'netherlands',
    'no': 'norway',
    'nz': 'new-zealand',
    'pa': 'panama',
    'pt': 'portugal',
    'py': 'paraguay',
    'qa': 'qatar',
    'sa': 'saudi-arabia',
    'se': 'sweden',
    'sn': 'senegal',
    'tn': 'tunisia',
    'tr': 'turkey',
    'us': 'usa',
    'uy': 'uruguay',
    'uz': 'uzbekistan',
    'za': 'south-africa',
}

headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

def download_logo(code, slug):
    try:
        url = f'https://football-logos.cc/{slug}/{slug}-national-team/'
        req = urllib.request.Request(url, headers=headers)
        
        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8')
            
        # Extract categoryId, logoId, hash
        cat_match = re.search(r'data-category-id="([^"]+)"', html)
        logo_match = re.search(r'data-logo-id="([^"]+)"', html)
        hash_match = re.search(r'value="512::([a-f0-9]+)"', html)
        
        if not cat_match or not logo_match or not hash_match:
            print(f'[-] Failed to parse elements for {slug}')
            return False
            
        cat_id = cat_match.group(1)
        logo_id = logo_match.group(1)
        logo_hash = hash_match.group(1)
        
        img_url = f'https://images.football-logos.cc/{cat_id}/512/{logo_id}.{logo_hash}.png'
        img_req = urllib.request.Request(img_url, headers={
            **headers,
            'Referer': 'https://football-logos.cc/'
        })
        
        with urllib.request.urlopen(img_req) as img_resp:
            img_data = img_resp.read()
            
        os.makedirs('assets/logos', exist_ok=True)
        img_path = f'assets/logos/{code}.png'
        with open(img_path, 'wb') as f:
            f.write(img_data)
            
        print(f'[+] Downloaded logo for {code} ({slug})')
        return True
    except Exception as e:
        print(f'[-] Error downloading {code} ({slug}): {e}')
        return False

def main():
    print(f'Starting logo download for {len(mapping)} teams...')
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(download_logo, code, slug) for code, slug in mapping.items()]
        results = [f.result() for f in futures]
    
    success = sum(1 for r in results if r)
    print(f'Finished! Successfully downloaded {success}/{len(mapping)} logos.')

if __name__ == '__main__':
    main()
