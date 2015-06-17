-- we try to test the addr_ctrl
--
use WORK.sim_pkg.all;
library address_controller_lib;

library axi_lib;
use axi_lib.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

library address_controller_lib;
use address_controller_lib.addr_ctrl_pkg.all;

library celloux_lib;
use celloux_lib.cell_pkg.all;

library global_lib;
use global_lib.numeric_std.all;
use global_lib.utils.all;

entity addr_ctrl_sim is

end entity addr_ctrl_sim;

architecture sim of addr_ctrl_sim is
  signal aclk:                          std_ulogic;
  signal aresetn:                       std_ulogic := '0';
  signal stop_sim:                      std_ulogic;
  signal s0_axi_araddr:                 std_logic_vector(11 downto 0);
  signal s0_axi_arprot:                 std_logic_vector(2 downto 0);
  signal s0_axi_arvalid:                std_logic;
  signal s0_axi_rready:                 std_logic;
  -- Write address channel
  signal s0_axi_awaddr:                 std_logic_vector(11 downto 0);
  signal s0_axi_awprot:                 std_logic_vector(2 downto 0);
  signal s0_axi_awvalid:                std_logic;
  signal s0_axi_wdata:                  std_logic_vector(31 downto 0);
  signal s0_axi_wstrb:                  std_logic_vector(3 downto 0);
  signal s0_axi_wvalid:                 std_logic;
  -- Write response channel
  signal s0_axi_bready:                 std_logic;
  -------------------------------
  -- Outputs (slave to master) --
  -------------------------------
  -- Read address channel
  signal s0_axi_arready:                std_logic;
  -- Read data channel
  signal s0_axi_rdata:                  std_logic_vector(31 downto 0);
  signal s0_axi_rresp:                  std_logic_vector(1 downto 0);
  signal s0_axi_rvalid:                 std_logic;
  -- Write address channel
  signal s0_axi_awready:                std_logic;
  -- Write data channel
  signal s0_axi_wready:                 std_logic;
  -- Write response channel
  signal s0_axi_bvalid:                 std_logic;
  signal s0_axi_bresp:                  std_logic_vector(1 downto 0);

  ---------------------------
  -- AXI master port m_axi --
  ---------------------------
  -------------------------------
  -- Outputs (slave to master) --
  -------------------------------
  -- Read address channel
  signal m_axi_arid:                    std_logic_vector(5 downto 0);
  signal m_axi_araddr:                  std_logic_vector(31 downto 0);
  signal m_axi_arlen:                   std_logic_vector(3 downto 0);
  signal m_axi_arsize:                  std_logic_vector(2 downto 0);
  signal m_axi_arburst:                 std_logic_vector(1 downto 0);
  signal m_axi_arlock:                  std_logic_vector(1 downto 0);
  signal m_axi_arcache:                 std_logic_vector(3 downto 0);
  signal m_axi_arprot:                  std_logic_vector(2 downto 0);
  signal m_axi_arqos:                   std_logic_vector(3 downto 0);
  signal m_axi_arvalid:                 std_logic;
  -- Read data channel
  signal m_axi_rready:                  std_logic;
  -- Write address channel
  signal m_axi_awid:                    std_logic_vector(5 downto 0);
  signal m_axi_awaddr:                  std_logic_vector(31 downto 0);
  signal m_axi_awlen:                   std_logic_vector(3 downto 0);
  signal m_axi_awsize:                  std_logic_vector(2 downto 0);
  signal m_axi_awburst:                 std_logic_vector(1 downto 0);
  signal m_axi_awlock:                  std_logic_vector(1 downto 0);
  signal m_axi_awcache:                 std_logic_vector(3 downto 0);
  signal m_axi_awprot:                  std_logic_vector(2 downto 0);
  signal m_axi_awqos:                   std_logic_vector(3 downto 0);
  signal m_axi_awvalid:                 std_logic;
  -- Write data channel
  signal m_axi_wid:                     std_logic_vector(5 downto 0);
  signal m_axi_wdata:                   std_logic_vector(63 downto 0);
  signal m_axi_wstrb:                   std_logic_vector(7 downto 0);
  signal m_axi_wlast:                   std_logic;
  signal m_axi_wvalid:                  std_logic;
  -- Write response channel
  signal m_axi_bready:                  std_logic;
  ------------------------------
  -- Inputs (slave to master) --
  ------------------------------
  -- Read address channel
  signal m_axi_arready:                 std_logic;
  -- Read data channel
  signal m_axi_rid:                     std_logic_vector(5 downto 0);
  signal m_axi_rdata:                   std_logic_vector(63 downto 0);
  signal m_axi_rresp:                   std_logic_vector(1 downto 0);
  signal m_axi_rlast:                   std_logic;
  signal m_axi_rvalid:                  std_logic;
  -- Write address channel
  signal m_axi_awready:                 std_logic;
  -- Write data channel
  signal m_axi_wready:                  std_logic;
  -- Write response channel
  signal m_axi_bvalid:                  std_logic;
  signal m_axi_bid:                     std_logic_vector(5 downto 0);
  signal m_axi_bresp:                   std_logic_vector(1 downto 0);
  signal write_vector_from_addr_ctrl:   cell_vector(0 to N_CELL-3);
  signal read_vector_from_addr_ctrl:    cell_vector(0 to N_CELL-1);

  signal test_height:                   integer;
  signal test_width:                    integer;
  signal data:                          data_table;
  signal gen:                           std_ulogic := '0'; -- if set the read data is random, else only 1


  signal read_state:                    READ_STATE_TYPE;
  signal write_state:                   WRITE_STATE_TYPE;
  signal addr_read_state:               ADDR_CTRL_READ_STATE;
  signal addr_write_state:              ADDR_CTRL_WRITE_STATE; 
  signal computation_start:             std_ulogic;
  signal global_start:                  std_ulogic;
  signal colored_cells:                 cell_table;
  --signal rready_fool:                   std_ulogic;

