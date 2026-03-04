---------------------------------------------------------------------------------------
-- Final Project Stage 1: RISCV_Multicycle
-- AUTHOR: C1C Payton Nunn
-- DESCRIPTION:
--   Implementation of a 5 stage RISC-V multicycle architecture (IF-ID-EX-MEM-WB)
--   that is NOT pipelined [all 5 stages of the first instruction completes before
--   the next instruction is called.
--   The only instructions implemented are:
--          ADD, ADDI, SUBI, LW, SW, j, and BNE
--          Also implemented is a custom instruction Load_Addr, similar to LA,
--          but always loads the defaults address of 0x10000000
--          All other decoded instructions are assumed to be a NOP,
--          which sets all control signals to '0'
--   The Data memory (LOOP label) begins at memory location 0x10000000
--
---------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity riscv_multicycle is
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC
    );
end riscv_multicycle;

architecture Behavioral of riscv_multicycle is

    type state_type is (FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK);
    signal state : state_type := FETCH;

    -- Basic Registers
    signal pc, pc_byte_not_word, NPC, next_pc           : STD_LOGIC_VECTOR(31 downto 0);
    signal instr                                        : STD_LOGIC_VECTOR(31 downto 0);
    signal opcode                                       : STD_LOGIC_VECTOR(6 downto 0);
    signal reg1_data, reg2_data                         : STD_LOGIC_VECTOR(31 downto 0);
    signal alu_input_a, alu_input_b, alu_result  : STD_LOGIC_VECTOR(31 downto 0);
    signal wb_data                               : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_data, data_memory_byte_not_word   : STD_LOGIC_VECTOR(31 downto 0);
    signal clock_counter : integer := 1;
    -- control signals
    signal mem_read   : STD_LOGIC;
    signal mem_write, mem_write_chip  : STD_LOGIC;
    signal alu_src    : STD_LOGIC;
    signal branch     : STD_LOGIC;
    signal jump       : STD_LOGIC;
    signal load_addr  : STD_LOGIC;
    signal reg_write, reg_write_chip  : STD_LOGIC;
    signal rs1, rs2, rd : STD_LOGIC_VECTOR(4 downto 0);
    signal wb_rd        : STD_LOGIC_VECTOR(4 downto 0);
    
    -- Registers for pipeline stages
    signal if_id_npc, id_ex_npc, ex_mem_npc, mem_wb_npc             : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal id_ex_alu_result, ex_mem_alu_result, mem_wb_alu_result   : STD_LOGIC_VECTOR(31 downto 0);
    signal if_id_alu_op, id_ex_alu_op, ex_mem_alu_op, mem_wb_alu_op : STD_LOGIC_VECTOR(3 downto 0);
    signal if_id_imm, id_ex_imm, ex_mem_imm, mem_wb_imm             : STD_LOGIC_VECTOR(31 downto 0);
    signal if_id_instr, id_ex_instr, ex_mem_instr, mem_wb_instr     : STD_LOGIC_VECTOR(31 downto 0); 
    signal if_id_reg1_data, id_ex_reg1_data, ex_mem_reg1_data, mem_wb_reg1_data : STD_LOGIC_VECTOR(31 downto 0);
    signal if_id_reg2_data, id_ex_reg2_data, ex_mem_reg2_data, mem_wb_reg2_data : STD_LOGIC_VECTOR(31 downto 0);
    signal if_id_rs1, id_ex_rs1, ex_mem_rs1, mem_wb_rs1 : STD_LOGIC_VECTOR(4 downto 0);
    signal if_id_rs2, id_ex_rs2, ex_mem_rs2, mem_wb_rs2 : STD_LOGIC_VECTOR(4 downto 0);
    signal if_id_rd, id_ex_rd, ex_mem_rd, mem_wb_rd     : STD_LOGIC_VECTOR(4 downto 0);

    -- control signals for pipeline stages
    signal if_id_reg_write, id_ex_reg_write, ex_mem_reg_write, mem_wb_reg_write  : STD_LOGIC;
    signal if_id_alu_src, id_ex_alu_src, ex_mem_alu_src, mem_wb_alu_src          : STD_LOGIC;
    signal if_id_mem_read, id_ex_mem_read, ex_mem_mem_read, mem_wb_mem_read      : STD_LOGIC;
    signal if_id_mem_write, id_ex_mem_write, ex_mem_mem_write, mem_wb_mem_write  : STD_LOGIC;
    signal if_id_branch, id_ex_branch, ex_mem_branch, mem_wb_branch              : STD_LOGIC;
    signal if_id_jump, id_ex_jump, ex_mem_jump, mem_wb_jump                      : STD_LOGIC;
    signal if_id_load_addr, id_ex_load_addr, ex_mem_load_addr, mem_wb_load_addr  : STD_LOGIC;
    
     -- Additional signals [used in later stages]
    signal stall, start_stall, double_stall        : STD_LOGIC;
    signal stall_counter : integer range 0 to 3 := 0;
    signal mux_select_A  : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal mux_select_B  : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
 
    -- OLDIES
    -- Signals for multicycle stages

    signal alu_op     : STD_LOGIC_VECTOR(3 downto 0);
    signal imm        : STD_LOGIC_VECTOR(31 downto 0);

    -- Pipeline registers
    signal if_id_pc    : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    --signal id_ex_reg1  : STD_LOGIC_VECTOR(31 downto 0);
    --signal id_ex_reg2  : STD_LOGIC_VECTOR(31 downto 0);
    signal ex_mem_alu  : STD_LOGIC_VECTOR(31 downto 0);
    --signal ex_mem_reg2 : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_wb_alu  : STD_LOGIC_VECTOR(31 downto 0);
    signal mem_wb_data : STD_LOGIC_VECTOR(31 downto 0);

    -- Additional signals

     


    
    component pc_live 
    Port (
        clk     : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        pc_in   : in  STD_LOGIC_VECTOR(31 downto 0);
        pc_out  : out STD_LOGIC_VECTOR(31 downto 0)
    );
    end component;
            
    component instr_mem
        Port (
            addr : in  STD_LOGIC_VECTOR(31 downto 0);
            instr   : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component reg_file
        Port (
            clk     : in  STD_LOGIC;
            rs1     : in  STD_LOGIC_VECTOR(4 downto 0);
            rs2     : in  STD_LOGIC_VECTOR(4 downto 0);
            rd      : in  STD_LOGIC_VECTOR(4 downto 0);
            data_in : in  STD_LOGIC_VECTOR(31 downto 0);
            reg_write : in  STD_LOGIC;
            data_out1     : out STD_LOGIC_VECTOR(31 downto 0);
            data_out2     : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;


    component control_unit 
        Port (
        opcode      : in  STD_LOGIC_VECTOR(6 downto 0);
        reg_write   : out STD_LOGIC;
        mem_read    : out STD_LOGIC;
        mem_write   : out STD_LOGIC;
        alu_src     : out STD_LOGIC;
        branch      : out STD_LOGIC;
        load_addr   : out STD_LOGIC;  -- Custom signal for load_addr instruction
        jump        : out STD_LOGIC
        );
    end component;

    component immediate_generator is
    Port (
        instr : in  STD_LOGIC_VECTOR(31 downto 0);
        imm   : out STD_LOGIC_VECTOR(31 downto 0)
    );
    end component;

   component alu_control is
    Port (
        funct7 : in  STD_LOGIC_VECTOR(6 downto 0);
        funct3 : in  STD_LOGIC_VECTOR(2 downto 0);
        alu_op : out STD_LOGIC_VECTOR(3 downto 0)
    );
    end component;

    component alu
        Port (
            a       : in  STD_LOGIC_VECTOR(31 downto 0);
            b       : in  STD_LOGIC_VECTOR(31 downto 0);
            op      : in  STD_LOGIC_VECTOR(3 downto 0);
            result  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component data_mem
        Port (
            addr    : in  STD_LOGIC_VECTOR(31 downto 0);
            data_in : in  STD_LOGIC_VECTOR(31 downto 0);
            mem_read  : in  STD_LOGIC;
            mem_write : in  STD_LOGIC;
            data_out  : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

begin
    -- clock counter process
    process(clk, reset)
    begin
        if reset = '1' then
            clock_counter <= 1;
        elsif rising_edge(clk) then
            clock_counter <= clock_counter + 1;
        end if;
    end process;

    -- PC logic
    pc_inst: pc_live
        port map (
            clk    => clk,
            reset  => reset,
            pc_in  => if_id_pc,   -- see writeback stage where the PC for the next clock cycle is determined
            pc_out => pc
        );

    NPC <= std_logic_vector(signed(pc) + 4);

    -- state machine to walk through 5 cyles per instruction (not pipelined)
    -- Remove this when adding the pipeline registers and pipelining
    process(clk, reset)
        begin
            if reset = '1' then
            elsif rising_edge(clk) then
                case state is
                    when FETCH =>
                        state <= DECODE;
                    when DECODE =>
                        state <= EXECUTE;
                    when EXECUTE =>
                        state <= MEMORY;
                    when MEMORY =>
                        state <= WRITEBACK;
                    when WRITEBACK =>
                        state <= FETCH;
                end case;
            end if;
        end process;   
    
    -------------------------- IF state hardware ---------------------------------------------
    -- Instruction memory
    pc_byte_not_word <= "00" & pc(31 downto 2);  -- divide by 4 by shifting left 2, since byte addressable, not word addressable
    instr_mem_inst: instr_mem
        port map (
            --addr  => pc,
            addr  => pc_byte_not_word,
            instr => instr
        );
    
    -- IF/ID pipeline register
    if_id_instr <= instr;
    if_id_npc <= NPC;
    -------------------------- ID state hardware ---------------------------------------------
    -- Decode instruction fields
    rs1 <= if_id_instr(19 downto 15);
    rs2 <= if_id_instr(24 downto 20);
    rd  <= if_id_instr(11 downto 7);
    opcode <= if_id_instr(6 downto 0);

    -- ALU control unit
    alu_control_inst: alu_control
        port map (
            funct3 => if_id_instr(14 downto 12),
            funct7 => if_id_instr(31 downto 25),
            alu_op => alu_op
        );

    -- Register file
    reg_file_inst: reg_file
        port map (
            clk       => clk,
            reg_write => reg_write_chip,  -- write is dangerous... only want to do this on a specific clock cycle
            rs1       => rs1,
            rs2       => rs2,
            rd        => wb_rd,
            data_in   => wb_data,  -- see writeback stage where mux selects correct value to write to register, wb_data?
            data_out1 => reg1_data,
            data_out2 => reg2_data
        );

    -- Control unit
    control_unit_inst: control_unit
        port map (
            opcode    => opcode,
            reg_write => reg_write,
            mem_read  => mem_read,
            mem_write => mem_write,
            alu_src   => alu_src,
            branch    => branch,
            load_addr => load_addr,
            jump      => jump
        );

    -- Immediate generator
    immediate_generator_inst: immediate_generator
        port map (
            instr => if_id_instr,
            imm   => imm
        );

    -- ID/EX pipeline register
    id_ex_alu_op <= alu_op;
    id_ex_rd <= if_id_instr(11 downto 7);
    id_ex_reg1_data <= reg1_data;
    id_ex_reg2_data <= reg2_data;
    id_ex_imm  <= imm;
    id_ex_npc <= if_id_npc;
    id_ex_reg_write <= reg_write;
    id_ex_alu_src <= alu_src;
    id_ex_mem_read <= mem_read;
    id_ex_mem_write <= mem_write;
    id_ex_branch <= branch;
    id_ex_jump <= jump;
    id_ex_load_addr <= load_addr;
    -------------------------- EX state hardware ---------------------------------------------
    
    alu_input_a <= id_ex_reg1_data;
    -- mux to select alu input B
    alu_input_b <= id_ex_imm when id_ex_alu_src = '1' else
                   id_ex_reg2_data;
    -- ALU
    alu_inst: alu
        port map (
            a      => alu_input_a,
            b      => alu_input_b,
            op     => id_ex_alu_op,
            result => alu_result
        );

    -- EX/MEM pipeline register
    ex_mem_alu  <= alu_result;
    ex_mem_rd <= id_ex_rd;
    ex_mem_reg2_data <= id_ex_reg2_data;
    ex_mem_npc <= id_ex_npc;
    ex_mem_imm <= id_ex_imm;
    ex_mem_reg_write <= id_ex_reg_write;
    ex_mem_alu_src <= id_ex_alu_src;
    ex_mem_mem_read <= id_ex_mem_read;
    ex_mem_mem_write <= id_ex_mem_write;
    ex_mem_branch <= id_ex_branch;
    ex_mem_jump <= id_ex_jump;
    ex_mem_load_addr <= id_ex_load_addr;
    -------------------------- MEM state hardware ---------------------------------------------
    
    -- Data memory
    data_memory_byte_not_word <= "00" & ex_mem_alu(31 downto 2);  -- divide by 4 by shifting left 2, since byte addressable, not word addressable
    data_mem_inst: data_mem
        port map (
            addr      => data_memory_byte_not_word,
            data_in   => ex_mem_reg2_data,
            data_out  => mem_data,
            mem_read  => mem_read,
            mem_write => mem_write_chip  -- write is dangerous... only want to do this on a specific clock cycle
        );

    -- Moore Machine, outputs determined by State
    -- MEMORY
    mem_write_chip <= '1' when (state = MEMORY and mem_write = '1') else '0';  -- ensure only write to memory during this state
    next_pc <= std_logic_vector(signed(ex_mem_npc) + signed(ex_mem_imm)) when (state = MEMORY and ex_mem_branch = '1' and ex_mem_alu /= x"00000000") else
               std_logic_vector(signed(ex_mem_npc) + signed(ex_mem_imm)) when (state = MEMORY and ex_mem_jump = '1') else
               ex_mem_npc when state = MEMORY and (ex_mem_jump = '0' and (ex_mem_branch = '0' or ex_mem_alu = x"00000000")) else
               next_pc;  -- otherwise, keep the same pc until time to update

    -------------------------- WB state hardware ---------------------------------------------
    -- MEM/WB pipeline register
    mem_wb_alu  <= ex_mem_alu;
    mem_wb_rd <= ex_mem_rd;
    mem_wb_data <= mem_data;
    mem_wb_reg_write <= ex_mem_reg_write;
    mem_wb_alu_src <= ex_mem_alu_src;
    mem_wb_mem_read <= ex_mem_mem_read;
    mem_wb_mem_write <= ex_mem_mem_write;
    mem_wb_branch <= ex_mem_branch;
    mem_wb_jump <= ex_mem_jump;
    mem_wb_load_addr <= ex_mem_load_addr;

    -- Moore Machine, outputs determined by State
    reg_write_chip <= '1' when (state = WRITEBACK and mem_wb_reg_write = '1') else '0'; -- ensure only write to registers during this state
    if_id_pc   <= next_pc when state = WRITEBACK else if_id_pc; -- only lets this update during WRITEBACK
    wb_data <= x"10000000" when (state = WRITEBACK and mem_wb_load_addr = '1') else
               mem_wb_data when (state = WRITEBACK and mem_wb_mem_read = '1') else
               mem_wb_alu  when (state = WRITEBACK and mem_wb_reg_write = '1') else
               wb_data;  -- only allow this to change during Writeback

    wb_rd   <= mem_wb_rd; -- Destination register
end Behavioral;
