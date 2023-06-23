-- usb-host entity
-- implements the usb host state machine for the ISP1362

library ieee;
use ieee.std_logic_1164.all;


entity usb_isp1362_host is
    port (
        CLK		: in std_logic;	-- system clock

        CS      : out std_logic; -- chip select input (active: low)
        -- read and write, asserts when low
        RD      : out std_logic;
        WR      : out std_logic;

        A0      : out std_logic; -- command or data phase
        A1      : out std_logic; -- PIO bus low: HC sel., high: DC sel.
        PIO     : inout std_logic_vector(15 downto 0) -- uP interface
    );
end entity;

architecture rtl_isp1362 of usb_isp1362_host is
begin
end architecture;
