library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

---
---
entity sinc3_filter is
    generic (
        WORD_WIDTH : integer := 12;
        DECIMATION : integer := 12
    );
    port (
        rst : in std_logic;

        -- 1 bit input
        in_data : in std_logic;
        in_clk : in std_logic;

        -- N bit output
        out_data : out unsigned(WORD_WIDTH - 1 downto 0);
        out_clk : out std_logic
    );
end entity sinc3_filter;

architecture arch of sinc3_filter is
    -- Accumulator registers
    signal acc1o : unsigned(WORD_WIDTH - 1 downto 0);
    signal acc2o : unsigned(WORD_WIDTH - 1 downto 0);
    signal acc3o : unsigned(WORD_WIDTH - 1 downto 0);

    signal acc1z : unsigned(WORD_WIDTH - 1 downto 0);
    signal acc2z : unsigned(WORD_WIDTH - 1 downto 0);
    signal acc3z : unsigned(WORD_WIDTH - 1 downto 0);

    -- Decimator word counter
    signal word_count : unsigned(DECIMATION - 1 downto 0);
    signal word_clk : std_logic;

    -- Differentiator registers
    signal diff0z : unsigned(WORD_WIDTH - 1 downto 0);
    signal diff1z : unsigned(WORD_WIDTH - 1 downto 0);
    signal diff2z : unsigned(WORD_WIDTH - 1 downto 0);

    signal diff1 : unsigned(WORD_WIDTH - 1 downto 0);
    signal diff2 : unsigned(WORD_WIDTH - 1 downto 0);
    signal diff3 : unsigned(WORD_WIDTH - 1 downto 0);

begin

    -- Clock output
    out_clk <= word_clk;

    -- Accumulator stage
    --
    accumulator : process (rst, in_clk)
        variable idata : integer;
    begin
        if rst = '1' then
            acc1z <= (others => '0');
            acc2z <= (others => '0');
            acc3z <= (others => '0');
        elsif rising_edge(in_clk) then
            acc1z <= acc1o;
            acc2z <= acc2o;
            acc3z <= acc3o;
        end if;
    end process accumulator;

    acc1o <= ("" & in_data) + acc1z;
    acc2o <= acc1o + acc2z;
    acc3o <= acc2o + acc3z; 

    -- Decimator stage
    --
    decimator : process (rst, in_clk)
    begin
        if rst = '1' then
            word_count <= (others => '0');
        elsif rising_edge(in_clk) then
            word_count <= word_count + 1;
        end if;
    end process decimator;
    word_clk <= word_count(word_count'high);


    -- Differentiator stage
    --
    differentiator : process (rst, word_clk)
    begin
        if rst = '1' then
            diff0z <= (others => '0');
            diff1z <= (others => '0');
            diff2z <= (others => '0');
            diff1 <= (others => '0');
            diff2 <= (others => '0');
            diff3 <= (others => '0');
        elsif rising_edge(word_clk) then
            diff0z <= acc3o;
            diff1z <= diff1;
            diff2z <= diff2;
            diff1 <= acc3o - diff0z;
            diff2 <= diff1 - diff1z;
            diff3 <= diff2 - diff2z;
        end if;
    end process differentiator;



    -- Latch result into output
    --
    output : process (rst, word_clk)
    begin
        if rst = '1' then
            out_data <= (others => '0');
        elsif rising_edge(word_clk) then
            out_data <= diff3;
        end if;
    end process output;

end architecture arch;