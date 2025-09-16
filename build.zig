const std = @import("std");
const Build = std.Build;

pub fn build_pugixml_cpplib(
    b: *Build,
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *Build.Step.Compile {
    // Create a module for the C++ library (no zig source, just C++)
    const cpplib_module = b.createModule(.{
        .root_source_file = null, // No Zig source, only C++
        .target = target,
        .optimize = optimize,
    });

    const pugixml_cpplib = b.addLibrary(.{
        .name = "pugixml_cpp",
        .root_module = cpplib_module,
        .linkage = .static,
    });

    pugixml_cpplib.installHeadersDirectory(
        b.path("src/c"),
        "",
        .{
            .include_extensions = &.{
                ".h",
                ".c",
                ".cpp",
                ".hpp",
            },
        },
    );
    pugixml_cpplib.addCSourceFiles(.{
        .root = b.path("src/c"),
        .files = &.{"pugixml.cpp"},
        .flags = &.{
            "-DPUGIXML_COMPACT",
            //"-DPUGIXML_NO_EXCEPTIONS",
            //"-DPUGIXML_NO_STL",
            //"-DPUGIXML_NO_XPATH",
            "-DPUGIXML_MEMORY_PAGE_SIZE=131072",
        },
    });
    pugixml_cpplib.linkLibCpp();
    b.installArtifact(pugixml_cpplib);
    return pugixml_cpplib;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_filters = b.option(
        []const []const u8,
        "test-filter",
        "Skip tests that do not match any filter",
    ) orelse &[0][]const u8{};

    //
    // pugixml c++ static library
    //
    const pugixml_cpplib = build_pugixml_cpplib(
        b,
        target,
        optimize,
    );

    //
    // Zig module
    //
    const pugixml_zig_module = b.addModule(
        "pugixml",
        .{
            .root_source_file = b.path("src/pugixml.zig"),
            .target = target,
            .optimize = optimize,
        },
    );
    pugixml_zig_module.addCSourceFile(
        .{ .file = b.path("src/c/zig-pugixml.cpp") },
    );

    // link against pugixml c++ library
    pugixml_zig_module.linkLibrary(pugixml_cpplib);

    //
    // "parse-xml" Executable
    //
    const parse_exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const parse_exe = b.addExecutable(.{
        .name = "parse-xml",
        .root_module = parse_exe_module,
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

    //
    // Test step
    // Adds "zig build test" to run unit tests
    //
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const unit_tests = b.addTest(.{
        .root_module = test_module,
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
    // clean step
    //
    const clean_step = b.step(
        "clean",
        "Clean up",
    );

    clean_step.dependOn(
        &b.addRemoveDirTree(.{ .cwd_relative = b.install_path }).step,
    );
    if (@import("builtin").os.tag != .windows) {
        clean_step.dependOn(
            &b.addRemoveDirTree(b.path(".zig-cache")).step,
        );

        clean_step.dependOn(
            &b.addRemoveDirTree(b.path("zig-out")).step,
        );
    }

    // Create source gzipped tarball
    const createTgzRun = createTgz(b);
    const runTarballStep = b.step(
        "tgz",
        "Make tgz from sources",
    );
    runTarballStep.dependOn(&createTgzRun.step);
}

fn createTgz(b: *std.Build) *std.Build.Step.Run {
    const tarRun = b.addSystemCommand(&.{
        "tar",
        "-C",
        "..",
        "-cf",
        "pugixml.tar",
        "pugixml/src/c/pugiconfig.hpp",
        "pugixml/src/c/pugixml.cpp",
        "pugixml/src/c/pugixml.hpp",
        "pugixml/src/c/zig-pugixml.cpp",
        "pugixml/src/c/zig-pugixml.h",
        "pugixml/src/main.zig",
        "pugixml/src/pugixml.zig",
        "pugixml/src/tests.zig",
        "pugixml/README.md",
        "pugixml/build.zig",
        "pugixml/build.zig.zon",
        "pugixml/.gitignore",
    });

    tarRun.has_side_effects = true;
    const gzipRun = b.addSystemCommand(&.{
        "gzip",
        "pugixml.tar",
    });

    gzipRun.has_side_effects = true;
    gzipRun.step.dependOn(&tarRun.step);

    const renameTarGzRun = b.addSystemCommand(
        &.{
            "mv",
            "pugixml.tar.gz",
            "pugixml.tgz",
        },
    );
    renameTarGzRun.has_side_effects = true;
    renameTarGzRun.step.dependOn(&gzipRun.step);
    return renameTarGzRun;
}