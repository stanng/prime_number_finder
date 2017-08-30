------------------------------------------------------------------------------
-- C5G VHDL Entity declaration
-- Adapted from C5G_Default.v
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity C5G is
  port (

    --------- ADC ---------
--    ADC_CONVST     :   out std_logic;
--    ADC_SCK        :   out std_logic;
--    ADC_SDI        :   out std_logic;
--    ADC_SDO        :    in std_logic;

    --------- AUD ---------
--    AUD_ADCDAT     :    in std_logic;
--    AUD_ADCLRCK    : inout std_logic;
--    AUD_BCLK       : inout std_logic;
--    AUD_DACDAT     :   out std_logic;
--    AUD_DACLRCK    : inout std_logic;
--    AUD_XCK        :   out std_logic;

    --------- CLOCK ---------
    CLOCK_125_p    :    in std_logic;
    CLOCK_50_B5B   :    in std_logic;
    CLOCK_50_B6A   :    in std_logic;
    CLOCK_50_B7A   :    in std_logic;
    CLOCK_50_B8A   :    in std_logic;

    --------- CPU ---------
    CPU_RESET_n    :    in std_logic;

    --------- DDR2LP ---------
--    DDR2LP_CA      :   out std_logic_vector ( 9 downto 0);
--    DDR2LP_CKE     :   out std_logic_vector ( 1 downto 0);
--    DDR2LP_CK_n    :   out std_logic;
--    DDR2LP_CK_p    :   out std_logic;
--    DDR2LP_CS_n    :   out std_logic_vector ( 1 downto 0);
--    DDR2LP_DM      :   out std_logic_vector ( 3 downto 0);
--    DDR2LP_DQ      : inout std_logic_vector (31 downto 0);
--    DDR2LP_DQS_n   : inout std_logic_vector ( 3 downto 0);
--    DDR2LP_DQS_p   : inout std_logic_vector ( 3 downto 0);
--    DDR2LP_OCT_RZQ :    in std_logic;

    --------- HEX2 ---------
    HEX0           :   out std_logic_vector ( 6 downto 0);
    HEX1           :   out std_logic_vector ( 6 downto 0);
--    HEX2           :   out std_logic_vector ( 6 downto 0);
--    HEX3           :   out std_logic_vector ( 6 downto 0);

    --------- EITHER GPIO or HEX2/HEX3 ---------
    -- GPIO pins are shared between header and (7-segment LED and Arduino)
    -- So define one or the other.
    GPIO           : inout std_logic_vector (35 downto 0);

    --------- HDMI ---------
--    HDMI_TX_CLK    :   out std_logic;
--    HDMI_TX_D      :   out std_logic_vector (23 downto 0);
--    HDMI_TX_DE     :   out std_logic;
--    HDMI_TX_HS     :   out std_logic;
--    HDMI_TX_INT    :    in std_logic;
--    HDMI_TX_VS     :   out std_logic;


    --------- HSMC ---------
--    HSMC_CLKIN0    :    in std_logic;
--    HSMC_CLKIN_n   :    in std_logic_vector ( 2 downto 1);
--    HSMC_CLKIN_p   :    in std_logic_vector ( 2 downto 1);
--    HSMC_CLKOUT0   :   out std_logic;
--    HSMC_CLKOUT_n  :   out std_logic_vector ( 2 downto 1);
--    HSMC_CLKOUT_p  :   out std_logic_vector ( 2 downto 1);
--    HSMC_D         : inout std_logic_vector ( 3 downto 0);
--    HSMC_GXB_RX_p  :    in std_logic_vector ( 3 downto 0);
--    HSMC_GXB_TX_p  :   out std_logic_vector ( 3 downto 0);
--    HSMC_RX_n      : inout std_logic_vector (16 downto 0);
--    HSMC_RX_p      : inout std_logic_vector (16 downto 0);
--    HSMC_TX_n      : inout std_logic_vector (16 downto 0);
--    HSMC_TX_p      : inout std_logic_vector (16 downto 0);


    --------- I2C ---------
--    I2C_SCL        :   out std_logic;
--    I2C_SDA        : inout std_logic;

    --------- KEY ---------
    KEY            :    in std_logic_vector ( 3 downto 0);

    --------- LEDG ---------
    LEDG           :   out std_logic_vector ( 7 downto 0);

    --------- LEDR ---------
    LEDR           :   out std_logic_vector ( 9 downto 0);

    --------- REFCLK ---------
--    REFCLK_p0      :    in std_logic;
--    REFCLK_p1      :    in std_logic;

--    --------- SD ---------
--    SD_CLK         :   out std_logic;
--    SD_CMD         : inout std_logic;
--    SD_DAT         : inout std_logic_vector ( 3 downto 0);
--
    --------- SMA ---------
--    SMA_GXB_RX_p   :    in std_logic;
--    SMA_GXB_TX_p   :   out std_logic;
--
    --------- SRAM ---------
--    SRAM_A         :   out std_logic_vector (17 downto 0);
--    SRAM_CE_n      :   out std_logic;
--    SRAM_D         : inout std_logic_vector (15 downto 0);
--    SRAM_LB_n      :   out std_logic;
--    SRAM_OE_n      :   out std_logic;
--    SRAM_UB_n      :   out std_logic;
--    SRAM_WE_n      :   out std_logic;

    --------- SW ---------
    SW             :    in std_logic_vector ( 9 downto 0)

    --------- UART ---------
--    UART_RX        :    in std_logic;
--    UART_TX        :   out std_logic
);
end entity C5G;
