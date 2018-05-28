echo Start Build BootLoader.Bin
nasm -f bin BootLoader.Asm -o BootLoader.Bin
echo BootLoader.Bin Build Success
@echo ********************************************************************
pause
echo Start Copy BootLoader.bin to BochsDbg
copy BootLoader.Bin D:\BochsDbg\BootLoader.Bin /y
echo Copy Success.
@echo ********************************************************************
pause