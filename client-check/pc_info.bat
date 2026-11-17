@echo off
chcp 65001 >nul

set "REPORT=%~dp0pc_report.txt"
set "POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not exist "%POWERSHELL%" (
    echo Ошибка: Windows PowerShell не найден.
    pause
    exit /b 1
)

> "%REPORT%" echo Диагностика компьютера
>> "%REPORT%" echo ======================
>> "%REPORT%" echo.
>> "%REPORT%" echo Операционная система
powershell -NoProfile -NonInteractive -Command "$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop; 'Название: {0}' -f $os.Caption; 'Версия: {0}' -f $os.Version" >> "%REPORT%"
if errorlevel 1 goto :failed

>> "%REPORT%" echo.
>> "%REPORT%" echo Процессор
powershell -NoProfile -NonInteractive -Command "$cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1; if (-not $cpu) { throw 'Процессор не найден.' }; 'Название: {0}' -f $cpu.Name" >> "%REPORT%"
if errorlevel 1 goto :failed

>> "%REPORT%" echo.
>> "%REPORT%" echo Оперативная память
powershell -NoProfile -NonInteractive -Command "$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop; 'Всего памяти: {0:N0} ГБ' -f ($os.TotalVisibleMemorySize / 1MB); 'Свободно памяти: {0:N0} ГБ' -f ($os.FreePhysicalMemory / 1MB)" >> "%REPORT%"
if errorlevel 1 goto :failed

>> "%REPORT%" echo.
>> "%REPORT%" echo Диск C
powershell -NoProfile -NonInteractive -Command "$disk = Get-CimInstance -ClassName Win32_LogicalDisk -ErrorAction Stop | Where-Object { $_.DeviceID -eq 'C:' } | Select-Object -First 1; if (-not $disk) { throw 'Диск C не найден.' }; 'Всего: {0:N0} ГБ' -f ($disk.Size / 1GB); 'Свободно: {0:N0} ГБ' -f ($disk.FreeSpace / 1GB)" >> "%REPORT%"
if errorlevel 1 goto :failed

>> "%REPORT%" echo.
>> "%REPORT%" echo Установленные программы
powershell -NoProfile -NonInteractive -Command "$roots = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'); $apps = foreach ($root in $roots) { Get-ItemProperty -Path (Join-Path $root '*') -ErrorAction SilentlyContinue }; $names = $apps | Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | Select-Object -ExpandProperty DisplayName | Sort-Object -Unique; if (-not $names) { throw 'В реестре не найдены названия установленных программ.' }; $names" >> "%REPORT%"
if errorlevel 1 goto :failed

>> "%REPORT%" echo.
>> "%REPORT%" echo Отчёт сохранён.
type "%REPORT%"
if errorlevel 1 goto :failed
pause
exit /b 0

:failed
echo.
echo Ошибка: не удалось собрать все сведения. Подробности приведены выше.
pause
exit /b 1
