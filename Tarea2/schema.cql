-- ============================================================
-- Keyspace
-- (confirma antes: SELECT data_center FROM system.local;
--  y cambia 'datacenter1' si es distinto)
-- ============================================================
CREATE KEYSPACE IF NOT EXISTS actors
WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': 3};

USE actors;

-- ============================================================
-- UDT: personaje (se usa dentro de actores_por_id)
-- ============================================================
CREATE TYPE IF NOT EXISTS personaje (
    nombre           text,
    produccion       text,
    tipo_produccion  text,                 -- 'profesional' | 'independiente'
    rol              text,                 -- principal, secundario, reparto, cameo
    apariciones      int,
    generos          frozen<set<text>>
);

-- ============================================================
-- Tabla 1: actores_por_id
-- Consulta 1: obtener un actor completo por su identificador.
--   SELECT * FROM actores_por_id WHERE id = ?;
-- PRIMARY KEY (id)
--   Clave de partición : id
--   Clustering         : ninguna (1 fila por partición)
-- ============================================================
CREATE TABLE IF NOT EXISTS actores_por_id (
    id            uuid,
    nombre        text,
    nacionalidad  text,
    fecha_nac     date,
    edad          int,
    patrimonio    decimal,
    idiomas       set<text>,
    personajes    list<frozen<personaje>>,
    PRIMARY KEY (id)
);

-- ============================================================
-- Tabla 2: actores_por_nacionalidad
-- Consulta 2: actores de una nacionalidad ordenados por edad.
--   SELECT * FROM actores_por_nacionalidad WHERE nacionalidad = ?;
--   (ASC por defecto; ORDER BY edad DESC para el orden inverso)
-- PRIMARY KEY ((nacionalidad), edad, id)
--   Clave de partición : nacionalidad
--   Clustering         : edad ASC, id ASC
--   (id garantiza unicidad si dos actores tienen la misma edad)
-- ============================================================
CREATE TABLE IF NOT EXISTS actores_por_nacionalidad (
    nacionalidad  text,
    edad          int,
    id            uuid,
    nombre        text,
    fecha_nac     date,
    patrimonio    decimal,
    idiomas       set<text>,
    PRIMARY KEY ((nacionalidad), edad, id)
) WITH CLUSTERING ORDER BY (edad ASC, id ASC);

-- ============================================================
-- Tabla 3: personajes_por_actor
-- Consulta 3: personajes de un actor según rol y apariciones.
--   SELECT * FROM personajes_por_actor WHERE actor_id = ?;
--   SELECT * FROM personajes_por_actor WHERE actor_id = ? AND rol = 'principal';
--   SELECT * FROM personajes_por_actor
--     WHERE actor_id = ? AND rol = 'principal' AND apariciones >= 50;
-- PRIMARY KEY ((actor_id), rol, apariciones, produccion, nombre)
--   Clave de partición : actor_id
--   Clustering         : rol ASC, apariciones DESC, produccion ASC, nombre ASC
--   (produccion y nombre hacen única cada fila dentro del actor)
-- ============================================================
CREATE TABLE IF NOT EXISTS personajes_por_actor (
    actor_id         uuid,
    rol              text,
    apariciones      int,
    produccion       text,
    nombre           text,
    tipo_produccion  text,
    generos          set<text>,
    actor_nombre     text,
    PRIMARY KEY ((actor_id), rol, apariciones, produccion, nombre)
) WITH CLUSTERING ORDER BY (rol ASC, apariciones DESC, produccion ASC, nombre ASC);
