##
commune2021 <- read.table(
  ##
  paste(
    "données/csv"
    , "commune2021.csv"
    , sep="/"
  )
  , sep = ","
  , header = T
  , quote = ''
  , stringsAsFactors = F
)
##
h <- function(x, sz, init=5381, M=33){
  m <- 2^31 - 1
  h = init
  for( l in as.integer(charToRaw(x)) ){
    # cat(l,  "\n")
    h <- ( (M * h)%%m  + l )%%m
    # cat(h,"\n")
  }
  as.integer(h %% sz)+1L
}
##
hcom <- sapply(commune2021$LIBELLE, function(x)h(x, 37742, 0, 31))
##
table(table(hcom))
##
hcom <- sapply(commune2021$LIBELLE, function(x)h(x, 37742*2, 0, 31))
##
table(table(hcom))
##
match("01001" , commune2021$COM)

##
x <- data.frame(oid=1:6,lib='A')
##
y <- data.frame(oid=4:8,lib='B')
## toutes les clefs (univers)
union(x$oid,y$oid)
## clefs en commun
intersect(x$oid,y$oid)
## différence
setdiff(x$oid,y$oid)
setdiff(y$oid,x$oid)
## différence symétrique
symdiff <- function( x, y){
  union(setdiff(x, y), setdiff( y, x))
  ## ou : setdiff( union(x, y), intersect(x, y))
}
symdiff(y$oid,x$oid)
## join
merge(x,y, by='oid')
## left join
merge(x,y, by='oid', all.x = T)
## right join
merge(x,y, by='oid', all.y = T)
## full outer join
merge(x,y, by='oid', all = T)
## produit cartésien
expand.grid(x$oid,y$oid)

