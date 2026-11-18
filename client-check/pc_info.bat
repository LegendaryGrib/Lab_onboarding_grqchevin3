@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

set "REPORT=%~dp0pc_report.txt"
set "APPS_FILE=%TEMP%\pc_apps_%RANDOM%.txt"
set "MATCH_FILE=%TEMP%\pc_matches_%RANDOM%.txt"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "APPS_READY=0"
set "BASIC_COUNT=0"
set "RECOMMENDATIONS=0"

>"%REPORT%" echo.
if not exist "%POWERSHELL%" (
    call :log "Ошибка: Windows PowerShell не найден."
    pause
    exit /b 1
)

call :log "Диагностика компьютера"
call :log "Время формирования: %date% %time%"
call :log "Сбор сведений о системе"

set "OS_NAME="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "(Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).Caption" 2^>nul') do set "OS_NAME=%%A"
if defined OS_NAME (call :log "Операционная система: %OS_NAME%") else (call :log "Не удалось получить название операционной системы.")

set "OS_VERSION="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "(Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).Version" 2^>nul') do set "OS_VERSION=%%A"
if defined OS_VERSION (call :log "Версия: %OS_VERSION%") else (call :log "Не удалось получить версию Windows.")

set "CPU_NAME="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)[0].Name" 2^>nul') do set "CPU_NAME=%%A"
if defined CPU_NAME (call :log "Процессор: %CPU_NAME%") else (call :log "Не удалось получить сведения о процессоре.")

set "TOTAL_MEMORY="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "$os=Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop; [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)" 2^>nul') do set "TOTAL_MEMORY=%%A"
if defined TOTAL_MEMORY (call :log "Всего памяти: %TOTAL_MEMORY% ГБ") else (call :log "Не удалось получить общий объём памяти.")

set "FREE_MEMORY="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "$os=Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop; [math]::Round($os.FreePhysicalMemory / 1MB, 1)" 2^>nul') do set "FREE_MEMORY=%%A"
if defined FREE_MEMORY (call :log "Свободно памяти: %FREE_MEMORY% ГБ") else (call :log "Не удалось получить свободный объём памяти.")

set "DISK_SIZE="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "$disk=Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID=''C:''' -ErrorAction Stop; [math]::Round($disk.Size / 1GB, 1)" 2^>nul') do set "DISK_SIZE=%%A"
if defined DISK_SIZE (call :log "Общий объём диска C: %DISK_SIZE% ГБ") else (call :log "Не удалось получить общий объём диска C.")

