@echo ********************************************************************
echo Start Build x64InjectShellCode
nasm -f bin x64InjectShellCode.Asm -o x64InjectShellCode.Bin
echo x64InjectShellCode Build Success
@echo ********************************************************************
echo Start Compress x64InjectShellCode.Bin
GenCompressCode.exe xor x64InjectShellCode.Bin
@echo ********************************************************************
echo Start Build x64ShellCodeUnCompress
nasm -f bin x64ShellCodeUnCompress.Asm -o x64ShellCodeUnCompress.Bin
echo x64ShellCodeUnCompress Build Success
del x64InjectShellCode.Bin
@echo ********************************************************************
pause