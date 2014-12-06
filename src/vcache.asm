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

EXTSYM MessageOn,MsgCount,Msgptr,Voice0Disable,Voice0Status,Voice1Disable
EXTSYM Voice1Status,Voice2Disable,Voice2Status,Voice3Disable,Voice3Status
EXTSYM Voice4Disable,Voice4Status,Voice5Disable,Voice5Status,Voice6Disable
EXTSYM Voice6Status,Voice7Disable,Voice7Status,bgcmsung,bgmode,cbackofsaddr
EXTSYM cbitmode,cgmod,debuggeron,disableeffects,frameskip,frskipper,newgfxerror2
EXTSYM maxbr,modeused,mousexloc,mouseyloc,newengen,newgfx16b,newgfxerror
EXTSYM nextdrawallng,oamaddr,pal16b,pal16bxcl,pressed,prevbright,prevpal
EXTSYM scaddsngb,scaddtngb,scaddtngbx,scfbl,scrndis,snesmouse,sprprdrn
EXTSYM t1cc,vidbright,vidbuffer,vidbufferm,vidbufferofsa,vidbufferofsb
EXTSYM vidmemch2,statefileloc,fnamest,GUIClick,MousePRClick,ngmsdraw,cvidmode
EXTSYM KeyDisableSC0,KeyDisableSC1,KeyDisableSC2,KeyDisableSC3,KeyDisableSC4
EXTSYM KeyDisableSC5,KeyDisableSC6,KeyDisableSC7,KeyFastFrwrd,SRAMSave5Sec
EXTSYM KeyBGDisble0,KeyBGDisble1,KeyBGDisble2,KeyBGDisble3,KeySprDisble
EXTSYM KeyResetAll,KeyExtraEnab,KeyWinDisble,KeyNewGfxSwt,KeyOffsetMSw
EXTSYM KeyStateSlc0,KeyStateSlc1,KeyStateSlc2,KeyStateSlc3,KeyStateSlc4
EXTSYM KeyStateSlc5,KeyStateSlc6,KeyStateSlc7,KeyStateSlc8,KeyStateSlc9
EXTSYM KeyIncStateSlot,KeyDecStateSlot
EXTSYM maxskip,DSPMem,SprValAdd,dsp1ptr,dsp1array,FastFwdToggle,SaveSramData
EXTSYM ngextbg,Mode7HiRes,Check60hz,Get_MouseData,Get_MousePositionDisplacement
EXTSYM WindowDisables,scanlines,romispal
EXTSYM MusicRelVol,MusicVol,WDSPReg0C,WDSPReg1C
EXTSYM DSPOp02,Op02AAS,Op02AZS,Op02CX,Op02CY,Op02FX,Op02FY
EXTSYM Op02FZ,Op02LES,Op02LFE,Op02VOF,Op02VVA
EXTSYM CurRecv
EXTSYM CNetType
EXTSYM KeySlowDown
EXTSYM chaton
EXTSYM genfulladdtab
EXTSYM KeyFRateDown,KeyFRateUp,KeyVolUp,KeyVolDown,KeyDisplayFPS,FPSOn
EXTSYM bg1ptr,bg2ptr,bg3ptr,bg4ptr,cachebg1,resolutn
EXTSYM curypos,oamram,objhipr,objptr,objptrn,objsize1,objsize2
EXTSYM spritetablea,sprleftpr,sprlefttot,vcache4b
EXTSYM objadds1,objadds2,objmovs1,objmovs2,tltype4b,vidmemch4,vram
EXTSYM bgptr,bgptrc,bgptrd,curtileptr,vcache2b
EXTSYM vcache8b,vidmemch8
EXTSYM offsetmshl,NextLineCache
EXTSYM tltype2b
EXTSYM tltype8b,objwlrpos


NEWSYM VCacheAsmStart



; Process stuff & Cache sprites

NEWSYM fskipped,     db 0
NEWSYM objvramadder, dd 0
NEWSYM pobjvram,     dw 0
NEWSYM sprprifix,    db 1

ALIGN32
NEWSYM OMBGTestVal, dd 0
NEWSYM ngptrdat2, dd 0
NEWSYM ofshvaladd, dd 0
NEWSYM ofsmtptrs, dd 0
NEWSYM ofsmcptr2, dd 0
NEWSYM sramb4save, dd 0
NEWSYM mode7hiresen, dd 1
NEWSYM hiresstuff, dd 0
NEWSYM cmovietimeint, dd 0
NEWSYM overalltimer, dd 0

mousecheck db 0



%macro stateselcomp 3
    mov eax,[%1]
    test byte[pressed+eax],1
    je %%nostsl
    mov byte[pressed+eax],2
    mov byte[sselm+11],%2
    mov eax,[statefileloc]
    mov byte[fnamest+eax],%3
    mov dword[Msgptr],sselm
    mov eax,[MsgCount]
    mov [MessageOn],eax
%%nostsl
%endmacro

%macro soundselcomp 4
    mov eax,[%1]
    test byte[pressed+eax],1
    je %%nosdis
    xor byte[%2],01h
    mov byte[%3],0
    mov byte[pressed+eax],2
    mov byte[sndchena+9],%4
    mov byte[sndchdis+9],%4
    mov dword[Msgptr],sndchena
    test byte[%2],01h
    jnz %%sen
    mov dword[Msgptr],sndchdis
%%sen
    mov eax,[MsgCount]
    mov [MessageOn],eax
%%nosdis
%endmacro


UpdateVolume:
    pushad
    xor eax,eax
    xor edx,edx
    mov al,[MusicRelVol]
    shl eax,7
    mov ebx,100
    div ebx
    cmp al,127
    jb .noof
    mov al,127
.noof
    mov [MusicVol],al

    mov al,[DSPMem+0Ch]
    call WDSPReg0C
    mov al,[DSPMem+1Ch]
    call WDSPReg1C

    mov dword[vollv+14],20202020h
    mov edx,vollv+15
    mov al,[MusicRelVol]
    cmp al,100
    jne .no100
    mov byte[edx],49
    mov byte[edx+1],48
    sub al,100
    add edx,2
.no100
    xor ah,ah
    mov bl,10
    div bl
    cmp al,0
    je .no10
    add al,48
    mov [edx],al
    inc edx
.no10
    add ah,48
    mov [edx],ah
    mov dword[Msgptr],vollv
    mov eax,[MsgCount]
    mov [MessageOn],eax
    popad
    ret

ClockCounter:
    inc dword[overalltimer]
    cmp byte[romispal],0
    jne .dopal
    cmp dword[overalltimer],60
    jne .notimer
    inc dword[cmovietimeint]
    sub dword[overalltimer],60
    jmp .notimer
.dopal
    cmp dword[overalltimer],50
    jne .notimer
    inc dword[cmovietimeint]
    sub dword[overalltimer],50
.notimer
    test byte[pressed+2Eh],1
    jz .noclear
    mov dword[cmovietimeint],0
    mov dword[overalltimer],0
.noclear
    ret


NEWSYM dsp1teststuff
    ; /////////////////////////////
    mov dword[dsp1ptr],0
    push eax
    push ecx
    mov ecx,4096
    mov eax,dsp1array
.cvloop
    mov byte[eax],0
    inc eax
    dec ecx
    jnz .cvloop
    pop ecx
    pop eax
    ret
    mov eax,dsp1array
    add eax,[dsp1ptr]
    push ebx
    mov byte[eax],02h
    mov bx,[Op02FX]
    mov [eax+1],bx
    mov bx,[Op02FY]
    mov [eax+3],bx
    mov bx,[Op02FZ]
    mov [eax+5],bx
    mov bx,[Op02LFE]
    mov [eax+7],bx
    mov bx,[Op02LES]
    mov [eax+9],bx
    mov bx,[Op02AAS]
    mov [eax+11],bx
    mov bx,[Op02AZS]
    mov [eax+13],bx
    mov bx,[Op02VOF]
    mov [eax+15],bx
    mov bx,[Op02VVA]
    mov [eax+17],bx
    mov bx,[Op02CX]
    mov [eax+19],bx
    mov bx,[Op02CY]
    mov [eax+21],bx
    pop ebx
    add dword[dsp1ptr],23
    pop ecx
    pop eax
    ; /////////////////////////////
    ret

FastForwardLock db 0
SlowDownLock db 0
FastForwardLockp db 0
SaveRamSaved db 'SAVED SRAM DATA',0
NEWSYM CSprWinPtr, dd 0

NEWSYM cachevideo
    mov byte[NextLineCache],0
    mov dword[objwlrpos],0FFFFFFFFh
    mov dword[CSprWinPtr],0
    mov byte[pressed],0
    mov dword[objvramadder],0
    mov dword[bgcmsung],0
    mov dword[modeused],0
    mov dword[modeused+4],0
    mov dword[scaddsngb],0
    mov dword[scaddtngb],0
    mov dword[sprprdrn],0
    mov dword[ngmsdraw],0
    mov dword[ngextbg],0
    mov dword[scaddtngbx],0FFFFFFFFh
    mov byte[hiresstuff],0
    mov byte[Mode7HiRes],0
    cmp dword[WindowDisables],0
    je .nowindis
    dec dword[WindowDisables]
