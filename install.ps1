#Requires -Version 5.1
# Claude Code Power User Setup — Phalkon Dev
# Tested on: Windows 10/11, PowerShell 5.1+
#
# Run:
#   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   .\install.ps1

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"   # prevents slow Invoke-WebRequest progress bar

$CLAUDE_DIR  = "$env:USERPROFILE\.claude"
$SCRIPT_DIR  = $PSScriptRoot
$INSTALL_DIR = "$env:USERPROFILE\.local\bin"

# ── Output helpers ────────────────────────────────────────────────────────────
function ok($msg)      { Write-Host "  [OK] $msg" -ForegroundColor Green }
function warn($msg)    { Write-Host "  [!]  $msg" -ForegroundColor Yellow }
function fail($msg)    { Write-Host "  [X]  $msg" -ForegroundColor Red; exit 1 }
function note($msg)    { Write-Host "       $msg" -ForegroundColor DarkGray }
function prompt_($msg) { Write-Host "  [?]  $msg" -ForegroundColor Cyan }
function action($msg)  { Write-Host "  [>]  $msg" -ForegroundColor Blue }

function section($title) {
    Write-Host ""
    Write-Host ("=" * 50) -ForegroundColor White
    Write-Host "  $title" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ("=" * 50) -ForegroundColor White
    Write-Host ""
}

function Read-YesNo($defaultYes = $true) {
    $ans = Read-Host "  -> "
    if ([string]::IsNullOrWhiteSpace($ans)) { return $defaultYes }
    return $ans -match "^[Yy]"
}

function Ensure-ProfileExists {
    if (!(Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
}

function Add-ToProfile($line) {
    Ensure-ProfileExists
    $content = (Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue) ?? ""
    if ($content -notlike "*$line*") {
        Add-Content -Path $PROFILE -Value ""
        Add-Content -Path $PROFILE -Value $line
    }
}

function Add-ToUserPath($dir) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User") ?? ""
    if ($userPath -notlike "*$dir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$dir", "User")
        $env:PATH += ";$dir"
        ok "Added $dir to user PATH"
    }
}

function Restrict-FilePermissions($path) {
    $acl = Get-Acl $path
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $env:USERNAME, "FullControl", "Allow"
    )
    $acl.SetAccessRule($rule)
    Set-Acl $path $acl
}

# ═════════════════════════════════════════════════════════════════════════════
#  WELCOME
# ═════════════════════════════════════════════════════════════════════════════

Clear-Host
Write-Host ""
Write-Host "  +================================================+" -ForegroundColor Cyan
Write-Host "  |   Claude Code Power User Setup                 |" -ForegroundColor Cyan
Write-Host "  |   Phalkon Dev — github.com/Phalkon-Dev         |" -ForegroundColor Cyan
Write-Host "  +================================================+" -ForegroundColor Cyan
Write-Host ""
Write-Host "  This script sets up a complete AI-assisted development environment"
Write-Host "  on Windows 10/11. It walks through 13 steps, backs up existing files"
Write-Host "  before touching them, and asks before overwriting anything."
Write-Host ""
Write-Host "  Tools installed: Claude Code config, RTK, Headroom, Ruflo MCP,"
Write-Host "  DeepSeek integration, PowerShell aliases, GSD workflow."
Write-Host ""
Read-Host "  Press Enter to begin, or Ctrl+C to cancel"


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 1 — PREREQUISITES
# ═════════════════════════════════════════════════════════════════════════════

section "Step 1 of 13 — Prerequisites"

Write-Host "  Checking that required tools are available."
Write-Host "  Missing tools will be offered for automatic installation."
Write-Host ""

# Check winget availability once upfront
$script:hasWinget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
if (-not $script:hasWinget) {
    warn "winget not found (ships with Windows 10 1709+ via App Installer)."
    note "Get it: ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    note "Missing tools must be installed manually if winget is unavailable."
    Write-Host ""
}

