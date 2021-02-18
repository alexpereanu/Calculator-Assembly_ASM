.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "PROIECT FERI",0
area_width EQU 640
area_height EQU 480
area DD 0
matrix	db '1','2','3',2
		db '4','5','6',3
		db '7','8','9',4
		db 0, '0', 1, 'C'
		
x0 dd 100 ;coordonata initiala x a chenarului
x1 dd 500 ;coordonata finala x a chenarului
y0 dd 130 ;coordonata initiala y a chenarului
y1 dd 430 ;coordonata finala y a chenarului
verifica dd 0
cifra dd 0
rezultat dd 0
termen dd ?
deplasare dd 125
validare dd 0
operator dd ?

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

constanta EQU 10 ; ca sa ne ajute la inmultirea cu 10 pentru numere mari 
symbol_width EQU 10
symbol_height EQU 20

alex_height EQU 20
alex_width EQU 10
include digits.inc
include letters.inc
include alex.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
make_letters:
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit: 
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text

	


make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

draw_linie_orizontala_macro macro drawArea, x, y, lungime
LOCAL vf, final
	push eax
	push ecx
	push ebx
	
	mov eax, 0
	mov eax, x
	mov ebx, 640
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
vf:
	mov ebx, drawArea
	add ebx, ecx
	mov dword ptr [ebx+eax], 000000h
	inc ecx
	inc ecx
	cmp ecx, lungime
	je final
	loop vf
final:
	pop ebx
	pop ecx
	pop eax
endm

draw_linie_verticala_macro macro drawArea, x, y, lungime
LOCAL vf, final
	push eax
	push ecx
	push ebx
	
	mov eax, 0
	mov eax, x
	mov ebx, 640
	mul ebx
	add eax, y
	shl eax, 2
	mov ecx, 0
vf:
	add eax, 2559
	mov EBX, drawArea
	add ebx, ecx
	mov dword ptr [ebx+eax], 000000h
	inc ecx
	inc ecx
	cmp ecx, lungime
	je final
	loop vf
final:
	pop ebx
	pop ecx
	pop eax
endm


; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

desenare_simbol proc 
;procedura pentru desenarea simbolurilor din biblioteca alex.inc
push ebp
mov ebp,esp
pusha
deseneaza_plus:
;desenam operatorul plus
mov eax, [ebp+arg1]
cmp eax, 0
jg deseneaza_minus
;sub eax,0
lea esi,alex
jmp desenare

deseneaza_minus:
;desenam operatorul minus
;mov eax,[ebp+arg1]
cmp eax,1
jg deseneaza_ori
sub eax,0
lea esi,alex
jmp desenare

deseneaza_ori:
;desenam operatorul de inmultire
;mov eax,[ebp+arg1]
cmp eax,2
jg deseneaza_impartire
sub eax,0
lea esi,alex
jmp desenare

deseneaza_impartire:
;mov eax,[ebp+arg1]
cmp eax,3
jg deseneaza_egal
sub eax,0
lea esi, alex
jmp desenare

deseneaza_egal:
mov eax,4 ; al 4-lea simbol de afisat din fisier
lea esi,alex

desenare:
	mov ebx, alex_width
	mul ebx
	mov ebx, alex_height
	mul ebx
	add esi, eax
	mov ecx, alex_height
bucla_simbol_linii_alex:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, alex_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, alex_width
bucla_simbol_coloane_alex:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb_alex
	mov dword ptr [edi], 0
	jmp simbol_pixel_next_alex
simbol_pixel_alb_alex:
	mov dword ptr [edi], 0FFFFFFh ;fundal patratel cu simbol 
simbol_pixel_next_alex:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane_alex
	pop ecx
	loop bucla_simbol_linii_alex
	popa
	mov esp, ebp
	pop ebp
	ret
desenare_simbol endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro_simbol macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call desenare_simbol
	add esp, 16
endm

orizontala macro x, y, len
local bucla
	pusha
	mov ecx, len ;lungimea
	mov esi, y
	mov edi, x
	mov ebx, area ; este deja adresa
	
	bucla:
	mov eax, area_width
	mul esi
	add eax,edi
	mov dword ptr [ebx+eax*4], 0h
	inc edi
	loop bucla
	popa