.nowindis

    cmp byte[CurRecv],1
    je near .fskipall

    call ClockCounter

    cmp byte[mode7hiresen],0
    je .nohires
    cmp byte[scanlines],1
    je .nohires
    cmp byte[cvidmode],9
    je .yeshires
    cmp byte[cvidmode],15
    jne .nohires
.yeshires
    mov byte[Mode7HiRes],1
.nohires
    mov dword[scfbl],1
    mov al,[vidbright]
    mov [maxbr],al
    mov byte[cgmod],1
    xor al,al
    mov [curblank],al
    cmp byte[debuggeron],0
    je .nodebugger
    mov byte[curblank],40h
    mov al,40h
    jmp .nofrskip
.nodebugger

    cmp dword[sramb4save],0
    je .nofocussave
    cmp byte[SRAMSave5Sec],0
    je .nofocussaveb
    dec dword[sramb4save]
    cmp dword[sramb4save],0
    jne .nofocussave
    pushad
    call SaveSramData
    popad
;    mov dword[Msgptr],SaveRamSaved
;    mov eax,[MsgCount]
;    mov [MessageOn],eax
    jmp .nofocussave
.nofocussaveb
    mov dword[sramb4save],0
.nofocussave

    cmp byte[CNetType],20
    je near .sdskip

    cmp byte[FastFwdToggle],0
    jne .ffmode2
    mov eax,[KeyFastFrwrd]
    test byte[pressed+eax],1
    jnz near .fastfor
    jmp .ffskip
.ffmode2
    mov eax,[KeyFastFrwrd]
    test byte[pressed+eax],1
    je .nofastfor
    mov byte[pressed+eax],2
    xor byte[FastForwardLock],1
    jmp .ff
.nofastfor
.ff
    cmp byte[FastForwardLock],1
    je near .fastfor
.ffskip

    cmp byte[FastFwdToggle],0
    jne .sdmode2
    mov eax,[KeySlowDown]
    test byte[pressed+eax],1
    jnz near .slowdwn
    jmp .sdskip
.sdmode2
    mov eax,[KeySlowDown]
    test byte[pressed+eax],1
    je .noslowdwn
    mov byte[pressed+eax],2
    xor byte[SlowDownLock],1
.noslowdwn
    cmp byte[SlowDownLock],1
    je near .slowdwn
    jmp .sdskip
.slowdwn
    mov ax,2
    jmp .skipnoslowdown
.sdskip
    mov ax,1
.skipnoslowdown

    cmp byte[frameskip],0
    jne near .frameskip
    cmp word[t1cc],ax
    jae .skipt1ccc
.noskip
    push eax
    call Check60hz
    pop eax
    cmp word[t1cc],ax
    jb .noskip
.skipt1ccc
    sub word[t1cc],ax
    cmp word[t1cc],ax
    jb .noskip2
    mov byte[curblank],40h
    inc byte[fskipped]
    mov al,40h
    mov cl,[maxskip]
    cmp byte[fskipped],cl
    jbe near .nofrskip
    mov word[t1cc],0
    mov byte[curblank],0
    mov byte[fskipped],0
    jmp .nofrskip
.noskip2
    mov byte[fskipped],0
    jmp .nofrskip
.fastfor
    inc byte[frskipper]
    push ebx
    mov bl,10
    jmp .fastforb
.frameskip
    inc byte[frskipper]
    push ebx
    mov bl,byte[frameskip]
.fastforb
    cmp byte[frskipper],bl
    pop ebx
    jae .nofrskip
.fskipall
    mov byte[curblank],40h
    mov al,40h
    jmp .frskip
.nofrskip
    mov byte[frskipper],0
.frskip
    push ebx
    push esi
    push edi
    push edx
    inc byte[mousecheck]
    and byte[mousecheck],07h
    cmp byte[mousecheck],0
    jne .noclick
    cmp byte[GUIClick],0
    je .noclick
    cmp byte[snesmouse],0
    jne .noclick
    call Get_MouseData
    test bx,02h
    jz .norclick
    cmp byte[MousePRClick],0
    jne .noclick
    mov byte[pressed+1],1
.norclick
    mov byte[MousePRClick],0
.noclick
    mov ax,[oamaddr]
    mov cl,[bgmode]
    mov al,01h
    shl al,cl
    mov [cachedmode],al
    ; disable all necessary backgrounds
    cmp byte[chaton],1
    je near .finishchatskip
    mov eax,[KeyBGDisble0]
    test byte[pressed+eax],1
    je .nodis1
    xor byte[scrndis],01h
    mov byte[pressed+eax],2
    mov dword[Msgptr],bg1layena
    test byte[scrndis],01h
    jz .en1
    mov dword[Msgptr],bg1laydis
.en1
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis1
    mov eax,[KeyBGDisble1]
    test byte[pressed+eax],1
    je .nodis2
    xor byte[scrndis],02h
    mov byte[pressed+eax],2
    mov dword[Msgptr],bg2layena
    test byte[scrndis],02h
    jz .en2
    mov dword[Msgptr],bg2laydis
.en2
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis2
    mov eax,[KeyBGDisble2]
    test byte[pressed+eax],1
    je .nodis3
    xor byte[scrndis],04h
    mov byte[pressed+eax],2
    mov dword[Msgptr],bg3layena
    test byte[scrndis],04h
    jz .en3
    mov dword[Msgptr],bg3laydis
.en3
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis3
    mov eax,[KeyBGDisble3]
    test byte[pressed+eax],1
    je .nodis4
    xor byte[scrndis],08h
    mov byte[pressed+eax],2
    mov dword[Msgptr],bg4layena
    test byte[scrndis],08h
    jz .en4
    mov dword[Msgptr],bg4laydis
.en4
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis4
    mov eax,[KeySprDisble]
    test byte[pressed+eax],1
    je .nodis5
    xor byte[scrndis],10h
    mov byte[pressed+eax],2
    mov dword[Msgptr],sprlayena
    test byte[scrndis],10h
    jz .en5
    mov dword[Msgptr],sprlaydis
.en5
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis5
    mov eax,[KeyResetAll]
    test byte[pressed+eax],1
    je .nodis6
    mov byte[pressed+eax],2
    mov byte[Voice0Disable],01h
    mov byte[Voice1Disable],01h
    mov byte[Voice2Disable],01h
    mov byte[Voice3Disable],01h
    mov byte[Voice4Disable],01h
    mov byte[Voice5Disable],01h
    mov byte[Voice6Disable],01h
    mov byte[Voice7Disable],01h
    mov byte[scrndis],00h
    mov byte[snesmouse],0
    mov dword[Msgptr],panickeyp
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis6
    mov eax,[KeyExtraEnab]
    test byte[pressed+eax],1
    je near .nodis7
    mov byte[pressed+eax],2
    inc byte[snesmouse]
    cmp byte[snesmouse],5
    jne .mousewrap
    mov byte[snesmouse],0
.mousewrap
    mov dword[Msgptr],snesle
    cmp byte[snesmouse],0
    jne .nom0
    mov dword[Msgptr],snesmousep0
.nom0
    cmp byte[snesmouse],1
    jne .nom1
    mov dword[Msgptr],snesmousep1
.nom1
    cmp byte[snesmouse],2
    jne .nom2
    mov dword[Msgptr],snesmousep2
.nom2
    cmp byte[snesmouse],3
    jne .nom3
    mov dword[Msgptr],snesss
    mov word[mousexloc],128
    mov word[mouseyloc],112
.nom3
    mov eax,[MsgCount]
    mov [MessageOn],eax
    call Get_MousePositionDisplacement
.nodis7
    cmp byte[CNetType],20
    jne .nonet
    cmp byte[snesmouse],0
    je .nonet
    mov byte[snesmouse],0
    mov dword[MessageOn],0
.nonet
    mov eax,[KeyNewGfxSwt]
    test byte[pressed+eax],1
    je near .nodis8
    mov byte[pressed+eax],2
    cmp byte[cbitmode],1
    jne .no16bng
    cmp byte[newgfx16b],1
    je .no16bng
    jmp .no16bng
    mov dword[Msgptr],newgfxerror
.msgstuff
    mov eax,[MsgCount]
    mov [MessageOn],eax
    cmp byte[newengen],0
    je near .nodis8
    mov byte[newengen],0
    jmp .disng
.nores
    mov dword[Msgptr],newgfxerror2
    jmp .msgstuff
.no16bng
    mov byte[prevbright],16
    xor byte[newengen],1
    mov dword[Msgptr],ngena
    cmp byte[newengen],1
    je .disng
    mov dword[Msgptr],ngdis
.disng
    mov eax,[MsgCount]
    mov [MessageOn],eax
    mov dword[nextdrawallng],1
    mov edi,vidmemch2
    mov ecx,1024*3
    mov eax,01010101h
    rep stosd
    mov edi,pal16b
    mov ecx,256
    xor eax,eax
    rep stosd
    mov edi,prevpal
    mov ecx,128
    rep stosd
    mov eax,0FFFFh
    cmp byte[newengen],1
    jne .noneweng
    mov eax,0FFFFFFFFh
.noneweng
    mov edi,pal16bxcl
    mov ecx,256
    rep stosd
    pushad
    call genfulladdtab
    popad
