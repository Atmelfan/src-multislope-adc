-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.components.all;

entity top is
  port (
    clk : in std_logic;
    rst : in std_logic;
    LED_R, LED_G, LED_B : out std_logic;

    SPI_MISO : out std_logic;
    SPI_MOSI : in std_logic;
    SPI_SCK : in std_logic;
    SPI_SS : in std_logic
  );
end top;
architecture blink of top is
  signal counter : unsigned (25 downto 0);

  -- SPI Slave controller interface
  signal spi_adr : std_logic_vector(7 downto 0);
  signal spi_dati : std_logic_vector(7 downto 0);
  signal spi_dato : std_logic_vector(7 downto 0);
  signal spi_stb : std_logic;
  signal spi_rw : std_logic;
  signal spi_ack : std_logic;

begin
  process (clk, rst) is
  begin
    if rst = '1' then
      counter <= (others => '0');
    elsif rising_edge(clk) then
      counter <= counter + 1;
    end if;
  end process;

  LED_R <= counter(23);
  LED_G <= counter(24);
  LED_B <= counter(25);

  SPI_HW : SB_SPI
  generic map(
    BUS_ADDR74 => "0b0000"
  )
  port map(
    SBCLKI => clk, -- System bus: clock input
    SBRWI => spi_rw, -- System bus: read/write input
    SBSTBI => spi_stb, -- System bus: strobe signal

    SBADRI0 => spi_adr(0), -- System bus: control registers address
    SBADRI1 => spi_adr(1),
    SBADRI2 => spi_adr(2),
    SBADRI3 => spi_adr(3),
    SBADRI4 => spi_adr(4),
    SBADRI5 => spi_adr(5),
    SBADRI6 => spi_adr(6),
    SBADRI7 => spi_adr(7),

    SBDATI0 => spi_dati(0), -- System bus: data input
    SBDATI1 => spi_dati(1),
    SBDATI2 => spi_dati(2),
    SBDATI3 => spi_dati(3),
    SBDATI4 => spi_dati(4),
    SBDATI5 => spi_dati(5),
    SBDATI6 => spi_dati(6),
    SBDATI7 => spi_dati(7),

    SBDATO0 => spi_dato(0), -- System bus: data output
    SBDATO1 => spi_dato(1),
    SBDATO2 => spi_dato(2),
    SBDATO3 => spi_dato(3),
    SBDATO4 => spi_dato(4),
    SBDATO5 => spi_dato(5),
    SBDATO6 => spi_dato(6),
    SBDATO7 => spi_dato(7),

    SBACKO => spi_ack, -- System bus: acknowledgement
    SPIIRQ => open, -- SPI interrupt output
    SPIWKUP => open, -- SPI wake up from standby signal
    MI => '0', -- Master input --> from PAD
    SO => SPI_MISO, -- Slave output --> to PAD
    SOE => open, -- Slave output enable --> to PAD (active high)
    SI => SPI_MOSI, -- Slave input --> from PAD
    MO => open, -- Master output --> to PAD
    MOE => open, -- Master output enable --> to PAD (active high)
    SCKI => SPI_SCK, -- Slave clock input --> from PAD
    SCKO => open, -- Slave clock output --> to PAD
    SCKOE => open, -- Slave clock output enable  --> to PAD (active high)
    SCSNI => SPI_SS, -- Slave chip select input --> from PAD
    MCSNO0 => open, -- Master chip select output --> to PAD
    MCSNO1 => open,
    MCSNO2 => open,
    MCSNO3 => open,
    MCSNOE0 => open, -- Master chip select output enable --> to PAD (active high)
    MCSNOE1 => open,
    MCSNOE2 => open,
    MCSNOE3 => open
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
      awvalid => open,
      awready => '1',
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
      arvalid => open,
      arready => '1',
      araddr => open,
      arprot => open,
      -- Read data channel
      rvalid => '1',
      rready => open,
      rdata => x"12_34_56_78",
      rresp => "00"
    );
end blink;