# Atelier "Introduction à la géomatique" - Exercices de manipulation 
tous ces exercices ont pour fonction d'appliquer pratiquement les principes généraux de la géomatique présentés dans l'atelier "Introduction à la géomatique" de manière théorique. Ces exercices se feront avec le logiciel de SIG Libre Quantum GIS (QGIS), version 3.16(.7). 

Lien vers le téléchargement de QGIS : <https://qgis.org/fr/site/forusers/download.html> : Choisir "Installeurs autonomes pour les progiciels OSGeo4W" (Windows) ou "Paquetages officiels authentifiés tout-en-un" (Mac), puis Version long terme (la plus stable).

<div style="text-align:center"><img src="images/Capture_exo_telechargement.PNG" width="1536" alt="Capture d'écran pour le téléchargement de QGIS 3.16.7 pour Windows"/></div>
	
## Exercice de manipulation 1 : Système de coordonnées de référence (SCR) dans le logiciel de SIG QGIS

### Ouvrir QGIS

### Ouvrir des données géographiques dans QGIS

Télécharger des données depuis deux sites institutionnels et un site académique :

* Télécharger les départements GEOFLA de 2016 depuis le site de l'IGN : Pour information, lien vers la page de téléchargement de toutes les données libres de l'IGN : <https://geoservices.ign.fr/documentation/diffusion/telechargement-donnees-libres.html> ***Lien vers le téléchargement des départements de France métropolitaine, 2016 : <ftp://Admin_Express_ext:Dahnoh0eigheeFok@ftp3.ign.fr/GEOFLA_2-2_DEPARTEMENT_SHP_LAMB93_FXX_2016-06-28.7z>***
* Télécharger les contours des pays du monde depuis la GADM (Database of Global Administrative Areas) mis à disposition par le département de biogéographie de l'Université de Californie à Berkeley. : Pour information, lien vers la page de téléchargement des données à l'échelle mondiale : <https://www.gadm.org/download_world.html>. ***Lien vers le téléchargement des données : <https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_shp.zip>***
* Télécharger les contours des états états-uniens depuis le site du United States Census Bureau: Pour information, lien vers la page de téléchargement des données géographiques de limites administratives étatsuniennes: <https://www.census.gov/geographies/mapping-files/time-series/geo/carto-boundary-file.html> ***Lien vers le téléchargement des données géographiques des états, 2018 : <https://www2.census.gov/geo/tiger/GENZ2018/shp/cb_2018_us_state_20m.zip>***

Extraire les fichiers téléchargés des dossiers compressés. Les mettre dans un dossier consacré aux exercices du TP.

