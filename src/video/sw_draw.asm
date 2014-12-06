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

; This file compiles to zero if not OpenBSD, thus it can be
; left in the Makefile.
%include "macros.mac"

ALIGN 32

EXTSYM SurfaceX,SurfaceY
EXTSYM ScreenPtr,SurfBufD
EXTSYM pitch, MMXSupport

SECTION .text

NEWSYM ClearWin16
        pushad
        mov  edi, [SurfBufD]
        xor  eax,eax
        xor  ebx,ebx
.Blank2: 
        mov  ecx, [SurfaceX]
        rep stosw
        mov  edx, [SurfaceX]
        add  edi, [pitch]
        shl  edx,1
        add  ebx,1
        sub  edi,edx
        cmp  ebx, [SurfaceY]
        jne .Blank2
        popad
        ret

NEWSYM DrawWin256x224x16
        pushad
        mov  esi, [ScreenPtr]
        mov  edi, [SurfBufD]
        xor  eax,eax
.Copying3: 
        mov  ecx,32
.CopyLoop: 
        movq mm0,[esi]
        movq mm1,[esi+8]
        movq [edi],mm0
        movq [edi+8],mm1
        add  esi,16
        add  edi,16
        dec  ecx
        jnz .CopyLoop
        inc  eax
        add  edi, [pitch]
        sub  edi,512
        add  esi,64
        cmp  eax,223
        jne .Copying3
        xor  eax,eax
        mov  ecx,128
        rep stosd
        emms
        popad
        ret

NEWSYM DrawWin320x240x16
        pushad
        xor  eax,eax
        xor  ebx,ebx
        mov  esi, [ScreenPtr]
        mov  edi, [SurfBufD]
.Blank1MMX: 
        mov  ecx,160
        rep stosd
        sub  edi,160
        add  edi, [pitch]
        add  ebx,1
        cmp  ebx,8
        jne .Blank1MMX
        xor  ebx,ebx
        pxor mm0,mm0
.Copying2MMX: 
        mov  ecx,4
.MMXLoopA: 
        movq [edi+0],mm0
        movq [edi+8],mm0
        add  edi,16
        dec  ecx
        jnz .MMXLoopA
        mov  ecx,32
.MMXLoopB: 
        movq mm1,[esi+0]
        movq mm2,[esi+8]
        movq [edi+0],mm1
        movq [edi+8],mm2
        add  esi,16
        add  edi,16
        dec  ecx
        jnz .MMXLoopB
        mov  ecx,4
.MMXLoopC: 
        movq [edi+0],mm0
        movq [edi+8],mm0
        add  edi,16
        dec  ecx
        jnz .MMXLoopC
        inc  ebx
        add  edi, [pitch]
        sub  edi,640
        add  esi,64
        cmp  ebx,223
        jne .Copying2MMX
        mov  ecx,128
        rep stosd
        emms
        popad
        ret
