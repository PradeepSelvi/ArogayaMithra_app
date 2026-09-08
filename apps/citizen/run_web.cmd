@echo off
cd /d "%~dp0build\web"
python -m http.server 8765
