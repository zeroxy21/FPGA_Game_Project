library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
	
library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50: in std_logic;

        -- HDMI
        io_hdmi_i2c_scl       : inout std_logic;
        io_hdmi_i2c_sda       : inout std_logic;
        o_hdmi_tx_clk        : out std_logic;
        o_hdmi_tx_d          : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de         : out std_logic;
        o_hdmi_tx_hs         : out std_logic;
        i_hdmi_tx_int        : in std_logic;
        o_hdmi_tx_vs         : out std_logic;

        -- KEYs
        i_rst_n : in std_logic;
		  
		-- LEDs
		o_leds : out std_logic_vector(9 downto 0);
		o_de10_leds : out std_logic_vector(7 downto 0);

		-- Coder
		i_left_ch_a : in std_logic;
		i_left_ch_b : in std_logic;
		i_left_pb : in std_logic;
		i_right_ch_a : in std_logic;
		i_right_ch_b : in std_logic;
		i_right_pb : in std_logic
    );
end entity telecran;

architecture rtl of telecran is
	component I2C_HDMI_Config 
		port (
			iCLK : in std_logic;
			iRST_N : in std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			HDMI_TX_INT  : in std_logic
		);
	end component;
	 
	component pll 
		port (
			refclk : in std_logic;
			rst : in std_logic;
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;
	
	component dpram
		generic
		 (
			  mem_size    : natural := 720 * 480;
			  data_width  : natural := 8
		 );
		 port 
		 (
			  i_clk_a        : in std_logic;
			  i_clk_b        : in std_logic;

			  i_data_a       : in std_logic_vector(data_width-1 downto 0);
			  i_data_b       : in std_logic_vector(data_width-1 downto 0);
			  i_addr_a       : in natural range 0 to mem_size-1;
			  i_addr_b       : in natural range 0 to mem_size-1;
			  i_we_a         : in std_logic := '1';
			  i_we_b         : in std_logic := '1';
			  o_q_a          : out std_logic_vector(data_width-1 downto 0);
			  o_q_b          : out std_logic_vector(data_width-1 downto 0)
		 );
	end component;


	component encoder
		port (
			i_clk        : in  std_logic;
			i_rst_n      : in  std_logic;
			LEFT_A       : in  std_logic;
			LEFT_B       : in  std_logic;
			RIGHT_A      : in  std_logic;
			RIGHT_B      : in  std_logic;
			left_counter : out natural range 0 to 479;
			right_counter: out natural range 0 to 719
		);
	end component;
	--resolution
	constant h_res : natural := 720;
	constant v_res : natural := 480;
	--hdmi controller
	signal s_clk_27 : std_logic;
	signal s_rst_n  : std_logic;	
	signal s_hdmi_hs : std_logic;
	signal s_hdmi_vs : std_logic;
	signal s_hdmi_de : std_logic;
	signal s_x_counter : natural range 0 to (h_res-1);
	signal s_y_counter : natural range 0 to (v_res-1);
	
	-- positions fournies par l'encodeur 
	signal x_position : natural range 0 to 719;
	signal y_position : natural range 0 to 479;
	
	-- RAM interface signals
	signal ram_data_a : std_logic_vector(7 downto 0) := (others => '0'); -- write data (port A)
	signal ram_data_b : std_logic_vector(7 downto 0) := (others => '0'); -- unused write on B
	signal ram_q_a : std_logic_vector(7 downto 0);
	signal ram_q_b : std_logic_vector(7 downto 0);
	signal ram_addr_a : natural range 0 to (720*480 - 1) := 0;
	signal ram_addr_b : natural range 0 to (720*480 - 1) := 0;
	signal ram_we_a : std_logic := '0';
	signal ram_we_b : std_logic := '0';

	-- anciennes positions pour detecter les changements
	signal prev_x : natural range 0 to 719 := 0;
	signal prev_y : natural range 0 to 479 := 0;

begin
	o_leds <= (others => '0');
	o_de10_leds <= (others => '0');


	pll0 : component pll 
		port map (
			refclk => i_clk_50,
			rst => not(i_rst_n),
			outclk_0 => s_clk_27,
			locked => s_rst_n
		);

	I2C_HDMI_Config0 : component I2C_HDMI_Config 
		port map (
			iCLK => i_clk_50,
			iRST_N => i_rst_n,
			I2C_SCLK => io_hdmi_i2c_scl,
			I2C_SDAT => io_hdmi_i2c_sda,
			HDMI_TX_INT => i_hdmi_tx_int
		);

	
	hdmi_controler : entity work.hdmi_controler
		generic map (
			h_res  => h_res,
			v_res  => v_res,
			h_sync => 61,
			h_fp   => 58,
			h_bp   => 18,
			v_sync => 5,
			v_fp   => 30,
			v_bp   => 9
		)
		port map (
			i_clk           => s_clk_27,
			i_rst_n         => s_rst_n,
			o_hdmi_hs       => s_hdmi_hs,
			o_hdmi_vs       => s_hdmi_vs,
			o_hdmi_de       => s_hdmi_de,
			o_pixel_en      => open,
			o_pixel_address => open,
			o_x_counter     => s_x_counter,
			o_y_counter     => s_y_counter
		);


	o_hdmi_tx_hs <= s_hdmi_hs;
	o_hdmi_tx_vs <= s_hdmi_vs;
	o_hdmi_tx_de <= s_hdmi_de;
	o_hdmi_tx_clk <= s_clk_27;

	
	enc0 : encoder
		port map (
			i_clk        => s_clk_27,
			i_rst_n      => i_rst_n,
			LEFT_A       => i_left_ch_a,
			LEFT_B       => i_left_ch_b,
			RIGHT_A      => i_right_ch_a,
			RIGHT_B      => i_right_ch_b,
			left_counter => x_position,
			right_counter=> y_position
		);


	ram0 : dpram
    port map (
        i_clk_a  => s_clk_27,
        i_clk_b  => s_clk_27,

        i_data_a => ram_data_a,
        i_data_b => ram_data_b,

        i_addr_a => ram_addr_a,
        i_addr_b => ram_addr_b,

        i_we_a   => ram_we_a,
        i_we_b   => ram_we_b,

        o_q_a    => ram_q_a,
        o_q_b    => ram_q_b
    );

	----------------------------------------------------------------
	-- 1) Calcul de l'adresse de lecture (port B) : HDMI lit la RAM
	--    adresse = y * h_res + x 
	----------------------------------------------------------------
	ram_addr_b <= s_y_counter * h_res + s_x_counter;

	----------------------------------------------------------------
	-- 2) Ecriture en RAM (port A) : on écrit un octet non-nul
	--    à l'adresse correspondant à (x_position,y_position)
	--    lorsqu'une position change 
	----------------------------------------------------------------
	write_ram_proc : process(s_clk_27)
	begin
		if rising_edge(s_clk_27) then
			if s_rst_n = '0' then
				prev_x   <= 0;
				prev_y   <= 0;
				ram_we_a <= '0';
				ram_data_a <= (others => '0');
				ram_addr_a <= 0;
			else
				-- par défaut pas d'écriture
				ram_we_a <= '0';
				-- si la position a changé, écrire 0xFF à l'adresse correspondante
				if (x_position /= prev_x) or (y_position /= prev_y) then
					ram_addr_a <= y_position * h_res + x_position;
					ram_data_a <= X"FF";      -- marqueur pixel blanc
					ram_we_a <= '1';         -- un cycle d'écriture
				end if;
				-- mémoriser la position courante comme précédente
				prev_x <= x_position;
				prev_y <= y_position;
			end if;
		end if;
	end process write_ram_proc;

	process(s_clk_27)
	begin
		if rising_edge(s_clk_27) then

			if ram_q_b /= X"00" then
				o_hdmi_tx_d <= X"FFFFFF";  -- blanc
			else
				o_hdmi_tx_d <= X"000000";  -- noir
			end if;
		end if;
	end process;
	
	process(s_clk_27,i_rst_n)
	begin 
		if i_rst_n='1' then 
		
	
end architecture rtl;
