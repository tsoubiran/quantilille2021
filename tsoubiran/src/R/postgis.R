
##
qtlldir <- !!!
##
setwd(qtlldir)

## chargement de la librairie
library(RPostgreSQL)

## décommentez l'une ou l'autre ligne
#postgres.pwd <- "<remplacer-par-votre-mot-de-passe/>"
## OU  lecture du mot de passe depuis la console de R pour ne pas avoir à l'écrire dans le script
#postgres.pwd <- readline()

## Connexion ----
pg.postgres.co <- dbConnect(
  PostgreSQL()  
  , host = '127.0.1'
  , user ="postgres"
  , password = postgres.pwd
)
##
dbSendQuery(pg.postgres.co, "create database qtll2021;")
##
dbDisconnect(pg.postgres.co)

## Connexion
pg.qtll2021.co <- dbConnect(
  PostgreSQL()  
  , host = '127.0.1'
  , user ="postgres"
  , password = postgres.pwd
  , dbname = "qtll2021"
)
##
dbSendQuery(pg.qtll2021.co, "create extension postgis;")


##
library(sf)
##
## Liste des fonds de cartes
##
couches <- c(
    topo2021_mel = "topo2021.mel" ## limite des communes de la MEL
  , iris2021_mel = "iris2021.mel" ## Iris de la MEL
  , ocsfin09_mel = "ocsfin09.mel" ## occupation des sols de la MEL
  , etab59       = "etab59"       ## établissements scolaires du Nord
  , etab_mel     = "etab_mel"     ## établissements scolaires de la MEL
)
##
## importation des fonds de carte ----
##
invisible(mapply(
  function(nm, couche){
    assign(
      sprintf("%s.geo0", nm)
      , st_read(
        sprintf("données/shp/%s.shp", couche)
        , quiet=T
      )
      , envir = parent.env(environment())
    )
    NULL
  }
  , couches
  , names(couches)
))
##
## WTF
##
colnames(topo2021.mel.geo0) <- tolower(colnames(topo2021.mel.geo0))
st_crs(topo2021.mel.geo0)$input <- "EPSG:2154"
rv <- st_write( topo2021.mel.geo0, pg.qtll2021.co, layer="topo2021_mel", delete_layer=T )
##
colnames(iris2021.mel.geo0) <- tolower(colnames(iris2021.mel.geo0))
st_crs(iris2021.mel.geo0)$input <- "EPSG:2154"
rv <- st_write( iris2021.mel.geo0, pg.qtll2021.co, layer="iris2021_mel", delete_layer=T )
##
colnames(ocsfin09.mel.geo0) <- tolower(colnames(ocsfin09.mel.geo0))
st_crs(ocsfin09.mel.geo0)$input <- "EPSG:2154"
rv <- st_write( ocsfin09.mel.geo0, pg.qtll2021.co, layer="ocsfin09_mel", delete_layer=T )
##
st_crs(etab59.geo0)$input <- "EPSG:2154"
rv <- st_write( etab59.geo0, pg.qtll2021.co, layer="etab59", delete_layer=T )


##
## Communes voisines de la commune Lille ----
##
##
rq <- "select 
  b.insee_com, b.nom, b.code_post
from topo2021_mel a
, topo2021_mel b
where a.insee_com='59350'
and ST_touches(a.geometry, b.geometry)
;"
##
lille.nb0 <- dbGetQuery( pg.qtll2021.co , rq)
##
View(lille.nb0)
##
plot(
  st_geometry(topo2021.mel.geo0)
  , col = c(NA, grey(.4))[as.integer(topo2021.mel.geo0$insee_com %in% lille.nb0$insee_com)+1]
  , border=grey(.75)
)

##
## Communes voisines pour toutes les communes de la MEL ----
##
##
rq <- "select 
  a.insee_com as com, a.nom 
, b.insee_com com_nb, b.nom as nom_nb
from topo2021_mel a
, topo2021_mel b
where ST_touches(a.geometry, b.geometry)
order by a.insee_com, b.insee_com
;"
##
mel.nb0 <- dbGetQuery( pg.qtll2021.co , rq)
##
View(mel.nb0)


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
## Création d'un index
rq <- 'create index mel_lim_gid_seq on mel_lim using GIST(geometry);'
##
rv <- dbSendQuery( pg.qtll2021.co , rq)
##
##
rq <-"select epcicode, epcilib,  geometry  as lim from mel_lim;"
##
mel.lim.pg0 <- st_read( pg.qtll2021.co , query=rq)

## La même chose avec sf
topo2021.mel.lim0 <- st_union(st_geometry(topo2021.mel.geo0))
## Comparaison
plot(st_geometry(mel.lim.pg0), lwd=4,border=grey(0))
plot(st_geometry(topo2021.mel.lim0),border=grey(.9), add=T)

##
## intersection OCS59 & Iris::MEL ----
##
##
##
rq <- "select 
code_iris, THEME09
, (ST_union( 
  ST_Intersection(a.geometry, b.geometry ) 
)) as geom2154
from iris2021_mel a, ocsfin09_mel b
where  b.THEME09 in ('CULTURES ANNUELLES', 'MARAICHAGES, SERRES')
and ST_intersects(a.geometry, b.geometry)
group by code_iris, THEME09
;"
##
ocsfin09.mel.iris.geo0 <- st_read( pg.qtll2021.co , query=rq)
##
plot(st_geometry(ocsfin09.mel.iris.geo0),col="green",border=NA)

