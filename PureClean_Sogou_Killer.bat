@echo off
setlocal DisableDelayedExpansion
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )
:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
echo Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
echo args = "ELEV " >> "%vbsGetPrivileges%"
echo For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
echo args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
echo Next >> "%vbsGetPrivileges%"
echo UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
"%SystemRoot%\System32\WScript.exe" "%vbsGetPrivileges%" %*
exit /B
:gotPrivileges
if exist "%vbsGetPrivileges%" ( del "%vbsGetPrivileges%" )

:: ==========================================
:: 第一部分：逻辑拦截 (注册表映像劫持)
:: ==========================================
echo [1/3] 正在建立注册表拦截防火墙...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SOGOUSmartAssistant.exe" /v debugger /t REG_SZ /d "ntsd -d" /f >nul

:: ==========================================
:: 第二部分：物理清理与夺权
:: ==========================================
echo [2/3] 正在强制关闭并清理残留文件...
taskkill /f /im SOGOUSmartAssistant.exe /t 2>nul
set "targetDir=C:\Program Files (x86)\SogouInput\Components\IChat"

if exist "%targetDir%" (
    takeown /f "%targetDir%" /r /d y >nul
    icacls "%targetDir%" /grant administrators:F /t >nul
    del /s /q /f "%targetDir%\*.*" 2>nul
    for /d %%p in ("%targetDir%\*") do rd /s /q "%%p" 2>nul
) else (
    md "%targetDir%" 2>nul
)

:: ==========================================
:: 第三部分：物理封锁 (权限死锁)
:: ==========================================
echo [3/3] 正在执行目录“权限死锁”...
icacls "%targetDir%" /reset /t >nul
icacls "%targetDir%" /deny Everyone:(OI)(CI)(W,WDAC,WO,WEA,WA) /t >nul

echo.
echo ======================================================
echo [操作完成] 
echo 1. 注册表已拦截：即使文件存在，系统也无法启动 AI 汪仔。
echo 2. 权限已死锁：搜狗主程序将难以向该目录写入新数据。
echo ======================================================
pause