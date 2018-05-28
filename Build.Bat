@echo ********************************************************************
echo Start Gen ShellCode
call ./x86ShellCodeBuild.Bat
@echo ********************************************************************

@echo ********************************************************************
echo Start Gen ShellCode
call ./x64ShellCodeBuild.Bat
@echo ********************************************************************

echo Start Build BootLoader.Bin
nasm -f bin BootLoader.Asm -o BootLoader.Bin
echo BootLoader.Bin Build Success
@echo ********************************************************************
pause
echo Start Copy BootLoader.bin to BochsDbg
copy BootLoader.Bin D:\BochsDbg\BootLoader.Bin /y
copy BootLoader.Bin C:\DellOpti380\DellBios\DellBios\BootLoader.Bin /y
echo Copy Success.
@echo ********************************************************************
pause