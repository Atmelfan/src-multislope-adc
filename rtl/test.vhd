-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.components.all;

entity test is
end entity;

architecture test_arch of test is

  -- Clock = 50 MHz
  constant T : time := 20 ns;

  signal clk, rst : std_logic;

  -- SPI Slave controller interface
  signal spi_adr : std_logic_vector(7 downto 0);
  signal spi_dati : std_logic_vector(7 downto 0);
  signal spi_dato : std_logic_vector(7 downto 0);
  signal spi_stb : std_logic;
  signal spi_rw : std_logic;
  signal spi_ack : std_logic;

  signal awvalid, awready, arvalid, arready : std_logic;

begin


  -- Continuous clock
  process
  begin
    clk <= '0';
    wait for T/2;
    clk <= '1';
    wait for T/2;
  end process;

  -- Reset = 1 for first clock cycle and then 0
  rst <= '1', '0' after T;

  awready <= awvalid after 2*T;
  arready <= arvalid after 2*T;

  -- Simulated SPI
  SPI_SIM : entity work.SIM_SPI
    generic map(
      BUS_ADDR74 => "0000"
    )
    port map(
      -- Control signals
      SBCLKI => clk,
      SBSTBI => spi_stb,
      SBRWI => spi_rw,
      SBACKO => spi_ack,

      -- Adress bus
      SBADRI => spi_adr,

      -- Data input bus
      SBDATI => spi_dati,
      -- Data output bus
      SBDATO => spi_dato
    );

  --SPI-AXI4-Lite bridge
  AXI4L_BRIDGE : entity work.axi4l_bridge
    port map(
      clk => clk,
      rst => rst,

      -- SPI interface
      spi_adr => spi_adr,
      spi_dati => spi_dati,
      spi_dato => spi_dato,
      spi_stb => spi_stb,
      spi_rw => spi_rw,
      spi_ack => spi_ack,

      -- AXI4-Lite
      aclk => open,
      aresetn => open,
      -- Write address channel
      awvalid => awvalid,
      awready => awready,
      awaddr => open,
      awprot => open,
      -- Write data channel
      wvalid => open,
      wready => '1',
      wdata => open,
      wstrb => open,
      -- Write response channel
      bvalid => '1',
      bready => open,
      bresp => "00",
      -- Read address channel
      arvalid => arvalid,
      arready => arready,
      araddr => open,
      arprot => open,
      -- Read data channel
      rvalid => '1',
      rready => open,
      rdata => x"12_34_56_78",
      rresp => "00"
    );
end;
