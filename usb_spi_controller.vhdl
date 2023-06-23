-- top-level vhdl

library ieee;
use ieee.std_logic_1164.all;

-- altera de2 expansion header
-- GPIO_0 |		  |      |    |
-- |    0 |	   1 |    2 |  3 |
-- | SCLK | MOSI | MISO | SS |
-- for debugging purposes, user can input
-- data from the SW to SPI fifo buffers.
-- push button 0 (key) is used to input the data
-- to fifo and push button 1 is used to clear the fifo

entity usb_spi_controller is
    generic (
        SPI_WORD_SIZE	: integer := 8
    );

    port (
        -- sys interface
        CLOCK_50        : in std_logic;
        RST             : in std_logic;
        -- SPI interface
        SPI_SCLK        : in std_logic;	-- SCLK
        SPI_SS          : in std_logic;	-- SS
        SPI_MOSI        : in std_logic;  -- MOSI
        SPI_MISO        : out std_logic;	-- MISO

        -- USB host interface (ISP1362)
        USB_CLK         : in std_logic;	 -- system clock
        -- signals negated, not named as such. (!CS, !RD, !WR) NCS, NRD, NWR
        USB_CS          : out std_logic; -- chip select input (active: low)
        USB_RD          : out std_logic; -- read strobe input  ; (low: request read)
        USB_WR          : out std_logic; -- write strobe input ; (low: requesting write)
        -- address signals
        USB_A0          : out std_logic; -- command or data phase
        USB_A1          : out std_logic; -- PIO bus low: HC sel., high: DC sel.
        USB_PIO         : inout std_logic_vector(15 downto 0);

        -- LED and SW for DEBUG
        LEDR_0          : out std_logic;
        LEDG_0          : out std_logic;
        SW_0            : in std_logic
    );
end entity;

architecture rtl of usb_spi_controller is
    constant fifo_size	: integer := 8;
    type fifo_type is array (0 to fifo_size) of std_logic_vector(7 downto 0);

    signal tx_fifo  : fifo_type;
    signal rx_fifo  : fifo_type;
    signal rx_full  : std_logic := '0';
    signal tx_empty : std_logic := '1';

	 signal rx_buffer : std_logic_vector (7 downto 0);
	 signal tx_buffer : std_logic_vector (7 downto 0);

	 signal tx_ready	: std_logic	:= '0';
	 signal tx_valid	: std_logic := '0';
	 signal rx_valid  : std_logic := '0';

begin

    spi_controller : entity work.spi_entity
        port map (
            SYS_CLK     => CLOCK_50,
            SYS_RST     => RST,
            SCLK        => SPI_SCLK,
            MISO        => SPI_MISO,
            MOSI        => SPI_MOSI,
            CS_N        => SPI_SS,
            DIN         => tx_buffer,
            DIN_VLD     => tx_valid,
            DIN_RDY     => tx_ready,
            DOUT        => rx_buffer,
            DOUT_VLD    => rx_valid
        );

    -- instantiate usb_isp1362_host
    usb_controller : entity work.usb_isp1362_host
        port map (
            CLK => CLOCK_50,
            CS  => USB_CS,
            RD  => USB_RD,
            WR  => USB_WR,
            A0  => USB_A0,
            A1  => USB_A1,
            PIO => USB_PIO
        );

    process (CLOCK_50, SW_0)
    begin
        if (SW_0 = '1') then
            LEDR_0 <= '0';
            LEDG_0 <= '1';
        else
            LEDR_0 <= '1';
            LEDG_0 <= '0';
        end if;
    end process;

    -- GPIO_0_3 <= 'Z';

end architecture rtl;
