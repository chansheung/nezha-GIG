#!/bin/bash
$setupScript = @"
#!/bin/bash
set -e

LOG="/tmp/setup_output.txt"
> "$LOG"

# Step 1: Set DMX_API_KEY
echo "=== Step 1: Set DMX_API_KEY ===" >> "$LOG"
grep -q 'DMX_API_KEY' ~/.bashrc 2>/dev/null || echo 'export DMX_API_KEY=sk-AbaIOQg4LcwGqgkqSTrqGbaxhui91of6UuBiMwMmfsB8xekO' >> ~/.bashrc
export DMX_API_KEY=sk-AbaIOQg4LcwGqgkqSTrqGbaxhui91of6UuBiMwMmfsB8xekO
echo "DMX_API_KEY=$DMX_API_KEY" >> "$LOG"

# Step 2: Check opencode in PATH
echo "=== Step 2: Check opencode ===" >> "$LOG"
export PATH="$HOME/.opencode/bin:$PATH"
if which opencode 2>/dev/null; then
    echo "opencode found: $(which opencode)" >> "$LOG"
else
    echo "opencode NOT in PATH, adding..." >> "$LOG"
    grep -q 'opencode/bin' ~/.bashrc 2>/dev/null || echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
    echo "opencode path added to bashrc" >> "$LOG"
fi
which opencode >> "$LOG" 2>&1 || echo "still not found" >> "$LOG"

# Step 3: Install Node.js via nvm
echo "=== Step 3: Install Node.js ===" >> "$LOG"
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing nvm..." >> "$LOG"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash >> "$LOG" 2>&1
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts >> "$LOG" 2>&1
echo "node: $(node --version)" >> "$LOG" 2>&1
echo "npm: $(npm --version)" >> "$LOG" 2>&1

# Step 4: Copy flowcraft
echo "=== Step 4: Copy flowcraft ===" >> "$LOG"
if [ ! -d "$HOME/flowcraft" ]; then
    cp -r /mnt/c/Users/well/flowcraft ~/flowcraft >> "$LOG" 2>&1
    echo "Copied flowcraft" >> "$LOG"
else
    echo "flowcraft already exists, skipping copy" >> "$LOG"
fi
cd ~/flowcraft
npm install >> "$LOG" 2>&1
echo "ls @opencode-ai:" >> "$LOG"
ls node_modules/@opencode-ai/ >> "$LOG" 2>&1 || echo "no @opencode-ai dir" >> "$LOG"

echo "=== DONE ===" >> "$LOG"
cat "$LOG"
"@

Set-Content -Path "C:\Users\well\AppData\Local\Temp\opencode\setup_wsl.sh" -Value $setupScript -Encoding UTF8
echo "\n[flowcraft:exit:$?]"