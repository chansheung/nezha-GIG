import urllib.request, zipfile, os, shutil, sys
sys.stdout.reconfigure(encoding='utf-8')
url = "https://github.com/nezhahq/agent/releases/download/v2.0.3/nezha-agent_windows_amd64.zip"
zip_path = r"F:\nezha\agent\official_agent.zip"
out_path = r"F:\nezha\agent\nezha-agent-official.exe"
print("Downloading...")
urllib.request.urlretrieve(url, zip_path)
print("Extracting...")
with zipfile.ZipFile(zip_path) as z:
    for info in z.infolist():
        if info.filename.endswith('.exe'):
            with z.open(info) as src, open(out_path, 'wb') as dst:
                shutil.copyfileobj(src, dst)
            print(f"Got: {info.filename}")
os.remove(zip_path)
print("Done")
