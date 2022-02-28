library ieee;
use ieee.std_logic_1164.all;

package components is

  component SB_GB
    port (
      GLOBAL_BUFFER_OUTPUT : out std_logic;
      USER_SIGNAL_TO_GLOBAL_BUFFER : in std_logic
    );
  end component;

  component SB_RGBA_DRV
    generic (
      CURRENT_MODE : string := "0b0";
      RGB0_CURRENT : string := "0b000000";
      RGB1_CURRENT : string := "0b000000";
      RGB2_CURRENT : string := "0b000000"
    );
    port (
      RGB0PWM : in std_logic;
      RGB1PWM : in std_logic;
      RGB2PWM : in std_logic;
      CURREN : in std_logic;
      RGBLEDEN : in std_logic;
      RGB0 : out std_logic;
      RGB1 : out std_logic;
      RGB2 : out std_logic
    );
  end component;

  component SB_SPI is
    generic (
      BUS_ADDR74 : string := "0b0000"
    );
    port (
      SBCLKI : in std_logic;
      SBRWI : in std_logic;
      SBSTBI : in std_logic;
      SBADRI0 : in std_logic;
      SBADRI1 : in std_logic;
      SBADRI2 : in std_logic;
      SBADRI3 : in std_logic;
      SBADRI4 : in std_logic;
      SBADRI5 : in std_logic;
      SBADRI6 : in std_logic;
      SBADRI7 : in std_logic;
      SBDATI0 : in std_logic;
      SBDATI1 : in std_logic;
      SBDATI2 : in std_logic;
      SBDATI3 : in std_logic;
      SBDATI4 : in std_logic;
      SBDATI5 : in std_logic;
      SBDATI6 : in std_logic;
      SBDATI7 : in std_logic;
      SBDATO0 : out std_logic;
      SBDATO1 : out std_logic;
      SBDATO2 : out std_logic;
      SBDATO3 : out std_logic;
      SBDATO4 : out std_logic;
      SBDATO5 : out std_logic;
      SBDATO6 : out std_logic;
      SBDATO7 : out std_logic;
      SBACKO : out std_logic;
      SPIIRQ : out std_logic;
      SPIWKUP : out std_logic;
      MI : in std_logic;
      SO : out std_logic;
      SOE : out std_logic;
      SI : in std_logic;
      MO : out std_logic;
      MOE : out std_logic;
      SCKI : in std_logic;
      SCKO : out std_logic;
      SCKOE : out std_logic;
      SCSNI : in std_logic;
      MCSNO0 : out std_logic;
      MCSNO1 : out std_logic;
      MCSNO2 : out std_logic;
      MCSNO3 : out std_logic;
      MCSNOE0 : out std_logic;
      MCSNOE1 : out std_logic;
      MCSNOE2 : out std_logic;
      MCSNOE3 : out std_logic
    );
  end component;

end components;