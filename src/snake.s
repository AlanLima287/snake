[BITS 16]
[ORG 0x7C00]

SECTOR_COUNT equ 0x07

; LWALL equ 0x16
; UWALL equ 0x06
; RWALL equ 0x39
; DWALL equ 0x12

LWALL equ 0x01
UWALL equ 0x01
RWALL equ 0x4E
DWALL equ 0x17

VSIZE equ DWALL - UWALL + 1
HSIZE equ RWALL - LWALL + 1

FIELD_SIZE equ VSIZE * HSIZE

STARTING_SIZE equ 3

LEFT  equ 0x4B
UP    equ 0x48
RIGHT equ 0x4D
DOWN  equ 0x50

FRUIT equ 0x66

start:
   cli
   xor ax, ax
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov sp, 0x7C00
   sti

load_sectors:
   xor dh, dh               ; head
   mov cx, 0x0002           ; ?
   mov bx, 0x7E00           ; data buffer
   mov al, SECTOR_COUNT - 1 ; 1 sector has already been loaded
   mov ah, 0x02             ; read from drive
   int 0x13

   jnc main

      mov si, ax
      call print_hex

      mov ah, 0
      int 0x16

      jmp poweroff

print_char: ; function print_char(al ch: char) void
   mov ah, 0x0A
   xor bx, bx
   mov cx, 1
   int 0x10

   ret

print_hex: ; function print_hex(si num: u16)
   mov cl, 0x04
   mov ah, 0x0E

   .loop:
      dec cl

      rol si, 0x4
      mov bx, si
      and bx, 0xF
      
      mov al, [bx + .hex]
      int 0x10

      test cl, cl
      jnz .loop
      
      ret
   
   .hex db "0123456789ABCDEF"

print_dec: ; function print_dec(esi num: u16)
   xor ecx, ecx
   xor bh, bh

   cmp esi, 0
   setl bl
   jge .loop
      neg esi

   .loop:
      mov eax, 0x66666667
      imul esi
      sar edx, 2

      mov eax, edx
      shr eax, 0x1F
      add edx, eax

      shl ecx, 4
      lea eax, [edx + edx * 4]
      add eax, eax
      sub esi, eax
      or ecx, esi

      inc bh
      mov esi, edx

      test edx, edx
      jnz .loop

   mov ah, 0x0E

   test bl, bl
   jz .print
      mov al, '-'
      int 0x10
   
   .print:
      dec bh

      mov al, cl
      and al, 0xF
      add al, '0'
      int 0x10

      shr cx, 4
      test bh, bh
      jnz .print

   ret

print_str: ; function print_str(si str: *char)
   .entry:
      push ax
      push si

   .loop:
      mov al, [si]
      test al, al
      jz .exit

      mov ah, 0x0E
      int 0x10

      inc si
      jmp .loop

   .exit:
      pop si
      pop ax
      ret

poweroff:
   mov ax, 0x5307
   mov bx, 0x0001
   mov cx, 0x0003
   int 0x15

   cli
   hlt

.padding:
   times 510 - ($ - $$) db 0
   dw 0xAA55

main:
   .entry:
      ; puts current timestamp into edx:eax
      rdtsc 
      mov [random.seed], eax

      ; hide cursor
      mov ch, 0x3F
      mov ah, 0x1
      int 0x10

      ; set the color for the screen
      mov bh, 0x2E
      mov cx, (UWALL << 8) | LWALL
      mov dx, (DWALL << 8) | RWALL
      mov ax, 0x0600
      int 0x10

      ; cursor to (0, 0)
      xor dx, dx
      xor bx, bx
      mov ah, 0x2
      int 0x10

      ; clear screen
      mov ax, 0x0A00
      mov cx, 0x07D0
      int 0x10

      ; cursor to (0xB, 0x26)
      mov dh, UWALL
      mov dl, LWALL + 1
      mov ah, 0x2
      int 0x10

      ; print the starting body of the snake
      mov ax, 0x0ADB
      mov cx, STARTING_SIZE
      int 0x10
   
      call put_fruit

   .loop:
      ; cursor to (0, 1)
      mov dx, 0x0001
      xor bx, bx
      mov ah, 2
      int 0x10

      ; print the snake size
      xor esi, esi
      mov si, [var.size]
      call print_dec

      xor cx, cx

      .wait:
         cmp cx, 0xFF
         jae .exit_wait

         mov ah, 1
         int 0x16
         jz .skip_key
            mov dh, [var.direction]

            mov ah, 0
            int 0x16

            cmp ah, LEFT
            jne .else_left
               cmp dh, RIGHT
               cmove ax, dx
               mov [.tmp_direction], ah
               jmp .skip_key

            .else_left:
            cmp ah, UP
            jne .else_up
               cmp dh, DOWN
               cmove ax, dx
               mov [.tmp_direction], ah
               jmp .skip_key
               
            .else_up:
            cmp ah, RIGHT
            jne .else_right
               cmp dh, LEFT
               cmove ax, dx
               mov [.tmp_direction], ah
               jmp .skip_key
            
            .else_right:
            cmp ah, DOWN
            jne .else_down
               cmp dh, UP
               cmove ax, dx
               mov [.tmp_direction], ah
               ; jmp .skip_key
         
            .else_down:

         .skip_key:
         inc cx
         jmp .wait

      .exit_wait:
         mov ah, [.tmp_direction]
         mov [var.direction], ah

         mov dx, [var.head]
         call dereference

         mov ah, [di]
         cmp ah, FRUIT
         jne .else
            inc word [var.size]
            call put_fruit
            jmp .esc
         .else:
         test ah, ah
         jnz game_over
            call move.tail
         
         .esc:
         call move.head
         
         mov cx, 1
   
         ; cursor to tail position
         mov dx, [var.tail]
         mov ah, 0x2
         int 0x10

         ; remove the tail
         mov ax, 0x0A00
         int 0x10

         ; cursor to head position
         mov dx, [var.head]
         mov ah, 0x2
         int 0x10

         ; print the head
         mov ax, 0x0ADB
         int 0x10

      jmp .loop
   
   .tmp_direction: db RIGHT

