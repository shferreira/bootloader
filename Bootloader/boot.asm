[bits 16]
[org 0x7c00]

	jmp short start
	nop

oem_name:		db "Glass OS"	; 0x03
bytes_per_sector:	dw 512		; 0x0b
sectors_per_cluster:	db 2		; 0x0d
reserved_sectors:	dw 1		; 0x0e
number_of_fats:		db 2		; 0x10
root_entries:		dw 512		; 0x11
small_sectors:		dw 5120		; 0x13
media_descriptor:	db 0xF8		; 0x15
sectors_per_fat:	dw 8		; 0x16
sectors_per_track:	dw 64		; 0x18
number_of_heads:	dw 16		; 0x1a
hidden_sectors:		dd 0		; 0x1c
total_sectors:		dd 0		; 0x20
physical_drive_number:	dw 0x80		; 0x24
reserved:		db 0x29		; 0x25
signature_byte:		db 0xE6		; 0x26
serial_number:		dw 0xAA1B	; 0x27
			db 0xF8
os_name:		db "OS         "; 0x2B
fat_16:			db "FAT12   "	; 0x36

start:
	cli

	; stack
	xor ax,ax
	mov sp,0x8000

	; first_sector (cx) = number_of_fats * sectors_per_fat + reserved_sectors = 17
	mov al,[number_of_fats]
	mul word [sectors_per_fat]
	add ax,[reserved_sectors]

	; first_data_sector (ax) = (32 * root_entries) / bytes_per_sector + first_sector  = 49
	xchg ax,cx
	mov ax,0x0020
	mul word [root_entries]
	div word [bytes_per_sector]
	add ax,cx
	push ax
	xchg ax,cx

	; root entries (dx)
	mov dx,[root_entries]

read_dir:
	; read everything into 0x0600
	mov di,0x0800
	mov bx,di
	mov cx,0x0001
	call read_sector

find_sys:
	; watch for end of the root directory
	cmp [di],ch
	jz error

	; search kernel by filename
	mov cx,0x0b
	mov si,FileName
	repe cmpsb
	jz load

	; decrement entries counter
	dec dx
	jz error

	; move data pointer
	add di,cx
	add di,0x15

	cmp di,bx
	jb find_sys

	jmp read_dir

load:
	xor cx,cx
	mov di,[di+0x0f]
	mov ax,di
	dec ax
	dec ax
	mul byte [sectors_per_cluster]
	pop cx
	add ax,cx
	inc ax

	mov di,0x0800	; memory - start
	mov bx,0x0800	; memory - end
	mov cx,2	; sectors to read
	call read_sector

	jmp 0x0800

read_sector:
	pusha
	xor cx,cx
	xor dx,dx

	; sector (cx) = (LBA (ax) % sectors_per_track (32)) + 1 = 12
	div word [sectors_per_track]
	inc dx
	xchg cx,dx

	; head (dx) = (LBA (ax) / sectors_per_track(32)) % number_of_heads (16) = 1
	div word [number_of_heads]

	; cilynder (ax) = (LBA (ax) / sectors_per_track) / number_of_head = 0

	mov dh,dl			; dh = head
	mov dl,[physical_drive_number]	; dl = drive
	mov ch,al			; ch = cilynder / cl = sector
	mov ax,0x0201			; ah = command / al = sectors to read
	int 0x13			; bx = address

	popa
	add bx,[bytes_per_sector]
	inc ax
	loop read_sector

	ret



error:
	push Error
	call printf
	hlt

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

FileName db 'KERNEL     ',0

Error db 'No Kernel',0

times 510-($-$$) db 0
dw 0xaa55
