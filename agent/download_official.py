import urllib.request
import zipfile
import os
import shutil

url = "https://github.com/nezhahq/agent/releases/download/v2.0.3/nezha-agent_windows_amd64.zip"
zip_path = r"F:\nezha\agent\official_agent.zip"
extract_dir = r"F:\nezha\agent\official_tmp"
output_path = r"F:\nezha\agent\nezha-agent-official.exe"

print(f"Downloading from {url}...")
urllib.request.urlretrieve(url, zip_path)
print("Downloaded OK")

print(f"Extracting to {extract_dir}...")
os.makedirs(extract_dir, exist_ok=True)
with zipfile.ZipFile(zip_path, 'r') as zf:
    zf.extractall(extract_dir)

for root, dirs, files in os.walk(extract_dir):
    for f in files:
        if f.endswith('.exe'):
            src = os.path.join(root, f)
            shutil.copy2(src, output_path)
            print(f"Extracted: {f} -> {os.path.basename(output_path)}")
            break

shutil.rmtree(extract_dir, ignore_errors=True)
os.remove(zip_path)
print("Done")
