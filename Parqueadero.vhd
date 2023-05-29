library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
	 
	 
entity Parqueadero is
    port (
        Front_Sensor : in  std_logic;    -- Front Sensor
        Back_Sensor  : in  std_logic;    -- Back sensor
        Code         : in  std_logic;    -- Código de acceso
        Red_LED      : out std_logic;    -- LED rojo
        Green_LED    : out std_logic     -- LED verde
    );
end entity;


architecture Behavioral of Parqueadero is
 type Estado_Acceso is (Esperando_Ingreso, Verificando_Codigo, Ingreso_Aceptado, Ingreso_Denegado);
   signal estado_acceso1 : Estado_Acceso;
    
 type Estado_Deteccion is (Esperando_Ingreso2, Verificando_Sensor, Ingreso_Detectado);
    signal estado_deteccion1 : Estado_Deteccion;

    signal intentos : natural range 0 to 3 := 0;
begin

--Maquina de estado del Front sensor
--Esta máquina de estado se aplicará una memoria para guardar un código de 4 bits
--que será la contraseña, en la cual si es correcta, se activará la luz verde, si no es 
--correcta en más de 3 intentos, se activará la luz roja y el carro no podrá ingresar,
--esto generará un return en el parqueadero y reinicia el programa para que entre otro vehículo.

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
                if Code = '1' then
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
    
-- Maquina de estado del back sensor
-- Esta máquina lo hace es también basarte en la primera máquina cuando el vehicula ingresa o no
-- al parqueadero, a partir de su ingreso, esta máquina también encenderá la luz verde o roja, dependiendo
-- si pasa o no pasa por el back sensor.
-- EL objetivo de esta máquina de estados a futuro, es implementar un divisor de frecuencia para iniciar el 
-- temporizador en cada uno de los parqueaderos, y así poder cobrar la cantidad de dinero indicada a la salida
-- Cabe destacar que este código es la beta solicitada para la primera parte del parcial, donde exvlusivamente se enseña
-- el uso de las máquinas de estado que se implementaran en el resultado final.
	 
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
                else
                    estado_deteccion1 <= Verificando_Sensor;
                end if;
                
            when Ingreso_Detectado =>
                estado_deteccion1 <= Esperando_Ingreso2;
        end case;
    end process;
    
    -- Salidas
	 
    Red_LED   <= '1' when estado_acceso1 = Ingreso_Denegado else '0';
    Green_LED <= '1' when estado_deteccion1 = Ingreso_Detectado else '0';
	 
end architecture;