Charger dans QGIS les données dans cet ordre, comme indiqué sur l'image ci-dessous :
*la couche de données gadm36_0 du GADM dans QGIS ;
*puis celle du United States Census Bureau (dites Ok à la fenêtre qui s'ouvre, nous y reviendront); 
*puis la couche DEPARTEMENT de l'IGN (chemin vers les données à partir du dossier extrait : GEOFLA_2-2_DEPARTEMENT_SHP_LAMB93_FXX_2016-06-28\GEOFLA\1_DONNEES_LIVRAISON_2021-02-00129\GEOFLA_2-2_SHP_LAMB93_FR-ED161\DEPARTEMENT). 
![Capture d'écran pour l'intégration de couche dans le logiciel de SIG QGIS](images/capture_gestionnaire_de_couche.png "Capture d'écran pour l'intégration de couche dans le logiciel de SIG QGIS")

***Remarque : pour ouvrir ces couches de données, il faut sélectionner à partir du gestionnaire des sources de données les fichiers avec l'extension .shp. Nous y reviendront.***

***Point sur l'interface d'un SIG :

![Capture d'écran de l'interface du logiciel de SIG QGIS](images/capture_interface_SIG.png "Capture d'écran de l'interface du logiciel de SIG QGIS")***

Rouvrez un projet vide puis charger de nouveau les données, mais cette fois dans l'ordre inverse : que constatez-vous ? A votre avis pourquoi ?

### Repérer le SCR des couches / du projet

Pour comprendre ce phénomène, nous allons explorer les SCR associés aux différentes couches de données et celles associées au projet QGIS. 
Dans un logiciel de SIG, il y a deux niveaux où est défini le SCR : 

* au niveau du projet :

```Projet (menu supérieur) > Propriété du Projet... > SCR```

Quel est le SCR du projet ?

Ce SCR se règle sur le SCR de la première couche importée dans le projet. C'est celui qui prime dans la visualisation des couches dans la fenêtre de visualisation.  

* au niveau de la couche de données :

```clic droit sur la couche dans la fenêtre de gestion des couches > Propriétés > Source```

Que constatez-vous? 

### Changer le SCR du projet
		
Il est possible de changer le SCR au niveau du projet en sélectionnant un autre SCR dans ses propriétés, en allant dans :

```Projet > Propriétés... > SCR.```

Changer le SCR du projet pour le mettre en WGS84.

### Changer le SCR des couches
		
#### Reprojeter à la volée

Dans les propriétés d'une couche, auxquelles on accède par un clic droit sur la couche dans la fenêtre de gestion des couches, il est possible de reprojeter "à la volée" chaque couche. 

```Clic droit sur la couche dans la fenêtre de gestion des couches > Propriétés > Sources.```

***Attention !! reprojecter à la volée n'est pas changer le SCR de la couche de manière pérenne ! Cela peut convenir pour voir les données au même endroit dans la fenêtre de visualisation de QGIS mais cela peut provoquer des erreurs de calcul au moment des traitements ==> il faut donc toujours mieux travailler avec des couches de données avec le même SCR enregistré.***

#### Changer le SCR d'une couche de données de manière pérenne

Pour cela il va falloir ré-enregistrer ces données dans un nouveau fichier, avec le nouveau SCR voulu. On voit à quel point le SCR de données géographiques est profondement lié aux données elles-mêmes.
Enregistrer les départements français en WGS84 en suivant ces étapes : 

```Menu supérieur > vecteur > Outils de gestion de données > Reprojeter une couche > choix de la couche à reprojeter (DEPARTEMENT) / choix du nouveau SCR (WGS 84, EPSG 4326) / choix de l'emplacement et du nom du nouveau fichier (DEPARTEMENT_WGS84).```


## Exercice 2 de manipulation : Intégration de données de formats et de sources diverses dans QGIS
	
Créer un nouveau projet.
L'enregistrer sous le nom exo2_structuration_SIG.qgz (attention à bien penser à l'enregistrer régulièrement pendant la manipulation).
Nous allons charger dans QGIS plusieurs couches de données, aux sources, formats et conditions de stockage diverses, pour visualiser des informations géologiques sur la France et plus particulièrement sur le département du Lot. 

### Couche de données vecteur
		
Réimporter la couche de données des départements de l'IGN. Ouvrir de dossier contenant ces données dans l'explorateur de fichier sur Windows ou le finder de Mac pour observer la structure du.des fichier.s. Que constatez-vous ?

Dans QGIS, ouvrir la table attributaire : 

```Clic droit sur la couche > table attributaire```

Pour tester les options de sélection et la liaison entre la table attributaire et les objets tracés dans la fenêtre de visualisation, selectionner le département français le plus à l'ouest sur la carte avec la flèche sélection (pictogramme dans le menu supérieur). Regarder dans la table attributaire, vous le retrouverez surligné en bleu.

Sélectionner ensuite le département du Lot à partir de la table attributaire, en le cherchant par son nom. 
Remarque : en cliquant sur le nom de la colonne dans la table attributaire, vous pouvez classer les lignes par ordre alphabétique ou numérique (selon le type des données). Vous constater que le département du Lot est alors allumé en jaune dans la fenêtre de visualisation.

![Capture d'écran de l'outil sélection d'objets sur la carte](images/Capture_outil_selection_carte_QGIS.png "Capture d'écran de l'outil sélection d'objets sur la carte")

Utiliser l'outil "Zoom sur la sélection" (barre d'outil supérieure) pour centrer la fenêtre de visualisation sur le département du Lot sélectionné.

### Couche de données raster

Télécharger un fichier raster IGN : le Modèle Numérique de Terrain (MNT) du département du Lot. Les MNT sont des données en format raster qui recouvrent toute une surface en modélisant les aspérités, l'altitude du terrain, à partir de données d'altitude mesurées de manière ponctuelle et extrapolées à toute la surface en question à des niveaux différents de précision (ici par cases de 25m).
Lien vers les données MNT du Lot sur la page des données libre de l'IGN, précision 25m : <ftp://BD_ALTI_ext:docoazeecoosh1Ai@ftp3.ign.fr/BDALTIV2_2-0_25M_ASC_LAMB93-IGN69_D046_2019-12-10.7z>
Ouvrir les fichiers MNT recouvrant le Lot dans QGIS via l'onglet Raster du gestionnaire de sources de données et constater ce qu'on peut faire et ne pas faire en allant dans les propriétés des couches raster, en comparaison des couches vecteurs.
Changer la visualisation de ces couches raster en réglant leur type de rendu en mode "ombrage" dans l'onglet "Symbologie" des propriétés de la couche et en réglant leur transparence à 50%.
Remarque : il est possible de copier et coller un style d'une couche à l'autre : 