function Install-IfMissing($label, $cmd, $wingetId, $fallbackUrl) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return }
    warn "$label is not installed."
    if (-not $script:hasWinget) {
        note "Install manually: $fallbackUrl"
        fail "Install $label, restart PowerShell, and re-run this script."
    }
    prompt_ "Install $label now? [Y/n]"
    $ans = Read-Host "  -> "
    if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match '^[Yy]') {
        action "winget install --id $wingetId -e --source winget"
        winget install --id $wingetId -e --source winget
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            warn "$label installed but not yet in PATH."
            note "Restart PowerShell and re-run this script."
            fail "PATH not updated — restart required."
        }
    } else {
        note "Skipped. Install manually: winget install --id $wingetId -e"
        fail "Install $label and re-run this script."
    }
}

Install-IfMissing "Node.js" "node" "OpenJS.NodeJS.LTS" "https://nodejs.org/"
Install-IfMissing "Git"     "git"  "Git.Git"           "https://git-scm.com/download/win"

if (!(Get-Command npx -ErrorAction SilentlyContinue)) {
    fail "npx not found — it ships with Node.js, try reinstalling Node."
}

$nodeVer = (node -e "process.stdout.write(process.version.slice(1).split('.')[0])") -as [int]
if ($nodeVer -lt 18) {
    fail "Node.js 18+ required. You have: $(node --version). Run: winget install OpenJS.NodeJS.LTS"
}

ok "Node.js $(node --version)"
ok "npx available"
ok "Git $(git --version)"

# Python: needed by Headroom — offer auto-install, but don't hard-fail if missing
$pythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
             elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" }
             else { $null }
$pipCmd = if (Get-Command pip3 -ErrorAction SilentlyContinue) { "pip3" }
          elseif (Get-Command pip -ErrorAction SilentlyContinue) { "pip" }
          else { $null }

if (-not $pythonCmd) {
    warn "Python 3 not found. Headroom install (Step 8) will be skipped."
    if ($script:hasWinget) {
        prompt_ "Install Python 3 now? [Y/n]"
        $ans = Read-Host "  -> "
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match '^[Yy]') {
            action "winget install --id Python.Python.3.13 -e --source winget"
            winget install --id Python.Python.3.13 -e --source winget
            $pythonCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
                         elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" }
                         else { $null }
            if (-not $pythonCmd) {
                note "Python installed — restart PowerShell and re-run for Headroom setup."
            }
        }
    } else {
        note "Install from: https://python.org/downloads — check 'Add Python to PATH'"
    }
} elseif (-not $pipCmd) {
    action "Trying $pythonCmd -m ensurepip --upgrade ..."
    & $pythonCmd -m ensurepip --upgrade 2>$null
    $pipCmd = if (Get-Command pip3 -ErrorAction SilentlyContinue) { "pip3" }
              elseif (Get-Command pip -ErrorAction SilentlyContinue) { "pip" }
              else { $null }
    if (-not $pipCmd) {
        warn "pip still not found. Headroom install (Step 8) will be skipped."
    }
}

