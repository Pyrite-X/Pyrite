# Dockerfile that builds both the gateway and the HTTP server executables
# into one image. Each can be triggered independently by overriding the command
# for the container to either ./pyrite_http or ./pyrite_gateway

# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
ENV PUB_CACHE=.pub-cache
COPY pubspec.* ./
RUN dart pub get
RUN dart pub upgrade

# Copy app source code and AOT compile it.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline

# Compile executables for both http & gateway in the image.
RUN dart compile exe bin/pyrite_http.dart -o bin/pyrite_http
RUN dart compile exe bin/pyrite_gateway.dart -o bin/pyrite_gateway

# Build golang FFI (mongo_go.so) for mongo_go dart package.
FROM alpine:latest as mongo_build
RUN apk add --no-cache --update go gcc g++

COPY --from=build /app/.pub-cache /

# mongo_go includes the go library to use, so go there and build it, then copy to topmost dir.
RUN cd /hosted/pub.dev/mongo_go*/go && go build -buildmode=c-shared -o mongo_go.so && mv mongo_go.so ../../../../mongo_go.so

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM alpine:latest
RUN apk add --no-cache --update gcc

COPY --from=build /runtime/ /

WORKDIR /pyrite

COPY --from=build /app/bin/pyrite_http .
COPY --from=build /app/bin/pyrite_gateway .

COPY --from=mongo_build mongo_go.so ./bin/

# Start the bot. 
CMD ["./pyrite_http"]