##
library(tmaptools)
##
library(RColorBrewer)
##
gcolIdx0 <- map_coloring(
  ocsfin09.mel.iris.geo0[
    idx0 <- which(
      ocsfin09.mel.iris.geo0$code_iris!=c("", ocsfin09.mel.iris.geo0$code_iris[-nrow(ocsfin09.mel.iris.geo0)])
    )
    ,]
  , palette=NULL
)
## 
gcol.pal <- brewer.pal(n=max(gcolIdx0), name="Set1")
##
gcolIdx1 <- gcolIdx0[match(ocsfin09.mel.iris.geo0$code_iris, ocsfin09.mel.iris.geo0$code_iris[idx0])]
##
plot(
  st_geometry(ocsfin09.mel.iris.geo0)
  , col=gcol.pal[gcolIdx1]
  , border=NA
  , add=F
)
##
plot(st_geometry(iris2021.mel.geo0), lwd=.5, border= grey(.3), add=T)
plot(st_geometry(topo2021.mel.lim0), lwd = 2, border= grey(.2), add=T )


##
## intersection OCS59 & Iris::MEL + calcul aire ----
##
##
##
rq <- "select 
  d.code_iris
  , THEME09
  , ST_Area(d.geometry) as iris_aire -- aire de l'Iris
  , ST_Area(c.geometry) as ocs_aire
  , c.geometry
from ( -- agrégation + calcul de l'aire pour les surfaces
  select 
  a.code_iris, THEME09
  , ST_union( 
    ST_Intersection(a.geometry, b.geometry ) /*st_buffer(b.geometry,0.0000001)*/
  ) as geometry
  from iris2021_mel a, ocsfin09_mel b
  where  b.THEME09 in ('CULTURES ANNUELLES', 'MARAICHAGES, SERRES')
  and ST_intersects(a.geometry, b.geometry)
  group by a.code_iris, THEME09
) c
right join iris2021_mel d -- jointure à droite —on garde tous les Iris même s'ils n'ont pas de surfaces cultivées—
on c.code_iris=d.code_iris
order by d.code_iris, c.THEME09 -- tri
;"
##
ocsfin09.mel.iris.aire0 <- st_read( pg.qtll2021.co , query=rq)
##
p <- with(
  ocsfin09.mel.iris.aire0
  , {
    ocs_aire[is.na(ocs_aire)] <- 0
    ocs_aire / iris_aire 
  }
)
##
summary(p)
##
with(
  ocsfin09.mel.iris.aire0
  , {
    ocs_aire[is.na(ocs_aire)] <- 0
    sum(ocs_aire) / sum(iris_aire )
  }
)

##
## Distances ----
##
##
rq <- "with  centroid as (
select
  code_iris, insee_com, nom_iris, nom_com
  , ST_Transform(
    ST_Centroid(geometry)  
    , 4326 -- WGS84
  ) as iris_centroid from iris2021_mel
)
select 
    a.code_iris as code_iris1 --, a.nom_com as nom_com1, a.nom_iris as nom_iris1
  , b.code_iris as code_iris2 --, b.nom_com as nom_com2, b.nom_iris as nom_iris1
  , ST_Distance( a.iris_centroid::geography, b.iris_centroid::geography ) as d
from centroid a, centroid b
--where a.insee_com<b.insee_com 
--order by a.code_iris, b.code_iris -- ordre lexicographique
;"
##
iris.dist0 <- dbGetQuery( pg.qtll2021.co , rq)
##
ctrd <- st_centroid(iris2021.mel.geo0) 
distmat <- st_distance(x=ctrd,y=ctrd)
##
m <- matrix(distmat[idx <- match(iris.dist0$code_iris1, ctrd$code_iris) + ( match(iris.dist0$code_iris2, ctrd$code_iris) -1 )*509], nrow=509)
##
n <- 10
distmat[1:n,1:n]
m[1:n,1:n]
##
summary(c(
  iris.dist0$d - m ##
))

##
## Voronoi ----
##
## 
##
rq <- "select
ST_CollectionExtract( 
  ST_VoronoiPolygons( ST_collect(a.geometry ) )
  , 3 
) 
as voronoi -- 
from 
    etab59 a
  , mel_lim b
where ST_intersects(b.geometry, a.geometry)
;"
##
etab.mel.vronoi0 <- st_read( pg.qtll2021.co , query=rq)
##
vor.sf0 <- st_collection_extract(
  st_voronoi(
    x = st_union(
      st_intersection( etab59.geo0, topo2021.mel.lim0)
    )
  )
)
##
plot(etab.mel.vronoi0)
plot(st_geometry(etab.mel.geo0), pch=20, cex=.2, col='red', add=T)
##
plot(vor.sf0)
plot(st_geometry(etab.mel.geo0), pch=20, cex=.2, col='red', add=T)


