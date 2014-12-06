;Copyright (C) 1997-2001 ZSNES Team ( zsknight@zsnes.com / _demo_@zsnes.com )
;
;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either
;version 2 of the License, or (at your option) any later
;version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

%include "macros.mac"

EXTSYM DSPMem,FPSOn,Makemode7Table,MessageOn,vesa2red10,scanlines,smallscreenon
EXTSYM MsgCount,Msgptr,OutputGraphicString,OutputGraphicString16b
EXTSYM PrepareSaveState,ResetState,breakatsignb,breakatsignc,cvidmode
EXTSYM cbitmode,copyvid,curblank,drawhline,drawhline16b,drawvline
EXTSYM drawvline16b,fnames,frameskip,mode7tab,pressed,spcA
EXTSYM spcBuffera,spcNZ,spcP,spcPCRam,spcRam,spcRamDP,spcS,spcX,spcY
EXTSYM spcon,vesa2_bpos,vesa2_clbit,vesa2_gpos,vesa2_rpos,vesa2selec
EXTSYM vidbuffer,spritetablea,sprlefttot,newengen,spcextraram,resolutn
EXTSYM Open_File,Close_File,Read_File,Write_File,Create_File,Get_Key,Get_Date
EXTSYM continueprognokeys,ForceNonTransp,GUIOn,Check_Key,JoyRead
EXTSYM GetScreen,SSKeyPressed,SPCKeyPressed,StopSound,StartSound    
EXTSYM ExecExitOkay,t1cc
EXTSYM Clear2xSaIBuffer
EXTSYM romdata,romtype,ScreenShotFormat
EXTSYM Voice0Disable,Voice1Disable,Voice2Disable,Voice3Disable
EXTSYM Voice4Disable,Voice5Disable,Voice6Disable,Voice7Disable
%ifndef NO_PNG
EXTSYM Grab_PNG_Data
%endif

NEWSYM MenuAsmStart




GUIBufferData:
    mov ecx,16384
    cmp byte[cbitmode],1
    jne near .16b
    add ecx,16384
.16b
    ; copy to spritetable
    mov esi,[vidbuffer]
    mov edi,[spritetablea]
.loop
    mov eax,[esi]
    mov [edi],eax
    add esi,4
    add edi,4
    dec ecx
    jnz .loop
    mov edi,sprlefttot
    mov ecx,64*5
.a
    mov dword[edi],0
    add edi,4
    dec ecx
    jnz .a
    ret

GUIUnBuffer:
    mov ecx,16384
    cmp byte[cbitmode],1
    jne near .16b
    add ecx,16384
.16b
    ; copy from spritetable
    mov esi,[vidbuffer]
    mov edi,[spritetablea]
.loop
    mov eax,[edi]
    mov [esi],eax
    add esi,4
    add edi,4
    dec ecx
    jnz .loop
    ret


NEWSYM nextmenupopup, db 0
NEWSYM NoInputRead, db 0
NEWSYM PrevMenuPos, db 0
NEWSYM MenuDisplace, dd 0
NEWSYM MenuDisplace16, dd 0
NEWSYM MenuNoExit, db 0
NEWSYM SPCSave, db 0

NEWSYM showmenu
    mov byte[ForceNonTransp],1
    cmp byte[cbitmode],1
    je near .nopalread
    mov edi,[vidbuffer]
    add edi,100000
    mov dx,03C7h
    mov al,0
    out dx,al
    mov dx,03C9h
    mov ecx,768
    mov byte[edi],12
    inc edi
.b
    in al,dx
    shl al,2
    mov [edi],al
    inc edi
    dec ecx
    jnz .b
.nopalread

    cmp byte[cbitmode],1
    je near .nopal16b
    ; set palette of colors 128,144, and 160 to white, blue, and red
    mov al,128
    mov dx,03C8h
    out dx,al
    inc dx
    mov al,63
    out dx,al
    out dx,al
    out dx,al
    mov al,144
    mov dx,03C8h
    out dx,al
    inc dx
    xor al,al
    out dx,al
    out dx,al
    mov al,50
    out dx,al
    mov al,160
    mov dx,03C8h
    out dx,al
    inc dx
    mov al,45
    out dx,al
    xor al,al
    out dx,al
    out dx,al
.nopal16b

    mov byte[NoInputRead],0
    cmp byte[newengen],0
    je .nong16b
    cmp byte[cbitmode],0
    je .nong16b
    call GetScreen
.nong16b
    cmp byte[SSKeyPressed],1
    jne .nosskey
    mov byte[SSKeyPressed],0
    call savepcx
    jmp .nopalwrite
.nosskey
    cmp byte[SPCKeyPressed],1
    je near .savespckey
    test byte[pressed+14],1
    jz .nof12
    call savepcx
    jmp .nopalwrite
