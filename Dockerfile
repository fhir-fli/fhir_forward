################
# Currently, this Dockerfile fails to build for web on M1 machines
# see this error: https://github.com/rvolosatovs/docker-protobuf/issues/81
# ...this example: https://github.com/rvolosatovs/docker-protobuf/blob/main/Dockerfile
# ...these instructions: https://github.com/tonistiigi/xx

# FROM --platform=$BUILDPLATFORM tonistiigi/xx AS xx
# FROM --platform=$BUILDPLATFORM alpine
# # copy xx scripts to your build stage
# COPY --from=xx / /
# # export TARGETPLATFORM (or other TARGET*)
# ARG TARGETPLATFORM
# # you can now call xx-* commands
# RUN xx-info env

################
# Official Dart image: https://hub.docker.com/_/dart
# spec: https://github.com/dart-lang/samples/blob/master/server/simple/Dockerfile
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.12)
# This is occasionally necessary if the stable version won't work
# FROM dart:3.10 AS build
# Specify current stable version
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
# Ensure packages are still up-to-date if anything has changed
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Start server.
EXPOSE 8080
# ENTRYPOINT ["/app/bin/server"]
CMD ["/app/bin/server"]
