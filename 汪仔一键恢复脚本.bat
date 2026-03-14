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
:: 第一部分：移除注册表拦截 (映像劫持)
:: ==========================================
echo [1/2] 正在解除注册表拦截规则...
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SOGOUSmartAssistant.exe" /f >nul 2>nul
if %errorlevel% == 0 (
    echo [成功] 注册表拦截已移除。
) else (
    echo [提示] 注册表中未发现拦截规则，无需处理。
)

:: ==========================================
:: 第二部分：恢复目录权限
:: ==========================================
echo [2/2] 正在恢复 IChat 目录的写入权限...
set "targetDir=C:\Program Files (x86)\SogouInput\Components\IChat"

if exist "%targetDir%" (
    :: 撤销拒绝策略，恢复继承
    icacls "%targetDir%" /remove:d Everyone /t >nul 2>nul
    icacls "%targetDir%" /reset /t >nul 2>nul
    icacls "%targetDir%" /grant administrators:F /t >nul 2>nul
    echo [成功] 目录权限已恢复正常。
) else (
    echo [提示] 未找到目标目录，无需恢复。
)

echo.
echo ======================================================
echo [恢复完成] 
echo 现在你可以尝试重新下载或运行 AI 汪仔。
echo 如果组件仍无法运行，建议重新安装一次搜狗输入法。
echo ======================================================
pause