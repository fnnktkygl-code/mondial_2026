import json
import os

json_path = 'assets/team_media.json'
if os.path.exists(json_path):
    with open(json_path, 'r') as f:
        media_map = json.load(f)
    cached = [k for k, v in media_map.items() if 'image_url' in v and v['image_url']]
    all_teams = list(media_map.keys())
    print(f"Total teams in JSON: {len(all_teams)}")
    print(f"Teams with cached preview image: {len(cached)}/62")
    print("Cached teams:", sorted(cached))
else:
    print("team_media.json does not exist!")
