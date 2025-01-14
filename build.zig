const std = @import("std");
const Build = std.Build;
const StaticLibraryOptions = Build.StaticLibraryOptions;
const Compile = Build.Step.Compile;

pub fn build_pugixml_cpplib(
    b: *Build,
    options: *StaticLibraryOptions,
) *Compile {
    options.name = "pugixml_cpp";
    defer options.name = undefined;
    const upstream = b.dependency(
        "pugixml",
        .{},
    );
    const pugixml_cpp = b.addStaticLibrary(options.*);
    pugixml_cpp.addIncludePath(upstream.path("src"));
    pugixml_cpp.installHeader(
        upstream.path("src/pugixml.hpp"),
        "pugixml/pugixml.hpp",
    );
    pugixml_cpp.installHeader(upstream.path(
        "src/pugiconfig.hpp",
    ), "pugixml/pugiconfig.hpp");
    pugixml_cpp.installHeader(
        upstream.path("src/pugixml.cpp"),
        "pugixml/pugixml.cpp",
    );
    pugixml_cpp.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{"pugixml.cpp"},
        .flags = &.{
            "-DPUGIXML_COMPACT",
            //"-DPUGIXML_NO_EXCEPTIONS",
            //"-DPUGIXML_NO_STL",
            //"-DPUGIXML_NO_XPATH",
            "-DPUGIXML_MEMORY_PAGE_SIZE=131072",
        },
    });
    pugixml_cpp.linkLibCpp();
    b.installArtifact(pugixml_cpp);
    return pugixml_cpp; // pugixml_cpp static library
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const strip = b.option(
        bool,
        "strip",
        "Omit debug information",
    );
    const pic = b.option(
        bool,
        "pic",
        "Produce position independent code",
    );

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    var options: StaticLibraryOptions = .{
        .name = undefined,
        .target = target,
        .optimize = optimize,
        .pic = pic,
        .strip = strip,
        .link_libc = false,
    };

    //
    // pugixml c++ static library
    //
    const pugixml_cpplib = build_pugixml_cpplib(
        b,
        &options,
    );

    //
    // Zig module
    //

    const pugixml_zig_module = b.addModule(
        "zig-pugixml",
        .{
            .root_source_file = b.path(
                "src/pugixml.zig",
            ),
        },
    );
    pugixml_zig_module.addIncludePath(b.path("src"));
    // pugixml_zig_module.addSystemIncludePath(b.path("src"));
    // link against pugixml c++ library
    pugixml_zig_module.linkLibrary(pugixml_cpplib);
    // the C interface to the pugixml.cpp code
    pugixml_zig_module.addCSourceFiles(.{
        .root = b.path("src"),
        .files = &.{
            "zig-pugixml.cpp",
        },
        .flags = &.{},
    });
    //
    // "parse-xml" Executable
    //
    const parse_exe = b.addExecutable(.{
        .name = "parse-xml",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .pic = pic,
        .link_libc = false,
    });

    // use the zig module built above
    parse_exe.root_module.addImport(
        "pugixml",
        pugixml_zig_module,
    );
    b.installArtifact(parse_exe);

    // Allow a "run" step as a build command
    const run_parse_exe = b.addRunArtifact(parse_exe);
    const run_parse_exe_step = b.step(
        "run",
        "run parse-xml",
    );
    if (b.args) |args| {
        run_parse_exe.addArgs(args);
    }
    run_parse_exe_step.dependOn(&run_parse_exe.step);
    run_parse_exe_step.dependOn(b.getInstallStep());

    // UNIT TESTS
    // Adds "zig build test" to run unit tests
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
        .strip = strip,
        .pic = pic,
        .link_libc = false,
        .filters = test_filters,
    });

    unit_tests.root_module.addImport(
        "pugixml",
        pugixml_zig_module,
    );
    const run_unit_tests = b.addRunArtifact(unit_tests);
    // run every time
    run_unit_tests.has_side_effects = true;
    const test_step = b.step(
        "test",
        "run tests",
    );
    test_step.dependOn(&run_unit_tests.step);
    b.installArtifact(unit_tests);

    //
    // CLEAN
    const clean_step = b.step("clean", "Clean up");

    clean_step.dependOn(
        &b.addRemoveDirTree(b.install_path).step,
    );
    if (@import("builtin").os.tag != .windows) {
        clean_step.dependOn(
            &b.addRemoveDirTree(b.pathFromRoot(".zig-cache")).step,
        );

        clean_step.dependOn(
            &b.addRemoveDirTree(b.pathFromRoot("zig-out")).step,
        );
    }

    // Create source gzipped tarball
    const createTgzRun = createTgz(b);
    const runTarballStep = b.step("tarball", "Make tarball from sources");
    runTarballStep.dependOn(&createTgzRun.step);
}

fn createTgz(b: *std.Build) *std.Build.Step.Run {
    const tarRun = b.addSystemCommand(&.{
        "tar",
        "-C",
        "..",
        "-cf",
        "zig-pugixml.tar",
        "zig-pugixml/build.zig",
        "zig-pugixml/build.zig.zon",
        "zig-pugixml/README.md",
        "zig-pugixml/src/pugixml.zig",
        "zig-pugixml/src/zig-pugixml.cpp",
        "zig-pugixml/src/zig-pugixml.h",
        "zig-pugixml/src/main.zig",
        "zig-pugixml/src/tests.zig",
        "zig-pugixml/test-files/books.xml",
    });
    tarRun.has_side_effects = true;
    const gzipRun = b.addSystemCommand(&.{ "gzip", "zig-pugixml.tar" });
    gzipRun.has_side_effects = true;
    gzipRun.step.dependOn(&tarRun.step);
    const renameTarGzRun = b.addSystemCommand(
        &.{ "mv", "zig-pugixml.tar.gz", "zig-pugixml.tgz" },
    );
    renameTarGzRun.has_side_effects = true;
    renameTarGzRun.step.dependOn(&gzipRun.step);
    return renameTarGzRun;
}
