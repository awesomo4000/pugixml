## Zig interface to the pugixml c++ library 

(https://pugixml.org/)




### Building:

Zig compiler version 0.13.0 is needed to compile.

#### For production build:

`zig build --release=fast`

#### For debug build(default):

`zig build`

#### To run tests:

`zig build test`


#### Build Artifactis

Output from build is in `./zig-out`, with sample binary `parse-xml` 
in `./zig-out/bin`.


#### Use `zig build -h` to see other options and build commands.

