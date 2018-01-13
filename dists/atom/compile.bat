@echo off
cd %1\src
if not %2=="execute" (
    rm -rf ..\game\WorldParty* units\*.*o units\*.a units\*.ppu units\*.rsj
    fpc WorldParty.dpr -FE../game -FUunits
)
if exist "units\link.res" (
    mv units\link.res ..\res\
)
if exist "..\game\WorldParty.exe" (
    if %2=="compile-execute" (
        start "" ../game/WorldParty -Benchmark
    )
    if %2=="execute" (
        start "" ../game/WorldParty -Benchmark
    )
)
