@echo off
setlocal enabledelayedexpansion

REM Define the URL you want to call
set "url=https://www.bing.com/search"
REM Define the number of times you want to call the URL
set "num_calls=10"
set "length=10"

REM Loop for the specified number of calls
for /l %%a in (1,1,%num_calls%) do (
    REM Generate a random alphanumeric string for each call using PowerShell
    for /f "delims=" %%b in ('powershell -Command "$a = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count %length% | ForEach-Object {[char]$_}); $a"') do set "random=%%b"

    REM Call the URL with the random string passed as a GET parameter
    curl --header @headers.txt --compressed -o nul "%url%?q=!random!"
)
endlocal
