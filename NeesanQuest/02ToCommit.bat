@echo off
echo unpacking RPG Maker game at: "%~dp0."
pause
rvpacker --action unpack --project "%~dp0." --project-type ace
echo done!
pause