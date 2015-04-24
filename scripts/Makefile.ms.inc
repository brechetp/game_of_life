celloux-srcs = $(wildcard $(srcrootdir)/celloux/*.vhd)
celloux-vsrcs = $(wildcard $(srcrootdir)/celloux/*.v)
celloux-tags = $(patsubst $(srcrootdir)/celloux/%.vhd,$(buildrootdir)/celloux_lib/%.tag,$(celloux-srcs)) $(patsubst $(srcrootdir)/celloux/%.v,$(buildrootdir)/celloux_lib/%.tag,$(celloux-vsrcs))
$(celloux-tags): $(buildrootdir)/celloux_lib/exists
celloux_lib: $(celloux-tags)
celloux_lib.cell: $(buildrootdir)/celloux_lib/cell.tag
$(buildrootdir)/celloux_lib/cell.tag: $(srcrootdir)/celloux/cell.vhd
celloux_lib.pack_cell: $(buildrootdir)/celloux_lib/pack_cell.tag
$(buildrootdir)/celloux_lib/pack_cell.tag: $(srcrootdir)/celloux/pack_cell.vhd
$(buildrootdir)/celloux_lib/cell.tag: $(buildrootdir)/celloux_lib/pack_cell.tag

sim-srcs = $(wildcard $(srcrootdir)/sim/*.vhd)
sim-vsrcs = $(wildcard $(srcrootdir)/sim/*.v)
sim-tags = $(patsubst $(srcrootdir)/sim/%.vhd,$(buildrootdir)/sim_lib/%.tag,$(sim-srcs)) $(patsubst $(srcrootdir)/sim/%.v,$(buildrootdir)/sim_lib/%.tag,$(sim-vsrcs))
$(sim-tags): $(buildrootdir)/sim_lib/exists
sim_lib: $(sim-tags)

all-tags =  $(celloux-tags) $(sim-tags)
doc-srcs =  $(celloux-srcs) $(sim-srcs)
doc-vsrcs =  $(celloux-vsrcs) $(sim-vsrcs)
$(vhdocldir)/done: $(doc-srcs)
