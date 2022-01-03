
#Enviroment
BIN2VHDL=../../scripts/bin2vhdl.py

CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy
OBJDUMP=riscv32-unknown-elf-objdump
CFLAGS=-march=rv32i -mabi=ilp32 -mstrict-align -nostartfiles

ODIR=obj
SDIR=src
BDIR=bin
TARGET=fibo

_OBJ = boot.o fibo.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))


all: $(TARGET).lst $(TARGET).vhdl

$(ODIR)/%.o: $(SDIR)/%.s $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/%.o: $(SDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET).elf: $(OBJ)
	$(CC) -T linker.ld -o $(BDIR)/$@ $(OBJ) $(CFLAGS)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $(BDIR)/$< $(BDIR)/$@

$(TARGET).lst: $(TARGET).elf
	$(OBJDUMP) -D $(BDIR)/$< > $(BDIR)/$@

$(TARGET).vhdl: $(TARGET).bin
	python3 $(BIN2VHDL) -i $(BDIR)/$< -o $(BDIR)/$@

.PHONY: clean

clean:
	rm -f $(ODIR)/*.o $(BDIR)/*.* *~ core $(INCDIR)/*~