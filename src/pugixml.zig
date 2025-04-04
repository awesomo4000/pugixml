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

const XmlError = error{
    NoParseResult,
};

pub const ParseError = error{
    FileNotFound,
    IOError,
    OutOfMemory,
    InternalError,
    UnrecognizedTag,
    BadPI,
    BadComment,
    BadCData,
    BadDocType,
    BadPCData,
    BadStartElement,
    BadAttribute,
    BadEndElement,
    EndElementMismatch,
    AppendInvalidRoot,
    NoDocumentElement,
};

const ParseResult = struct {
    status: ParseStatus,
    description: [*:0]const u8,
    offset: usize,

    const Self = @This();

    pub fn initWith_C_Result(
        result: ?*c.xml_parse_result,
    ) ParseResult {
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

    pub fn statusAsError(self: *const Self) ?ParseError {
        return switch (self.status) {
            .ok => null,
            .file_not_found => ParseError.FileNotFound,
            .io_error => ParseError.IOError,
            .out_of_memory => ParseError.OutOfMemory,
            .internal_error => ParseError.InternalError,
            .unrecognized_tag => ParseError.UnrecognizedTag,
            .bad_pi => ParseError.BadPI,
            .bad_comment => ParseError.BadComment,
            .bad_cdata => ParseError.BadCData,
            .bad_doctype => ParseError.BadDocType,
            .bad_pcdata => ParseError.BadPCData,
            .bad_start_element => ParseError.BadStartElement,
            .bad_attribute => ParseError.BadAttribute,
            .bad_end_element => ParseError.BadEndElement,
            .end_element_mismatch => ParseError.EndElementMismatch,
            .append_invalid_root => ParseError.AppendInvalidRoot,
            .no_document_element => ParseError.NoDocumentElement,
        };
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

    pub fn isEmpty(self: *const Self) bool {
        return c.text_is_empty(self.c_text);
    }
};

pub const Attribute = struct {
    c_attr: ?*c.xml_attribute,
    const Self = @This();

    pub fn eql(self: Self, other: Self) bool {
        //        if ((self.c_attr == null) and (other.c_attr == null)) return true;
        return c.attrs_eql(self.c_attr, other.c_attr);
    }

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

    pub fn setName(
        self: *const Self,
        attrName: [:0]const u8,
    ) bool {
        return c.attr_set_name(self.c_attr, attrName);
    }

    pub fn setValue(
        self: *const Self,
        attrValue: [:0]const u8,
    ) bool {
        return c.attr_set_value(self.c_attr, attrValue);
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
            "{s}(name=\"{s}\",value=\"{?s}\" {?s}",
            .{
                @typeName(Self),
                self.name(),
                self.value(),
                self.c_attr,
            },
        );
    }
};

pub const Node = struct {
    c_node: ?*c.xml_node,
    //c_node: NodeOrDoc,

    const Self = @This();

    pub const Error = error{WrongType};

    pub fn init() Self {
        return Self{ .c_node = c.new_xml_node() };
    }

    pub fn initWith_C_Node(c_node: ?*c.xml_node) Self {
        return Self{ .c_node = c_node };
    }

    pub fn eql(self: Self, other: Self) bool {
        //        if ((self.c_node == null) and (other.c_node == null)) return true;
        return c.nodes_eql(self.c_node, other.c_node);
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

    pub fn nameZ(self: *const Self) [:0]const u8 {
        return std.mem.span(c.get_node_name(self.c_node));
    }

    pub fn getType(self: *const Self) NodeType {
        return @enumFromInt(c.get_node_type(self.c_node));
    }

    pub fn attribute(
        self: *const Self,
        attr_name: [:0]const u8,
    ) Attribute {
        return Attribute{ .c_attr = c.get_attr_by_name(
            self.c_node,
            attr_name,
        ) };
    }

    pub fn firstAttribute(self: *const Self) Attribute {
        return Attribute{ .c_attr = c.get_first_attr(
            self.c_node,
        ) };
    }

    pub fn lastAttribute(self: *const Self) Attribute {
        return Attribute{ .c_attr = c.get_last_attr(
            self.c_node,
        ) };
    }

    pub fn attributeIterator(
        self: *const Self,
    ) AttributeIterator {
        return AttributeIterator{
            .first = self.firstAttribute(),
        };
    }

    pub fn nextSibling(self: *const Self) Self {
        const c_node = c.get_next_sibling(self.c_node);
        return Node{ .c_node = c_node };
    }

    pub fn nextSiblingNamed(self: *const Self, elementName: [:0]const u8) Self {
        const c_node = c.next_sibling_named(
            self.c_node,
            elementName,
        );
        return Node{ .c_node = c_node };
    }

    pub fn previousSibling(self: *const Self) Self {
        const c_node = c.get_previous_sibling(self.c_node);
        return Node{ .c_node = c_node };
    }

    pub fn text(self: *const Self) Text {
        const text_node = c.get_node_text(self.c_node);
        return Text.initWith_C_Text(text_node);
    }

    pub fn child(
        self: *const Self,
        child_name: [:0]const u8,
    ) Self {
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

    pub fn setName(
        self: *const Self,
        nodeName: [:0]const u8,
    ) bool {
        return c.node_set_name(self.c_node, nodeName);
    }

    pub fn setValue(
        self: *const Self,
        nodeValue: [:0]const u8,
    ) Node.Error!void {
        const result = c.node_set_value(
            self.c_node,
            nodeValue,
        );
        if (result == false) {
            return Node.Error.WrongType;
        } else {
            return;
        }
    }

    pub fn removeAttribute(
        self: *const Self,
        attr: Attribute,
    ) bool {
        const result = c.remove_attr(
            self.c_node,
            attr.c_attr,
        );
        return result;
    }

    pub fn removeAttributes(self: *const Self) bool {
        const result = c.remove_attrs(self.c_node);
        return result;
    }

    const Removeable = union(enum) {
        child: Node,
        allChildren: void,
        name: [:0]const u8,
        attr: Attribute,
        attrName: [:0]const u8,
        allAttrs: void,
    };

    pub fn remove(
        self: *const Self,
        thing: Removeable,
    ) bool {
        return switch (thing) {
            .child => c.remove_child(
                self.c_node,
                thing.child.c_node,
            ),
            .allChildren => c.remove_children(self.c_node),
            .name => c.remove_child_by_name(
                self.c_node,
                thing.name,
            ),
            .attr => c.remove_attr(
                self.c_node,
                thing.attr.c_attr,
            ),
            .attrName => c.remove_attr_by_name(
                self.c_node,
                thing.attrName,
            ),
            .allAttrs => c.remove_attrs(self.c_node),
        };
    }

    const AttributePlacement = union(enum) {
        append: void,
        prepend: void,
        after: Attribute,
        before: Attribute,
    };

    pub fn addAttribute(
        self: *const Self,
        attrName: [:0]const u8,
        where: AttributePlacement,
    ) Attribute {
        const c_attr = switch (where) {
            .append => c.append_attr(self.c_node, attrName),
            .prepend => c.prepend_attr(self.c_node, attrName),
            .after => c.insert_attr_after(
                self.c_node,
                attrName,
                where.after.c_attr,
            ),
            .before => c.insert_attr_before(
                self.c_node,
                attrName,
                where.before.c_attr,
            ),
        };
        return Attribute{ .c_attr = c_attr };
    }

    pub fn appendAttribute(
        self: *const Self,
        attrName: [:0]const u8,
    ) Attribute {
        return Attribute{ .c_attr = c.append_attr(
            self.c_node,
            attrName,
        ) };
    }

    const Placement = union(enum) {
        append: void,
        prepend: void,
        after: Node,
        before: Node,
    };

    pub fn add(
        self: *const Self,
        childName: [:0]const u8,
        where: Placement,
    ) Node {
        const c_node = switch (where) {
            .append => c.append_child(self.c_node, childName),
            .prepend => c.prepend_child(self.c_node, childName),
            .after => c.insert_child_after(
                self.c_node,
                childName,
                where.after.c_node,
            ),
            .before => c.insert_child_before(
                self.c_node,
                childName,
                where.before.c_node,
            ),
        };

        return Node{ .c_node = c_node };
    }

    pub fn deinit(self: *Self) void {
        if (self.c_node) |node| {
            c.free_xml_node(node);
        }
    }

    pub fn childIteratorNamed(self: *const Self, named: [:0]const u8) NodeIteratorNamed {
        return NodeIteratorNamed{
            .first = self.child(named),
        };
    }

    pub fn childIterator(self: *const Self) NodeIterator {
        return NodeIterator{
            .first = self.firstChild(),
        };
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

const NodeIteratorNamed = struct {
    first: Node,
    const Self = @This();

    pub fn next(self: *Self) ?Node {
        if (self.first.isEmpty()) {
            return null;
        }
        const current = self.first;
        const tmpName = current.nameZ();
        self.first = self.first.nextSiblingNamed(tmpName);
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

pub const ContextDetail = struct {
    offset: usize,
    context: []const u8,
    contextLength: usize,
    contextOffset: usize,

    const Self = @This();
    pub fn format(
        self: *const Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print(
            "{s}\n{s: >[3]}^--[{d}]",
            .{ self.context, "", self.offset, self.contextOffset },
        );
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

    pub fn contextDetail(
        self: *Self,
        source: []const u8,
        parseResult: ParseResult,
        contextLength: usize,
    ) ContextDetail {
        _ = self;
        const offset = parseResult.offset;
        const startPos = offset -| contextLength;
        var endPos = offset +| contextLength;
        endPos = @min(endPos, source.len);
        return ContextDetail{
            .offset = offset,
            .context = source[startPos..endPos],
            .contextLength = contextLength,
            .contextOffset = offset - startPos,
        };
    }

    pub fn loadFile(
        self: *Self,
        path: [:0]const u8,
    ) ParseResult {
        const c_result: ?*c.struct_xml_parse_result = c.load_file(
            self.c_doc,
            path,
        );
        const result = ParseResult.initWith_C_Result(
            c_result,
        );
        //self.parseResult = result;
        return result;
    }

    pub fn loadFileOrError(self: *Self, path: [:0]const u8) ParseError!void {
        const result = self.loadFile(path);
        if (result.isErr()) {
            return result.statusAsError().?;
        }
        return;
    }

    pub fn loadString(self: *Self, source: [:0]const u8) ParseResult {
        const c_result: ?*c.struct_xml_parse_result = c.load_string(
            self.c_doc,
            source,
        );
        const result = ParseResult.initWith_C_Result(
            c_result,
        );
        self.parseResult = result;
        return result;
    }

    pub fn loadStringOrError(self: *Self, source: [:0]const u8) ParseError!void {
        const result = self.loadString(source);
        if (result.isErr()) {
            return result.statusAsError().?;
        }
        return;
    }

    pub fn loadBuffer(self: *Self, source: []const u8) ParseResult {
        const c_result = c.load_buffer(
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

    pub fn loadBufferInplace(
        self: *Self,
        source: []u8,
    ) ParseResult {
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

    pub fn lastChild(self: *const Self) Node {
        const c_node = c.get_doc_last_child(self.c_doc);
        return Node{ .c_node = c_node };
    }

    pub fn child(self: *const Self, name: [:0]const u8) Node {
        const c_node = c.get_doc_child_named(
            self.c_doc,
            name,
        );
        return Node{ .c_node = c_node };
    }

    pub fn childIterator(self: *const Self) NodeIterator {
        return NodeIterator{
            .first = self.firstChild(),
        };
    }

    pub fn childIteratorNamed(
        self: *const Self,
        named: [:0]const u8,
    ) NodeIteratorNamed {
        return NodeIteratorNamed{
            .first = self.child(named),
        };
    }

    pub fn addChild(
        self: *const Self,
        name: [:0]const u8,
        where: Node.Placement,
    ) Node {
        const docNode = Node{
            .c_node = c.doc_to_node(self.c_doc),
        };
        return docNode.add(name, where);
    }

    pub fn toStderr(self: *const Self) !void {
        if (!(self.parseResult.?.isOk())) {
            return XmlError.NoParseResult;
        }
        c.doc_to_stderr(self.c_doc);
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
