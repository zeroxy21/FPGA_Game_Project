library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
    port (
        i_clk    : in  std_logic;
        i_rst_n  : in  std_logic;

        LEFT_A   : in  std_logic;
        LEFT_B   : in  std_logic;
        RIGHT_A  : in  std_logic;
        RIGHT_B  : in  std_logic;

        left_counter  : out natural range 0 to 479;
        right_counter : out natural range 0 to 719
    );
end entity encoder;

architecture rtl of encoder is

    --------------------------------------------------------------------
    -- LEFT ENCODER (vertical)
    --------------------------------------------------------------------
    signal left_pos : natural range 0 to 479 := 0;

    signal la_sync, lb_sync : std_logic_vector(2 downto 0) := (others => '0');
    signal la_clean, lb_clean : std_logic := '0';
    signal lab_last : std_logic_vector(1 downto 0) := "00";

    --------------------------------------------------------------------
    -- RIGHT ENCODER (horizontal)
    --------------------------------------------------------------------
    signal right_pos : natural range 0 to 719 := 0;

    signal ra_sync, rb_sync : std_logic_vector(2 downto 0) := (others => '0');
    signal ra_clean, rb_clean : std_logic := '0';
    signal rab_last : std_logic_vector(1 downto 0) := "00";

begin

    --------------------------------------------------------------------
    -- LEFT : synchronisation + anti rebond
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            la_sync  <= (others => '0');
            lb_sync  <= (others => '0');
            la_clean <= '0';
            lb_clean <= '0';
        elsif rising_edge(i_clk) then
            la_sync <= la_sync(1 downto 0) & LEFT_A;
            lb_sync <= lb_sync(1 downto 0) & LEFT_B;

            if la_sync = "111" then la_clean <= '1';
            elsif la_sync = "000" then la_clean <= '0';
            end if;

            if lb_sync = "111" then lb_clean <= '1';
            elsif lb_sync = "000" then lb_clean <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- RIGHT : synchronisation + anti rebond
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
    begin
        if i_rst_n = '0' then
            ra_sync  <= (others => '0');
            rb_sync  <= (others => '0');
            ra_clean <= '0';
            rb_clean <= '0';
        elsif rising_edge(i_clk) then
            ra_sync <= ra_sync(1 downto 0) & RIGHT_A;
            rb_sync <= rb_sync(1 downto 0) & RIGHT_B;

            if ra_sync = "111" then ra_clean <= '1';
            elsif ra_sync = "000" then ra_clean <= '0';
            end if;

            if rb_sync = "111" then rb_clean <= '1';
            elsif rb_sync = "000" then rb_clean <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- LEFT : Quadrature 4X
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
        variable ab_now : std_logic_vector(1 downto 0);
    begin
        if i_rst_n = '0' then
            left_pos <= 0;
            lab_last <= "00";
        elsif rising_edge(i_clk) then
            ab_now := la_clean & lb_clean;

            case lab_last is
                when "00" =>
                    if ab_now = "01" then left_pos <= (left_pos + 1) mod 480;
                    elsif ab_now = "10" then left_pos <= (left_pos + 479) mod 480;
                    end if;
                when "01" =>
                    if ab_now = "11" then left_pos <= (left_pos + 1) mod 480;
                    elsif ab_now = "00" then left_pos <= (left_pos + 479) mod 480;
                    end if;
                when "11" =>
                    if ab_now = "10" then left_pos <= (left_pos + 1) mod 480;
                    elsif ab_now = "01" then left_pos <= (left_pos + 479) mod 480;
                    end if;
                when "10" =>
                    if ab_now = "00" then left_pos <= (left_pos + 1) mod 480;
                    elsif ab_now = "11" then left_pos <= (left_pos + 479) mod 480;
                    end if;
                when others => null;
            end case;

            lab_last <= ab_now;
        end if;
    end process;

    --------------------------------------------------------------------
    -- RIGHT : Quadrature 4X
    --------------------------------------------------------------------
    process(i_clk, i_rst_n)
        variable ab_now : std_logic_vector(1 downto 0);
    begin
        if i_rst_n = '0' then
            right_pos <= 0;
            rab_last <= "00";
        elsif rising_edge(i_clk) then
            ab_now := ra_clean & rb_clean;

            case rab_last is
                when "00" =>
                    if ab_now = "01" then right_pos <= (right_pos + 1) mod 720;
                    elsif ab_now = "10" then right_pos <= (right_pos + 719) mod 720;
                    end if;
                when "01" =>
                    if ab_now = "11" then right_pos <= (right_pos + 1) mod 720;
                    elsif ab_now = "00" then right_pos <= (right_pos + 719) mod 720;
                    end if;
                when "11" =>
                    if ab_now = "10" then right_pos <= (right_pos + 1) mod 720;
                    elsif ab_now = "01" then right_pos <= (right_pos + 719) mod 720;
                    end if;
                when "10" =>
                    if ab_now = "00" then right_pos <= (right_pos + 1) mod 720;
                    elsif ab_now = "11" then right_pos <= (right_pos + 719) mod 720;
                    end if;
                when others => null;
            end case;

            rab_last <= ab_now;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Sorties
    --------------------------------------------------------------------
    left_counter  <= left_pos;
    right_counter <= right_pos;

end architecture rtl;

