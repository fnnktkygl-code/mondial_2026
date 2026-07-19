import json

with open("assets/initial_matches_new.json") as f:
    matches = json.load(f)

for m in matches:
    if m.get("stage") in ["Round of 32", "Round of 16", "Quarter-Final", "Semi-Final"]:
        print(f"{m['id']}: {m['t1']} vs {m['t2']} ({m['stage']})")
