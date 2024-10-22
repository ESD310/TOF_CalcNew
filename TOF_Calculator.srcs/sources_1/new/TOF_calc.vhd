
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOF_calc is
    Port (
        --sample_in : IN std_logic_vector (11 downto 0) := "011010011011";
        rdy_in : IN std_logic;
        --TOF_out : OUT std_logic_vector (19 downto 0);
        --rdy_out : OUT std_logic;
        klok : IN std_logic;
        reset_in : IN std_logic );
end TOF_calc;

architecture Behavioral of TOF_calc is

type t_LUT is array (0 to 200) of std_logic_vector(11 downto 0);

signal LUT : t_LUT := (others=>(others => '0'));
signal sample_shiftReg : t_LUT :=(others=>(others => '0'));
signal max_corr : unsigned(31 downto 0) := (others => '0');
signal max_shift : unsigned(20 downto 0) := (others => '0'); 
signal temp : unsigned(31 downto 0) := (others => '0');
signal cur_shift : unsigned(20 downto 0) := (others => '0');
signal k : integer := 0;


begin

-- Make LUT for sent signal
-- We need 200 samples for a 16 wave measurement   (1/40000)*16*500.000)  
process(rdy_in)
begin
    if(rising_edge(rdy_in)) then 
        for i in 150 downto 50 loop
            LUT(i) <= "111111111111";
        end loop;
    end if;
end process;



-- Put sample into shift register
process(rdy_in) 
begin
    if(rising_edge(rdy_in)) then
        sample_shiftReg(0) <= "011010011011";
        for i in 200 downto 1 loop
            sample_shiftReg(i) <= sample_shiftReg(i-1);
        end loop;
    end if;
end process;


-- Compare shift register to LUT
process (rdy_in, klok)
    variable enable : std_logic := '0';
begin

if (enable = '0') then
    if (rising_edge(rdy_in)) then
    enable := '1';
    end if;
end if;

if (enable = '1') then
    if( rising_edge(klok)) then
    --Calculate xcor
        if (k <= 100) then
            temp <= temp + ("00000000" & ( unsigned(sample_shiftReg(k)) * unsigned(LUT(k)) ));
            k <= k + 1;
            
            -- Check if biggest yet corr
            if (temp > max_corr) then
            max_corr <= temp;
            max_shift <= cur_shift;
            end if;
        
        -- if for loop done, reset
        else
        k <= 0;
        enable := '0';
        temp <= "00000000000000000000000000000000";
        cur_shift <= cur_shift + 1;
        end if;
        -- check if best yet xcor
    end if;
end if;
end process;


end Behavioral;
