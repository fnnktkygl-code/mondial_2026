#!/usr/bin/env python3
"""Fetch preview images for the 2 remaining teams: cw (Curaçao) and sco (Scotland)."""

import json
import os
import re
import time
import urllib.request
import urllib.error

TEAMS = {
    "cw": "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/curacao-team-profile-history",
    "sco": "https://www.fifa.com/en/tournaments/mens/worldcup/canadamexicousa2026/articles/scotland-team-profile-history",
}

OUTPUT_DIR = "assets/team_profile_preview"
MEDIA_JSON = "assets/team_media.json"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

with open(MEDIA_JSON) as f:
    media_data = json.load(f)


def fetch_html(url, timeout=45):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def find_og_image(html):
    m = re.search(r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']', html)
    if m:
        return m.group(1)
    m = re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']', html)
    if m:
        return m.group(1)
    return None


def find_candidate_image(html, team_code):
    patterns = [
        r'(https://digitalhub\.fifa\.com/m/[^"\']+team-profile[^"\']*\.(?:avif|jpg|jpeg|png|webp))',
        r'(https://digitalhub\.fifa\.com/m/[^"\']*' + re.escape(team_code) + r'[^"\']*\.(?:avif|jpg|jpeg|png|webp))',
        r'(https://digitalhub\.fifa\.com/m/[^"\']+\.(?:avif|jpg|jpeg|png|webp))',
    ]
    for p in patterns:
        m = re.search(p, html, re.IGNORECASE)
        if m:
            return m.group(1)
    return None


def download_image(url, dest_path, timeout=45):
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = resp.read()
    with open(dest_path, "wb") as f:
        f.write(data)


for code, profile_url in TEAMS.items():
    print(f"\n[{code.upper()}] Fetching: {profile_url}")
    # Try up to 3 times
    html = None
    for attempt in range(1, 4):
        try:
            html = fetch_html(profile_url)
            print(f"  HTML fetched ({len(html)} chars)")
            break
        except Exception as e:
            print(f"  Attempt {attempt} failed: {e}")
            time.sleep(5)

    if not html:
        print(f"  [SKIP] Could not fetch HTML for {code}")
        continue

    img_url = find_og_image(html) or find_candidate_image(html, code)
    if not img_url:
        print(f"  [SKIP] No image found in HTML for {code}")
        continue

    print(f"  Image URL: {img_url}")
    ext = img_url.split(".")[-1].split("?")[0]
    dest = os.path.join(OUTPUT_DIR, f"{code}_preview.{ext}")

    try:
        download_image(img_url, dest)
        print(f"  Saved to {dest}")
        media_data[code]["image_url"] = dest
        media_data[code]["media_url"] = img_url
    except Exception as e:
        print(f"  Download failed: {e}")

with open(MEDIA_JSON, "w") as f:
    json.dump(media_data, f, ensure_ascii=False, indent=2)

print("\nDone. Updated team_media.json.")
