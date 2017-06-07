[bits 16]
[org 0x7c00]

push BemVindo
call printf
hlt


BemVindo db 'Bem Vindo! Este é o Kernel :)',13,10,0



printf:
	mov si,[esp+2]
	mov ah,0x0e
	mov bh,0x00
	mov bl,0x07
char:
	lodsb
	or al,al
	jz enda
	int 0x10
	jmp char
enda:
	mov al,10
	int 0x10
	mov al,13
	int 0x10
	ret
