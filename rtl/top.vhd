library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk : in std_logic;
    rst : in std_logic;
    LED_R, LED_G, LED_B : out std_logic);
end top;
architecture blink of top is
  signal counter : unsigned (25 downto 0);
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
end blink;