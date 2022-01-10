library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity spi_slave is
    generic (
        BUS_ADDR : integer := 2#00000#
    )
    port (
        -- 
        clk : in std_logic;
        rst : in std_logic;

        -- Input registers
        

        -- Output registers

    );
end spi_slave;

architecture arch of spi_slave is

    -- Register adresses for SB_SPI controller
    constant SPICR0 : std_logic_vector(7 downto 0) := "00001000";
    constant SPICR1 : std_logic_vector(7 downto 0) := "00001001";
    constant SPICR2 : std_logic_vector(7 downto 0) := "00001010";
    constant SPIBR : std_logic_vector(7 downto 0) := "00001011";
    constant SPITXDR : std_logic_vector(7 downto 0) := "00001101";
    constant SPIRXDR : std_logic_vector(7 downto 0) := "00001110";
    constant SPICSR : std_logic_vector(7 downto 0) := "00001111";
    constant SPISR : std_logic_vector(7 downto 0) := "00001100";
    constant SPIIRQ : std_logic_vector(7 downto 0) := "00000110";
    constant SPIIRQEN : std_logic_vector(7 downto 0) := "00000111";

    type controller_state is (
        -- Initialize
        INIT_CR0,
        INIT_CR1,
        INIT_CR2,
        INIT_BR,
        INIT_CSR,
        --
        WAIT_FOR_READ,
        READ_INIT,
        READ_ADDR,
        --
        WAIT_FOR_WRITE,
        WRITE_INIT,
        WRITE

    );

    signal state : controller_state;

    -- SPI Slave controller interface
    signal spi_adr : std_logic_vector(7 downto 0);
    signal spi_dati : std_logic_vector(7 downto 0);
    signal spi_dato : std_logic_vector(7 downto 0);
    signal spi_stb : std_logic;
    signal spi_rw : std_logic;
    signal spi_ack : std_logic;

begin

    spi_control : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= INIT_CR0;
            else
                case(state) is

                    when INIT_CR0 =>
                    spi_adr <= SPICR0;
                    spi_dati <= (others => '0'); -- Default delays
                    spi_stb <= '1';
                    spi_rw <= '1';
                    if spi_ack = '1' then
                        spi_stb <= '0';
                        state <= INIT_CR0;
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
                    end if;

                    when others =>
                    state <= INIT_CR0;

                end case;

            end if;
        end if;
    end process spi_control;

    SPI_SLAVE : entity SB_SPI
        generic map(
            BUS_ADDR74 => BUS_ADDR
        )
        port map(
            -- Control signals
            SBCLKI => clk,
            SBSTBI => spi_stb,
            SBRWI => spi_rw,
            SBACKO => spi_ack,

            -- Adress bus
            SBADRI0 => spi_adr[0],
            SBADRI1 => spi_adr[1],
            SBADRI2 => spi_adr[2],
            SBADRI3 => spi_adr[3],
            SBADRI4 => spi_adr[4],
            SBADRI5 => spi_adr[5],
            SBADRI6 => spi_adr[6],
            SBADRI7 => spi_adr[7],

            -- Data input bus
            SBDATI0 => spi_dati[0],
            SBDATI1 => spi_dati[1],
            SBDATI2 => spi_dati[2],
            SBDATI3 => spi_dati[3],
            SBDATI4 => spi_dati[4],
            SBDATI5 => spi_dati[5],
            SBDATI6 => spi_dati[6],
            SBDATI7 => spi_dati[7],

            -- Data output bus
            SBDATO0 => spi_dato[0],
            SBDATO1 => spi_dato[1],
            SBDATO2 => spi_dato[2],
            SBDATO3 => spi_dato[3],
            SBDATO4 => spi_dato[4],
            SBDATO5 => spi_dato[5],
            SBDATO6 => spi_dato[6],
            SBDATO7 => spi_dato[7],

            -- Slave connections
            SO => SPI_MISO,
            SI => SPI_MOSI,
            SCKI => SPI_SCK,
            SCSNI => SPI_SS,

            -- Master connections left open
            MI => open,
            MO => open
        );

end architecture; -- arch