endm


in_chenar proc ;verificam daca s-a dat click in chenarul tabelului
push ebp
mov ebx,[ebp+arg2] ; x'ul click-ului
mov edx,[ebp+arg3] ;y'ul click-ului
push edx
push ebx
cmp ebx,x0
jl fals
cmp ebx,x1
jg fals
cmp edx,y0
jl fals
cmp edx,y1
jg fals
mov eax,1
mov verifica,eax
jmp iesi

fals:
mov eax,0
mov verifica,eax

iesi:
pop ebp
ret
in_chenar endp

aflare_cifra proc 
push ebp

;push ecx
;mov ebx,[ebp+arg2]
;mov edx,[ebp+arg3]
;push edx
;push ebx
;call in_chenar ; ne returneaza in verifica 1 daca click-ul e in chenar,respectiv 0 in caz contrar
;add esp,8
;cmp eax,1
;jne wrong

verificare_cifra_1:  ;1 apartine[100-190, 187-267]
cmp ebx,100 	;comparam x'ul click-ului cu x-ul chenarului cu cifra 1
jl wrong 	; daca e mai mic ca 100, e in afara chenarului
cmp ebx,190 ; daca e mai mic ca 190, verific daca e cifra 1
jg verificare_cifra_2
cmp edx,267 ;y-ul chenarului cu cifra 1
jg verificare_cifra_4
cmp edx,187
jl wrong 
mov eax,1
mov cifra,eax
jmp iesire


verificare_cifra_2: ; cifra 2 apartine[190-300, 187-267]
cmp ebx,190
jl verificare_cifra_1
cmp ebx, 320
jg verificare_cifra_3
cmp edx,267
jg verificare_cifra_5
cmp edx,187
jl wrong
mov eax,2
mov cifra,eax
jmp iesire

verificare_cifra_3: ;cifra 3 apartine[300-425, 187-267]
cmp ebx,320
jl verificare_cifra_2
cmp ebx,425
jg verificare_caracter_inmultire
cmp edx,187
jl wrong
cmp edx,267
jg verificare_cifra_6
mov eax,3
mov cifra,eax
jmp iesire

verificare_cifra_4: ;cifra 4 apartine[100-190,265-320]
cmp ebx,100
jl wrong
cmp ebx,190
jg verificare_cifra_5
cmp edx,265
jl verificare_cifra_1
cmp edx,320
jg verificare_cifra_7
mov eax,4
mov cifra,4
jmp iesire


verificare_cifra_5: ;cifra 5 apartine[190-320, 265-320]
cmp ebx,190
jl verificare_cifra_4
cmp ebx,320
jg verificare_cifra_6
cmp edx,265
jl verificare_cifra_2
cmp edx,320
jg verificare_cifra_8
mov eax,5
mov cifra,5
jmp iesire

verificare_cifra_6: ; cifra 6 apartine[320-425,265-320]
cmp ebx,320
jl verificare_cifra_5
cmp ebx,425
jg verificare_caracter_impartire
cmp edx,265
jl verificare_cifra_3
cmp edx,320
jg verificare_cifra_9
mov eax,6
mov cifra,eax
jmp iesire

verificare_cifra_7:; cifra 7 apartine[100-190, 320-375]
cmp ebx,190
jg verificare_cifra_8
cmp edx,320
jl verificare_cifra_4
cmp edx,375
jg verificare_caracter_adunare
mov eax,7
mov cifra,eax
jmp iesire

verificare_cifra_8:; cifra 8 apartine[190-320, 320-375]
cmp ebx,190
jl verificare_cifra_7
cmp ebx,320
jg verificare_cifra_9
cmp edx,320
jl verificare_cifra_5
cmp edx,375
jg verificare_cifra_0
mov eax,8
mov cifra,eax
jmp iesire


verificare_cifra_9: ;cifra 9 apartine[320-425, 320-375]
cmp ebx,320
jl verificare_cifra_8
cmp ebx,425
jg verificare_caracter_egal
cmp edx,320
jl verificare_cifra_6
cmp edx,375
jg verificare_caracter_scadere
mov eax,9
mov cifra,9
jmp iesire

verificare_caracter_adunare: ;+ apartine [100-190, 375-430] 10
cmp ebx,100
jl wrong
cmp ebx,190
jg verificare_cifra_0
cmp edx,375
jl verificare_cifra_7
cmp edx,430
jg wrong
mov eax,10
mov cifra,eax
jmp iesire

verificare_caracter_scadere: ;- apartine [320-425, 375-430] 11
cmp ebx,320
jl verificare_cifra_0
cmp ebx,425
jg verificare_caracter_c
cmp edx,375
jl verificare_cifra_9
cmp edx,430
jg wrong
mov eax,11
mov cifra,eax
jmp iesire

verificare_caracter_egal: ;  = apartine [425-500, 320-375] 12 
cmp ebx, 425
jl verificare_cifra_9
cmp ebx, 500
jg wrong
cmp edx, 320
jl verificare_caracter_impartire
cmp edx,375
jg verificare_caracter_c
mov eax,12
mov cifra,eax
jmp iesire

verificare_caracter_impartire: ; / apartine [425-500, 265-320] 13 
cmp ebx,425
jl verificare_cifra_6
cmp ebx,500
jg wrong
cmp edx,265
jl verificare_caracter_inmultire
cmp edx,320
jg verificare_caracter_egal
mov eax,13
mov cifra,eax
jmp iesire

verificare_caracter_c: ; c apartine [425-500, 375-430] 14 
cmp ebx,425
jl verificare_caracter_scadere
cmp ebx,500
jg wrong
cmp edx,375
jl verificare_caracter_egal
cmp edx,430
jg wrong
mov eax,14
mov cifra,eax
jmp iesire


verificare_caracter_inmultire: ;* apartine [425-500, 190-265] 15
cmp ebx,425
jl verificare_cifra_3
cmp ebx,500
jg wrong
cmp edx,190
jl wrong
cmp edx,265
jg verificare_caracter_impartire
mov eax,15
mov cifra,eax
jmp iesire

verificare_cifra_0:
cmp ebx,190
jl verificare_caracter_adunare
cmp ebx, 320
jg verificare_caracter_scadere
cmp edx,375
jl verificare_cifra_8
cmp edx, 430
jg wrong
mov eax,0
mov cifra,0
jmp iesire
 

wrong:



iesire:
pop ebp
ret
aflare_cifra endp
;0-9 cifre, 10 + , 11 - , 12 =, 13 /, 14 c, 15 *

calculare proc
push ebp
mov ebx,[ebp+arg2]		;verificare daca click-ul s-a dat pe tabla
mov edx,[ebp+arg3]
push edx
push ebx
call aflare_cifra
add esp,8

;push edi


cmp eax,0
je sari_afisare_0
cmp eax, 1
je sari_afisare_1
cmp eax, 2 
je sari_afisare_2
cmp eax, 3
je sari_afisare_3
cmp eax, 4 
je sari_afisare_4
cmp eax, 5
je sari_afisare_5
cmp eax, 6
je sari_afisare_6
cmp eax, 7
je sari_afisare_7
cmp eax, 8
je sari_afisare_8
cmp eax, 9
je sari_afisare_9
cmp eax, 10
je sari_afisare_10
cmp eax, 11
je sari_afisare_11
cmp eax,12
je sari_afisare_12
cmp eax,13
je sari_afisare_13
cmp eax,14
je sari_afisare_14
cmp eax,15
je sari_afisare_15

sari_afisare_14:
mov eax,14
mov termen, eax
jmp iesi

sari_afisare_15:
make_text_macro_simbol 2,area,deplasare,155 ;inmultire
mov termen,15
jmp iesi

sari_afisare_13:
make_text_macro_simbol 3,area,deplasare,155 ;impartire
mov termen,13
jmp iesi

sari_afisare_12:
make_text_macro_simbol 4,area,deplasare,155 ;egal
mov termen,12
;add edi,10
jmp iesi

sari_afisare_11:
make_text_macro_simbol 1,area,deplasare,155; minus
mov termen,11
;add edi,10
jmp iesi

sari_afisare_10:
make_text_macro_simbol 0,area,deplasare,155 ;plus
mov termen,10
jmp iesi

