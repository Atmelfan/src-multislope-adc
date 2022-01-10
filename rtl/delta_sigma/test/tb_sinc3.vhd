library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_sinc3 is
  --
end entity;

architecture tb of tb_sinc3 is

  -- Clock = 50 MHz
  constant T : time := 20 ns;

  -- Testbench signals
  signal clk, rst : std_logic := '1';

  -- DUT signals
  signal dut_in, word_clk : std_logic;
  signal dut_out : unsigned(23 downto 0);

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
  rst <= '1', '0' after T*5;

  --- DUT
  dut_in <= '1';

  filter : entity work.sinc3_filter(arch)
    generic map(
      WORD_WIDTH => 24,
      DECIMATION => 10
    )
    port map(
      rst => rst,

      -- 1 bit input
      in_data => dut_in,
      in_clk => clk,

      -- N bit output
      out_data => dut_out,
      out_clk => word_clk
    );

end tb; -- arch