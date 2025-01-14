// zig wrapper library for using pugixml C++
//
const std = @import("std");
const c = @cImport({
    @cInclude("zig-pugixml.h");
});

pub const NodeType = enum(u32) {
    node_null = 0, // Empty (null) node handle
    node_document, // A document tree's absolute root
    node_element, // Element tag, i.e. '<node/>'
    node_pcdata, // Plain character data, i.e. 'text'
    node_cdata, // Character data, i.e. '<![CDATA[text]]>'
    node_comment, // Comment tag, i.e. '<!-- text -->'
    node_pi, // Processing instruction, i.e. '<?name?>'
    node_declaration, // Document declaration, i.e. '<?xml version="1.0"?>'
    node_doctype, // Document type declaration, i.e. '<!DOCTYPE doc>'
};

// copied from pugixml enum xml_parse_status (v1.15)

pub const ParseStatus = enum(u32) {
    ok = 0, // No error
    file_not_found, // File not found during load_file()
    io_error, // Error reading from file/stream
    out_of_memory, // Could not allocate memory
    internal_error, // Internal error occurred
    unrecognized_tag, // Could not determine tag type
    bad_pi, // Bad declaration/processing instruction
    bad_comment, // Bad comment
    bad_cdata, // Bad CDATA section
    bad_doctype, // Bad document type declaration
    bad_pcdata, // Bad PCDATA section
    bad_start_element, // Bad start element tag
    bad_attribute, // Bad element attribute
    bad_end_element, // Bad end element tag
    end_element_mismatch, // Mismatched start-end tags
    append_invalid_root, // Unable to append nodes
    no_document_element, // Document had no element nodes
};

const ParseResult = struct {
    status: ParseStatus,
    description: [*:0]const u8,
    offset: usize,

    const Self = @This();

    pub fn initWith_C_Result(result: ?*c.xml_parse_result) ParseResult {
        return Self{
            .status = @enumFromInt(c.get_status(result)),
            .description = c.get_description(result),
            .offset = c.get_offset(result),
        };
    }

    pub fn isOk(self: *const Self) bool {
        return (self.status == ParseStatus.ok);
    }

    pub fn isErr(self: *const Self) bool {
        return (!(self.status == ParseStatus.ok));
    }

    pub fn format(
        self: *const Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print(
            \\{s}(status="{}","{s}",offset={d})"
        , .{
            @typeName(Self),
            self.status,
            self.description,
            self.offset,
        });
    }
};

const Text = struct {
    c_text: ?*c.xml_text,

    const Self = @This();

    pub fn initWith_C_Text(c_text: ?*c.xml_text) Self {
        return Self{ .c_text = c_text };
    }

    pub fn asString(self: *const Self) []const u8 {
        return std.mem.span(c.get_text_as_string(
            self.c_text,
        ));
    }

    pub fn asInt(self: *const Self) c_int {
        return c.get_text_as_int(self.c_text);
    }

    pub fn asBool(self: *const Self) bool {
        return c.get_text_as_bool(self.c_text);
    }
};

const Attribute = struct {
    c_attr: ?*c.xml_attribute,
    const Self = @This();

    pub fn isEmpty(self: *const Self) bool {
        const res: bool = c.attr_is_empty(self.c_attr);
        return res;
    }

    pub fn name(self: *const Self) []const u8 {
        return std.mem.span(c.get_attr_name(self.c_attr));
    }

    pub fn value(self: *const Self) []const u8 {
        return std.mem.span(c.get_attr_value(self.c_attr));
    }

    pub fn nextAttribute(self: *const Self) Self {
        return Attribute{
            .c_attr = c.get_next_attr(self.c_attr),
        };
    }

    pub fn previousAttribute(self: *const Self) Self {
        return Attribute{
            .c_attr = c.get_previous_attr(self.c_attr),
        };
    }
};

pub const Node = struct {
    c_node: ?*c.xml_node,

    const Self = @This();

    pub const Error = error{WrongType};

    pub fn init() Self {
        return Self{ .c_node = c.new_xml_node() };
    }

    pub fn initWith_C_Node(c_node: ?*c.xml_node) Self {
        return Self{ .c_node = c_node };
    }

    pub fn isEmpty(self: *const Self) bool {
        const res: bool = c.node_is_empty(self.c_node);
        return res;
    }

    pub fn firstChild(self: *const Self) Node {
        return Node{
            .c_node = c.get_first_child(self.c_node),
        };
    }

    pub fn name(self: *const Self) []const u8 {
        return std.mem.span(c.get_node_name(
            self.c_node,
        ));
    }

    pub fn getType(self: *const Self) NodeType {
        return @enumFromInt(c.get_node_type(self.c_node));
    }

    pub fn firstAttribute(self: *const Self) Attribute {
        return Attribute{ .c_attr = c.get_first_attr(
            self.c_node,
        ) };
    }

    pub fn lastAttribute(self: *const Self) Attribute {
        return Attribute{ .c_node = c.get_last_attr(
            self.c_node,
        ) };
    }

    pub fn attributeIterator(self: *const Self) AttributeIterator {
        return AttributeIterator{
            .first = self.firstAttribute(),
        };
    }

    pub fn nextSibling(self: *const Self) Self {
        const c_node = c.get_next_sibling(self.c_node);
        return Node{ .c_node = c_node };
    }

    pub fn text(self: *const Self) Text {
        const text_node = c.get_node_text(self.c_node);
        return Text.initWith_C_Text(text_node);
    }

    pub fn child(self: *const Self, child_name: [:0]const u8) Self {
        const c_node = c.get_child_named(
            self.c_node,
            child_name,
        );
        return Node{ .c_node = c_node };
    }

    pub fn parent(self: *const Self) Self {
        const c_node = c.get_parent(self.c_node);
        return Node{ .c_node = c_node };
    }

    pub fn setName(self: *const Self, nodeName: [:0]const u8) bool {
        return c.node_set_name(self.c_node, nodeName);
    }

    pub fn setValue(
        self: *const Self,
        nodeValue: [:0]const u8,
    ) Node.Error!void {
        const result = c.node_set_value(self.c_node, nodeValue);
        if (result == false) {
            return Node.Error.WrongType;
        } else {
            return;
        }
    }

    pub fn deinit(self: *Self) void {
        if (self.c_node) |node| {
            c.free_xml_node(node);
        }
    }

    pub fn format(
        self: *const Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{s}(name=\"{s}\",c_node={?s})", .{
            @typeName(Self),
            self.name(),
            self.c_node,
        });
    }
};

