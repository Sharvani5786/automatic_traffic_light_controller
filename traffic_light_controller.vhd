library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  
                     -- Traffic ligh system for a intersection between highway and                                   farm way 
                     -- There is a sensor on the farm way side, when there are vehicles, 
                     -- Traffic light turns to YELLOW, then GREEN to let the vehicles cross the highway 
                     -- Otherwise, always green light on Highway and Red light on farm way 
entity traffic_light_controller is
 port ( sensor  : in STD_LOGIC; -- Sensor 
        clk  : in STD_LOGIC;    -- clock 
        rst_n: in STD_LOGIC;    -- reset active low 
        L_H  : out STD_LOGIC_VECTOR(2 downto 0); -- light outputs of high way
        L_F  : out STD_LOGIC_VECTOR(2 downto 0) -- light outputs of farm way
                                                 --RED_YELLOW_GREEN 
      );
end traffic_light_controller;

architecture traffic_light of traffic_light_controller is
signal counter_1s: std_logic_vector(27 downto 0):= x"0000000";
signal delay_count:std_logic_vector(3 downto 0):= x"0";
signal delay_10s, delay_3s_F,delay_3s_H, R_L_ENABLE, Y_L1_ENABLE,Y_L2_ENABLE: std_logic:='0';
signal clk_1s_enable: std_logic; -- 1s clock enable 
type FSM_States is (HGRE_FRED, HYEL_FRED, HRED_FGRE, HRED_FYEL);
                    -- HGRE_FRED : Highway green and farm red
                    -- HYEL_FRED : Highway yellow and farm red
                    -- HRED_FGRE : Highway red and farm green
                    -- HRED_FYEL : Highway red and farm yellow
signal current_state, next_state: FSM_States;
begin
                    -- next state FSM sequential logic 
process(clk,rst_n) 
begin
if(rst_n='0') then
 current_state <= HGRE_FRED;
elsif(rising_edge(clk)) then 
 current_state <= next_state; 
end if; 
end process;

     -- FSM combinational logic 
process(current_state,sensor,delay_3s_F,delay_3s_H,delay_10s)
begin
case current_state is 
when HGRE_FRED =>       -- When Green light on Highway and Red light on Farm way
 R_L_ENABLE <= '0';     -- disable RED light delay counting
 Y_L1_ENABLE <= '0';    -- disable YELLOW light Highway delay counting
 Y_L2_ENABLE <= '0';    -- disable YELLOW light Farmway delay counting
 L_H <= "001";  -- Green light on Highway
 L_F <= "100";  -- Red light on Farm way 
 if(sensor = '1') then  -- if vehicle is detected on farm way by sensors
  next_state <= HYEL_FRED;
  
  -- High way turns to Yellow light 
 else 
  next_state <= HGRE_FRED; 
  
  -- Otherwise, remains GREEN ON highway and RED on Farm way
 end if;
when HYEL_FRED => -- When Yellow light on Highway and Red light on Farm way
 L_H <= "010";    -- Yellow light on Highway
 L_F <= "100";    -- Red light on Farm way 
 R_L_ENABLE <= '0';   -- disable RED light delay counting
 Y_L1_ENABLE <= '1';  -- enable YELLOW light Highway delay counting
 Y_L2_ENABLE <= '0';  -- disable YELLOW light Farmway delay counting
 
 if(delay_3s_H='1') then 
  -- if Yellow light delay counts to 3s, 
  -- turn Highway to RED, 
  -- Farm way to green light 
  next_state <= HRED_FGRE; 
 else 
  next_state <= HYEL_FRED; 
  -- Remains Yellow on highway and Red on Farm way 
  -- if Yellow light not yet in 3s 
 end if;
when HRED_FGRE => -- When Yellow light on Highway and Red light on Farm way
 L_H <= "100";   -- RED light on Highway 
 L_F <= "001";   -- GREEN light on Farm way 
 R_L_ENABLE <= '1';-- enable RED light delay counting
 Y_L1_ENABLE <= '0';-- disable YELLOW light Highway delay counting
 Y_L2_ENABLE <= '0';-- disable YELLOW light Farmway delay counting
 if(delay_10s='1') then
 -- if RED light on highway is 10s, Farm way turns to Yellow
  next_state <= HRED_FYEL;
 else 
  next_state <= HRED_FGRE; 
  -- Remains if delay counts for RED light on highway not enough 10s 
 end if;
when HRED_FYEL =>
 L_H <= "100";-- RED light on Highway 
 L_F <= "010";-- Yellow light on Farm way 
 R_L_ENABLE <= '0'; -- disable RED light delay counting
 Y_L1_ENABLE <= '0';-- disable YELLOW light Highway delay counting
 Y_L2_ENABLE <= '1';-- enable YELLOW light Farmway delay counting
 if(delay_3s_F='1') then 
 -- if delay for Yellow light is 3s,
 -- turn highway to GREEN light
 -- Farm way to RED Light
 next_state <= HGRE_FRED;
 else 
 next_state <= HRED_FYEL;
 -- if not enough 3s, remain the same state 
 end if;
when others => next_state <= HGRE_FRED; -- Green on highway, red on farm way 
end case;
end process;
 -- Delay counts for Yellow and RED light  
process(clk)
begin
if(rising_edge(clk)) then 
if(clk_1s_enable='1') then
 if(R_L_ENABLE='1' or Y_L1_ENABLE='1' or Y_L2_ENABLE='1') then
  delay_count <= delay_count + x"1";
  if((delay_count = x"9") and R_L_ENABLE ='1') then 
   delay_10s <= '1';
   delay_3s_H <= '0';
   delay_3s_F <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and Y_L1_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_H <= '1';
   delay_3s_F <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and Y_L2_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_H <= '0';
   delay_3s_F <= '1';
   delay_count <= x"0";
  else
   delay_10s <= '0';
   delay_3s_H <= '0';
   delay_3s_F <= '0';
  end if;
 end if;
 end if;
end if;
end process;
 --creating 1second delay using 50MHZ clock frequency device
process(clk)
begin
if(rising_edge(clk)) then 
 counter_1s <= counter_1s + x"0000001";
 if(counter_1s >= x"2FAF080") then --here,2FAF080 IS HEX conversion of 50*10^6HZ 
                                   --here for every second,clock rises by 2FAF080 times
  counter_1s <= x"0000000";
 end if;
end if;
end process;
clk_1s_enable <= '1' when counter_1s = x"2FAF080" else '0'; 
end traffic_light;
