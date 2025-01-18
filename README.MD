# Gleam

## Compile Client Into Server Priv
```
(cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static)
```

## Run Server
```
(cd server && gleam run)
```
## build and run
```
(cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static) && (cd server && gleam run)
```
## build and run 2
```
(cd client && gleam run -m lustre/dev build --outdir=../server/priv/static) && (cd server && gleam run)
```