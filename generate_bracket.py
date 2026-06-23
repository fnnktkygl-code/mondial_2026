import json
import datetime

with open('assets/initial_matches.json', 'r') as f:
    matches = json.load(f)

# Filter out existing knockouts
group_matches = [m for m in matches if not m.get('isKnockout')]

# Official 2026 World Cup bracket paths
# Round of 32
r32 = [
    ("m73", "2A", "2B", "2026-06-28T19:00:00Z", "SoFi Stadium"),
    ("m74", "1E", "3rd1", "2026-06-29T19:00:00Z", "Gillette Stadium"),
    ("m75", "1F", "2C", "2026-06-29T22:00:00Z", "Estadio BBVA"),
    ("m76", "1C", "2F", "2026-06-29T19:00:00Z", "NRG Stadium"),
    ("m77", "1I", "3rd2", "2026-06-30T19:00:00Z", "MetLife Stadium"),
    ("m78", "2E", "2I", "2026-06-30T22:00:00Z", "AT&T Stadium"),
    ("m79", "1A", "3rd3", "2026-07-01T19:00:00Z", "Estadio Azteca"),
    ("m80", "1L", "3rd4", "2026-07-01T22:00:00Z", "Mercedes-Benz Stadium"),
    ("m81", "1G", "3rd5", "2026-07-01T19:00:00Z", "Lumen Field"),
    ("m82", "1D", "3rd6", "2026-07-01T22:00:00Z", "Levi's Stadium"),
    ("m83", "1H", "2J", "2026-07-02T19:00:00Z", "SoFi Stadium"),
    ("m84", "2K", "2L", "2026-07-02T22:00:00Z", "BMO Field"),
    ("m85", "1B", "3rd7", "2026-07-02T19:00:00Z", "BC Place"),
    ("m86", "2D", "2G", "2026-07-03T19:00:00Z", "AT&T Stadium"),
    ("m87", "1J", "2H", "2026-07-03T19:00:00Z", "Hard Rock Stadium"),
    ("m88", "1K", "3rd8", "2026-07-03T22:00:00Z", "Arrowhead Stadium")
]

# We need to map the user's bracket tree exactly.
# User's text tree:
# M89: w74 vs w77 (July 4 - Philadelphia)
# M90: w73 vs w75 (July 4 - Houston)
# M91: w76 vs w78 (July 5 - MetLife)
# M92: w79 vs w80 (July 5 - Azteca)
# M93: w81 vs w82 (July 6 - Arlington)
# M94: w83 vs w84 (July 6 - Seattle)
# M95: w85 vs w86 (July 7 - Atlanta)
# M96: w87 vs w88 (July 7 - Vancouver)

r16 = [
    ("m89", "w74", "w77", "2026-07-04T19:00:00Z", "Lincoln Financial Field"),
    ("m90", "w73", "w75", "2026-07-04T22:00:00Z", "NRG Stadium"),
    ("m91", "w76", "w78", "2026-07-05T19:00:00Z", "MetLife Stadium"),
    ("m92", "w79", "w80", "2026-07-05T22:00:00Z", "Estadio Azteca"),
    ("m93", "w81", "w82", "2026-07-06T19:00:00Z", "AT&T Stadium"),
    ("m94", "w83", "w84", "2026-07-06T22:00:00Z", "Lumen Field"),
    ("m95", "w85", "w86", "2026-07-07T19:00:00Z", "Mercedes-Benz Stadium"),
    ("m96", "w87", "w88", "2026-07-07T22:00:00Z", "BC Place")
]

# Quarter finals
# From user text:
# M97: w89 vs w90 (July 9 - Boston)
# M98: w93 vs w94 (July 10 - Los Angeles)
# M99: w91 vs w92 (July 11 - Miami)
# M100: w95 vs w96 (July 11 - Kansas City)

qf = [
    ("m97", "w89", "w90", "2026-07-09T19:00:00Z", "Gillette Stadium"),
    ("m98", "w93", "w94", "2026-07-10T19:00:00Z", "SoFi Stadium"),
    ("m99", "w91", "w92", "2026-07-11T19:00:00Z", "Hard Rock Stadium"),
    ("m100", "w95", "w96", "2026-07-11T22:00:00Z", "Arrowhead Stadium")
]

# Semi finals
# M101: w97 vs w98 (July 14 - Arlington)
# M102: w99 vs w100 (July 15 - Atlanta)
sf = [
    ("m101", "w97", "w98", "2026-07-14T19:00:00Z", "AT&T Stadium"),
    ("m102", "w99", "w100", "2026-07-15T19:00:00Z", "Mercedes-Benz Stadium")
]

# Third place
# M103: l101 vs l102 (July 18 - Miami)
third = [
    ("m103", "l101", "l102", "2026-07-18T19:00:00Z", "Hard Rock Stadium")
]

# Final
# M104: w101 vs w102 (July 19 - New York)
final = [
    ("m104", "w101", "w102", "2026-07-19T19:00:00Z", "MetLife Stadium")
]

knockouts = []
stages = [
    (r32, "Round of 32"),
    (r16, "Round of 16"),
    (qf, "Quarter-Final"),
    (sf, "Semi-Final"),
    (third, "Play-off for third place"),
    (final, "Final")
]

for stage_matches, stage_name in stages:
    for m in stage_matches:
        knockouts.append({
            "id": m[0],
            "date": m[3],
            "t1": m[1],
            "t2": m[2],
            "t1Score": None,
            "t2Score": None,
            "venue": m[4],
            "group": None,
            "stage": stage_name,
            "isKnockout": True,
            "status": "TIMED",
            "lastUpdated": "2026-06-22T00:00:00Z",
            "goals": [],
            "stats": None
        })

group_matches.extend(knockouts)

with open('assets/initial_matches_new.json', 'w') as f:
    json.dump(group_matches, f, indent=2)

print("Generated new bracket!")
