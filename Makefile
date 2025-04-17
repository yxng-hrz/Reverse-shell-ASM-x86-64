ASM = nasm
LD = ld

ASMFLAGS = -f elf64
LDFLAGS = 

SRC = reverse_shell.asm
OBJ = $(SRC:.asm=.o)
TARGET = reverse_shell

all: $(TARGET)

$(OBJ): $(SRC)
	$(ASM) $(ASMFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $<

clean:
	rm -f $(OBJ)

fclean: clean
	rm -f $(TARGET)

re: fclean all

run: $(TARGET)
	./$(TARGET)

.PHONY: all clean fclean re run