if ($pythonCmd -and $pipCmd) {
    $pyVer = (& $pythonCmd --version 2>&1) -replace "Python ", ""
    ok "Python $pyVer"
    ok "pip available"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 2 — CLAUDE CODE
# ═════════════════════════════════════════════════════════════════════════════

section "Step 2 of 13 — Claude Code"

Write-Host "  Claude Code is Anthropic's official AI CLI for software development."
Write-Host "  It lets you chat with Claude directly in your terminal, edit files,"
Write-Host "  run commands, and use multi-agent workflows — all from the command line."
Write-Host ""
note "Install from: https://claude.ai/download  (native installer, not npm)"
Write-Host ""

if (Get-Command claude -ErrorAction SilentlyContinue) {
    $ver = (claude --version 2>$null) ?? "version unknown"
    ok "Claude Code already installed — $ver"
} else {
    warn "Claude Code is not installed."
    Write-Host ""
    Write-Host "  Download and run the native installer from https://claude.ai/download"
    Write-Host "  then re-run this script. The native installer is required — do not use"
    Write-Host "  the npm package, which is a different (older) tool."
    Write-Host ""
    Read-Host "  Press Enter to continue in config-only mode, or Ctrl+C to install Claude first"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 3 — ANTHROPIC API KEY
# ═════════════════════════════════════════════════════════════════════════════

section "Step 3 of 13 — Anthropic Authentication"

Write-Host "  Claude Code needs to authenticate with Anthropic's API to function."
Write-Host "  There are two ways to do this:"
Write-Host ""
Write-Host "    Option A — Claude.ai subscription (Pro or Max plan):"
Write-Host "      No key needed here. After this script finishes, run 'claude' and"
Write-Host "      it will open your browser to log in with your Claude.ai account."
Write-Host ""
Write-Host "    Option B — Anthropic API key:"
Write-Host "      For users who pay per-use via the API (console.anthropic.com)."
Write-Host "      The key starts with 'sk-ant-...' and is found in your API settings."
Write-Host ""
note "Your key will be stored in $CLAUDE_DIR\anthropic_env.ps1 with restricted permissions."
note "It will NOT be written to any world-readable file."
Write-Host ""

$credsFile  = "$CLAUDE_DIR\.credentials.json"
$apiKeySet  = $false

if ((Test-Path $credsFile) -and (Get-Item $credsFile).Length -gt 0) {
    ok "Existing credentials file found — Claude Code is already authenticated"
    $apiKeySet = $true
}
if ($env:ANTHROPIC_API_KEY) {
    ok "ANTHROPIC_API_KEY is already set in the current environment"
    $apiKeySet = $true
}

if (!$apiKeySet) {
    prompt_ "Do you have an Anthropic API key to enter now? (y/N)"
    note "Say N if you use a Claude.ai subscription — you'll log in after setup."
    if (Read-YesNo $false) {
        $secureKey = Read-Host "  Paste your Anthropic API key (input is hidden)" -AsSecureString
        $key = [System.Net.NetworkCredential]::new("", $secureKey).Password
        if ($key) {
            New-Item -ItemType Directory -Force -Path $CLAUDE_DIR | Out-Null
            $secretsFile = "$CLAUDE_DIR\anthropic_env.ps1"
            Set-Content -Path $secretsFile -Value "`$env:ANTHROPIC_API_KEY = '$key'"
            Restrict-FilePermissions $secretsFile
            ok "Key saved to $secretsFile (owner-only permissions)"
            Add-ToProfile ". `"$secretsFile`""
            ok "Added loader line to PowerShell profile"
            $env:ANTHROPIC_API_KEY = $key
        } else {
            warn "Nothing entered — skipping. Run 'claude' after setup to authenticate via browser."
        }
    } else {
        warn "Skipping. After setup, run 'claude' and follow the browser login prompt."
    }
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 4 — GIT IDENTITY
# ═════════════════════════════════════════════════════════════════════════════

section "Step 4 of 13 — Git Identity"

Write-Host "  Git requires a name and email to attach to every commit you make."
Write-Host "  If these are not set, 'git commit' will fail with an error."
Write-Host "  This sets them globally (~/.gitconfig), so they apply to all repos."
Write-Host ""

$gitName  = (git config --global user.name  2>$null) ?? ""
$gitEmail = (git config --global user.email 2>$null) ?? ""

if ($gitName -and $gitEmail) {
    ok "Git identity already configured: $gitName <$gitEmail>"
} else {
    warn "Git identity is not fully configured."
    Write-Host ""
    if (!$gitName) {
        prompt_ "Your full name (will appear in git commits, e.g. 'Ana Garcia'):"
        $inputName = Read-Host "  -> "
        if ($inputName) {
            git config --global user.name $inputName
            ok "git user.name set to: $inputName"
        } else {
            warn "Skipped — git commits may fail until this is set."
        }
    }
    if (!$gitEmail) {
        prompt_ "Your work email (will appear in git commits):"
        $inputEmail = Read-Host "  -> "
        if ($inputEmail) {
            git config --global user.email $inputEmail
            ok "git user.email set to: $inputEmail"
        } else {
            warn "Skipped — git commits may fail until this is set."
        }
    }
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 5 — RTK (RUST TOKEN KILLER)
# ═════════════════════════════════════════════════════════════════════════════

section "Step 5 of 13 — RTK (Rust Token Killer)"

Write-Host "  Every time Claude runs a shell command (git status, ls, npm install...),"
Write-Host "  the full raw output is sent back as tokens. On a busy session this adds"
Write-Host "  up fast and drives API costs up."
Write-Host ""
Write-Host "  RTK sits between Claude and your shell. It intercepts command output and"
Write-Host "  strips everything that isn't useful to Claude — cutting token usage by"
Write-Host "  60-90% on typical dev operations."
Write-Host ""
Write-Host "  RTK is activated automatically via a hook in settings.json. Once installed,"
Write-Host "  it works silently in the background — no change to how you use Claude."
Write-Host ""
note "Source: https://github.com/rtk-ai/rtk"
note "Binary will be placed at: $INSTALL_DIR\rtk.exe"
Write-Host ""

function Install-RTK {
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
    $filename   = "rtk-x86_64-pc-windows-msvc.zip"
    $url        = "https://github.com/rtk-ai/rtk/releases/latest/download/$filename"
    $zipPath    = "$INSTALL_DIR\$filename"
    $extractDir = "$INSTALL_DIR\rtk-extract"
    $dest       = "$INSTALL_DIR\rtk.exe"
    action "Downloading $filename from GitHub releases..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        $exePath = Get-ChildItem -Path $extractDir -Filter "rtk.exe" -Recurse |
                   Select-Object -First 1 -ExpandProperty FullName
        if (-not $exePath) { throw "rtk.exe not found in archive" }
        Move-Item $exePath $dest -Force
        Remove-Item $zipPath    -Force
        Remove-Item $extractDir -Recurse -Force
        Add-ToUserPath $INSTALL_DIR
        $ver = (& $dest --version 2>$null) ?? "version unknown"
        ok "RTK installed — $ver"
        return $true
    } catch {
        warn "Download failed: $_"
        warn "Install manually from: https://github.com/rtk-ai/rtk"
        if (Test-Path $zipPath)    { Remove-Item $zipPath    -Force -ErrorAction SilentlyContinue }
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue }
        return $false
    }
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
    $ver = (rtk --version 2>$null) ?? ""
    ok "RTK already installed — $ver"
} else {
    prompt_ "Install RTK now? (Y/n)"
    note "Recommended — significant cost and speed improvement over time."
    if (Read-YesNo $true) {
        Install-RTK | Out-Null
    } else {
        warn "Skipping RTK. You can install it later from: https://github.com/rtk-ai/rtk"
    }
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 6 — HEADROOM
# ═════════════════════════════════════════════════════════════════════════════

section "Step 6 of 13 — Headroom (Context Compression)"

Write-Host "  Headroom is a context compression proxy. It sits between Claude Code and"
Write-Host "  the AI provider, intercepting every API request and compressing the context"
Write-Host "  window by stripping redundant content before it is sent."
Write-Host ""
Write-Host "  This reduces token usage by 60-95% per session — meaning longer sessions"
Write-Host "  before hitting context limits and lower API costs."
Write-Host ""
Write-Host "  The aliases 'claude-default' and 'claude-deepseek' launch Claude Code"
Write-Host "  through Headroom automatically. No manual configuration needed once installed."
Write-Host ""
note "Source: https://github.com/headroomlabs-ai/headroom"
note "Install: pip install 'headroom-ai[all]'  (Python package — no binary download)"
Write-Host ""

function Install-Headroom {
    $pipCmd = if (Get-Command pip3 -ErrorAction SilentlyContinue) { "pip3" }
              elseif (Get-Command pip -ErrorAction SilentlyContinue) { "pip" }
              else { $null }
    if (-not $pipCmd) {
        warn "pip not found. Install Python first (https://python.org), then run:"
        note "  pip install 'headroom-ai[all]'"
        return $false
    }
    action "Installing headroom-ai Python package via $pipCmd..."
    try {
        & $pipCmd install "headroom-ai[all]"
        $ver = (headroom --version 2>$null) ?? "version unknown"
        ok "Headroom installed — $ver"
        return $true
    } catch {
        warn "pip install failed: $_"
        warn "Install manually: pip install 'headroom-ai[all]'"
        return $false
    }
}

if (Get-Command headroom -ErrorAction SilentlyContinue) {
    $ver = (headroom --version 2>$null) ?? ""
    ok "Headroom already installed — $ver"
} else {
    prompt_ "Install Headroom now? (Y/n)"
    note "Required if you want to use DeepSeek or switch AI providers."
    if (Read-YesNo $true) {
        Install-Headroom | Out-Null
    } else {
        warn "Skipping Headroom. The claude-deepseek alias will not work without it."
    }
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 7 — DEEPSEEK API KEY
# ═════════════════════════════════════════════════════════════════════════════

section "Step 7 of 13 — DeepSeek API Key"

Write-Host "  DeepSeek is a Chinese AI lab that offers models competitive with Claude"
Write-Host "  at a fraction of the cost. Via Headroom, Claude Code can be pointed at"
Write-Host "  DeepSeek's API for tasks where you don't need Anthropic-level quality"
Write-Host "  (e.g. boilerplate generation, simple refactors, documentation)."
Write-Host ""
Write-Host "  Once configured, you switch providers with a single command:"
Write-Host ""
Write-Host "    claude-default     -> launches Claude Code using Anthropic's API"
Write-Host "    claude-deepseek    -> launches Claude Code using DeepSeek's API"
Write-Host ""
Write-Host "  Get a DeepSeek API key at: https://platform.deepseek.com"
Write-Host "  Keys start with 'sk-...'"
Write-Host ""
note "Your key will be stored in $CLAUDE_DIR\deepseek_env.ps1 with restricted permissions."
Write-Host ""

$deepseekEnv = "$CLAUDE_DIR\deepseek_env.ps1"

if ((Test-Path $deepseekEnv) -and (Get-Item $deepseekEnv).Length -gt 0) {
    ok "DeepSeek credentials file already exists at $deepseekEnv"
} else {
    prompt_ "Do you have a DeepSeek API key to configure now? (y/N)"
    note "Optional — add it later by creating $deepseekEnv"
    if (Read-YesNo $false) {
        $secureKey = Read-Host "  Paste your DeepSeek API key (input is hidden)" -AsSecureString
        $key = [System.Net.NetworkCredential]::new("", $secureKey).Password
        if ($key) {
            New-Item -ItemType Directory -Force -Path $CLAUDE_DIR | Out-Null
            Set-Content -Path $deepseekEnv -Value "`$env:DEEPSEEK_API_KEY = '$key'"
            Restrict-FilePermissions $deepseekEnv
            ok "Key saved to $deepseekEnv (owner-only permissions)"
            Add-ToProfile ". `"$deepseekEnv`""
            ok "Added loader line to PowerShell profile"
        } else {
            warn "Nothing entered — skipping."
        }
    } else {
        warn "Skipping. To add it later, create $deepseekEnv with:"
        note "  `$env:DEEPSEEK_API_KEY = 'your-key-here'"
    }
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 8 — RUFLO MCP SERVER
# ═════════════════════════════════════════════════════════════════════════════

section "Step 8 of 13 — Ruflo MCP Server"

Write-Host "  MCP (Model Context Protocol) lets Claude Code connect to external tools."
Write-Host "  Ruflo is the MCP server for claude-flow, which adds three capabilities:"
Write-Host ""
Write-Host "    * Multi-agent orchestration — spawn specialized sub-agents that work"
Write-Host "      in parallel on different parts of a task, then combine their output."
Write-Host ""
Write-Host "    * Persistent memory — Claude remembers patterns and context across"
Write-Host "      sessions using a hybrid vector+graph memory store."
Write-Host ""
Write-Host "    * Workflow hooks — automated actions before/after tool use."
Write-Host ""
Write-Host "  Ruflo is configured in ~/.mcp.json and starts on demand via npx."
Write-Host "  No separate install required — it downloads automatically on first use."
Write-Host ""
note "Config will be written to: $env:USERPROFILE\.mcp.json"
note "Mode: v3, topology: hierarchical-mesh, max agents: 15"
Write-Host ""

$mcpDest = "$env:USERPROFILE\.mcp.json"
$mcpSrc  = "$SCRIPT_DIR\config\.mcp.json"

if (Test-Path $mcpDest) {
    $mcpContent = Get-Content $mcpDest -Raw
    if ($mcpContent -like '*"ruflo"*') {
        ok "Ruflo already present in $mcpDest"
    } else {
        warn "$mcpDest exists but doesn't include ruflo."
        action "You'll need to manually merge $mcpSrc into $mcpDest"
    }
} else {
    action "Creating $mcpDest with ruflo MCP server configuration..."
    Copy-Item $mcpSrc $mcpDest
    ok "$mcpDest created"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 9 — CLAUDE CODE SETTINGS
# ═════════════════════════════════════════════════════════════════════════════

section "Step 9 of 13 — Claude Code Settings"

Write-Host "  Two configuration files control how Claude Code behaves:"
Write-Host ""
Write-Host "  settings.json — the main config. This sets:"
Write-Host "    * Model: claude-sonnet-4-6 (main), claude-haiku-4-5 (fast tasks)"
Write-Host "    * Permissions: pre-approved bash commands (git, npm, python, curl...)"
Write-Host "    * Plugins: 15+ curated plugins enabled"
Write-Host "    * Hooks: RTK token-saver, GSD context monitor, GSD status line"
Write-Host ""
Write-Host "  settings.local.json — machine-specific overrides. This sets:"
Write-Host "    * ANTHROPIC_BASE_URL to http://127.0.0.1:8787 (the Headroom proxy)"
Write-Host ""
note "Files written to: $CLAUDE_DIR\settings.json and $CLAUDE_DIR\settings.local.json"
Write-Host ""

New-Item -ItemType Directory -Force -Path $CLAUDE_DIR | Out-Null

$settingsDest = "$CLAUDE_DIR\settings.json"
$settingsSrc  = "$SCRIPT_DIR\config\settings.json"

if (Test-Path $settingsDest) {
    warn "settings.json already exists at $settingsDest"
    Write-Host "  Overwriting it will replace your current Claude Code configuration."
    Write-Host "  A backup will be saved to settings.json.bak first."
    Write-Host ""
    prompt_ "Overwrite your existing settings.json with the Phalkon defaults? (Y/n)"
    if (Read-YesNo $true) {
        Copy-Item $settingsDest "$settingsDest.bak"
        ok "Backup saved to $settingsDest.bak"
        Copy-Item $settingsSrc $settingsDest
        ok "settings.json installed"
    } else {
        warn "Skipping settings.json. Your existing config is unchanged."
        note "To apply later: Copy-Item $settingsSrc $settingsDest"
    }
} else {
    action "Writing settings.json..."
    Copy-Item $settingsSrc $settingsDest
    ok "settings.json installed"
}

$localDest = "$CLAUDE_DIR\settings.local.json"
$localSrc  = "$SCRIPT_DIR\config\settings.local.json"

if (Test-Path $localDest) {
    warn "settings.local.json already exists at $localDest"
    Write-Host "  The Phalkon version sets ANTHROPIC_BASE_URL to the Headroom proxy."
    Write-Host ""
    prompt_ "Overwrite your existing settings.local.json? (Y/n)"
    if (Read-YesNo $true) {
        Copy-Item $localDest "$localDest.bak"
        ok "Backup saved to $localDest.bak"
        Copy-Item $localSrc $localDest
        ok "settings.local.json installed"
    } else {
        warn "Skipping settings.local.json. Your existing overrides are unchanged."
    }
} else {
    action "Writing settings.local.json (Headroom proxy config)..."
    Copy-Item $localSrc $localDest
    ok "settings.local.json installed"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 10 — CLAUDE.md (GLOBAL RULES)
# ═════════════════════════════════════════════════════════════════════════════

section "Step 10 of 13 — CLAUDE.md (Global Rules)"

Write-Host "  CLAUDE.md is a special file that Claude Code reads automatically at the"
Write-Host "  start of every session. It contains persistent instructions that shape"
Write-Host "  how Claude behaves — without you having to repeat them every time."
Write-Host ""
Write-Host "  The global CLAUDE.md (at $CLAUDE_DIR\CLAUDE.md) applies to ALL projects."
Write-Host "  Individual projects can have their own CLAUDE.md at the repo root."
Write-Host ""
note "If CLAUDE.md already exists, it will NOT be overwritten."
note "Diff the new version with: Compare-Object (Get-Content $CLAUDE_DIR\CLAUDE.md) (Get-Content $SCRIPT_DIR\config\CLAUDE.md)"
Write-Host ""

$claudeMdDest = "$CLAUDE_DIR\CLAUDE.md"

if (Test-Path $claudeMdDest) {
    warn "$claudeMdDest already exists — skipping to avoid overwriting your customizations."
    note "Review $SCRIPT_DIR\config\CLAUDE.md and manually merge any sections you want."
} else {
    action "Writing $claudeMdDest..."
    Copy-Item "$SCRIPT_DIR\config\CLAUDE.md" $claudeMdDest
    ok "CLAUDE.md installed"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 11 — REFERENCE DOCS
# ═════════════════════════════════════════════════════════════════════════════

section "Step 11 of 13 — Reference Docs"

Write-Host "  Two reference documents are installed into $CLAUDE_DIR so Claude can"
Write-Host "  read them during sessions when needed:"
Write-Host ""
Write-Host "  RTK.md — quick reference for RTK commands (rtk gain, rtk discover, etc.)"
Write-Host "    Loaded via @RTK.md in CLAUDE.md so it's always available."
Write-Host ""
Write-Host "  project-workflow.md — the full Phalkon project lifecycle guide:"
Write-Host "    repo creation from templates, docs structure, session protocols,"
Write-Host "    template sync workflow, and all GSD slash commands."
Write-Host ""
note "If these files already exist you will be asked before overwriting."
Write-Host ""

function Install-RefDoc($src, $dest, $label) {
    if (Test-Path $dest) {
        warn "$dest already exists."
        Write-Host "  This file may have been customized. Overwriting replaces it with the"
        Write-Host "  latest version from the Phalkon setup repo."
        Write-Host ""
        prompt_ "Overwrite $label? (Y/n)"
        if (Read-YesNo $true) {
            Copy-Item $dest "$dest.bak"
            ok "Backup saved to $dest.bak"
            Copy-Item $src $dest
            ok "$label updated"
        } else {
            warn "Skipping $label — existing file kept."
        }
    } else {
        action "Writing $label..."
        Copy-Item $src $dest
        ok "$label installed"
    }
}

Install-RefDoc "$SCRIPT_DIR\config\RTK.md"            "$CLAUDE_DIR\RTK.md"            "RTK.md"
Install-RefDoc "$SCRIPT_DIR\docs\project-workflow.md" "$CLAUDE_DIR\project-workflow.md" "project-workflow.md"


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 12 — POWERSHELL ALIASES
# ═════════════════════════════════════════════════════════════════════════════

section "Step 12 of 13 — PowerShell Aliases"

Write-Host "  A set of productivity aliases for PowerShell, covering:"
Write-Host ""
Write-Host "    * git shortcuts     (gst, gp, gpl, git-commit, gcb, gl...)"
Write-Host "    * Python / venv     (a = activate, create-venv, pip-install...)"
Write-Host "    * Docker            (dps, dcup, dcdown, dlog...)"
Write-Host "    * System tools      (ll, myip, listen, genpass...)"
Write-Host "    * Claude + Headroom (claude-default, claude-deepseek and -continue variants)"
Write-Host ""
Write-Host "  The Claude/Headroom aliases let you launch Claude Code through the"
Write-Host "  Headroom proxy with a single word:"
Write-Host ""
Write-Host "    claude-default           -> Claude Code via Anthropic API"
Write-Host "    claude-default-continue  -> same, resumes your last session"
Write-Host "    claude-deepseek          -> Claude Code via DeepSeek API (cheaper)"
Write-Host "    claude-deepseek-continue -> same, resumes your last session"
Write-Host ""

$aliasesDest = "$CLAUDE_DIR\aliases.ps1"
$aliasesSrc  = "$SCRIPT_DIR\powershell\aliases.ps1"

if (Test-Path $aliasesDest) {
    warn "$aliasesDest already exists — skipping to avoid overwriting your aliases."
    note "Review $aliasesSrc and add the functions you want manually."
} else {
    action "Writing $aliasesDest..."
    Copy-Item $aliasesSrc $aliasesDest
    ok "$aliasesDest installed"
    Add-ToProfile ". `"$aliasesDest`""
    ok "Added dot-source to PowerShell profile ($PROFILE)"
}


# ═════════════════════════════════════════════════════════════════════════════
#  STEP 13 — DONE
# ═════════════════════════════════════════════════════════════════════════════

section "Step 13 of 13 — Complete"

Write-Host "  All done! Here's what to do next:" -ForegroundColor Green
Write-Host ""
Write-Host "  (1) Reload your PowerShell profile to activate aliases:"
Write-Host ""
Write-Host "        . `$PROFILE"
Write-Host ""
Write-Host "  (2) Launch Claude Code for the first time:"
Write-Host ""
Write-Host "        claude                   (direct, uses Anthropic API)"
Write-Host "        claude-default           (through Headroom proxy)"
Write-Host "        claude-deepseek          (through Headroom -> DeepSeek API)"
Write-Host ""
Write-Host "     On first run, if you didn't set an API key in Step 3, Claude will"
Write-Host "     open your browser to log in with your Claude.ai account."
Write-Host ""
Write-Host "  (3) Inside Claude Code, install the plugin suite:"
Write-Host ""
Write-Host "        /plugins"
Write-Host ""
Write-Host "     Enable these official plugins:"
Write-Host "       frontend-design, code-review, feature-dev, playwright,"
Write-Host "       claude-md-management, security-guidance, commit-commands,"
Write-Host "       claude-code-setup, pr-review-toolkit, pyright-lsp,"
Write-Host "       atlassian, remember, circleback"
Write-Host ""
Write-Host "     Third-party plugins (marketplaces already registered in settings.json):"
Write-Host "       claude-mem (thedotmack), cc-fleet (ethanhq),"
Write-Host "       andrej-karpathy-skills (karpathy-skills)"
Write-Host ""
Write-Host "  (4) Check your RTK token savings after your first session:"
Write-Host ""
Write-Host "        rtk gain"
Write-Host ""
Write-Host "  (5) Start a new project with the Phalkon workflow:"
Write-Host ""
Write-Host "        /gsd:new-project"
Write-Host ""
Write-Host "  Full reference guide: $SCRIPT_DIR\README.md"
Write-Host ""
Write-Host "  Installed by: https://github.com/Phalkon-Dev/claude-setup" -ForegroundColor DarkGray
Write-Host ""
