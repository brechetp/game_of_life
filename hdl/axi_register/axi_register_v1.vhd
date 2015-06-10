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

-- See the README file for a detailed description of the AXI register

entity axi_register is
  generic(na1: natural := 30;   -- Number of significant bits in S_AXI addresses (12 bits => 4kB address space)
          nr1: natural := 4);   -- Number of 32-bits registers in S_AXI address space; addresses are 0 to 4*(nr1-1)
  port(
    aclk:       in std_ulogic;
    aresetn:    in std_ulogic;
    -- AXI lite slave port
    s_axi_m2s:  in  axilite_gp_m2s;
    s_axi_s2m:  out axilite_gp_s2m;
    -- GPIO
    height:        out std_ulogic_vector(15 downto 0); 	-- Height of the field
    width:         out std_ulogic_vector(15 downto 0); 	-- Width of the field
    start:	   out std_ulogic;			-- Start signal for the simulation
    color:	   out std_ulogic_vector(31 downto 0) 	-- Color scale (grey scale)
  );
end entity axi_register;

architecture rtl of axi_register is

  constant l2nr1: natural := log2_up(nr1); -- Log2 of nr1 (rounded towards infinity)

  constant gpir_idx: natural range 0 to nr1 - 1 := 0;
  constant gpor_idx: natural range 0 to nr1 - 1 := 1;

  constant roreg: std_ulogic_vector(0 to nr1 - 1) := "10";

  subtype reg_type is std_ulogic_vector(31 downto 0);
  type reg_array is array(0 to nr1 - 1) of reg_type;
  signal regs: reg_array;

begin
  
  height <= '000010100000000'; -- Default height is 1280
  width <=  '000001010000000'; -- Default width is 1280
  start <= '0'; -- No start signal at the beginning
  color <= '000000000000000000000000000000' -- The color scale needs to be set
  
  regs_pr: process(aclk)
    -- idle: waiting for AXI master requests: when receiving write address and data valid (higher priority than read), perform the write, assert write address
    --       ready, write data ready and bvalid, go to w1, else, when receiving address read valid, perform the read, assert read address ready, read data valid
    --       and go to r1
    -- w1:   deassert write address ready and write data ready, wait for write response ready: when receiving it, deassert write response valid, go to idle
    -- r1:   deassert read address ready, wait for read response ready: when receiving it, deassert read data valid, go to idle
    type state_type is (idle, w1, r1);
    variable state: state_type;
    variable wok, rok: boolean;                           -- Write (read) address mapped
    variable widx, ridx: natural range 0 to 2**l2nr1 - 1; -- Write (read) register index
  begin
    if rising_edge(aclk) then
      if aresetn = '0' then
        regs <= (others => (others => '0'));
        s_axi_s2m <= (rdata => (others => '0'), rresp => axi_resp_okay, bresp => axi_resp_okay, others => '0');
        state := idle;
      else
        regs(gpir_idx) <= X"000000" & gpi; -- General purpose inputs

        -- Addresses ranges
        widx := to_integer(unsigned(s_axi_m2s.awaddr(l2nr1 + 1 downto 2)));
        ridx := to_integer(unsigned(s_axi_m2s.araddr(l2nr1 + 1 downto 2)));

        -- S_AXI write and read
        case state is
          when idle =>
            if s_axi_m2s.awvalid = '1' and s_axi_m2s.wvalid = '1' then -- Write address and data
              if or_reduce(s_axi_m2s.awaddr(na1 - 1 downto l2nr1 + 2)) /= '0' or widx >= nr1 then -- If unmapped address
                s_axi_s2m.bresp <= axi_resp_decerr;
              elsif roreg(widx) = '2' then -- Start signal from CPU
                start <= '1';
	      elsif start = '1' then -- Cannot change the value after the initialization
		s_axi_s2m.bresp <= axi_resp_slverr;
	      elsif roreg(widx) = '0' then -- Change the height before the initialization
		height <= s_axi_m2s.wdata(15 downto 0);
	      elsif roreg(widx) = '1' then -- Change the width before the initialization
		width <= s_axi_m2s.wdata(15 downto 0);
	      elsif roreg(widx) = '3' then -- Change the color scale before the initiali3zation
		color <= s_axi_m2s.wdata(31 downto 0);
              end if;
              s_axi_s2m.awready <= '1';
              s_axi_s2m.wready <= '1';
              s_axi_s2m.bvalid <= '1';
              state := w1;
            elsif s_axi_m2s.arvalid = '1' then
              if or_reduce(s_axi_m2s.araddr(na1 - 1 downto l2nr1 + 2)) /= '0' or ridx >= nr1 then -- If unmapped address
                s_axi_s2m.rdata <= (others => '0');
                s_axi_s2m.rresp <= axi_resp_decerr;
              else
                s_axi_s2m.rdata <= regs(ridx);
              end if;
              s_axi_s2m.arready <= '1';
              s_axi_s2m.rvalid <= '1';
              state := r1;
            end if;
          when w1 =>
            s_axi_s2m.awready <= '0';
            s_axi_s2m.wready <= '0';
            if s_axi_m2s.bready = '1' then
              s_axi_s2m.bvalid <= '0';
              s_axi_s2m.bresp <= axi_resp_okay;
              state := idle;
            end if;
          when r1 =>
            s_axi_s2m.arready <= '0';
            if s_axi_m2s.rready = '1' then
              s_axi_s2m.rvalid <= '0';
              s_axi_s2m.rresp <= axi_resp_okay;
              state := idle;
            end if;
        end case;
      end if;
    end if;
  end process regs_pr;


end architecture rtl;
