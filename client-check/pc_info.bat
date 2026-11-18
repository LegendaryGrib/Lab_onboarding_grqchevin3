@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

set "REPORT=%~dp0pc_report.txt"
set "APPS_FILE=%TEMP%\pc_apps_%RANDOM%.txt"
set "MATCH_FILE=%TEMP%\pc_matches_%RANDOM%.txt"
set "INFO_FILE=%TEMP%\pc_info_%RANDOM%.txt"
set "PS_INFO=%TEMP%\pc_ps_info_%RANDOM%.ps1"
set "PS_APPS=%TEMP%\pc_ps_apps_%RANDOM%.ps1"
set "PS_FIND=%TEMP%\pc_ps_find_%RANDOM%.ps1"
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

:: ---- PS: сведения о системе ----
>"%PS_INFO%" echo $os = Get-CimInstance Win32_OperatingSystem
>>"%PS_INFO%" echo $cpu = Get-CimInstance Win32_Processor
>>"%PS_INFO%" echo $cpu = $cpu ^| Select-Object -First 1
>>"%PS_INFO%" echo $d = Get-CimInstance Win32_LogicalDisk
>>"%PS_INFO%" echo $d = $d ^| ? { $_.DeviceID -eq 'C:' }
>>"%PS_INFO%" echo "OS_NAME=$($os.Caption)"
>>"%PS_INFO%" echo "OS_VER=$($os.Version)"
>>"%PS_INFO%" echo "CPU=$($cpu.Name)"
>>"%PS_INFO%" echo "RAM_TOTAL=$([math]::Round($os.TotalVisibleMemorySize/1MB,1))"
>>"%PS_INFO%" echo "RAM_FREE=$([math]::Round($os.FreePhysicalMemory/1MB,1))"
>>"%PS_INFO%" echo "DISK_SIZE=$([math]::Round($d.Size/1GB,1))"
>>"%PS_INFO%" echo "DISK_FREE=$([math]::Round($d.FreeSpace/1GB,1))"

:: ---- PS: список программ ----
>"%PS_APPS%" echo $ErrorActionPreference = 'SilentlyContinue'
>>"%PS_APPS%" echo $r = @()
>>"%PS_APPS%" echo $r += 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'
>>"%PS_APPS%" echo $r += 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
>>"%PS_APPS%" echo $a = Get-ItemProperty (Join-Path $r '*')
>>"%PS_APPS%" echo $a = $a ^| ? { $_.DisplayName -and $_.SystemComponent -ne 1 }
>>"%PS_APPS%" echo $n = @($a.DisplayName ^| Sort-Object -Unique)
>>"%PS_APPS%" echo if ($n.Count -eq 0) { $n = @('') }
>>"%PS_APPS%" echo $n ^| Set-Content $env:APPS_FILE -Encoding UTF8

:: ---- PS: поиск совпадений ----
>"%PS_FIND%" echo $ErrorActionPreference = 'SilentlyContinue'
>>"%PS_FIND%" echo $p = $env:APP_PATTERN
>>"%PS_FIND%" echo $a = Get-Content $env:APPS_FILE -EA 0
>>"%PS_FIND%" echo $m = @($a ^| ? { $_ -match $p })
>>"%PS_FIND%" echo if ($m.Count -gt 0) { $m ^| Set-Content $env:MATCH_FILE -Encoding UTF8 }

call :log "Диагностика компьютера"
call :log "Время формирования: %date% %time%"
call :log "Сбор сведений о системе"

"%POWERSHELL%" -NoP -EP Bypass -File "%PS_INFO%" >"%INFO_FILE%" 2>nul
for /f "usebackq tokens=1,* delims==" %%A in ("%INFO_FILE%") do set "S_%%A=%%B"

if defined S_OS_NAME (call :log "ОС: %S_OS_NAME%") else (call :log "ОС не определена.")
if defined S_OS_VER  (call :log "Версия: %S_OS_VER%") else (call :log "Версия не определена.")
if defined S_CPU     (call :log "Процессор: %S_CPU%") else (call :log "Процессор не определён.")
if defined S_RAM_TOTAL (call :log "Всего памяти: %S_RAM_TOTAL% ГБ") else (call :log "ОЗУ не определено.")
if defined S_RAM_FREE  (call :log "Свободно памяти: %S_RAM_FREE% ГБ") else (call :log "Свободно ОЗУ неизвестно.")
if defined S_DISK_SIZE (call :log "Диск C всего: %S_DISK_SIZE% ГБ") else (call :log "Объём C: неизвестен.")
if defined S_DISK_FREE (call :log "Диск C свободно: %S_DISK_FREE% ГБ") else (call :log "Свободно на C: неизвестно.")

call :log "Сбор списка установленных программ"
"%POWERSHELL%" -NoP -EP Bypass -File "%PS_APPS%" >nul 2>nul
if errorlevel 1 (
    call :log "Не удалось прочитать список программ."
) else (
    set "APPS_READY=1"
    call :log "Список программ подготовлен."
)

call :log "Проверка базового офисного ПО"
call :check "Офисный пакет найден:" "Office|LibreOffice|OpenOffice|МойОфис" "Офисный пакет не обнаружен."
call :check "Браузер найден:" "Chrome|Firefox|Edge|Яндекс" "Браузер не обнаружен."
call :log "Edge является компонентом Windows."
call :check "PDF-программа найдена:" "Acrobat|Foxit|SumatraPDF" "PDF-программа не обнаружена."
call :check "Архиватор найден:" "7-Zip|WinRAR|WinZip" "Архиватор не обнаружен."
call :check "Антивирус найден:" "Defender|Kaspersky|ESET|Dr\.Web" "Антивирус не обнаружен."

call :log "Проверка прочих программ"
call :review "Игровое ПО найдено:" "Steam|Epic Games|GOG|Origin|Ubisoft Connect|Battle\.net|Riot|game|gaming" "Игровое ПО не найдено."
call :review "Торрент-клиенты найдены:" "torrent|uTorrent|BitTorrent|qBittorrent|Vuze" "Торрент-клиенты не найдены."
call :review "Мессенджеры найдены:" "Discord|Telegram|WhatsApp|Viber|Skype" "Мессенджеры не найдены."
call :review "Развлечения найдены:" "Wallpaper Engine|OBS|Soundpad|VLC|KMPlayer|PotPlayer" "Развлечения не найдены."

call :log "Результат — рекомендация к проверке."
call :log "Проверено категорий: %BASIC_COUNT%"
call :log "Рекомендаций: %RECOMMENDATIONS%"
call :log "Отчёт: %REPORT%"

del /q "%APPS_FILE%" "%MATCH_FILE%" "%INFO_FILE%" "%PS_INFO%" "%PS_APPS%" "%PS_FIND%" >nul 2>nul
pause
exit /b 0

:check
set /a BASIC_COUNT+=1
if not "%APPS_READY%"=="1" (
    call :log "Категория не проверена: список недоступен."
    set /a RECOMMENDATIONS+=1
    exit /b
)
set "APP_PATTERN=%~2"
call :find
if errorlevel 1 (
    call :log "Проверка не выполнена."
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
    call :log "Категория не проверена: список недоступен."
    set /a RECOMMENDATIONS+=1
    exit /b
)
set "APP_PATTERN=%~2"
call :find
if errorlevel 1 (
    call :log "Поиск не выполнен."
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
if not exist "%APPS_FILE%" exit /b 1
"%POWERSHELL%" -NoP -EP Bypass -File "%PS_FIND%" >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

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
