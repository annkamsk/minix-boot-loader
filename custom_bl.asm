org 0600h								; move down to 0600h

_start:
	cli										; disable interrupts
	xor ax, ax      			; zero other segments
  mov ds, ax
  mov es, ax
	mov ss, ax
  mov sp, 7C00h 				; place stack before the bootloader
	sti										; set interrupt flag
	cld										; zero the direction flag
	mov si, sp						; start address
	mov di, 0600h					; destination address
	mov cx, 512/2
	rep movsw

	jmp 0:main						; jump to the copy at 0600h, so we can load the boot sector at 7C00h.
main:
  mov [DriveNo], dl     ; drive number stored in DL

	mov edi, BUF					; store pointer to BUF
	call print

input_loop:
	mov ah, 01h						; check for key
	int 16h								; keyboard interrupt call
	jz	input_loop				; if no pending key
	mov ah, 00h						; get key
	int 16h
	cmp al, 121						; check if 'y'
	je 	save_yes
	cmp al, 110						; check if 'n'
	je	save_no
	jmp input_loop

save_yes:
	call print_char
	jmp	load_bl

save_no:
	call print_char

load_bl:								; load the normal boot loader
	; look for one active partition.
	mov si, PartitionTable
	xor ax, ax
	mov cx, 4
	checkpartloop:
	test byte [si], 80h
	jz .notactive
	inc ax
	mov di, si
	.notactive:   add si, byte 16
							loop checkpartloop
	cmp ax, byte 1				; better be only one
	jnz bad_disk

	; load the boot sector
	push di
	mov si, dapa
	mov bx, [di+8]				; copy the block address
	mov [si+8], bx
	mov bx, [di+10]
	mov [si+10], bx
	mov dl, [DriveNo]
	mov ah, 42h
	int 13h
	pop si								; DS:SI -> partition table entry
	cmp word [7C00h+510], 0AA55h
	jne missing_os
	cli

	jmp 0:7C00h						; jump to boot sector */

missing_os:
	xor edi, edi
	mov edi, missing_os_msg
	jmp print

bad_disk:
	xor edi, edi
	mov edi, bad_disk_msg
	jmp print

print:									; w rejestrze edi print spodziewa się otrzymać adres bufora
print_loop:
	mov al, BYTE [edi]		; weź kolejny znak z bufora
	inc edi								; ++idx
	cmp al, 0x0						; jeśli to znak końca napisu
	je	end_loop					; zakończ
	call print_char				; jeśli nie, to wypisz znak
	jmp print_loop
end_loop:
	ret

print_char:							; w rejestrze al funkcja spodziewa się otrzymać argument - znak do wypisania
  mov ah, 0xe
  int 0x10
  ret

	align 4, db 0 ; Begin data area

; Error messages
missing_os_msg  db 'Missing operating system', 13, 10, 0
bad_disk_msg    db 'Operating system loading error', 13, 10, 0

BUF 						db 'Enter your choice: ', 0xd, 0xa, 0x0 ; napis kończy się znakiem nowej linii (0xd, 0xa) i nullem (0x0)

dapa: 					dw 16							; disk address packet size
.count:					dw 1							; block count
.off						dw 7C00h					; offset of buffer
.seg 						dw 0							; segment of buffer
.lba						dd 0							; LBA
								dd 0

PartitionTable  equ $$+446                      ; Start of partition table

DriveNo         equ 0800h
