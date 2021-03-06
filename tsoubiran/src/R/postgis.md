---
title: "Utilisation de l'extension PostGIS à partir de R avec le package sf"
author: "Thomas Soubiran"
date: "Juillet 2021"
---
  
PostGIS est une extension spatiale pour le gestionnaire de base de données PostgreSQL. 
Dans ce qui suit, nous allons voir comment exécuter des requêtes spatiales dans PostgreSQL 
à partir de R en utilisant les packages RPostgreSQL et sf.


## ¡¡¡README!!!

Tout ce qui concerne l'administration de PostgreSQL *ne sera pas abordé ici*. 
C'est pourquoi les requêtes SQL seront soumises avec le compte postgres qui le compte administrateur de PostgreSQL. 

Ce qui n'est pas bien.

En effet, un compte administrateur ne devrait servir qu'à des taches…administratives. 
Toutes les autres opérations devraient donc être réalisées par un utilisateur avec des droits limités. 

Les étapes de configuration de PostgreSQL ont toutefois été omises pour faciliter la prise en main.

## Préparation de la base

Avant de commencer, on se positionne dans le bon répertoire :
  
  ``` {r,eval=FALSE}  
##
qtlldir <- "/chemin/vers/le/répertoire/postgis/données/"
##
setwd(qtlldir)
```

### Création de la base de données qtll2021

Pour commencer, il faut d'abord créer la base de données dans PostgreSQL. 
On se connecte à la base, puis on exécute la commande SQL `create database` avec la fonction `dbSendQuery()` 
qui, comme son nom l'indique, envoie des requêtes à RPostgreSQL mais _sans récupérer de résultats_ à la différence 
de la fonction  `dbGetQuery()` qui, on le verra plus loin, récupère le résultat et le transforme en `data.frame`.
Enfin, on se déconnecte.

``` {r,eval=FALSE}  
## Création de la base de données ----
## Chargement de la librairie
library(RPostgreSQL)
## Connexion
pg.postgres.co <- dbConnect(
  PostgreSQL()  
  , host = '127.0.1'
  , user ="postgres"
  , password = postgres.pwd
)
## Création de la base qtll2021
dbSendQuery(pg.postgres.co, "create database qtll2021;")
## Déconnexion
dbDisconnect(pg.postgres.co)
```

Ensuite, on se connecte à la base et on active l'extension postgis :
  
  
  ``` {r,eval=FALSE}  
## Activation de l'extension PostGIS----
## Connexion à la base qtll2021
pg.qtll2021.co <- dbConnect(
  PostgreSQL()  
  , host = '127.0.1'
  , user ="postgres"
  , password = postgres.pwd
  , dbname = "qtll2021"
)
## Activation de l'extension PostGIS
dbSendQuery(pg.qtll2021.co, "create extension postgis;")
```

### Import des données dans RPostgreSQL

Nous sommes maintenant prêt à importer des couches dans la base. 
Dans ce qui suit, nous utiliserons les quatre couches suivantes :
  
* topo2021_mel : limites des communes de la Métropole européenne de Lille (MEL)
* iris2021_mel : Iris de la MEL
* ocsfin09_mel : occupation des sols de la MEL
* etab59       : établissements scolaires du département du Nord


``` {r,eval=FALSE}  
## Import des données dans R ----
##
library(sf)
##
## 
##
couches <- c(
  topo2021_mel = "topo2021.mel" ## limite des communes de la MEL
  , iris2021_mel = "iris2021.mel" ## Iris de la MEL
  , ocsfin09_mel = "ocsfin09.mel" ## occupation des sols de la MEL
  , etab59       = "etab59"       ## établissements scolaires du Nord
)
## Chargement des shapefiles
invisible(mapply(
  function(nm, couche){
    assign(
      nm
      , sf::st_read(
        sprintf("shp/%s.shp", couche)
        , quiet=T
        , options = "ENCODING=WINDOWS-1252"
      )
      , envir = parent.env(environment())
    )
    NULL
  }
  , couches
  , names(couches)
))
```
A ce stade, comme indiqué dans la présentation de lundi, il faudrait harmoniser les noms de colonne entre les différentes couches.

Avant d'envoyer les fonds de carte, il faut les modifier en :

* ajoutant l'EPSG qui est absent des fichier prj, sinon sf va ajouter un nouvel EPSG dans la base qtll2021 que sf ne reconnaîtra pas lors de la récupération des données dans R
* en changeant la chasse des noms de colonne pour éviter les messages affirmant de façon erronée que la colonne sélectionnée n'existe pas
  