```clic droit sur la couche dont on veut reproduire le style > Styles > copier le style
Clic droit sur la couche à laquelle on veut appliquer le même style > Styles > coller le style```

### Intégration de données de sources diverses

#### Flux WMS/WFS : 
Pour l'instant, nous avons à chaque fois télécharger en local sur notre ordinateur des fichiers de données, que nous avons ensuite affiché dans le logiciel QGIS. Il est possible d'afficher et de traiter des données dans QGIS de manière distante, en se connectant à une base de données ou à des flux web. Ces flux web peuvent être des Web Map Service (WMS), Web Map Tile Service (WMTS ou Web Tile Service (WTS); ce sont des données en mode raster qui sont utiles pour servir de fond de carte par exemple. Il y a également des Web Feature Service (WFS) pour des données en mode vecteurs, qui sont intérogeables objet par objet, comme une couche vecteur classique.
Nous allons afficher des données à travers des flux WSM dans QGIS : 

```Ouvrir le gestionnaire des sources de données > WMS/WMTS > et créer une nouvelle connexion vers un serveur de données WMS comme montré sur la capture d'écran ci-dessous et validez
> vous pouvez ensuite cliquer sur connexion pour se connecter au server et voir les couches proposées > vous pouvez afficher la carte géologique à l'échelle de la France en sélectionnant comme sur l'image ci-dessous et en cliquant sur "Appliquer"
faites des tests en affichant d'autres données du BRGM
Vous pouvez également aller regarder les ressources de WMS ci-dessous et essayer d'afficher les couches qui vous intéressent. ```

![Capture d'écran du paramétrage de l'outil de gestion des couches pour se connecter au serveur WMS du BRGM](images/Capture_WMS_BRGM.PNG "Capture d'écran du paramétrage de l'outil de gestion des couches pour se connecter au serveur WMS du BRGM")

![Capture d'écran du paramétrage de l'outil de gestion des couches pour afficher la carte géologique à l'échelle de la France](images/Capture_WMS_BRGM2.PNG "Capture d'écran du paramétrage de l'outil de gestion des couches pour afficher la carte géologique à l'échelle de la France")

Ressources pour trouver des flux WMS/WFS : 
* Documentation IGN sur les clés WMS/WFS : <https://geoservices.ign.fr/blog/2017/06/28/geoportail_sans_compte.html> + le tutoriel pour intégrer une couche IGN en flux WMS/WFS/WMTS dans QGIS : <https://geoservices.ign.fr/documentation/utilisation_SIG/QGIS.html> 
* Une liste de ressources pour des flux WMS/WFS : <https://georezo.net/wiki/main/webmapping/webservices>

#### OSM
QGIS offre un accès direct aux données contenues dans la base de données d'OpenStreetMap que vous pouvez charger directement dans votre projet QGIS, en mode vecteur. Pour cela il faut activer une extension spécifique (les extensions sont des options/outils supplémentaires non-activités par defaut) : QuickOSM.

```Extenstions dans le menu supérieur > Installer/gérer les extensions > rechercher QuickOSM > Sélectionner QuickOSM > cliquer sur Installer le plugin
Vous retrouverez le plugin dans Vecteur (menu supérieur) > QuickOSM > QuickOSM```

Paramétrer l'outil QuickOSM comme sur la capture ci-dessous en zoomant sur le département du Lot afin de récupérer le tracé des rivières à partir d'OpenStreet Map (une emprise plus grande entrainerait une requête trop grosse qui ne pourrait aboutir). Puis explorer les possibilités de données offertes par cet outils QuickOSM notamment en allant regarder la documentation sur les clefs OSM (bouton "Aide sur les clefs/valeurs"). Choisissez les objets d'OSM qui vous intéresse à ajouter à votre carte.

![Capture d'écran du paramétrage de l'outil QuickOSM pour afficher les rivières principales](images/Capture_quickOSM.PNG "Capture d'écran du paramétrage de l'outil QuickOSM pour afficher les rivières principales")

