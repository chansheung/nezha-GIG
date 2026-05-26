#!/bin/bash
$scriptContent = @'
#!/bin/bash
exec > /tmp/setup_output.txt 2>&1

echo "=== STEP 1: Set DMX_API_KEY ==="
grep -q 'DMX_API_KEY' ~/.bashrc
if [ $? -ne 0 ]; then
    echo 'export DMX_API_KEY=sk-AbaIOQg4LcwGqgkqSTrqGbaxhui91of6UuBiMwMmfsB8xekO' >> ~/.bashrc
    echo "Added DMX_API_KEY to ~/.bashrc"
else
    echo "DMX_API_KEY already in ~/.bashrc"
fi
source ~/.bashrc
echo "DMX_API_KEY=$DMX_API_KEY"

echo ""
echo "=== STEP 2: Check opencode in PATH ==="
which opencode 2>/dev/null
if [ $? -ne 0 ]; then
    echo "opencode NOT IN PATH"
    grep -q 'opencode/bin' ~/.bashrc
    if [ $? -ne 0 ]; then
        echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.bashrc
        echo "Added opencode to PATH in ~/.bashrc"
    fi
    source ~/.bashrc
    which opencode 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "opencode still NOT found after adding to PATH"
    else
        echo "opencode found at: $(which opencode)"
    fi
else
    echo "opencode found at: $(which opencode)"
fi

echo ""
echo "=== STEP 3: Install Node.js via nvm ==="
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    echo "nvm already installed"
else
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts
echo "node: $(node --version)"
echo "npm: $(npm --version)"

echo ""
echo "=== STEP 4: Copy flowcraft plugin ==="
if [ -d /mnt/c/Users/well/flowcraft ]; then
    cp -r /mnt/c/Users/well/flowcraft ~/flowcraft
    echo "Copied flowcraft to ~/flowcraft"
    cd ~/flowcraft
    npm install
    echo "npm install completed"
    ls node_modules/@opencode-ai/ 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "@opencode-ai packages found"
    else
        echo "@opencode-ai directory not found in node_modules"
        ls node_modules/ | head -20
    fi
else
    echo "ERROR: /mnt/c/Users/well/flowcraft not found"
fi

echo ""
echo "=== DONE ==="
'@
[System.IO.File]::WriteAllText("C:\Users\well\AppData\Local\Temp\opencode\setup_wsl.sh", $scriptContent)
Write-Output "Script written"
echo "\n[flowcraft:exit:$?]"