.yesng
.disng2
.nodis8
    mov eax,[KeyWinDisble]
    test byte[pressed+eax],1
    je .nodis9
    mov byte[pressed+eax],2
    xor byte[disableeffects],1
    mov dword[Msgptr],windissw
    cmp byte[disableeffects],1
    je .disablew
    mov dword[Msgptr],winenasw
.disablew
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis9
    mov eax,[KeyOffsetMSw]
    test byte[pressed+eax],1
    je .nodis10
    mov byte[pressed+eax],2
    xor byte[osm2dis],1
    mov dword[Msgptr],ofsdissw
    cmp byte[osm2dis],1
    je .disableom
    mov dword[Msgptr],ofsenasw
.disableom
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nodis10
    mov eax,[KeyVolUp]
    test byte[pressed+eax],1
    je .novolup
    cmp byte[MusicRelVol],100
    jae .novolup
    inc byte[MusicRelVol]
    call UpdateVolume
.novolup
    mov eax,[KeyVolDown]
    test byte[pressed+eax],1
    je .novoldown
    cmp byte[MusicRelVol],0
    je .novoldown
    dec byte[MusicRelVol]
    call UpdateVolume
.novoldown
    mov eax,[KeyFRateUp]
    test byte[pressed+eax],1
    je .nofrup
    mov byte[pressed+eax],2
    cmp byte[frameskip],10
    je .nofrup
    mov byte[FPSOn],0
    inc byte[frameskip]
    mov al,[frameskip]
    add al,47
    mov [frlev+18],al
    mov dword[Msgptr],frlev
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nofrup
    mov eax,[KeyFRateDown]
    test byte[pressed+eax],1
    je .nofrdown
    mov byte[pressed+eax],2
    cmp byte[frameskip],0
    je .nofrdown
    dec byte[frameskip]
    cmp byte[frameskip],0
    je .min
    mov al,[frameskip]
    add al,47
    mov [frlev+18],al
    mov dword[Msgptr],frlev
    jmp .nomin
.min
    mov dword[Msgptr],frlv0
    mov word[t1cc],0
.nomin
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nofrdown
    mov eax,[KeyDisplayFPS]
    test byte[pressed+eax],1
    je .nodisplayfps
    mov byte[pressed+eax],2
    cmp byte[frameskip],0
    jne .nodisplayfps
    xor byte[FPSOn],1
.nodisplayfps

    ; do state selects
    stateselcomp KeyStateSlc0,'0','t'
    stateselcomp KeyStateSlc1,'1','1'
    stateselcomp KeyStateSlc2,'2','2'
    stateselcomp KeyStateSlc3,'3','3'
    stateselcomp KeyStateSlc4,'4','4'
    stateselcomp KeyStateSlc5,'5','5'
    stateselcomp KeyStateSlc6,'6','6'
    stateselcomp KeyStateSlc7,'7','7'
    stateselcomp KeyStateSlc8,'8','8'
    stateselcomp KeyStateSlc9,'9','9'
    mov eax,[KeyStateSlc0]
    test byte[pressed+eax],1
    je .nostsl0
    mov byte[pressed+eax],2
    mov byte[sselm+11],'0'
    mov dword[Msgptr],sselm
    mov eax,[MsgCount]
    mov [MessageOn],eax
.nostsl0

    mov eax,[KeyIncStateSlot]
    test byte[pressed+eax],1
    je .noincstateslot
    mov byte[pressed+eax],2
    mov eax,[statefileloc]
    mov dh,[fnamest+eax]
    cmp dh,'t'
    je .secondstate
    cmp dh,'9'
    je .jumptofirststate
    inc dh
    jmp .donextstate
.secondstate
    mov dh,'1'
    jmp .donextstate
.jumptofirststate
    mov dh,'t'
.donextstate
    mov byte[fnamest+eax],dh
    cmp dh,'t'
    je .firststatemsg
    mov byte[sselm+11],dh
    jmp .incstatemsg
.firststatemsg
    mov byte[sselm+11],'0'
.incstatemsg
    mov dword[Msgptr],sselm
    mov eax,[MsgCount]
    mov [MessageOn],eax
    xor dh,dh
.noincstateslot

    mov eax,[KeyDecStateSlot]
    test byte[pressed+eax],1
    je .nodecstateslot
    mov byte[pressed+eax],2
    mov eax,[statefileloc]
    mov dh,[fnamest+eax]
    cmp dh,'t'
    je .jumptolaststate
    dec dh
    cmp dh,'0'
    jne .doprevstate
.firststate
    mov dh,'t'
    jmp .doprevstate
.jumptolaststate
    mov dh,'9'
.doprevstate
    mov byte[fnamest+eax],dh
    cmp dh,'t'
    je .firststatemsg2
    mov byte[sselm+11],dh
    jmp .decstatemsg
.firststatemsg2
    mov byte[sselm+11],'0'
.decstatemsg
    mov dword[Msgptr],sselm
    mov eax,[MsgCount]
    mov [MessageOn],eax
    xor dh,dh
.nodecstateslot

    ; do sound disables
    soundselcomp KeyDisableSC0,Voice0Disable,Voice0Status,'1'
    soundselcomp KeyDisableSC1,Voice1Disable,Voice1Status,'2'
    soundselcomp KeyDisableSC2,Voice2Disable,Voice2Status,'3'
    soundselcomp KeyDisableSC3,Voice3Disable,Voice3Status,'4'
    soundselcomp KeyDisableSC4,Voice4Disable,Voice4Status,'5'
    soundselcomp KeyDisableSC5,Voice5Disable,Voice5Status,'6'
    soundselcomp KeyDisableSC6,Voice6Disable,Voice6Status,'7'
    soundselcomp KeyDisableSC7,Voice7Disable,Voice7Status,'8'

.finishchatskip
    cmp byte[curblank],0h
    jne near yesblank
    ; Swap video addresses
;    mov ebx,[vidbuffer]
;    cmp ebx,[vidbufferofsa]
;    je .useb
    mov ebx,[vidbufferofsa]
    mov [vidbuffer],ebx
    add ebx,75036+16
    mov [cbackofsaddr],ebx
    mov ebx,[vidbufferofsb]
    mov [vidbufferm],ebx
;    jmp .nouseb
;.useb
;    mov ebx,[vidbufferofsb]
;    mov [vidbuffer],ebx
;    add ebx,75036+16
;    mov [cbackofsaddr],ebx
;    mov ebx,[vidbufferofsa]
;    mov [vidbufferm],ebx
;.nouseb

NEWSYM docache
    xor ebx,ebx
    mov bl,[bgmode]
    shl bl,2
    add ebx,colormodedef
    mov [colormodeofs],ebx
    xor ebx,ebx
    mov bl,[bgmode]
    mov al,[colormodedef+ebx*4]
    mov [curcolbg1],al
    mov ah,[colormodedef+ebx*4+1]
    mov [curcolbg2],ah
    mov al,[colormodedef+ebx*4]
    mov [curcolbg3],al
    mov ah,[colormodedef+ebx*4+1]
    mov [curcolbg4],ah
    mov ax,[bg1ptr]
    mov [curbgofs1],ax
    mov ax,[bg2ptr]
    mov [curbgofs2],ax
    mov ax,[bg3ptr]
    mov [curbgofs3],ax
    mov ax,[bg4ptr]
    mov [curbgofs4],ax
    push es
    mov ax,ds
    mov es,ax
    ; clear # of sprites & bg cache
    mov edi,cachebg1
    mov ecx,64*5+16*4
    xor eax,eax
    rep stosd
;    cmp byte[sprprifix],0
;    je .nosprfix
;    mov edi,sprlefttotb
;    mov ecx,64*3
;    xor eax,eax
;    rep stosd
;.nosprfix
    ; do sprites
;    test word[scrnon],1010h
;    jz .nosprites
    test byte[scrndis],10h
    jnz .nosprites
    call cachesprites
    call processsprites
;    mov byte[sprprncache],0
;    cmp byte[sprprifix],0
;    je .nosprites
;    call processspritesb

.nosprites
    ; fill background with 0's unless 16-bit/new graphics engine mode is on
    jmp .skipbgclear
    cmp byte[cbitmode],1
    je .skipbgclear
    cmp byte[newengen],1
    jne .skipbgclear
    mov edi,[vidbuffer]
    xor eax,eax
    add edi,16
    mov dl,[resolutn]
.loopa
    mov ecx,64
    rep stosd
    add edi,32
    dec dl
    jnz .loopa
.skipbgclear
    xor ecx,ecx
    pop es
NEWSYM yesblank
    pop edx
    pop edi
    pop esi
    pop ebx
    ret

.Zero dd 0,0
.Zero2 dd 0,0

NEWSYM osm2dis,      db 0
NEWSYM cachedmode,   db 0
NEWSYM tempfname,    db 'vram.bin',0
NEWSYM scrnsizebyte, dw 1024,2048,2048,4096
NEWSYM colormodedef, db 1,1,1,1, 2,2,1,0, 2,2,0,0, 3,2,0,0,
               db 3,1,0,0, 2,1,0,0, 2,0,0,0, 0,0,0,0
NEWSYM colormoded2,  db 4,4,4,4, 5,5,4,0, 5,5,0,0, 6,5,0,0,
               db 6,4,0,0, 5,4,0,0, 5,0,0,0, 0,0,0,0
