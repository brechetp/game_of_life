## Local definitions for the project. Adapt to your own project.
LIBDIR		= myLib
TOP		= cell_sim
SYNSRC		= cell.vhd
SYNTOP		= cell

## Dependencies of the project. If file foo.vhd depends on file bar.vhd (that
## is, bar.vhd must be compiled before foo.vhd), add a line:
## .foo.tag: .bar.tag
.cell.tag: .pack_cell.tag
## If foo.vhd depends on several files bar1.vhd and bar2.vhd, add a line:
## .foo.tag: .bar1.tag .bar2.tag
##.g1_sim.tag: .g1.tag

## Standard definitions. You shouldn't need to edit anything below this line,
## unless you have a very good reason and you know exactly what you're doing.
MKLIB		= vlib
MAP		= vmap
COM		= vcom
COMFLAGS	= -ignoredefaultbinding -pedanticerrors -O5
SIM		= vsim
SIMFLAGS	=
SRCS		= $(wildcard *.vhd)
TAGS		= $(patsubst %.vhd,.%.tag,$(SRCS))
SYN		= dc_shell
SYNFLAGS	= -x 'source ../syn.tcl'

.PHONY: help all sim simi syn clean

help:
	@echo '"make" does intentionally nothing. Type:'
	@echo '  "make all" to compile all the VHDL source files'
	@echo '  "make sim" to compile and simulate in batch mode'
	@echo '  "make simi" to compile and simulate interactively'
	@echo '  "make syn" to synthesize and generate reports'
	@echo '  "make clean" to remove the generated files and restore the original distribution'

all: .$(TOP).tag

simi: SIMFLAGS += -do "add wave /*; run -all"
simi: .$(TOP).tag
	$(SIM) $(SIMFLAGS) $(TOP)

sim: SIMFLAGS += -c -do "run -all; quit"
sim: .$(TOP).tag
	$(SIM) $(SIMFLAGS) $(TOP)

.$(LIBDIR).libtag:
	$(MKLIB) $(LIBDIR)
	$(MAP) WORK $(LIBDIR)
	touch $@

.%.tag: %.vhd .$(LIBDIR).libtag
	$(COM) $(COMFLAGS) $<
	touch $@

syn: $(SYNTOP).dc-syn/$(SYNTOP).v

$(SYNTOP).dc-syn/$(SYNTOP).v: $(SYNSRC) syn.tcl
	@stamp=`date +'%s'`; \
	syndir="$(SYNTOP).dc-syn.$$stamp"; \
	mkdir $$syndir; \
	cd $$syndir; \
	$(SYN) $(SYNFLAGS); \
	cd ..; \
	syndir_link="$(SYNTOP).dc-syn"; \
	rm -f $$syndir_link; \
	ln -s $$syndir $$syndir_link; \
	echo "--------------------------------------------------------------------------------"; \
	echo "Results stored in $$syndir (linked to $$syndir_link)"; \
	echo "--------------------------------------------------------------------------------"

## Cleaning target.
clean:
	rm -rf $(TAGS) transcript vsim.wlf .$(LIBDIR).libtag modelsim.ini $(LIBDIR)
	rm -rf *~ $(SYNTOP).dc-syn $(SYNTOP).dc-syn.*
