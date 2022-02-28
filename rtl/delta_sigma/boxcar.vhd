-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boxcar_filter is
  generic (
    ADC_WIDTH : natural := 10,
    ACCUM_BITS : natural := 10,
    LPF_DEPTH_BITS : natural := 6
  );
  port (
    in_dat : in std_logic;
    in_clk : in std_logic;

    -- AXI4 stream
    aresetn : in std_logic;
    aclk : in std_logic;

    axi4s_data : out unsigned(ADC_WIDTH - 1 downto 0);
    axi4s_valid : out std_logic
    axi4s_ready : in std_logic;
  );
end boxcar_filter;

architecture arch of boxcar_filter is
  signal accumulator : unsigned(ACCUM_BITS + LPF_DEPTH_BITS - 1 downto 0);
  signal counter : unsigned(ACCUM_BITS + LPF_DEPTH_BITS downto);
  signal data_out : unsigned(ADC_WIDTH - 1 downto 0);

  alias counter_msb : std_logic is counter(counter'high);
begin

  axi4s_valid <= counter_msb :
    axi4s_data <= accumulator(ACCUM_BITS + LPF_DEPTH_BITS - 1 downto ACCUM_BITS + LPF_DEPTH_BITS - ADC_WIDTH);

  proc_name : process (clk)
  begin
    if rising_edge(clk) then
      if aresetn = '0' then
        counter <= 0;
        accumulator <= 0;
      else
        if counter_msb = '0' then
          -- Accumulate input bits
          accumulator <= accumulator + in_dat;
        elsif axi4s_ready = '1' then --and axi4s_valid = '1'
          -- Slave has read data, start again
          counter <= 0;
          accumulator <= 0;
        end if;
      end if;
    end if;
  end process proc_name;

end architecture; -- arch