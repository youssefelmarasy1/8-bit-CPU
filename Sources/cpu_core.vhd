----------------------------------------------------------------------------------
-- Company: Department of Electrical and Computer Engineering, University of Alberta
-- Engineer: Shyama Gandhi and Bruce Cockburn
-- Create Date: 10/29/2020 07:18:24 PM
-- Design Name: CONTROLLER AND DATAPATH FOR THE CPU
-- Module Name: cpu - structural
-- Description: CPU LAB 3 - ECE 410 (2021)
-- Revision:
-- Revision 0.01 - File Created
-- Revision 1.01 - File Modified by Raju Machupalli (October 31, 2021)
-- Revision 2.01 - File Modified by Shyama Gandhi (November 2, 2021)
-- Revision 3.01 - File Modified by Antonio Andara (October 31, 2023)
-- *******************************************************************************
-- Additional Comments:
-- The CPU core integrates the datapath and the controller FSM
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY cpu_core IS
---------------------------------------------------------------------------
-- finish the port declaration with the appropriate types
    PORT( clock         : IN STD_LOGIC
        ; reset         : IN STD_LOGIC
        ; enter         : IN STD_LOGIC
        ; user_input    : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
        ; CPU_output    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        ; PC_output     : OUT STD_LOGIC_VECTOR(4 DOWNTO 0)
        ; OPCODE_output : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        ; done          : OUT STD_LOGIC
        );
---------------------------------------------------------------------------
END cpu_core;

ARCHITECTURE Structural OF cpu_core IS
---------------------------------------------------------------------------
-- declare any necessary signals if any
---------------------------------------------------------------------------
    SIGNAL mux_sel: STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL immediate_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL acc_write      : STD_LOGIC;
    SIGNAL rf_address     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rf_write       : STD_LOGIC;
    SIGNAL alu_sel        : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL output_enable  : STD_LOGIC;
    SIGNAL zero_flag      : STD_LOGIC;
    SIGNAL positive_flag  : STD_LOGIC;
    --SIGNAL PC_out         : STD_LOGIC_VECTOR(4 DOWNTO 0);
    --SIGNAL OPCODE_output  : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL bits_rotate    : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL clock_div           : STD_LOGIC;
    --SIGNAL user_in     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
BEGIN

    -- CPU clock divider, used to slow the processing of instructions
    -- allowing for manual testing. for simulation use freq_out <= 62_500_000
    core_div : ENTITY WORK.clock_divider(Behavioral)
        GENERIC MAP (freq_out => 62_500_000)
        PORT MAP( clock => clock
                , clock_div => clock_div
                );

    controller : ENTITY WORK.controller(Behavioral)
        PORT MAP (clock => clock_div,
                  reset => reset,
                  enter => enter,
                  mux_sel => mux_sel,
                  immediate_data => immediate_data,
                  acc_write => acc_write,      
                  rf_address => rf_address,    
                  rf_write => rf_write,      
                  alu_sel => alu_sel,       
                  output_enable => output_enable,
                  zero_flag => zero_flag,      
                  positive_flag => positive_flag, 
                  PC_out => PC_output,         
                  OPCODE_output => OPCODE_output,  
                  bits_rotate => bits_rotate,   
                  done => done
                  );-- instantiate controller entity

    datapath : ENTITY WORK.datapath(Structural)
        PORT MAP (clock => clock_div, 
                  reset => reset,        
                  mux_sel => mux_sel,     
                  immediate_data => immediate_data,
                  user_in  => user_input,  
                  acc_write => acc_write,    
                  rf_address => rf_address,    
                  rf_write => rf_write,     
                  alu_sel => alu_sel,       
                  bits_rotate => bits_rotate,  
                  output_enable => output_enable, 
                  zero_flag => zero_flag,     
                  positive_flag => positive_flag, 
                  datapath_out  => CPU_output         
        );-- instantiate datapath entity

END Structural;