``` {r,eval=TRUE}  
##
st_crs(topo2021.mel)$input <- "EPSG:2154"
colnames(topo2021.mel) <- tolower(colnames(topo2021.mel))
##
st_crs(iris2021.mel)$input <- "EPSG:2154"
colnames(iris2021.mel) <- tolower(colnames(iris2021.mel))
##
st_crs(ocsfin09.mel)$input <- "EPSG:2154"
colnames(ocsfin09.mel) <- tolower(colnames(ocsfin09.mel))
##
st_crs(etab59)$input <- "EPSG:2154"
```

Comme son nom l'indique, la fonction `st_write()` permet d'écrire des couches dans différents format mais aussi vers d'autres applications comme RPostgreSQL. 
Il suffit pour ça de lui passer une connexion en argument. L'appel de fonction ne crée toutefois pas d'index spatial, il faut donc rajouter une requête 
SQL pour en créer un.

``` {r,eval=TRUE}  
##
rv <- mapply(
  function(nm, couche){
    st_write( get(nm, envir = parent.env(environment())), pg.qtll2021.co, layer=couche, delete_layer=T )
    rq <- sprintf('create index %s_geoIdx on %s using GIST(geometry);', couche, couche)
    dbSendQuery( pg.qtll2021.co , rq)
  }
  , couches
  , names(couches)
)
```

## Exemples de requêtes spatiales

Tout est maintenant prêt pour soumettre des requêtes spatiales à RPostgreSQL. 

Comme indiqué dans la présentation, les fonctions proposées par PostGIS sont sensiblement les mêmes
que sf et ont généralement le même nom car les deux utilisent les mêmes librairies.

### Voisinage

Commençons par récupérer toutes les communes voisines de Lille avec la fonction `ST_Touches()` :
  
``` {r,eval=TRUE}
##
## Communes voisines de la commune Lille ----
##
##
rq <- "select 
  b.insee_com, b.nom, b.code_post
from topo2021_mel a
, topo2021_mel b
where a.insee_com='59350'
and ST_Touches(a.geometry, b.geometry)
;"
##
lille.nb0 <- dbGetQuery( pg.qtll2021.co , rq)
##
print(lille.nb0)
##
plot(
  st_geometry(topo2021.mel)
  , col = c(NA, grey(.4))[as.integer(topo2021.mel$insee_com %in% lille.nb0$insee_com)+1]
  , border=grey(.75)
)
```
Ce type de requêtes peut-être par exemple pour ensuite calculer des statistiques d'autocorrélation 
spatiales qui nécessite de savoir quels sont les voisins d'un objet.

La même chose pour toutes les communes de la MEL :
  
``` {r,eval=TRUE}
##
## Communes voisines pour toutes les communes de la MEL ----
##
##
rq <- "select 
  a.insee_com as com, a.nom 
, b.insee_com com_nb, b.nom as nom_nb
from topo2021_mel a
, topo2021_mel b
where ST_Touches(a.geometry, b.geometry)
order by a.insee_com, b.insee_com -- tri sur les codes communes
;"
##
mel.nb <- dbGetQuery( pg.qtll2021.co , rq)
##
View(mel.nb)
```

Avec sf :
  
```{r,eval=FALSE}
mel.nblst <- st_touches(iris2021.mel,iris2021.mel)
```

sf retourne une liste avec les indices des communes dans la table de départ alors que RPostgreSQL fournit directement les attributs des communes. 
Il faut donc rajouter une étape pour obtenir le même résultat qu'avec RPostgreSQL.

### Limites de la MEL

Pour la suite, nous allons avoir besoin des limites de la MEL. 
Celles-ci peuvent être crée dans R puis envoyées à RPostgreSQL avec la fonction `st_union()` qui va fusionner tous les polygones en un seul. 
Il est toutefois aussi possible de créer des bases spatiales directement dans RPostgreSQL :

``` {r,eval=FALSE}
##
## Fond de carte des limites de la MEL ----
##
rq <-"create table mel_lim as
select 
    '245900410'                     as epcicode
  , 'Métropole Européenne de Lille' as epcilib
  , ST_Union(geometry)              as geometry
from topo2021_mel
;"
##
rv <- dbSendQuery( pg.qtll2021.co , rq, overwrite=T)
## Indexation
rq <- 'create index mel_lim_gid_seq on mel_lim using GIST(geometry);'
rv <- dbSendQuery( pg.qtll2021.co , rq)

```

``` {r,eval=TRUE}
##
## Récupération des limites
## 
rq <-"select  epcicode, epcilib,  geometry  as lim from mel_lim;"
##
mel.lim.pg <- st_read( pg.qtll2021.co , query=rq)
```

On utilise ici la fonction `st_read()` car elle convertit directement le résultat de la requête en objet sf.

La même chose avec sf :

``` {r,eval=TRUE}
## La même chose avec sf
mel.lim <- st_union(st_geometry(topo2021.mel))
## Comparaison
plot(st_geometry(mel.lim.pg), lwd=4,border=grey(0))
plot(st_geometry(mel.lim),border=grey(.9), add=T)
```

