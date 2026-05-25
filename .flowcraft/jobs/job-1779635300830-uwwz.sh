#!/bin/bash
python -c "
import urllib.request, zipfile, os, shutil
url = 'https://github.com/nezhahq/agent/releases/download/v2.0.3/nezha-agent_windows_amd64.zip'
zip_path = os.path.join('F:\\nezha\\agent', 'official_agent.zip')
exe_path = os.path.join('F:\\nezha\\agent', 'nezha-agent-official.exe')
urllib.request.urlretrieve(url, zip_path)
print('Downloaded zip')
with zipfile.ZipFile(zip_path, 'r') as zf:
    for info in zf.infolist():
        if info.filename.endswith('.exe'):
            with zf.open(info) as src, open(exe_path, 'wb') as dst:
                shutil.copyfileobj(src, dst)
            print(f'Extracted {info.filename}')
os.remove(zip_path)
print('Done')
"
echo "\n[flowcraft:exit:$?]"