begin

  i_addr_ctrl: entity address_controller_lib.addr_ctrl(window)
  port map(
    aclk                            => aclk,
    aresetn                         => aresetn,
    s0_axi_araddr                   => s0_axi_araddr,
    s0_axi_arprot                   => s0_axi_arprot,
    s0_axi_arvalid                  => s0_axi_arvalid,
    -- Read data channel
    s0_axi_rready                   => s0_axi_rready,
    -- Write address channel
    s0_axi_awaddr                   => s0_axi_awaddr,
    s0_axi_awprot                   => s0_axi_awprot,
    s0_axi_awvalid                  => s0_axi_awvalid,
    -- Write data channel
    s0_axi_wdata                    => s0_axi_wdata,
    s0_axi_wstrb                    => s0_axi_wstrb,
    s0_axi_wvalid                   => s0_axi_wvalid,
    -- Write response channel
    s0_axi_bready                   => s0_axi_bready,
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    s0_axi_arready                  => s0_axi_arready,
    -- Read data channel
    s0_axi_rdata                    => s0_axi_rdata,
    s0_axi_rresp                    => s0_axi_rresp,
    s0_axi_rvalid                   => s0_axi_rvalid,
    -- Write address channel
    s0_axi_awready                  => s0_axi_awready,
    -- Write data channel
    s0_axi_wready                   => s0_axi_wready,
    -- Write response channel
    s0_axi_bvalid                   => s0_axi_bvalid,
    s0_axi_bresp                    => s0_axi_bresp,

    ---------------------------
    -- AXI master port m_axi --
    ---------------------------
    -------------------------------
    -- Outputs (slave to master) --
    -------------------------------
    -- Read address channel
    m_axi_arid                      => m_axi_arid,
    m_axi_araddr                    => m_axi_araddr,
    m_axi_arlen                     => m_axi_arlen,
    m_axi_arsize                    => m_axi_arsize,
    m_axi_arburst                   => m_axi_arburst,
    m_axi_arlock                    => m_axi_arlock,
    m_axi_arcache                   => m_axi_arcache,
    m_axi_arprot                    => m_axi_arprot,
    m_axi_arqos                     => m_axi_arqos,
    m_axi_arvalid                   => m_axi_arvalid,
    -- Read data channel
    m_axi_rready                    => m_axi_rready,
    -- Write address channel
    m_axi_awid                      => m_axi_awid,
    m_axi_awaddr                    => m_axi_awaddr,
    m_axi_awlen                     => m_axi_awlen,
    m_axi_awsize                    => m_axi_awsize,
    m_axi_awburst                   => m_axi_awburst,
    m_axi_awlock                    => m_axi_awlock,
    m_axi_awcache                   => m_axi_awcache,
    m_axi_awprot                    => m_axi_awprot,
    m_axi_awqos                     => m_axi_awqos,
    m_axi_awvalid                   => m_axi_awvalid,
    -- Write data channel
    m_axi_wid                       => m_axi_wid,
    m_axi_wdata                     => m_axi_wdata,
    m_axi_wstrb                     => m_axi_wstrb,
    m_axi_wlast                     => m_axi_wlast,
    m_axi_wvalid                    => m_axi_wvalid,
    -- Write response channel
    m_axi_bready                    => m_axi_bready,
    ------------------------------
    -- Inputs (slave to master) --
    ------------------------------
    -- Read address channel
    m_axi_arready                   => m_axi_arready,
    -- Read data channel
    m_axi_rid                       => m_axi_rid,
    m_axi_rdata                     => m_axi_rdata,
    m_axi_rresp                     => m_axi_rresp,
    m_axi_rlast                     => m_axi_rlast,
    m_axi_rvalid                    => m_axi_rvalid,
    -- Write address channel
    m_axi_awready                   => m_axi_awready,
    -- Write data channel
    m_axi_wready                    => m_axi_wready,
    -- Write response channel
    m_axi_bvalid                    => m_axi_bvalid,
    m_axi_bid                       => m_axi_bid,
    m_axi_bresp                     => m_axi_bresp
  );

  clk_gen: process
  begin
    aresetn <= '1' after 40 ns;
    aclk <= '1';
    wait for 10 ns;
    aclk <= '0';
    wait for 10 ns;
    if stop_sim = '1' then
      wait;
    end if;
  end process;

  data <= gen_random_data_table(0) when (gen = '1') else -- random read input generation at CC #5
          white_cells;

  colored_cells <= coloring(data);

  order_generator: process(aclk)
    variable cpt: integer :=0;
    begin
      if aresetn = '0' then
        cpt := 0;
      elsif aclk = '1' then
        cpt := cpt +1;
        s0_axi_awvalid <= '0';
        s0_axi_wvalid  <= '0';
        s0_axi_bready  <= '1';
        if cpt = 5 then
          gen               <= '1'; -- random input
          s0_axi_awvalid    <= '1';
          s0_axi_wvalid     <= '1';
          s0_axi_awaddr     <= "000000000000"; -- height
          s0_axi_wdata      <= std_logic_vector(to_unsigned(10, 32)); -- data height
        elsif cpt = 10 then
          s0_axi_awvalid    <= '1';
          s0_axi_wvalid     <= '1';
          s0_axi_awaddr     <= "000000000100"; -- width
          s0_axi_wdata      <= std_logic_vector(to_unsigned(160, 32)); -- data height
        elsif cpt = 15 then
          s0_axi_awvalid    <= '1';
          s0_axi_wvalid     <= '1';
          s0_axi_awaddr     <= "000000001100"; -- color
          s0_axi_wdata      <= "00000000011000000000110000000011";
        elsif cpt = 20 then
          s0_axi_awvalid    <= '1';
          s0_axi_wvalid     <= '1';
          s0_axi_awaddr     <= "000000001000"; --start
          s0_axi_wdata      <= "00000000000000000000000000000001";
        end if;
        if cpt = 100000 then
          stop_sim <= '1';
        end if;
      end if;
  end process order_generator;

  slave_read: process(aclk)
    variable count: natural range 0 to 10;
    variable request_id: integer range -1 to data'length - 1;
    variable read_size: integer range 0 to 15;
  begin
    if aclk = '1' then
      if aresetn = '0' then
	m_axi_arready <= '1';
	-- Read data channel
	m_axi_rid <= (others => '0');
	m_axi_rdata <= (others => '0');
	m_axi_rresp <= std_logic_vector(axi_resp_okay);
        m_axi_rlast <= '0';
	m_axi_rvalid <= '0';
        count := 0;
        request_id := -1;
	-- Writ

      else
        m_axi_rlast <= '0';
        m_axi_rvalid <= '0';
        case read_state is
          when R_IDLE =>
            if m_axi_arvalid = '1' then
              read_size := to_integer(unsigned(m_axi_arlen));
              read_state <= SEND;
              count := 0;
              request_id := request_id+1;
            end if;

          when SEND =>
            if m_axi_rready = '1' then
              m_axi_rdata <= data(request_id)(count); -- data is a matrix RQ_NUM*88
              m_axi_rvalid <= '1';
              if count = read_size then
                m_axi_rlast <= '1';
                if request_id = data'length - 1 then
                  request_id := -1;
                end if;
                read_state <= R_IDLE;
              end if;
              count := count + 1;
            end if;
        end case;
      end if;
    end if;
  end process slave_read;

  slave_write: process(aclk)
  begin
    if aclk = '1' then
     if aresetn = '0' then
	m_axi_awready             <= '1';
	-- Write data channel
	m_axi_wready              <= '0';
	-- Write response channel
	m_axi_bvalid              <= '1';
	m_axi_bid                 <= (others => '0');
	m_axi_bresp               <= std_logic_vector(axi_resp_okay);
      else

        m_axi_wready <= '0';
        case write_state is
          when W_IDLE =>
            if m_axi_awvalid = '1' then
              write_state <= WRITE;
            end if;

          when WRITE =>
            m_axi_wready <= '1';
            if m_axi_wlast = '1' then
              write_state <= W_IDLE;
            end if;
        end case;
      end if;
    end if;
  end process slave_write;
end architecture;








         




