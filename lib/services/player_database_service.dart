// lib/services/player_database_service.dart
//
// All WC 2026 squads embedded as static const data.
// No JSON file, no async loading — getAllPlayers() is always ready.
// Call PlayerDatabaseService.init() in main() for the debug print only;
// the data is available immediately without it.

class PlayerDatabaseService {
  static const Map<String, Map<String, List<String>>> _squads = {
    'Germany': {
      'Goalkeepers': ['Manuel Neuer', 'Oliver Baumann', 'Alexander Nübel'],
      'Defenders': ['Antonio Rüdiger', 'Waldemar Anton', 'Jonathan Tah', 'Joshua Kimmich', 'Nico Schlotterbeck', 'Nathaniel Brown', 'David Raum', 'Malick Thiaw'],
      'Midfielders': ['Aleksandar Pavlović', 'Leon Goretzka', 'Jamie Leweling', 'Jamal Musiala', 'Pascal Groß', 'Angelo Stiller', 'Florian Wirtz', 'Leroy Sané', 'Nadiem Amiri', 'Felix Nmecha', 'Lennart Karl'],
      'Forwards': ['Kai Havertz', 'Nick Woltemade', 'Maximilian Beier', 'Deniz Undav'],
    },
    'England': {
      'Goalkeepers': ['Jordan Pickford', 'Dean Henderson', 'James Trafford'],
      'Defenders': ['Ezri Konsa', 'Nico O\'Reilly', 'John Stones', 'Marc Guéhi', 'Valentino Livramento', 'Daniel Burn', 'Reece James', 'Djed Spence', 'Jarell Quansah'],
      'Midfielders': ['Declan Rice', 'Elliot Anderson', 'Jude Bellingham', 'Jordan Henderson', 'Kobbie Mainoo', 'Morgan Rogers', 'Eberechi Eze'],
      'Forwards': ['Bukayo Saka', 'Harry Kane', 'Marcus Rashford', 'Anthony Gordon', 'Oliver Watkins', 'Noni Madueke', 'Ivan Toney'],
    },
    'Austria': {
      'Goalkeepers': ['Alexander Schlager', 'Florian Wiegele', 'Patrick Pentz'],
      'Defenders': ['David Affengruber', 'Kevin Danso', 'Stefan Posch', 'David Alaba', 'Philipp Lienhart', 'Phillip Mwene', 'Marco Friedl', 'Michael Svoboda'],
      'Midfielders': ['Xaver Schlager', 'Nicolas Seiwald', 'Marcel Sabitzer', 'Florian Grillitsch', 'Carney Chukwuemeka', 'Romano Schmid', 'Christoph Baumgartner', 'Konrad Laimer', 'Alexander Prass', 'Paul Wanner', 'Alessandro Schöpf'],
      'Forwards': ['Marko Arnautović', 'Michael Gregoritsch', 'Saša Kalajdžić', 'Patrick Wimmer'],
    },
    'Belgium': {
      'Goalkeepers': ['Thibaut Courtois', 'Senne Lammens', 'Mike Penders'],
      'Defenders': ['Zeno Debast', 'Arthur Theate', 'Brandon Mechele', 'Maxim De Cuyper', 'Thomas Meunier', 'Koni De Winter', 'Joaquin Seys', 'Timothy Castagne', 'Nathan Ngoy'],
      'Midfielders': ['Axel Witsel', 'Kevin De Bruyne', 'Youri Tielemans', 'Diego Moreira', 'Hans Vanaken', 'Alexis Saelemaekers', 'Nicolas Raskin', 'Amadou Onana'],
      'Forwards': ['Romelu Lukaku', 'Leandro Trossard', 'Jérémy Doku', 'Dodi Lukebakio', 'Charles De Ketelaere', 'Matías Fernández-Pardo'],
    },
    'Bosnia & Herzegovina': {
      'Goalkeepers': ['Nikola Vasilj', 'Mladen Jurkas', 'Martin Zlomislić'],
      'Defenders': ['Nihad Mujakić', 'Dennis Hadžikadunic', 'Tarik Muharemović', 'Sead Kolašinac', 'Amar Dedić', 'Nikola Katić', 'Stjepan Radeljić', 'Nidal Čelik'],
      'Midfielders': ['Benjamin Tahirović', 'Armin Gigović', 'Ivan Bašić', 'Ivan Šunjić', 'Amar Memić', 'Amir Hadžiahmetović', 'Dženis Burnić', 'Ermin Mahmić'],
      'Forwards': ['Samed Bazdar', 'Ermedin Demirović', 'Edin Džeko', 'Kerim Alajbegović', 'Esmir Bajraktarević', 'Haris Tabaković', 'Jovo Lukić'],
    },
    'Croatia': {
      'Goalkeepers': ['Dominik Livaković', 'Ivor Pandur', 'Dominik Kotarski'],
      'Defenders': ['Josip Stanišić', 'Marin Pongračić', 'Joško Gvardiol', 'Duje Čaleta-Car', 'Josip Šutalo', 'Kristijan Jakić', 'Luka Vušković', 'Martin Erlić'],
      'Midfielders': ['Nikola Moro', 'Mateo Kovačić', 'Luka Modrić', 'Nikola Vlašić', 'Mario Pašalić', 'Martin Baturina', 'Petar Sučić', 'Toni Fruk', 'Luka Sučić'],
      'Forwards': ['Andrej Kramarić', 'Ante Budimir', 'Ivan Perišić', 'Igor Matanović', 'Marco Pašalić', 'Petar Musa'],
    },
    'Scotland': {
      'Goalkeepers': ['Angus Gunn', 'Liam Kelly', 'Craig Gordon'],
      'Defenders': ['Aaron Hickey', 'Andy Robertson', 'Grant Hanley', 'Kieran Tierney', 'Jack Hendry', 'John Souttar', 'Dominic Hyam', 'Nathan Patterson', 'Anthony Ralston', 'Scott McKenna'],
      'Midfielders': ['Scott McTominay', 'John McGinn', 'Tyler Fletcher', 'Ryan Christie', 'Lewis Ferguson', 'Kenny McLean'],
      'Forwards': ['Lyndon Dykes', 'Che Adams', 'Ross Stewart', 'Ben Gannon-Doak', 'George Hirst', 'Lawrence Shankland', 'Findlay Curtis'],
    },
    'Spain': {
      'Goalkeepers': ['David Raya', 'Joan García', 'Unai Simón'],
      'Defenders': ['Marc Pubill', 'Álex Grimaldo', 'Eric García', 'Marcos Llorente', 'Pedro Porro', 'Aymeric Laporte', 'Pau Cubarsí', 'Marc Cucurella'],
      'Midfielders': ['Mikel Merino', 'Fabián Ruiz', 'Pablo Gavira', 'Álex Baena', 'Rodrigo Hernández', 'Martín Zubimendi', 'Pedro López'],
      'Forwards': ['Ferran Torres', 'Dani Olmo', 'Yeremy Pino', 'Nico Williams', 'Lamine Yamal', 'Mikel Oyarzabal', 'Víctor Muñoz', 'Borja Iglesias'],
    },
    'France': {
      'Goalkeepers': ['Brice Samba', 'Mike Maignan', 'Robin Risser'],
      'Defenders': ['Malo Gusto', 'Lucas Digne', 'Dayot Upamecano', 'Jules Koundé', 'Ibrahima Konaté', 'William Saliba', 'Théo Hernandez', 'Lucas Hernandez', 'Maxence Lacroix'],
      'Midfielders': ['Manu Koné', 'Aurélien Tchouaméni', 'N\'Golo Kanté', 'Adrien Rabiot', 'Warren Zaïre-Emery', 'Rayan Cherki', 'Maghnes Akliouche'],
      'Forwards': ['Ousmane Dembélé', 'Marcus Thuram', 'Kylian Mbappé', 'Michaël Olise', 'Bradley Barcola', 'Désiré Doué', 'Jean-Philippe Mateta'],
    },
    'Norway': {
      'Goalkeepers': ['Ørjan Nyland', 'Sander Tangvik', 'Egil Selvik'],
      'Defenders': ['Kristoffer Ajer', 'Leo Østigård', 'David Wolfe', 'Fredrik Bjørkan', 'Marcus Pedersen', 'Torbjørn Heggem', 'Sondre Langas', 'Henrik Falchener'],
      'Midfielders': ['Morten Thorsby', 'Patrick Berg', 'Sander Berge', 'Martin Ødegaard', 'Fredrik Aursnes', 'Kristian Thorstvedt', 'Thelo Aasgaard', 'Andreas Schjelderup', 'Oscar Bobb', 'Jens Hauge'],
      'Forwards': ['Alexander Sørloth', 'Erling Haaland', 'Jørgen Larsen', 'Antonio Nusa', 'Julian Ryerson'],
    },
    'Netherlands': {
      'Goalkeepers': ['Bart Verbruggen', 'Robin Roefs', 'Mark Flekken'],
      'Defenders': ['Jurriën Timber', 'Virgil van Dijk', 'Nathan Aké', 'Jan-Paul van Hecke', 'Mats Wieffer', 'Micky van de Ven', 'Denzel Dumfries', 'Jorrel Hato'],
      'Midfielders': ['Marten de Roon', 'Justin Kluivert', 'Ryan Gravenberch', 'Tijjani Reijnders', 'Guus Til', 'Teun Koopmeiners', 'Frenkie de Jong', 'Quinten Timber'],
      'Forwards': ['Wout Weghorst', 'Memphis Depay', 'Cody Gakpo', 'Noa Lang', 'Donyell Malen', 'Brian Brobbey', 'Crysencio Summerville'],
    },
    'Portugal': {
      'Goalkeepers': ['Diogo Costa', 'José Sá', 'Rui Silva'],
      'Defenders': ['Nelson Semedo', 'Rúben Dias', 'Tomás Araújo', 'Diogo Dalot', 'Renato Veiga', 'Gonçalo Inácio', 'João Cancelo', 'Samu Costa', 'Nuno Mendes'],
      'Midfielders': ['Matheus Nunes', 'Bruno Fernandes', 'Bernardo Silva', 'João Neves', 'Rúben Neves', 'Vítor Ferreira'],
      'Forwards': ['Cristiano Ronaldo', 'Gonçalo Ramos', 'João Félix', 'Francisco Trincão', 'Rafael Leão', 'Pedro Neto', 'Gonçalo Guedes', 'Francisco Conceição'],
    },
    'Sweden': {
      'Goalkeepers': ['Jacob Zetterström', 'Viktor Johansson', 'Kristoffer Nordfeldt'],
      'Defenders': ['Gustaf Lagerbielke', 'Victor Lindelöf', 'Isak Hien', 'Gabriel Gudmundsson', 'Herman Johansson', 'Daniel Svensson', 'Hjalmar Ekdal', 'Carl Starfelt', 'Eric Smith', 'Alexander Bernhardsson', 'Elliot Stroud'],
      'Midfielders': ['Lucas Bergvall', 'Benjamin Nygren', 'Ken Sema', 'Jesper Karlström', 'Yasin Ayari', 'Mattias Svanberg', 'Besfort Zeneli'],
      'Forwards': ['Alexander Isak', 'Anthony Elanga', 'Viktor Gyökeres', 'Gustaf Nilsson', 'Taha Ali'],
    },
    'Switzerland': {
      'Goalkeepers': ['Gregor Kobel', 'Yvon Mvogo', 'Marvin Keller'],
      'Defenders': ['Miro Muheim', 'Silvan Widmer', 'Nico Elvedi', 'Manuel Akanji', 'Ricardo Rodríguez', 'Eray Cömert', 'Aurèle Amenda', 'Luca Jaquez'],
      'Midfielders': ['Denis Zakaria', 'Remo Freuler', 'Johan Manzambi', 'Granit Xhaka', 'Ardon Jashari', 'Djibril Sow', 'Michel Aebischer', 'Fabian Rieder'],
      'Forwards': ['Breel Embolo', 'Dan Ndoye', 'Christian Fassnacht', 'Rubén Vargas', 'Noah Okafor', 'Zeki Amdouni', 'Cédric Itten'],
    },
    'Czechia': {
      'Goalkeepers': ['Matěj Kovář', 'Jindřich Stánek', 'Lukáš Horníček'],
      'Defenders': ['David Zima', 'Tomáš Holeš', 'Robin Hranáč', 'Vladimír Coufal', 'Štěpán Chaloupek', 'Ladislav Krejčí', 'David Jurásek', 'Jaroslav Zelený', 'David Doudera'],
      'Midfielders': ['Vladimír Darida', 'Lukáš Červ', 'Lukáš Provod', 'Michal Sadílek', 'Tomáš Souček', 'Alexandr Sojka', 'Hugo Šochůrek'],
      'Forwards': ['Adam Hložek', 'Patrik Schick', 'Jan Kuchta', 'Mojmír Chytil', 'Pavel Šulc', 'Tomáš Chorý', 'Denis Višinský'],
    },
    'Turkey': {
      'Goalkeepers': ['Mert Günok', 'Altay Bayındır', 'Uğurcan Çakır'],
      'Defenders': ['Zeki Çelik', 'Merih Demiral', 'Çağlar Söyüncü', 'Eren Elmalı', 'Abdülkerim Bardakçı', 'Ozan Kabak', 'Mert Müldür', 'Ferdi Kadıoğlu', 'Samet Akaydın'],
      'Midfielders': ['Salih Özcan', 'Orkun Kökcü', 'Hakan Çalhanoğlu', 'İsmail Yüksek', 'Kaan Ayhan'],
      'Forwards': ['Kerem Aktürkoğlu', 'Arda Güler', 'Deniz Gül', 'Kenan Yıldız', 'İrfan Kahveci', 'Yunus Akgün', 'Barış Yılmaz', 'Oğuz Aydın', 'Can Uzun'],
    },
    'Argentina': {
      'Goalkeepers': ['Juan Musso', 'Gerónimo Rulli', 'Emiliano Martínez'],
      'Defenders': ['Leonardo Balerdi', 'Nicolás Tagliafico', 'Gonzalo Montiel', 'Lisandro Martínez', 'Cristian Romero', 'Nicolás Otamendi', 'Facundo Medina', 'Nahuel Molina'],
      'Midfielders': ['Leandro Paredes', 'Rodrigo de Paul', 'Valentín Barco', 'Giovani Lo Celso', 'Exequiel Palacios', 'Nicolás González', 'Alexis Mac Allister', 'Enzo Fernández'],
      'Forwards': ['Julián Álvarez', 'Lionel Messi', 'Thiago Almada', 'Giuliano Simeone', 'Nicolás Paz', 'José López', 'Lautaro Martínez'],
    },
    'Brazil': {
      'Goalkeepers': ['Alisson Becker', 'Weverton Caldeira', 'Ederson Moraes'],
      'Defenders': ['Wesley', 'Gabriel Magalhães', 'Marcos Corrêa', 'Alex Sandro', 'Danilo Luiz', 'Bremer', 'Léo Pereira', 'Douglas Santos', 'Roger Ibanez'],
      'Midfielders': ['Carlos Casimiro', 'Bruno Guimarães', 'Fábio Tavares', 'Danilo Santos', 'Lucas Paquetá'],
      'Forwards': ['Vinícius Júnior', 'Matheus Cunha', 'Neymar Santos', 'Raphael Belloli', 'Endrick Sousa', 'Luiz Henrique', 'Gabriel Martinelli', 'Igor Thiago', 'Rayan'],
    },
    'Colombia': {
      'Goalkeepers': ['David Ospina', 'Camilo Vargas', 'Álvaro Montero'],
      'Defenders': ['Daniel Muñoz', 'Jhon Lucumí', 'Santiago Arias', 'Yerry Mina', 'Gustavo Puerta', 'Johan Mojica', 'Willer Ditta', 'Deiver Machado', 'Dávinson Sánchez'],
      'Midfielders': ['Kevin Castaño', 'Richard Ríos', 'Jorge Carrascal', 'James Rodríguez', 'Jhon Arias', 'Juan Portilla', 'Jefferson Lerma', 'Juan Quintero'],
      'Forwards': ['Luis Díaz', 'Jhon Córdoba', 'Juan Hernández', 'Leandro Campaz', 'Luis Suárez', 'Andrés Gómez'],
    },
    'Ecuador': {
      'Goalkeepers': ['Hernán Galíndez', 'Moisés Ramírez', 'Gonzalo Valle'],
      'Defenders': ['Félix Torres', 'Piero Hincapié', 'Joel Ordóñez', 'Willian Pacho', 'Pervis Estupiñán', 'Ángelo Preciado', 'Jackson Porozo', 'Yaimar Medina'],
      'Midfielders': ['Jordy Alcívar', 'Anthony Valencia', 'Kendry Páez', 'Alan Minda', 'Pedro Vite', 'Denil Castillo', 'Alan Franco', 'Moisés Caicedo'],
      'Forwards': ['John Yeboah', 'Kevin Rodríguez', 'Enner Valencia', 'Jordy Caicedo', 'Gonzalo Plata', 'Nilson Angulo', 'Jeremy Arévalo'],
    },
    'Paraguay': {
      'Goalkeepers': ['Roberto Fernández', 'Orlando Gill', 'Gastón Olveira'],
      'Defenders': ['Gustavo Velázquez', 'Omar Alderete', 'Juan Cáceres', 'Fabián Balbuena', 'Junior Alonso', 'José Canale', 'Gustavo Gómez', 'Alexandro Maidana'],
      'Midfielders': ['Ramón Sosa', 'Diego Gómez', 'Miguel Almirón', 'Mauricio', 'Andrés Cubas', 'Damián Bobadilla', 'Braian Ojeda', 'Matías Galarza', 'Gustavo Caballero'],
      'Forwards': ['Antonio Sanabria', 'Alejandro Romero', 'Álex Arce', 'Julio Enciso', 'Gabriel Ávalos', 'Isidro Pitta'],
    },
    'Uruguay': {
      'Goalkeepers': ['Sergio Rochet', 'Santiago Mele', 'Fernando Muslera'],
      'Defenders': ['José Giménez', 'Sebastián Cáceres', 'Ronald Araújo', 'Guillermo Varela', 'Mathías Olivera', 'Matías Viña', 'Santiago Bueno'],
      'Midfielders': ['Manuel Ugarte', 'Rodrigo Bentancur', 'Nicolás de la Cruz', 'Federico Valverde', 'Giorgian de Arrascaeta', 'Agustín Canobbio', 'Emiliano Martínez', 'Maximiliano Araújo', 'Joaquín Piquerez', 'Juan Sanabria', 'Rodrigo Zalazar'],
      'Forwards': ['Darwin Núñez', 'Facundo Pellistri', 'Brian Rodríguez', 'Rodrigo Aguirre', 'Federico Viñas'],
    },
    'Canada': {
      'Goalkeepers': ['Dayne St. Clair', 'Maxime Crépeau', 'Owen Goodman'],
      'Defenders': ['Alistair Johnston', 'Alfie Jones', 'Luc de Fougerolles', 'Joel Waterman', 'Derek Cornelius', 'Moïse Bombito', 'Alphonso Davies', 'Richie Laryea', 'Niko Sigur'],
      'Midfielders': ['Mathieu Choinière', 'Stephen Eustaquio', 'Ismaël Koné', 'Liam Millar', 'Jacob Shaffelburg', 'Jonathan Osorio', 'Nathan Saliba', 'Marcelo Flores'],
      'Forwards': ['Cyle Larin', 'Jonathan David', 'Tani Oluwaseyi', 'Tajon Buchanan', 'Ali Ahmed', 'Promise David'],
    },
    'USA': {
      'Goalkeepers': ['Matt Turner', 'Matt Freese', 'Chris Brady'],
      'Defenders': ['Sergiño Dest', 'Chris Richards', 'Antonee Robinson', 'Auston Trusty', 'Miles Robinson', 'Tim Ream', 'Alex Freeman', 'Max Arfsten', 'Mark McKenzie', 'Joe Scally'],
      'Midfielders': ['Tyler Adams', 'Giovanni Reyna', 'Weston McKennie', 'Sebastian Berhalter', 'Cristian Roldán', 'Malik Tillman'],
      'Forwards': ['Ricardo Pepi', 'Christian Pulisic', 'Brenden Aaronson', 'Haji Wright', 'Folarin Balogun', 'Timothy Weah', 'Alex Zendejas'],
    },
    'Mexico': {
      'Goalkeepers': ['Raúl Rangel', 'Carlos Acevedo', 'Guillermo Ochoa'],
      'Defenders': ['Jorge Sánchez', 'César Montes', 'Edson Álvarez', 'Johan Vásquez', 'Israel Reyes', 'Mateo Chávez', 'Jesús Gallardo'],
      'Midfielders': ['Erik Lira', 'Luis Romo', 'Álvaro Fidalgo', 'Orbelín Piñeda', 'Obed Vargas', 'Gilberto Mora', 'Luis Chávez', 'Brian Gutiérrez'],
      'Forwards': ['Raúl Jiménez', 'Alexis Vega', 'Santiago Giménez', 'Armando González', 'Julián Quiñones', 'César Huerta', 'Guillermo Martínez', 'Roberto Alvarado'],
    },
    'Curaçao': {
      'Goalkeepers': ['Eloy Room', 'Tyrick Bodak', 'Trevor Doornbusch'],
      'Defenders': ['Shurandy Sambo', 'Jurien Gaari', 'Roshon van Eijma', 'Sherel Floranus', 'Armando Obispo', 'Joshua Brenet', 'Riechedly Bazoer', 'Deveron Fonville'],
      'Midfielders': ['Godfried Roemeratoe', 'Juninho Bacuna', 'Livano Comenencia', 'Leandro Bacuna', 'Arjany Martha', 'Tahith Chong', 'Kevin Felida'],
      'Forwards': ['Jürgen Locadia', 'Jeremy Antonisse', 'Sontje Hansen', 'Tyrese Noslin', 'Kenji Gorre', 'Jearl Margaritha', 'Brandley Kuwas', 'Gervane Kastaneer'],
    },
    'Haiti': {
      'Goalkeepers': ['Johny Placide', 'Alexandre Pierre', 'Josué Duverger'],
      'Defenders': ['Carlens Arcus', 'Keeto Thermoncy', 'Ricardo Ade', 'Hannes Delcroix', 'Martin Expérience', 'Markhus Lacroix', 'Jean-Kevin Duverne', 'Wilguens Paugain'],
      'Midfielders': ['Carl Sainte', 'Jean-Ricner Bellegarde', 'Leverton Pierre', 'Danley Jean Jacques', 'Dominique Simon', 'Woodensky Pierre'],
      'Forwards': ['Derrick Etienne', 'Duckens Nazon', 'Louicius Deedson', 'Ruben Providence', 'Lenny Joseph', 'Wilson Isidor', 'Yassin Fortune', 'Frantzdy Pierrot'],
    },
    'Panama': {
      'Goalkeepers': ['Luis Mejía', 'César Samudio', 'Orlando Mosquera'],
      'Defenders': ['César Blackman', 'José Córdoba', 'Fidel Escobar', 'Edgardo Farina', 'Jiovany Ramos', 'Carlos Harvey', 'Eric Davis', 'Andrés Andrade', 'Amir Murillo', 'Roderick Miller', 'Jorge Gutiérrez'],
      'Midfielders': ['Cristian Martínez', 'José Rodríguez', 'Adalberto Carrasquilla', 'Ismael Díaz', 'Edgar Bárcenas', 'Alberto Quintero', 'Aníbal Godoy', 'César Yanis'],
      'Forwards': ['Tomás Rodríguez', 'José Fajardo', 'Cecilio Waterman', 'Azarías Londoño'],
    },
    'South Africa': {
      'Goalkeepers': ['Ronwen Williams', 'Sipho Chaine', 'Ricardo Goss'],
      'Defenders': ['Thabang Matuludi', 'Khulumani Ndamane', 'Aubrey Modiba', 'Mbekezeli Mbokazi', 'Samukelo Kabini', 'Nkosinathi Sibisi', 'Khuliso Mudau', 'Ime Okon', 'Olwethu Makhanya', 'Bradley Cross'],
      'Midfielders': ['Teboho Mokoena', 'Thalente Mbatha', 'Themba Zwane', 'Sphephelo Sithole', 'Jayden Adams'],
      'Forwards': ['Oswin Appollis', 'Tshepang Moremi', 'Lyle Foster', 'Relebohile Mofokeng', 'Thapelo Maseko', 'Iqraam Rayners', 'Evidence Makgopa', 'Kamogelo Sebelebele'],
    },
    'Algeria': {
      'Goalkeepers': ['Melvin Mastil', 'Oussama Benbot', 'Luca Zidane'],
      'Defenders': ['Aïssa Mandi', 'Achraf Abada', 'Mohamed Tougaï', 'Zineddine Belaïd', 'Jaouen Hadjam', 'Rayan Aït-Nouri', 'Rafik Belghali', 'Ramy Bensebaini', 'Samir Chergui'],
      'Midfielders': ['Ramiz Zerrouki', 'Houssem Aouar', 'Fares Chaïbi', 'Hicham Boudaoui', 'Nabil Bentaleb', 'Ibrahim Maza', 'Yassine Titraoui'],
      'Forwards': ['Riyad Mahrez', 'Amine Gouiri', 'Anis Hadj Moussa', 'Nadhir Benbouali', 'Mohamed Amoura', 'Adil Boulbina', 'Fares Ghedjemis'],
    },
    'Cape Verde': {
      'Goalkeepers': ['Vozinha', 'Márcio Rosa', 'CJ Dos Santos'],
      'Defenders': ['Stopira', 'Diney Borges', 'Pico Lopes', 'Logan Costa', 'Sidny Cabral', 'Steven Moreira', 'Wagner Pina', 'Kelvin Pires'],
      'Midfielders': ['Kevin Pina', 'Jovane Cabral', 'João Paulo', 'Jamiro Monteiro', 'Garry Rodrigues', 'Deroy Duarte', 'Laros Duarte', 'Yannick Semedo', 'Willy Semedo', 'Telmo Arcanjo', 'Nuno da Costa', 'Hélio Varela'],
      'Forwards': ['Gilson Benchimol', 'Dailon Livramento', 'Ryan Mendes'],
    },
    'Ivory Coast': {
      'Goalkeepers': ['Yahia Fofana', 'Mohamed Koné', 'Alban Lafont'],
      'Defenders': ['Ousmane Diomandé', 'Ghislain Konan', 'Wilfried Singo', 'Odilon Kossounou', 'Christopher Operi', 'Guela Doué', 'Emmanuel Agbadou', 'Evan Ndicka'],
      'Midfielders': ['Jean Séri', 'Seko Fofana', 'Franck Kessié', 'Ibrahim Sangaré', 'Parfait Guiagon', 'Christ Oulai'],
      'Forwards': ['Ange-Yoan Bonny', 'Simon Adingra', 'Yan Diomandé', 'Elye Wahi', 'Oumar Diakité', 'Amad Diallo', 'Nicolas Pépé', 'Evann Guessand', 'Bazoumana Touré'],
    },
    'Egypt': {
      'Goalkeepers': ['Mohamed Elshenawy', 'Mahdy Soliman', 'Mostafa Shoubir', 'Mohamed Alaa'],
      'Defenders': ['Yasser Ibrahim', 'Mohamed Hany', 'Hossam Abdelmaguid', 'Ramy Rabia', 'Mohamed Abdelmoneim', 'Ahmed Fatouh', 'Karim Hafez', 'Tarek Alaa'],
      'Midfielders': ['Emam Ashour', 'Mostafa Zico', 'Hamdy Fathy', 'Mohanad Lashin', 'Nabil Donga', 'Marawan Attia', 'Mahmoud Saber'],
      'Forwards': ['Mahmoud Hassan', 'Hamza Abdelkarim', 'Mohamed Salah', 'Haissem Hassan', 'Ibrahim Adel', 'Omar Marmoush', 'Mahmoud Hamdy'],
    },
    'Ghana': {
      'Goalkeepers': ['Lawrence Zigi', 'Joseph Anang', 'Benjamin Asare'],
      'Defenders': ['Alidu Seidu', 'Jonas Adjetey', 'Abdul Mumin', 'Gideon Mensah', 'Baba Rahman', 'Jerome Opoku', 'Kojo Oppong', 'Derrick Luckassen', 'Marvin Senaya'],
      'Midfielders': ['Caleb Yirenkyi', 'Thomas Partey', 'Kwasi Sibo', 'Antoine Semenyo', 'Elisha Owusu', 'Augustine Boakye'],
      'Forwards': ['Fatawu Issahaku', 'Jordan Ayew', 'Brandon Thomas-Asante', 'Christopher Baah', 'Iñaki Williams', 'Kamaldeen Sulemana', 'Ernest Nuamah', 'Prince Adu'],
    },
    'Morocco': {
      'Goalkeepers': ['Yassine Bounou', 'Munir El Kajoui', 'Ahmed Tagnaouti'],
      'Defenders': ['Achraf Hakimi', 'Noussair Mazraoui', 'Nayef Aguerd', 'Zakaria El Ouahdi', 'Issa Diop', 'Chadi Riad', 'Youssef Belammari', 'Redouane Halhal', 'Anass Salah-Eddine'],
      'Midfielders': ['Sofyan Amrabat', 'Ayyoub Bouaddi', 'Chemsdine Talbi', 'Azzedine Ounahi', 'Ismaël Saibari', 'Samir El Mourabet', 'Gessime Yassine', 'Bilal El Khannouss', 'Neil El Aynaoui'],
      'Forwards': ['Soufiane Rahimi', 'Brahim Díaz', 'Abde Ezzalzouli', 'Ayoub El Kaabi', 'Ayoub Amaimouni'],
    },
    'DR Congo': {
      'Goalkeepers': ['Lionel Mpasi', 'Timothy Fayulu', 'Matthieu Epolo'],
      'Defenders': ['Aaron Wan-Bissaka', 'Steve Kapuadi', 'Axel Tuanzebe', 'Dylan Batubinsika', 'Joris Kayembe', 'Chancel Mbemba', 'Gédéon Kalulu', 'Arthur Masuaku'],
      'Midfielders': ['Ngalayel Mukau', 'Nathanaël Mbuku', 'Samuel Moutoussamy', 'Théo Bongonda', 'Noah Sadiki', 'Aaron Tshibola', 'Charles Pickel', 'Edo Kayembe'],
      'Forwards': ['Brian Cipenga', 'Gaël Kakuta', 'Meschack Elia', 'Cédric Bakambu', 'Fiston Mayele', 'Yoane Wissa', 'Simon Banza'],
    },
    'Senegal': {
      'Goalkeepers': ['Yehvann Diouf', 'Édouard Mendy', 'Mory Diaw'],
      'Defenders': ['Mamadou Sarr', 'Kalidou Koulibaly', 'Abdoulaye Seck', 'Ismail Jakobs', 'Krepin Diatta', 'Moussa Niakhaté', 'Antoine Mendy', 'El Hadji Diouf'],
      'Midfielders': ['Idrissa Gueye', 'Pathé Ciss', 'Lamine Camara', 'Pape Sarr', 'Habib Diarra', 'Bara Ndiaye', 'Pape Gueye'],
      'Forwards': ['Assane Diao', 'Bamba Dieng', 'Sadio Mané', 'Nicolas Jackson', 'Chérif Ndiaye', 'Iliman Ndiaye', 'Ismaîla Sarr', 'Ibrahim Mbaye'],
    },
    'Tunisia': {
      'Goalkeepers': ['Mouhib Chamakh', 'Aymen Dahmen', 'Sabri Ben Hessen'],
      'Defenders': ['Ali Abdi', 'Montassar Talbi', 'Omar Rekik', 'Adam Arous', 'Dylan Bronn', 'Mortadha Ben Ouanes', 'Yan Valery', 'Mohamed Ben Hmida', 'Moutaz Neffati', 'Raed Chikhaoui'],
      'Midfielders': ['Hannibal Mejbri', 'Ismaël Gharbi', 'Rani Khedira', 'Khalil Ayari', 'Mohamed Hadj Mahmoud', 'Ellyes Skhiri', 'Anis Slimane', 'Sebastian Tounekti'],
      'Forwards': ['Elias Achouri', 'Elias Saad', 'Hazem Mastouri', 'Rayan Elloumi', 'Firas Chaouat'],
    },
    'Saudi Arabia': {
      'Goalkeepers': ['Nawaf Al-Aqidi', 'Mohammed Al-Owais', 'Ahmed Al-Kassar'],
      'Defenders': ['Ali Majrashi', 'Ali Lajami', 'Abdulelah Al-Amri', 'Hassan Al-Tambakti', 'Saud Abdulhamid', 'Nawaf Bu Washl', 'Hassan Kadish', 'Moteb Al-Harbi', 'Jehad Thikri', 'Mohammed Abu Alshamat'],
      'Midfielders': ['Nasser Al-Dawsari', 'Musab Al-Juwayr', 'Abdullah Al-Khaibari', 'Ziyad Al-Johani', 'Ala Al-Hajji', 'Mohamed Kanno'],
      'Forwards': ['Aiman Yahya', 'Feras Al-Brikan', 'Salem Al-Dawsari', 'Saleh Al-Shehri', 'Khalid Al-Ghannam', 'Abdullah Al-Hamddan', 'Sultan Mandash'],
    },
    'Australia': {
      'Goalkeepers': ['Mathew Ryan', 'Paul Izzo', 'Patrick Beach'],
      'Defenders': ['Miloš Degenek', 'Alessandro Circati', 'Jacob Italiano', 'Jordan Bos', 'Jason Geria', 'Kai Trewin', 'Aziz Behich', 'Harry Souttar', 'Cameron Burgess', 'Lucas Herrington'],
      'Midfielders': ['Connor Metcalfe', 'Aiden O\'Neill', 'Cameron Devlin', 'Jackson Irvine', 'Paul Okon-Engstler'],
      'Forwards': ['Mathew Leckie', 'Mohamed Touré', 'Ajdin Hrustić', 'Awer Mabil', 'Nestory Irankunda', 'Cristian Volpato', 'Nishan Velupillay', 'Tete Yengi'],
    },
    'Iraq': {
      'Goalkeepers': ['Fahad Talib', 'Jalal Hassan', 'Ahmed Basil'],
      'Defenders': ['Rebin Ghareeb', 'Hussein Ali', 'Zaid Tahseen', 'Akam Hashim', 'Munaf Younus', 'Ahmed Yahya', 'Merchas Doski', 'Mustafa Saadoon', 'Frans Putros'],
      'Midfielders': ['Youssef Amyn', 'Ibrahim Bayesh', 'Zidane Iqbal', 'Amir Al-Ammari', 'Kevin Yakob', 'Aimar Sher', 'Zaid Ismael'],
      'Forwards': ['Ali Al-Hamadi', 'Mohanad Ali', 'Ahmed Qasim', 'Ali Yousif', 'Ali Jasim', 'Aymen Hussein', 'Marko Farji'],
    },
    'Japan': {
      'Goalkeepers': ['Zion Suzuki', 'Keisuke Osako', 'Tomoki Hayakawa'],
      'Defenders': ['Yukinari Sugawara', 'Shogo Taniguchi', 'Kou Itakura', 'Yuto Nagatomo', 'Tsuyoshi Watanabe', 'Ayumu Seko', 'Hiroki Ito', 'Takehiro Tomiyasu', 'Junnosuke Suzuki'],
      'Midfielders': ['Wataru Endo', 'Ao Tanaka', 'Takefusa Kubo', 'Ritsu Doan', 'Daizen Maeda', 'Keito Nakamura', 'Junya Ito', 'Daichi Kamada', 'Yuito Suzuki', 'Kaishu Sano'],
      'Forwards': ['Keisuke Goto', 'Ayase Ueda', 'Koki Ogawa', 'Kento Shiogai'],
    },
    'Jordan': {
      'Goalkeepers': ['Yazeed Abu Laila', 'Nour Baniateyah', 'Abdallah Al-Fakhori'],
      'Defenders': ['Mohammad Abu Hasheesh', 'Abdallah Nasib', 'Husam Abu Dahab', 'Yazan Al-Arab', 'Mohammad Abu Al-Nadi', 'Saleem Obaid', 'Saed Al-Rosan', 'Ehsan Haddad', 'Anas Badawi'],
      'Midfielders': ['Amer Jamous', 'Noor Al-Rawabdeh', 'Rajaei Ayed', 'Ibrahim Sadeh', 'Mohannad Abu Taha', 'Nizar Al-Rashdan', 'Mohammad Al-Daoud'],
      'Forwards': ['Mohammad Abu Zraiq', 'Ali Olwan', 'Mousa Al-Tamari', 'Odeh Fakhoury', 'Mahmoud Al-Mardi', 'Ibrahim Sabra', 'Ali Azaizeh'],
    },
    'Uzbekistan': {
      'Goalkeepers': ['Utkir Yusupov', 'Abduvohid Nematov', 'Botirali Ergashev'],
      'Defenders': ['Abdukodir Khusanov', 'Khojiakbar Alijonov', 'Farrukh Sayfiev', 'Rustam Ashurmatov', 'Sherzod Nasrullaev', 'Umar Eshmurodov', 'Abdulla Abdullaev', 'Behruzjon Karimov', 'Avazbek Ulmasaliyev', 'Jakhongir Urozov'],
      'Midfielders': ['Akmal Mozgovoy', 'Otabek Shukurov', 'Jamshid Iskanderov', 'Odiljon Xamrobekov', 'Jaloliddin Masharipov', 'Oston Urunov', 'Dostonbek Khamdamov', 'Azizjon Ganiev', 'Abbosbek Fayzullaev', 'Sherzod Esanov'],
      'Forwards': ['Eldor Shomurodov', 'Azizbek Amonov', 'Igor Sergeev'],
    },
    'Qatar': {
      'Goalkeepers': ['Mahmoud Abu Nada', 'Salah Zakaria', 'Meshaal Barsham'],
      'Defenders': ['Pedro Miguel', 'Lucas Mendes', 'Issa Laye', 'Jassem Gaber', 'Ayoub Aloui', 'Homam Ahmed', 'Boualem Khoukhi', 'Sultan Al-Brake', 'Al-Hashmi Al-Hussein'],
      'Midfielders': ['Abdulaziz Hatem', 'Karim Boudiaf', 'Ahmed Al-Ganehi', 'Ahmed Fathy', 'Assim Madibo'],
      'Forwards': ['Ahmed Alaaeldin', 'Edmilson Júnior', 'Mohammed Muntari', 'Hassan Al-Haydos', 'Akram Afif', 'Yusuf Abdurisag', 'Almoez Ali', 'Tahsin Jamshid', 'Mohamed Manai'],
    },
    'South Korea': {
      'Goalkeepers': ['Seunggyu Kim', 'Bumkeun Song', 'Hyeonwoo Jo'],
      'Defenders': ['Hanbeom Lee', 'Minjae Kim', 'Taehyeon Kim', 'Taeseok Lee', 'Wije Cho', 'Moonhwan Kim', 'Jinseob Park', 'Youngwoo Seol', 'Jens Castrop'],
      'Midfielders': ['Gihyuk Lee', 'Inbeom Hwang', 'Seungho Paik', 'Jaesung Lee', 'Heechan Hwang', 'Junho Bae', 'Kangin Lee', 'Hyunjun Yang', 'Jingyu Kim', 'Jisung Eom', 'Donggyeong Lee'],
      'Forwards': ['Heungmin Son', 'Guesung Cho', 'Hyeongyu Oh'],
    },
    'Iran': {
      'Goalkeepers': ['Alireza Beiranvand', 'Payam Niazmand', 'Hossein Hosseini'],
      'Defenders': ['Saleh Hardani', 'Ehsan Hajisafi', 'Shoja Khalilzadeh', 'Milad Mohammadi', 'Hossein Kanani', 'Arya Yousefi', 'Ali Nemati', 'Ramin Rezaeian', 'Danial Iri'],
      'Midfielders': ['Saeid Ezatolahi', 'Alireza Jahanbakhsh', 'Mohammad Mohebbi', 'Saman Ghoddos', 'Roozbeh Cheshmi', 'Mehdi Torabi', 'Mohammad Ghorbani', 'Amirmohammad Razaghinia'],
      'Forwards': ['Mehdi Taremi', 'Mehdi Ghayedi', 'Ali Alipour', 'Amirhossein Hosseinzadeh', 'Shahriyar Moghanloo', 'Dennis Dargahi'],
    },
    'New Zealand': {
      'Goalkeepers': ['Max Crocombe', 'Alex Paulsen', 'Michael Woud'],
      'Defenders': ['Tim Payne', 'Francis de Vries', 'Tyler Bindon', 'Michael Boxall', 'Liberato Cacace', 'Nando Pijnaker', 'Finn Surman', 'Callan Elliot', 'Tommy Smith'],
      'Midfielders': ['Joe Bell', 'Matthew Garbett', 'Marko Stamenić', 'Sarpreet Singh', 'Elijah Just', 'Alex Rufer', 'Ben Old', 'Callum McCowatt', 'Ryan Thomas', 'Lachlan Bayliss'],
      'Forwards': ['Chris Wood', 'Kosta Barbarouses', 'Ben Waine', 'Jesse Randall'],
    },
  };

