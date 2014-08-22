@echo off
:: USAGE: unzip <file> <destination folder>
echo Unzipping %1 to %2
:: Extract full path, yes to all queries, open as zip, everything from file %1 to folder %2
call "C:\Program Files\7-Zip\7z.exe" x -y -tzip %1 -o%2