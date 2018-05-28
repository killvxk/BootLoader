@echo ********************************************************************
echo Start Build x86InjectShellCode
nasm -f bin x86InjectShellCode.Asm -o x86InjectShellCode.Bin
echo x86InjectShellCode Build Success
@echo ********************************************************************
echo Start Compress x86InjectShellCode.Bin
GenCompressCode.exe xor x86InjectShellCode.Bin
@echo ********************************************************************
echo Start Build x86ShellCodeUnCompress
nasm -f bin x86ShellCodeUnCompress.Asm -o x86ShellCodeUnCompress.Bin
echo x86ShellCodeUnCompress Build Success
del x86InjectShellCode.Bin
@echo ********************************************************************
pause