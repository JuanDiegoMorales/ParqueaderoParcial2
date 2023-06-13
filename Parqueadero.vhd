library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Parqueadero is
    port (
	     reloj 		: in std_logic;
        Front_Sensor : in  std_logic;             -- Front Sensor
        Back_Sensor  : in  std_logic;             -- Back sensor
        Code         : in  std_logic_vector(3 downto 0);    -- Código de acceso
        Red_LED      : out std_logic;             -- LED rojo
        Green_LED    : out std_logic;             -- LED verde
        Segments1    : out std_logic_vector(6 downto 0);   -- Salida para el primer display de 7 segmentos (unidades)
        Segments10   : out std_logic_vector(6 downto 0)    -- Salida para el segundo display de 7 segmentos (decenas)
    );
end entity;

architecture Behavioral of Parqueadero is
    type Estado_Acceso is (Esperando_Ingreso, Verificando_Codigo, Ingreso_Aceptado, Ingreso_Denegado);
    signal estado_acceso1 : Estado_Acceso;

    type Estado_Deteccion is (Esperando_Ingreso2, Verificando_Sensor, Ingreso_Detectado);
    signal estado_deteccion1 : Estado_Deteccion;

    signal intentos : natural range 0 to 3 := 0;
    signal password : std_logic_vector(3 downto 0) := "0001";

    signal cronometro : integer range 0 to 99 := 0;
    signal lugar_asignado : std_logic_vector(2 downto 0) := "000";
	 
	 signal clock: STD_LOGIC;
	 signal clock_2: STD_LOGIC;
	 
	 component freq_divider
	PORT (  clk : IN STD_LOGIC;
				out1, out2 : BUFFER STD_LOGIC);
	end component;

    -- Función para verificar la disponibilidad de un lugar en el parqueadero
    function lugar_disponible(lugar : integer) return boolean is
    begin
        -- Implementa la lógica para verificar la disponibilidad del lugar
        -- Retorna TRUE si el lugar está disponible, FALSE en caso contrario
        -- Puedes implementar tu propia lógica aquí
        return TRUE;
    end function;

    function asignar_lugar return std_logic_vector is
        variable lugar : integer range 0 to 7;
    begin
        for i in 0 to 7 loop
            if lugar_disponible(i) then -- Verificar si el lugar está disponible
                lugar := i;
                exit; -- Salir del bucle al encontrar un lugar disponible
            end if;
        end loop;
        return std_logic_vector(to_unsigned(lugar, 3)); -- Convertir el lugar a std_logic_vector(2 downto 0)
    end function;

    -- Función para convertir un número decimal en una representación de 7 segmentos
    function decimal_to_7seg(number : integer) return std_logic_vector is
    begin
        case number is
            when 0 =>
                return "0000001";
            when 1 =>
                return "1001111";
            when 2 =>
                return "0010010";
            when 3 =>
                return "0000110";
            when 4 =>
                return "1001100";
            when 5 =>
                return "0100100";
            when 6 =>
                return "0100000";
            when 7 =>
                return "0001111";
            when 8 =>
                return "0000000";
            when 9 =>
                return "0000100";
            when others =>
                return "1111111"; -- Valor por defecto para números inválidos
        end case;
    end function;

begin

	 Relog_1_segundo: freq_divider port map (clk => reloj, out1 => clock, out2 =>clock_2);
	 
    -- Máquina de estado del Front Sensor
    process (Front_Sensor, Code)
    begin
        case estado_acceso1 is
            when Esperando_Ingreso =>
                if Front_Sensor = '1' then
                    estado_acceso1 <= Verificando_Codigo;
                    intentos <= 0;
                else
                    estado_acceso1 <= Esperando_Ingreso;
                end if;

            when Verificando_Codigo =>
                if Code = password then
                    estado_acceso1 <= Ingreso_Aceptado;
                else
                    if intentos = 2 then
                        estado_acceso1 <= Ingreso_Denegado;
                    else
                        estado_acceso1 <= Verificando_Codigo;
                        intentos <= intentos + 1;
                    end if;
                end if;

            when Ingreso_Aceptado =>
                estado_acceso1 <= Esperando_Ingreso;

            when Ingreso_Denegado =>
                estado_acceso1 <= Esperando_Ingreso;
        end case;
    end process;

    -- Máquina de estado del back sensor
    process (Back_Sensor)
    begin
	 
        case estado_deteccion1 is
            when Esperando_Ingreso2 =>
                if Front_Sensor = '1' then
                    estado_deteccion1 <= Verificando_Sensor;
                else
                    estado_deteccion1 <= Esperando_Ingreso2;
                end if;

            when Verificando_Sensor =>
                if Back_Sensor = '1' then
                    estado_deteccion1 <= Ingreso_Detectado;
                    cronometro <= 0; -- Reiniciar el cronómetro cuando el vehículo ingresa
                    lugar_asignado <= asignar_lugar; -- Asignar un lugar al vehículo
                else
                    estado_deteccion1 <= Verificando_Sensor;
                end if;

            when Ingreso_Detectado =>
                estado_deteccion1 <= Esperando_Ingreso2;
                cronometro <= cronometro + 1; -- Incrementar el cronómetro en cada ciclo del reloj
        end case;
    end process;

    -- Convertir el valor del cronómetro a la representación de 7 segmentos para las decenas
    Segments10 <= decimal_to_7seg(cronometro / 10);
    
    -- Convertir el valor del cronómetro a la representación de 7 segmentos para las unidades
    Segments1 <= decimal_to_7seg(cronometro mod 10);

    -- Salidas
    Red_LED   <= '1' when estado_acceso1 = Ingreso_Denegado else '0';
    Green_LED <= '1' when estado_deteccion1 = Ingreso_Detectado else '0';

end architecture;
