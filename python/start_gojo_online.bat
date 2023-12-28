@echo off
setlocal enabledelayedexpansion

set "filename=memory_gojo"
set "newname=memory_niko"
set "tempname=memory_temp"

rem Check if "memory_gojo" exists
if exist %filename% (
    rem Rename "memory" to "memory_niko"
    ren memory !newname!

    rem Rename "memory_gojo" to "memory"
    ren %filename% memory
    echo File renaming successful.
) else (
    echo File "memory_gojo" not found.
)

endlocal

python server.py --ip 0.0.0.0 --port 8001 --human Libby --bot Gojo
pause