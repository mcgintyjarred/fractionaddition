; asmsyntax=nasm

global addf
; *****************************************
; * void addf(float a, float b, float *x) *
; *****************************************

%define a [ebp+8]
%define b [ebp+12]
%define x [ebp+16]

%define r1 [ebp-4]
%define s1 [ebp-8]
%define e1 [ebp-12]
%define f1 [ebp-16]

%define r2 [ebp-20]
%define s2 [ebp-24]
%define e2 [ebp-28]
%define f2 [ebp-32]

%define r3 [ebp-34]
%define s3 [ebp-38]
%define e3 [ebp-42]
%define f3 [ebp-46]

addf:
  push ebp
  mov ebp, esp
  sub esp, f3

;**************************************************************
; Saving of the float
;**************************************************************

  mov ebx, a
  mov edx, b
  
  mov r1, ebx		; contains original value of float a
  mov r2, edx		; contains original value of float b

  shr ebx, 31
  shr edx, 31

  ; 1 if negative 
  ; 0 if positive
  mov s1, ebx
  mov s2, edx

  mov ebx, a
  mov edx, b

  ; bit mask to get e1 and e2
  and ebx, 01111111100000000000000000000000b
  and edx, 01111111100000000000000000000000b

  ; shift to the right of the register
  ; can now view the exponents as ints 

  shr ebx, 23		; ebx = e1
  shr edx, 23		; edx = e2

  sub ebx, 127
  sub edx, 127

  mov e1, ebx
  mov e2, edx

  mov ecx, a					; ecx = f1
  shl ecx, 9
  shr ecx, 9
  ;and ecx, 00000000011111111111111111111111b	; mask so you can only see the fraction

  mov eax, b					; eax = f2
  shl eax, 9
  shr eax, 9
  ;and eax, 00000000011111111111111111111111b	; mask so you can only see the fraction


  ; add leading one to the fractions 
  or ecx, 00000000100000000000000000000000b
  or eax, 00000000100000000000000000000000b

  mov f1, ecx
  mov f2, eax

;**************************************************************
; Check for cancelling  
;**************************************************************

  mov ebx, s1
  mov ecx, s2
  
  cmp ebx, ecx
  je .zero

  mov ebx, e1
  mov ecx, e2
  
  cmp ebx, ecx
  jne .zero

  mov ebx, f1
  mov ecx, f2
  
  cmp ebx, ecx
  jne .zero
  mov ebx, 00000000000000000000000000000000b
  jmp .done

.zero:
  mov ebx, a
  mov ecx, b
  add ebx, ecx
  jnz .start_compare
  mov ebx, 00000000000000000000000000000000b
  jmp .done

.start_compare:
; first while loop
;**************************************************************
; while e1 < e2
;**************************************************************

  mov ebx, e1
  mov edx, e2
  mov ecx, f1

.while_1:

  cmp ebx, edx
  jge .end_1

  inc ebx		; e1 = e1 + 1
  shr ecx, 1		; f1 = f1 / 2 with no remainder

  jmp .while_1
.end_1:

  mov e1, ebx		; update e1
  mov f1, ecx		; update f1



  ; ebx = e1
  ; edx = e2
  ; ecx = f1
  ; eax = f2

; second while loop
;**************************************************************
; while e2 < e1
;**************************************************************

  mov edx, e2
  mov ebx, e1
  mov eax, f2

.while_2:
  cmp edx, ebx
  jge .end_2

  inc edx		; e2 = e2 + 1
  shr eax, 1 		; f2 = f2 / 2 with no remainder 

  jmp .while_2
.end_2:

  mov e2, edx		; update e2
  mov f2, eax		; update d2

;**************************************************************
; Save e3 = e2 = e1
;**************************************************************
  ; ebx and edx are now common == e3
  ; keep ebx as common e3
  mov edx, e2
  mov e3, edx

;**************************************************************
; if r1 < 0 - neg f1
;**************************************************************
  ;mov esi, a		; esi == r1
  ;shr edx, 31

  mov edx, r1
  cmp edx, 0

  jge .if_1		; r1 < 0, otherwise skip
  mov ecx, f1
  neg ecx		; two's comp. of f1
  mov f1, ecx

;**************************************************************
; if r2 < 0 - neg f2
;**************************************************************
.if_1:
  
  ;mov edi, b		; edi == r2
  ;shr edi, 31
  ;shr edx, 31
  mov edx, r2
  cmp edx, 0

  jge .if_2		; r2 < 0; otherwise skip
  mov eax, f2
  neg eax		; two's comp. of f2
  mov f2, eax

.if_2:

;**************************************************************
; set f3 = f1 + f2
;**************************************************************
  ; ecx = f3 == f1 +f2
  mov ecx, f1
  mov eax, f2
  add ecx, eax		; create common f3
 ;and ecx, 00000000011111111111111111111111b
  mov f3, ecx

;**************************************************************
; if f3 < 0 - neg f3
;**************************************************************
  ;shr ecx, 31
  mov ecx, f3
  cmp ecx, 0		; f3 < 0, otherwise jump
  jge .else

  mov ecx, f3
  neg ecx 		; two's comp. of f3
  mov f3, ecx
  
; Setting the sign bit to negative
  mov edx, 10000000000000000000000000000000b
  mov s3, edx
  jmp .end_if_3
.else:


  mov edx, 00000000000000000000000000000000b 
  mov s3, edx
.end_if_3:

  ; esi - is where fraction starts at pos 10
  ;mov esi, 00000000010000000000000000000000b

  ; s3 = edx - sign bit
  ; e3 = ebx - exponent
  ; f3 = ecx
;  dec ebx
  ;jmp .end_norm

  ;mov edx, 00000000000000000000001000000000b


;**************************************************************
; Normalizing
;**************************************************************
  mov eax, f3
  mov ebx, e3
;  shl ebx, 23

  cmp eax, 0
  je .end_norm

  mov edx, 11111111100000000000000000000000b
.norm_while_1:
  mov eax, f3
  and eax, edx
  cmp eax, 00000000011111111111111111111111b
  jng .end_norm_1

  mov eax, f3
  shr eax, 1
  inc ebx

  mov f3, eax
  mov e3, ebx 
  jmp .norm_while_1
.end_norm_1:

  mov edx, 00000000100000000000000000000000b
.norm_while_2:
  mov eax, f3
  and eax, edx

  cmp eax, edx
  je .end_norm_2

  mov eax, f3
  shl eax, 1
  mov f3, eax

  mov ebx, e3
  dec ebx
  mov e3, ebx 

  jmp .norm_while_2
.end_norm_2:
  ;cmp eax, edx
  ;jge .end_norm


  ;mov f3, eax
  ;jmp .normalize
.end_norm:
 

;**************************************************************
; Combine s3, e3, f3
;**************************************************************
  mov edx, s3
  mov ebx, e3
  add ebx, 127
  shl ebx, 23		; move to the left 23 bits, in place
  mov ecx, f3
  shl ecx, 9
  shr ecx, 9

  xor ebx, ecx		; add in f3
  xor ebx, edx		; add in sign

  ; r3 == ebx

.done:
  mov eax, x
  mov dword [eax], ebx

  mov esp, ebp
  pop ebp
  ret
