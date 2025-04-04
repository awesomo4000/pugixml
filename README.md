# Zig wrappers for the PugiXML C++ parser

This is a set of wrappers with a nice zig interface to the pugixml C++ xml library.

Pugixml C++ (https://pugixml.org/) is a high-speed in-situ XML parser. It parses XML to a DOM structure without doing much copying of the data (using pointers). It is one of the fastest XML parsers available. XML files must fit in memory with an overhead of about 25%.

The code for pugixml C++ (currently v1.15) is included in this repo in the `src/c/pugi*.[ch]pp` files. The zig c->cpp interface to the library files are in `src/c/zig-pugixml.cpp` and `src/c/zig-pugixml.h`.


## Using:

In your zig project, run:


`zig fetch --save=pugixml https://github.com/awesomo4000/pugixml/archive/refs/tag/v0.2.1.tar.gz`

In build.zig:

```zig

    // Define the dependency

    const pugixml_dep = b.dependency("pugixml", .{
        .target = target,
        .optimize = optimize,
    });

    // Use it with a module

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("pugixml", pugixml_dep.module("pugixml"));

```

After modifying build.zig, you may import "pugixml" in your zig source:

```zig

const pugixml = @import("pugixml");

```

Refer to `src/tests.zig` to see examples of usage.


## C++ and Zig

Using C++ code from Zig requires a translation layer using the C++ code from C, then exporting the C functions via `extern C` in the C header file. Zig code then imports the C header file to reference its definitions. This code is linked into the final binary (staticly for this binding).

Look in `src/c/zig-pugixml.h` to see how zig does C imports.

Check out `build.zig` to see how the build system compiles the C++ library and links it to the Zig module.

## Sample program: `parse-xml`

There is a sample program `parse-xml` included in the build that shows how to use the zig module. It times how long it takes to parse an XML file. Example:

```
$ ./zig-out/bin/parse-xml
Usage: parse-xml filename

$ ls -lh ./big-testfile.xml
-rw-r--r-- 434M Jan 15 03:12 ./big-testfile.xml

$ ./zig-out/bin/parse-xml ./big-testfile.xml 
./big-testfile.xml: No error.
Elapsed time: 224.362ms.
```

`parse-xml` should run fine against malformed data, e.g.:

```
$ ./zig-out/bin/parse-xml /dev/random
/dev/random: Error reading from file/stream.
Elapsed time: 0.059ms.
```

## Building:

Use version 0.14.0 of Zig to build.

Cross-compiled builds produced working versions for the following platforms:

   - x86_64-windows
   - aarch64-windows
   - aarch64-linux
   - aarch64-macos


### For production builds:

```
zig build --release=fast

zig build --release=small
```

### For debug build (the default):

`zig build`

### Building for other OSes

By default, Zig builds for the OS running the compiler.  To cross compile for a different system, use commands like these:

`zig build -Dtarget=x86-64-winodws --release=small`

`zig build -Dtarget=aarch64-windows --release=fast`

`zig build -Dtarget=x86-64-linux --release=fast`

`zig build -Dtarget=aarch64-linux --release=fast`


## Tests

For tests in debug mode:

`zig build test` 

For tests in release mode: 

`zig build test --release=fast`

A clean test run will return no output, which means all tests passed. The exit code should be 0 for a good test run.


## Build Artifacts

Output from build is in `./zig-out`, with sample binary `parse-xml` in `./zig-out/bin/parse-xml`. 

Include files and C code is in `./zig-out/include`.

The static library for pugixml C++ created during the build is in `./zig-out/lib/libpugixml_cpp.a` .


## Build options

Use `zig build -h` to see other options and build commands:

```
$ zig build -h
Usage: zig build [steps] [options]

Steps:
  install (default)            Copy build artifacts to prefix path
  uninstall                    Remove build artifacts from prefix path
  run                          run parse-xml
  test                         run tests
  clean                        Clean up
  tarball                      Make tarball from sources

...

```
