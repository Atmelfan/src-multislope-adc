library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use IEEE.math_real.all;

entity tb_multislope is
    --
end entity;

architecture tb of tb_multislope is

    -- Clock = 50 MHz
    constant T : time := 20 ns;

    constant VREF : real := 7.0;
    constant IRES : real := 50.0E3;
    constant CINT : real := 1.0E-9;

    -- Testbench signals
    signal clk, rst : std_logic := '1';
    signal dut_start : std_logic;

    -- DUT signals
    signal dut_sel_vin, dut_sel_posvref, dut_sel_negvref : std_logic;
    signal dut_cmp_in : std_logic;
    signal dut_out : unsigned(23 downto 0);
    signal integrator_voltage, input_voltage, res : real;
begin

    -- Continuous clock
    process
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process;

    integrator_simulation : process (clk)
    variable delta: real;
    begin
        delta := 0.0;
        if rst = '1' then
            integrator_voltage <= 0.0;

        elsif rising_edge(clk) then
            if dut_sel_vin = '1' then
                delta := delta + 20.0E-9 * input_voltage/(IRES * CINT);
            end if;
            if dut_sel_posvref = '1' then
                delta := delta + 20.0E-9 * VREF/(IRES * CINT);
            end if;
            if dut_sel_negvref = '1' then
                delta := delta - 20.0E-9 * VREF/(IRES * CINT);
            end if;
            integrator_voltage <= integrator_voltage + delta;

            if integrator_voltage > 1.25 then
                dut_cmp_in <= '1';
            else
            dut_cmp_in <= '0';
            end if;
        end if;
    end process integrator_simulation;

    -- Reset = 1 for first clock cycle and then 0
    rst <= '1', '0' after T;
    dut_start <= '0', '1' after T * 1000;

    input_voltage <= 2.5;

    -- DUT
    DUT : entity work.multislope(arch)
    generic map(
        COUNTER_WIDTH => 32,
        RUNUP_PARTIAL_T => 10000
    )
    port map(
        clk => clk,
        rst => rst,

        start => dut_start,
        freerun => '1',

        -- Outputs

        -- Integration time in clock cycles
        int_t => to_unsigned(20000, 32),

        cmp_in => dut_cmp_in,

        -- Residue ADC
        adc_vout => (others => '0'),
        adc_conv => open,
        adc_ready => '1',

        -- Integrator switch control
        sel_vin => dut_sel_vin,
        sel_neg_vref => dut_sel_negvref,
        sel_pos_vref => dut_sel_posvref
    );

end tb; -- arch