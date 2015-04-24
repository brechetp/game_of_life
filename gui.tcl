# Search path for libraries, library definitions
set_app_var target_library saed32rvt_tt0p85v25c.db
set edk ${synopsys_root}/../../EDK/SAED32_EDK/lib
set search_path [concat $search_path ${edk}/stdcell_rvt/db_ccs ${edk}/stdcell_rvt/db_nldm ${edk}/stdcell_hvt/db_ccs ${edk}/stdcell_hvt/db_nldm]
set link_library  [list * $target_library]
set symbol_library ""
read_ddc g1.ddc
gui_start
gui_create_schematic
