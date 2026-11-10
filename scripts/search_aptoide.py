import urllib.request
import json

url = "https://ws75.aptoide.com/api/7/apps/search/query=Crunchyroll"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode())
        apps = data.get('datalist', {}).get('list', [])
        for a in apps[:8]:
            print(f"Name: {a.get('name')} | Pkg: {a.get('package')} | Ver: {a.get('vername')} | ID: {a.get('id')} | Size: {a.get('size')}")
except Exception as e:
    print("Error:", e)
