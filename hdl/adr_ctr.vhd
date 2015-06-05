--
-- SimpleRegister4Zynq - This file is part of SimpleRegister4Zynq
-- Copyright (C) 2015 - Telecom ParisTech
--
-- This file must be used under the terms of the CeCILL.
-- This source file is licensed as described in the file COPYING, which
-- you should have received as part of this distribution.  The terms
-- are also available at
-- http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
--

library ieee;
use ieee.std_logic_1164.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

library axi_lib;
use axi_lib.axi_pkg.all;

entity adr_ctrl is
   port(
	aclk:		in std_ulogic;		-- Clock
	aresetn:	in std_ulogic;		-- Reset
   )
end entity adr_ctrl;

architecture adr_ctr of adr_ctrl is

	signal s_axi_m2s: 	axilite_gp_m2s;
	signal s_axi_s2m: 	axilite_gp_s2m;
	signal height: 		std_ulogic_vector(15 downto 0);
	signal width: 		std_ulogic_vector(15 downto 0);
	signal start: 		std_ulogic;
    	signal color: 		std_ulogic_vector(31 downto 0);
	signal waddress:	std_ulogic_vector(31 downto 0);
	signal raddress:	std_ulogic_vector(31 downto 0);
	signal wsize:		std_ulogic_vector(7 downto 0);
	signal rsiwe:		std_ulogic_vector(7 downto 0);
	signal ready_writing:	std_ulogic;
	signal read_request:	std_ulogic;
	signal in_cell_vector:	cell_vector;
	signal out_cell_vector:	cell_vector;
	signal done_reading:	std_ulogic;
	signal done_writing:	std_ulogic;
	signal write_offset:	integer range 0 to 79;

begin

	i_axi_register: entity work.axi_register
	port map(
		aclk       => aclk,
		aresetn    => aresetn,
		s_axi_m2s => s_axi_m2s,
		s_axi_s2m => s_axi_s2m,
		height => height,
		width => width,
		start => start,
		color => color
	);

	i_axi_register_master: entity work.axi_register_master
	port map(
		aclk		=> aclk,
		aresetn		=> aresetn,
		m_axi_m2s 	=> s_axi_m2s,
		m_axi_s2m 	=> s_axi_s2m,
		wadress 	=> waddress,
		raddress 	=> raddress,
		wsize		=> wsize,
		rsize		=> rsize,
		wc_vector	=> out_cell_vector,
		write_rq	=> ready_writing,
		read_rq		=> read_request,
		rc_vector	=> in_cell_vector,
		done_reading	=> done_reading,
		done_writing	=> done_writing,
		write_offset	=> write_offset
	);

	i_cell_ctrl: entity work.cell_ctrl
	port map(
		in_cell_vector	=> in_cell_vector,
		done_reading	=> done_reading,
		done_writing	=> done_writing,
		out_cell_vector	=> out_cell_vector,
		ready_writing	=> ready_writing,
		ready_reading	=> ready_reading
	);
