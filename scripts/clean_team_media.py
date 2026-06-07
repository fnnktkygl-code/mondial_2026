import json
import os

QUALIFIED_TEAMS = {
    'mx', 'de', 'us', 'en', 'ca', 'jp', 'fr', 'br', 'sn', 'ar', 'ma', 'es',
    'pt', 'nl', 'be', 'hr', 'uy', 'co', 'kr', 'se', 'ch', 'dz', 'eg', 'tn',
    'gh', 'ci', 'ec', 'au', 'nz', 'sa', 'ir', 'tr', 'cz', 'at', 'za', 'ba',
    'cd', 'cu', 'cv', 'sco', 'ht', 'iq', 'jo', 'no', 'pa', 'py', 'qa', 'uz'
}

json_path = 'assets/team_media.json'
if os.path.exists(json_path):
    with open(json_path, 'r') as f:
        media_map = json.load(f)
        
    cleaned_map = {k: v for k, v in media_map.items() if k in QUALIFIED_TEAMS}
    print(f"Original size: {len(media_map)}, Cleaned size: {len(cleaned_map)}")
    
    # Write back
    with open(json_path, 'w') as f:
        json.dump(cleaned_map, f, indent=2)
    print("Successfully cleaned team_media.json")
else:
    print("Error: team_media.json not found!")
