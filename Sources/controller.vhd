----------------------------------------------------------------------------------
-- Company: Department of Electrical and Computer Engineering, University of Alberta
-- Engineer: Shyama Gandhi and Bruce Cockburn
-- Create Date: 10/29/2020 07:18:24 PM
-- Updated Date: 01/11/2021
-- Design Name: CONTROLLER FOR THE CPU
-- Module Name: cpu - behavioral(controller)
-- Description: CPU_LAB 3 - ECE 410 (2021)
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.01 - File Modified by Raju Machupalli (October 31, 2021)
-- Revision 2.01 - File Modified by Shyama Gandhi (November 2, 2021)
-- Revision 3.01 - File Modified by Antonio Andara (October 31, 2023)
-- Additional Comments:
--*********************************************************************************
-- The controller implements the states for each instructions and asserts appropriate control signals for the datapath during every state.
-- For detailed information on the opcodes and instructions to be executed, refer the lab manual.
-----------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY controller IS
    PORT( clock          : IN STD_LOGIC
        ; reset          : IN STD_LOGIC
        ; enter          : IN STD_LOGIC
        ; mux_sel        : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        ; immediate_data : BUFFER STD_LOGIC_VECTOR(7 DOWNTO 0)
        ; acc_write      : OUT STD_LOGIC
        ; rf_address     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        ; rf_write       : OUT STD_LOGIC
        ; alu_sel        : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        ; output_enable  : OUT STD_LOGIC
        ; zero_flag      : IN STD_LOGIC
        ; positive_flag  : IN STD_LOGIC
        ; PC_out         : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
        ; OPCODE_output  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        ; bits_rotate    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
        ; done           : OUT STD_LOGIC --should be zero except for one instruction, only a 1 when we "HALT"
        );
END controller;

ARCHITECTURE Behavioral OF controller IS
    --we "might" need to create new states
    TYPE state_type IS ( STATE_FETCH
                       , STATE_DECODE
                       , STATE_INA
                       , STATE_LDI
                       , STATE_LDA
                       , STATE_STA
                       , STATE_ADD
                       , STATE_SUB
                       , STATE_ROTR
                       , STATE_INC
                       , STATE_DEC
                       , STATE_AND
                       , STATE_OUTA
                       , STATE_JMPZ
                       , STATE_HALT
                       , STATE_JMPR
                       , STATE_ROTL
                       );

    SIGNAL state     : state_type;
    SIGNAL IR        : STD_LOGIC_VECTOR(7 DOWNTO 0); -- instruction register
    SIGNAL rrr       : STD_LOGIC_VECTOR(2 DOWNTO 0); --This will take the last 3-bits of the instruction (the register number) whenever needed and will be passed to the rf_address
    SIGNAL PC        : INTEGER RANGE 0 TO 31        := 0; -- program counter

-- Instructions and their opcodes (pre-decided)
    CONSTANT OPCODE_INA  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT OPCODE_LDI  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT OPCODE_LDA  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";    
    CONSTANT OPCODE_STA  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT OPCODE_ADD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT OPCODE_SUB  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    --First custom instruction: Jump Register
    CONSTANT OPCODE_JMPR: STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    CONSTANT OPCODE_ROTR : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    CONSTANT OPCODE_INC  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001";
    CONSTANT OPCODE_DEC  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
    CONSTANT OPCODE_AND : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011";
    --Second Custom instruction: Rotate left
    CONSTANT OPCODE_ROTL: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1100";
    CONSTANT OPCODE_JMPZ : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1101";
    CONSTANT OPCODE_OUTA : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1110";
    CONSTANT OPCODE_HALT : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111";


    -- program memory that will store the instructions sequentially
    TYPE PM_BLOCK IS ARRAY(0 TO 31) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    
BEGIN

    --opcode is kept up-to-date
    OPCODE_output <= IR(7 DOWNTO 4);
    
    PROCESS (clock) -- add sensitity list

        -- "PM" is the program memory that holds the instructions
        -- to be executed by the CPU 
        VARIABLE PM     : PM_BLOCK;

        -- To STATE_DECODE the 4 MSBs from the PC content
        VARIABLE OPCODE : STD_LOGIC_VECTOR(3 DOWNTO 0);
        
        

    BEGIN
