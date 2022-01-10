library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity delta_sigma_converter is
    generic (
        DATA_WIDTH : integer
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        -- Digital interface
        digital_out : out std_logic_vector(11 downto 0);
        digital_ready : out std_logic;

        -- Analog interface
        analog_cmp : in std_logic;
        analog_out : out std_logic
    );
end entity delta_sigma_converter;

architecture arch of delta_sigma_converter is

begin
    -- Comparator & sample
    modulator : process (clk, rst)
    begin
        if rst = '1' then

        elsif rising_edge(clk) then

        end if;
    end process modulator;

end architecture arch;