La différence est ici que `st_union()` retourne un objet `sfc` qui ne contient donc aucun attribut.

### Intersection entre les parcelles cultivées et les Iris de la MEL

La requête suivante donne un exemple de jointure spatiale entre deux couches :

* les surfaces cultivées
* le découpage des Iris

pour attribuer les surfaces cultivées à l'Iris dans lequel elles se trouvent.

``` {r,eval=TRUE}
##
## Intersection entre les parcelles cultivées et les Iris de la MEL ----
##
##
##
rq <- "select 
    code_iris, THEME09
  , ST_union(-- agrégation à l'Iris -- 3b.
    ST_Intersection(a.geometry, b.geometry ) -- 3a.
  ) as geom2154
from 
    iris2021_mel a
  , ocsfin09_mel b
where  b.THEME09 in ('CULTURES ANNUELLES', 'MARAICHAGES, SERRES') -- 1.
and ST_intersects(a.geometry, b.geometry) -- 2.
group by code_iris, THEME09
;"
##
ocsfin09.mel.iris <- st_read( pg.qtll2021.co , query=rq)
```

La requête consiste à 

1. sélectionner les polygones de surfaces cultivées de la couche OCS
2. réaliser la jointure spatiale entre la géométrie de la table OCS et celle des Iris
3. et, enfin :
  a. calculer l'intersection entre les polygones de cultures et les Iris correspondants
  b. agréger à l'Iris

L'agrégation permet d'obtenir le résultat à l'Iris. On obtient donc une table avec 306 observations au lieu de 1228, 
soit le nombre total de parcelles cultivées dans la MEL.

``` {r,eval=TRUE}
##
plot(st_geometry(ocsfin09.mel.iris),col="green2",border=NA)
plot(st_geometry(iris2021.mel), lwd=.5, border= grey(.5), add=T)
```


### Intersection entre les parcelles cultivées et les Iris de la MEL et calcul d'aires

La requête suivante ajoute le calcul des aires à la requête précédente et fait le calcul dans deux projections différentes :
  
* Lambert conique conforme qui est la projection de la couche
* Lambert azimutale équivalente

``` {r,eval=TRUE}
##
## Intersection entre les parcelles cultivées et les Iris de la MEL et calcul d'aires ----
##
##
rq <- "select 
  d.code_iris
  , THEME09
  -- calcul des aires 3.
  , ST_Area(d.geometry) as iris_aire -- aire de l'Iris
  , ST_Area(ST_Transform(
    d.geometry, 3035
  )) as iris_aire_laea -- aire de l'Iris projeté en Lambert azitmuthale équivalente
  , ST_Area(c.geometry) as ocs_aire 
  , ST_Area(ST_Transform(
    c.geometry, 3035
  )) as ocs_aire_laea
  --
  , c.geometry
from ( -- même requête que précédemment 1.
  select 
  a.code_iris, THEME09
  , ST_union( 
    ST_Intersection(a.geometry, b.geometry )
  ) as geometry
  from iris2021_mel a, ocsfin09_mel b
  where  b.THEME09 in ('CULTURES ANNUELLES', 'MARAICHAGES, SERRES')
  and ST_intersects(a.geometry, b.geometry)
  group by a.code_iris, THEME09
) c
right join iris2021_mel d -- jointure à droite —on garde tous les Iris même s'ils n'ont pas de surfaces cultivées— 2.
on c.code_iris=d.code_iris
order by d.code_iris, c.THEME09 -- tri
;"
##
ocsfin09.mel.iris.aire <- st_read( pg.qtll2021.co , query=rq)
```

Étapes de la requête :
  
1. la sous-requête c est identique à la précédente
2. on réalise une jointure à droite (voir cours) car tous les Iris n'ont pas de surfaces cultivées
3. calcul des aires

Les requêtes SQL permettent donc de facilement combiner les jointures spatiales avec d'autres type de jointures.

Nous pouvons maintenant calculer les proportions de surfaces cultivées à l'Iris :

``` {r,eval=TRUE}
##
p <- with(
  ocsfin09.mel.iris.aire
  , {
    ocs_aire[is.na(ocs_aire)] <- 0 ## Iris sans cultures
    ocs_aire / iris_aire 
  }
)
##
summary(p)
```

ainsi que la proportion de surfaces cultivées dans la MEL :

```{r,eval=TRUE}
##
with(
  ocsfin09.mel.iris.aire
  , {
    ocs_aire[is.na(ocs_aire)] <- 0
    sum(ocs_aire) / sum(iris_aire )
  }
)

```

et les différences entre les deux projections :

``` {r,eval=TRUE}
summary(
  d <- with( ocsfin09.mel.iris.aire, ocs_aire - ocs_aire_laea)/1000^2
)
with(
  ocsfin09.mel.iris.aire
  , plot( ocs_aire/1000^2, d, pch=20 )
)
##
with(
  ocsfin09.mel.iris.aire
  , {
    ocs_aire_laea[is.na(ocs_aire_laea)] <- 0
    sum(ocs_aire_laea) / sum(iris_aire_laea )
  }
)
```

