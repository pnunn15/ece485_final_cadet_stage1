
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
        a       : in  STD_LOGIC_VECTOR(31 downto 0);
        b       : in  STD_LOGIC_VECTOR(31 downto 0);
        op      : in  STD_LOGIC_VECTOR(3 downto 0);
        result  : out STD_LOGIC_VECTOR(31 downto 0)
    );
end alu;

architecture Behavioral of alu is
begin
    process(a, b, op)
    begin
        case op is
            when "0000" => result <= std_logic_vector(signed(a) + signed(b)); -- ADD
            when "1111" => result <= std_logic_vector(signed(a) - signed(b)); -- SUB
            when others => result <= (others => '0');
        end case;
    end process;
end Behavioral;
