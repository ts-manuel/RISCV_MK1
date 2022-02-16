
#Enviroment
BIN2VHDL=../../scripts/bin2vhdl.py
BIN2MIF=../../scripts/bin2mif.py

CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy
OBJDUMP=riscv32-unknown-elf-objdump
STRIP=riscv32-unknown-elf-strip
CFLAGS=-O3 -march=rv32i -mabi=ilp32 -mstrict-align -lm# -nostartfiles

ODIR=obj
SDIR=src
BDIR=bin
TARGET=bench


_OBJ = boot.o sbrk.o main.o hardware/uart.o jpeg/decoder.o jpeg/bit_buffer.o test_images.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))


all: $(TARGET).lst $(TARGET).vhdl $(TARGET).mif

$(ODIR)/%.o: $(SDIR)/%.s $(DEPS)
	mkdir -p $(@D)
	$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/%.o: $(SDIR)/%.c $(DEPS)
	mkdir -p $(@D)
	$(CC) -c -o $@ $< $(CFLAGS)

$(TARGET).elf: $(OBJ)
	$(CC) -T linker.ld -o $(BDIR)/$@ $(OBJ) $(CFLAGS)
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
	rm -f -r $(ODIR)/*.o $(ODIR)/* $(BDIR)/*.* *~ core $(INCDIR)/*~