NEWSYM colormodeofs, dd 0
NEWSYM curblank,     db 80h             ; current blank state (40h = skip fill)
NEWSYM addr2add,     dd 0
;cachebg1    times 64 db 0
;cachebg2    times 64 db 0
;cachebg3    times 64 db 0
;cachebg4    times 64 db 0
;sprlefttot  times 256 db 0     ; total sprites left
;sprleftpr   times 256 db 0     ; sprites left for priority 0
;sprleftpr1  times 256 db 0     ; sprites left for priority 1
;sprleftpr2  times 256 db 0     ; sprites left for priority 2
;sprleftpr3  times 256 db 0     ; sprites left for priority 3
;spritetable times 256*512 db 0  ; sprite table (flip/pal/xloc/vbufptr)38*7
NEWSYM curbgofs1,   dw 0
NEWSYM curbgofs2,   dw 0
NEWSYM curbgofs3,   dw 0
NEWSYM curbgofs4,   dw 0
NEWSYM curcolbg1,   db 0
NEWSYM curcolbg2,   db 0
NEWSYM curcolbg3,   db 0
NEWSYM curcolbg4,   db 0
NEWSYM panickeyp,   db 'ALL SWITCHES NORMAL',0
NEWSYM snesmousep0, db 'MOUSE/SUPER SCOPE DISABLED',0
NEWSYM snesmousep1, db 'MOUSE ENABLED IN PORT 1',0
NEWSYM snesmousep2, db 'MOUSE ENABLED IN PORT 2',0
NEWSYM snesss,      db 'SUPER SCOPE ENABLED',0
NEWSYM snesle,      db 'LETHAL ENFORCER GUN ENABLED',0
NEWSYM windissw,    db 'WINDOWING DISABLED',0
NEWSYM winenasw,    db 'WINDOWING ENABLED',0
NEWSYM ofsdissw,    db 'OFFSET MODE DISABLED',0
NEWSYM ofsenasw,    db 'OFFSET MODE ENABLED',0
NEWSYM ngena, db 'NEW GFX ENGINE ENABLED',0
NEWSYM ngdis, db 'NEW GFX ENGINE DISABLED',0
NEWSYM sselm, db 'STATE SLOT 0 SELECTED',0
NEWSYM vollv, db 'VOLUME LEVEL :    ',0
NEWSYM frlev, db 'FRAME SKIP SET TO  ',0
NEWSYM frlv0, db 'AUTO FRAMERATE ENABLED',0
sndchena db 'SOUND CH   ENABLED',0
sndchdis db 'SOUND CH   DISABLED',0
bg1layena db 'BG1 LAYER ENABLED',0
bg2layena db 'BG2 LAYER ENABLED',0
bg3layena db 'BG3 LAYER ENABLED',0
bg4layena db 'BG4 LAYER ENABLED',0
sprlayena db 'SPRITE LAYER ENABLED',0
bg1laydis db 'BG1 LAYER DISABLED',0
bg2laydis db 'BG2 LAYER DISABLED',0
bg3laydis db 'BG3 LAYER DISABLED',0
bg4laydis db 'BG4 LAYER DISABLED',0
sprlaydis db 'SPRITE LAYER DISABLED',0

;*******************************************************
; Process Sprites
;*******************************************************
; Use oamram for object table
NEWSYM processsprites
;    cmp byte[cbitmode],1
;    je .skipnewspr
;    cmp byte[newengen],1
;    je .skipnewspr
    cmp byte[sprprifix],0
    jne near processspritesb
.skipnewspr
    ; set obj pointers
    cmp byte[objsize1],1
    jne .16dot1
    mov ebx,.process8x8sprite
    mov [.size1ptr],ebx
    jmp .fin1
.16dot1
    cmp byte[objsize1],4
    jne .32dot1
    mov ebx,.process16x16sprite
    mov [.size1ptr],ebx
    jmp .fin1
.32dot1
    cmp byte[objsize1],16
    jne .64dot1
    mov ebx,.process32x32sprite
    mov [.size1ptr],ebx
    jmp .fin1
.64dot1
    mov ebx,.process64x64sprite
    mov [.size1ptr],ebx
.fin1
    cmp byte[objsize2],1
    jne .16dot2
    mov ebx,.process8x8sprite
    mov [.size2ptr],ebx
    jmp .fin2
.16dot2
    cmp byte[objsize2],4
    jne .32dot2
    mov ebx,.process16x16sprite
    mov [.size2ptr],ebx
    jmp .fin2
.32dot2
    cmp byte[objsize2],16
    jne .64dot2
    mov ebx,.process32x32sprite
    mov [.size2ptr],ebx
    jmp .fin2 
.64dot2 
    mov ebx,.process64x64sprite
    mov [.size2ptr],ebx
.fin2
    ; set pointer adder
    xor eax,eax
    xor ebx,ebx
    mov al,[objhipr]
    shl ax,2
    mov ebx,eax
    sub bx,4
    and bx,01FCh
    mov dword[addr2add],0
    mov byte[.prileft],4
    mov byte[.curpri],0
    ; do 1st priority
    mov ecx,[objptr]
    shl ecx,1
    mov [.objvramloc],ecx
    mov ecx,[objptrn]
    sub ecx,[objptr]
    shl ecx,1
    mov [.objvramloc2],ecx
    push ebp
    mov ebp,[spritetablea]
.startobject
    mov byte[.objleft],128
.objloop
    xor ecx,ecx
    mov cx,[oamram+ebx+2]
    mov dl,ch
    shr dl,4
    and dl,03h
    cmp dl,[.curpri]
    jne near .nextobj
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    ; set up pointer to esi
    mov dh,ch
    and ch,01h
    shr dh,1
    shl ecx,6
    add ecx,[.objvramloc]
    test byte[oamram+ebx+3],01h
    jz .noloc2
    add ecx,[.objvramloc2]
.noloc2
    and ecx,01FFFFh
    add ecx,[vcache4b]
    mov esi,ecx
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder
    add cx,65535-511
.noadder
    cmp cx,256
    jge .returnfromptr
    cmp cx,-64
    jle .returnfromptr
    test ah,02h
    jz .size1
    jmp dword near [.size2ptr]
.size1
    jmp dword near [.size1ptr]
.returnfromptr
    pop ebx
    ; next object
.nextobj
    sub bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop
    add dword[addr2add],256
    inc byte[.curpri]
    dec byte[.prileft]
    jnz near .startobject
    pop ebp
    ret

.objvramloc dd 0
.objvramloc2 dd 0
.curpri  dd 0
.trypri  dd 0
.objleft dd 0
.prileft dd 0
.size1ptr dd 0
.size2ptr dd 0

.reprocesssprite
    cmp cx,-8
    jle .next
    cmp cx,256
    jge .next
    add cx,8
.reprocessspriteb
    cmp dl,[resolutn]
    jae .overflow
    xor ebx,ebx
    mov bl,dl
    xor eax,eax
    cmp bx,[curypos]
    jb .overflow
    mov al,byte[sprlefttot+ebx]
    cmp al,37
    ja near .overflow
    inc byte[sprlefttot+ebx]
    add ebx,[addr2add]
    inc byte[sprleftpr+ebx]
    sub ebx,[addr2add]
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    mov byte[ebp+ebx+6],dh
    mov byte[ebp+ebx+7],al
.overflow
    inc dl
    add esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteb
    sub cx,8
    ret
.next
    add dl,8
    add esi,64
    ret

.reprocessspriteflipy
    cmp cx,-8
    jle .nextb
    cmp cx,256
    jge .nextb
    add cx,8
.reprocessspriteflipyb
    cmp dl,[resolutn]
    jae .overflow2
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow2
    mov al,byte[sprlefttot+ebx]
    cmp al,37
    ja near .overflow2
    inc byte[sprlefttot+ebx]
    add ebx,[addr2add]
    inc byte[sprleftpr+ebx]
    sub ebx,[addr2add]
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    mov byte[ebp+ebx+6],dh
    mov byte[ebp+ebx+7],al
.overflow2
    inc dl
    sub esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteflipyb
    sub cx,8
    ret
.nextb
    add dl,8
    sub esi,64
    ret

.statusbit db 0

.process8x8sprite:
    test dh,40h
    jnz .8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    jmp .returnfromptr
.8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add esi,56
    call .reprocessspriteflipy
    jmp .returnfromptr
.numleft2do db 0

.process16x16sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .16x16flipx
    test dh,40h
    jnz .16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub cx,8
    add esi,64*14
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    jmp .returnfromptr
.16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,16
    sub cx,8
    add esi,64*14
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    jmp .returnfromptr
.16x16flipx
    test dh,40h
    jnz .16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    call .reprocesssprite
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    add esi,64*14
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    jmp .returnfromptr
.16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    add esi,64*14
    sub dl,16
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    jmp .returnfromptr

;*******************************************************
; Sprite increment/draw macros
;*******************************************************

%macro nextsprite2right 0
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
%endmacro

%macro nextsprite2rightflipy 0
    add esi,128
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
%endmacro

%macro nextsprite2rightflipx 0
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
%endmacro

%macro nextsprite2rightflipyx 0
    add esi,128
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
%endmacro

;*******************************************************
; 32x32 sprites routines
;*******************************************************

%macro nextline32x32 0
    sub cx,24
    add esi,64*12
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
%endmacro

