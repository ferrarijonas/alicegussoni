# Sincroniza os arquivos compartilhados com o upstream (ferrarijonas/paodeverdade).
# NUNCA edite esses arquivos aqui — edite no upstream e rode este script.
# Veja SHARED.md para a lista completa.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$upstream = Join-Path $env:TEMP 'upstream-paodeverdade'

$shared = @(
  'assets/js/main.js', 'assets/js/main.min.js',
  'assets/js/analytics.js', 'assets/js/analytics.min.js',
  'assets/js/lotada.js', 'assets/js/lotada.min.js'
)

if (Test-Path $upstream) { Remove-Item -Recurse -Force $upstream }
git clone --depth 1 https://github.com/ferrarijonas/paodeverdade.git $upstream

foreach ($f in $shared) {
  $dst = Join-Path $root $f
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  Copy-Item -Force (Join-Path $upstream $f) $dst
}

git -C $root status --short
Write-Host 'Revisou? Entao: git add -A; git commit -m "sync upstream"; git push'