.nof12
    mov dword[menucloc],0
    cmp byte[nextmenupopup],0
    je .nomenuinc2
    mov byte[pressed+1Ch],0
    mov dword[menucloc],40*288
    cmp byte[PrevMenuPos],1
    jne .nomenuinc
    mov dword[menucloc],50*288
.nomenuinc
    cmp byte[PrevMenuPos],2
    jne .nomenuinc2
    mov dword[menucloc],60*288
.nomenuinc2
    cmp byte[PrevMenuPos],3
    jne .nomenuinc3
    mov dword[menucloc],70*288
.nomenuinc3

    mov dword[menudrawbox8b.stringi+13],' BMP'
%ifndef NO_PNG 
    cmp byte[ScreenShotFormat],0
    je .normalscrn
    mov dword[menudrawbox8b.stringi+13],' PNG'
%endif
.normalscrn
    cmp byte[cbitmode],1
    je near .nopcx
    mov dword[menudrawbox8b.stringi+13],' PCX'
.nopcx
    mov byte[nextmenupopup],0
    mov byte[menu16btrans],0
    mov byte[pressed+1],0
    mov byte[pressed+59],0
    mov byte[curblank],00h
    call GUIBufferData
    ; Draw box
    call menudrawbox8b
    call menudrawbox8b
    cmp byte[newengen],0
    je .notng
    mov byte[GUIOn],1
.notng
    pushad
    call copyvid
    popad
    call StopSound
.nextkey
    call GUIUnBuffer
    call menudrawbox8b
    push eax
    call copyvid
    pop eax

    call JoyRead
    call Check_Key
    or al,al
    jz .nextkey
    call Get_Key
    cmp al,0
    jne near .processextend

    call Get_Key
    cmp al,72
    jne .noup
    cmp dword[menucloc],0
    jne .nogoup
    add dword[menucloc],80*288
.nogoup
    sub dword[menucloc],10*288
    call menudrawbox8b
    mov al,[newengen]
    mov byte[newengen],0

    mov [newengen],al
    jmp .nextkey
.noup
    cmp al,80
    jne .nodown
    cmp dword[menucloc],70*288
    jne .nogodown
    sub dword[menucloc],80*288
.nogodown
    add dword[menucloc],10*288
    call menudrawbox8b
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
    jmp .nextkey
.nodown
    jmp .nextkey
.processextend
    cmp al,27
    je near .exitloop
    cmp al,13
    je .done
    jmp .nextkey
.done
    call GUIUnBuffer
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
    cmp dword[menucloc],0
    jne .nosavepcx
    call savepcx
.nosavepcx
    cmp dword[menucloc],40*288
    jne .nosavepcx2
    call savepcx
    mov byte[ExecExitOkay],0
    mov byte[nextmenupopup],3
    mov byte[NoInputRead],1
    mov byte[t1cc],0
    mov byte[PrevMenuPos],0
.nosavepcx2
    cmp dword[menucloc],50*288
    jne .noskipframe
    mov byte[ExecExitOkay],0
    mov byte[nextmenupopup],3
    mov byte[NoInputRead],1
    mov byte[t1cc],0
    mov byte[PrevMenuPos],1
.noskipframe
    cmp dword[menucloc],70*288
    jne .noimagechange
    cmp byte[cbitmode],0
    je .noimagechange
    xor byte[ScreenShotFormat],1
    mov byte[MenuNoExit],1
    mov byte[ExecExitOkay],0
    mov byte[nextmenupopup],1
    mov byte[NoInputRead],1
    mov byte[t1cc],0
    mov byte[PrevMenuPos],3
.noimagechange
    cmp dword[menucloc],60*288
    jne .nomovewin
    mov byte[MenuNoExit],1
    mov byte[ExecExitOkay],0
    mov byte[nextmenupopup],1
    mov byte[NoInputRead],1
    mov byte[t1cc],0
    mov byte[PrevMenuPos],2
    cmp dword[MenuDisplace],0
    je .movewin
    mov dword[MenuDisplace],0
    mov dword[MenuDisplace16],0
    jmp .nomovewin
.movewin
    mov dword[MenuDisplace],90*288
    mov dword[MenuDisplace16],90*288*2
.nomovewin
    cmp dword[menucloc],10*288
    jne .nofps
    cmp byte[frameskip],0
    je .yesfs
    mov dword[Msgptr],.unablefps
    mov eax,[MsgCount]
    mov [MessageOn],eax
    jmp .nofps
.yesfs
    xor byte[FPSOn],1
.nofps
    cmp dword[menucloc],20*288
    jne near .nospcsave
.savespckey
    cmp byte[spcon],0
    je .nospc
    cmp byte[newengen],1
;    je .unablespc
    mov dword[Msgptr],.search
    mov eax,[MsgCount]
    mov [MessageOn],eax
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
;    call breakatsignc
;    cmp byte[prbreak],1
;    je .yesesc
    mov byte[SPCSave],1
    call breakatsignb
    mov byte[SPCSave],0