dereference: ; function dereference(dx inx: u16) di: u16
   mov bx, dx

   sub bh, UWALL
   sub bl, LWALL

   mov si, bx
   shr si, 8
   imul si, HSIZE

   xor bh, bh

   lea di, [si + bx + snake]
   ret

move:
   .tail:
      mov dx, [var.tail]
      call dereference
      mov ah, [di]

      call .move
      
      mov byte [di], 0x00
      mov [var.tail], dx
      ret

   .head:
      mov dx, [var.head]
      call dereference

      mov ah, [var.direction]
      mov [di], ah

      call .move

      mov [var.head], dx
      ret

   .move:
      cmp ah, LEFT
      jne .else_left
         dec dl
         cmp dl, LWALL
         jge .exit
         
         mov dl, RWALL
         jmp .exit

      .else_left:
      cmp ah, UP
      jne .else_up
         dec dh
         cmp dh, UWALL
         jge .exit

         mov dh, DWALL
         jmp .exit
         
      .else_up:
      cmp ah, RIGHT
      jne .else_right
         inc dl
         cmp dl, RWALL
         jle .exit

         mov dl, LWALL
         jmp .exit
      
      .else_right:
      cmp ah, DOWN
      jne .else_down
         inc dh
         cmp dh, DWALL
         jle .exit

         mov dh, UWALL
         jmp .exit

      .else_down:
         jmp poweroff

      .exit:
         ret

put_fruit: ; function () ax: u16
   
   mov cl, UWALL
   mov ch, DWALL + 1
   call random_int
   mov dh, al

   mov cl, LWALL
   mov ch, RWALL + 1
   call random_int
   mov dl, al

   call dereference
   mov ah, [di]
   test ah, ah
      jnz put_fruit
   
   mov byte [di], FRUIT

   ; print fruit
   mov ah, 0x2
   int 0x10

   mov ax, 0x0AFE
   mov cx, 1
   int 0x10

   ret

game_over:
   mov bh, 0x44
   mov dx, [var.head]
   mov cx, dx
   mov ax, 0x0600
   int 0x10

   mov dx, 0x1801
   xor bx, bx
   mov ah, 2
   int 0x10

   mov si, .str
   call print_str

.terminate:
   mov ah, 0
   int 0x16

   cmp ax, 0x011B
   je poweroff

   cmp ax, 0x1C0D
   jne .terminate

   mov byte [main.tmp_direction], RIGHT
   mov byte [var.direction], RIGHT
   mov word [var.tail], (UWALL << 8) | LWALL
   mov word [var.head], (UWALL << 8) | (LWALL + STARTING_SIZE)
   mov word [var.size], STARTING_SIZE

   xor bx, bx
   .body:
      cmp bx, STARTING_SIZE
      jge .fill
      mov byte [bx + snake], RIGHT
      inc bx
      jmp .body

   .fill:
      cmp bx, FIELD_SIZE - STARTING_SIZE
      jge main
      mov byte [bx + snake], 0
      inc bx
      jmp .fill

   .str:
      db "Press ESCAPE to poweroff, press RETURN to restart...", 0

var:
   .direction: db RIGHT
   .tail: db LWALL, UWALL
   .head: db LWALL + STARTING_SIZE, UWALL
   .size: dw STARTING_SIZE

snake:
   times STARTING_SIZE db RIGHT
   times (FIELD_SIZE - STARTING_SIZE) db 0

sleep: ; function sleep(ecx time: u32)
   .entry:
      push edx
      push eax

      rdtsc
      add eax, ecx

   .wait:
      rdtsc
      cmp ecx, eax
      jbe .wait
   
   .exit:
      pop eax
      pop edx
      ret

random: ; function random() ax: u16
   mov eax, [.seed]
   
   imul eax, 0x343FD
   add eax, 0x269EC3
   mov [.seed], eax
   
   shr eax, 0x10
   and eax, 0xFFFF
   ret

   .seed dd 0

random_int: ; function random(cl min: u16, ch max: u16) al: u8
   call random
   and ax, 0x3FF
   sub ch, cl
   jle poweroff
   idiv ch

   mov al, ah
   add al, cl

   ret

times 512 * (SECTOR_COUNT) - ($ - $$) db 0xCC