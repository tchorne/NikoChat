@echo off
setlocal enabledelayedexpansion

set "filename=memory_niko"
set "newname=memory_gojo"
set "tempname=memory_temp"

rem Check if "memory_niko" exists
if exist %filename% (
    rem Rename "memory" to "memory_gojo"
    ren memory !newname!

    rem Rename "memory_niko" to "memory"
    ren %filename% memory
    echo File renaming successful.
) else (
    echo File "memory_niko" not found.
)

endlocal

python server.py --ip 127.0.0.1 --port 8081 --human Thomas --bot Niko
pause