;    cmp byte[prbreak],1
;    je .yesesc
    call savespcdata
    mov byte[curblank],40h
    mov dword[Msgptr],.saved
    mov eax,[MsgCount]
    mov [MessageOn],eax
    jmp .nospcsave
.nospc
    mov dword[Msgptr],.nosound
    mov eax,[MsgCount]
    mov [MessageOn],eax
    jmp .nospcsave
.unablespc
    mov dword[Msgptr],.unable
    mov eax,[MsgCount]
    mov [MessageOn],eax
    jmp .nospcsave
.yesesc
    mov dword[Msgptr],.escpress
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nospcsave
    cmp dword[menucloc],30*288
    jne .nosnddmp
    call dumpsound
    mov dword[Msgptr],.sndbufsav
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nosnddmp
    cmp byte[SPCKeyPressed],1
    jne .exitloop
    mov byte[SPCKeyPressed],0
    jmp .nopalwrite
.exitloop
    call GUIUnBuffer
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
    cmp byte[cbitmode],1
    je near .nopalwrite
    mov edi,[vidbuffer]
    add edi,100000
    mov dx,03C8h
    mov al,0
    out dx,al
    mov dx,03C9h
    mov ecx,768
    inc edi
.c
    mov al,[edi]
    shr al,2
    out dx,al
    inc edi
    dec ecx
    jnz .c
.nopalwrite
    mov eax,pressed
    mov ecx,256
.looppr
    cmp byte[eax],1
    jne .notpr
    mov byte[eax],2
.notpr
    inc eax
    dec ecx
    jnz .looppr
;    mov byte[pressed+1],2
;    cmp byte[pressed+59],1
;    jne .not59
;    mov byte[pressed+59],2
;.not59
;    cmp byte[pressed+28],1
;    jne .not28
;    mov byte[pressed+28],2
;.not28
    call StartSound
    mov byte[ForceNonTransp],0
    mov byte[GUIOn],0
    call Clear2xSaIBuffer
    cmp byte[MenuNoExit],1
    je .noexitmenu
    jmp continueprognokeys
.noexitmenu
    mov byte[MenuNoExit],0
    jmp showmenu

.unablefps db 'NEED AUTO FRAMERATE ON',0
.sndbufsav db 'BUFFER SAVED AS SOUNDDMP.RAW',0
.search    db 'SEARCHING FOR SONG START.',0
.nosound   db 'SOUND MUST BE ENABLED.',0
.unable    db 'CANNOT USE IN NEW GFX ENGINE.',0
.escpress  db 'ESC TERMINATED SEARCH.',0
.saved     db '.SPC FILE SAVED.',0

NEWSYM menudrawbox8b
    cmp byte[cbitmode],1
    je near menudrawbox16b
    ; draw a small blue box with a white border
    mov esi,40+20*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,150
    mov al,95
.loop
    mov byte[esi],144
    inc esi
    dec ecx
    jnz .loop
    add esi,288-150
    dec al
    mov ecx,150
    jnz .loop
    mov al,128
    ; Draw lines
    mov esi,40+20*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,150
    call drawhline
    mov esi,40+20*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,95
    call drawvline
    mov esi,40+114*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,150
    call drawhline
    mov esi,40+32*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,150
    call drawhline
    mov esi,189+20*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,95
    call drawvline
    call menudrawcursor8b

    mov esi,45+23*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.string
    call OutputGraphicString
    mov esi,45+35*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringa
    call OutputGraphicString
    mov esi,45+45*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringb
    test byte[FPSOn],1
    jz .nofps
    mov edi,.stringc
.nofps
    call OutputGraphicString
    mov esi,45+55*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringd
    call OutputGraphicString
    mov esi,45+65*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringe
    call OutputGraphicString
    mov esi,45+75*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringf
    call OutputGraphicString
    mov esi,45+85*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringg
    call OutputGraphicString
    mov esi,45+95*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringh
    call OutputGraphicString
    mov esi,45+105*288
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov edi,.stringi
    call OutputGraphicString
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
    ret

.string db 'MISC OPTIONS',0
.stringa db 'SAVE SNAPSHOT',0
.stringb db 'SHOW FPS',0
.stringc db 'HIDE FPS',0
.stringd db 'SAVE SPC DATA',0
.stringe db 'SOUND BUFFER DUMP',0
.stringf db 'SNAPSHOT/INCR FRM',0
.stringg db 'INCR FRAME ONLY',0
.stringh db 'MOVE THIS WINDOW',0
.stringi db 'IMAGE FORMAT: ---',0

NEWSYM menudrawcursor8b
    cmp byte[cbitmode],1
    je near menudrawcursor16b
    ; draw a small red box
    mov esi,41+34*288
    add esi,[menucloc]
    add esi,[vidbuffer]
    add esi,[MenuDisplace]
    mov ecx,148
    mov al,9