  // ─── Cached flat list (built once on first call) ────────────────────────────

  static List<String>? _allPlayers;
  static Map<String, List<String>>? _teamPlayerMap;

  /// Flat sorted list of every player across all squads.
  /// Synchronous and always ready — no await needed.
  static List<String> getAllPlayers() {
    if (_allPlayers != null) return _allPlayers!;
    final players = <String>[];
    for (final positions in _squads.values) {
      for (final group in positions.values) {
        players.addAll(group);
      }
    }
    players.sort();
    _allPlayers = players;
    return _allPlayers!;
  }

  /// Players for a specific country name (as keyed above, e.g. 'France').
  static List<String> getPlayersForTeam(String teamName) {
    _teamPlayerMap ??= {
      for (final entry in _squads.entries)
        entry.key: entry.value.values.expand((g) => g).toList(),
    };
    return _teamPlayerMap![teamName] ?? [];
  }

  /// Position of a player within a squad ('Goalkeepers', 'Defenders', etc.).
  static String? getPlayerPosition(String teamName, String playerName) {
    final positions = _squads[teamName];
    if (positions == null) return null;
    for (final entry in positions.entries) {
      if (entry.value.contains(playerName)) return entry.key;
    }
    return null;
  }

  /// Finds the country code/name associated with a specific player.
  static String? getTeamForPlayer(String playerName) {
    final target = normalize(playerName);
    for (final entry in _squads.entries) {
      for (final group in entry.value.values) {
        for (final player in group) {
          if (normalize(player) == target) {
            return entry.key;
          }
        }
      }
    }
    return null;
  }

