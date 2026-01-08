

global main, print_multi
extern printf, puts, fgets, stdin, strlen

section .rodata
    out_args_fmt: db "Number of arguments: %d", 0
    out_arg_fmt: db "Argument: ", 0
    newline: db 0xA, 0
    hex_byte_fmt: db "%02hhx", 0

section .bss
    buffer: resb 600    ; buffer for fgets (as per assignment limit)

section .data
    x_struct: dd 5
    x_num: db 0xaa, 1,2,0x44,0x4f

section .text
main:
	push ebp
    mov ebp, esp


    push dword [ebp + 8] ; argc
    push dword [ebp + 12] ; argv
    call printArgs

    call getmulti
    push x_struct
    call print_multi
    add esp, 4

    mov esp, ebp
    pop ebp
    ret



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
    jl .done

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

.done:
    push newline
    call printf
    add esp, 4

    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret



; --------------------------------------- Part 1 ----------------------------------