
#Enviroment
BIN2VHDL=../../scripts/bin2vhdl.py
BIN2MIF=../../scripts/bin2mif.py

CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy
OBJDUMP=riscv32-unknown-elf-objdump
STRIP=riscv32-unknown-elf-strip
CFLAGS=-O3 -march=rv32i -mabi=ilp32 -mstrict-align# -nostartfiles

ODIR=obj
SDIR=src
BDIR=bin
TARGET=demo


_OBJ = boot.o sbrk.o demo.o disp7seg.o uart.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))


all: $(TARGET).lst $(TARGET).vhdl $(TARGET).mif

$(ODIR)/%.o: $(SDIR)/%.s $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/%.o: $(SDIR)/%.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET).elf: $(OBJ)
	$(CC) -T linker.ld -o $(BDIR)/$@ $(OBJ) $(CFLAGS)
#	$(CC) -T default.ld -o $(BDIR)/$@ $(OBJ) $(CFLAGS)
	$(STRIP) --strip-debug $(BDIR)/$@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $(BDIR)/$< $(BDIR)/$@

$(TARGET).lst: $(TARGET).elf
	$(OBJDUMP) -D $(BDIR)/$< > $(BDIR)/$@

$(TARGET).vhdl: $(TARGET).bin
	python3 $(BIN2VHDL) -i $(BDIR)/$< -o $(BDIR)/$@

$(TARGET).mif: $(TARGET).bin
	python3 $(BIN2MIF) -i $(BDIR)/$< -o $(BDIR)/$@

.PHONY: clean

clean:
	rm -f $(ODIR)/*.o $(BDIR)/*.* *~ core $(INCDIR)/*~