.loop
    mov byte[esi],160
    inc esi
    dec ecx
    jnz .loop
    add esi,288-148
    dec al
    mov ecx,148
    jnz .loop
    mov al,128
    ret

NEWSYM menucloc, dd 0

NEWSYM menudrawbox16b
    ; draw shadow behind box
    cmp byte[menu16btrans],0
    jne .noshadow
    mov byte[menu16btrans],1
    mov esi,50*2+30*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,150
    mov al,85
    mov ah,5
.loop16b2
    mov dx,[esi]
    and dx,[vesa2_clbit]
    shr dx,1
    mov [esi],dx
    add esi,2
    dec ecx
    jnz .loop16b2
    add esi,288*2-150*2
    dec al
    mov ecx,150
    jnz .loop16b2
.noshadow

    mov ax,01Fh
    mov cl,[vesa2_rpos]
    shl ax,cl
    mov [.allred],ax
    mov ax,012h
    mov cl,[vesa2_bpos]
    shl ax,cl
    mov dx,ax
    mov ax,01h
    mov cl,[vesa2_gpos]
    shl ax,cl
    mov bx,ax
    mov ax,01h
    mov cl,[vesa2_rpos]
    shl ax,cl
    or bx,ax

    ; draw a small blue box with a white border
    mov esi,40*2+20*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,150
    mov al,95
    mov ah,5
.loop16b
    mov [esi],dx
    add esi,2
    dec ecx
    jnz .loop16b
    add esi,288*2-150*2
    dec ah
    jnz .nocolinc16b
    add dx,bx
    mov ah,5
.nocolinc16b
    dec al
    mov ecx,150
    jnz .loop16b

    ; Draw lines
    mov ax,0FFFFh
    mov esi,40*2+20*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,150
    call drawhline16b
    mov esi,40*2+20*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,95
    call drawvline16b
    mov esi,40*2+114*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,150
    call drawhline16b
    mov esi,40*2+32*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,150
    call drawhline16b
    mov esi,189*2+20*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,95
    call drawvline16b
    call menudrawcursor16b

    mov esi,45*2+23*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.string
    call OutputGraphicString16b
    mov esi,45*2+35*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringa
    call OutputGraphicString16b
    mov esi,45*2+45*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringb
    test byte[FPSOn],1
    jz .nofps
    mov edi,menudrawbox8b.stringc
.nofps
    call OutputGraphicString16b
    mov esi,45*2+55*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringd
    call OutputGraphicString16b
    mov esi,45*2+65*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringe
    call OutputGraphicString16b
    mov esi,45*2+75*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringf
    call OutputGraphicString16b
    mov esi,45*2+85*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringg
    call OutputGraphicString16b
    mov esi,45*2+95*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringh
    call OutputGraphicString16b
    mov esi,45*2+105*288*2
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov edi,menudrawbox8b.stringi
    call OutputGraphicString16b
    mov al,[newengen]
    mov byte[newengen],0
    push eax
    call copyvid
    pop eax
    mov [newengen],al
    ret

.allred dw 0
.blue   dw 0
.stepb  dw 0

NEWSYM menu16btrans, db 0

NEWSYM menudrawcursor16b
    ; draw a small red box
    mov esi,41*2+34*288*2
    add esi,[menucloc]
    add esi,[menucloc]
    add esi,[vidbuffer]
    add esi,[MenuDisplace16]
    mov ecx,148
    mov al,9
    mov bx,[menudrawbox16b.allred]
.loop
    mov [esi],bx
    add esi,2
    dec ecx
    jnz .loop
    add esi,288*2-148*2
    dec al
    mov ecx,148
    jnz .loop
    mov al,128
    ret

NEWSYM savespcdata
    sub dword[spcPCRam],spcRam
    ; Assemble N/Z flags into P
    and byte[spcP],0FDh
    test byte[spcNZ],0FFh
    jnz .nozero
    or byte[spcP],02h
.nozero
    and byte[spcP],07Fh
    test byte[spcNZ],80h
    jz .noneg
    or byte[spcP],80h
.noneg
    mov ax,[spcPCRam]
    mov [ssdatst+37],ax
    mov al,[spcA]
    mov [ssdatst+39],al
    mov al,[spcX]
    mov [ssdatst+40],al
    mov al,[spcY]
    mov [ssdatst+41],al
    mov al,[spcP]
    mov [ssdatst+42],al
    mov al,[spcS]
    mov [ssdatst+43],al
    add dword[spcPCRam],spcRam
.savestuff
    sub dword[spcPCRam],spcRam
    sub dword[spcRamDP],spcRam
    call PrepareSaveState
    ; Copy from fnames to .spcfname, replacing .srm with .spc
    mov esi,fnames+1
    mov edi,.spcfname
.next
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    cmp al,'.'
    jne .next
    ; Save stuff
    mov byte[edi],'s'
    mov byte[edi+1],'p'
    mov byte[edi+2],'c'
    mov byte[edi+3],0
    ; Find an unoccupied file
