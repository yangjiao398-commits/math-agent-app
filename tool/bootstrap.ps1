#Requires -Version 5
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$flutter = "C:\Users\lenoov\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
  Write-Host "未找到 Flutter SDK。请先安装 Flutter 3 并把 bin 加入 PATH，或克隆到 C:\Users\lenoov\flutter"
  Write-Host "git clone -b stable --depth 1 https://github.com/flutter/flutter.git C:\Users\lenoov\flutter"
  exit 1
}
Set-Location $root
& $flutter create --org com.mathagent --project-name math_agent_app --platforms=ios,android .
& $flutter pub get
Write-Host "然后: flutter run --dart-define=API_BASE=http://10.0.2.2:3010"
