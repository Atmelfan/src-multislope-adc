library IEEE;
use IEEE.std_logic_1164.all;

entity ds_sampler is
    port (
        clk : in std_logic;

        --
        analog_cmp : in std_logic;
        analog_out : out std_logic;

        --
        digital_out : out std_logic
    );
end entity ds_sampler;

architecture rtl of ds_sampler is

begin

    --
    -- 
    sampling_element : process (clk)
    begin
        if rising_edge(clk) then
            digital_out <= analog_cmp;
            analog_out <= analog_cmp;
        end if;
    end process sampling_element;
end architecture rtl;