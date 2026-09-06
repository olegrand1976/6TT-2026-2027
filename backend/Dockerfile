FROM golang:1.27.1-alpine

WORKDIR /app

# git est requis par `go install` ; wget (busybox) sert au healthcheck Docker.
RUN apk add --no-cache git

# Air : hot reload du code Go a chaque modification dans le bind mount.
RUN go install github.com/air-verse/air@v1.67.4

# Couche de cache des dependances : ne change que si go.mod/go.sum changent.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

EXPOSE 8080

CMD ["air", "-c", ".air.toml"]
