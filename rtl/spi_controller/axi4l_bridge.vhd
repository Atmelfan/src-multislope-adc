-- Copyright (c) 2022
-- Author(s): 
-- * Gustav Palmqvist <gustavp@gpa-robotics.com>
--
-- SPDX-License-Identifier: CERN-OHL-S-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4l_bridge is
    generic (
        ADDR_WIDTH : natural := 32;
        BUS_ADDR : std_logic_vector(3 downto 0) := "0000"
    );
    port (
        -- 
        clk : in std_logic;
        rst : in std_logic;

        -- SPI interface
        spi_adr : out std_logic_vector(7 downto 0);
        spi_dati : out std_logic_vector(7 downto 0);
        spi_dato : in std_logic_vector(7 downto 0);
        spi_stb : out std_logic;
        spi_rw : out std_logic;
        spi_ack : in std_logic;

        -- AXI4-Lite master
        aclk, aresetn : out std_logic;
        -- Write address channel
        awvalid : out std_logic;
        awready : in std_logic;
        awaddr : out std_logic_vector(31 downto 0);
        awprot : out std_logic_vector(2 downto 0);
        -- Write data channel
        wvalid : out std_logic;
        wready : in std_logic;
        wdata : out std_logic_vector(31 downto 0);
        wstrb : out std_logic_vector(3 downto 0);
        -- Write response channel
        bvalid : in std_logic;
        bready : out std_logic;
        bresp : in std_logic_vector(1 downto 0);
        -- Read address channel
        arvalid : out std_logic;
        arready : in std_logic;
        araddr : out std_logic_vector(31 downto 0);
        arprot : out std_logic_vector(2 downto 0);
        -- Read data channel
        rvalid : in std_logic;
        rready : out std_logic;
        rdata : in std_logic_vector(31 downto 0);
        rresp : in std_logic_vector(1 downto 0)
    );
end axi4l_bridge;

architecture arch of axi4l_bridge is

    constant DATA_WIDTH : natural := 32;

    -- Register adresses for SB_SPI controller
    constant SPICR0 : std_logic_vector(7 downto 0) := BUS_ADDR & "1000";
    constant SPICR1 : std_logic_vector(7 downto 0) := BUS_ADDR & "1001";
    constant SPICR2 : std_logic_vector(7 downto 0) := BUS_ADDR & "1010";
    constant SPIBR : std_logic_vector(7 downto 0) := BUS_ADDR & "1011";
    constant SPITXDR : std_logic_vector(7 downto 0) := BUS_ADDR & "1101";
    constant SPIRXDR : std_logic_vector(7 downto 0) := BUS_ADDR & "1110";
    constant SPICSR : std_logic_vector(7 downto 0) := BUS_ADDR & "1111";
    constant SPISR : std_logic_vector(7 downto 0) := BUS_ADDR & "1100";
    constant SPIIRQ : std_logic_vector(7 downto 0) := BUS_ADDR & "0110";
    constant SPIIRQEN : std_logic_vector(7 downto 0) := BUS_ADDR & "0111";

    constant OP_NOPE : std_logic_vector(3 downto 0) := x"0";
    constant OP_READ : std_logic_vector(3 downto 0) := x"1";
    constant OP_WRITE : std_logic_vector(3 downto 0) := x"2";

    type controller_state is (
        -- Initialize
        INIT_CR0,
        INIT_CR1,
        INIT_CR2,
        INIT_BR,
        INIT_CSR,

        -- AXI address
        WAIT_FOR_READ,
        READ_ADDR,

        -- AXI Read operation
        WAIT_FOR_ARREADY,
        READ_AXI_DATA,
        WAIT_FOR_WRITE_DATA,
        WRITE_DATA,

        -- AXI write operation
        WAIT_FOR_AWREADY,
        WAIT_FOR_READ_DATA,
        READ_DATA,
        WRITE_AXI_DATA
    );

    -- Statemachine registers
    signal state : controller_state;
    signal byte_cnt : unsigned(4 downto 0);
    signal read_write : std_logic;

    -- AXI4-Lite registers
    signal addr_reg : std_logic_vector(ADDR_WIDTH - 1 downto 0);

    signal write_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal read_data_reg : std_logic_vector(DATA_WIDTH - 1 downto 0);

    signal last_response : std_logic_vector(1 downto 0);