À cette échelle, les déformations induites par la projection sont donc relativement faibles sans être négligeables.


### Calcul de distance(s) entre les établissements scolaires de la MEL


```{r,eval=TRUE}
##
## Distances entre établissements scolaires ----
##
##
rq <- "with longlat as (-- création d'une table temporaire 1.
select
numero_
, e.geometry
, ST_Transform(-- retour au coordonnées WGS84
               e.geometry
               , 4326 -- WGS84
) as longlat /**/
  from 
etab59 e
, mel_lim m
where ST_Intersects(e.geometry, m.geometry) -- sélection des établissements de la MEL
)select -- calcul des distances 2. 
lll.numero_ as etabno1, llr.numero_ as etabno2
, ST_Distance( lll.geometry, llr.geometry ) as deuclid -- a. 
, ST_Distance( lll.longlat::geography, llr.longlat::geography ) as dlonglat -- b.
, ST_DistanceSpheroid( lll.longlat, llr.longlat, 'SPHEROID[\"WGS 84\", 6378137, 298.25]' ) as dsphere1 -- c.
, ST_DistanceSphere( lll.longlat, llr.longlat ) as dsphere2 -- d.
from --- produit cartésien 
longlat lll
, longlat llr  
-- where lll.numero_< llr.numero_ -- matrice triangulaire supérieure 3. 
order by lll.numero_, llr.numero_ -- ordre lexicographique 4.
;"
##
etab.dist0 <- dbGetQuery( pg.qtll2021.co , rq)
```

Dans cet exemple, on souhaite calculer les distances entre tous les établissements scolaires de la MEL. 
Il nous faut donc générer toutes les paires de coordonnées entre tous les établissements. 
Pour cela, on utilise le produit cartésien vu dans la partie cours (voir aussi le fichier script.R).

On utilise de plus la clause `with` qui crée une table temporaire contenant les établissements de la MEL 
obtenue par intersection avec la couche des établissement avec celle des limites de la MEL. On aurait bien évidemment pu utiliser le code postal de l'établissement 
mais ceci aurait nécessité de générer la liste des codes postaux au préalable.

Comme le calcul des distances nécessite de faire un produit cartésien des établissements à partir d'une table qui n'existe pas, 
la clause `with` permet de ne pas à avoir à répéter deux fois l'étape de sélection des établissements de la MEL.

La seconde étape calcule :

a. distance euclidienne sur la carte
b. distance euclidienne à partir de la longitude et de la latitude sur l'ellipsoïde de référence (WGS84)
c. distance euclidienne à partir de la longitude et de la latitude sur une sphère
d. à peu près la même chose

La fonction `st_distance()` de sf diffère de la fonction `st_distance()` de PostGIS. 
En effet, la première calcule la distance du grand cercle qui est la distance sur la courbature de la sphère XXX
et non la distance linéaire entre deux points.

Comparons les résultats :

```{r,eval=TRUE}
etab.mel <- st_intersection( etab59, mel.lim)
etab.mel <- etab.mel[order(etab.mel$numero_),]
d <- st_distance(x=etab.mel,y=etab.mel)
diff <- as.matrix(etab.dist0[c("deuclid",  "dlonglat", "dsphere1", "dsphere2")]) - c(unclass(d))
summary(diff)
```

La distance sur la carte est donc la plus proche de la distance du grand cercle. Une fois de plus, les déformations sont faibles à cette échelle. 
Les écarts seraient plus importants pour des distances plus longues. 
De façon attendue, les autres calculs sous-estiment eux systématiquement la distance entre les points.

D'autre part, la MEL compte 892 établissements scolaires. On obtient donc une table avec 892^2=795664 observations. Comme la matrice de distances est symétrique 
(sinon, par définition, ce ne serait pas une distance), une solution plus efficace consiste à ne calculer que la partie au dessus (ou en dessous) de la diagonale. 
Pour cela, décommentez la condition 3. On obtient alors une table avec 892*(892-1)/2 = 397386 observations.

On peut transformer le résultat en matrice comme suit :

```{r,eval=FALSE}
## ¡¡¡DÉCOMMENTEZ 3. AVANT!!!
netab <- length( etabno <- sort( unique(c(etab.dist0$etabno1,etab.dist0$etabno2)) ) )
idx <- match(etab.dist0$etabno1, etabno) + ( match(etab.dist0$etabno2, etabno) -1 )*netab
d <- matrix(0.,nrow=netab,ncol=netab)
d[idx] <- etab.dist0$deuclid
d <- d+t(d)
```

Une autre solution consisterait à utiliser une matrice éparse.