.tryagainspc
    mov edx,.spcfname
    call Open_File
    jc .nofileopen
    mov bx,ax
    call Close_File
    cmp byte[edi+2],'c'
    jne .notc
    mov byte[edi+2],'1'
    jmp .tryagainspc
.notc
    cmp byte[edi+2],'9'
    je .donext10
    inc byte[edi+2]
    jmp .tryagainspc
.donext10
    mov al,[edi+1]
    cmp al,[edi+2]
    je .nofileopen
    cmp byte[edi+1],'p'
    jne .notp
    mov byte[edi+1],'0'
.notp
    inc byte[edi+1]
    mov byte[edi+2],'0'
    jmp .tryagainspc
.nofileopen
    xor al,al
    mov al,[edi+1]
    mov [showmenu.saved+2],al
    mov al,[edi+2]
    mov [showmenu.saved+3],al
    ; copy spcextra ram to dspmem+192
    mov esi,spcextraram
    mov edi,DSPMem+192
    mov ecx,64
.loop
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    dec ecx
    jnz .loop

    ; Copy Game Title

    mov esi,[romdata]
    add esi,7FC0h
    cmp byte[romtype],2
    jne .nohirom2
    add esi,8000h
.nohirom2
    mov ecx,20
    mov edi,ssdatst+46+32
.romloop
    mov al,[esi]
    mov [edi],al
    inc esi
    inc edi
    dec ecx
    jnz .romloop
    ; Copy Date of spc dumped
    call Get_Date
    mov [ssdatst+09Eh],dl
    mov [ssdatst+09Fh],dh
    mov [ssdatst+0A0h],cx

    ; Set Channel Disables
    mov byte[ssdatst+0D0h],0
    cmp byte[Voice0Disable],1
    je .enable0
    or byte[ssdatst+0D0h],1
.enable0
    cmp byte[Voice1Disable],1
    je .enable1
    or byte[ssdatst+0D0h],2
.enable1
    cmp byte[Voice2Disable],1
    je .enable2
    or byte[ssdatst+0D0h],4
.enable2
    cmp byte[Voice3Disable],1
    je .enable3
    or byte[ssdatst+0D0h],8
.enable3
    cmp byte[Voice4Disable],1
    je .enable4
    or byte[ssdatst+0D0h],16
.enable4
    cmp byte[Voice5Disable],1
    je .enable5
    or byte[ssdatst+0D0h],32
.enable5
    cmp byte[Voice6Disable],1
    je .enable6
    or byte[ssdatst+0D0h],64
.enable6
    cmp byte[Voice7Disable],1
    je .enable7
    or byte[ssdatst+0D0h],128
.enable7

;  times 32 db 0 ; Title of game (Offset 48)
;  times 32 db 0 ; Song Name
;  times 32 db 0 ; Author of Song
;  times 32 db 0 ; Name of dumper
;  times 32 db 0 ; Comments
;  times 4  db 0 ; date of spc dumped
;  times 4  db 0 ; time in milliseconds before fading out
;  times 2  db 0 ; fade-out length in milliseconds
;  db 0          ; default channel enables

    mov edx,.spcfname
    call Create_File
    mov bx,ax
    mov ecx,256
    mov edx,ssdatst
    call Write_File

    ; Save SPC stuff
    mov ecx,65536
    mov edx,spcRam
    call Write_File
    mov ecx,256
    mov edx,DSPMem
    call Write_File
    call Close_File
    add dword[spcPCRam],spcRam
    add dword[spcRamDP],spcRam
    call ResetState
    ret

.spcfname times 128 db 0
;.SPC File Format

;Offset 00000h - File Header : SNES-SPC700 Sound File Data v0.10
;Offset 00021h - 0x26,0x26,0x26
;Offset 00024h - Version #(/100)
;Offset 00025h - PC Register value (1 Word)
;Offset 00027h - A Register Value (1 byte)
;Offset 00028h - X Register Value (1 byte)
;Offset 00029h - Y Register Value (1 byte)
;Offset 0002Ah - Status Flags Value (1 byte)
;Offset 0002Bh - Stack Register Value (1 byte)
;Offset 0002Ch-000FFh - Reserved For Future Use
;Offset 00100h-100FFh - SPCRam
;Offset 10100h-101FFh - DSPRam

;Offset 0002Eh-0004Dh - SubTitle/Song Name
;Offset 0004Eh-0006Dh - Title of Game
;Offset 0006Eh-0007Dh - Name of Dumper
;Offset 0007Eh-0009Dh - Comments
;Offset 0009Eh-000A4h - Date of SPC Dumped in decimal (DD/MM/YYYY)
;Offset 000A9h-000ABh - Time in seconds for the spc to play before fading
;Offset 000ACh-000AFh - Fade out time in milliseconds
;Offset 000B0h-000CFh - Author of Song
;Offset 000D0h        - Default Channel Disables (0 = enable, 1 = disable)
;Offset 000D1h        - Emulator used to dump .spc file
;                       (0 = UNKNOWN, 1 = ZSNES, 2 = SNES9X)
;                       (Note : Contact the authors if you're an snes emu
;                       author with an .spc capture in order to assign
;                       you a number)

