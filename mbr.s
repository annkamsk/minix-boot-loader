org 0600h                           ; move down to 0600h

_start:
    cli                             ; disable interrupts
    xor ax, ax                      ; zero other segments
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 7C00h                   ; place stack before the bootloader
    sti                             ; set interrupt flag
    cld                             ; zero the direction flag
    mov si, sp                      ; starting address
    mov di, 0600h                   ; destination address
    mov cx, 512/2
    rep movsw

    jmp 0:main                      ; jump to the copy at 0600h, so we can load the boot sector at 7C00h

main:
    mov [DriveNo], dl               ; drive number stored in DL

    mov edi, BUF                    ; store pointer to BUF
    call print

input_loop:                         ; read user input
    mov ah, 01h                     ; check for key
    int 16h                         ; keyboard interrupt call
    jz  input_loop                  ; if no pending key, go back
    mov ah, 00h                     ; get key
    int 16h
    cmp al, 121                     ; check if 'y'
    je  save_yes
    cmp al, 110                     ; check if 'n'
    je  save_no
    jmp input_loop

save_yes:
    call print_char
    mov [ans], byte 01h
    jmp load_bl

save_no:
    call print_char
    mov [ans], byte 02h

load_bl:                            ; load the normal boot loader
                                    ; look for one active partition
    mov si, PartitionTable
    xor ax, ax
    mov cx, 4
checkpartloop:
    test byte [si], 80h
    jz .notactive
    inc ax
    mov di, si
.notactive:
    add si, byte 16
    loop checkpartloop

    cmp ax, byte 1                  ; check if only one is active
    jnz bad_disk

    ; save an option chosen by the user in the 2nd sector
    push di
    mov si, dapw
    mov bx, [di+8]                  ; copy the block address
    add bx, byte 1                  ; sector = 2
    mov [si+8], bx
    mov bx, [di+10]
    mov [si+10], bx
    mov dl, [DriveNo]
    mov ah, 43h                     ; set the write to disc BIOS call
    mov al, 1
    int 13h
    pop di

    ; load the boot sector
    push di
    mov si, dapa
    mov bx, [di+8]                  ; copy the block address
    mov [si+8], bx
    mov bx, [di+10]
    mov [si+10], bx
    mov dl, [DriveNo]
    mov ah, 42h
    int 13h
    pop si                          ; get partition table entry
    cmp word [7C00h+510], 0AA55h
    jne missing_os
    cli

    jmp 0:7C00h                     ; jump to boot sector

missing_os:
    xor edi, edi
    mov edi, missing_os_msg
    jmp print

bad_disk:
    xor edi, edi
    mov edi, bad_disk_msg
    jmp print

print:                              ; in edi register, function expects to get address of a buffer
print_loop:
    mov al, BYTE [edi]              ; take next char from the buffer
    inc edi                         ; ++idx
    cmp al, 0x0                     ; if it's end of string
    je  end_loop
    call print_char                 ; else print char
    jmp print_loop
end_loop:
    ret

print_char:                         ; in al register, function expects to get char to print
    mov ah, 0xe
    int 0x10
    ret

    align 4, db 0                   ; begin data area

; Error messages
missing_os_msg          db 'Missing operating system', 13, 10, 0
bad_disk_msg            db 'Operating system loading error', 13, 10, 0

BUF                     db 'Enter your choice: ', 0xd, 0xa, 0x0

; dap table for reading bootloader code
dapa:                   dw 16                           ; disk address packet size
.count:                 dw 1                            ; block count
.off                    dw 7C00h                        ; offset of buffer
.seg                    dw 0                            ; segment of buffer
.lba                    dd 0                            ; LBA
                        dd 0

; dap table for saving aaaaa option
dapw                    dw 16                           ; disk address packet size
.countw                 dw 1                            ; block count
.offw                   dw 0600h                        ; offset of buffer
.segw                   dw 0                            ; segment of buffer
.lbaw                   dd 0                            ; LBA
                        dd 0

ans                     db 0                            ; saved option: 1 for yes, 2 for no

PartitionTable          equ $$+446                      ; start of partition table
DriveNo                 equ 0800h