  /// Advanced Fuzzy Match — Handles initials, inverted names (Asian conventions), and hyphenations.
  /// E.g., API 'I.B. Hwang' will flawlessly match DB 'Hwang In-beom'.
  static String? getBestMatchingName(String teamName, String inputName) {
    if (inputName.isEmpty) return null;
    final players = getPlayersForTeam(teamName);
    if (players.isEmpty) return null;

    final normInput = normalize(inputName).toLowerCase();
    final inputTokens = normInput.split(RegExp(r'[\s\.\-]+')).where((t) => t.isNotEmpty).toList();

    String? bestPlayer;
    int bestScore = -1;

    for (final player in players) {
      final normPlayer = normalize(player).toLowerCase();
      final playerTokens = normPlayer.split(RegExp(r'[\s\.\-]+')).where((t) => t.isNotEmpty).toList();

      int score = 0;
      
      // 1. Flat quick match (e.g. "Jovo Lukić" == "Jovo Lukić")
      final flatInput = normInput.replaceAll(RegExp(r'[^a-z]'), '');
      final flatPlayer = normPlayer.replaceAll(RegExp(r'[^a-z]'), '');
      if (flatInput == flatPlayer) return player;
      
      if (flatPlayer.contains(flatInput) || flatInput.contains(flatPlayer)) {
        score += 30; // Base score for partial flat match
      }

      // 2. Token scoring strategy
      Set<int> usedDbIndices = {};
      for (final iToken in inputTokens) {
        int bestTokenScore = 0;
        int? bestMatchedIndex;

        for (int j = 0; j < playerTokens.length; j++) {
          if (usedDbIndices.contains(j)) continue;
          final pToken = playerTokens[j];

          if (iToken.length == 1) {
            // Initial match (e.g. 'i' matches 'in')
            if (pToken.startsWith(iToken)) {
              if (10 > bestTokenScore) {
                bestTokenScore = 10;
                bestMatchedIndex = j;
              }
            }
          } else {
            // Word match
            if (pToken == iToken) {
              bestTokenScore = 100;
              bestMatchedIndex = j;
              break; // Max score, stop searching for this token
            } else if (pToken.contains(iToken) || iToken.contains(pToken)) {
              if (50 > bestTokenScore) {
                bestTokenScore = 50;
                bestMatchedIndex = j;
              }
            }
          }
        }
        score += bestTokenScore;
        if (bestMatchedIndex != null) usedDbIndices.add(bestMatchedIndex);
      }

      if (score > bestScore) {
        bestScore = score;
        bestPlayer = player;
      }
    }

    // Require a minimum confidence score to avoid absurd false positives
    // 10 = one initial (e.g. "M. Silva" vs "Martinez"), 50 = partial word, 100 = exact word.
    if (bestScore >= 10) {
      return bestPlayer;
    }
    return null;
  }

  /// Optional: call in main() for the startup log line. Data is usable without it.
  static void init() {
    final players = getAllPlayers();
    // ignore: avoid_print
    print('PlayerDatabaseService: ${players.length} players across ${_squads.length} teams — ready.');
  }

  /// Strips diacritics for accent-insensitive matching (e.g. "Vinícius" -> "vinicius").
  static String normalize(String input) {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ';
    const plain   = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUCN';
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      final idx = accents.indexOf(char);
      buffer.write(idx != -1 ? plain[idx].toLowerCase() : char);
    }
    return buffer.toString();
  }

  /// Returns the canonical (correctly accented) player name matching
  /// the input, ignoring case and diacritics. Null if no match.
  static String? findCanonicalName(String input) {
    final target = normalize(input);
    for (final player in getAllPlayers()) {
      if (normalize(player) == target) return player;
    }
    return null;
  }

  static Future<void> loadPlayers() async {}

}
