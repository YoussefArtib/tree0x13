org 0x7C00
bits 16

%define VGA_SEGMENT       0xA000
%define VGA_MODE13_WIDTH  320
%define VGA_MODE13_HEIGHT 200

%define RED   0x04
%define GREEN 0x02
%define BROWN 0x06
%define WHITE 0x0F

entry:
    push bp
    mov bp, sp

    ; Video mode
    mov ax, 0x13
    int 0x10

    ; ?
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; print "Just a beautiful apple tree"
    mov ah, 0x13
    mov bx, WHITE
    mov bp, msg         ; string
    mov cl, msg_len     ; length
    mov dh, 23          ; row
    mov dl, 5           ; col
    int 0x10

    mov ax, VGA_SEGMENT
    mov es, ax          ; segment 0xA000, where
                        ; the memory for mode 0x13 is located

    ; 30x60 rect
    mov di, 145
    mov si, 120
    mov dx, 30
    mov cx, 60
    mov bx, BROWN
    call draw_rectangle

    ; 120x30 rect
    mov di, 100
    mov si, 90
    mov dx, 120
    mov cx, 30
    mov bx, GREEN
    call draw_rectangle

    ; 90x30 rect
    mov di, 110
    mov si, 60
    mov dx, 90
    mov cx, 30
    mov bx, GREEN
    call draw_rectangle

    ; 60x30 rect
    mov di, 130
    mov si, 30
    mov dx, 60
    mov cx, 30
    mov bx, GREEN
    call draw_rectangle

    ; draw the apples
    mov ax, 0
.apples_loop:
        lea bx, apples
        add bx, ax
        mov di, [bx]
        mov si, [bx + 2]
        mov dx, 5
        mov cx, RED
        push ax
        call draw_circle
        pop ax
        add ax, 4
        cmp ax, 28
        jz .end_apples_loop
        jmp .apples_loop
.end_apples_loop:

    ; ?
    cli
    hlt
    ; jmp $

;(x = di, y = si, color = dx)
draw_pixel:
    push bp
    mov bp, sp
    sub sp, 16

    mov word [bp - 2], di; x
    mov word [bp - 4], si; y
    mov word [bp - 6], dx; color

    mov ax, [bp - 4]
    mov bx, [bp - 2]
    mov di, VGA_MODE13_WIDTH
    mul di
    add ax, bx
    mov di, ax
    mov dx, [bp - 6]
    mov BYTE [es:di], dl

    add sp, 16
    pop bp
    ret

; (x = di, y = si, length = dx, color = cx)
; Horizontal line
draw_line: 
    push bp
    mov bp, sp
    sub sp, 16
    mov word [bp - 2], di; x
    mov word [bp - 4], si; y
    mov word [bp - 6], dx; length
    mov word [bp - 8], cx; color

    mov cx, [bp - 6]
    mov dx, 3
.loop:
    push dx
    mov di, [bp - 2]
    mov si, [bp - 4]
    mov dx, [bp - 8]
    call draw_pixel
    pop dx
    inc byte [bp - 2]
    loop .loop

    add sp, 16
    pop bp
    ret

; (x = di, y = si, width = dx, height = cx, color = bx)
draw_rectangle:
    push bp
    mov bp, sp
    sub sp, 16
    mov word [bp - 2], di; x
    mov word [bp - 4], si; y
    mov word [bp - 6], dx; width
    mov word [bp - 8], cx; height
    mov word [bp - 10], bx; color

    mov cx, [bp - 8]
.loop:
    push cx

    mov di, [bp - 2]
    mov si, [bp - 4]
    mov dx, [bp - 6]
    mov cx, [bp - 10]
    call draw_line

    inc word [bp - 4]
    pop cx
    loop .loop

    add sp, 16
    pop bp
    ret
    
; (center(x = di, y = si), radius = dx, color = cx)
draw_circle:
    push bp
    mov bp, sp
    sub sp, 32
    mov word [bp - 18], cx
    mov dword [bp - 16], 0

    mov word [bp - 2], di; x
    mov word [bp - 4], si; y
    mov word [bp - 6], dx; radius

    sub di, dx
    mov word [bp - 8], di; startx
    sub si, dx
    mov word [bp - 10], si; starty

    ; y_end = starty + radius * 2
    xor ax, ax
    mov ax, [bp - 6]; radius
    mov bx, 2
    mul bx
    add ax, [bp - 10]; starty
    mov word [bp - 12], ax; y_end

    ; x_end = startx + radius * 2
    xor ax, ax
    mov ax, [bp - 6]; radius
    mov bx, 2
    mul bx
    add ax, [bp - 8]; startx
    mov word [bp - 14], ax; x_end

    mov di, [bp - 8]
    mov word [bp - 20], di

.loopy:
    mov ax, [bp - 10]; starty
    cmp ax, [bp - 12]; yi <= y_end
    jae .endy

    mov di, [bp - 20]
    mov word [bp - 8], di
.loopx:
    mov ax, [bp - 8];  startx
    cmp ax, [bp - 14]; xi <= x_end
    jae .endx

    ; (xi - x)²
    mov ax, [bp - 8]; xi
    sub ax, [bp - 2]; xi - x
    mul ax
    mov word [bp - 16], ax; store (xi - x)²
    ; (yi - y)²
    mov ax, [bp - 10]; yi
    sub ax, [bp - 4]; yi - y
    mul ax
    add word [bp - 16], ax; store (xi - x)² + (yi - y)²

    mov ax, [bp - 6]; radius
    mul ax; r²
    cmp word [bp - 16], ax
    jbe .draw_pix
    jmp .dont_draw_pix

.draw_pix:
    mov di, [bp - 8]
    mov si, [bp - 10]
    mov dx, [bp - 18]
    call draw_pixel
.dont_draw_pix:
    inc word [bp - 8]; inc startx
    jmp .loopx

.endx:
    inc word [bp - 10]; inc starty
    jmp .loopy

.endy:
    add sp, 32
    pop bp
    ret

apples:
    dw 155, 40; 1st apple
    dw 145, 60; 2nd apple
    dw 180, 70; 3rd apple
    dw 130, 80; 4th apple
    dw 160, 90; 5th apple
    dw 200, 100; 6th apple
    dw 120, 110; 7th apple

msg: db "Just a beautiful apple tree"; but the code is ugly
msg_len equ $ - msg

; padding
times 510 - ($-$$) db 0
; boot signature
dw 0xAA55
