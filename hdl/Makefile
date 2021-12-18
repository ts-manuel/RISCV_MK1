
VPATH = rtl/core tb/core #Search path
WORKDIR=work# Work directory
VCDDIR=vcd
VHDL_RTL := $(wildcard rtl/core/*.vhd)# VHDL source files
VHDL_TB  := $(wildcard tb/core/*.vhd)# VHDL test bench files
TARGETS := $(notdir $(VHDL_TB:.vhd=.vcd))# Target files simulation output
#
GHDL=/usr/local/bin/ghdl
GHDLFLAGS=--workdir=$(WORKDIR) --std=08


all : $(TARGETS)


$(TARGETS) : analysis
$(TARGETS) : %.vcd: %.vhd
	$(GHDL) -e $(GHDLFLAGS) $(basename $(notdir $<))
	$(GHDL) -r $(GHDLFLAGS) $(basename $(notdir $<)) --vcd=$(VCDDIR)/$(notdir $@)
	@echo "-------------------------------------------------"
	@echo " " $(basename $(notdir $<)) "PASSED!!!"
	@echo "-------------------------------------------------"


analysis: clean
	$(GHDL) -a $(GHDLFLAGS) $(VHDL_RTL) $(VHDL_TB)


clean: force
	@rm -f $(WORKDIR)/*.cf $(VCDDIR)/*.vcd *.cf *.vcd


force:
