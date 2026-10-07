from cassandra.cluster import Cluster

cluster = Cluster(['127.0.0.1'], port=9042)
session = cluster.connect('actors')

actores = session.execute("SELECT id, nombre, nacionalidad, edad, patrimonio, personajes FROM actores_por_id")

for actor in actores:
    nuevo_patrimonio = float(actor.patrimonio) * 1.32
    
    if actor.edad < 40:
        rol = 'principal'
        apariciones = 3
    else:
        rol = 'secundario'
        apariciones = 1

    session.execute("""
        UPDATE actores_por_id 
        SET patrimonio = %s, personajes = personajes + [{
            nombre: 'Personaje Desconocido', 
            produccion: 'Sansa Ball Race', 
            tipo_produccion: 'profesional', 
            rol: %s, 
            apariciones: %s, 
            generos: {'animación'}
        }]
        WHERE id = %s
    """, (nuevo_patrimonio, rol, apariciones, actor.id))

    session.execute("""
        UPDATE actores_por_nacionalidad 
        SET patrimonio = %s 
        WHERE nacionalidad = %s AND edad = %s AND id = %s
    """, (nuevo_patrimonio, actor.nacionalidad, actor.edad, actor.id))

    session.execute("""
        INSERT INTO personajes_por_actor 
        (actor_id, rol, apariciones, produccion, nombre, tipo_produccion, generos, actor_nombre)
        VALUES (%s, %s, %s, 'Sansa Ball Race', 'Personaje Desconocido', 'profesional', {'animación'}, %s)
    """, (actor.id, rol, apariciones, actor.nombre))
