
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_riscv_multicycle is
end tb_riscv_multicycle;

architecture Behavioral of tb_riscv_multicycle is

    -- Component declaration for the RISC-V processor
    component riscv_multicycle is
        Port (
            clk     : in  STD_LOGIC;
            reset   : in  STD_LOGIC
        );
    end component;

    -- Signals for clock and reset
    signal clk     : STD_LOGIC := '0';
    signal reset   : STD_LOGIC := '1';

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the RISC-V processor
    uut: riscv_multicycle
        Port map (
            clk => clk,
            reset => reset
        );

    -- Clock generation process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Reset process
    reset_process : process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait;
    end process;

    -- Simulation process to run the program for 10 iterations
    sim_process : process
    begin
        -- Wait for reset to complete
        wait for 30 ns;

        -- Run the simulation for enough time to complete 10 iterations
        wait for 3000 ns;

        -- End simulation
        wait;
    end process;

end Behavioral;
