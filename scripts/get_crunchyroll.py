from apkpure.apkpure import ApkPure

api = ApkPure()
print("Searching for Crunchyroll...")
try:
    results = api.search("Crunchyroll")
    print("Results:", results)
except Exception as e:
    print("Search error:", e)
