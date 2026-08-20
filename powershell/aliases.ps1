# Claude Code Power User — PowerShell Aliases
# Source this file from your PowerShell profile ($PROFILE):
#   . "$env:USERPROFILE\.claude\aliases.ps1"  (or wherever you put this)
#
# Note: some names differ from the bash version to avoid conflicts with
# built-in PowerShell aliases (gc = Get-Content, gm = Get-Member, etc.)

# System
function ll   { Get-ChildItem -Force @args }
function la   { Get-ChildItem -Force @args }
function l    { Get-ChildItem @args }
function ..   { Set-Location .. }
function ...  { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function reload { . $PROFILE }
function df   { Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } }
function free {
    $os = Get-CimInstance Win32_OperatingSystem
    "Total: $([math]::Round($os.TotalVisibleMemorySize/1KB))MB   Free: $([math]::Round($os.FreePhysicalMemory/1KB))MB"
}

# Git (gc/gm/gs conflict with PS built-ins — use git-commit/git-merge/git-stash)
Set-Alias -Name g    -Value git
function ga          { git add @args }
function gaa         { git add --all }
function gst         { git status }
function git-commit  { git commit -m @args }
function gca         { git commit -am @args }
function gcl         { git clone @args }
function gco         { git checkout @args }
function gcb         { git checkout -b @args }
function gp          { git push @args }
function gpl         { git pull }
function gf          { git fetch }
function gb          { git branch @args }
function git-merge   { git merge @args }
function gd          { git diff @args }
function gl          { git log --oneline --graph --decorate @args }
function glog        { git log --oneline --graph --decorate --all }
function grm         { git remote @args }
function grv         { git remote -v }
function grs         { git reset @args }
function grsh        { git reset --hard @args }
function grss        { git reset --soft @args }
function git-stash   { git stash @args }
function gsp         { git stash pop }
function gsl         { git stash list }

# Python virtual environment
Set-Alias -Name py   -Value python
function pvenv       { python -m venv @args }
function create-venv { python -m venv .venv }
function a           { .\.venv\Scripts\Activate.ps1 }
function pip-upgrade { pip install --upgrade pip }
function pip-install { pip install -r requirements.txt }
function pip-freeze  { pip freeze | Out-File requirements.txt }
function pip-list_   { pip list }
function django-run  { python manage.py runserver }
function django-migrate       { python manage.py migrate }
function django-makemigrations { python manage.py makemigrations }
function django-shell { python manage.py shell }

# Quick project setup
function setup-django  { create-venv; a; pip install django }
function setup-flask   { create-venv; a; pip install flask; New-Item -ItemType File app.py }
function setup-fastapi { create-venv; a; pip install fastapi uvicorn; New-Item -ItemType File main.py }

# Docker
function dps      { docker ps }
function dpsa     { docker ps -a }
function di       { docker images }
function drmi     { docker rmi @args }
function drm_     { docker rm @args }
function dst      { docker start @args }
function dsp      { docker stop @args }
function dex      { docker exec -it @args }
function dlog     { docker logs @args }
function dprune   { docker system prune -af }
function dcup     { docker-compose up -d @args }
function dcdown   { docker-compose down }
function dcrestart { docker-compose restart @args }
function dclogs   { docker-compose logs -f @args }

# Network
function myip    { (Invoke-WebRequest -UseBasicParsing "http://ipecho.net/plain").Content.Trim() }
function listen  { netstat -ano | Select-String "LISTENING" }
function ports   { netstat -ano }

# Process management
function psa     { Get-Process }
function psg     { param($name) Get-Process | Where-Object { $_.Name -like "*$name*" } }
function psm     { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 }
function psc     { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# System info
function cpuinfo  { Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed }
function meminfo  { free }
function diskinfo { df }

# Passwords
function genpass {
    $bytes = [byte[]]::new(20)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}
function genpass-strong {
    $bytes = [byte[]]::new(32)
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    [Convert]::ToBase64String($bytes)
}

# Date and time
function now      { Get-Date -Format "HH:mm:ss" }
function nowdate  { Get-Date -Format "dd-MM-yyyy" }
function today    { Get-Date -Format "dddd, MMMM d, yyyy" }

# Misc
function h        { Get-History }
function c        { Clear-Host }
function path_    { $env:PATH -split ";" }
function catn     { $i = 1; Get-Content @args | ForEach-Object { "{0}`t{1}" -f $i, $_; $i++ } }
function clip_    { Set-Clipboard @args }
function paste_   { Get-Clipboard }
function http-server { python -m http.server @args }

# Headroom + DeepSeek
# headroom wrap claude starts the local proxy and launches Claude Code through it.
# settings.local.json points ANTHROPIC_BASE_URL to the proxy (127.0.0.1:8787).
function claude-default {
    Remove-Item Env:CLAUDE_API_KEY  -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_BASE_URL -ErrorAction SilentlyContinue
    headroom wrap claude
}
function claude-default-continue {
    Remove-Item Env:CLAUDE_API_KEY  -ErrorAction SilentlyContinue
    Remove-Item Env:CLAUDE_BASE_URL -ErrorAction SilentlyContinue
    headroom wrap claude -- -c
}
function claude-deepseek {
    $env:CLAUDE_API_KEY  = $env:DEEPSEEK_API_KEY
    $env:CLAUDE_BASE_URL = "https://api.deepseek.com/v1"
    headroom wrap claude
}
function claude-deepseek-continue {
    $env:CLAUDE_API_KEY  = $env:DEEPSEEK_API_KEY
    $env:CLAUDE_BASE_URL = "https://api.deepseek.com/v1"
    headroom wrap claude -- -c
}
