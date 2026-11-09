#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
populate_v140_enciclopedia.py
Genera y puebla las tablas `biblical_authors` y `book_summaries` en assets/data/logos_k_logos.db
para Berea Interlineal v1.4.0.
"""

import os
import shutil
import sqlite3
import sys

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

DB_PATH = "assets/data/logos_k_logos.db"
BACKUP_PATH = "assets/data/logos_k_logos.db.bak"

def main():
    if not os.path.exists(BACKUP_PATH):
        print(f"[INFO] Creando respaldo de la base de datos en {BACKUP_PATH}...")
        shutil.copyfile(DB_PATH, BACKUP_PATH)
    else:
        print(f"[INFO] Respaldo ya existe en {BACKUP_PATH}.")

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # Normalizar Hageo si era 'Hag' en books para coincidir con verses y BookCatalog ('Ha')
    cur.execute("UPDATE books SET id = 'Ha' WHERE id = 'Hag'")

    # Crear tablas
    cur.execute("""
    CREATE TABLE IF NOT EXISTS biblical_authors (
        author_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name_es TEXT NOT NULL,
        name_original TEXT NOT NULL,
        strong_code TEXT,
        era TEXT NOT NULL,
        occupation TEXT NOT NULL,
        calling_verse TEXT NOT NULL,
        biography TEXT NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE IF NOT EXISTS book_summaries (
        book_id INTEGER PRIMARY KEY,
        book_code TEXT NOT NULL,
        testament TEXT NOT NULL,
        category TEXT NOT NULL,
        author_id INTEGER NOT NULL,
        recipients TEXT NOT NULL,
        date_written TEXT NOT NULL,
        historical_context TEXT NOT NULL,
        key_themes TEXT NOT NULL,
        key_verse_ref TEXT NOT NULL,
        practical_application TEXT NOT NULL,
        FOREIGN KEY (author_id) REFERENCES biblical_authors(author_id)
    );
    """)

    cur.execute("CREATE INDEX IF NOT EXISTS idx_summaries_testament ON book_summaries(testament);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_summaries_category ON book_summaries(category);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_summaries_code ON book_summaries(book_code);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_authors_name ON biblical_authors(name_es);")

    # Limpiar datos previos si existieran para inserción idempotente limpia
    cur.execute("DELETE FROM book_summaries")
    cur.execute("DELETE FROM biblical_authors")
    cur.execute("DELETE FROM sqlite_sequence WHERE name IN ('biblical_authors', 'book_summaries')")

    print("[INFO] Insertando 35 Escritores Bíblicos...")
    authors_data = [
        # 1. Moisés
        (
            1, "Moisés", "מֹשֶׁה", "H4872",
            "Época Patriarcal y Éxodo (c. 1526-1406 a.C.)",
            "Príncipe de Egipto, pastor en Madián, caudillo libertador y profeta de Yahvé",
            "Éxodo 3:4-10",
            "Nacido en Egipto en tiempos de opresión faraónica, Moisés fue preservado en una cesta sobre el Nilo y educado en toda la sabiduría de la corte egipcia. Tras huir a Madián y pastorear durante cuarenta años, Dios se le reveló en la zarza ardiente del monte Horeb para comisionarlo como redentor de Israel.\n\n"
            "Guió al pueblo a través del Mar Rojo, recibió la Ley en el Sinaí, erigió el Tabernáculo y condujo a la congregación durante cuarenta años de travesía por el desierto. Autor divinamente inspirado del Pentateuco (Torá) y del Salmo 90, su figura prefigura a Cristo como Profeta, Mediador del pacto e intercesor abnegado."
        ),
        # 2. Josué
        (
            2, "Josué", "יְהוֹשֻׁעַ", "H3091",
            "Conquista y Asentamiento en Canaán (c. 1490-1380 a.C.)",
            "Comandante militar, servidor de Moisés y caudillo supremo de Israel",
            "Josué 1:1-9",
            "Hijo de Nun, de la tribu de Efraín. Fue el fiel ayudante de Moisés y uno de los dos únicos espías que mantuvieron la fe en las promesas divinas al explorar la tierra prometida. Sucesor oficial de Moisés ungido por mandato de Dios.\n\n"
            "Lideró el cruce milagroso del río Jordán, la caída de Jericó y la conquista estratégica de las regiones norte y sur de Canaán. Culminó su ministerio distribuyendo las tierras por tribus y sellando el pacto de fidelidad en Siquem: «Yo y mi casa serviremos a Jehová» (Josué 24:15)."
        ),
        # 3. Samuel
        (
            3, "Samuel", "שְׁמוּאֵל", "H8050",
            "Transición de los Jueces a la Monarquía (c. 1105-1010 a.C.)",
            "Profeta, sacerdote, educador y último gran Juez de Israel",
            "1 Samuel 3:1-10",
            "Hijo concedido en respuesta a la ferviente oración de Ana y dedicado desde niño al servicio del Tabernáculo en Silo bajo el sumo sacerdote Elí. Llamado por Dios desde su niñez, restableció la autoridad de la Palabra en Israel tras décadas de apostasía.\n\n"
            "Fundó las escuelas de los profetas, guió al pueblo en victorias decisivas contra los filisteos y presidió la trascendental transición teocrática ungiendo por mandato divino a los dos primeros monarcas de Israel: Saúl y David. Es tradicionalmente el redactor de Jueces, Rut y las crónicas tempranas de 1 Samuel."
        ),
        # 4. David
        (
            4, "David", "דָּוִד", "H1732",
            "Reino Unido de Israel (c. 1040-970 a.C.)",
            "Pastor de Belén, arpista real, guerrero, rey de Judá e Israel y salmista supremo",
            "1 Samuel 16:11-13",
            "El menor de los hijos de Isaí, ungido secretamente por Samuel mientras cuidaba ovejas en Belén. Con una fe inquebrantable derrotó al gigante Goliat en el valle de Ela, soportó años de persecución injusta bajo el rey Saúl y ascendió finalmente al trono de todo Israel, unificando la nación y estableciendo a Jerusalén (Sión) como capital política y espiritual.\n\n"
            "Reconocido como «el dulce cantor de Israel» y hombre conforme al corazón de Dios, redactó al menos 73 salmos canónicos donde confluyen la más íntima devoción, el dolor del arrepentimiento sincero y las más sublimes profecías sobre el Mesías, su Hijo y Señor."
        ),
        # 5. Salomón
        (
            5, "Salomón", "שְׁלֹמֹה", "H8010",
            "Cúspide de la Monarquía Unida (c. 990-931 a.C.)",
            "Tercer Rey de Israel, sabio ilustre, arquitecto del Primer Templo y compilador sapiencial",
            "1 Reyes 3:5-14",
            "Hijo de David y Betsabé, elegido por Dios para suceder a su padre en el trono de Israel. Al iniciar su reinado pidió sabiduría para gobernar con justicia al pueblo de Dios, recibiendo entendimiento sin parangón, paz en todas las fronteras y una riqueza legendaria.\n\n"
            "Erigió el majestuoso Templo de Jerusalén conforme al diseño revelado a David. Autor de gran parte del libro de Proverbios, de Eclesiastés, de los Cantares y de los Salmos 72 y 127, su producción literaria plasmó las cumbres de la teología sapiencial hebrea."
        ),
        # 6. Asaf
        (
            6, "Asaf", "אָסָף", "H623",
            "Reino Unido y Canto Levítico (c. 1000 a.C.)",
            "Levita guersonita, maestro de coro del Tabernáculo, vidente y compositor sacro",
            "1 Crónicas 16:4-7",
            "Designado por el rey David para liderar el ministerio musical y la alabanza continua ante el Arca del Pacto en Jerusalén. Reconocido como profeta y salmista (2 Crónicas 29:30).\n\n"
            "Sus doce salmos (Salmo 50 y Salmos 73 al 83) destacan por su profundidad teológica, confrontando dilemas existenciales como la aparente prosperidad de los impíos, la justicia providencial y el llamado al juicio divino sobre las naciones."
        ),
        # 7. Los Hijos de Coré
        (
            7, "Los Hijos de Coré", "בְּנֵי קֹרַח", "H7141",
            "Monarquía Davidica y Templo de Salomón",
            "Gremio levítico de cantores, guardianes de las puertas y poetas sacros",
            "1 Crónicas 9:19",
            "Descendientes del levita Coré que sobrevivieron a la rebelión en el desierto por la soberana gracia de Dios (Números 26:11). En la época davídica formaron uno de los cuerpos musicales más insignes del santuario.\n\n"
            "Compusieron once salmos inmortales (Salmos 42, 44–49, 84, 85, 87, 88), célebres por su anhelo ardiente por la presencia de Dios en el santuario («Como el ciervo brama por las corrientes de las aguas») y su reverencia ante la majestad divina."
        ),
        # 8. Agur y Lemuel
        (
            8, "Agur y Lemuel", "אָגוּר", "H94",
            "Monarquía Hebrea y Tradición Sapiencial",
            "Maestros éticos, sabios inspirados y reyes consejeros",
            "Proverbios 30:1-4",
            "Agur, hijo de Jaqué, plasmó en Proverbios 30 su asombro ante la inescrutable grandeza creadora de Dios y la fragilidad del conocimiento humano. Lemuel, rey de Masa instruido por su madre piadosa, compuso el poema acróstico inmortal a la mujer virtuosa y sabia en Proverbios 31."
        ),
        # 9. Isaías
        (
            9, "Isaías", "יְשַׁעְיָהוּ", "H3470",
            "Profeta del Reino de Judá (c. 740-681 a.C.)",
            "Profeta cortesano de Jerusalén, historiador real y teólogo mesiánico supremo",
            "Isaías 6:1-8",
            "Hijo de Amoz, perteneciente al linaje aristocrático de Jerusalén. Ministró durante los reinados de Uzías, Jotam, Acaz y Ezequías frente a la expansión del colosal Imperio Asirio.\n\n"
            "Conocido justamente como «el profeta evangélico del Antiguo Testamento», su obra combina una deslumbrante elevación poética con la revelación más detallada del Siervo Sufriente (Isaías 53), el nacimiento virginal de Emanuel y la gloriosa instauración de los cielos nuevos y tierra nueva."
        ),
        # 10. Jeremías
        (
            10, "Jeremías", "יִרְמְיָהוּ", "H3414",
            "Declive y Caída de Judá ante Babilonia (c. 650-570 a.C.)",
            "Sacerdote de Anatot, profeta a las naciones y testigo ocular de la caída de Jerusalén",
            "Jeremías 1:4-10",
            "Llamado desde el vientre materno para anunciar el juicio inminente sobre Judá debido a su incorregible idolatría. Ministró durante más de cuatro décadas en medio de calumnias, encarcelamientos y soledad.\n\n"
            "Conocido como «el profeta que llora», presenció el sitio y destrucción del Templo en 586 a.C. por Nabucodonosor. Redactó el libro de Jeremías y las elegías acrósticas de Lamentaciones, legando la maravillosa profecía del Nuevo Pacto grabado en el corazón (Jeremías 31:31-34)."
        ),
        # 11. Ezequiel
        (
            11, "Ezequiel", "יְחֶזְקֵאל", "H3168",
            "Exilio Babilónico (c. 622-570 a.C.)",
            "Sacerdote de la estirpe de Sadoc, atalaya espiritual y profeta apocalíptico",
            "Ezequiel 1:1-3",
            "Hijo de Buzi, llevado cautivo a Babilonia en la segunda deportación (597 a.C.) junto al rey Joaquín. A los treinta años, a orillas del río Quebar, contempló el carro de la gloria de Yahvé y fue comisionado como atalaya de la casa de Israel.\n\n"
            "Mediante actos dramáticos y visiones cósmicas proclamó la partida de la gloria de Dios de Jerusalén, la responsabilidad individual, la resurrección nacional simbolizada en el valle de los huesos secos y el diseño del Templo celestial restaurado con el manantial de aguas vivas."
        ),
        # 12. Daniel
        (
            12, "Daniel", "דָּנִיֵּאל", "H1840",
            "Imperios Neobabilónico y Medo-Persa (c. 620-536 a.C.)",
            "Príncipe de Judá, primer ministro imperial, estadista y profeta de los tiempos finales",
            "Daniel 1:8; 2:19-23",
            "Deportivo en la primera oleada cautiva en 605 a.C., Daniel mantuvo una devoción sin fisuras en la corte de Babilonia, rehusando contaminarse con los manjares reales. Dotado de sabiduría divina para revelar sueños y enigmas, sirvió en los más altos cargos de estado bajo Nabucodonosor, Belsasar, Darío el Medo y Ciro el Grande.\n\n"
            "Sobrevivió al foso de los leones y recibió visiones monumentales sobre la sucesión de los cuatro imperios mundiales, el reinado eterno del Hijo del Hombre y el cómputo exacto de las setenta semanas que anticipaban la redención del Mesías Príncipe."
        ),
        # 13. Oseas
        (
            13, "Oseas", "הוֹשֵׁעַ", "H1954",
            "Últimos Años del Reino del Norte de Israel (c. 755-715 a.C.)",
            "Profeta del amor entrañable y de la fidelidad del pacto de Yahvé",
            "Oseas 1:2",
            "Hijo de Beeri. Dios le ordenó tomar por esposa a Gomer, cuya dolorosa infidelidad matrimonial se convirtió en una vívida parábola viviente de la infidelidad idolátrica de Israel hacia Dios.\n\n"
            "A pesar del quebranto del pecado y el juicio inminente de la cautividad asiria, Oseas predicó con una ternura inagotable el corazón compasivo de Dios, quien redime y restaura a su pueblo como un esposo fiel a su amada."
        ),
        # 14. Joel
        (
            14, "Joel", "יוֹאֵל", "H3100",
            "Profeta de Judá (c. Siglo IX / VI a.C.)",
            "Profeta teológico del Día de Jehová y del derramamiento pentecostal",
            "Joel 2:28-32",
            "Hijo de Petuel. Tras una devastadora plaga de langostas y una severa sequía que asoló los campos y anuló las ofrendas del Templo de Jerusalén, convocó a un solemne ayuno nacional y arrepentimiento sincero con rasgamiento de corazón.\n\n"
            "Proclamó que aquella calamidad era preludio del gran Día de Jehová, anunciando con precisión milenaria el derramamiento universal del Espíritu Santo cumplido gloriosamente en Pentecostés (Hechos 2)."
        ),
        # 15. Amós
        (
            15, "Amós", "עָמוֹס", "H5986",
            "Época de Prosperidad y Corrupción de Israel (c. 760 a.C.)",
            "Boyero y cultivador de higos silvestres de Tecoa, predicador de justicia divina",
            "Amós 7:14-15",
            "Campesino oriundo de la aldea de Tecoa en Judá, sin linaje sacerdotal ni formación profética formal, enviado por Dios al santuario apóstata de Bet-el en el próspero Reino del Norte durante el mandato de Jeroboam II.\n\n"
            "Con valentía inquebrantable denunció la opresión de los pobres, el lujo desmedido y la religiosidad hipócrita, clamando: «Pero corra el juicio como las aguas, y la justicia como impetuoso arroyo» (Amós 5:24)."
        ),
        # 16. Abdías
        (
            16, "Abdías", "עֹבַדְיָה", "H5662",
            "Juicio sobre Edom (c. 586 a.C.)",
            "Profeta heraldo de la soberanía universal y protector de Sión",
            "Abdías 1:1",
            "Su nombre significa «siervo de Jehová». Dirigió su oráculo fulminante contra la nación de Edom (descendientes de Esaú), quienes se jactaban de sus fortalezas rocosas inexpugnables en Petra y se regocijaron perversamente ante la calamidad y saqueo de Jerusalén por los babilonios.\n\n"
            "Sentenció que el orgullo humano será derribado y que el monte de Sión será santo, culminando con la gloriosa declaración: «Y el reino será de Jehová»."
        ),
        # 17. Jonás
        (
            17, "Jonás", "יוֹנָה", "H3124",
            "Misión a Nínive (c. 785-760 a.C.)",
            "Profeta de Gat-hefer enviado a la capital del Imperio Asirio",
            "Jonás 1:1-2",
            "Hijo de Amitai, natural de la región de Galilea. Recibió el mandato de clamar contra la sanguinaria ciudad de Nínive, pero intentó huir hacia Tarsis en sentido opuesto. Preservado tres días y tres noches en el vientre de un gran pez, aprendió que «la salvación es de Jehová».\n\n"
            "Predicó en Nínive provocando el mayor arrepentimiento multitudinario de la historia antigua. Su experiencia fue señal tipológica suprema de la muerte, sepultura y resurrección de Jesucristo (Mateo 12:40)."
        ),
        # 18. Miqueas
        (
            18, "Miqueas", "מִיכָה", "H4318",
            "Judá e Israel (c. 735-700 a.C.)",
            "Profeta rural de Moreset-gat, defensor de la ética del pacto y heraldo mesiánico",
            "Miqueas 3:8",
            "Contemporáneo de Isaías y Oseas, alzó su voz en favor de los campesinos despojados por terratenientes corruptos, sacerdotes codiciosos y falsos profetas que profetizaban por dinero.\n\n"
            "Profetizó con exactitud asombrosa que el Mesías y Soberano eterno nacería en la humilde aldea de Belén Efrata (Miqueas 5:2), resumiendo el verdadero clamor divino: «hacer justicia, y amar misericordia, y humillarte ante tu Dios» (Miqueas 6:8)."
        ),
        # 19. Nahúm
        (
            19, "Nahúm", "נַחוּם", "H5151",
            "Caída de Asiria (c. 663-612 a.C.)",
            "Profeta de Elcos, proclamador de la santidad y venganza justiciera de Dios",
            "Nahúm 1:1-3",
            "Su nombre significa «consolador». Un siglo después del arrepentimiento efímero de Nínive bajo Jonás, Asiria reincidió en una crueldad sanguinaria sin límites. Nahúm proclamó con maestría poética y vehemencia el colapso final e irrevocable de la capital asiria.\n\n"
            "Consoló al pueblo oprimido de Judá recordándoles que «Jehová es bueno, fortaleza en el día de la angustia; y conoce a los que en él confían» (Nahúm 1:7)."
        ),
        # 20. Habacuc
        (
            20, "Habacuc", "חֲבַקּוּק", "H2265",
            "Vísperas de la Invasión Caldea (c. 608-605 a.C.)",
            "Profeta y músico del Templo, intercesor que dialoga con Dios",
            "Habacuc 2:1-4",
            "A diferencia de otros profetas que hablaban a los hombres en nombre de Dios, Habacuc llevó las perplejidades del corazón creyente ante el trono celestial: ¿por qué tolera Dios la injusticia en Judá y por qué usa a los crueles caldeos como vara de corrección?\n\n"
            "En su atalaya recibió la joya teológica que encendió la Reforma protestante: «Mas el justo por su fe vivirá» (Habacuc 2:4; Romanos 1:17), concluyendo con el cántico de adoración más sublime ante la prueba."
        ),
        # 21. Sofonías
        (
            21, "Sofonías", "צְפַנְיָה", "H6846",
            "Reinado de Josías en Judá (c. 640-621 a.C.)",
            "Príncipe de sangre real (tataranieto del rey Ezequías) y profeta de purificación",
            "Sofonías 1:1",
            "Perteneciente a la nobleza real de Jerusalén, ministró en los albores de las reformas del joven rey Josías. Denunció con severidad el sincretismo religioso, la adopción de modas paganas y la indiferencia espiritual de quienes creían que Dios «ni hace bien ni hace mal».\n\n"
            "Describió el Día de Jehová como día de ira cósmica, pero concluyó con una conmovedora revelación del Dios que se regocija sobre su remanente redimido con cánticos de alegría."
        ),
        # 22. Hageo
        (
            22, "Hageo", "חַגַּי", "H2292",
            "Restauración Post-Exílica (520 a.C.)",
            "Profeta del Segundo Templo y restaurador del fervor sacerdotal",
            "Hageo 1:1-3",
            "Primer profeta enviado a la comunidad judía retornada de Babilonia bajo Zorobabel y Josué. Los repatriados habían suspendido la reconstrucción del Templo durante dieciséis años para dedicarse a sus propias casas artesonadas y negocios privados.\n\n"
            "Con cuatro mensajes concisos y penetrantes exhortó: «Meditad sobre vuestros caminos», reanudando la obra en apenas 24 días y profetizando que la gloria postrera de aquella casa superaría a la primera por la presencia de Cristo."
        ),
        # 23. Zacarías
        (
            23, "Zacarías", "זְכַרְיָה", "H2148",
            "Restauración Post-Exílica y Esperanzas Mesiánicas (c. 520-480 a.C.)",
            "Sacerdote de la familia de Iddo, vidente apocalíptico y profeta de la redención",
            "Zacarías 1:1-3",
            "Compañero de ministerio de Hageo, nacido durante el cautiverio babilónico. Mediante ocho visiones nocturnas, coronaciones simbólicas y oráculos mesiánicos consoló a los constructores del Templo («No con ejército, ni con fuerza, sino con mi Espíritu»).\n\n"
            "Es el profeta que con mayor exactitud anticipó detalles de la Pasión de Cristo: su entrada humilde sobre un asno en Jerusalén (9:9), su venta por treinta monedas de plata (11:12), la mirada a Aquel a quien traspasaron (12:10) y la apertura de la fuente para lavar el pecado (13:1)."
        ),
        # 24. Malaquías
        (
            24, "Malaquías", "מַלְאָכִי", "H4401",
            "Cierre del Canon del Antiguo Testamento (c. 433-400 a.C.)",
            "Mensajero de Dios y centinela de la fidelidad del pacto matrimonial y sacerdotal",
            "Malaquías 1:1",
            "Su nombre significa «mi mensajero». Ministró en la época posterior a Nehemías, enfrentando la desilusión religiosa, la ofrenda de animales ciegos y cojos en el altar, el divorcio despiadado contra las esposas de la juventud y el robo de los diezmos y ofrendas.\n\n"
            "Utilizando un estilo dialéctico de preguntas y respuestas, anunció la venida del mensajero precursor (Juan el Bautista) y el advenimiento del «Sol de justicia», en cuyas alas vendrá salvación antes de que concluyera la revelación profética por cuatro siglos de silencio."
        ),
        # 25. Esdras
        (
            25, "Esdras", "עֶזְרָא", "H5830",
            "Retorno bajo el Imperio Persa (c. 480-440 a.C.)",
            "Sacerdote del linaje de Aarón, escriba eminente en la ley de Dios y reformador",
            "Esdras 7:6-10",
            "Líder de la segunda expedición de exiliados que regresó a Jerusalén en 458 a.C. bajo el patrocinio del rey Artajerjes I. Destacó por su consagración ejemplar: «había preparado su corazón para inquirir la ley de Jehová y para cumplirla, y para enseñar en Israel sus estatutos y decretos».\n\n"
            "Presidió el avivamiento espiritual del pueblo, expulsó las alianzas paganas y, según la tradición unánime judía, compiló el canon del Antiguo Testamento y redactó 1 y 2 Crónicas además del libro que lleva su nombre."
        ),
        # 26. Nehemías
        (
            26, "Nehemías", "נְחֶמְיָה", "H5166",
            "Reconstrucción de Jerusalén (c. 445-420 a.C.)",
            "Copero real del palacio imperial de Susa, gobernador piadoso de Judá y estadista",
            "Nehemías 1:1-11",
            "Hijo de Hacalías. Al enterarse del estado desolado y las murallas derruidas de Jerusalén, lloró, ayunó y oró al Dios del cielo. Autorizado por el rey persa Artajerjes, viajó como gobernador a Judá y reconstruyó los muros en tan solo 52 días frente a intensas conspiraciones enemigas.\n\n"
            "Combinó una oración incesante con una vigilancia militar estricta («con una mano trabajaban en la obra, y en la otra tenían la espada»). Instituyó reformas sociales contra la usura y cooperó con Esdras en la renovación del pacto sagrado."
        ),
        # 27. Mardoqueo / Tradición Judía de Ester
        (
            27, "Mardoqueo", "מָרְדֳּכַי", "H4782",
            "Imperio Persa bajo Asuero / Jerjes I (c. 486-465 a.C.)",
            "Funcionario judío de la corte de Susa, tutor de la reina Ester y gran visir del reino",
            "Ester 2:5-7",
            "De la tribu de Benjamín, criado en la capital persa de Susa. Crió a su prima huérfana Hadasa (Ester) y descubrió un complot para asesinar al rey. Al rehusar postrarse ante el soberbio Amán agagueo, desató una conspiración de exterminio contra todos los judíos del imperio.\n\n"
            "Con fe serena confrontó a Ester: «¿Y quién sabe si para esta hora has llegado al reino?». Tras el providencial rescate de Israel, fue exaltado como segundo del monarca persa e instituyó la festividad gozosa del Purim."
        ),
        # 28. Mateo (Leví)
        (
            28, "Mateo", "Μαθθαῖος", "G3156",
            "Siglo I d.C. (Judea y Diáspora)",
            "Publicano en Capernaúm, apóstol de Jesucristo y evangelista del Rey Mesías",
            "Mateo 9:9",
            "Hijo de Alfeo, empleado de aduanas que cobraba tributos comerciales en Galilea para el Imperio Romano y Herodes Antipas. Al oír la voz imperiosa de Jesús: «Sígueme», lo dejó todo inmediatamente y celebró un banquete para sus antiguos colegas recaudadores.\n\n"
            "Autor del primer Evangelio canónico, redactado con un profundo conocimiento de las profecías del Antiguo Testamento para demostrar a los lectores hebreos que Jesús de Nazaret es el Rey prometido del linaje de David y cumplimiento del pacto abrahámico."
        ),
        # 29. Marcos (Juan Marcos)
        (
            29, "Marcos", "Μᾶρκος", "G3138",
            "Siglo I d.C. (Jerusalén, Antioquía y Roma)",
            "Hijo de María de Jerusalén, misionero, colaborador de Bernabé y Pablo, y amanuense de Pedro",
            "Hechos 12:12; 1 Pedro 5:13",
            "Joven creyente en cuya casa familiar se reunía la iglesia primitiva en Jerusalén para orar cuando Pedro fue milagrosamente liberado de la cárcel. Acompañó a Pablo y Bernabé en su primer viaje misionero, aunque desertó en Panfilia; más tarde fue plenamente restaurado, llegando a ser «útil para el ministerio» (2 Timoteo 4:11).\n\n"
            "Recogió las memorias vivenciales y el testimonio apostólico de Pedro en Roma, redactando el Evangelio más dinámico y conciso, donde Jesús es presentado como el Siervo de Dios y el Hijo obediente que dio su vida en rescate por muchos."
        ),
        # 30. Lucas
        (
            30, "Lucas", "Λουκᾶς", "G3065",
            "Siglo I d.C. (Imperio Romano)",
            "Médico gentil de Antioquía, historiador de suprema precisión y compañero inseparable de Pablo",
            "Colosenses 4:14; Lucas 1:1-4",
            "Único escritor no judío del Nuevo Testamento. Hombre de vasta cultura griega y formación médica rigurosa, se unió a Pablo en Troas durante su segundo viaje misionero y permaneció fielmente a su lado en sus encarcelamientos en Cesarea y Roma («Sólo Lucas está conmigo», 2 Timoteo 4:11).\n\n"
            "Investigó minuciosamente con testigos oculares para componer su díptico monumental: el Evangelio de Lucas (destacando la compasión de Jesús por los marginados, mujeres, samaritanos y pecadores) y el libro de los Hechos de los Apóstoles."
        ),
        # 31. Juan el Apóstol
        (
            31, "Juan", "Ἰωάννης", "G2491",
            "Siglo I d.C. (Galilea, Jerusalén, Éfeso y Patmos)",
            "Pescador de Betsaida, el «discípulo amado», pilar de la iglesia de Jerusalén y apóstol teólogo",
            "Juan 21:20-24; Apocalipsis 1:9",
            "Hijo de Zebedeo y Salomé, hermano de Jacobo. Integró junto a Pedro y Jacobo el círculo más íntimo de Jesús, recostando su cabeza en el pecho del Maestro durante la Última Cena y permaneciendo fiel al pie de la cruz, donde Jesús le encomendó el cuidado de su madre María.\n\n"
            "Ministró en sus últimos años en la metrópoli de Éfeso. Desterrado en la agreste isla de Patmos por causa del Evangelio bajo Domiciano, recibió la sublime revelación del Apocalipsis. Redactó además el cuarto Evangelio y las tres epístolas universales de comunión y amor fraternal."
        ),
        # 32. Pablo de Tarso
        (
            32, "Pablo", "Παῦλος", "G3972",
            "Siglo I d.C. (Cilicia, Judea, Grecia y Roma)",
            "Ciudadano romano, fariseo instruido por Gamaliel, tejedor de tiendas y Apóstol a los Gentiles",
            "Hechos 9:1-16; Romanos 1:1",
            "Saulo de Tarso, celoso perseguidor de la iglesia primitiva que consintió en la muerte de Esteban. Camino a Damasco fue derribado por la luz celestial de Cristo resucitado, transformando radicalmente su vida y comisionándolo como apóstol a los reyes y a los gentiles.\n\n"
            "Realizó tres viajes misioneros épicos plantando iglesias por toda Asia Menor y Grecia, compareció ante procuradores y césares en Roma y redactó trece epístolas canónicas que formularon la doctrina cristiana de la justificación por la fe, la gracia soberana y la unión mística del creyente en Cristo Jesús."
        ),
        # 33. Santiago (Jacobo el Justo)
        (
            33, "Santiago", "Ἰάκωβος", "G2385",
            "Siglo I d.C. (Nazaret y Jerusalén)",
            "Hermano del Señor Jesús, testigo de su resurrección y obispo principal de la iglesia de Jerusalén",
            "Gálatas 1:19; Santiago 1:1",
            "Hermano terrenal de Jesús que inicialmente no creía en su mesianismo durante su ministerio público. Tras la resurrección, el Señor se le apareció en privado (1 Corintios 15:7), convirtiéndose en un devoto pilar de la asamblea apostólica.\n\n"
            "Presidió el crucial Concilio de Jerusalén (Hechos 15) que preservó la libertad del Evangelio para los gentiles. Conocido históricamente como «el Justo» por su consagración a la oración intercesora, redactó la epístola práctica sobre la fe viva que se demuestra mediante obras de misericordia."
        ),
        # 34. Pedro (Simón bar Jonás)
        (
            34, "Pedro", "Πέτρος", "G4074",
            "Siglo I d.C. (Galilea, Jerusalén, Antioquía y Roma)",
            "Pescador de Betsaida, portavoz del colegio apostólico y pastor de la grey de Dios",
            "Mateo 16:16-19; Juan 21:15-17",
            "Hermano de Andrés, a quien Jesús llamó y apodó «Cefas» (Piedra). Proclamó la gran confesión: «Tú eres el Cristo, el Hijo del Dios viviente». A pesar de su dolorosa negación en el patio del sumo sacerdote, fue perdonado y restaurado tiernamente por Cristo a orillas del mar de Tiberias.\n\n"
            "Abrió las puertas del Evangelio en Pentecostés ante los judíos y en Cesarea ante los gentiles en casa de Cornelio. Redactó dos epístolas pastorales inmortales para sostener la esperanza viva de los creyentes perseguidos, sellando su testimonio apostólico con el martirio en Roma."
        ),
        # 35. Judas (Hermano de Jacobo)
        (
            35, "Judas", "Ἰούδας", "G2455",
            "Siglo I d.C. (Galilea y Judea)",
            "Hermano carnal de Jacobo y del Señor Jesús, defensor ferviente de la ortodoxia apostólica",
            "Judas 1:1",
            "Al igual que su hermano Santiago, no creyó en Jesús durante su ministerio terrenal pero fue transformado por su resurrección, figurando en el aposento alto esperando el Espíritu Santo (Hechos 1:14). Con profunda humildad se presentó a sí mismo simplemente como «siervo de Jesucristo y hermano de Jacobo».\n\n"
            "Autor de la enérgica epístola que exhorta a «contender ardientemente por la fe que ha sido una vez dada a los santos» frente a la infiltración de libertinos e impostores, concluyendo con una de las doxologías más sublimes de las Sagradas Escrituras."
        ),
    ]

    cur.executemany("""
    INSERT INTO biblical_authors (author_id, name_es, name_original, strong_code, era, occupation, calling_verse, biography)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """, authors_data)

    print("[INFO] Insertando 66 Fichas Técnicas de Libros Canónicos...")
    summaries_data = [
        # --- PENTATEUCO (1-5) ---
        (
            1, "Gn", "OT", "Pentateuco", 1,
            "El pueblo de Israel acampado en las llanuras de Moab, preparándose para entrar a Canaán.",
            "c. 1446-1406 a.C.",
            "Egipto dominaba el Cercano Oriente con sus panteones idólatras. Los israelitas, tras cuatro siglos en Egipto, necesitaban conocer al Dios Único, Creador de los cielos y la tierra, y recordar los pactos sagrados jurados a Abraham, Isaac y Jacob.",
            "1. La Creación ex nihilo y la soberanía de Dios sobre el cosmos.\n2. La caída del hombre, la entrada del pecado y el Protoevangelio (Gn 3:15).\n3. La elección soberana de la línea patriarcal y la providencia de Dios (historia de José).",
            "Génesis 1:1",
            "• Reconocer que Dios es el origen, sustento y propósito final de toda nuestra existencia diaria.\n• Confiar en que los planes providenciales de Dios transforman el mal en bien para nuestra salvación.\n• Caminar en fe y obediencia como Abraham, creyendo en las promesas divinas aún contra toda esperanza visible."
        ),
        (
            2, "Ex", "OT", "Pentateuco", 1,
            "La nación redimida de Israel en su marcha por el desierto de Sinaí.",
            "c. 1446-1406 a.C.",
            "Bajo la dinastía de faraones opresores que desconocían a José, los hebreos sufrían dura servidumbre. Dios ejecuta juicio sobre los falsos dioses de Egipto mediante las diez plagas, inaugura la Pascua y constituye a Israel como reino de sacerdotes.",
            "1. La redención por la sangre del cordero pascual y el poder liberador de Yahvé.\n2. La promulgación de la Ley moral (Decálogo) y el pacto en el monte Sinaí.\n3. La presencia santa de Dios habitando en medio de su pueblo mediante el Tabernáculo.",
            "Éxodo 3:14",
            "• Alabar a Dios como el Libertador soberano que rompe las cadenas del pecado y de la esclavitud espiritual.\n• Respetar la santidad de los mandamientos divinos como guía de gratitud y rectitud ética.\n• Cultivar una comunión reverente sabiendo que Dios anhela morar en medio de su pueblo redimido."
        ),
        (
            3, "Lv", "OT", "Pentateuco", 1,
            "Los sacerdotes levitas y la congregación de Israel al pie del monte Sinaí.",
            "c. 1445 a.C.",
            "Con el Tabernáculo erigido en el desierto, surge la necesidad apremiante de regular cómo un pueblo pecador puede acercarse y convivir con el Dios tres veces santo sin ser consumido por su justicia.",
            "1. La expiación sustitutiva mediante sacrificios cruentos que señalan a Cristo.\n2. La santidad integral de la vida del creyente («Sed santos, porque yo soy santo»).\n3. El Día de la Expiación (Yom Kipur) y el perdón continuo de los pecados.",
            "Levítico 19:2",
            "• Acercarnos confiadamente a Dios únicamente sobre la base del sacrificio expiatorio perfecto de Cristo.\n• Consagrar cada aspecto de nuestro cuerpo, pensamientos y relaciones a la santidad que honra a Dios.\n• Valorar el perdón y la restauración espiritual que Dios nos brinda diariamente."
        ),
        (
            4, "Nm", "OT", "Pentateuco", 1,
            "La segunda generación de israelitas nacida en el desierto, rumbo a la ribera oriental del Jordán.",
            "c. 1406 a.C.",
            "Relata los casi cuarenta años de peregrinación errante por el desierto de Parán, provocada por la incredulidad en Cades-barnea. Registra dos censos militares de la congregación antes y después del juicio.",
            "1. La fidelidad inquebrantable de Dios frente a la murmuración y rebelión humana.\n2. La disciplina pedagógica y justa de Dios sobre su pueblo incrédulo.\n3. La serpiente de bronce como figura redentora de la salvación por la fe.",
            "Números 6:24-26",
            "• Cuidarnos de la queja y el desánimo, recordando las innumerables bondades que Dios nos ha mostrado.\n• Confiar plenamente en el liderazgo y las promesas de Dios cuando enfrentemos gigantes en el camino.\n• Mirar a Cristo crucificado como nuestra única fuente de vida y sanidad espiritual."
        ),
        (
            5, "Dt", "OT", "Pentateuco", 1,
            "La nueva generación de Israel que aguardaba cruzar el Jordán para poseer Canaán.",
            "c. 1406 a.C.",
            "Moisés, con 120 años de edad y a punto de morir en el monte Nebo, pronuncia sus tres grandes discursos de despedida en las llanuras de Moab, renovando el pacto antes de que el pueblo enfrente las tentaciones de Canaán.",
            "1. El Shemá: la adoración monoteísta exclusiva al Único Señor con todo el corazón.\n2. La advertencia contra la complacencia, el olvido y la asimilación cultural idólatra.\n3. La elección solemne entre la vida y la bendición frente a la muerte y la maldición.",
            "Deuteronomio 6:4-5",
            "• Amar al Señor nuestro Dios con toda el alma, mente y fuerzas en cada decisión de la vida cotidiana.\n• Transmitir con fidelidad la Palabra de Dios a nuestros hijos y a las nuevas generaciones en el hogar.\n• Recordar constantemente que toda bendición material proviene de la gracia inmerecida de Dios."
        ),

        # --- HISTÓRICOS (6-17) ---
        (
            6, "Jos", "OT", "Libros Históricos", 2,
            "Las doce tribus de Israel en proceso de conquista y reparto de la tierra prometida.",
            "c. 1380 a.C.",
            "Tras la muerte de Moisés, Josué asume el mando. Las ciudades-estado cananeas estaban fortificadas y sumidas en ritos inmorales degradantes. Dios entrega la tierra mediante batallas milagrosas guiadas por el Arca del Pacto.",
            "1. La fidelidad de Dios al cumplir su promesa territorial a los patriarcas.\n2. La necesidad de esfuerzo, valor y meditación constante en la Ley para triunfar espiritualmente.\n3. El compromiso incondicional: «Yo y mi casa serviremos a Jehová».",
            "Josué 1:8",
            "• Meditar de día y de noche en las Escrituras para que nuestro caminar sea prosperado según la voluntad divina.\n• Actuar con santa valentía ante los desafíos, sabiendo que el Señor va con nosotros adondequiera que vayamos.\n• Establecer en nuestros hogares un compromiso inquebrantable de servicio exclusivo a Dios."
        ),
        (
            7, "Jue", "OT", "Libros Históricos", 3,
            "Las tribus de Israel dispersas en sus territorios tribales en constante asedio.",
            "c. 1050-1000 a.C.",
            "Tras la muerte de Josué, la falta de unidad nacional y la seducción de los cultos a Baal y Asera provocaron continuas crisis. Dios levantaba caudillos carismáticos (jueces) para librarlos de invasores moabitas, madianitas y filisteos.",
            "1. El ciclo continuo de apostasía: pecado, opresión, clamor, liberación y recaída.\n2. El caos moral cuando «cada uno hacía lo que bien le parecía ante sus propios ojos».\n3. La misericordia paciente de Dios al escuchar el gemido de su pueblo humillado.",
            "Jueces 21:25",
            "• Evitar el relativismo moral, sometiendo nuestros criterios a la verdad revelada por Dios.\n• Reconocer que la idolatría del corazón conduce inexorablemente al vacío y la opresión.\n• Acudir al Señor con arrepentimiento genuino cada vez que reconozcamos nuestro extravío."
        ),
        (
            8, "Rt", "OT", "Libros Históricos", 3,
            "La comunidad de creyentes en Israel durante la era monárquica temprana.",
            "c. 1000 a.C.",
            "Acontece en los oscuros días de los jueces. Una hambruna empuja a la familia de Elimelec a Moab. Tras quedar viudas y en la indigencia, Noemí y su nuera moabita Rut regresan a Belén de Judá durante la siega de la cebada.",
            "1. La providencia invisible de Dios dirigiendo circunstancias aparentemente ordinarias.\n2. La lealtad del amor pactual (jéjed) manifestada por Rut hacia Noemí y hacia el Dios de Israel.\n3. La figura de Booz como pariente redentor (Goel), tipo de Cristo redimiendo a la iglesia.",
            "Rut 1:16",
            "• Confiar en que Dios orquesta detalles silenciosos de nuestra vida para cumplir sus propósitos eternos.\n• Mostrar compasión, fidelidad y bondad abnegada con los miembros más vulnerables de la familia.\n• Descansar en Cristo Jesús como nuestro Redentor que pagó nuestra deuda y nos adoptó por gracia."
        ),
        (
            9, "1S", "OT", "Libros Históricos", 3,
            "El pueblo de Israel experimentando la transición de la teocracia tribal a la monarquía.",
            "c. 930 a.C.",
            "Israel sufría la severa presión militar de los filisteos y la decadencia del sacerdocio en Silo. El pueblo demanda impacientemente un rey humano «como todas las demás naciones», resultando en la unción de Saúl y su posterior rechazo divino.",
            "1. La soberanía de Dios al juzgar el corazón y no la apariencia externa del hombre.\n2. El contraste entre la desobediencia arrogante de Saúl y la fe devota del joven pastor David.\n3. La obediencia sincera superior a los sacrificios religiosos huecos.",
            "1 Samuel 16:7",
            "• Cuidar la pureza interior del corazón antes que preocuparnos por las apariencias ante la sociedad.\n• Enfrentar los gigantes de la vida en el nombre de Jehová de los ejércitos y no con fuerzas humanas.\n• Obedecer pronta y cabalmente las instrucciones de Dios sin buscar justificaciones personales."
        ),
        (
            10, "2S", "OT", "Libros Históricos", 3,
            "El reino unido de Israel consolidado bajo la dinastía davídica.",
            "c. 930 a.C.",
            "Narra los cuarenta años del reinado de David: su entronización en Hebrón, la conquista de Jerusalén, el traslado del Arca a Sión y sus victorias militares, junto con la dolorosa tragedia familiar tras su pecado con Betsabé.",
            "1. El Pacto Davídico incondicional (2 S 7): la promesa de un trono y reino eterno cumplido en Cristo.\n2. Las graves consecuencias personales y familiares del pecado, aun en los siervos amados de Dios.\n3. La gracia perdonadora de Dios ante el quebrantamiento y arrepentimiento sincero.",
            "2 Samuel 7:16",
            "• Valorar el perdón inmenso de Dios manteniéndonos alerta contra la soberbia y la complacencia.\n• Aceptar con humildad la disciplina correctiva del Señor en tiempos de caída espiritual.\n• Edificar nuestra esperanza en el reinado eterno del Hijo de David, Jesucristo."
        ),
        (
            11, "1R", "OT", "Libros Históricos", 24,
            "El pueblo de Israel y Judá durante el esplendor y la posterior fractura nacional.",
            "c. 550 a.C.",
            "Abre con la unción de Salomón, la edificación del Templo y la visita de la reina de Sabá, pero describe cómo las esposas extranjeras desviaron su corazón. Tras su muerte, el reino se divide en dos: Israel (norte) y Judá (sur).",
            "1. La fidelidad de Dios recompensando la obediencia y trayendo disciplina sobre la apostasía.\n2. El pecado de Jeroboam al erigir becerros de oro por conveniencia política.\n3. El ministerio profético intrépido de Elías desafiando a Acab y a los 450 profetas de Baal en el Carmelo.",
            "1 Reyes 18:21",
            "• Mantener nuestro corazón totalmente leal a Dios sin tolerar compromisos con los ídolos del mundo.\n• No buscar atajos humanos ni alterar la adoración de Dios para acomodar intereses personales.\n• Permanecer firmes en la verdad aún cuando nos sintamos en minoría frente a una cultura hostil."
        ),
        (
            12, "2R", "OT", "Libros Históricos", 24,
            "Los remanentes cautivos en Babilonia reflexionando sobre las causas de su ruina nacional.",
            "c. 550 a.C.",
            "Narra la espiral descendente de ambos reinos. Samaria cae en 722 a.C. ante Asiria debido a su idolatría irremediable. Judá experimenta breves reformas con Ezequías y Josías, pero finalmente Jerusalén y el Templo son arrasados en 586 a.C. por Babilonia.",
            "1. La justicia ineludible de Dios sobre la desobediencia prolongada y el desprecio a los profetas.\n2. El ministerio milagroso de Eliseo como demostración del poder y compasión divina.\n3. La preservación providencial de la simiente davídica aun en medio del cautiverio en Babilonia.",
            "2 Reyes 17:13-14",
            "• Atender con diligencia las advertencias de la Palabra antes de que el corazón se endurezca.\n• Reconocer que la historia humana se encuentra bajo el soberano juicio y gobierno de Dios.\n• Confiar en que Dios jamás abandona a su remanente fiel, incluso en las épocas más oscuras."
        ),
        (
            13, "1Cr", "OT", "Libros Históricos", 24,
            "La comunidad de repatriados post-exílicos que reedificaban Jerusalén.",
            "c. 450-400 a.C.",
            "Los exiliados que regresaron de Babilonia eran un remanente pobre y desalentado. Esdras recopila genealogías y la historia de David con énfasis sacerdotal para recordarles su identidad sagrada como pueblo del pacto.",
            "1. La centralidad del Templo, el sacerdocio levítico y la adoración reverente y ordenada.\n2. La soberanía de Dios a lo largo de las generaciones trazada en las genealogías sagradas.\n3. La preparación minuciosa de David para que su hijo Salomón construyera la casa de Dios.",
            "1 Crónicas 29:11-12",
            "• Dar a Dios la prioridad suprema en nuestras vidas mediante una alabanza gozosa y reverente.\n• Entender que nuestra herencia espiritual tiene raíces firmes en el propósito eterno de Dios.\n• Contribuir con generosidad y alegría de corazón para la extensión del reino de Dios."
        ),
        (
            14, "2Cr", "OT", "Libros Históricos", 24,
            "El remanente judío restaurado buscando revitalizar su vida religiosa comunitaria.",
            "c. 450-400 a.C.",
            "Continúa la crónica centrándose exclusivamente en los reyes de Judá, resaltando los avivamientos espirituales de Asa, Josafat, Ezequías y Josías, culminando con el edicto libertador del emperador persa Ciro el Grande.",
            "1. La promesa divina de perdón y sanidad cuando el pueblo se humilla, ora y busca el rostro de Dios.\n2. La bendición de las reformas espirituales y el retorno a las Escrituras.\n3. La compasión divina que envió mensajeros continuos antes de ejecutar el juicio final.",
            "2 Crónicas 7:14",
            "• Humillarnos en oración sincera y apartarnos del pecado para experimentar la sanidad de Dios.\n• Buscar a Dios en tiempos de crisis como el rey Josafat: «No sabemos qué hacer, y a ti volvemos nuestros ojos».\n• Renovar continuamente nuestro compromiso con la lectura y obediencia de la Palabra de Dios."
        ),
        (
            15, "Esd", "OT", "Libros Históricos", 24,
            "Los exiliados judíos que regresaron en dos oleadas desde Babilonia a Jerusalén.",
            "c. 440 a.C.",
            "Ciro promulga el decreto en 538 a.C. permitiendo el retorno bajo Zorobabel para reconstruir el Templo. Décadas más tarde, en 458 a.C., Esdras encabeza la segunda expedición para restaurar la pureza moral y la enseñanza de la Ley.",
            "1. La soberanía de Dios sobre los reyes gentiles (Ciro, Darío, Artajerjes) para favorecer a su pueblo.\n2. La perseverancia frente a la oposición y calumnias de los pueblos vecinos.\n3. La pasión por el estudio, cumplimiento y enseñanza pedagógica de la Palabra de Dios.",
            "Esdras 7:10",
            "• Dedicar tiempo sistemático a estudiar, vivir y enseñar la verdad bíblica con integridad.\n• No desmayar en la edificación de la obra de Dios cuando aparezcan intimidaciones o desánimos.\n• Confesar comunitariamente el pecado para mantener la comunión íntima con el Señor."
        ),
        (
            16, "Neh", "OT", "Libros Históricos", 25,
            "Los habitantes de Jerusalén y las aldeas de Judá en reconstrucción.",
            "c. 430 a.C.",
            "Casi un siglo después del primer retorno, las murallas de Jerusalén seguían en ruinas, dejando a la ciudad indefensa ante el desprecio de samaritanos y árabes. Nehemías viaja con permiso imperial para liderar la reconstrucción física y espiritual.",
            "1. El liderazgo espiritual que combina oración continua, fe audaz y planificación estratégica rigurosa.\n2. La unidad de la congregación trabajando hombro con hombro con vigilancia constante.\n3. El gozo del Señor como fortaleza inexpugnable del creyente en medio del cansancio.",
            "Nehemías 8:10",
            "• Llevar toda angustia y proyecto a Dios en oración antes de emprender cualquier acción humana.\n• Trabajar activamente en la iglesia y la comunidad manteniendo las defensas espirituales levantadas.\n• Encontrar en el gozo del Señor la energía necesaria para superar los momentos de mayor agotamiento."
        ),
        (
            17, "Est", "OT", "Libros Históricos", 26,
            "Los millones de judíos dispersos en las 127 provincias del Imperio Medo-Persa.",
            "c. 465-424 a.C.",
            "Ambientado en la fastuosa capital de Susa durante el reinado de Asuero (Jerjes I). El perverso Amán consigue un decreto real irrevocable para aniquilar a todos los judíos del imperio en un solo día.",
            "1. La providencia soberana de Dios obrando silenciosamente entre bastidores (el nombre de Dios no se menciona expresamente).\n2. El valor abnegado de Ester y la fe firme de Mardoqueo: «¿Y quién sabe si para esta hora has llegado al reino?».\n3. La ironía del juicio divino: los enemigos son atrapados en las mismas trampas que tramaron.",
            "Ester 4:14",
            "• Confiar plenamente en que Dios sigue gobernando los acontecimientos cuando su mano parece oculta.\n• Actuar con valentía ética en nuestro lugar de influencia, asumiendo riesgos por causa del bien.\n• Celebrar con gratitud las liberaciones y victorias que el Señor nos concede en la vida."
        ),

        # --- POÉTICOS Y SAPIENCIALES (18-22) ---
        (
            18, "Job", "OT", "Poéticos y Sapienciales", 1,
            "Todos los seres humanos que enfrentan el misterio del sufrimiento inocente.",
            "c. Época Patriarcal (c. 2000-1800 a.C.)",
            "Ubicado en la tierra de Uz. Job, un varón íntegro y temeroso de Dios, pierde repentinamente en un solo día sus diez hijos, todas sus riquezas y su salud física en medio de un conflicto cósmico entre Dios y Satanás.",
            "1. La soberanía absoluta de Dios que trasciende la comprensión y los esquemas teológicos humanos.\n2. El problema del sufrimiento del justo y la refutación de la teología mecánica de la retribución.\n3. La fe perseverante que exclama: «Yo sé que mi Redentor vive, y al fin se levantará sobre el polvo».",
            "Job 19:25",
            "• Adorar a Dios por quien Él es y no solo por las bendiciones materiales que de Él recibimos.\n• Acompañar a los que sufren con silencio comprensivo y empatía, evitando juicios condenatorios ligeros.\n• Confiar en la sabiduría y bondad divina aun en medio de las pruebas más dolorosas e inexplicables."
        ),
        (
            19, "Sal", "OT", "Poéticos y Sapienciales", 4,
            "La congregación del pueblo de Dios en la adoración pública del Templo y en la devoción privada.",
            "c. 1410-430 a.C. (compilación davídica y post-exílica)",
            "Himnario inspirado y devocionario por excelencia de Israel. Abarca diez siglos de historia, desde Moisés (Sal 90) hasta el retorno del exilio babilónico (Sal 126 y 137).",
            "1. La alabanza suprema a la majestad, justicia, santidad y misericordia eterna de Dios.\n2. El lamento sincero del alma humana derramando dolor, dudas y persecuciones ante el trono divino.\n3. Las profecías mesiánicas sobre la entronización, sufrimiento y resurrección del Redentor.",
            "Salmos 23:1",
            "• Acudir a Dios con absoluta honestidad emocional en la oración, depositando en Él ansiedades y gozos.\n• Descansar en el cuidado amoroso de Jehová como nuestro Buen Pastor que suple todas nuestras necesidades.\n• Cultivar una vida de gratitud y alabanza continua que transforme nuestra perspectiva cotidiana."
        ),
        (
            20, "Pr", "OT", "Poéticos y Sapienciales", 5,
            "Los jóvenes de Israel, líderes, familias y todo aquel que busca sabiduría práctica para la vida.",
            "c. 970-700 a.C.",
            "Compilado fundamentalmente por Salomón y más tarde copiado por escribas del rey Ezequías. En una sociedad con múltiples influencias morales, enseña el arte de vivir con destreza moral bajo el temor de Yahvé.",
            "1. El principio de la sabiduría: el temor reverente a Jehová.\n2. Consejos prácticos sobre la lengua, el trabajo diligente, las finanzas, la justicia y la familia.\n3. El contraste vitalicio entre el sabio que escucha consejo y el necio que sigue su propia opinión.",
            "Proverbios 3:5-6",
            "• Confiar en el Señor de todo corazón antes que apoyarnos en nuestra propia prudencia humana.\n• Cuidar celosamente las palabras que pronunciamos, usando la lengua para edificar y sembrar paz.\n• Actuar con integridad, diligencia y pureza en el trabajo, los negocios y el ámbito íntimo del hogar."
        ),
        (
            21, "Ec", "OT", "Poéticos y Sapienciales", 5,
            "El lector que indaga con rigor filosófico el sentido de la existencia terrenal.",
            "c. 935 a.C.",
            "Salomón reflexiona hacia el ocaso de su vida tras haber experimentado el colmo del poder, los placeres sensoriales, las obras colosales y el saber intelectual. Examina la vida «debajo del sol» separada de Dios.",
            "1. La futilidad y vacío intrínseco de los logros y placeres humanos cuando se prescinde del Creador.\n2. La realidad inexorable de la muerte y la incertidumbre de las riquezas temporales.\n3. La conclusión suprema: «Teme a Dios, y guarda sus mandamientos; porque esto es el todo del hombre».",
            "Eclesiastés 12:13",
            "• Recordar a nuestro Creador en los días de la juventud antes de que lleguen los días difíciles.\n• Disfrutar de los placeres sencillos del trabajo, el alimento y la familia como dádivas de la gracia de Dios.\n• Enfocar la vida en la eternidad, sabiendo que Dios traerá toda obra a juicio justo."
        ),
        (
            22, "Cnt", "OT", "Poéticos y Sapienciales", 5,
            "Esposos, jóvenes y el pueblo de Dios que celebra la pureza del amor nupcial.",
            "c. 965 a.C.",
            "Un majestuoso poema lírico que exalta el amor romántico y conyugal entre un rey pastor (Salomón) y una humilde doncella sulamita en los bellos parajes del campo de Israel.",
            "1. La santidad, hermosura y dignidad del amor conyugal y la intimidad matrimonial instituida por Dios.\n2. La exclusividad, el deleite y la fidelidad del pacto de amor («Yo soy de mi amado, y mi amado es mío»).\n3. El amor inquebrantable que es «fuerte como la muerte» y que las muchas aguas no pueden apagar.",
            "Cantares 8:7",
            "• Proteger la pureza y reverencia del amor en el noviazgo y el matrimonio como un don sagrado.\n• Cultivar la ternura, el aprecio mutuo y la fidelidad sin reservas en la relación de pareja.\n• Contemplar en el amor conyugal el reflejo del amor apasionado y eterno de Cristo por su Iglesia."
        ),

        # --- PROFETAS MAYORES (23-27) ---
        (
            23, "Is", "OT", "Profetas Mayores", 9,
            "La nación de Judá, Jerusalén y las generaciones futuras hasta la venida del Mesías.",
            "c. 740-681 a.C.",
            "Isaías ministró durante la expansión brutal del Imperio Asirio que destruyó a Samaria en 722 a.C. y asedió a Jerusalén en tiempos de Ezequías. Contempló la santidad majestuosa de Yahvé en el Templo celestial.",
            "1. La santidad trascendente del Dios de Israel: «Santo, Santo, Santo, Jehová de los ejércitos».\n2. El juicio sobre el orgullo de Judá y de los imperios mundiales.\n3. La redención mesiánica a través del Siervo de Jehová herido por nuestras rebeliones (Is 53).",
            "Isaías 53:5",
            "• Descansar en el sacrificio vicario de Cristo Jesús como pago pleno por nuestras transgresiones y paz para el alma.\n• Renovar nuestras fuerzas en la oración confiada: los que esperan en Jehová levantarán alas como las águilas.\n• Vivir con una reverencia profunda reconociendo la santidad gloriosa del Señor en todo momento."
        ),
        (
            24, "Jer", "OT", "Profetas Mayores", 10,
            "Los reyes, sacerdotes y habitantes de Judá antes y durante el cautiverio babilónico.",
            "c. 627-580 a.C.",
            "Judá colapsaba espiritualmente en idolatría y sacrificios a Moloc mientras el Imperio Babilónico de Nabucodonosor se convertía en la potencia hegemónica. Jeremías advirtió incansablemente que Jerusalén caería.",
            "1. El juicio inevitable sobre el pecado endurecido y la apostasía nacional.\n2. El engaño incurable del corazón humano separado de la gracia divina.\n3. La gloriosa promesa del Nuevo Pacto grabado en la mente y el corazón con perdón eterno de iniquidades.",
            "Jeremías 31:33",
            "• Examinar nuestro corazón a la luz de Dios para extirpar cualquier ídolo oculto o autosuficiencia.\n• Permanecer fieles al testimonio de la verdad aunque la sociedad se burle o nos rechace.\n• Regocijarnos en la gracia del Nuevo Pacto donde el Espíritu Santo escribe la ley divina en nuestras vidas."
        ),
        (
            25, "Lm", "OT", "Profetas Mayores", 10,
            "Los sobrevivientes desolados que contemplaban las ruinas humeantes de Jerusalén.",
            "c. 586 a.C.",
            "Cinco poemas acrósticos fúnebres redactados inmediatamente tras la destrucción de Jerusalén y del Templo de Salomón por los ejércitos caldeos, presenciando hambrunas atroces y deportación masiva.",
            "1. El dolor desgarrador y el quebranto ante las justas consecuencias del pecado.\n2. El reconocimiento de la justicia impecable de Dios en el castigo de la rebelión.\n3. El rayo de luz en medio de las cenizas: «Por la misericordia de Jehová no hemos sido consumidos».",
            "Lamentaciones 3:22-23",
            "• Acudir a Dios en los momentos de mayor pérdida y quebranto con una fe que no se rinde.\n• Recordar cada amanecer que las compasiones y bondades de Dios son nuevas cada mañana.\n• Esperar en silencio la salvación de Dios aun cuando todo alrededor parezca haberse derrumbado."
        ),
        (
            26, "Ez", "OT", "Profetas Mayores", 11,
            "La comunidad de cautivos judíos junto al río Quebar en Babilonia.",
            "c. 593-571 a.C.",
            "Ezequiel fue deportado en 597 a.C. Los cautivos abrigaban falsas esperanzas de un pronto regreso, pensando que el Templo jamás caería. Ezequiel muestra que la gloria de Dios abandonó el santuario a causa de sus abominaciones.",
            "1. La trascendencia y santidad de la gloria de Yahvé («Y sabrán que yo soy Jehová»).\n2. La responsabilidad moral individual ante Dios por los propios pecados.\n3. La regeneración interior por el Espíritu: el corazón de piedra cambiado por un corazón de carne sensible.",
            "Ezequiel 36:26",
            "• Asumir con madurez nuestra responsabilidad personal ante Dios sin culpar a las generaciones previas.\n• Clamar para que el Espíritu Santo siga ablandando y renovando nuestro corazón cada día.\n• Interceder con fe por la resurrección espiritual de vidas y familias enteras que parecen valles de huesos secos."
        ),
        (
            27, "Dn", "OT", "Profetas Mayores", 12,
            "El pueblo judío disperso bajo imperios paganos y los creyentes de todos los siglos.",
            "c. 536 a.C.",
            "Daniel fue llevado cautivo a Babilonia en 605 a.C., sirviendo en los palacios de Nabucodonosor y Darío. El libro combina relatos históricos de fidelidad heroica con visiones apocalípticas de imperios sucesivos.",
            "1. La soberanía suprema del Dios Altísimo sobre todos los reyes y naciones de la tierra.\n2. La fidelidad inquebrantable en medio de una cultura pagana hostil.\n3. El establecimiento invencible del Reino del Hijo del Hombre que nunca tendrá fin.",
            "Daniel 2:44",
            "• Mantener convicciones firmes y no contaminarnos con los placeres o valores corruptos del mundo.\n• Orar con constancia y devoción disciplinada, confiando en que Dios reina por encima de cualquier crisis política.\n• Consagrar nuestra vida al servicio del Reino celestial inquebrantable de Jesucristo."
        ),

        # --- PROFETAS MENORES (28-39) ---
        (
            28, "Os", "OT", "Profetas Menores", 13,
            "El Reino del Norte de Israel (Efraín) en sus últimas décadas antes de la destrucción asiria.",
            "c. 750-715 a.C.",
            "Israel vivía una prosperidad material aparente pero sumida en prostitución cúltica a Baal y alianzas con Asiria y Egipto. La tragedia conyugal de Oseas con Gomer retrata el corazón herido de Dios por la traición idolátrica.",
            "1. La infidelidad espiritual como adulterio contra el Dios del pacto.\n2. El juicio inevitable por la falta de conocimiento verdadero de Dios.\n3. El amor redentor y compasivo de Dios que promete sanar la rebelión de su pueblo gratuitamente.",
            "Oseas 6:6",
            "• Buscar un conocimiento vivo e íntimo de Dios más allá de ritos religiosos externos.\n• Arrepentirnos de toda tibieza espiritual o afecto idolátrico que desplace a Cristo del primer lugar.\n• Descansar en la misericordia incondicional de Dios que recibe con amor entrañable a quien regresa a Él."
        ),
        (
            29, "Jl", "OT", "Profetas Menores", 14,
            "Los sacerdotes, ancianos y habitantes de la tierra de Judá.",
            "c. 835 a.C.",
            "Una devastadora plaga de langostas devoró completamente la vegetación, viñedos e higueras de Judá, interrumpiendo el culto en el Templo. Joel interpreta esta catástrofe como un llamamiento al arrepentimiento nacional.",
            "1. El Día de Jehová como día de juicio sobre las naciones y purificación de su pueblo.\n2. El llamado urgente al arrepentimiento interior: «Rasgad vuestro corazón, y no vuestros vestidos».\n3. La profecía del derramamiento glorioso del Espíritu Santo sobre toda carne.",
            "Joel 2:28",
            "• Rasgar el corazón con contrición verdadera ante Dios en lugar de guardar meras apariencias religiosas.\n• Vivir a la luz del pronto regreso del Señor y del Día del Juicio con sobriedad y vigilancia.\n• Pedir continuamente la llenura del Espíritu Santo para testificar con poder y valentía."
        ),
        (
            30, "Am", "OT", "Profetas Menores", 15,
            "Las clases acomodadas y los líderes religiosos del Reino del Norte en Samaria y Bet-el.",
            "c. 760 a.C.",
            "Bajo Jeroboam II, Israel disfrutaba de expansión territorial y riqueza deslumbrante, pero los ricos oprimían a los pobres, sobornaban a los jueces y mantenían una religiosidad pomposa pero vacía.",
            "1. La justicia social y ética como exigencia inseparable del conocimiento de Dios.\n2. El juicio universal de Dios sobre los pecados de crueldad de todas las naciones.\n3. La advertencia solemne: «Prepárate para venir al encuentro de tu Dios, oh Israel».",
            "Amós 5:24",
            "• Practicar una fe activa que defienda a los necesitados y promueva la equidad en nuestras relaciones.\n• Rechazar cualquier adoración que no vaya acompañada de una conducta cotidiana recta.\n• Vivir preparados espiritualmente en todo momento para comparecer ante nuestro Creador."
        ),
        (
            31, "Abd", "OT", "Profetas Menores", 16,
            "Los orgullosos habitantes de Edom y el pueblo angustiado de Judá.",
            "c. 586 a.C.",
            "Los edomitas (descendientes de Esaú), asentados en las inexpugnables fortalezas rocosas de Seir, se burlaron y saquearon a Jerusalén cuando los babilonios la invadieron, entregando a los prófugos.",
            "1. El juicio implacable de Dios sobre la soberbia y la autosuficiencia humana.\n2. La gravedad del pecado de indiferencia y regocijo ante la calamidad del hermano.\n3. La restauración final de Sión y el triunfo del Reino universal de Dios.",
            "Abdías 1:15",
            "• Despojarnos de todo orgullo o autosuficiencia en nuestras capacidades humanas o materiales.\n• No alegrarnos jamás del dolor o fracaso del prójimo, sino mostrar solidaridad y consuelo cristiano.\n• Confiar en que Dios vindicará a su pueblo en el día final."
        ),
        (
            32, "Jon", "OT", "Profetas Menores", 17,
            "El pueblo de Israel para desafiar su etnocentrismo y mostrar la gracia de Dios hacia las naciones.",
            "c. 760 a.C.",
            "Nínive era la capital brutal de Asiria, archi-enemiga de Israel. Jonás se resiste a predicarles por temor a que Dios les tuviera compasión y los perdonara si se arrepentían.",
            "1. La misericordia universal de Dios que trasciende barreras nacionales y étnicas.\n2. La futilidad de intentar huir de la presencia y de la vocación divina.\n3. La soberanía de Dios sobre la naturaleza para disciplinar y guiar a sus siervos.",
            "Jonás 2:9",
            "• Rendir nuestra voluntad a los mandatos de Dios sin buscar escapar de su llamado para nuestra vida.\n• Desterrar cualquier prejuicio hacia quienes consideramos lejanos de la gracia de Cristo.\n• Recordar que la salvación es exclusivamente por la soberana gracia y compasión de Dios."
        ),
        (
            33, "Mi", "OT", "Profetas Menores", 18,
            "Los habitantes de Judá y Samaria bajo los reinados de Jotam, Acaz y Ezequías.",
            "c. 735-700 a.C.",
            "Samaria marchaba a su ruina y Judá corría el mismo peligro. Los líderes codiciosos extorsionaban a los campesinos y los falsos profetas prometían paz a cambio de dinero.",
            "1. La denuncia profética contra la corrupción política, judicial y espiritual.\n2. La síntesis de la fe bíblica: hacer justicia, amar la misericordia y humillarse ante Dios.\n3. La gloriosa profecía del origen eterno del Mesías nacido en Belén Efrata (Mi 5:2).",
            "Miqueas 6:8",
            "• Medir nuestra madurez espiritual no por rituales, sino por nuestro trato justo y compasivo hacia otros.\n• Andar humildemente delante del Señor sin vanagloria ni pretensiones humanas.\n• Poner nuestra mirada en Jesús, el Rey eterno nacido en Belén para apacentar a su pueblo."
        ),
        (
            34, "Nah", "OT", "Profetas Menores", 19,
            "La oprimida nación de Judá celebrando la justicia de Dios sobre el opresor asirio.",
            "c. 660-612 a.C.",
            "Nínive había reanudado su política imperial de terror, desollamiento de cautivos y saqueos masivos. Nahúm profetiza la ruina repentina y total de la ciudad por inundaciones y fuego.",
            "1. La santidad y soberanía vengadora de Dios contra los tiranos sanguinarios de la tierra.\n2. La bondad inmutable de Dios como refugio en el día de la angustia para los que confían en Él.\n3. El consuelo para los justos al ver que la opresión y el mal tienen un límite determinado por Dios.",
            "Nahúm 1:7",
            "• Refugiarnos en el Señor en medio de cualquier aflicción o amenaza externa.\n• Confiar en que ningún opresor ni sistema perverso podrá prevalecer contra la justicia divina.\n• Mantener la paz sabiendo que Dios guarda y conoce a los que en Él confían."
        ),
        (
            35, "Hab", "OT", "Profetas Menores", 20,
            "Los creyentes perplejos ante el aparente triunfo del mal y las crisis históricas.",
            "c. 605 a.C.",
            "Habacuc presencia la decadencia moral en Judá y se asombra al oír que Dios usará a los bárbaros caldeos (babilonios) como instrumento de juicio. Sube a su torre de vigilancia para esperar la respuesta de Dios.",
            "1. El diálogo sincero del creyente con Dios ante los dilemas morales de la historia.\n2. El principio nuclear de la redención: «El justo por su fe vivirá».\n3. El triunfo de la alabanza que se alegra en Dios aun cuando falten todos los recursos materiales.",
            "Habacuc 3:17-18",
            "• Vivir por fe y no por vista, descansando en el carácter inmutable de Dios en medio de la incertidumbre.\n• Aprender a esperar con paciencia los tiempos soberanos de Dios sin caer en el desespero.\n• Cantar con gozo en el Dios de nuestra salvación aunque falten los bienes terrenales."
        ),
        (
            36, "Sof", "OT", "Profetas Menores", 21,
            "Los habitantes de Jerusalén y las naciones vecinas en tiempos del rey Josías.",
            "c. 630 a.C.",
            "A pesar de las intenciones de reforma, en Jerusalén convivían la adoración a Yahvé con el culto a Baal, a Milcom y a las estrellas. Sofonías anuncia una purificación universal.",
            "1. El Día terrible de Jehová que consumirá el pecado y la hipocresía sobre la tierra.\n2. El llamado a la mansedumbre y la justicia antes de que venga la hora de la prueba.\n3. El cántico de regocijo divino: Dios callará de amor y se gozará sobre su pueblo con cánticos.",
            "Sofonías 3:17",
            "• Buscar la mansedumbre y la rectitud para ser guardados en el día de la ira divina.\n• No caer en el letargo espiritual de quienes piensan que Dios no interviene en los asuntos humanos.\n• Descansar en el amor infinito de Dios, quien se regocija con cánticos sobre sus hijos."
        ),
        (
            37, "Ha", "OT", "Profetas Menores", 22,
            "Los repatriados en Jerusalén bajo el gobernador Zorobabel y el sumo sacerdote Josué.",
            "c. 520 a.C.",
            "Tras volver del cautiverio, los judíos comenzaron a edificar el Templo, pero por oposición y egoísmo suspendieron la obra durante 16 años mientras construían lujosas casas artesonadas para sí mismos.",
            "1. La primacía innegociable de la obra de Dios por encima de los intereses personales y materiales.\n2. La esterilidad y frustración económica consecuencia de descuidar la casa de Dios.\n3. La presencia consoladora de Dios: «Yo estoy con vosotros, dice Jehová de los ejércitos».",
            "Hageo 1:4",
            "• Evaluar nuestras prioridades diarias para asegurar que el reino de Dios esté en primer lugar.\n• Consagrar nuestros recursos y talentos al servicio del Señor con generosidad de corazón.\n• Confiar en que Dios se encargará de nuestras necesidades cuando prioricemos su voluntad."
        ),
        (
            38, "Zac", "OT", "Profetas Menores", 23,
            "La frágil comunidad post-exílica en Judá y los creyentes que esperan el Reino Mesiánico.",
            "c. 520-480 a.C.",
            "Compañero de Hageo, Zacarías anima a los constructores del Segundo Templo mostrándoles la gloriosa perspectiva mesiánica que trascendía los modestos cimientos que estaban levantando.",
            "1. La victoria espiritual lograda «no con ejército, ni con fuerza, sino con mi Espíritu».\n2. Las profecías detalladas de la venida del Mesías: como Rey humilde, Pastor herido y Sacerdote supremo.\n3. La restauración final de Jerusalén y la santidad de las naciones adorando al Rey de gloria.",
            "Zacarías 4:6",
            "• No despreciar los comienzos pequeños ni medir el éxito espiritual por parámetros humanos.\n• Depender en cada desafío de la presencia y unción poderosa del Espíritu Santo.\n• Mirar a Cristo, traspasado por nuestros pecados, y aguardar su glorioso advenimiento con esperanza."
        ),
        (
            39, "Mal", "OT", "Profetas Menores", 24,
            "La comunidad judía en tiempos de Nehemías, hundida en el cinismo y la rutina religiosa.",
            "c. 430 a.C.",
            "El Segundo Templo estaba terminado pero los sacrificios se ofrecían con desgano, trayendo animales ciegos y cojos. Los sacerdotes menospreciaban la mesa de Jehová y el pueblo robaba los diezmos.",
            "1. El amor soberano de Dios reclamando una honra sincera de padre y de señor.\n2. La fidelidad al pacto matrimonial y la condena terminante del divorcio egoísta.\n3. El llamado al arrepentimiento financiero y la promesa del Sol de justicia con salvación en sus alas.",
            "Malaquías 3:10",
            "• Ofrecer a Dios siempre lo mejor de nuestras fuerzas, tiempo y talentos, jamás las sobras.\n• Honrar con lealtad y santidad el pacto del matrimonio ante la sociedad contemporánea.\n• Probar la fidelidad generosa de Dios devolviendo los diezmos y ofrendas con gozo de corazón."
        ),

        # --- EVANGELIOS (40-43) ---
        (
            40, "Mt", "NT", "Evangelios", 28,
            "Los lectores judeocristianos y la iglesia universal en busca de entender las raíces de la fe.",
            "c. 60-65 d.C.",
            "El templo de Jerusalén seguía en pie. Mateo demuestra sistemáticamente que Jesús de Nazaret es el Rey prometido del linaje de David mediante el cumplimiento de las profecías del Antiguo Testamento.",
            "1. La persona de Jesús como el Rey Mesiánico e Hijo de David que inaugura el Reino de los Cielos.\n2. El Sermón del Monte como constitución ética y espiritual para los discípulos del Reino.\n3. La Gran Comisión de hacer discípulos a todas las naciones con la promesa: «Yo estoy con vosotros todos los días».",
            "Mateo 28:18-20",
            "• Reconocer la soberanía absoluta de Jesucristo sobre cada área de nuestra vida.\n• Vivir conforme a los valores contraculturales del Sermón del Monte en un mundo secular.\n• Participar activamente en la Gran Comisión compartiendo el Evangelio con palabras y testimonio."
        ),
        (
            41, "Mr", "NT", "Evangelios", 29,
            "Los cristianos gentiles de Roma enfrentando la persecución bajo Nerón.",
            "c. 55-65 d.C.",
            "En la capital imperial de Roma, los creyentes necesitaban un relato vigoroso y dinámico. Marcos presenta a Jesús en acción constante («inmediatamente»), sirviendo y entregando su vida.",
            "1. Jesús como el Siervo sufriente de Yahvé que no vino para ser servido sino para servir.\n2. El poder sobre la enfermedad, los demonios, las tormentas y la muerte.\n3. La teología de la cruz y el llamado radical al discipulado abnegado.",
            "Marcos 10:45",
            "• Seguir a Jesús con prontitud y abnegación, dispuestos a tomar nuestra cruz cada día.\n• Cultivar un espíritu humilde de servicio hacia los demás a ejemplo del Maestro.\n• Confiar en el poder de Jesús para calmar las tormentas y temores de nuestra vida."
        ),
        (
            42, "Lc", "NT", "Evangelios", 30,
            "El ilustre Teófilo y los creyentes de cultura helenística en todo el Imperio Romano.",
            "c. 60-62 d.C.",
            "Lucas, médico e historiador de exquisita formación, investiga con rigor a testigos oculares para presentar la certeza histórica del Evangelio, resaltando la perfecta humanidad de Jesús.",
            "1. Jesús como el Salvador compasivo del mundo: busca y salva a los marginados, pecadores y gentiles.\n2. La importancia de la oración constante y el gozo en el Espíritu Santo.\n3. Las parábolas exclusivas del perdón supremo (el buen samaritano, el hijo pródigo, Zaqueo).",
            "Lucas 19:10",
            "• Mostrar el amor compasivo de Cristo hacia las personas despreciadas o necesitadas de la sociedad.\n• Perseverar en una vida de oración sincera y agradecida en todo tiempo.\n• Celebrar el gozo de la salvación que Dios experimenta cuando un pecador se arrepiente."
        ),
        (
            43, "Jn", "NT", "Evangelios", 31,
            "La iglesia universal y todo lector que busca vida eterna en Cristo Jesús.",
            "c. 85-95 d.C.",
            "Hacia fines del siglo I en Éfeso, surgían corrientes gnósticas que negaban la deidad o la encarnación real de Jesús. Juan selecciona siete señales milagrosas y los discursos del «Yo Soy» para generar fe salvadora.",
            "1. La deidad eterna y preexistente de Jesucristo, el Verbo encarnado de Dios.\n2. Las siete señales milagrosas que demuestran que Jesús es el Cristo, el Hijo de Dios.\n3. La promesa de la vida eterna mediante la fe personal en su Nombre y la presencia del Consolador.",
            "Juan 20:31",
            "• Creer firmemente en Jesucristo como Dios encarnado para tener vida eterna y abundante.\n• Permanecer unidos a la Vid verdadera para dar fruto que glorifique al Padre celestial.\n• Amar a nuestros hermanos en la fe como Cristo nos ha amado, reflejando su luz en el mundo."
        ),

        # --- HISTORIA DE LA IGLESIA (44) ---
        (
            44, "Hch", "NT", "Historia de la Iglesia Primitiva", 30,
            "Teófilo y la iglesia dispersada por el mundo grecorromano.",
            "c. 62-64 d.C.",
            "Cubre tres décadas gloriosas (30-62 d.C.): desde la ascensión de Jesús y Pentecostés en Jerusalén hasta el encarcelamiento de Pablo en Roma, narrando la expansión imparable del Evangelio guiada por el Espíritu.",
            "1. El descenso y bautismo del Espíritu Santo empoderando a la iglesia para el testimonio global.\n2. La marcha victoriosa del Evangelio desde Jerusalén, Judea, Samaria hasta lo último de la tierra.\n3. La proclamación valiente del Reino ante persecuciones, sínodos y cortes imperiales.",
            "Hechos 1:8",
            "• Depender del poder del Espíritu Santo para ser testigos valientes y veraces de Cristo.\n• Participar activamente en la comunión fraterna, la doctrina apostólica y las oraciones de la iglesia.\n• Perseverar en la proclamación del Evangelio sabiendo que la Palabra de Dios no está encadenada."
        ),

        # --- EPÍSTOLAS PAULINAS (45-57) ---
        (
            45, "Ro", "NT", "Epístolas Paulinas", 32,
            "La iglesia de Roma, integrada por creyentes judíos y gentiles.",
            "c. 57 d.C.",
            "Redactada desde Corinto durante su tercer viaje misionero. Pablo prepara su visita a la capital del imperio y sistematiza la más profunda exposición teológica del Evangelio de la gracia de Dios.",
            "1. La pecaminosidad universal de toda la humanidad (gentiles y judíos) sin excusa ante Dios.\n2. La justificación por la fe en Cristo imputada como justicia de Dios aparte de las obras de la Ley.\n3. La vida en el Espíritu, la seguridad de la elección soberana y la consagración como sacrificio vivo.",
            "Romanos 1:16-17",
            "• Vivir con gratitud inconmovible sabiendo que hemos sido justificados únicamente por la gracia mediante la fe.\n• Presentar nuestro cuerpo a Dios como sacrificio vivo, santo y agradable como nuestro culto racional.\n• Fomentar la armonía y el amor mutuo entre hermanos que sostienen distintas opiniones en asuntos no esenciales."
        ),
        (
            46, "1Co", "NT", "Epístolas Paulinas", 32,
            "La iglesia de Dios en Corinto, una metrópoli comercial marcada por el libertinaje.",
            "c. 55 d.C.",
            "Fundada en su segundo viaje, la congregación corintia enfrentaba divisiones partidistas, inmoralidad tolerada, pleitos en cortes paganas y confusión sobre los dones espirituales y la resurrección.",
            "1. La sabiduría de la cruz de Cristo que anula el orgullo intelectual y filosófico humano.\n2. El cuerpo del creyente como templo sagrado del Espíritu Santo.\n3. El amor cristiano (ágape) como camino más excelente y la gloriosa certeza de la resurrección corporal.",
            "1 Corintios 15:58",
            "• Huir de las divisiones y personalismos, reconociendo que solo Cristo fue crucificado por nosotros.\n• Cuidar la pureza moral sabiendo que nuestro cuerpo es morada viva del Espíritu de Dios.\n• Ejercer los dones y talentos espirituales motivados siempre por el amor hacia la edificación común."
        ),
        (
            47, "2Co", "NT", "Epístolas Paulinas", 32,
            "Los creyentes de Corinto y de toda la región de Acaya.",
            "c. 56 d.C.",
            "Falsos apóstoles infiltrados atacaban la autoridad y motivos de Pablo. El apóstol abre su corazón con una vulnerabilidad sin igual, defendiendo la naturaleza del ministerio del Nuevo Pacto.",
            "1. El consuelo de Dios en medio de las tribulaciones más severas para consolar a otros.\n2. El ministerio de reconciliación confiado a vasijas de barro para que la excelencia del poder sea de Dios.\n3. La gracia divina que se perfecciona en la debilidad humana: «Bástate mi gracia».",
            "2 Corintios 12:9",
            "• Descansar en el poder de la gracia de Dios cuando experimentemos debilidad, rechazo o dolor físico.\n• Vivir como embajadores de Cristo, anunciando la reconciliación con Dios en cada esfera de la vida.\n• Ofrendar con alegría y generosidad de corazón sabiendo que Dios ama al dador alegre."
        ),
        (
            48, "Ga", "NT", "Epístolas Paulinas", 32,
            "Las iglesias de Galacia (Antioquía de Pisidia, Iconio, Listra y Derbe).",
            "c. 48-49 d.C.",
            "Maestros judaizantes persuadían a los nuevos conversos gentiles de que para ser salvos debían circuncidarse y guardar la ley mosaica. Pablo escribe con pasión santa defendiendo la libertad del Evangelio.",
            "1. El anatema contra cualquier evangelio diferente que añada obras humanas a la gracia.\n2. La justificación exclusivamente por la fe en Cristo y no por las obras de la Ley.\n3. La libertad cristiana para servir en amor y manifestar el fruto sobrenatural del Espíritu Santo.",
            "Gálatas 2:20",
            "• Rechazar cualquier doctrina legalista que pretenda condicionar la salvación a méritos personales.\n• Andar cotidianamente en el Espíritu para no satisfacer los deseos destructivos de la carne.\n• Manifestar el fruto del Espíritu: amor, gozo, paz, paciencia, benignidad, bondad, fe, mansedumbre y templanza."
        ),
        (
            49, "Ef", "NT", "Epístolas Paulinas", 32,
            "La iglesia de Éfeso y las congregaciones de la provincia romana de Asia.",
            "c. 60-62 d.C.",
            "Escrita desde su primera prisión en Roma. Éfeso era el centro de la magia y del culto a Diana. Pablo eleva la mirada de los creyentes hacia las bendiciones celestiales y la unidad del Cuerpo de Cristo.",
            "1. La elección soberana y las bendiciones espirituales en los lugares celestiales en Cristo.\n2. La salvación únicamente por gracia por medio de la fe para buenas obras preparadas de antemano.\n3. La unidad de la Iglesia derribando la pared intermedia de separación y la armadura completa de Dios.",
            "Efesios 2:8-9",
            "• Alabar a Dios por habernos adoptado y bendecido con toda bendición espiritual en Cristo Jesús.\n• Caminar de manera digna de nuestra vocación santa en el matrimonio, la familia y el trabajo.\n• Vestirnos a diario con toda la armadura de Dios para resistir firmes los embates del enemigo."
        ),
        (
            50, "Fil", "NT", "Epístolas Paulinas", 32,
            "La amada iglesia de Filipos, primera congregación fundada en suelo europeo.",
            "c. 61-62 d.C.",
            "Desde la prisión romana, encadenado a un guardia pretoriano y con riesgo de muerte, Pablo desborda gratitud, afecto y gozo por la ofrenda que los filipenses le enviaron mediante Epafrodito.",
            "1. El gozo cristiano triunfante e independiente de las circunstancias adversas o cadenas terrenales.\n2. El himno de la humillación y exaltación de Cristo (Kénosis, Fil 2:5-11).\n3. El contentamiento y la paz que sobrepasa todo entendimiento: «Todo lo puedo en Cristo que me fortalece».",
            "Filipenses 4:13",
            "• Buscar nuestro gozo en el Señor y no en las circunstancias cambiantes de la vida.\n• Imitar la actitud humilde y sacrificial de Cristo, considerando a los demás como superiores a uno mismo.\n• Llevar toda inquietud a Dios en oración y acción de gracias para disfrutar de su paz inalterable."
        ),
        (
            51, "Col", "NT", "Epístolas Paulinas", 32,
            "La iglesia en Colosas, en el valle del Lico en Frigia.",
            "c. 60-62 d.C.",
            "Epafras visita a Pablo en prisión preocupado por una herejía sincretista que mezclaba filosofía griega, misticismo oriental, culto a los ángeles y legalismo judío.",
            "1. La supremacía absoluta y preeminencia de Cristo sobre toda la creación y sobre la Iglesia.\n2. La plenitud de la Deidad habitando corporalmente en Jesús: en Él estamos completos.\n3. El despojo del viejo hombre y el revestimiento de virtudes celestiales en el hogar y la sociedad.",
            "Colosenses 1:18",
            "• Dar a Cristo la primacía absoluta en nuestros pensamientos, planes, finanzas y relaciones.\n• No dejarnos cautivar por filosofías huecas o modas culturales que diluyan la verdad del Evangelio.\n• Poner la mira en las cosas de arriba, donde está Cristo sentado a la diestra de Dios."
        ),
        (
            52, "1Ts", "NT", "Epístolas Paulinas", 32,
            "La joven iglesia de Tesalónica en Macedonia perseguida por hostigadores locales.",
            "c. 51 d.C.",
            "Una de las primeras cartas de Pablo, enviada desde Corinto tras recibir buenas noticias de Timoteo sobre la firmeza de la fe tesalonicense, respondiendo dudas sobre los creyentes fallecidos antes del regreso de Cristo.",
            "1. La memoria grata del ministerio de Pablo como una nodriza y un padre cariñoso.\n2. El llamado a la santificación moral y a apartarse de la fornicación pagana.\n3. La bienaventurada esperanza del arrebatamiento de la Iglesia y la segunda venida de Cristo.",
            "1 Tesalonicenses 4:16-17",
            "• Consolar nuestro corazón ante la partida de seres queridos en la fe con la esperanza de la resurrección.\n• Santificar nuestra vida en pureza moral sabiendo que Dios nos ha llamado a santidad y no a inmundicia.\n• Vivir alertas como hijos de la luz, orando sin cesar y dando gracias a Dios en toda circunstancia."
        ),
        (
            53, "2Ts", "NT", "Epístolas Paulinas", 32,
            "Los hermanos de Tesalónica confundidos por falsas enseñanzas sobre el fin de los tiempos.",
            "c. 51-52 d.C.",
            "Circulaba una carta apócrifa alegando falsamente que el Día del Señor ya había llegado, lo que generó histeria espiritual y llevó a algunos a dejar de trabajar para vivir como holgazanes.",
            "1. El consuelo en medio de persecuciones severas anunciando la retribución justa de Dios.\n2. La revelación de los acontecimientos previos a la venida de Cristo: la apostasía y el hombre de pecado.\n3. La exhortación a la responsabilidad diaria: «Si alguno no quiere trabajar, tampoco coma».",
            "2 Tesalonicenses 3:3",
            "• No dejarnos alarmar por rumores apocalípticos sensacionalistas ni perder el equilibrio espiritual.\n• Cumplir responsablemente con nuestras tareas laborales y familiares mientras aguardamos al Señor.\n• Confiar en que el Señor es fiel para fortalecernos y guardarnos de todo mal."
        ),
        (
            54, "1Ti", "NT", "Epístolas Paulinas", 32,
            "El joven pastor Timoteo, delegado apostólico en la metrópoli de Éfeso.",
            "c. 63-65 d.C.",
            "Tras ser liberado de su primer arresto romano, Pablo encarga a Timoteo combatir a falsos maestros que enseñaban genealogías interminables y mitos ascéticos en la iglesia de Éfeso.",
            "1. La defensa intransigente de la sana doctrina frente a doctrinas de demonios y fábulas.\n2. Los requisitos éticos y espirituales para obispos (pastores) y diáconos en la casa de Dios.\n3. La piedad con contentamiento como gran ganancia, advirtiendo contra la codicia del dinero.",
            "1 Timoteo 2:5",
            "• Defender y atesorar la sana doctrina bíblica frente a enseñanzas modernas engañosas.\n• Apoyar y orar por los pastores y líderes espirituales que guían con fidelidad la congregación.\n• Cultivar la piedad con contentamiento, huyendo del amor al dinero que desvía a tantos de la fe."
        ),
        (
            55, "2Ti", "NT", "Epístolas Paulinas", 32,
            "Timoteo, su amado hijo espiritual en la fe.",
            "c. 67 d.C.",
            "Último escrito apostólico de Pablo. Encarcelado en la húmeda cárcel Mamertina de Roma bajo Nerón y a las puertas del martirio, redacta su testamento espiritual instando a Timoteo a no avergonzarse del Evangelio.",
            "1. El encargo de predicar la Palabra a tiempo y fuera de tiempo con fidelidad insobornable.\n2. La inspiración divina de toda la Escritura para enseñar, redargüir, corregir e instruir en justicia.\n3. El testimonio triunfal de una vida bien acabada: «He peleado la buena batalla, he acabado la carrera, he guardado la fe».",
            "2 Timoteo 3:16-17",
            "• Permanecer firmes y sin avergonzarnos del testimonio de Cristo ante las presiones sociales.\n• Sumergirnos diariamente en las Sagradas Escrituras para ser equipados para toda buena obra.\n• Correr la carrera de la fe con la mirada puesta en la corona incorruptible de justicia."
        ),
        (
            56, "Tit", "NT", "Epístolas Paulinas", 32,
            "Tito, fiel colaborador de Pablo, comisionado en la isla de Creta.",
            "c. 63-65 d.C.",
            "Los cretenses tenían fama proverbial de mentirosos y perezosos. Pablo deja a Tito para organizar las iglesias recién plantadas, ordenar ancianos piadosos y enseñar la sana doctrina.",
            "1. La ordenación de líderes calificados moral y espiritualmente en cada congregación local.\n2. La teología de la gracia de Dios que nos enseña a renunciar a la impiedad y a los deseos mundanos.\n3. La conducta irreprensible de los creyentes en el hogar y ante las autoridades civiles como adorno del Evangelio.",
            "Tito 2:11-12",
            "• Demostrar la autenticidad de nuestra fe mediante una vida transformada y fructífera en buenas obras.\n• Permitir que la gracia de Dios nos enseñe a decir «no» a las pasiones mundanas y a vivir con templanza.\n• Ser ciudadanos ejemplares que honren a Cristo con una conducta pacífica, honesta y respetuosa."
        ),
        (
            57, "Flm", "NT", "Epístolas Paulinas", 32,
            "Filemón, cristiano pudiente de Colosas, junto con la iglesia que se reunía en su hogar.",
            "c. 60-62 d.C.",
            "Onésimo, esclavo fugitivo de Filemón, había huido a Roma donde conoció a Pablo y se convirtió a Cristo. Pablo envía esta conmovedora carta personal pidiendo a Filemón que reciba a Onésimo no ya como esclavo, sino como hermano amado.",
            "1. El poder del Evangelio para sanar heridas y derribar barreras sociales de opresión.\n2. La intercesión cristiana: Pablo ofrece asumir las deudas de Onésimo («Ponlo a mi cuenta»).\n3. La práctica del perdón genuino y la reconciliación fraterna en el Cuerpo de Cristo.",
            "Filemón 1:17",
            "• Extender un perdón completo y sincero a quienes nos hayan ofendido o defraudado en el pasado.\n• Mirar a todo hermano en la fe con amor fraternal, sin importar su condición social o trasfondo.\n• Actuar como pacificadores e intercesores para restaurar relaciones rotas entre personas."
        ),

        # --- HEBREOS (58) ---
        (
            58, "He", "NT", "Epístola a los Hebreos", 32,
            "Los creyentes judeocristianos tentados a retroceder al judaísmo tradicional para evitar persecución.",
            "c. 64-68 d.C.",
            "El templo de Jerusalén con sus sacrificios seguía operando, atrayendo a los hebreos convertidos que sufrían despojo de sus bienes. El autor demuestra que el Nuevo Pacto supera infinitamente al Antiguo.",
            "1. La superioridad suprema de Cristo sobre ángeles, Moisés, Josué, Aarón y el sacerdocio levítico.\n2. El sacerdocio perfecto y eterno de Cristo según el orden de Melquisedec.\n3. El catálogo inmortal de la fe (He 11) y la exhortación a correr la carrera puestos los ojos en Jesús.",
            "Hebreos 4:14-16",
            "• Acercarnos confiadamente al trono de la gracia para alcanzar misericordia y oportuno socorro.\n• Poner los ojos en Jesús, autor y consumador de nuestra fe, sin mirar atrás en momentos de desánimo.\n• Vivir por la fe que agrada a Dios, creyendo que Él es galardonador de los que le buscan."
        ),

        # --- EPÍSTOLAS GENERALES (59-65) ---
        (
            59, "Stg", "NT", "Epístolas Generales", 33,
            "Las doce tribus de la dispersión: cristianos judíos esparcidos por el Imperio Romano.",
            "c. 45-49 d.C.",
            "Probablemente la primera carta redactada del Nuevo Testamento. Santiago aborda con agudeza profética la inconsistencia de quienes profesaban fe pero discriminaban a los pobres y no controlaban su lengua.",
            "1. La prueba de la fe como generadora de paciencia y madurez espiritual.\n2. La fe viva e indiscutible que se demuestra mediante obras de amor y misericordia («la fe sin obras es muerta»).\n3. El freno indispensable de la lengua y la advertencia contra la amistad con el mundo.",
            "Santiago 1:22",
            "• Ser hacedores de la Palabra y no tan solamente oidores engañándonos a nosotros mismos.\n• Refrenar la lengua diariamente, evitando chismes, quejas o palabras hirientes que destruyen.\n• Atender con amor práctico a huérfanos, viudas y personas en necesidad como adoración pura a Dios."
        ),
        (
            60, "1P", "NT", "Epístolas Generales", 34,
            "Los cristianos expatriados en las provincias de Ponto, Galacia, Capadocia, Asia y Bitinia.",
            "c. 63-64 d.C.",
            "Bajo el ambiente hostil previo a las persecuciones neronianas sistemáticas, los creyentes sufrían acusaciones falsas, burlas y marginación social por rehusar participar en la inmoralidad pagana.",
            "1. La esperanza viva fundamentada en la resurrección de Jesucristo y la herencia incorruptible en los cielos.\n2. El pueblo de Dios como linaje escogido, real sacerdocio y nación santa.\n3. El sufrimiento cristiano por hacer el bien siguiendo las pisadas de Cristo y echando toda ansiedad sobre Él.",
            "1 Pedro 2:9",
            "• Responder con mansedumbre, respeto y testimonio intachable cuando enfrentemos hostilidad por nuestra fe.\n• Recordar nuestra identidad sublime como sacerdotes reales llamados a anunciar las virtudes de Dios.\n• Echar toda nuestra ansiedad sobre el Señor, con la plena convicción de que Él cuida de nosotros."
        ),
        (
            61, "2P", "NT", "Epístolas Generales", 34,
            "La iglesia amenazada internamente por falsos maestros y burladores escépticos.",
            "c. 65-68 d.C.",
            "Consciente de su martirio inminente («sabiendo que en breve debo abandonar el cuerpo»), Pedro advierte contra herejías gnósticas y libertinas que negaban el juicio venidero y la segunda venida de Cristo.",
            "1. La provisión divina que nos ha otorgado todas las cosas que pertenecen a la vida y a la piedad.\n2. La confiabilidad suprema de la palabra profética inspirada por el Espíritu Santo sobre ingeniosas fábulas humanas.\n3. La certeza del Día del Señor y la paciencia de Dios que espera que todos procedan al arrepentimiento.",
            "2 Pedro 3:18",
            "• Crecer continuamente en la gracia y en el conocimiento de nuestro Señor y Salvador Jesucristo.\n• Añadir a nuestra fe virtud, conocimiento, dominio propio, paciencia, piedad y afecto fraternal.\n• Estar apercibidos contra maestros engañosos fundamentándonos en la Palabra inspirada de Dios."
        ),
        (
            62, "1Jn", "NT", "Epístolas Generales", 31,
            "Las iglesias de Asia Menor asediadas por el protognosticismo que negaba la encarnación real de Jesús.",
            "c. 85-95 d.C.",
            "Falsos maestros que abandonaron la comunidad afirmaban tener una iluminación superior, alegando que el cuerpo era malo y que por tanto el pecado en la carne no importaba y Jesús no vino en carne verdadera.",
            "1. La comunión con Dios que es Luz: confesar los pecados para ser limpiados con la sangre de Jesucristo.\n2. Las tres pruebas de la vida cristiana genuina: prueba teológica (fe en Cristo), moral (obediencia) y social (amor fraterno).\n3. La seguridad inquebrantable de la vida eterna: «Estas cosas os he escrito... para que sepáis que tenéis vida eterna».",
            "1 Juan 5:13",
            "• Mantener una comunión constante con Dios confesando con prontitud nuestras faltas ante Él.\n• Amar a nuestros hermanos con hechos y verdad y no solo de palabra o de lengua.\n• Vivir con la plena certidumbre y paz espiritual de que poseemos la vida eterna en Cristo Jesús."
        ),
        (
            63, "2Jn", "NT", "Epístolas Generales", 31,
            "La «señora elegida y a sus hijos» (una congregación local amada y sus miembros).",
            "c. 85-95 d.C.",
            "Misioneros itinerantes recorrían las iglesias. Juan advierte que no todos venían de parte de Dios; algunos eran engañadores que no confesaban que Jesucristo ha venido en carne.",
            "1. El equilibrio perfecto entre andar en la verdad bíblica y amarse unos a otros.\n2. El discernimiento espiritual para no hospedar ni colaborar con quienes niegan la doctrina apostólica de Cristo.\n3. La advertencia contra ir más allá de la revelación de Cristo («extraviarse y no perseverar en la doctrina»).",
            "2 Juan 1:6",
            "• Andar en amor mutuo pero sin rebajar ni comprometer jamás los fundamentos de la verdad bíblica.\n• Ejercer discernimiento espiritual riguroso antes de respaldar o promover ministerios o enseñanzas.\n• Cuidar celosamente la sana doctrina para no perder la recompensa celestial completa."
        ),
        (
            64, "3Jn", "NT", "Epístolas Generales", 31,
            "Gayo, creyente hospitalario y amado líder congregacional.",
            "c. 85-95 d.C.",
            "Contrasta el testimonio de tres hombres: Gayo (hospitalario y fiel), Diótrefes (arrogante y dominador, a quien le gustaba tener el primer lugar y expulsaba a los hermanos) y Demetrio (hombre de buen testimonio ante todos).",
            "1. El gozo del líder espiritual al ver a sus hijos espirituales «andar en la verdad».\n2. La hospitalidad y el apoyo material a los obreros de la fe como colaboradores de la verdad.\n3. La condenación de la arrogancia y del afán de protagonismo que busca controlar la iglesia de Dios.",
            "3 Juan 1:4",
            "• Abrir con gozo nuestro corazón y hogar para apoyar a los siervos de Dios y la obra misionera.\n• Guardarnos de cualquier actitud autoritaria o soberbia que busque robar la gloria debida únicamente a Cristo.\n• Procurar un testimonio de vida intachable y reconocido por todos como el de Demetrio."
        ),
        (
            65, "Jud", "NT", "Epístolas Generales", 35,
            "Los santos llamados, amados en Dios Padre y guardados en Jesucristo.",
            "c. 65-80 d.C.",
            "Hombres impíos se habían infiltrado secretamente en las iglesias, convirtiendo la gracia de Dios en libertinaje moral y negando al único Soberano y Señor Jesucristo.",
            "1. El deber ineludible de «contender ardientemente por la fe que ha sido una vez dada a los santos».\n2. Ejemplos históricos del juicio divino contra la rebelión: Israel en el desierto, ángeles caídos, Sodoma y Coré.\n3. La sublime doxología a Aquel que es poderoso para guardarnos sin caída y presentarnos sin mancha con gran alegría.",
            "Judas 1:24-25",
            "• Defender con amor pero con firmeza inquebrantable las verdades fundamentales del Evangelio de Cristo.\n• Edificarnos sobre nuestra santísima fe, orando en el Espíritu Santo y conservándonos en el amor de Dios.\n• Descansar en el poder del Señor Jesús, quien nos guarda de tropezar y nos sostiene hasta el final."
        ),

        # --- PROFECÍA APOCALÍPTICA (66) ---
        (
            66, "Ap", "NT", "Profecía Apocalíptica", 31,
            "Las siete iglesias de la provincia romana de Asia (Éfeso, Esmirna, Pérgamo, Tiatira, Sardis, Filadelfia, Laodicea) y la Iglesia de todos los tiempos.",
            "c. 95 d.C.",
            "Bajo el feroz emperador romano Domiciano, quien exigía ser adorado como «Señor y Dios», los creyentes enfrentaban persecución, martirio y la seducción de contemporizar con la sociedad pagana. Juan, desterrado en Patmos, recibe la revelación consumada.",
            "1. La majestad triunfante de Jesucristo como el Cordero inmolado, el León de Judá y el Rey de reyes.\n2. El juicio soberano de Dios que derrotará definitivamente a Satanás, a la bestia, a la muerte y al pecado.\n3. La Nueva Jerusalén, el descenso del tabernáculo de Dios con los hombres y la renovación cósmica: «¡Sí, ven, Señor Jesús!»",
            "Apocalipsis 21:3-4",
            "• Perseverar en fidelidad a Cristo frente a cualquier presión o persecución social, sabiendo que la victoria final es de nuestro Dios.\n• Consolar nuestro corazón en los momentos de pérdida sabiendo que Dios enjugará toda lágrima y que el dolor pasará.\n• Vivir con una viva expectativa de la segunda venida de Jesús, purificándonos y anhelando su regreso."
        )
    ]

    cur.executemany("""
    INSERT INTO book_summaries (
        book_id, book_code, testament, category, author_id,
        recipients, date_written, historical_context, key_themes, key_verse_ref, practical_application
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, summaries_data)

    conn.commit()

    # Validaciones rigurosas
    cur.execute("SELECT count(*) FROM biblical_authors")
    n_authors = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM book_summaries")
    n_summaries = cur.fetchone()[0]
    print(f"[EXITO] Autores insertados: {n_authors}")
    print(f"[EXITO] Fichas de libros insertadas: {n_summaries}")

    # Verificar integridad referencial
    cur.execute("""
    SELECT s.book_id, s.book_code, b.name, a.name_es, s.key_verse_ref
    FROM book_summaries s
    JOIN books b ON b.rowid = s.book_id
    JOIN biblical_authors a ON a.author_id = s.author_id
    ORDER BY s.book_id LIMIT 5
    """)
    rows = cur.fetchall()
    print("[MUESTRA 5 PRIMEROS LIBROS]:")
    for r in rows:
        print(f"  #{r[0]} [{r[1]}] {r[2]} -> Autor: {r[3]} (Versículo clave: {r[4]})")

    cur.execute("""
    SELECT s.book_id, s.book_code, b.name, a.name_es, s.key_verse_ref
    FROM book_summaries s
    JOIN books b ON b.rowid = s.book_id
    JOIN biblical_authors a ON a.author_id = s.author_id
    WHERE s.book_id IN (40, 44, 45, 66)
    """)
    rows_nt = cur.fetchall()
    print("[MUESTRA NUEVO TESTAMENTO]:")
    for r in rows_nt:
        print(f"  #{r[0]} [{r[1]}] {r[2]} -> Autor: {r[3]} (Versículo clave: {r[4]})")

    conn.close()
    print("[FIN] Base de datos enriquecida y verificada con éxito.")

if __name__ == "__main__":
    main()
