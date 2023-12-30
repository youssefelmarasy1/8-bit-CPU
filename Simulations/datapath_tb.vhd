----------------------------------------------------------------------------------
-- Filename : display_controller.vhdl
-- Author : Antonio Alejandro Andara Lara
-- Date : 31-Oct-2023
-- Design Name: accumulator_tb
-- Project Name: ECE 410 lab 3 2023
-- Description : testbench for the accumulator register of the simple CPU
-- Additional Comments:
-- Copyright : University of Alberta, 2023
-- License : CC0 1.0 Universal
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY datapath_tb IS
END datapath_tb;


ARCHITECTURE sim OF datapath_tb IS
        SIGNAL reset          :  STD_LOGIC;
        SIGNAL clock          :  STD_LOGIC := '0';
        SIGNAL mux_sel        :  STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
        SIGNAL immediate_data :  STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
        SIGNAL user_in        :  STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";
        SIGNAL acc_write      :  STD_LOGIC := '0';
        SIGNAL rf_address     :  STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
        SIGNAL rf_write       :  STD_LOGIC := '0' ;
        SIGNAL alu_sel        :  STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
        SIGNAL bits_rotate    :  STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
        SIGNAL output_enable  :  STD_LOGIC := '0';
        SIGNAL zero_flag      :  STD_LOGIC := '0';
        SIGNAL positive_flag  :  STD_LOGIC := '0';
        SIGNAL datapath_out   :  STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";

BEGIN

    uut: ENTITY WORK.datapath(Structural)
        PORT MAP( reset     => reset,
                  clock     => clock,
                  mux_sel => mux_sel,
                  immediate_data => immediate_data,
                  user_in => user_in,
                  acc_write => acc_write,
                  --acc_in    => acc_in,
                  --acc_out   => acc_out,
                  rf_address => rf_address,
                  rf_write => rf_write,
                  alu_sel => alu_sel,
                  bits_rotate => bits_rotate,
                  output_enable => output_enable,
                  zero_flag => zero_flag,
                  positive_flag => positive_flag,
                  datapath_out => datapath_out
                );
               
clk_process : PROCESS
    BEGIN
        WAIT FOR 10 ns;
        clock <= NOT clock;
    END PROCESS clk_process;

    stim_proc: PROCESS
    BEGIN
    -- Reset the accumulator
        reset <= '1';
        WAIT FOR 50 ns;
        reset <= '0';
    -- set inputs for 4:1 mux
        immediate_data <= "11110000";
        WAIT FOR 50ns;
        user_in <= "00001111";
        WAIT FOR 50ns;
        mux_sel <= "11"; --selects user_in 
        WAIT FOR 50ns;
        acc_write <= '1' ;
        WAIT FOR 20ns;
        acc_write <= '0' ;
        rf_address <= "010"; --store in Register 2
        WAIT FOR 50ns;
        rf_write <= '1';
        WAIT FOR 50ns;
        rf_write <= '0';
        WAIT FOR 50ns;
        alu_sel <= "100"; -- test case for ADD instruction
        --Select the ALU output
        mux_sel <= "00";
--        reset <= '0';
--        WAIT FOR 50ns;
        output_enable <= '1';
        WAIT FOR 40ns;
--        output_enable <= '0';
        --Show the Accumulator output in the tri-state buffer
        acc_write <= '1';
        WAIT FOR 20ns;
        acc_write <= '0';
--        output_enable <= '1';
--        WAIT FOR 50 ns;
--        output_enable <= '0';
        
        WAIT;
        
--        WAIT FOR 50ns;
--        acc_write <= '0';
--        WAIT FOR 50ns;
--        alu_sel <= "000";
--        WAIT FOR 50ns;
        
--        output_enable <= '1';
--        output_enable <= '0';
        
        
        
        
        
    END PROCESS;                
END sim;