;Offset 0002Eh-0004Dh - Name of SPC (32 bytes)
;Offset 0004Eh-0005Dh - Name of Game (16 bytes)
;Offset 0006Eh-0007Dh - Name of SPC dumper (16 bytes)
;Offset 0007Eh-0009Dh - Comments (32 bytes)
;Offset 0009Eh-000A8h - Date the SPC was Dumped (10 bytes)
;Offset 000A9h-000ABh - Internal SPC timer (3 bytes)

NEWSYM ssdatst
  db 'SNES-SPC700 Sound File Data v0.30',26,26,26     ; offset 0
  db 10 ; Version #(/100), offset 36
  ; SPC Registers
  dw 0  ; PC, offset 37
  db 0  ; A, offset 39
  db 0  ; X, offset 40
  db 0  ; Y, offset 41
  db 0  ; P, offset 42
  db 0  ; S, offset 43
  db 0,0 ; offset 44 (reserved)

  times 32 db 0 ; Title of game (Offset 46)
  times 32 db 0 ; Song Name
  times 16 db 0 ; Name of dumper
  times 32 db 0 ; Comments
  times 10 db 0 ; date of spc dumped
  times 4  db 0 ; time in seconds before fading out
  times 4  db 0 ; fade-out length in milliseconds
  times 32 db 0 ; Author of Song
  db 0          ; default channel enables
  db 1          ; emulator used to dump .spc files
  ; 32*5+20 = 180

  times 48 db 0        ;(reserved), offset 224
  ; SPCRAM (offset 256), 64k
  ; DSPRAM (offset 256+65536), 256 bytes

NEWSYM dumpsound
    mov cx,0
    mov edx,.filename
    call Create_File
    ; Process sound data
    mov bx,ax
    xor ecx,ecx
    xor esi,esi
.loop
    push eax
    mov eax,[spcBuffera]
    mov edx,dword[eax+ecx*4]
    pop eax
    cmp edx,0
    je .nowrite
    mov [mode7tab+esi],edx
    add esi,4
    cmp esi,65536
    je .savenow
.return
.nowrite
    inc cx
    jnz .loop
    cmp esi,0
    je .nosave
    mov ecx,esi
    mov edx,mode7tab
    call Write_File
.nosave
    call Close_File
    call Makemode7Table
    ret

.savenow
    push ecx
    mov ecx,65536
    mov edx,mode7tab
    call Write_File
    pop ecx
    xor esi,esi
    jmp .return

.filename db 'SOUNDDMP.RAW',0

NEWSYM pcxheader
          db 10,5,1,8
          dw 0,0,255,223
          dw 256,224
          times 48 db 0
          db 0,1
.bpline   dw 256
          times 128-68 db 0

NEWSYM picnum, dw 0

NEWSYM savepcx
%ifndef NO_PNG
        cmp byte[ScreenShotFormat],1
        jne .notpng
        call Grab_PNG_Data
	ret
.notpng
%endif
    
    mov byte[pressed+1],0
    mov byte[pressed+59],0
    cmp byte[cbitmode],1
    je near .save16b
    mov edi,pcxheader
    mov ecx,128
.clearhead
    mov byte[edi],0
    inc edi
    dec ecx
    jnz .clearhead
    mov byte[pcxheader+0],10
    mov byte[pcxheader+1],5
    mov byte[pcxheader+2],1
    mov byte[pcxheader+3],8
    mov word[pcxheader+8],255
    mov word[pcxheader+10],222
    mov byte[pcxheader.bpline-1],1
    mov word[pcxheader.bpline],256
    cmp byte[resolutn],224
    je .res224ph
    mov word[pcxheader+10],237
.res224ph

    ; get unused filename
    mov byte[.filename+5],'.'
    mov byte[.filename+6],'p'
    mov byte[.filename+7],'c'
    mov byte[.filename+8],'x'
    mov byte[.filename+9],0
    mov word[picnum],1
.findagain
    mov edx,.filename
    call Open_File
    jc near .nofile
    mov bx,ax
    call Close_File

    inc word[picnum]
    cmp word[picnum],1000
    je .nofile

    mov ax,[picnum]
    xor edx,edx
    mov bx,100
    div bx
    mov cl,al
    mov ax,dx
    xor edx,edx
    mov bx,10
    div bx
    mov esi,.filename+5
    add cl,48
    add al,48
    add dl,48
    cmp cl,48
    je .nohund
    mov byte[esi],cl
    mov byte[esi+1],al
    mov byte[esi+2],dl
    add esi,3
    jmp .finproc
