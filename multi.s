MASK EQU 0xB400

global main, print_multi
extern printf, puts, fgets, stdin, strlen, malloc

section .rodata
    out_args_fmt: db "Number of arguments: %d", 0
    out_arg_fmt: db "Argument: ", 0
    newline: db 0xA, 0
    hex_byte_fmt: db "%02hhx", 0
    flag_I: db "-I", 0
    flag_R: db "-R", 0

section .bss
    buffer: resb 600    ; buffer for fgets (as per assignment limit)

section .data
    x_struct: dd 5
    x_num: db 0xaa, 1,2,0x44,0x4f
    y_struct: dd 6
    y_num: db 0xaa, 1,2,3,0x44,0x4f
    STATE: dw 0xACE1

section .text
; --------------------------------------- Part 0 ----------------------------------

printArgs:
    push ebp
    mov ebp, esp

    ; Get argc and argv from the stack
    mov eax, [ebp + 12] ; argc
    mov ebx, [ebp + 8] ; argv

    mov edi, eax ; end of loop

    ; Print number of arguments
    push eax
    push out_args_fmt
    call printf
    add esp, 8

    push newline ; New Line
    call printf
    add esp, 4

    ; Loop through each argument and print it
    mov esi, 0 ; index = 0

.print_loop:
    cmp esi, edi
    jge .end_loop

    ; Print "Argument: " (no newline)
    push out_arg_fmt
    call printf
    add esp, 4

    ; Print argv[esi] using puts (puts appends a newline)
    push dword [ebx + esi * 4]
    call puts
    add esp, 4

    inc esi ; increase index
    jmp .print_loop
    
.end_loop:
    mov esp, ebp
    pop ebp
    ret

; --------------------------------------- Part 0 ----------------------------------

; --------------------------------------- Part 1 ----------------------------------

print_multi:
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov ebx, [ebp + 8]      ; pointer to struct multi
    mov ecx, [ebx]          ; get size field (first 4 bytes)
    
    ; Prepare loop to print from MSB to LSB (Little Endian)
    mov esi, ecx            
    dec esi                 ; start at index size-1

.loop:
    cmp esi, 0
    jl .done1A

    ; Access byte: base + 4 (size field) + index
    movzx eax, byte [ebx + 4 + esi]
    
    push ecx                ; save caller-saved register
    push eax                ; byte to print
    push hex_byte_fmt
    call printf
    add esp, 8
    pop ecx

    dec esi
    jmp .loop

.done1A:
    push dword newline
    call printf
    add esp, 4

    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


getmulti:
    push dword ebp
    mov ebp, esp
    push dword ebx
    push dword esi
    push dword edi

    ; Step 1: Get input from user
    push dword [stdin]
    push dword 600
    push dword buffer
    call fgets
    add esp, 12

    ; Step 2: Calculate length and remove newline
    push dword buffer
    call strlen
    add esp, 4
    ; eax contains length
    
    mov ecx, eax
    ; If string is empty, just return
    cmp ecx, 0
    je .getmulti_done

    ; Remove newline if present at the end
    cmp byte [buffer + ecx - 1], 10
    jne .prepare_conversion
    dec ecx
    mov byte [buffer + ecx], 0

.prepare_conversion:
    ; ecx = string length
    ; Calculate bytes needed: (ecx + 1) / 2
    mov eax, ecx
    inc eax
    shr eax, 1              ; eax = number of bytes
    
    mov ebx, x_struct
    mov [ebx], eax          ; Set size field
    
    mov esi, ecx            ; esi = string pointer (offset)
    mov edi, 0              ; edi = byte index in x_num

.convert_loop:
    cmp esi, 0
    jle .getmulti_done

    ; --- Get Low Nibble (the character on the right) ---
    dec esi
    movzx eax, byte [buffer + esi]
    
    ; Convert ASCII to int
    cmp al, 'a'
    jge .low_lower
    cmp al, 'A'
    jge .low_upper
    sub al, '0'
    jmp .low_done
.low_lower:
    sub al, 'a'
    add al, 10
    jmp .low_done
.low_upper:
    sub al, 'A'
    add al, 10
.low_done:
    mov dl, al              ; Store low nibble in dl

    ; --- Get High Nibble (the character to the left) ---
    cmp esi, 0
    jle .store_byte         ; If no more characters, high nibble is 0
    
    dec esi
    movzx eax, byte [buffer + esi]

    ; Convert ASCII to int
    cmp al, 'a'
    jge .high_lower
    cmp al, 'A'
    jge .high_upper
    sub al, '0'
    jmp .high_done