sari_afisare_9:
make_text_macro '9', area, deplasare, 155
mov termen,9
;add edi,10
jmp iesi

sari_afisare_8:
make_text_macro '8',area,deplasare,155
mov termen,8
;add edi,10
jmp iesi

sari_afisare_7:
make_text_macro '7',area,deplasare,155
mov termen,7
;add edi,10
jmp iesi

sari_afisare_6:
make_text_macro '6',area,deplasare,155
mov termen,6
;add edi,10
jmp iesi

sari_afisare_5:
make_text_macro '5',area,deplasare,155
mov termen,5
;add edi,10
jmp iesi

sari_afisare_4:
make_text_macro '4',area,deplasare,155
mov termen,4
;add edi,10
jmp iesi

sari_afisare_3:
make_text_macro '3',area,deplasare,155
mov termen,3
;add edi,10
jmp iesi

sari_afisare_2:
make_text_macro '2',area,deplasare,155
mov termen,2
;add edi, 10
jmp iesi

sari_afisare_1:
make_text_macro '1',area,deplasare,155
mov termen,1 
;add edi,10
jmp iesi

sari_afisare_0:
make_text_macro '0',area,deplasare,155
mov termen,0

iesi:
mov eax,termen
;pop edi
pop ebp
ret
calculare endp





; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - click in afara chenarului calculatorului, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y

	
	draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
clear:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12

make_text_macro '1',area, 145,226
make_text_macro '2',area, 270,226
make_text_macro '3',area, 384,226
make_text_macro '4',area, 145,280
make_text_macro '5',area, 270,280
make_text_macro '6',area, 384,280
make_text_macro '7',area, 145,334
make_text_macro_simbol 0,area,145,388
make_text_macro '8',area, 270,334
make_text_macro '9',area, 384,334
make_text_macro_simbol 1,area,384,388
make_text_macro '0',area, 270,394
make_text_macro_simbol 2,area,460,226
make_text_macro_simbol 3,area,460, 280
make_text_macro_simbol 4,area,460, 330
make_text_macro 'C',area, 460,392
	
	
	
draw_linie_orizontala_macro area,130,100,1600
draw_linie_verticala_macro area, 130,100,300
draw_linie_orizontala_macro area,430,100,1600
draw_linie_verticala_macro area, 130,500,300
draw_linie_verticala_macro area,186,425,245
draw_linie_orizontala_macro area,187,100,1600
draw_linie_orizontala_macro area,265,100,1600
draw_linie_orizontala_macro area,319,100,1600
draw_linie_orizontala_macro area,374,100,1600
draw_linie_verticala_macro area,186,190,245
draw_linie_verticala_macro area,187,320,245
	
mov deplasare,125
mov rezultat,0
mov validare,0
jmp iesire

	
evt_click:
mov ebx,[ebp+arg2]
mov edx,[ebp+arg3]	
push edx
push ebx
add esp,8
call calculare
add esp,4

cmp eax,14 ; verificam daca s-a dat click pe caracterul C
je clear
 
	cmp eax,9
	jg sari_operator	;in aceasta secventa verificam pe ce cifra am dat click. daca e 0-9 atunci sarim la iesi si nu luam in seama faptul ca este operator 
	mov termen, eax
	mov ecx,termen
	cmp validare,1 
	je fa_rezultat 
 
	add deplasare,10 ;deplasam coordonata x-ului urmatoarei cifre cu 10, ca sa apara frumos pe ecran, una langa cealalta
	jmp iesire
	
sari_operator:
;0-9 cifre, 10 + , 11 - , 12 =, 13 /, 14 c, 15 *
;verificare care operator este 
mov operator, eax
mov rezultat, ecx 
mov validare, 1 
add deplasare,10 
jmp iesire


fa_rezultat:
cmp operator,10
je aduna
cmp operator,11
je scade 

aduna:
mov ecx,termen
add rezultat, ecx
add deplasare,10
jmp afisare_rezultat

scade:
mov ecx,termen
sub rezultat,ecx
add deplasare,10
jmp afisare_rezultat

