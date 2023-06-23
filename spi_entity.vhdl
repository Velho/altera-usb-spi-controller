-- velho
-- spi-entity periphiral
-- implements the spi slave
-- 	- handles the miso, mosi
--		- full-duplex => each sck read mosi and write miso
-- spi protocol is setup as follows,
--  request is built from the command and data,
--
-- reference:
-- https://github.com/jakubcabal/spi-fpga/blob/master/rtl/spi_slave.vhd
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_entity is
    generic (
        DATA_WIDTH  : integer := 8
    );
    port (
        -- sys signals
        SYS_CLK     : in std_logic;
        SYS_RST     : in std_logic;
        -- spi signals
        SCLK        : in std_logic;
        CS_N        : in std_logic;
        MOSI        : in std_logic;
        MISO        : out std_logic;

        DIN         : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- data for transmission to SPI master
        DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, data for transmission are valid
        DIN_RDY     : out std_logic; -- when DIN_RDY = 1, SPI slave is ready to accept valid data for transmission
        DOUT        : out std_logic_vector(DATA_WIDTH-1 downto 0); -- received data from SPI master
        DOUT_VLD    : out std_logic  -- when DOUT_VLD = 1, received data are valid
    );
end entity;

architecture spi_rtl of spi_entity is

    -- width of 8, can be represented with 3 bits
    constant BIT_CNT_WIDTH : natural := natural(ceil(log2(real(DATA_WIDTH))));

    -- internal signals for buffers
    signal rx_fifo          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal tx_fifo          : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal rx_fifo_full     : std_logic; -- := '0';
    signal tx_fifo_empty    : std_logic; --:= '1';

    -- spi internals

    signal sclk_meta        : std_logic;
    signal cs_n_meta        : std_logic;
    signal mosi_meta        : std_logic;

    signal sclk_reg         : std_logic;
    signal mosi_reg         : std_logic;
    signal cs_n_reg         : std_logic;
    signal spi_clk_reg      : std_logic;
    -- spi edge flags
    signal spi_clk_fedge_en : std_logic;
    signal spi_clk_redge_en : std_logic;

    signal bit_cnt          : unsigned(BIT_CNT_WIDTH-1 downto 0);
    signal bit_cnt_max      : std_logic;

    signal rx_data_valid    : std_logic;
    signal last_bit_en      : std_logic;
    signal load_data_en     : std_logic;

    -- shift registers
    signal shift_reg_busy   : std_logic;
    signal data_shift_reg   : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal slave_ready      : std_logic;

begin

    -- one process to reset all the internals?

    sync : process(SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            sclk_meta  <= SCLK;
            cs_n_meta  <= CS_N;

            -- todo resolve metastability
            -- interface object, mode out cannot be read
            -- change object mode to buffer
            -- mosi_iv    <= MOSI;
            mosi_meta  <= MOSI;

            sclk_reg   <= sclk_meta;
            cs_n_reg   <= cs_n_meta;
            mosi_reg   <= mosi_meta;
        end if;
    end process;

    spi_clk : process(SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (SYS_RST = '1') then
                spi_clk_reg <= '0';
            else
                spi_clk_reg <= sclk_reg;
            end if;
        end if;
    end process;

    spi_clk_fedge_en <= not sclk_reg and spi_clk_reg;
    spi_clk_redge_en <= sclk_reg and not spi_clk_reg;


    bit_cnt_p : process (SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (SYS_RST = '1') then
                bit_cnt <= (others => '0');
            elsif (spi_clk_fedge_en = '1' and cs_n_reg = '0') then
                if (bit_cnt_max = '1') then
                    bit_cnt <= (others => '0');
                else
                    bit_cnt <= bit_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    bit_cnt_max <= '1' when (bit_cnt = DATA_WIDTH-1) else '0';


    last_bit_en_p : process(SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (SYS_RST = '1') then
                last_bit_en <= '0';
            else
                last_bit_en <= bit_cnt_max;
            end if;
        end if;
    end process;

    rx_data_valid <= spi_clk_fedge_en and last_bit_en;  -- why not ..valid <= .. and bit_cnt_max ?

    shift_reg_busy_p : process (SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (SYS_RST = '1') then
                shift_reg_busy <= '0';
            else
                if (DIN_VLD = '1' and (cs_n_reg = '1' or rx_data_valid = '1')) then
                    shift_reg_busy <= '1';
                elsif (rx_data_valid = '1') then
                    shift_reg_busy <= '0';
                else
                    shift_reg_busy <= shift_reg_busy;
                end if;
            end if;
        end if;
    end process;

    slave_ready <= (cs_n_reg and not shift_reg_busy) or rx_data_valid;
    load_data_en  <= slave_ready and DIN_VLD;


    data_shift_register_p : process (SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (load_data_en = '1') then
                data_shift_reg <= DIN;
            elsif (spi_clk_redge_en = '1' and cs_n_reg = '0') then
                data_shift_reg <= data_shift_reg(DATA_WIDTH-2 downto 0) & mosi_reg;
            end if;
        end if;
    end process;

    miso_p : process (SYS_CLK)
    begin
        if (rising_edge(SYS_CLK)) then
            if (load_data_en = '1') then
                MISO <= DIN(DATA_WIDTH-1);
            elsif(spi_clk_fedge_en = '1' and cs_n_reg = '0') then
                MISO <= data_shift_reg(DATA_WIDTH-1);
            end if;
        end if;
    end process;

    DIN_RDY     <= slave_ready;
    DOUT        <= data_shift_reg;
    DOUT_VLD  <= rx_data_valid;

end architecture;