.process32x32sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .32x32flipx
    test dh,40h
    jnz near .32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline32x32
    nextline32x32
    nextline32x32
    jmp .returnfromptr

%macro nextline32x32flipy 0
    sub cx,24
    add esi,64*12+128
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
%endmacro

.32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    jmp .returnfromptr

%macro nextline32x32flipx 0
    add cx,24
    add esi,64*12
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
%endmacro

.32x32flipx
    test dh,40h
    jnz near .32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    jmp .returnfromptr

%macro nextline32x32flipyx 0
    add cx,24
    add esi,64*12+128
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
%endmacro

.32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    jmp .returnfromptr

;*******************************************************
; 64x64 sprites routines
;*******************************************************

%macro nextline64x64 0
    sub cx,56
    add esi,64*8
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
%endmacro

.process64x64sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .64x64flipx
    test dh,40h
    jnz near .64x64flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    jmp .returnfromptr

%macro nextline64x64flipy 0
    sub cx,56
    add esi,64*8+128
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
%endmacro

.64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    jmp .returnfromptr

%macro nextline64x64flipx 0
    add cx,56
    add esi,64*8
    mov byte[.numleft2do],8
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
%endmacro

.64x64flipx
    test dh,40h
    jnz near .64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    jmp .returnfromptr

%macro nextline64x64flipyx 0
    add cx,56
    add esi,64*8+128
    sub dl,16
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
%endmacro

.64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    jmp .returnfromptr

;*******************************************************
; Process Sprites B - Process
;*******************************************************
; Use oamram for object table

NEWSYM processspritesb
    ; set obj pointers
    cmp byte[objsize1],1
    jne .16dot1
    mov ebx,.process8x8sprite
    mov [.size1ptr],ebx
    jmp .fin1
.16dot1
    cmp byte[objsize1],4
    jne .32dot1
    mov ebx,.process16x16sprite
    mov [.size1ptr],ebx
    jmp .fin1
.32dot1
    cmp byte[objsize1],16
    jne .64dot1
    mov ebx,.process32x32sprite
    mov [.size1ptr],ebx
    jmp .fin1
.64dot1
    mov ebx,.process64x64sprite
    mov [.size1ptr],ebx
.fin1
    cmp byte[objsize2],1
    jne .16dot2
    mov ebx,.process8x8sprite
    mov [.size2ptr],ebx
    jmp .fin2
.16dot2
    cmp byte[objsize2],4
    jne .32dot2
    mov ebx,.process16x16sprite
    mov [.size2ptr],ebx
    jmp .fin2
.32dot2
    cmp byte[objsize2],16
    jne .64dot2
    mov ebx,.process32x32sprite
    mov [.size2ptr],ebx
    jmp .fin2 
.64dot2 
    mov ebx,.process64x64sprite
    mov [.size2ptr],ebx
.fin2
    ; set pointer adder
    xor eax,eax
    xor ebx,ebx
    mov al,[objhipr]
    shl ax,2
    mov ebx,eax
    and bx,01FCh
    mov dword[addr2add],0
    ; do 1st priority
    mov ecx,[objptr]
    shl ecx,1
    mov [.objvramloc],ecx
    mov ecx,[objptrn]
    sub ecx,[objptr]
    shl ecx,1
    mov [.objvramloc2],ecx
    push ebp
    mov ebp,[spritetablea]
.startobject
    mov byte[.objleft],128
.objloop
    xor ecx,ecx
    mov cx,[oamram+ebx+2]
    mov dl,ch
    shr dl,4
    and edx,03h
    mov [.cpri],dl
    ; get object information
    push ebx
    mov dl,[oamram+ebx+1]       ; y
    inc dl
    ; set up pointer to esi
    mov dh,ch
    and ch,01h
    shr dh,1
    shl ecx,6
    add ecx,[.objvramloc]
    test byte[oamram+ebx+3],01h
    jz .noloc2
    add ecx,[.objvramloc2]
.noloc2
    and ecx,01FFFFh
    add ecx,[vcache4b]
    mov esi,ecx
    ; get x
    mov al,[oamram+ebx]         ; x
    ; get double bits
    mov cl,bl
    shr ebx,4           ; /16
    shr cl,1
    and cl,06h
    mov ah,[oamram+ebx+512]
    shr ah,cl
    and ah,03h
    mov ch,ah
    and ch,01h
    mov cl,al
    ; process object
    ; esi = pointer to 8-bit object, dh = stats (1 shifted to right)
    ; cx = x position, dl = y position
    cmp cx,384
    jb .noadder
    add cx,65535-511
.noadder
    cmp cx,256
    jge .returnfromptr
    cmp cx,-64
    jle .returnfromptr
    test ah,02h
    jz .size1
    jmp dword near [.size2ptr]
.size1
    jmp dword near [.size1ptr]
.returnfromptr
    pop ebx
    ; next object
.nextobj
    add bx,4
    and bx,01FCh
    dec byte[.objleft]
    jnz near .objloop
    pop ebp
    ret

.objvramloc dd 0
.objvramloc2 dd 0
.curpri  dd 0
.trypri  dd 0
.objleft dd 0
.prileft dd 0
.size1ptr dd 0
.size2ptr dd 0
.cpri     dd 0

.reprocesssprite
    cmp cx,-8
    jle near .next
    cmp cx,256
    jge .next
    add cx,8
.reprocessspriteb
    cmp dl,[resolutn]
    jae .overflow
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow
    mov al,byte[sprlefttot+ebx]
    cmp al,37
    ja near .overflow
    inc byte[sprlefttot+ebx]
    mov edi,[.cpri]
    mov byte[sprleftpr+ebx*4+edi],1
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    and al,0F8h
    or al,[.cpri]
    mov byte[ebp+ebx+6],dh
    mov byte[ebp+ebx+7],al
.overflow
    inc dl
    add esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteb
    sub cx,8
    ret
.next
    add dl,8
    add esi,64
    ret

.reprocessspriteflipy
    cmp cx,-8
    jle near .nextb
    cmp cx,256
    jge .nextb
    add cx,8
.reprocessspriteflipyb
    cmp dl,[resolutn]
    jae .overflow2
    xor ebx,ebx
    xor eax,eax
    mov bl,dl
    cmp bx,[curypos]
    jb .overflow
    mov al,byte[sprlefttot+ebx]
    cmp al,37
    ja near .overflow2
    inc byte[sprlefttot+ebx]
    mov edi,[.cpri]
    mov byte[sprleftpr+ebx*4+edi],1
    shl ebx,9
    shl eax,3
    add ebx,eax
    mov [ebp+ebx],cx
    mov [ebp+ebx+2],esi
    mov al,[.statusbit]
    and al,0F8h
    or al,[.cpri]
    mov byte[ebp+ebx+6],dh
    mov byte[ebp+ebx+7],al
.overflow2
    inc dl
    sub esi,8
    dec byte[.numleft2do]
    jnz .reprocessspriteflipyb
    sub cx,8
    ret
.nextb
    add dl,8
    sub esi,64
    ret

.statusbit db 0

.process8x8sprite:
    test dh,40h
    jnz .8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    jmp .returnfromptr
.8x8flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add esi,56
    call .reprocessspriteflipy
    jmp .returnfromptr
.numleft2do db 0

.process16x16sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .16x16flipx
    test dh,40h
    jnz .16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub cx,8
    add esi,64*14
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    jmp .returnfromptr
.16x16flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,16
    sub cx,8
    add esi,64*14
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    jmp .returnfromptr
.16x16flipx
    test dh,40h
    jnz .16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    call .reprocesssprite
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    add esi,64*14
    add cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocesssprite
    jmp .returnfromptr
.16x16flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,8
    add dl,8
    add esi,56
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    add esi,64*14
    sub dl,16
    add cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    add esi,128
    sub dl,8
    sub cx,8
    mov byte[.numleft2do],8
    call .reprocessspriteflipy
    jmp .returnfromptr

;*******************************************************
; 32x32 sprites routines
;*******************************************************

.process32x32sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .32x32flipx
    test dh,40h
    jnz near .32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline32x32
    nextline32x32
    nextline32x32
    jmp .returnfromptr

.32x32flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline32x32flipy
    nextline32x32flipy
    nextline32x32flipy
    jmp .returnfromptr

.32x32flipx
    test dh,40h
    jnz near .32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline32x32flipx
    nextline32x32flipx
    nextline32x32flipx
    jmp .returnfromptr

.32x32flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,24
    add dl,24
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline32x32flipyx
    nextline32x32flipyx
    nextline32x32flipyx
    jmp .returnfromptr

;*******************************************************
; 64x64 sprites routines
;*******************************************************

.process64x64sprite:
    mov [.statusbit],dh
    test dh,20h
    jnz near .64x64flipx
    test dh,40h
    jnz near .64x64flipy
    mov [.statusbit],dh
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    call .reprocesssprite
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextsprite2right
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    nextline64x64
    jmp .returnfromptr

.64x64flipy
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextsprite2rightflipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    nextline64x64flipy
    jmp .returnfromptr

.64x64flipx
    test dh,40h
    jnz near .64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    call .reprocesssprite
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextsprite2rightflipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    nextline64x64flipx
    jmp .returnfromptr