.high_lower:
    sub al, 'a'
    add al, 10
    jmp .high_done
.high_upper:
    sub al, 'A'
    add al, 10
.high_done:
    shl al, 4               ; Move to high nibble position
    or dl, al               ; Combine with low nibble

.store_byte:
    mov [ebx + 4 + edi], dl ; Store in x_num array
    inc edi
    jmp .convert_loop

.getmulti_done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret


; --------------------------------------- Part 1 ----------------------------------

; --------------------------------------- Part 2 ----------------------------------

; Part 2.A: MaxMin (Input: EAX, EBX | Output: EAX=Longer, EBX=Shorter)
MaxMin:
    push ecx
    push edx
    mov ecx, [eax]
    mov edx, [ebx]
    cmp ecx, edx
    jge .done2A
    xchg eax, ebx
.done2A:
    pop edx
    pop ecx
    ret

; Part 2.B: add_multi (Input: EAX points to p, EBX points to q)
add_multi:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; 1. Identify longer and shorter structs
    call MaxMin         ; EAX = long_ptr, EBX = short_ptr
    mov esi, eax        ; ESI = long source
    mov edi, ebx        ; EDI = short source

    ; 2. Requirement 2.B: Print the two numbers being added
    push edi            ; Push short_ptr
    call print_multi
    add esp, 4
    
    push esi            ; Push long_ptr
    call print_multi
    add esp, 4
    
    ; 3. Malloc for result (size field + max_len + 1 for carry)
    mov ecx, [esi]      ; ecx = max_len
    lea eax, [ecx + 5]  
    push ecx
    push eax
    call malloc
    add esp, 4
    pop ecx

    ; 4. Setup Result Struct
    mov edx, ecx
    inc edx
    mov [eax], edx      ; result->size = max_len + 1
    mov ebx, eax        ; EBX = result_ptr
    
    mov edx, 0          ; index = 0
    clc                 ; Clear carry initially
    pushf               ; Save Carry on stack

.loop_min:
    cmp edx, [edi]      ; index < min_len?
    jge .loop_max
    
    popf                ; Restore Carry
    mov al, [esi + 4 + edx]
    adc al, [edi + 4 + edx]
    pushf               ; Save Carry
    
    mov [ebx + 4 + edx], al
    inc edx
    jmp .loop_min

.loop_max:
    cmp edx, ecx        ; index < max_len?
    jge .final_carry
    
    popf                ; Restore Carry
    mov al, [esi + 4 + edx]
    adc al, 0
    pushf               ; Save Carry
    
    mov [ebx + 4 + edx], al
    inc edx
    jmp .loop_max

.final_carry:
    popf                ; Restore last Carry
    mov al, 0
    adc al, 0
    mov [ebx + 4 + edx], al
    
    ; 5. Requirement 2.B: Print the result
    push ebx            ; Push result_ptr
    call print_multi
    add esp, 4
    
    mov eax, ebx        ; Return the result pointer in EAX

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; --------------------------------------- Part 2 ----------------------------------

; --------------------------------------- Part 3 ----------------------------------

; rand_num: Generates a 16-bit pseudo-random number using LFSR Fibonacci algorithm
rand_num:
    push ebp
    mov ebp, esp
    push ebx

    mov ax, [STATE]         ; Load the current 16-bit state
    mov bx, MASK            ; Load the mask
    and bx, ax              ; Isolate the relevant bits (taps)
    
    ; Compute the parity of the isolated bits. 
    ; x86 PF flag checks parity only on the lowest byte. 
    ; To check 16-bit, we XOR high and low bytes:
    xor bh, bl              ; Now BH/BL parity reflects all 16 bits
    jp .parity_even         ; If Parity is even, we shift in a 0

.parity_odd:
    mov cx, 0x8000          ; Odd parity: prepare to shift in a 1 (MSB)
    jmp .do_shift

.parity_even:
    mov cx, 0x0000          ; Even parity: prepare to shift in a 0

.do_shift:
    shr ax, 1               ; Shift current state right by 1
    or ax, cx               ; Put computed parity bit into the MSB
    mov [STATE], ax        ; Update global STATE
    
    movzx eax, ax           ; Return updated 16-bit state in EAX
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; PRmulti: Creates a pseudo-random Multi-precision Integer struct
PRmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

.get_len:
    call rand_num
    and eax, 0xFF           ; Take the first 8 bits (one byte)
    cmp eax, 0
    je .get_len             ; If length is 0, regenerate
    
    mov ebx, eax            ; ebx = n (length in bytes)
    
    ; Malloc: 4 bytes (header) + n bytes
    lea eax, [ebx + 4]
    push ebx                ; Save n
    push eax                ; Allocation size
    call malloc
    add esp, 4
    pop ebx                 ; Restore n
    
    mov [eax], ebx          ; Set struct size field
    mov esi, eax            ; ESI = new struct pointer
    mov edi, 0              ; Current byte index