begin

    -- AXI4 clock and reset
    aclk <= clk;
    aresetn <= not rst;

    awaddr <= "0000" & addr_reg(27 downto 0);
    awprot <= (others => '0'); -- Don't care

    araddr <= "0000" & addr_reg(27 downto 0);
    arprot <= (others => '0'); -- Don't care

    wdata <= write_data_reg;
    wstrb <= (others => '1'); -- Only write whole 32 bit words

    -- SPI slave
    spi_control : process (clk)
    begin
        if rising_edge(clk) then
            spi_stb <= '0';

            awvalid <= '0';
            wvalid <= '0';
            bready <= '0';

            arvalid <= '0';
            rready <= '0';

            if rst = '1' then
                -- 
                state <= INIT_CR0;
                byte_cnt <= (others => '0');
                read_write <= '1';

                addr_reg <= (others => '0');
                write_data_reg <= (others => '0');
                read_data_reg <= (others => '0');
            else
                case(state) is

                    when INIT_CR0 =>
                    spi_adr <= SPICR0;
                    spi_dati <= (others => '0'); -- Default delays
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= INIT_CR1;
                    end if;

                    when INIT_CR1 =>
                    spi_adr <= SPICR1;
                    spi_dati <= (7 => '1', others => '0'); -- Enable SPI
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= INIT_CR2;
                    end if;

                    when INIT_CR2 =>
                    spi_adr <= SPICR2;
                    spi_dati <= (0 => '1', others => '0'); -- LSB first
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= INIT_BR;
                    end if;

                    when INIT_BR =>
                    spi_adr <= SPIBR;
                    spi_dati <= (others => '0'); -- Divider = 1
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= INIT_CSR;
                    end if;

                    when INIT_CSR =>
                    spi_adr <= SPICSR;
                    spi_dati <= (others => '0'); -- Not used in slave mode
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_READ;
                    end if;

                    when WAIT_FOR_READ =>
                    spi_adr <= SPISR;
                    spi_stb <= '1';
                    spi_rw <= '0';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_READ;

                        if spi_dato(3) = '1' then
                            state <= READ_ADDR;
                        end if;
                    end if;

                    when READ_ADDR =>
                    spi_adr <= SPIRXDR;
                    spi_stb <= '1';
                    spi_rw <= '0';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_READ;
                        byte_cnt <= byte_cnt + 1;
                        --report "byte_cnt = " & to_string(to_integer(byte_cnt)) severity note;
                        case(to_integer(byte_cnt)) is
                            -- First byte
                            when 0 => addr_reg(31 downto 24) <= spi_dato;
                            -- Second byte
                            when 1 => addr_reg(23 downto 16) <= spi_dato;
                            -- Third byte
                            when 2 => addr_reg(15 downto 8) <= spi_dato;
                            -- Forth byte, decode operation
                            when others => addr_reg(7 downto 0) <= spi_dato;

                            if addr_reg(31 downto 28) = OP_NOPE then
                                report "OP_NOPE" severity note;
                                byte_cnt <= (others => '0');
                                last_response <= "00"; -- Okay response
                                state <= WAIT_FOR_READ;
                            elsif addr_reg(31 downto 28) = OP_WRITE then
                                report "OP_WRITE" severity note;
                                awvalid <= '1';
                                state <= WAIT_FOR_AWREADY;
                            elsif addr_reg(31 downto 28) = OP_READ then
                                report "OP_READ" severity note;
                                arvalid <= '1';
                                state <= WAIT_FOR_ARREADY;
                            else
                                -- Invalid operation
                                -- Reset
                                report "<INVALID>" severity error;
                                byte_cnt <= (others => '0');
                                last_response <= "11"; -- Error response
                                state <= WAIT_FOR_READ;
                            end if;
                        end case;
                    end if;

                    -- Write data
                    when WAIT_FOR_AWREADY =>
                    --report "WRITE TO ADDR 0" & to_hstring(addr_reg(27 downto 0)) severity note;
                    awvalid <= '1';
                    if awready = '1' then
                        --report "AWREADY" severity note;
                        -- Write address ready
                        awvalid <= '0';
                        state <= WAIT_FOR_READ_DATA;
                    end if;

                    when WAIT_FOR_READ_DATA =>
                    spi_adr <= SPISR;
                    spi_stb <= '1';
                    spi_rw <= '0';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_READ_DATA;

                        if spi_dato(3) = '1' then
                            state <= READ_DATA;
                        end if;
                    end if;

                    when READ_DATA =>
                    spi_adr <= SPIRXDR;
                    spi_stb <= '1';
                    spi_rw <= '0';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_READ_DATA;

                        byte_cnt <= byte_cnt + 1;
                        --report "byte_cnt = " & to_string(to_integer(byte_cnt)) severity note;
                        case(to_integer(byte_cnt)) is
                            -- First byte
                            when 4 => write_data_reg(31 downto 24) <= spi_dato;
                            -- Second byte
                            when 5 => write_data_reg(23 downto 16) <= spi_dato;
                            -- Third byte
                            when 6 => write_data_reg(15 downto 8) <= spi_dato;
                            -- Forth byte
                            when others => write_data_reg(7 downto 0) <= spi_dato;

                            byte_cnt <= (others => '0');
                            wvalid <= '1';
                            bready <= '1';
                            state <= WRITE_AXI_DATA;

                        end case;
                    end if;

                    when WRITE_AXI_DATA =>
                    --report "WRITE " & to_hstring(write_data_reg) severity note;
                    wvalid <= '1';
                    bready <= '1';
                    if wready = '1' and bvalid = '1' then
                        --report "WREADY" severity note;
                        -- Write ready
                        wvalid <= '0';
                        bready <= '0';
                        last_response <= bresp;
                        state <= WAIT_FOR_READ;
                    end if;

                    -- Read data
                    when WAIT_FOR_ARREADY =>
                    --report "READ FROM ADDR 0" & to_hstring(addr_reg) severity note;
                    arvalid <= '1';
                    if arready = '1' then
                        --report "ARREADY" severity note;
                        -- Write address ready
                        arvalid <= '0';
                        state <= READ_AXI_DATA;

                        rready <= '1';
                    end if;

                    when READ_AXI_DATA =>
                    rready <= '1';
                    if rvalid = '1' then
                        --report "RVALID" severity note;
                        -- Write ready
                        rready <= '0';
                        state <= WAIT_FOR_WRITE_DATA;

                        last_response <= rresp;
                        read_data_reg <= rdata;
                        --report "READ " & to_hstring(rdata) severity note;
                    end if;

                    when WAIT_FOR_WRITE_DATA =>
                    spi_adr <= SPISR;
                    spi_stb <= '1';
                    spi_rw <= '0';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_WRITE_DATA;

                        if spi_dato(4) = '1' then
                            state <= WRITE_DATA;
                        end if;
                    end if;

                    when WRITE_DATA =>
                    spi_adr <= SPITXDR;
                    case(to_integer(byte_cnt)) is
                        -- First byte
                        when 4 => spi_dati <= read_data_reg(31 downto 24);
                        -- Second byte
                        when 5 => spi_dati <= read_data_reg(23 downto 16);
                        -- Third byte
                        when 6 => spi_dati <= read_data_reg(15 downto 8);
                        -- Forth byte
                        when others => spi_dati <= read_data_reg(7 downto 0);
                    end case;
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= WAIT_FOR_WRITE_DATA;

                        if byte_cnt < 7 then
                            byte_cnt <= byte_cnt + 1;
                        else
                            byte_cnt <= (others => '0');
                            state <= WAIT_FOR_READ;
                        end if;
                    end if;
                    when others =>
                    state <= INIT_CR0;

                end case;

            end if;
        end if;
    end process spi_control;

end architecture; -- arch