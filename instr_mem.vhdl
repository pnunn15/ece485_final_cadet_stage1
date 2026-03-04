library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity instr_mem is
    Port (
        addr    : in  STD_LOGIC_VECTOR(31 downto 0);
        instr   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end instr_mem;

architecture Behavioral of instr_mem is
    type memory_array is array (0 to 255) of STD_LOGIC_VECTOR(31 downto 0);
    signal memory : memory_array := (
        -- used https://www.binaryhexconverter.com/ to convert from binary to hex
        -- used https://www.exploringbinary.com/twos-complement-converter/ to convert from decimal to 2s complement
        0 => x"00900293", -- addi x5, x0, 9         000000001001 00000 000 00101 0010011
--        1 => x"00000317", -- load_addr x6, array (custom instruction), where array is 0x10000000
--        2 => x"00032383", -- lw x7, 0(x6)           
--        3 => x"00430313", -- loop: addi x6, x6, 4   
--        4 => x"00032503", -- lw x10, 0(x6)    
--        5 => x"007503B3", -- add x7, x10, x7 
--        6 => x"00129293", -- subi x5, x5, 1 (or "addi x5, x5, -1")  
--        7 => x"FC029CE3", -- bne x5, x0, loop   1 [jump -20; note: assumes PC is incremented by 4]
--        8 => x"FFDFF06F", -- done: j done             [jump -4; note: assumes PC is incremented by 4]               
        others => (others => '0')
    );
begin
    process(addr)
    begin
        instr <= memory(to_integer(unsigned(addr(7 downto 0))));
    end process;
end Behavioral;