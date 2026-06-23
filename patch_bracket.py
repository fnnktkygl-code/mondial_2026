import json

with open('assets/initial_matches.json', 'r') as f:
    matches = json.load(f)

fixes = {
    "m81": {"t1": "1D", "t2": "3rd5"},
    "m82": {"t1": "1G", "t2": "3rd6"},
    "m83": {"t1": "2K", "t2": "2L"},
    "m84": {"t1": "1H", "t2": "2J"},
    "m86": {"t1": "1J", "t2": "2H"},
    "m87": {"t1": "1K", "t2": "3rd8"},
    "m88": {"t1": "2D", "t2": "2G"}
}

for m in matches:
    if m['id'] in fixes:
        m['t1'] = fixes[m['id']]['t1']
        m['t2'] = fixes[m['id']]['t2']

with open('assets/initial_matches.json', 'w') as f:
    json.dump(matches, f, indent=2)

print("Patched!")
