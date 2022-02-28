-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity multislope is
    generic (
        COUNTER_WIDTH : integer;
        RUNUP_PARTIAL_T : integer
    );
    port (
        clk, rst : in std_logic;

        start, freerun : in std_logic;

        -- Outputs

        -- Integration time in clock cycles
        int_t : in unsigned(COUNTER_WIDTH - 1 downto 0);

        cmp_in : in std_logic;

        -- Residue ADC
        adc_vout : in unsigned(11 downto 0);
        adc_conv : out std_logic;
        adc_ready : in std_logic;

        -- Integrator switch control
        sel_vin : out std_logic;
        sel_neg_vref : out std_logic;
        sel_pos_vref : out std_logic
    );
end entity multislope;

architecture arch of multislope is
    type slope_state is (
        -- Idle, hold charge
        HOLD,
        -- Sample starting charge
        SAMPLE_PREVIOUS,
        -- Runup phase
        RUNUP,
        RUNUP_ADD,
        RUNUP_SUB,
        -- Rundown phase
        RUNDOWN_ADD,
        RUNDOWN_SUB,
        -- Sample remainder charge
        SAMPLE_REMAINDER
    );

    type switch_state is (
        --
        S_POS,
        S_POS_CANCEL,
        S_NEG,
        S_NEG_CANCEL

    );

    signal start_edge : std_logic;

    signal state : slope_state;
    signal sw_state : switch_state;

    signal previous_sample, remainder_sample : unsigned(11 downto 0);

    signal run_up_counter, run_up_part : unsigned(COUNTER_WIDTH - 1 downto 0);
    signal run_up_charge_add, run_up_charge_sub : unsigned(COUNTER_WIDTH - 1 downto 0);
    signal run_down_counter : unsigned(COUNTER_WIDTH - 1 downto 0);

begin

    -- Control integrator 
    sw_ctrl : process (sw_state)
    begin
        case(sw_state) is
            when S_POS =>
            sel_pos_vref <= '1';
            sel_neg_vref <= '0';
            when S_POS_CANCEL =>
            sel_pos_vref <= '0';
            sel_neg_vref <= '0';
            when S_NEG =>
            sel_pos_vref <= '0';
            sel_neg_vref <= '1';
            when S_NEG_CANCEL =>
            sel_pos_vref <= '1';
            sel_neg_vref <= '1';
            when others =>
            report "unreachable" severity failure;
        end case;
    end process sw_ctrl;

    proc_name : process (start, rst, state)
    begin
        if rst = '1' then
            start_edge <= '0';
        elsif state = RUNUP then
        start_edge <= '0';
            
        elsif rising_edge(start) then
            start_edge <= '1';
        end if;
    end process proc_name;

    slope_fsm : process (clk, rst)
    begin
        adc_conv <= '0';
        if rst = '1' then
            state <= HOLD;
            sw_state <= S_POS_CANCEL;
            run_up_counter <= (others => '0');
            run_up_part <= (others => '0');
            run_up_charge_add <= (others => '0');
            run_up_charge_sub <= (others => '0');
            run_down_counter <= (others => '0');

        elsif rising_edge(clk) then
            case(state) is
                when HOLD =>
                sw_state <= S_POS_CANCEL;
                sel_vin <= '0';
                if start_edge = '1' then
                    state <= SAMPLE_PREVIOUS;
                end if;

                when SAMPLE_PREVIOUS =>
                -- Save remainder voltage and if freerunning start next cycle 
                sw_state <= S_POS_CANCEL;
                sel_vin <= '0';
                adc_conv <= '1';
                if adc_ready = '1' then
                    previous_sample <= adc_vout;
                    state <= RUNUP;
                end if;

                when RUNUP =>
                -- Save remainder voltage and if freerunning start next cycle 
                sw_state <= S_POS_CANCEL;
                sel_vin <= '1';
                adc_conv <= '0';

                run_up_counter <= run_up_counter + 1; -- Total runup time
                if run_up_counter = int_t then
                    run_up_part <= (others => '0');
                    if cmp_in = '1' then
                        state <= RUNDOWN_SUB;
                    else
                        state <= RUNDOWN_ADD;
                    end if;
                elsif run_up_part = RUNUP_PARTIAL_T then
                    run_up_part <= (others => '0');
                    if cmp_in = '1' then
                        state <= RUNUP_SUB;
                    else
                        state <= RUNUP_ADD;
                    end if;
                else
                    run_up_part <= run_up_part + 1;
                end if;

                when RUNUP_ADD =>
                sw_state <= S_POS;
                sel_vin <= '1';
                adc_conv <= '0';

                run_up_counter <= run_up_counter + 1;
                run_up_charge_add <= run_up_charge_add + 1;
                if cmp_in = '1' then
                    state <= RUNUP;
                end if;

                when RUNUP_SUB =>
                sw_state <= S_NEG;
                sel_vin <= '1';
                adc_conv <= '0';

                run_up_counter <= run_up_counter + 1;
                run_up_charge_sub <= run_up_charge_sub + 1;
                if cmp_in = '0' then
                    state <= RUNUP;
                end if;

                when RUNDOWN_ADD =>
                sw_state <= S_POS;
                sel_vin <= '0';
                adc_conv <= '0';
                run_down_counter <= run_down_counter + 1;
                if cmp_in = '1' then
                    state <= SAMPLE_REMAINDER;
                end if;

                when RUNDOWN_SUB =>
                sw_state <= S_NEG;
                sel_vin <= '0';
                adc_conv <= '0';

                run_down_counter <= run_down_counter + 1;
                if cmp_in = '0' then
                    state <= SAMPLE_REMAINDER;
                end if;

                when SAMPLE_REMAINDER =>
                -- Save remainder voltage and if freerunning start next cycle 
                sw_state <= S_POS_CANCEL;
                sel_vin <= '0';
                adc_conv <= '1';
                if adc_ready = '1' then
                    previous_sample <= adc_vout;
                    if freerun = '1' then
                        remainder_sample <= adc_vout;
                        state <= RUNUP;
                    else
                        state <= HOLD;
                    end if;

                end if;

                when others =>

            end case;
        end if;
    end process slope_fsm;
end architecture arch;