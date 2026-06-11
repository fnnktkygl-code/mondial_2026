import urllib.request
import os
import json
import base64
from io import BytesIO
from PIL import Image

try:
    from rembg import remove
except ImportError:
    print("rembg is not installed. Please install it using: pip install 'rembg[cpu]'")
    exit(1)

# List of teams
TEAMS = [
    'argentina', 'australia', 'austria', 'belgium', 'bosnia', 'brazil', 'cameroon', 'canada',
    'colombia', 'costa-rica', 'croatia', 'denmark', 'ecuador', 'egypt', 'england', 'france',
    'germany', 'ghana', 'iran', 'iraq', 'ivory-coast', 'japan', 'mexico', 'morocco',
    'netherlands', 'new-zealand', 'nigeria', 'norway', 'panama', 'paraguay', 'peru', 'poland',
    'portugal', 'qatar', 'saudi-arabia', 'scotland', 'senegal', 'serbia', 'south-africa',
    'south-korea', 'spain', 'sweden', 'switzerland', 'tunisia', 'turkey', 'uruguay', 'usa', 'wales'
]

BASE_URL = "https://www.api-football.com/public/img/news/wc_2026/{}.webp"
ASSETS_DIR = "assets/wc_banners"

os.makedirs(ASSETS_DIR, exist_ok=True)

results = {}

for team in TEAMS:
    url = BASE_URL.format(team)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})

    try:
        with urllib.request.urlopen(req) as response:
            image_data = response.read()

            # Process with rembg
            input_image = Image.open(BytesIO(image_data))
            output_image = remove(input_image)

            # Save no bg
            no_bg_path = os.path.join(ASSETS_DIR, f"{team}_no_bg.webp")
            output_image.save(no_bg_path, format="WEBP")

            # Convert to base64 for JSON
            buffered = BytesIO()
            output_image.save(buffered, format="WEBP")
            img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

            results[team] = {
                "no_bg_path": no_bg_path,
                "no_bg_base64": img_str
            }
            print(f"Successfully processed {team}")

    except Exception as e:
        pass

# Save JSON
json_path = os.path.join(ASSETS_DIR, "teams_data.json")
with open(json_path, "w") as f:
    json.dump(results, f, indent=2)

print(f"JSON saved to {json_path}")

# Generate Dart file
dart_path = "lib/wc_teams_images.dart"
os.makedirs(os.path.dirname(dart_path), exist_ok=True)

with open(dart_path, "w") as f:
    f.write("/// Generated file containing World Cup team banners (No Background)\n")
    f.write("class WcTeamsImages {\n")
    f.write("  static const Map<String, String> noBgImagesBase64 = {\n")
    for team, data in results.items():
        f.write(f"    '{team}': '{data['no_bg_base64']}',\n")
    f.write("  };\n")
    f.write("}\n")

print(f"Dart file saved to {dart_path}")
