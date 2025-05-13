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
