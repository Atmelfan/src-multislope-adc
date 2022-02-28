-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

entity SIM_SPI is
    generic (
        BUS_ADDR74 : std_logic_vector(3 downto 0)
    );
    port (
        -- Clock
        sbclki : in std_logic;

        -- Databus
        sbstbi : in std_logic;
        sbrwi : in std_logic;
        sbadri : in std_logic_vector(7 downto 0);
        sbdati : in std_logic_vector(7 downto 0);
        sbdato : out std_logic_vector(7 downto 0);
        sbacko : out std_logic;

        -- Status signals
        spiirqo : out std_logic;
        spiwkupo : out std_logic
    );
end SIM_SPI;

architecture SIM_SPI_arch of SIM_SPI is

    constant ADDR_SPICR0 : std_logic_vector(3 downto 0) := "1000";
    constant ADDR_SPICR1 : std_logic_vector(3 downto 0) := "1001";
    constant ADDR_SPICR2 : std_logic_vector(3 downto 0) := "1010";
    constant ADDR_SPIBR : std_logic_vector(3 downto 0) := "1011";
    constant ADDR_SPITXDR : std_logic_vector(3 downto 0) := "1101";
    constant ADDR_SPIRXDR : std_logic_vector(3 downto 0) := "1110";
    constant ADDR_SPICSR : std_logic_vector(3 downto 0) := "1111";
    constant ADDR_SPISR : std_logic_vector(3 downto 0) := "1100";
    constant ADDR_SPIIRQ : std_logic_vector(3 downto 0) := "0110";
    constant ADDR_SPIIRQEN : std_logic_vector(3 downto 0) := "0111";

    -- SPI cosim interface
    procedure sim_spi_init is
    begin
        report "VHPIDIRECT sim_spi_init" severity failure;
    end;
    attribute foreign of sim_spi_init : procedure is "VHPIDIRECT sim_spi_init";

    -- 
    --
    procedure sim_spi_rxtx (data : inout std_logic_vector(7 downto 0); flags : inout std_logic_vector(3 downto 0)) is
    begin
        report "VHPIDIRECT sim_spi_rxtx" severity failure;
    end;
    attribute foreign of sim_spi_rxtx : procedure is "VHPIDIRECT sim_spi_rxtx";

    -- Control registers
    signal spicr0, spicr1, spicr2, spibr, spitxdr, spirxdr, spicsr, spisr, spiirq, spiirqen : std_logic_vector(7 downto 0) := (others => '0');

    alias sbadri_bus : std_logic_vector(3 downto 0) is sbadri(7 downto 4);
    alias sbadri_reg : std_logic_vector(3 downto 0) is sbadri(3 downto 0);

    signal sr_tip, sr_busy, sr_trdy, sr_toe, sr_roe, sr_mdf : std_logic := '0';
    signal sr_rrdy : std_logic := '0';
begin

    -- Status register
    spisr <= (sr_tip & sr_busy & '0' & sr_trdy & sr_rrdy & sr_toe & sr_roe & sr_mdf);

    system_bus : process (sbclki)
        variable data : std_logic_vector(7 downto 0) := (others => '0');
        variable flags : std_logic_vector(3 downto 0) := (others => '0');
    begin
        if rising_edge(sbclki) then

            -- Talk when RX buffer is empty and enabled
            if (sr_rrdy = '0' or sr_trdy = '0') and spicr1(7) = '1' then
                data := spitxdr;
                --report "TXDR="&to_hstring(data) severity note;
                sim_spi_rxtx(data, flags);
                if flags(3) = '1' then
                    -- Driver has closed channel
                    report "Channel closed" severity warning;
                    --finish; -- Fails with segmentation fault...
                elsif flags(0) = '1' then
                    --Driver has sent a byte
                    --report "RXDR="&to_hstring(data) severity note;
                    spirxdr <= data;
                    sr_rrdy <= '1';
                    sr_trdy <= '1';
                end if;    
            end if ;

            -- Logic
            if sbstbi = '1' and sbacko = '0' and sbadri_bus = BUS_ADDR74 then
                if sbrwi = '1' then
                    -- Write
                    case(sbadri_reg) is
                        when ADDR_SPICR0 =>
                        report "wrote CR0" severity note;
                        spicr0 <= sbdati;

                        when ADDR_SPICR1 =>
                        report "wrote CR1" severity note;
                        spicr1 <= sbdati;

                        when ADDR_SPICR2 =>
                        report "wrote CR2" severity note;
                        spicr2 <= sbdati;

                        when ADDR_SPIBR =>
                        report "wrote BR" severity note;
                        spibr <= sbdati;

                        when ADDR_SPITXDR =>
                        report "wrote TXDR" severity note;
                        spitxdr <= sbdati;
                        sr_trdy <= '0'; -- Set write empty flag

                        when ADDR_SPICSR =>
                        report "wrote SR" severity note;
                        spicsr <= sbdati;

                        when ADDR_SPIIRQ =>
                        report "wrote IRQ" severity note;
                        spiirq <= (others => '0');

                        when ADDR_SPIIRQEN =>
                        report "wrote IRQEN" severity note;
                        spiirqen <= sbdati;

                        when ADDR_SPIRXDR | ADDR_SPISR =>
                        report "Tried to write to read-only register" severity failure;

                        when others =>
                        report "Tried to write non-existant register" severity failure;
                    end case;
                else
                    -- Read
                    case(sbadri_reg) is
                        when ADDR_SPICR0 =>
                        report "read CR0" severity note;
                        sbdato <= spicr0;

                        when ADDR_SPICR1 =>
                        report "read CR1" severity note;
                        sbdato <= spicr1;

                        when ADDR_SPICR2 =>
                        report "read CR2" severity note;
                        sbdato <= spicr2;

                        when ADDR_SPIBR =>
                        report "read BR" severity note;
                        sbdato <= spibr;

                        when ADDR_SPITXDR =>
                        report "read TXDR" severity note;
                        sbdato <= spitxdr;

                        when ADDR_SPIRXDR =>
                        report "read RXDR" severity note;
                        sbdato <= spirxdr;
                        sr_rrdy <= '0'; -- Clear Read ready flag

                        when ADDR_SPICSR =>
                        report "read CSR" severity note;
                        sbdato <= spicsr;

                        when ADDR_SPISR =>
                        report "read ISR "& to_string(spisr) severity note;
                        sbdato <= spisr;

                        when ADDR_SPIIRQ =>
                        report "read IRQ" severity note;
                        sbdato <= spiirq;

                        when ADDR_SPIIRQEN =>
                        report "read IRQEN" severity note;
                        sbdato <= spiirqen;

                        when others =>
                        report "Tried to read non-existant register" severity failure;
                    end case;

                end if;

                -- Acknowledge
                sbacko <= '1';
            else
                sbacko <= '0';
            end if;

        end if;
    end process system_bus;

end architecture; -- arch