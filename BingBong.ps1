# Pfad zur Ausgabedatei für die exportierten Cookies
$outputFile = "headers.txt"

# Pfad zur SQLite-DLL
$sqliteDllPath = "System.Data.SQLite.dll"  # Passe den Pfad entsprechend an

# Lade das SQLite-Assembly
Add-Type -Path $sqliteDllPath

# Finde den Pfad zur Cookies-Datenbank von Firefox
$firefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles"
$firefoxProfile = $firefoxProfiles | Select-Object -Index 1
$cookiesDB = Join-Path $firefoxProfile.FullName "cookies.sqlite"

# Kopiere die Datenbank, um Konflikte beim Lesen zu vermeiden
$tempDB = "temp_cookies.sqlite"

# Lösche die temporäre Datenbankdatei
Remove-Item -Path $tempDB -Force

# Lösche die temporäre Cookiedatei
#Remove-Item -Path $outputFile -Force

@"
authority: www.bing.com
accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7
accept-language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7
referer: https://www.bing.com/search?q=auto&form=QBLH&sp=-1&ghc=1&lq=0&pq=auto&sc=12-4&qs=n&sk=&cvid=1637992F28A54988AA0355A0FFB5383F&ghsh=0&ghacc=0&ghpl=&wlexpsignin=1
sec-fetch-dest: document
sec-fetch-mode: navigate
sec-fetch-site: same-origin
sec-fetch-user: ?1
upgrade-insecure-requests: 1
user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36
"@ | Out-File -FilePath $outputFile


Copy-Item -Path $cookiesDB -Destination $tempDB -Force

# Verbinde mit der SQLite-Datenbank
$conn = New-Object -TypeName System.Data.SQLite.SQLiteConnection -ArgumentList "Data Source=$tempDB;Version=3"
$conn.Open()
$cmd = $conn.CreateCommand()

# Abfrage, um alle Cookies aus der Datenbank abzurufen
$cmd.CommandText = "SELECT name, value, host, path, expiry FROM moz_cookies where host='.bing.com'"
$reader = $cmd.ExecuteReader()

# Öffne die Ausgabedatei und schreibe die Cookies
$first = $true
while ($reader.Read()) {
    if ($first) {
        $first = $false
        $cookieList = "cookie: " + $reader.GetString(0) + "=" + $reader.GetString(1)
    } else {
        $cookieList = $cookieList + "; " + $reader.GetString(0) + "=" + $reader.GetString(1)
    }
    #$cookieName = $reader.GetString(0)
    #$cookieValue = $reader.GetString(1)
    #$cookieHost = $reader.GetString(2)
    #$cookiePath = $reader.GetString(3)
    #$cookieExpiry = $reader.GetInt64(4)

    # Wenn das Ablaufdatum 'null' ist, setze es auf '0' (Sitzungscookie)
    if ($cookieExpiry -eq $null) {
        $cookieExpiry = 0
    }

}
Add-Content -Path $outputFile -Value $cookieList


# Schließe die Verbindung zur Datenbank
$conn.Close()

Write-Output "Cookies wurden erfolgreich nach '$outputFile' exportiert."

cmd.exe /c 'bing-call.bat'