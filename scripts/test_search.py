import urllib.request
import json

url = "https://cxm-api.fifa.com/fifacxmsearch/api/results?locale=en&searchString=team-profile-history&size=100&clientType=fifaplus&type=search&context=default"
req = urllib.request.Request(url, headers={
    'X-Functions-Key': '2kD9zRYRT7xN6kSGs6EoHcvSyKOyK0B4YaKTf1Ygeaw8PM6bgfR6SQ==',
    'Content-Type': 'application/json',
    'User-Agent': 'Mozilla/5.0'
})

try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        print("Success! Hits:", len(data.get('hits', {}).get('hits', [])))
        for hit in data.get('hits', {}).get('hits', [])[:5]:
            source = hit.get('_source', {})
            print(source.get('title'), "->", source.get('relativeUrl'))
except Exception as e:
    print("Error:", e)
