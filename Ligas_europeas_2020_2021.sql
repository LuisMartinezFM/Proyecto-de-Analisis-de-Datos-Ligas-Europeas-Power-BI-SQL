CREATE TABLE equipos_futbol(
equipo VARCHAR,
torneo VARCHAR,
goles INTEGER,
tiros_por_juego	NUMERIC,
tarjetas_amarillas INTEGER,
tarjetas_rojas INTEGER,
posesion NUMERIC,
porcentaje_de_pases NUMERIC,
duelos_aereos_ganados NUMERIC,
calificacion NUMERIC
);

-- 1 Creacion de tabla para añadir csv
CREATE TABLE equipos_futbol (
    equipo VARCHAR(100),
    torneo VARCHAR(50),
    goles INTEGER,
    tiros_por_juego NUMERIC(5,2),
    tarjetas_amarillas INTEGER,
    tarjetas_rojas INTEGER,
    posesion NUMERIC(5,2),
    porcentaje_de_pases NUMERIC(5,2),
    duelos_aereos_ganados NUMERIC(5,2),
    calificacion NUMERIC(5,2)
);

-- 2 importacion de los datos mediante csv

-- 3 limpiar datos
-- este dateset no necesita limpieza

-- 4 filtar datos

-- 4.1 Calificación promedio por liga (torneo)
-- Crear tablas auxiliares
CREATE TABLE promedio_calificacion_torneo AS
SELECT 
    torneo,
    AVG(calificacion) AS calificacion_promedio,
    COUNT(*) AS cantidad_equipos
FROM equipos_futbol
GROUP BY torneo;


-- 4.2 Top de ligas con peor fair play
CREATE TABLE fair_play_torneo AS
SELECT 
    torneo,
    SUM(tarjetas_amarillas) AS total_amarillas,
    SUM(tarjetas_rojas) AS total_rojas
FROM equipos_futbol
GROUP BY torneo;


-- 4.3 Top ligas con más goles
CREATE TABLE goles_torneo AS
SELECT 
    torneo,
    SUM(goles) AS total_de_goles
FROM equipos_futbol
GROUP BY torneo;

-- 4.4 ligas con mas goles por jornada
-- antes de obtener el kpi necesitamos una columna con es numero de partidos por torneo o numero de jornadas

CREATE TABLE goles_por_torneo (
    torneo VARCHAR(50),
    goles_totales INTEGER,
    partidos_jugados INTEGER
);


ALTER TABLE goles_torneo
ADD COLUMN partidos_jugados INTEGER;

--columna goles por partido
ALTER TABLE goles_torneo
ADD COLUMN goles_por_partido NUMERIC(5,2);

UPDATE goles_torneo
SET goles_por_partido = ROUND(total_de_goles::NUMERIC / partidos_jugados, 2);
-- se renombra la tabla goles por partido
ALTER TABLE goles_torneo
RENAME COLUMN goles_por_partido TO goles_por_jornada;
----
-- todo esto no sirvio
UPDATE goles_torneo
SET partidos_jugados = 38
WHERE torneo IN ('Premier League', 'LaLiga', 'Serie A', 'Ligue 1');

UPDATE goles_torneo
SET partidos_jugados = 34
WHERE torneo = 'Bundesliga';

ALTER TABLE goles_torneo
ADD COLUMN tiros_totales NUMERIC;

UPDATE goles_torneo gt
SET tiros_totales =
(
    SELECT SUM(ef.tiros_por_juego * gt.partidos_jugados)
    FROM equipos_futbol ef
    WHERE ef.torneo = gt.torneo
);

--- se borra la columna tiros totales
ALTER TABLE goles_torneo
DROP COLUMN tiros_totales;


-- 4.5 Precisión de pase promedio por liga
-- se renombra goles_torneo por torneos
ALTER TABLE goles_torneo
RENAME TO torneos;

ALTER TABLE torneos
ADD COLUMN porcentaje_de_pases NUMERIC(5,2);

UPDATE torneos t
SET porcentaje_de_pases =
(
    SELECT ROUND(AVG(ef.porcentaje_de_pases), 2)
    FROM equipos_futbol ef
    WHERE ef.torneo = t.torneo
);

--se añade columna con imagenes
ALTER TABLE torneos
ADD COLUMN logo_url TEXT;

UPDATE torneos
SET logo_url = 'https://tmssl.akamaized.net//images/logo/header/gb1.png?lm=1521104656'
WHERE torneo = 'Premier League';

UPDATE torneos
SET logo_url = 'https://tmssl.akamaized.net//images/logo/header/es1.png?lm=1725974302'
WHERE torneo = 'LaLiga';

UPDATE torneos
SET logo_url = 'https://tmssl.akamaized.net//images/logo/header/it1.png?lm=1656073460'
WHERE torneo = 'Serie A';

UPDATE torneos
SET logo_url = 'https://tmssl.akamaized.net//images/logo/header/l1.png?lm=1525905518'
WHERE torneo = 'Bundesliga';

UPDATE torneos
SET logo_url = 'https://tmssl.akamaized.net//images/logo/header/fr1.png?lm=1732280518'
WHERE torneo = 'Ligue 1';


--
UPDATE torneos
SET porcentaje_de_pases = porcentaje_de_pases / 100;


UPDATE porcentaje_de_pases NUMERIC(10,4);

UPDATE torneos t
SET porcentaje_de_pases =
(
    SELECT ROUND(AVG(ef.porcentaje_de_pases), 2)
    FROM equipos_futbol ef
    WHERE ef.torneo = t.torneo
);

CREATE TABLE ranking_torneos_calificacion AS
SELECT
    torneo,
    ROUND(AVG(calificacion), 2) AS calificacion_promedio,
    RANK() OVER (ORDER BY AVG(calificacion) DESC) AS ranking
FROM equipos_futbol
GROUP BY torneo
ORDER BY calificacion_promedio DESC;