.nohund
    cmp al,48
    je .noten
    mov byte[esi],al
    mov byte[esi+1],dl
    add esi,2
    jmp .finproc
.noten
    mov byte[esi],dl
    inc esi
.finproc
    mov byte[esi],'.'
    mov byte[esi+1],'p'
    mov byte[esi+2],'c'
    mov byte[esi+3],'x'
    mov byte[esi+4],0
    jmp .findagain
.nofile

    mov edx,.filename
    call Create_File
    ; Save header
    mov bx,ax
    mov ecx,128
    mov edx,pcxheader
    call Write_File
    ; Save picture Data
    mov byte[.rowsleft],223
    cmp byte[resolutn],224
    je .res224p
    mov byte[.rowsleft],238
.res224p
    mov ecx,256
    mov edx,[vidbuffer]
    add edx,16+288
.a
    xor ecx,ecx
    mov esi,edx
    mov edi,mode7tab
    push ebx
    mov ebx,256
.loopp
    mov al,[esi]
    mov [edi],al
    mov ah,al
    and ah,0C0h
    cmp ah,0C0h
    jne .norep
    mov byte[edi],0C1h
    inc edi
    inc ecx
    mov byte[edi],al
.norep
    inc ecx
    inc esi
    inc edi
    dec ebx
    jnz .loopp
    pop ebx
    xor al,al
    push edx
    mov edx,mode7tab
    call Write_File
    pop edx
    add edx,288
    dec byte[.rowsleft]
    jnz .a
    ; Save Palette
    mov ecx,769
    mov edx,[vidbuffer]
    add edx,100000
    call Write_File
    call Makemode7Table
    call Close_File
;    mov dword[Msgptr],.pcxsaved
;    mov eax,[MsgCount]
;    mov [MessageOn],eax
    ret

.save16b
    test byte[pressed+14],1
    jnz near save16b2
    call prepare16b
    mov edi,pcxheader
    mov ecx,128
.clearhead2
    mov byte[edi],0
    inc edi
    dec ecx
    jnz .clearhead2
    ; Initial header = 14 bytes
    mov byte[pcxheader],'B'
    mov byte[pcxheader+1],'M'
    mov dword[pcxheader+2],02A01Ah-768
    mov dword[pcxheader+10],26

    mov dword[pcxheader+14],12
    mov word[pcxheader+18],256
    mov word[pcxheader+20],223
    mov word[pcxheader+22],1
    mov word[pcxheader+24],24

    cmp byte[resolutn],224
    je .res224b
    add dword[pcxheader+2],768*15
    mov word[pcxheader+20],238
.res224b

    ; get unused filename
    mov byte[.filename2+5],'.'
    mov byte[.filename2+6],'b'
    mov byte[.filename2+7],'m'
    mov byte[.filename2+8],'p'
    mov byte[.filename2+9],0
    mov word[picnum],1
.findagain2
    mov edx,.filename2
    call Open_File
    jc near .nofile2
    mov bx,ax
    call Close_File

    inc word[picnum]
    cmp word[picnum],1000
    je near .nofile2

    mov ax,[picnum]
    xor edx,edx
    mov bx,100
    div bx
    mov cl,al
    mov ax,dx
    xor edx,edx
    mov bx,10
    div bx
    mov esi,.filename2+5
    add cl,48
    add al,48
    add dl,48
    cmp cl,48
    je .nohund2
    mov byte[esi],cl
    mov byte[esi+1],al
    mov byte[esi+2],dl
    add esi,3
    jmp .finproc2
.nohund2
    cmp al,48
    je .noten2
    mov byte[esi],al
    mov byte[esi+1],dl
    add esi,2
    jmp .finproc2
.noten2
    mov byte[esi],dl
    inc esi
.finproc2
    mov byte[esi],'.'
    mov byte[esi+1],'b'
    mov byte[esi+2],'m'
    mov byte[esi+3],'p'
    mov byte[esi+4],0
    jmp .findagain2
.nofile2

    mov edx,.filename2
    call Create_File
    ; Save header
    mov bx,ax
    mov ecx,26
    mov edx,pcxheader
    call Write_File
    ; Save picture Data
    mov byte[.rowsleft],223
    mov esi,[vidbuffer]
    add esi,32+288*2*223
    cmp byte[resolutn],224
    je .res224b2
    mov byte[.rowsleft],238
    add esi,288*2*15
.res224b2
    mov [.curdptr],esi
.a2
    mov ecx,256
    mov edi,mode7tab
    mov esi,[.curdptr]
    sub dword[.curdptr],288*2