.fill_loop:
    cmp edi, ebx
    jge .done_pr
    
    call rand_num           ; Get new random bits
    ; We take the low byte (AL) and store it in our array
    mov [esi + 4 + edi], al
    
    inc edi
    jmp .fill_loop

.done_pr:
    mov eax, esi            ; Return pointer to the random struct
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; --------------------------------------- Part 3 ----------------------------------

; --------------------------------------- Part 4 ----------------------------------
main:
    push ebp
    mov ebp, esp

    ; Check if there is at least one argument besides the program name
    mov eax, [ebp + 8]      ; eax = argc
    cmp eax, 1
    jle .run_default        ; No flags -> Default mode

    mov ebx, [ebp + 12]     ; ebx = argv
    mov ecx, [ebx + 4]      ; ecx = argv[1]

    cmp byte [ecx], '-'
    jne .run_default
    
    mov al, [ecx + 1]
    cmp al, 'I'
    je .run_input
    cmp al, 'R'
    je .run_random

.run_default:
    mov eax, x_struct
    mov ebx, y_struct
    call add_multi
    jmp .end_main

.run_input:
    call getmulti_dynamic
    push eax                ; Save first struct pointer on stack
    call getmulti_dynamic
    mov ebx, eax            ; Second struct in ebx
    pop eax                 ; First struct in eax
    call add_multi
    jmp .end_main

.run_random:
    call PRmulti
    push eax                ; Save first random struct on stack
    call PRmulti
    mov ebx, eax            ; Second random struct in ebx
    pop eax                 ; First random struct in eax
    call add_multi

.end_main:
    mov esp, ebp
    pop ebp
    ret

getmulti_dynamic:
    push ebp
    mov ebp, esp
    sub esp, 4              ; Local space to save the malloc pointer safely
    push ebx
    push esi
    push edi

    ; Read from stdin
    push dword [stdin]
    push 600
    push buffer
    call fgets
    add esp, 12

    test eax, eax
    jz .empty_struct

    push buffer
    call strlen
    add esp, 4
    
    mov ecx, eax            
    test ecx, ecx
    jz .empty_struct

    ; Remove newline and null-terminate
    cmp byte [buffer + ecx - 1], 10
    jne .calc_size
    dec ecx
    mov byte [buffer + ecx], 0
    test ecx, ecx
    jz .empty_struct

.calc_size:
    ; Preserve string length in ESI
    mov esi, ecx
    
    mov eax, ecx
    inc eax
    shr eax, 1              ; number of bytes needed
    mov edi, eax            ; store byte count in edi
    
    lea eax, [edi + 4]      ; size field + bytes
    push eax
    call malloc
    add esp, 4
    
    test eax, eax
    jz .exit_dynamic

    mov [ebp - 4], eax      ; SAVE the malloc pointer to local stack variable
    mov dword [eax], edi    ; set struct->size field
    
    mov ebx, 0              ; ebx = byte index in the new struct array

.conv_loop:
    test esi, esi           ; Check if we finished the string
    jle .done_dynamic
    
    ; Low nibble (right-most character)
    dec esi
    movzx eax, byte [buffer + esi]
    call char_to_int
    mov dl, al
    
    ; High nibble (next character to the left)
    test esi, esi
    jle .store_byte
    dec esi
    movzx eax, byte [buffer + esi]
    call char_to_int
    shl al, 4
    or dl, al

.store_byte:
    mov ecx, [ebp - 4]      ; RELOAD the malloc pointer from stack
    mov [ecx + 4 + ebx], dl ; store byte at (base + 4 + index)
    inc ebx
    jmp .conv_loop

.empty_struct:
    push 4
    call malloc
    add esp, 4
    mov dword [eax], 0
    mov [ebp - 4], eax
    jmp .done_dynamic

.done_dynamic:
    mov eax, [ebp - 4]      ; Return the saved pointer in EAX

.exit_dynamic:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; Separate helper for ASCII to Hex conversion
char_to_int:
    cmp al, '9'
    jbe .is_digit
    cmp al, 'F'
    jbe .is_upper
    sub al, 32          ; Convert lower to upper
.is_upper:
    sub al, 'A'
    add al, 10
    ret
.is_digit:
    sub al, '0'
    ret

; --------------------------------------- Part 4 ----------------------------------