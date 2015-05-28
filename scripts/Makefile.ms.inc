axi-srcs = $(wildcard $(srcrootdir)/axi/*.vhd)
axi-vsrcs = $(wildcard $(srcrootdir)/axi/*.v)
axi-tags = $(patsubst $(srcrootdir)/axi/%.vhd,$(buildrootdir)/axi_lib/%.tag,$(axi-srcs)) $(patsubst $(srcrootdir)/axi/%.v,$(buildrootdir)/axi_lib/%.tag,$(axi-vsrcs))
$(axi-tags): $(buildrootdir)/axi_lib/exists
axi_lib: $(axi-tags)
axi_lib.axi_pkg: $(buildrootdir)/axi_lib/axi_pkg.tag
$(buildrootdir)/axi_lib/axi_pkg.tag: $(srcrootdir)/axi/axi_pkg.vhd

axi_register-srcs = $(wildcard $(srcrootdir)/axi_register/*.vhd)
axi_register-vsrcs = $(wildcard $(srcrootdir)/axi_register/*.v)
axi_register-tags = $(patsubst $(srcrootdir)/axi_register/%.vhd,$(buildrootdir)/axi_register_lib/%.tag,$(axi_register-srcs)) $(patsubst $(srcrootdir)/axi_register/%.v,$(buildrootdir)/axi_register_lib/%.tag,$(axi_register-vsrcs))
$(axi_register-tags): $(buildrootdir)/axi_register_lib/exists
axi_register_lib: $(axi_register-tags)
axi_register_lib.axi_register_master: $(buildrootdir)/axi_register_lib/axi_register_master.tag
$(buildrootdir)/axi_register_lib/axi_register_master.tag: $(srcrootdir)/axi_register/axi_register_master.vhd
axi_register_lib.axi_register: $(buildrootdir)/axi_register_lib/axi_register.tag
$(buildrootdir)/axi_register_lib/axi_register.tag: $(srcrootdir)/axi_register/axi_register.vhd
axi_register_lib.axi_register_wrapper: $(buildrootdir)/axi_register_lib/axi_register_wrapper.tag
$(buildrootdir)/axi_register_lib/axi_register_wrapper.tag: $(srcrootdir)/axi_register/axi_register_wrapper.vhd
$(buildrootdir)/axi_register_lib/axi_register.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/utils.tag \
$(buildrootdir)/axi_lib/axi_pkg.tag
$(buildrootdir)/axi_register_lib/axi_register_wrapper.tag: \
$(buildrootdir)/axi_lib/axi_pkg.tag \
$(buildrootdir)/axi_register_lib/axi_register.tag

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

global-srcs = $(wildcard $(srcrootdir)/global/*.vhd)
global-vsrcs = $(wildcard $(srcrootdir)/global/*.v)
global-tags = $(patsubst $(srcrootdir)/global/%.vhd,$(buildrootdir)/global_lib/%.tag,$(global-srcs)) $(patsubst $(srcrootdir)/global/%.v,$(buildrootdir)/global_lib/%.tag,$(global-vsrcs))
$(global-tags): $(buildrootdir)/global_lib/exists
global_lib: $(global-tags)
global_lib.global: $(buildrootdir)/global_lib/global.tag
$(buildrootdir)/global_lib/global.tag: $(srcrootdir)/global/global.vhd
global_lib.numeric_std: $(buildrootdir)/global_lib/numeric_std.tag
$(buildrootdir)/global_lib/numeric_std.tag: $(srcrootdir)/global/numeric_std.vhd
global_lib.sim_utils_sim: $(buildrootdir)/global_lib/sim_utils_sim.tag
$(buildrootdir)/global_lib/sim_utils_sim.tag: $(srcrootdir)/global/sim_utils_sim.vhd
global_lib.sim_utils: $(buildrootdir)/global_lib/sim_utils.tag
$(buildrootdir)/global_lib/sim_utils.tag: $(srcrootdir)/global/sim_utils.vhd
global_lib.utils: $(buildrootdir)/global_lib/utils.tag
$(buildrootdir)/global_lib/utils.tag: $(srcrootdir)/global/utils.vhd
$(buildrootdir)/global_lib/global.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag
$(buildrootdir)/global_lib/sim_utils.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag \
$(buildrootdir)/global_lib/utils.tag
$(buildrootdir)/global_lib/sim_utils_sim.tag: \
$(buildrootdir)/random_lib/rnd.tag \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag \
$(buildrootdir)/global_lib/sim_utils.tag
$(buildrootdir)/global_lib/utils.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/global_lib/global.tag

main-srcs = $(wildcard $(srcrootdir)/main/*.vhd)
main-vsrcs = $(wildcard $(srcrootdir)/main/*.v)
main-tags = $(patsubst $(srcrootdir)/main/%.vhd,$(buildrootdir)/main_lib/%.tag,$(main-srcs)) $(patsubst $(srcrootdir)/main/%.v,$(buildrootdir)/main_lib/%.tag,$(main-vsrcs))
$(main-tags): $(buildrootdir)/main_lib/exists
main_lib: $(main-tags)
main_lib.ac: $(buildrootdir)/main_lib/ac.tag
$(buildrootdir)/main_lib/ac.tag: $(srcrootdir)/main/ac.vhd
main_lib.buffer: $(buildrootdir)/main_lib/buffer.tag
$(buildrootdir)/main_lib/buffer.tag: $(srcrootdir)/main/buffer.vhd
main_lib.translate: $(buildrootdir)/main_lib/translate.tag
$(buildrootdir)/main_lib/translate.tag: $(srcrootdir)/main/translate.vhd

random-srcs = $(wildcard $(srcrootdir)/random/*.vhd)
random-vsrcs = $(wildcard $(srcrootdir)/random/*.v)
random-tags = $(patsubst $(srcrootdir)/random/%.vhd,$(buildrootdir)/random_lib/%.tag,$(random-srcs)) $(patsubst $(srcrootdir)/random/%.v,$(buildrootdir)/random_lib/%.tag,$(random-vsrcs))
$(random-tags): $(buildrootdir)/random_lib/exists
random_lib: $(random-tags)
random_lib.random_pkg: $(buildrootdir)/random_lib/random_pkg.tag
$(buildrootdir)/random_lib/random_pkg.tag: $(srcrootdir)/random/random_pkg.vhd
random_lib.rnd: $(buildrootdir)/random_lib/rnd.tag
$(buildrootdir)/random_lib/rnd.tag: $(srcrootdir)/random/rnd.vhd
$(buildrootdir)/random_lib/rnd.tag: \
$(buildrootdir)/global_lib/numeric_std.tag \
$(buildrootdir)/random_lib/random_pkg.tag

sim-srcs = $(wildcard $(srcrootdir)/sim/*.vhd)
sim-vsrcs = $(wildcard $(srcrootdir)/sim/*.v)
sim-tags = $(patsubst $(srcrootdir)/sim/%.vhd,$(buildrootdir)/sim_lib/%.tag,$(sim-srcs)) $(patsubst $(srcrootdir)/sim/%.v,$(buildrootdir)/sim_lib/%.tag,$(sim-vsrcs))
$(sim-tags): $(buildrootdir)/sim_lib/exists
sim_lib: $(sim-tags)
sim_lib.cell_sim: $(buildrootdir)/sim_lib/cell_sim.tag
$(buildrootdir)/sim_lib/cell_sim.tag: $(srcrootdir)/sim/cell_sim.vhd
sim_lib.pack_cell: $(buildrootdir)/sim_lib/pack_cell.tag
$(buildrootdir)/sim_lib/pack_cell.tag: $(srcrootdir)/sim/pack_cell.vhd

all-tags =  $(axi-tags) $(axi_register-tags) $(celloux-tags) $(global-tags) $(main-tags) $(random-tags) $(sim-tags)
doc-srcs =  $(axi-srcs) $(axi_register-srcs) $(celloux-srcs) $(global-srcs) $(main-srcs) $(random-srcs) $(sim-srcs)
doc-vsrcs =  $(axi-vsrcs) $(axi_register-vsrcs) $(celloux-vsrcs) $(global-vsrcs) $(main-vsrcs) $(random-vsrcs) $(sim-vsrcs)
$(vhdocldir)/done: $(doc-srcs)
