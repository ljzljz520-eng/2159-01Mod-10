# Build stage
FROM emscripten/emsdk:3.1.51 AS build
WORKDIR /src

# Copy frontend source code (now flat structure)
COPY frontend/fireworks.c .
COPY frontend/index.html .

# Create output directory
RUN mkdir -p public

# Compile C to WebAssembly
# -s USE_SDL=2      : Use SDL2
# -s WASM=1         : Output WebAssembly
# -O3               : Optimization level
# -o public/fireworks.js : Output file
RUN emcc fireworks.c \
    -s USE_SDL=2 \
    -s WASM=1 \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXPORTED_RUNTIME_METHODS=['ccall','cwrap'] \
    -s EXPORTED_FUNCTIONS=['_beat_trigger','_add_beat_timestamp','_clear_beats','_start_beat_playback','_stop_beat_playback','_is_beat_playing'] \
    -O3 \
    -o public/fireworks.js

# Production stage
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy built artifacts from build stage
COPY --from=build /src/public/fireworks.js .
COPY --from=build /src/public/fireworks.wasm .
COPY --from=build /src/index.html .

EXPOSE 3000

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