const NodeIterator = struct {
    first: Node,
    const Self = @This();

    pub fn next(self: *Self) ?Node {
        if (self.first.isEmpty()) {
            return null;
        }
        const current = self.first;
        self.first = self.first.nextSibling();
        return current;
    }
};

const AttributeIterator = struct {
    first: Attribute,
    const Self = @This();

    pub fn next(self: *Self) ?Attribute {
        if (self.first.isEmpty()) {
            return null;
        }
        const current = self.first;
        self.first = self.first.nextAttribute();
        return current;
    }
};

pub const Doc = struct {
    c_doc: ?*c.xml_document,
    parseResult: ?ParseResult,

    const Self = @This();

    pub fn init() Self {
        return Self{
            .c_doc = c.new_xml_doc(),
            .parseResult = null,
        };
    }

    pub fn deinit(self: *const Self) void {
        if (self.c_doc) |doc| {
            c.free_xml_doc(doc);
        }
    }

    pub fn contextDetail(self: *Self, source: [:0]const u8) []const u8 {
        // _ = source;
        if (self.parseResult == null) {
            return "no parse result";
        }
        const offset = self.parseResult.?.offset;
        const contextLen = 64;
        const startPos = applyShift(offset, -contextLen);
        var endPos = applyShift(offset, contextLen);
        endPos = @min(endPos, source.len);
        return source[startPos..endPos];
    }

    pub fn loadFile(self: *Self, path: [:0]const u8) ParseResult {
        const c_result: ?*c.struct_xml_parse_result = c.load_file(
            self.c_doc,
            path,
        );
        const result = ParseResult.initWith_C_Result(c_result);
        //self.parseResult = result;
        return result;
    }

    pub fn loadString(self: *Self, source: [:0]const u8) ParseResult {
        const c_result: ?*c.struct_xml_parse_result = c.load_string(
            self.c_doc,
            source,
        );
        const result = ParseResult.initWith_C_Result(c_result);
        self.parseResult = result;
        return result;
    }

    pub fn loadBuffer(self: *Self, source: []const u8) ParseResult {
        const c_result = c.load_buffer(
            self.c_doc,
            source.ptr,
            source.len,
        );
        const result = ParseResult.initWith_C_Result(c_result);
        self.parseResult = result;
        return result;
    }

    pub fn loadBufferFragment(
        self: *Self,
        source: []const u8,
    ) ParseResult {
        const c_result = c.load_buffer_fragment(
            self.c_doc,
            source.ptr,
            source.len,
        );
        const result = ParseResult.initWith_C_Result(
            c_result,
        );
        self.parseResult = result;
        return result;
    }

    pub fn loadBufferInplace(self: *Self, source: []u8) ParseResult {
        const c_result =
            c.load_buffer_inplace(
            self.c_doc,
            source.ptr,
            source.len,
        );
        const result = ParseResult.initWith_C_Result(
            c_result,
        );
        self.parseResult = result;
        return result;
    }

    pub fn firstChild(self: *const Self) Node {
        const c_node = c.get_doc_first_child(self.c_doc);
        return Node{ .c_node = c_node };
    }

    pub fn child(self: *Self, name: [:0]const u8) Node {
        const c_node = c.get_doc_child_named(
            self.c_doc,
            name,
        );
        return Node{ .c_node = c_node };
    }

    pub fn childIterator(self: *const Self) NodeIterator {
        return NodeIterator{ .first = self.firstChild() };
    }

    pub fn walkTree(self: *const Self) void {
        c.walk_tree(self.c_doc);
        return;
    }
};

fn applyShift(orig: usize, shift: isize) usize {
    // https://ziggit.dev/t/on-type-choices-and-idiomatic-way-to-add-a-negative-number-to-usize/2301
    const s: isize = shift;
    var u: usize = orig;
    if (s < 0)
        u -|= @abs(s) // use @abs to avoid overflow
    else
        u +|= @intCast(s);
    return u;
}
