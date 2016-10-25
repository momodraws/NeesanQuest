@echo off
echo packing RPG Maker game at: "%~dp0."
echo if this is okay, press any key!
pause
rvpacker --action pack --project "%~dp0." --project-type ace
echo done!