.64x64flipyx
    and dh,07h
    mov byte[.numleft2do],8
    shl dh,4
    add dh,128
    add cx,56
    add dl,56
    add esi,56
    call .reprocessspriteflipy
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextsprite2rightflipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    nextline64x64flipyx
    jmp .returnfromptr

;*******************************************************
; Cache Process Macros, info from Nerlaska!
;*******************************************************

%macro processcache2b 1
    xor al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

%macro processcache4b 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

;*******************************************************
; Cache Sprites
;*******************************************************
; Use oamram for object table, copy from vram -> vcache4b
; 16x16 sprite, to move = 2, to add = 14, 32x32 = 4,12, 64x64 = 8,8

%macro processcache4bs 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesprites
    ; initialize obj size cache
    mov dword[.objptr],oamram
    add dword[.objptr],512
    mov esi,dword[.objptr]
    mov al,[esi]
    mov [.curobjtype],al
    mov byte[.objleftinbyte],4
    ; Initialize oamram pointer
    mov esi,oamram
    add esi,2

    ; process pointers (.objptra = source, .objptrb = dest)
.trynextgroup
    xor ebx,ebx
    mov bx,[objptr]
    mov ecx,ebx
    shr ecx,4
    mov [.nbg],cx
    mov edi,[vram]
    add edi,ebx
    mov [.objptra],edi
    shl ebx,1
    add ebx,[vcache4b]
    mov [.objptrb],ebx

    xor ebx,ebx
    mov bx,[objptrn]
    mov ecx,ebx
    shr ecx,4
    mov [.nbg2],cx
    mov edi,[vram]
    add edi,ebx
    mov [.objptra2],edi
    shl ebx,1
    add ebx,[vcache4b]
    mov [.objptrb2],ebx

    xor ebx,ebx

    ; process objects
    mov dword[.sprnum],3
    mov byte[.objleft],128
.nextobj
    ; process sprite sizes
    test byte[.curobjtype],02h
    jz .dosprsize1
    mov al,[objsize2]
    mov [.num2do],al
    mov ax,[objadds2]
    mov [.byte2add],ax
    mov al,[objmovs2]
    mov [.byte2move],al
    mov [.byteb4add],al
    jmp .exitsprsize
.dosprsize1
    mov al,[objsize1]
    mov [.num2do],al
    mov ax,[objadds1]
    mov [.byte2add],ax
    mov al,[objmovs1]
    mov [.byte2move],al
    mov [.byteb4add],al
.exitsprsize
    shr byte[.curobjtype],2
    dec byte[.objleftinbyte]
    jnz .skipobjproc
    mov byte[.objleftinbyte],4
    inc dword[.objptr]
    mov ebx,[.objptr]
    mov al,[ebx]
    mov [.curobjtype],al
.skipobjproc
    mov bx,[esi]
    and bh,1h
    mov [.curobj],bx
.nextobject
    mov ebx,[.sprnum]
    mov cl,[oamram+ebx-2]
    mov ch,[curypos]
    dec ch
    cmp cl,ch
    jb near .nocache
    test byte[oamram+ebx],01h
    jnz .namebase
    xor ebx,ebx
    mov bx,[.curobj]
    mov cx,bx
    add bx,bx
    add bx,[.nbg]
    and bx,4095
    test word[vidmemch4+ebx],0101h
    jz near .nocache
    mov word[vidmemch4+ebx],0000h
    mov [.sprfillpl],ebx
    push esi
    shl bx,4
    mov esi,[vram]
    add esi,ebx
    add ebx,ebx
    mov edi,[vcache4b]
    add edi,ebx
    jmp .nonamebase
.namebase
    xor ebx,ebx
    mov bx,[.curobj]
    mov cx,bx
    shl bx,1
    add bx,[.nbg2]
    and bx,4095
    test word[vidmemch4+ebx],0101h
    jz near .nocache
    mov word[vidmemch4+ebx],0000h
    mov [.sprfillpl],ebx
    push esi
    shl bx,4
    mov esi,[vram]
    add esi,ebx
    add ebx,ebx
    mov edi,[vcache4b]
    add edi,ebx
.nonamebase
    ; convert from [esi] to [edi]
    mov byte[.rowleft],8
    mov byte[tiletypec],3
.donext

    mov cx,[esi]
    mov dx,[esi+16]

    processcache4bs 0
    processcache4bs 1
    processcache4bs 2
    processcache4bs 3
    processcache4bs 4
    processcache4bs 5
    processcache4bs 6
    processcache4bs 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    mov ebx,[.sprfillpl]
    mov al,[tiletypec]
    shr ebx,1
    pop esi
    mov byte[tltype4b+ebx],al
.nocache
    inc word[.curobj]
    dec byte[.byteb4add]
    jnz .skipbyteadd
    mov ax,[.byte2add]
    add word[.curobj],ax
    mov al,[.byte2move]
    mov byte[.byteb4add],al
.skipbyteadd
    dec byte[.num2do]
    jnz near .nextobject
    add esi,4
    add dword[.sprnum],4
    dec byte[.objleft]
    jnz near .nextobj
    ret

.objptra dd 0
.objptrb dd 0
.nbg     dd 0
.objptra2 dd 0
.objptrb2 dd 0
.nbg2     dd 0
.objleft db 0
.rowleft db 0
.a       dd 0
.objptr dd 0
.objleftinbyte dd 0
.curobjtype dd 0
.num2do dd 1
.curobj dd 0
.byteb4add dd 2
.byte2move dd 0
.byte2add  dd 0
.sprnum    dd 0
.sprcheck  dd 0
.sprfillpl dd 0

