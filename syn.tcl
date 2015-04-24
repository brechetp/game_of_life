#########################
# Variables definitions #
#########################

# Edit the following definitions to reflect your constraints

# The target clock period (in nano-seconds)
set clock_period 20.0
# Name of input clock (comment out if combinatorial design)
set clock_name clk
# Name of the top-level entity
set top_level_entity cell
# List of VHDL source files
set vhdl_source_files { pack_cell.vhd cell.vhd }

# In case you know what you are doing and you know what the following variables
# do, adapt their values to your needs. Else, leave them as they are, the
# default values are reasonable ones.

# Search path for libraries, library definitions
set_app_var target_library saed32rvt_tt0p85v25c.db
set edk ${synopsys_root}/../../EDK/SAED32_EDK/lib
set search_path [concat $search_path ${edk}/stdcell_rvt/db_ccs ${edk}/stdcell_rvt/db_nldm ${edk}/stdcell_hvt/db_ccs ${edk}/stdcell_hvt/db_nldm]
set link_library  [list * $target_library]
set symbol_library ""
# Maximum number of CPU cores to use
set_host_options -max_cores 8
# Generate HTML log file
set_app_var html_log_enable true
# Name of HTML log file
set_app_var html_log_filename dc_log.html
# External input delay
set input_delay [ expr $clock_period / 4 ]
# External output delay
set output_delay [ expr $clock_period / 4 ]
# Library cell driving all primary inputs but the clock
set driving_cell "DFFX2_RVT"
# Load capacitance on outputs (fF)
set output_load 2
# Maximum area (comment if no area constraint)
# set max_area 100

#######################################
# Run the whole synthesis design flow #
#######################################

# You shouldn't change anything after this line. But of course if you know what
# you're doing...

# Read HDL files and elaborate
foreach d $vhdl_source_files {
	analyze -format vhdl -library work ../$d
}
elaborate $top_level_entity
if { [current_design] == "" } {
	exit 1
}

# Set timing constraints
if ![ info exists clock_name ] {
	set clock_name virtual_clock
}
if {[sizeof_collection [get_ports $clock_name]] > 0} {
	create_clock -period $clock_period $clock_name
} else {
	create_clock -period $clock_period -name $clock_name
}
set_input_delay -clock $clock_name $input_delay [all_inputs]
set_output_delay -clock $clock_name $output_delay [all_outputs]

# Set design constraints
set_driving_cell -lib_cell DFFX2_RVT [all_inputs]
# If real clock, set infinite drive strength
if {[sizeof_collection [get_ports $clock_name]] > 0} {
	set_drive 0 $clock_name
}
set_load $output_load [all_outputs]
if [ info exists max_area ] {
	set_max_area $max_area
}

# Turn on auto wire load selection (library must support this feature)
set auto_wire_load_selection true

# Check design
check_design

# Synthesize
compile

# Reports
echo "*******************"
echo "*** AREA REPORT ***"
echo "*******************"
report_area
report_area > $top_level_entity.area
echo "*********************"
echo "*** TIMING REPORT ***"
echo "*********************"
report_timing
report_timing > $top_level_entity.timing

# Write output files
write_file -format verilog -hierarchy -output $top_level_entity.v $top_level_entity
write_file -format ddc -hierarchy -output $top_level_entity.ddc $top_level_entity

# Quit
quit