-- RESET initializes all the control signals to 0.
        IF (reset = '1') THEN
            PC             <= 0;
            IR             <= (OTHERS => '0');
            PC_out         <= std_logic_vector(to_unsigned(PC, PC_out'length));
            mux_sel        <= "00";
            immediate_data <= (OTHERS => '0');
            acc_write      <= '0';
            rf_address     <= "000";
            rf_write       <= '0';
            alu_sel        <= "000";
            output_enable  <= '0';
            done           <= '0';
            bits_rotate    <= "00";
            state          <= STATE_FETCH;

------------------------------------------------
            -- assembly code for program goes here
--            PM(0) := "00010000"; --INA 
--            PM(1) := "00100000"; --LDI opcode
--            PM(2) := "10101010"; --2nd byte of LDI is the immediate data
--            PM(3) := "01000111"; --STA
--            PM(4) := "00010000"; --INA
--            PM(5) := "00100000"; --LDI opcode
--            PM(6) := "01101001"; --LDI Immediate Data 
--            PM(7) := "01000101"; --STA
--            PM(8) := "00110100"; --LDA, R[rrr]
              PM(0) := "00010000"; -- INA
              PM(1) := "01000000"; -- STA R[0]
              PM(2) := "00110000"; --LDA R[0]
              PM(3) := "10100000"; --DEC A
              PM(4) := "01000000"; -- STA R[0]
              PM(5) := "11100000"; -- OUT A
              PM(6) := "11010000"; --JMPZ x0C
              PM(7) := "00001100"; -- x0C
              PM(8) := "00100000"; -- LDI A x00
              PM(9) := "00000000"; -- x00
              PM(10) := "11010000"; -- JMPZ x02
              PM(11) := "00000010"; -- x02
              PM(12) := "00100000"; -- LDI A x0F
              PM(13) := "00001111"; -- x0F
              PM(14) := "01000000"; -- STA R[0]
              PM(15) := "00100000"; -- LDI A xAA
              PM(16) := "10101010"; -- xAA
              PM(17) := "10110000"; -- AND A R[0]
              PM(18) := "11100000"; -- OUT A
              PM(19) := "10010000"; -- INC A
              PM(20) := "01000000"; -- STA R[0]
              PM(21) := "00100000"; -- LDI A x0F
              PM(22) := "00001111"; -- x0F
              PM(23) := "01010000"; -- ADD R[0]
              PM(24) := "11100000"; -- OUT A
              PM(25) := "11110000"; -- HALT
              
              
              
              
            -- add more instructions as needed
--------------------------------------------------

        ELSIF RISING_EDGE(clock) THEN
            CASE state IS

                WHEN STATE_FETCH => -- FETCH instruction
                    PC_out         <= std_logic_vector(to_unsigned(PC, PC_out'length));
                    -- ****************************************
                    -- write the 8-bit instruction into the Instruction Register here:
                    IR <=  PM(PC);
				    -- ****************************************
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0';
                    rf_address     <= "000";
                    rf_write       <= '0';
                    alu_sel        <= "000";
                    done           <= '0';
                                    
                    IF (enter = '1') THEN
                    -- ****************************************
                    -- increment the program counter here:
                        PC <= PC +1;
				    -- ****************************************
                        output_enable  <= '0';
                        state  <= STATE_DECODE;
                    ELSE
                        state  <= STATE_FETCH;
                    END IF;

                WHEN STATE_DECODE => -- DECODE instruction

                    OPCODE := IR(7 DOWNTO 4);

                    CASE OPCODE IS
                        -- every instruction must have an execute state
                        WHEN OPCODE_INA  => state <= STATE_INA;
                        WHEN OPCODE_LDI  => state <= STATE_LDI;
                        WHEN OPCODE_LDA  => state <= STATE_LDA;
                        WHEN OPCODE_STA  => state <= STATE_STA;
                        WHEN OPCODE_ADD  => state <= STATE_ADD;
                        WHEN OPCODE_SUB  => state <= STATE_SUB;
                        WHEN OPCODE_ROTR => state <= STATE_ROTR;
                        WHEN OPCODE_INC  => state <= STATE_INC;
                        WHEN OPCODE_DEC  => state <= STATE_DEC;
                        WHEN OPCODE_AND  => state <= STATE_AND;
                        WHEN OPCODE_JMPZ => state <= STATE_JMPZ;
                        WHEN OPCODE_OUTA => state <= STATE_OUTA;
                        WHEN OPCODE_HALT => state <= STATE_HALT;
                        --These are the execute states for the two custom instructions
                        WHEN OPCODE_JMPR => state <= STATE_JMPR;
                        WHEN OPCODE_ROTL => state <= STATE_ROTL;
                        --WHEN OPCODE_HALT => state <= STATE_HALT;
                        WHEN OTHERS      => state <= STATE_HALT;
                    END CASE;

                    mux_sel        <= "00";

                    -- ****************************************
                    -- Pre-fetching immediate data relaxes the
                    -- requirement for PM to be very fast
                    -- for LDI to work properly.
                    -- pre-fetch immediate data value here:

                    -- ****************************************
                    immediate_data <= PM(PC);
                    acc_write      <= '0';
                    
                    -- ****************************************
                    -- set up the register file address here to
                    -- reduce the delay for waiting one more cycle
                    rrr <= IR(2 downto 0); -- extracting the last 3 bits to know the register value
                    rf_address <= rrr; 
                    -- ****************************************
                    
                    rf_write       <= '0';
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';

                    -- ****************************************
                    -- set up the bit rotate value here:
                    bits_rotate  <= IR(1 downto 0);
                    -- ****************************************

                WHEN STATE_INA => -- INA exceute
                    mux_sel        <= "11";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1';
                    rf_address     <= "000";
                    rf_write       <= '0';
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';
                    state          <= STATE_FETCH;
                
                WHEN STATE_LDI => -- LDI exceute
                    mux_sel        <= "10";
                    -- immediate data has already been pre-fetched
                    acc_write      <= '1';
                    rf_address     <= "000";
                    rf_write       <= '0';
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';
                    PC             <= PC + 1;
                    state          <= STATE_FETCH;

                WHEN STATE_LDA => -- LDA exceute
                -- LDA loads the value from register into accumulator
                    -- *********************************
                    -- write the entire state for STATE_LDA
                    mux_sel        <= "01";
                    -- immediate data has already been pre-fetched
                    acc_write      <= '1'; --Everywhere acc_write = 1 except STA
                    --rf_address     <= rrr; --These are the last 3 bits of the 8-bit code for the instruction
                    -- rf_address (Register address)has already been pre-fetched
                    rf_write       <= '0'; -- we're not writing anything into register here
                    alu_sel        <= "000"; -- here it's zero because LDA instructiion does nothing with the ALU block
                    output_enable  <= '0';
                    done           <= '0';
                    -- PC already updates when you press enter
                    --PC             <= PC + 1;
                    state          <= STATE_FETCH; 
                    
                    -- *********************************

                WHEN STATE_STA => -- STA exceute
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0';
                    --rf_address     <= IR(2 DOWNTO 0);
                    -- is the previous line necessary? why? No, because we already have it pre-fetched 
                    rf_write       <= '1';
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';
                    state          <= STATE_FETCH;
                --Diff mux_sel and acc_write
                
                WHEN STATE_ADD => -- ADD exceute
                -- add contents of accumulator and register and store into accumulator
                    -- *********************************
                    -- write the entire state for STATE_ADD
                    mux_sel        <= "00"; --Use input #1 of the MUX (Register file contents)
                    immediate_data <= (OTHERS => '0');
                    -- immediate data has already been pre-fetched
                    acc_write      <= '1'; -- nothing to change in the accumulator and taking pre-existing data available
                    
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "100"; -- 100 corresponds to ADD in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    --PC             <= PC + 1;
                    state          <= STATE_FETCH; --LDI stores immediate value into accumulator
                    
                    -- *********************************

                WHEN STATE_SUB => -- SUB exceute
                -- sub register content from accumulator content and store in accumulator
                    -- *********************************
                    -- write the entire state for STATE_SUB
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- nothing to change in the accumulator and taking pre-existing data available
                    
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "101"; -- 100 corresponds to ADD in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    --PC             <= PC + 1;
                    state          <= STATE_LDI; -- LDI stores immediate value into accumulator
                    
                    -- *********************************
                
                -- *********************************
                -- write the entire case handling for custom
                -- instruction 1
                -- *********************************
                WHEN STATE_ROTL => -- ROTL exceute
                -- rotate accumulator content left by xx bits
                    -- *********************************
                    -- write the entire state for STATE_ROTR
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- change in the accumulator because we rotate bits
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "010"; -- 010 corresponds to rotate left in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                WHEN STATE_ROTR => -- ROTR exceute
                -- rotate accumulator content right by xx bits
                    -- *********************************
                    -- write the entire state for STATE_ROTR
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- change in the accumulator because we rotate bits
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "011"; -- 011 corresponds to rotate right in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    --PC             <= PC + 1;
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                    -- *********************************

                WHEN STATE_INC =>
                -- increment value stored in accumulator
                    -- *********************************
                    -- write the entire state for STATE_INC
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- change in the accumulator as we increment it
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "110"; -- 110 corresponds to INC in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                    -- *********************************
                
                WHEN STATE_DEC =>
                -- decrement value store in accumulator
                    -- *********************************
                    -- write the entire state for STATE_DEC
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- change in the accumulator and decrement
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "111"; -- 111 corresponds to ADD in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    --PC             <= PC + 1;
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                    -- *********************************

                WHEN STATE_AND =>
                -- bitwise AND of accumulator and register 
                    -- *********************************
                    -- write the entire state for STATE_AND
                    mux_sel        <= "00";
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '1'; -- change in the accumulator and decrement
                    --rf_address     <= (OTHERS => '0');
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "001"; -- 001 corresponds to bitwise AND in ALU address bit operations
                    output_enable  <= '0'; 
                    done           <= '0';
                    --PC             <= PC + 1;
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                    -- *********************************
                
                -- *********************************
                -- write the entire case handling for custom
                -- instruction 1
                -- *********************************
                WHEN STATE_JMPR => -- JMPR exceute
                --Allows the program counter (PC) to jump forward or backward from the current
                --location by a specified offset rather than to a fixed address.
                -- check for zero flag. If zero flag = 1 then absolute jump to memory address 000a aaaa 
                    -- *********************************
                    -- write the entire state for STATE_JMPZ
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0';
                    rf_write       <= '0';
                    
                    IF zero_flag = '1' THEN
                        PC <= PC + to_integer(unsigned(immediate_data));   
                    ELSE
                        PC <= PC +1;
                    END IF;
                    
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';
                    state          <= STATE_FETCH;
                
                WHEN STATE_JMPZ => -- JMPZ exceute
                -- check for zero flag. If zero flag = 1 then absolute jump to memory address 000a aaaa
                    -- *********************************
                    -- write the entire state for STATE_JMPZ
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0';
                    rf_write       <= '0';
                    
                    IF zero_flag = '1' THEN
                        PC <= to_integer(unsigned(immediate_data));   
                    ELSE
                        PC <= PC +1;
                    END IF;
                    
                    alu_sel        <= "000";
                    output_enable  <= '0';
                    done           <= '0';
                    state          <= STATE_FETCH;
                    
                    -- *********************************

                WHEN STATE_OUTA => -- OUTA exceute
                -- display 8 bit result from accumulator
                    -- *********************************
                    -- write the entire state for STATE_OUTA
                    mux_sel        <= "00"; -- immediate data passing through mux
                    -- immediate data has already been pre-fetched
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0'; -- change in the accumulator and decrement
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "000"; 
                    output_enable  <= '1'; 
                    done           <= '0';
                    
                    state          <= STATE_FETCH; -- LDI stores immediate value into accumulator
                    
                    -- *********************************

                WHEN STATE_HALT => -- HALT execute
                --stop/halt execution
                    -- *********************************
                    -- write the entire state for STATE_HALT
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    -- immediate data has already been pre-fetched
                    acc_write      <= '0'; -- change in the accumulator and decrement
                    rf_address     <= "000";
                    rf_write       <= '0'; -- nothing to change, taking pre-existing value in register and going into ALU 
                    alu_sel        <= "000"; 
                    output_enable  <= '1'; 
                    done           <= '1';
                    state          <= STATE_HALT; -- LDI stores immediate value into accumulator
                    
                    -- *********************************

                WHEN OTHERS =>
                    mux_sel        <= "00";
                    immediate_data <= (OTHERS => '0');
                    acc_write      <= '0';
                    rf_address     <= "000";
                    rf_write       <= '0';
                    alu_sel        <= "000";
                    output_enable  <= '1';
                    done           <= '1';
                    state          <= STATE_HALT;

            END CASE;
        END IF;
    END PROCESS;
    
END Behavioral;