;*******************************************************
; Cache 2-Bit
;*******************************************************
NEWSYM cachetile2b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,4
    mov byte[.count],32
    mov [.nbg],bx
    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    and esi,4095
    test byte[vidmemch2+esi],01h
    jz near .nocache
    mov byte[vidmemch2+esi],00h
    mov edi,esi
    shl esi,4
    shl edi,6
    add esi,[vram]
    add edi,[vcache2b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    processcache2b 0
    processcache2b 1
    processcache2b 2
    processcache2b 3
    processcache2b 4
    processcache2b 5
    processcache2b 6
    processcache2b 7
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg     dw 0
.count   db 0
.a       db 0
.rowleft db 0
.nextar  db 0

NEWSYM cache2bit
    ret

;*******************************************************
; Cache 4-Bit
;*******************************************************

; esi = pointer to tile location vram
; edi = pointer to graphics data (cache & non-cache)
; ebx = external pointer
; tile value : bit 15 = flipy, bit 14 = flipx, bit 10-12 = palette, 0-9=tile#

NEWSYM cachetile4b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,5
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,1
    and esi,4095
    test word[vidmemch4+esi],0101h
    jz near .nocache
    mov word[vidmemch4+esi],0000h
    mov edi,esi
    shl esi,4
    shl edi,5
    add esi,[vram]
    add edi,[vcache4b]
    push eax
    mov byte[.rowleft],8
.donext

    mov cx,[esi]
    mov dx,[esi+16]
    processcache4b 0
    processcache4b 1
    processcache4b 2
    processcache4b 3
    processcache4b 4
    processcache4b 5
    processcache4b 6
    processcache4b 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg     dw 0
.count   db 0
.rowleft db 0
.nextar  db 0

NEWSYM cache4bit
    ret
;*******************************************************
; Cache 8-Bit
;*******************************************************
; tile value : bit 15 = flipy, bit 14 = flipx, bit 10-12 = palette, 0-9=tile#
NEWSYM cachetile8b
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,6
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,2
    and esi,4095
    test dword[vidmemch8+esi],01010101h
    jz near .nocache
    mov dword[vidmemch8+esi],00000000h
    mov edi,esi
    shl esi,4
    shl edi,4
    add esi,[vram]
    add edi,[vcache8b]
    push eax
    mov byte[.rowleft],8
.donext
    xor ah,ah
    xor ebx,ebx
    xor ecx,ecx
    xor edx,edx
    mov byte[.a],0

    mov al,[esi]                ; bitplane 0
    cmp al,0
    je .skipconva
    test al,01h
    jz .skipa0
    or ah,01h
.skipa0
    test al,02h
    jz .skipa1
    or bl,01h
.skipa1
    test al,04h
    jz .skipa2
    or bh,01h
.skipa2
    test al,08h
    jz .skipa3
    or cl,01h
.skipa3
    test al,10h
    jz .skipa4
    or ch,01h
.skipa4
    test al,20h
    jz .skipa5
    or dl,01h
.skipa5
    test al,40h
    jz .skipa6
    or dh,01h
.skipa6
    test al,80h
    jz .skipa7
    or byte[.a],01h
.skipa7
.skipconva

    mov al,[esi+1]                ; bitplane 1
    cmp al,0
    je .skipconvb
    test al,01h
    jz .skipb0
    or ah,02h
.skipb0
    test al,02h
    jz .skipb1
    or bl,02h
.skipb1
    test al,04h
    jz .skipb2
    or bh,02h
.skipb2
    test al,08h
    jz .skipb3
    or cl,02h
.skipb3
    test al,10h
    jz .skipb4
    or ch,02h
.skipb4
    test al,20h
    jz .skipb5
    or dl,02h
.skipb5
    test al,40h
    jz .skipb6
    or dh,02h
.skipb6
    test al,80h
    jz .skipb7
    or byte[.a],02h
.skipb7
.skipconvb

    mov al,[esi+16]                ; bitplane 2
    cmp al,0
    je .skipconvc
    test al,01h
    jz .skipc0
    or ah,04h
.skipc0
    test al,02h
    jz .skipc1
    or bl,04h
.skipc1
    test al,04h
    jz .skipc2
    or bh,04h
.skipc2
    test al,08h
    jz .skipc3
    or cl,04h
.skipc3
    test al,10h
    jz .skipc4
    or ch,04h
.skipc4
    test al,20h
    jz .skipc5
    or dl,04h
.skipc5
    test al,40h
    jz .skipc6
    or dh,04h
.skipc6
    test al,80h
    jz .skipc7
    or byte[.a],04h
.skipc7
.skipconvc

    mov al,[esi+17]                ; bitplane 3
    cmp al,0
    je .skipconvd
    test al,01h
    jz .skipd0
    or ah,08h
.skipd0
    test al,02h
    jz .skipd1
    or bl,08h
.skipd1
    test al,04h
    jz .skipd2
    or bh,08h
.skipd2
    test al,08h
    jz .skipd3
    or cl,08h
.skipd3
    test al,10h
    jz .skipd4
    or ch,08h
.skipd4
    test al,20h
    jz .skipd5
    or dl,08h
.skipd5
    test al,40h
    jz .skipd6
    or dh,08h
.skipd6
    test al,80h
    jz .skipd7
    or byte[.a],08h
.skipd7
.skipconvd

    mov al,[esi+32]                ; bitplane 4
    cmp al,0
    je .skipconve
    test al,01h
    jz .skipe0
    or ah,10h
.skipe0
    test al,02h
    jz .skipe1
    or bl,10h
.skipe1
    test al,04h
    jz .skipe2
    or bh,10h
.skipe2
    test al,08h
    jz .skipe3
    or cl,10h
.skipe3
    test al,10h
    jz .skipe4
    or ch,10h
.skipe4
    test al,20h
    jz .skipe5
    or dl,10h
.skipe5
    test al,40h
    jz .skipe6
    or dh,10h
.skipe6
    test al,80h
    jz .skipe7
    or byte[.a],10h
.skipe7
.skipconve

    mov al,[esi+33]                ; bitplane 5
    cmp al,0
    je .skipconvf
    test al,01h
    jz .skipf0
    or ah,20h
.skipf0
    test al,02h
    jz .skipf1
    or bl,20h
.skipf1
    test al,04h
    jz .skipf2
    or bh,20h
.skipf2
    test al,08h
    jz .skipf3
    or cl,20h
.skipf3
    test al,10h
    jz .skipf4
    or ch,20h
.skipf4
    test al,20h
    jz .skipf5
    or dl,20h
.skipf5
    test al,40h
    jz .skipf6
    or dh,20h
.skipf6
    test al,80h
    jz .skipf7
    or byte[.a],20h
.skipf7
.skipconvf

    mov al,[esi+48]                ; bitplane 6
    cmp al,0
    je .skipconvg
    test al,01h
    jz .skipg0
    or ah,40h
.skipg0
    test al,02h
    jz .skipg1
    or bl,40h
.skipg1
    test al,04h
    jz .skipg2
    or bh,40h
.skipg2
    test al,08h
    jz .skipg3
    or cl,40h
.skipg3
    test al,10h
    jz .skipg4
    or ch,40h
.skipg4
    test al,20h
    jz .skipg5
    or dl,40h
.skipg5
    test al,40h
    jz .skipg6
    or dh,40h
.skipg6
    test al,80h
    jz .skipg7
    or byte[.a],40h
.skipg7
.skipconvg

    mov al,[esi+49]                ; bitplane 7
    cmp al,0
    je .skipconvh
    test al,01h
    jz .skiph0
    or ah,80h
.skiph0
    test al,02h
    jz .skiph1
    or bl,80h
.skiph1
    test al,04h
    jz .skiph2
    or bh,80h
.skiph2
    test al,08h
    jz .skiph3
    or cl,80h
.skiph3
    test al,10h
    jz .skiph4
    or ch,80h
.skiph4
    test al,20h
    jz .skiph5
    or dl,80h
.skiph5
    test al,40h
    jz .skiph6
    or dh,80h
.skiph6
    test al,80h
    jz .skiph7
    or byte[.a],80h
.skiph7
.skipconvh

    ; move all bytes into [edi]
    mov [edi+7],ah
    mov [edi+6],bl
    mov [edi+5],bh
    mov [edi+4],cl
    mov [edi+3],ch
    mov [edi+2],dl
    mov [edi+1],dh
    mov al,[.a]
    mov [edi],al
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
.nocache
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg     dw 0
.count   db 0
.a       db 0
.rowleft db 0
.nextar  db 0

NEWSYM cache8bit
    ret

;*******************************************************
; Cache 2-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile2b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,4
    mov byte[.count],32
    mov [.nbg],bx
    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test byte[vidmemch2+esi],01h
    jz near .nocache
    mov byte[vidmemch2+esi],00h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,6
    add esi,[vram]
    add edi,[vcache2b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    processcache2b 0
    processcache2b 1
    processcache2b 2
    processcache2b 3
    processcache2b 4
    processcache2b 5
    processcache2b 6
    processcache2b 7
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    inc esi
    cmp byte[.tileleft],3
    jne .noadd
    add esi,14
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg      dw 0
.count    db 0
.a        db 0
.rowleft  db 0
.nextar   db 0
.tileleft db 0

NEWSYM cache2bit16x16
    ret

;*******************************************************
; Cache 4-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile4b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,5
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,1
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test word[vidmemch4+esi],0101h
    jz near .nocache
    mov word[vidmemch4+esi],0000h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,5
    add esi,[vram]
    add edi,[vcache4b]
    push eax
    mov byte[.rowleft],8
.donext
    mov cx,[esi]
    mov dx,[esi+16]

    processcache4b 0
    processcache4b 1
    processcache4b 2
    processcache4b 3
    processcache4b 4
    processcache4b 5
    processcache4b 6
    processcache4b 7

    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    add esi,2
    cmp byte[.tileleft],3
    jne .noadd
    add esi,28
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg     dw 0
.count   db 0
.rowleft db 0
.nextar  db 0
.tileleft db 0

NEWSYM cache4bit16x16
    ret

;*******************************************************
; Cache 8-Bit 16x16 tiles
;*******************************************************

NEWSYM cachetile8b16x16
    ; Keep high word ecx 0
    push eax
    xor ecx,ecx
    push edx
    mov byte[.nextar],1
    push ebx
    ; get tile info location
    test al,20h
    jnz .highptr
    shl eax,6   ; x 64 for each line
    add ax,[bgptr]
    jmp .loptr
.highptr
    and al,1Fh
    shl eax,6   ; x 64 for each line
    add ax,[bgptrc]
.loptr
    add eax,[vram]
    mov bx,[curtileptr]
    shr bx,6
    mov byte[.count],32
    mov [.nbg],bx

    ; do loop
.cacheloop
    mov si,[eax]
    and esi,03FFh
    add si,[.nbg]
    shl esi,2
    mov byte[.tileleft],4
.nextof4
    and esi,4095
    test dword[vidmemch8+esi],01010101h
    jz near .nocache
    mov dword[vidmemch8+esi],00000000h
    push esi
    mov edi,esi
    shl esi,4
    shl edi,4
    add esi,[vram]
    add edi,[vcache8b]
    push eax
    mov byte[.rowleft],8
.donext
    xor ah,ah
    xor ebx,ebx
    xor ecx,ecx
    xor edx,edx
    mov byte[.a],0

    mov al,[esi]                ; bitplane 0
    cmp al,0
    je .skipconva
    test al,01h
    jz .skipa0
    or ah,01h
.skipa0
    test al,02h
    jz .skipa1
    or bl,01h
.skipa1
    test al,04h
    jz .skipa2
    or bh,01h
.skipa2
    test al,08h
    jz .skipa3
    or cl,01h
.skipa3
    test al,10h
    jz .skipa4
    or ch,01h
.skipa4
    test al,20h
    jz .skipa5
    or dl,01h
.skipa5
    test al,40h
    jz .skipa6
    or dh,01h
.skipa6
    test al,80h
    jz .skipa7
    or byte[.a],01h
.skipa7
.skipconva

    mov al,[esi+1]                ; bitplane 1
    cmp al,0
    je .skipconvb
    test al,01h
    jz .skipb0
    or ah,02h
.skipb0
    test al,02h
    jz .skipb1
    or bl,02h
.skipb1
    test al,04h
    jz .skipb2
    or bh,02h
.skipb2
    test al,08h
    jz .skipb3
    or cl,02h
.skipb3
    test al,10h
    jz .skipb4
    or ch,02h
.skipb4
    test al,20h
    jz .skipb5
    or dl,02h
.skipb5
    test al,40h
    jz .skipb6
    or dh,02h
.skipb6
    test al,80h
    jz .skipb7
    or byte[.a],02h
.skipb7
.skipconvb

    mov al,[esi+16]                ; bitplane 2
    cmp al,0
    je .skipconvc
    test al,01h
    jz .skipc0
    or ah,04h
.skipc0
    test al,02h
    jz .skipc1
    or bl,04h
.skipc1
    test al,04h
    jz .skipc2
    or bh,04h
.skipc2
    test al,08h
    jz .skipc3
    or cl,04h
.skipc3
    test al,10h
    jz .skipc4
    or ch,04h
.skipc4
    test al,20h
    jz .skipc5
    or dl,04h
.skipc5
    test al,40h
    jz .skipc6
    or dh,04h
.skipc6
    test al,80h
    jz .skipc7
    or byte[.a],04h
.skipc7
.skipconvc

    mov al,[esi+17]                ; bitplane 3
    cmp al,0
    je .skipconvd
    test al,01h
    jz .skipd0
    or ah,08h
.skipd0
    test al,02h
    jz .skipd1
    or bl,08h
.skipd1
    test al,04h
    jz .skipd2
    or bh,08h
.skipd2
    test al,08h
    jz .skipd3
    or cl,08h
.skipd3
    test al,10h
    jz .skipd4
    or ch,08h
.skipd4
    test al,20h
    jz .skipd5
    or dl,08h
.skipd5
    test al,40h
    jz .skipd6
    or dh,08h
.skipd6
    test al,80h
    jz .skipd7
    or byte[.a],08h
.skipd7
.skipconvd

    mov al,[esi+32]                ; bitplane 4
    cmp al,0
    je .skipconve
    test al,01h
    jz .skipe0
    or ah,10h
.skipe0
    test al,02h
    jz .skipe1
    or bl,10h
.skipe1
    test al,04h
    jz .skipe2
    or bh,10h
.skipe2
    test al,08h
    jz .skipe3
    or cl,10h
.skipe3
    test al,10h
    jz .skipe4
    or ch,10h
.skipe4
    test al,20h
    jz .skipe5
    or dl,10h
.skipe5
    test al,40h
    jz .skipe6
    or dh,10h
.skipe6
    test al,80h
    jz .skipe7
    or byte[.a],10h
.skipe7
.skipconve

    mov al,[esi+33]                ; bitplane 5
    cmp al,0
    je .skipconvf
    test al,01h
    jz .skipf0
    or ah,20h
.skipf0
    test al,02h
    jz .skipf1
    or bl,20h
.skipf1
    test al,04h
    jz .skipf2
    or bh,20h
.skipf2
    test al,08h
    jz .skipf3
    or cl,20h
.skipf3
    test al,10h
    jz .skipf4
    or ch,20h
.skipf4
    test al,20h
    jz .skipf5
    or dl,20h
.skipf5
    test al,40h
    jz .skipf6
    or dh,20h
.skipf6
    test al,80h
    jz .skipf7
    or byte[.a],20h
.skipf7
.skipconvf

    mov al,[esi+48]                ; bitplane 6
    cmp al,0
    je .skipconvg
    test al,01h
    jz .skipg0
    or ah,40h
.skipg0
    test al,02h
    jz .skipg1
    or bl,40h
.skipg1
    test al,04h
    jz .skipg2
    or bh,40h
.skipg2
    test al,08h
    jz .skipg3
    or cl,40h
.skipg3
    test al,10h
    jz .skipg4
    or ch,40h
.skipg4
    test al,20h
    jz .skipg5
    or dl,40h
.skipg5
    test al,40h
    jz .skipg6
    or dh,40h
.skipg6
    test al,80h
    jz .skipg7
    or byte[.a],40h
.skipg7
.skipconvg

    mov al,[esi+49]                ; bitplane 7
    cmp al,0
    je .skipconvh
    test al,01h
    jz .skiph0
    or ah,80h
.skiph0
    test al,02h
    jz .skiph1
    or bl,80h
.skiph1
    test al,04h
    jz .skiph2
    or bh,80h
.skiph2
    test al,08h
    jz .skiph3
    or cl,80h
.skiph3
    test al,10h
    jz .skiph4
    or ch,80h
.skiph4
    test al,20h
    jz .skiph5
    or dl,80h
.skiph5
    test al,40h
    jz .skiph6
    or dh,80h
.skiph6
    test al,80h
    jz .skiph7
    or byte[.a],80h
.skiph7
.skipconvh

    ; move all bytes into [edi]
    mov [edi+7],ah
    mov [edi+6],bl
    mov [edi+5],bh
    mov [edi+4],cl
    mov [edi+3],ch
    mov [edi+2],dl
    mov [edi+1],dh
    mov al,[.a]
    mov [edi],al
    add edi,8
    add esi,2
    dec byte[.rowleft]
    jnz near .donext
    pop eax
    pop esi
.nocache
    add esi,4
    cmp byte[.tileleft],3
    jne .noadd
    add esi,56
.noadd
    dec byte[.tileleft]
    jnz near .nextof4
    add eax,2
    dec byte[.count]
    jnz near .cacheloop

    cmp byte[.nextar],0
    je .skipall
    mov bx,[bgptrc]
    cmp [bgptrd],bx
    je .skipall
    add eax,2048-64
    mov byte[.count],32
    mov byte[.nextar],0
    jmp .cacheloop
.skipall
    pop ebx
    pop edx
    pop eax
    ret

.nbg      dw 0
.count    db 0
.a        db 0
.rowleft  db 0
.nextar   db 0
.tileleft db 0

NEWSYM cache8bit16x16
    ret

NEWSYM cachesingle
    cmp byte[offsetmshl],1
    je near cachesingle4b
    cmp byte[offsetmshl],2
    je near cachesingle2b
    ret

%macro processcache4b2 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add ch,ch
    adc al,al
    add cl,cl
    adc al,al
    mov [edi+%1],al
%endmacro

NEWSYM cachesingle4b
    mov word[ebx],0
    sub ebx,vidmemch4
    push edi
    mov edi,ebx
    shl edi,5           ; cached ram
    shl ebx,4           ; vram
    add edi,[vcache4b]
    add ebx,[vram]
    push eax
    push edx
    mov byte[scacheloop],8
.nextline
    mov cx,[ebx]
    mov dx,[ebx+16]
    processcache4b2 0
    processcache4b2 1
    processcache4b2 2
    processcache4b2 3
    processcache4b2 4
    processcache4b2 5
    processcache4b2 6
    processcache4b2 7
    add ebx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop eax
    pop edi
    ret

NEWSYM cachesingle2b
    ret

NEWSYM scacheloop, db 0
NEWSYM tiletypec, db 0

%macro processcache4b3 1
    xor al,al
    add dh,dh
    adc al,al
    add dl,dl
    adc al,al
    add bh,bh
    adc al,al
    add bl,bl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesingle4bng
    mov word[vidmemch4+ecx*2],0
    mov byte[tiletypec],3
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,5           ; vram
    add edi,[vcache4b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    mov dx,[ecx+16]
    processcache4b3 0
    processcache4b3 1
    processcache4b3 2
    processcache4b3 3
    processcache4b3 4
    processcache4b3 5
    processcache4b3 6
    processcache4b3 7
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype4b+ecx],al
    pop eax
    pop edi
    ret

%macro processcache2b3 1
    xor al,al
    add bh,bh
    adc al,al
    add bl,bl
    adc al,al
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
%endmacro

NEWSYM cachesingle2bng
    mov byte[vidmemch2+ecx],0
    mov byte[tiletypec],3
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,4           ; vram
    add edi,[vcache2b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    processcache2b3 0
    processcache2b3 1
    processcache2b3 2
    processcache2b3 3
    processcache2b3 4
    processcache2b3 5
    processcache2b3 6
    processcache2b3 7
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype2b+ecx],al
    pop eax
    pop edi
    ret

%macro processcache8b3 1
    xor esi,esi
    add ch,ch
    adc esi,esi
    add cl,cl
    adc esi,esi
    add dh,dh
    adc esi,esi
    add dl,dl
    adc esi,esi
    add ah,ah
    adc esi,esi
    add al,al
    adc esi,esi
    add bh,bh
    adc esi,esi
    add bl,bl
    adc esi,esi
    push eax
    mov eax,esi
    mov [edi+%1],al
    or al,al
    jz %%zeroed
    and byte[tiletypec],1
    jmp %%nozeroed
%%zeroed
    and byte[tiletypec],2
%%nozeroed
    pop eax
%endmacro

NEWSYM cachesingle8bng
    mov dword[vidmemch8+ecx*4],0
    mov byte[tiletypec],3
    push esi
    push edi
    push eax
    push ecx
    push ebx
    push edx
    mov edi,ecx
    shl edi,6           ; cached ram
    shl ecx,6           ; vram
    add edi,[vcache8b]
    add ecx,[vram]
    mov byte[scacheloop],8
.nextline
    mov bx,[ecx]
    mov ax,[ecx+16]
    mov dx,[ecx+32]
    push ecx
    mov cx,[ecx+48]
    processcache8b3 0
    processcache8b3 1
    processcache8b3 2
    processcache8b3 3
    processcache8b3 4
    processcache8b3 5
    processcache8b3 6
    processcache8b3 7
    pop ecx
    add ecx,2
    add edi,8
    dec byte[scacheloop]
    jnz near .nextline
    pop edx
    pop ebx
    pop ecx
    mov al,[tiletypec]
    mov [tltype8b+ecx],al
    pop eax
    pop edi
    pop esi
    ret
NEWSYM VCacheAsmEnd
