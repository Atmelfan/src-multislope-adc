-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity delta_sigma_adc is
    generic(
        TOPOLOGY :string := "NETWORK";

        -- # Lowpass filter settings
        -- Filter architecture
        -- * "BOXCAR" => Average filter
        -- * "SINC" => SincN filter, where N = LPF_ORDER
        LPF_ARCH: string := "BOXCAR";
        -- Filter 'order'
        -- * BOXCAR => Numberof bits to cut
        -- * SINC => Number of differentiator/integrator stages   
        LPF_ORDER : natural := 3;
        -- Accumulator depth
        LPF_ACCUM : natural := 10;

        -- # AXI4 stream output settings
        -- TDATA width in bytes,data is always 
        -- right adjusted within stream
        AXI_TDATA_NBYTES: natural := 2;
        -- 

    );
  port (
    clk, enable: in std_logic;

    -- 
    analog_cmp : in std_logic;
    analog_out: out std_logic;

    -- AXI4 stream output
    aclk, aresetn : in std_logic;
    -- Data channel
    tvalid : out std_logic;
    tready : in std_logic;
    tdata : out std_logic(AXI_TDATA_NBYTES*8 - 1 downto 0);

  );
end delta_sigma_adc ;

architecture arch of delta_sigma_adc is

    signal filter_reset : std_logic;

begin

    filter_reset <= enable and aresetn;



end architecture ; -- arch