# Target technology libraries: in 32/28 nm node, the libraries are named according
# the following syntax:
#
#   saed32Xvt_YYVpVVvTTTc.db
#
# where:
#
# - Xvt = hvt, rvt or lvt, for high, regular and low voltage threshold. The
#   higher the voltage threshold, the slower the library and the lower the
#   static power.
# - YY = ff, tt or ss, for fast-fast, typical-typical and slow-slow, 3 different
#   characterization corners for 3 different manufacturing qualities of N-P
#   transistors. A fast-fast chip is faster than a slow-slow but if the
#   synthesizer is asked to work in the fast-fast corner, it can be that, after
#   manufacturing, typical-typical and slow-slow chips are not fast enough and
#   must be discarded...
# - VpVVv = the power supply voltage used for characterization (in volts).
# - TTT = the temperature used for characterization (in Celsius degrees). If the
#   first character in TTT is a 'n', the temperature is negative.
#
# Example: the saed32hvt_ss0p75v125c.db library is a high voltage threshold one
# (slower than regular or low voltage threshold) with low leakage power. It has
# been characterized for a slow-slow manufacturing process, with a 0.75 V
# voltage and at a 125 C temperature. Use it if you are more concerned with
# leakage power than speed and you want all your manufactured circuits, even the
# ones manufactured in the slow-slow corner, to operate normally with a rather
# low 0.75 V power supply and at a rather high 125 C temperature.
#
# The following libraries are available:
#
# saed32hvt_ff0p85v125c.db
# saed32hvt_ff0p85v25c.db
# saed32hvt_ff0p85vn40c.db
# saed32hvt_ff0p95v125c.db
# saed32hvt_ff0p95v25c.db
# saed32hvt_ff0p95vn40c.db
# saed32hvt_ff1p16v125c.db
# saed32hvt_ff1p16v25c.db
# saed32hvt_ff1p16vn40c.db
# saed32hvt_ss0p75v125c.db
# saed32hvt_ss0p75v25c.db
# saed32hvt_ss0p75vn40c.db
# saed32hvt_ss0p7v125c.db
# saed32hvt_ss0p7v25c.db
# saed32hvt_ss0p7vn40c.db
# saed32hvt_ss0p95v125c.db
# saed32hvt_ss0p95v25c.db
# saed32hvt_ss0p95vn40c.db
# saed32hvt_tt0p78v125c.db
# saed32hvt_tt0p78v25c.db
# saed32hvt_tt0p78vn40c.db
# saed32hvt_tt0p85v125c.db
# saed32hvt_tt0p85v25c.db
# saed32hvt_tt0p85vn40c.db
# saed32hvt_tt1p05v125c.db
# saed32hvt_tt1p05v25c.db
# saed32hvt_tt1p05vn40c.db
# saed32lvt_ff0p85v125c.db
# saed32lvt_ff0p85v125c.lib
# saed32lvt_ff0p85v25c.db
# saed32lvt_ff0p85v25c.lib
# saed32lvt_ff0p85vn40c.db
# saed32lvt_ff0p85vn40c.lib
# saed32lvt_ff0p95v125c.db
# saed32lvt_ff0p95v125c.lib
# saed32lvt_ff0p95v25c.db
# saed32lvt_ff0p95v25c.lib
# saed32lvt_ff0p95vn40c.db
# saed32lvt_ff0p95vn40c.lib
# saed32lvt_ff1p16v125c.db
# saed32lvt_ff1p16v125c.lib
# saed32lvt_ff1p16v25c.db
# saed32lvt_ff1p16v25c.lib
# saed32lvt_ff1p16vn40c.db
# saed32lvt_ff1p16vn40c.lib
# saed32lvt_ss0p75v125c.db
# saed32lvt_ss0p75v125c.lib
# saed32lvt_ss0p75v25c.db
# saed32lvt_ss0p75v25c.lib
# saed32lvt_ss0p75vn40c.db
# saed32lvt_ss0p75vn40c.lib
# saed32lvt_ss0p7v125c.db
# saed32lvt_ss0p7v125c.lib
# saed32lvt_ss0p7v25c.db
# saed32lvt_ss0p7v25c.lib
# saed32lvt_ss0p7vn40c.db
# saed32lvt_ss0p7vn40c.lib
# saed32lvt_ss0p95v125c.db
# saed32lvt_ss0p95v125c.lib
# saed32lvt_ss0p95v25c.db
# saed32lvt_ss0p95v25c.lib
# saed32lvt_ss0p95vn40c.db
# saed32lvt_ss0p95vn40c.lib
# saed32lvt_tt0p78v125c.db
# saed32lvt_tt0p78v125c.lib
# saed32lvt_tt0p78v25c.db
# saed32lvt_tt0p78v25c.lib
# saed32lvt_tt0p78vn40c.db
# saed32lvt_tt0p78vn40c.lib
# saed32lvt_tt0p85v125c.db
# saed32lvt_tt0p85v125c.lib
# saed32lvt_tt0p85v25c.db
# saed32lvt_tt0p85v25c.lib
# saed32lvt_tt0p85vn40c.db
# saed32lvt_tt0p85vn40c.lib
# saed32lvt_tt1p05v125c.db
# saed32lvt_tt1p05v125c.lib
# saed32lvt_tt1p05v25c.db
# saed32lvt_tt1p05v25c.lib
# saed32lvt_tt1p05vn40c.db
# saed32lvt_tt1p05vn40c.lib
# saed32rvt_ff0p85v125c.db
# saed32rvt_ff0p85v25c.db
# saed32rvt_ff0p85vn40c.db
# saed32rvt_ff0p95v125c.db
# saed32rvt_ff0p95v25c.db
# saed32rvt_ff0p95vn40c.db
# saed32rvt_ff1p16v125c.db
# saed32rvt_ff1p16v25c.db
# saed32rvt_ff1p16vn40c.db
# saed32rvt_ss0p75v125c.db
# saed32rvt_ss0p75v25c.db
# saed32rvt_ss0p75vn40c.db
# saed32rvt_ss0p7v125c.db
# saed32rvt_ss0p7v25c.db
# saed32rvt_ss0p7vn40c.db
# saed32rvt_ss0p95v125c.db
# saed32rvt_ss0p95v25c.db
# saed32rvt_ss0p95vn40c.db
# saed32rvt_tt0p78v125c.db
# saed32rvt_tt0p78v25c.db
# saed32rvt_tt0p78vn40c.db
# saed32rvt_tt0p85v125c.db
# saed32rvt_tt0p85v25c.db
# saed32rvt_tt0p85vn40c.db
# saed32rvt_tt1p05v125c.db
# saed32rvt_tt1p05v25c.db
# saed32rvt_tt1p05vn40c.db
#
# Example:
#
# saed32rvt_tt0p85v25c.db is a regular threshold voltage library, that is, it is
# designed for medium leakage power and medium speed. It has been characterized
# with a 0.85 volts power supply, at 25 C° and for a Typical-Typical
# manufacturing quality. Use this library if your design is more sensitive to
# leakage power than to speed, if you accept to drop the Slow-Slow samples after
# manufacturing and if you want your chips to operate in medium voltage and
# temperature conditions. Be warned, however: if your speed contraints are too
# tight, the synthesizer will have a much more difficult job to do; it may fail
# or end up with a larger silicon area than expected.