.b2
    push ecx
    mov ax,[esi]
    mov cl,[vesa2_bpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi],al
    mov ax,[esi]
    mov cl,[vesa2_gpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi+1],al
    mov ax,[esi]
    mov cl,[vesa2_rpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi+2],al
    pop ecx
    add edi,3
    add esi,2
    dec ecx
    jnz .b2
    push edx
    mov ecx,768
    mov edx,mode7tab
    call Write_File
    pop edx
    add edx,288*2
    dec byte[.rowsleft]
    jnz near .a2
    call Makemode7Table
    call Close_File
;    mov dword[Msgptr],.rawsaved
;    mov eax,[MsgCount]
;    mov [MessageOn],eax
    call restore16b
    ret

.pcxsaved db 'SNAPSHOT SAVED TO '
.filename db 'image.pcx',0,0,0,0
.rawsaved db 'SNAPSHOT SAVED TO '
.filename2 db 'image.bmp',0,0,0,0
.rowsleft db 0
.curdptr dd 0

NEWSYM save16b2
    call prepare16b
    mov byte[pressed+14],2
    push es
    mov edi,pcxheader
    mov ecx,128
.clearhead2
    mov byte[edi],0
    inc edi
    dec ecx
    jnz .clearhead2
    ; Initial header = 14 bytes
    mov byte[pcxheader],'B'
    mov byte[pcxheader+1],'M'
    mov dword[pcxheader+2],02A01Ah-256*224*3+512*448*3
    mov dword[pcxheader+10],26
    mov dword[pcxheader+14],12
    mov word[pcxheader+18],512
    mov word[pcxheader+20],448
    mov word[pcxheader+22],1
    mov word[pcxheader+24],24

    ; get unused filename
    mov byte[.filename2+5],'.'
    mov byte[.filename2+6],'b'
    mov byte[.filename2+7],'m'
    mov byte[.filename2+8],'p'
    mov byte[.filename2+9],0
    mov word[picnum],1
.findagain2
    mov edx,.filename2
    call Open_File
    jc near .nofile2
    mov bx,ax
    call Close_File

    inc word[picnum]
    cmp word[picnum],1000
    je near .nofile2

    mov ax,[picnum]
    xor edx,edx
    mov bx,100
    div bx
    mov cl,al
    mov ax,dx
    xor edx,edx
    mov bx,10
    div bx
    mov esi,.filename2+5
    add cl,48
    add al,48
    add dl,48
    cmp cl,48
    je .nohund2
    mov byte[esi],cl
    mov byte[esi+1],al
    mov byte[esi+2],dl
    add esi,3
    jmp .finproc2
.nohund2
    cmp al,48
    je .noten2
    mov byte[esi],al
    mov byte[esi+1],dl
    add esi,2
    jmp .finproc2
.noten2
    mov byte[esi],dl
    inc esi
.finproc2
    mov byte[esi],'.'
    mov byte[esi+1],'b'
    mov byte[esi+2],'m'
    mov byte[esi+3],'p'
    mov byte[esi+4],0
    jmp .findagain2
.nofile2

    mov cx,0
    mov edx,.filename2
    call Create_File
    ; Save header
    mov bx,ax
    mov ecx,26
    mov edx,pcxheader
    call Write_File
    ; Save picture Data
    mov dword[.rowsleft],448
    mov ax,[vesa2selec]
    mov es,ax
    mov esi,32*2+640*2*223*2+640*2
    mov [.curdptr],esi
.a2
    mov ecx,512
    mov edi,mode7tab
    mov esi,[.curdptr]
    sub dword[.curdptr],640*2
.b2
    push ecx
    mov ax,[es:esi]
    mov cl,[vesa2_bpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi],al
    mov ax,[es:esi]
    mov cl,[vesa2_gpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi+1],al
    mov ax,[es:esi]
    mov cl,[vesa2_rpos]
    shr ax,cl
    and ax,1Fh
    shl al,3
    mov byte[edi+2],al
    pop ecx
    add edi,3
    add esi,2
    dec ecx
    jnz .b2
    push edx
    mov ecx,768*2
    mov edx,mode7tab
    call Write_File
    pop edx
    add edx,288*2
    dec dword[.rowsleft]
    jnz near .a2
    call Makemode7Table
    call Close_File
;    mov dword[Msgptr],.rawsaved
;    mov eax,[MsgCount]
;    mov [MessageOn],eax
    pop es
    call restore16b
    ret

.rawsaved db 'SNAPSHOT SAVED TO '
.filename2 db 'image.bmp',0,0,0,0
.rowsleft dd 0
.curdptr dd 0

prepare16b:
   cmp byte[vesa2red10],1
   jne .nored
   cmp byte[cvidmode],5
   jne .nored
   cmp byte[scanlines],1
   je .nored
   cmp byte[smallscreenon],1
   je .nored
   mov byte[vesa2_rpos],10
   mov byte[vesa2_gpos],5
.nored
   ret
restore16b:
   cmp byte[vesa2red10],1
   jne .nored
   mov byte[vesa2_rpos],11
   mov byte[vesa2_gpos],6
.nored
   ret
NEWSYM MenuAsmEnd