set "DISK_FREE="
for /f "delims=" %%A in ('"%POWERSHELL%" -NoProfile -NonInteractive -Command "$disk=Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID=''C:''' -ErrorAction Stop; [math]::Round($disk.FreeSpace / 1GB, 1)" 2^>nul') do set "DISK_FREE=%%A"
if defined DISK_FREE (call :log "Свободно на диске C: %DISK_FREE% ГБ") else (call :log "Не удалось получить свободное место на диске C.")

call :log "Сбор списка установленных программ"
"%POWERSHELL%" -NoProfile -NonInteractive -Command "$ErrorActionPreference='Stop'; $roots=@('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'); $apps=foreach($root in $roots){Get-ItemProperty -Path (Join-Path $root '*') -ErrorAction SilentlyContinue}; $names=@($apps | Where-Object {$_.DisplayName -and $_.SystemComponent -ne 1} | Select-Object -ExpandProperty DisplayName | Sort-Object -Unique); if($names.Count -eq 0){$names=@('')}; Set-Content -LiteralPath $env:APPS_FILE -Value $names -Encoding UTF8" >nul 2>nul
if errorlevel 1 (
    call :log "Не удалось прочитать список программ из реестра."
) else (
    set "APPS_READY=1"
    call :log "Список программ подготовлен."
)

call :log "Проверка базового офисного ПО"
call :check "Офисный пакет найден:" "Office|LibreOffice|OpenOffice|МойОфис" "Не обнаружен офисный пакет. Проверьте Office, LibreOffice или МойОфис."
call :check "Браузер найден:" "Chrome|Firefox|Edge|Яндекс" "Не обнаружен браузер. Рекомендуется установить Chrome, Firefox или другой браузер организации."
call :log "Edge является компонентом Windows, его наличие не подтверждает настройку рабочего места."
call :check "Программа для PDF найдена:" "Acrobat|Foxit|SumatraPDF" "Не обнаружена программа для PDF. Рекомендуется установить Acrobat, Foxit или SumatraPDF."
call :check "Архиватор найден:" "7-Zip|WinRAR|WinZip" "Не обнаружен архиватор. Для работы с вложениями рекомендуется установить 7-Zip или WinRAR."
call :check "Антивирус найден:" "Defender|Kaspersky|ESET|Dr\.Web" "Не обнаружен антивирус. Проверьте защиту компьютера и настройки организации."

call :log "Проверка программ, не относящихся к базовым офисным задачам"
call :review "Игровое ПО найдено, проверьте необходимость:" "Steam|Epic Games|GOG|Origin|Ubisoft Connect|Battle\.net|Riot|game|gaming" "Игровое ПО не найдено."
call :review "Найдены торрент-клиенты или файлообменные программы, проверьте необходимость:" "torrent|uTorrent|BitTorrent|qBittorrent|Vuze" "Торрент-клиенты и файлообменные программы не найдены."
call :review "Найдены мессенджеры, проверьте соответствие корпоративному стандарту:" "Discord|Telegram|WhatsApp|Viber|Skype" "Мессенджеры из списка проверки не найдены."
call :review "Найдены программы для развлечений или оформления, проверьте необходимость:" "Wallpaper Engine|OBS|Soundpad|VLC|Media Player|KMPlayer|PotPlayer" "Программы для развлечений и оформления из списка не найдены."

call :log "Результат является рекомендацией к проверке, а не указанием к удалению. Решение принимает администратор."
call :log "Проверено категорий базового ПО: %BASIC_COUNT%"
call :log "Рекомендаций для проверки: %RECOMMENDATIONS%"
call :log "Отчёт сохранён: %REPORT%"

del /q "%APPS_FILE%" "%MATCH_FILE%" >nul 2>nul
pause
exit /b 0

:check
set /a BASIC_COUNT+=1
if not "%APPS_READY%"=="1" (
    call :log "Не удалось проверить категорию: список программ недоступен."
    set /a RECOMMENDATIONS+=1
    exit /b
)
set "APP_PATTERN=%~2"
call :find
if errorlevel 1 (
    call :log "Не удалось выполнить проверку базового ПО."
    set /a RECOMMENDATIONS+=1
    exit /b
)
if exist "%MATCH_FILE%" (
    call :log "%~1"
    type "%MATCH_FILE%"
    type "%MATCH_FILE%" >>"%REPORT%"
) else (
    call :log "%~3"
    set /a RECOMMENDATIONS+=1
)
exit /b

:review
if not "%APPS_READY%"=="1" (
    call :log "Не удалось выполнить проверку: список программ недоступен."
    set /a RECOMMENDATIONS+=1
    exit /b
)
set "APP_PATTERN=%~2"
call :find
if errorlevel 1 (
    call :log "Не удалось выполнить поиск по списку программ."
    set /a RECOMMENDATIONS+=1
    exit /b
)
if exist "%MATCH_FILE%" (
    call :log "%~1"
    type "%MATCH_FILE%"
    type "%MATCH_FILE%" >>"%REPORT%"
    set /a RECOMMENDATIONS+=1
) else (
    call :log "%~3"
)
exit /b

:find
del /q "%MATCH_FILE%" >nul 2>nul
"%POWERSHELL%" -NoProfile -NonInteractive -Command "$apps=Get-Content -LiteralPath $env:APPS_FILE; $matches=@($apps | Where-Object {$_ -match $env:APP_PATTERN}); if($matches.Count -gt 0){Set-Content -LiteralPath $env:MATCH_FILE -Value $matches -Encoding UTF8}" >nul 2>nul
exit /b %errorlevel%

:log
set "LOG_MESSAGE=%~1"
setlocal EnableDelayedExpansion
if not defined LOG_MESSAGE (
    echo(
    >>"%REPORT%" echo(
) else (
    echo(!LOG_MESSAGE!
    >>"%REPORT%" echo(!LOG_MESSAGE!
)
endlocal
exit /b
