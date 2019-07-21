org 0x7c00				; informacja o początkowym adresie programu ('Binary File Program Origin')

jmp 0:start         	; wyzerowanie rejestru cs

start:	
	mov ax, cs      	; wyzerowanie pozostałych rejestrów segmentowych
    mov ds, ax
   	mov es, ax
   	mov ss, ax
   	mov sp, 0x8000 		; inicjowanie stosu

main:
	mov edi, BUF			; store pointer to BUF
	call print
loop:
	jmp loop

print:						; w rejestrze edi print spodziewa się otrzymać adres bufora

print_loop:
	mov al, BYTE [edi]		; weź kolejny znak z bufora
	inc edi					; ++idx
	cmp al, 0x0				; jeśli to znak końca napisu
	je	end_loop			; zakończ
	call print_char			; jeśli nie, to wypisz znak
	jmp print_loop
end_loop:
	ret

print_char:					; w rejestrze al funkcja spodziewa się otrzymać argument - znak do wypisania
    mov ah, 0xe
    int 0x10
    ret

BUF db 'Enter your choice: ', 0xd, 0xa, 0x0 ; napis kończy się znakiem nowej linii (0xd, 0xa) i nullem (0x0)

times 510 - ($ - $$) db 0;
dw 0xaa55