afisare_rezultat:
cmp rezultat,2
je afiseaza_2
cmp rezultat,3
je afiseaza_3
cmp rezultat,4
je afiseaza_4
cmp rezultat,5
je afiseaza_5
cmp rezultat,6
je afiseaza_6
cmp rezultat,7
je afiseaza_7
cmp rezultat,8
je afiseaza_8
cmp rezultat,9
je afiseaza_9
jmp iesire

afiseaza_2:
make_text_macro_simbol 4,area,deplasare,155
add deplasare,10
make_text_macro '2',area,deplasare,155
jmp iesire

afiseaza_3:
make_text_macro '3',area,deplasare,155
jmp iesire

afiseaza_4:
make_text_macro '4',area,deplasare,155
jmp iesire

afiseaza_5:
make_text_macro '5',area,deplasare,155
jmp iesire

afiseaza_6:
make_text_macro '6',area,deplasare,155
jmp iesire

afiseaza_7:
make_text_macro '7',area,deplasare,155
jmp iesire

afiseaza_8:
make_text_macro '8',area,deplasare,155
jmp iesire

afiseaza_9:
make_text_macro '9',area,deplasare,155
jmp iesire



evt_timer:
make_text_macro 'A',area,220,100
make_text_macro 'S',area,230,100
make_text_macro 'T',area,240,100
make_text_macro 'E',area,250,100
make_text_macro 'P',area,260,100
make_text_macro 'T',area,270,100

make_text_macro 'C',area,290,100
make_text_macro 'L',area,300,100
make_text_macro 'I',area,310,100
make_text_macro 'C',area,320,100
make_text_macro 'K',area,330,100


	
	;scriem un mesaj
	make_text_macro 'W', area, 250, 20
	make_text_macro 'I', area, 260, 20
	make_text_macro 'N', area, 270, 20
	make_text_macro 'D', area, 280, 20
	make_text_macro 'O', area, 290, 20
	make_text_macro 'W', area, 300, 20
	make_text_macro 'S', area, 310, 20
	

	make_text_macro 'C', area, 240, 45
	make_text_macro 'A', area, 250, 45
	make_text_macro 'L', area, 260, 45
	make_text_macro 'C', area, 270, 45
	make_text_macro 'U', area, 280, 45
	make_text_macro 'L', area, 290, 45
	make_text_macro 'A', area, 300, 45
	make_text_macro 'T', area, 310, 45
	make_text_macro 'O', area, 320, 45
	make_text_macro 'R', area, 330, 45
	
	make_text_macro 'B',area, 490,440
	make_text_macro 'Y',area, 500,440
	
	make_text_macro 'A',area, 510,457
	make_text_macro 'L',area, 520,457
	make_text_macro 'E',area, 530,457
	make_text_macro 'X',area, 540,457
	
	make_text_macro '1',area, 145,226
	make_text_macro '2',area, 270,226
	make_text_macro '3',area, 384,226
	make_text_macro '4',area, 145,280
	make_text_macro '5',area, 270,280
	make_text_macro '6',area, 384,280
	make_text_macro '7',area, 145,334
	make_text_macro_simbol 0,area,145,388
	make_text_macro '8',area, 270,334
	make_text_macro '9',area, 384,334
	make_text_macro_simbol 1,area,384,388
	make_text_macro '0',area, 270,394
	make_text_macro_simbol 2,area,460,226
	make_text_macro_simbol 3,area,460, 280
	make_text_macro_simbol 4,area,460, 330
	make_text_macro 'C',area, 460,392
	
	
	
	draw_linie_orizontala_macro area,130,100,1600
	draw_linie_verticala_macro area, 130,100,300
	draw_linie_orizontala_macro area,430,100,1600
	draw_linie_verticala_macro area, 130,500,300
	draw_linie_verticala_macro area,186,425,245
	draw_linie_orizontala_macro area,187,100,1600
	draw_linie_orizontala_macro area,265,100,1600
	draw_linie_orizontala_macro area,319,100,1600
	draw_linie_orizontala_macro area,374,100,1600
	draw_linie_verticala_macro area,186,190,245
	draw_linie_verticala_macro area,187,320,245
	
	
	
iesire:

	
final_draw: 
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
