const std = @import("std");
const testing = std.testing;
const time = std.time;
const Instant = time.Instant;
const Timer = time.Instant;
const expect = testing.expect;
const expectError = testing.expectError;
const expectEqualStrings = testing.expectEqualStrings;

const pugixml = @import("pugixml");

const valid_xml =
    \\<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
    \\<Profile FormatVersion="1">
    \\    <Tools>
    \\        <Tool Filename="jam" AllowIntercept="true">
    \\            <Description>Jamplus build system</Description>
    \\        </Tool>
    \\        <Tool Filename="mayabatch.exe" AllowRemote="true"
    \\ OutputFileMasks="*.dae" DeriveCaptionFrom="lastparam" Timeout="40" />
    \\        <Tool Filename="meshbuilder_*.exe" AllowRemote="false" 
    \\ OutputFileMasks="*.mesh" DeriveCaptionFrom="lastparam" Timeout="10" />
    \\        <Tool Filename="texbuilder_*.exe" AllowRemote="true" 
    \\ OutputFileMasks="*.tex" DeriveCaptionFrom="lastparam" />
    \\        <Tool Filename="shaderbuilder_*.exe" AllowRemote="true"
    \\ DeriveCaptionFrom="lastparam" />
    \\    </Tools>
    \\</Profile>"
    \\
;

var valid_xml_mutable_slice = valid_xml.*;

fn valid_doc() pugixml.Doc {
    var doc = pugixml.Doc.init();
    const result = doc.loadBuffer(valid_xml);
    std.debug.assert(result.status == pugixml.ParseStatus.ok);
    return doc;
}

test "load xml from nonexistent file returns error" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadFile("file_not_there.xml");
    try expect(result.status == .file_not_found);
    //std.debug.print("{ParseResult}\n", .{result});
}

test "load valid xml sample books.xml" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();

    const result = doc.loadFile("test-files/books.xml");
    try expect(result.status == .ok);
    const node = doc.firstChild();
    // std.debug.print("{Node}", .{node});
    try expectEqualStrings("catalog", node.name());
}

test "access child, grandchild, greatgrandchild" {
    var doc = valid_doc();
    const child = doc.child("Profile");
    // std.debug.print("{Node}\n", .{child});
    try expect(!child.isEmpty());

    const gchild = doc.child("Profile").child("Tools");
    // std.debug.print("{Node}\n", .{gchild});
    try expect(!gchild.isEmpty());

    const ggchild = doc.child("Profile").child("Tools").child("Tool");
    // std.debug.print("{Node},empty={}\n", .{ ggchild, ggchild.isEmpty() });
    try expect(!ggchild.isEmpty());

    const nope = ggchild.child("Foobar");
    // std.debug.print("{Node},empty={}\n", .{ nope, nope.isEmpty() });
    try expect(nope.isEmpty());
}

test "ParseResult not ok for invalid xml" {
    const invalid_xml = "invalid xml content";
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadBuffer(invalid_xml);
    try expect(result.status != pugixml.ParseStatus.ok);
}

test "loadBuffer ParseStatus.ok for valid xml" {
    var doc: pugixml.Doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadBuffer(valid_xml);
    try expect(result.status == pugixml.ParseStatus.ok);
}

test "isEmpty works" {
    var doc = valid_doc();
    const nonempty_child = doc.child("Profile");
    const empty_child = doc.child("Foobar");
    try expect(!nonempty_child.isEmpty());
    try expect(empty_child.isEmpty());
}

test "loadString ParseResult.ok" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadString(valid_xml);
    try expect(result.status == pugixml.ParseStatus.ok);
}

test "loadString error ParseResult" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadString("invalid xml");
    // try expect(result.status != pugixml.ParseStatus.ok);
    // try expect(result.isOk());
    try expect(result.isErr());
}

test "loadBufferInplace ParseResult.ok" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadBufferInplace(
        &valid_xml_mutable_slice,
        //        valid_xml_mutable_slice.len,
    );
    try expect(result.status == pugixml.ParseStatus.ok);
}

test "loadBufferInplace using file ParseResult.ok" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        std.debug.panic("leak detected", .{});
    };
    const allocator = gpa.allocator();
    const filename = "test-files/books.xml";
    const buffer = try std.fs.cwd().readFileAlloc(
        allocator,
        filename,
        std.math.maxInt(usize),
    );
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const result = doc.loadBufferInplace(buffer);
    try expect(result.status == pugixml.ParseStatus.ok);
    allocator.free(buffer);
}

test "create tiny childless node" {
    const source = "<node></node>";
    var doc = pugixml.Doc.init();
    const result = doc.loadString(source);
    // std.debug.print("{ParseResult}\n", .{result});
    try expect(result.isOk());
}

test "check some error cases" {
    var doc = pugixml.Doc.init();
    defer doc.deinit();
    const Status = pugixml.ParseStatus;
    // testcase entry ( e : expected result, o: offset of err, s : source xml )
    const C = struct {
        e: Status,
        o: usize,
        s: [:0]const u8,
    };

    const testList = [_]C{
        C{
            .e = .ok,
            .o = 0,
            .s = "<node attr='value'><child>text</child></node>",
        },
        C{
            .e = .end_element_mismatch,
            .o = 32,
            .s = "<node attr='value'><child>text</chil></node>",
        },
        C{
            .e = .end_element_mismatch,
            .o = 37,
            .s = "<node attr='value'><child>text</child>",
        },
        C{
            .e = .bad_attribute,
            .o = 12,
            .s = "<node attr='value\"><child>text</child></node>",
        },
        C{
            .e = .unrecognized_tag,
            .o = 20,
            .s = "<node attr='value'><#tag /></node>",
        },
    };

    for (testList) |t| {
        const r = doc.loadString(t.s);
        //std.debug.print("{ParseResult}\n", .{r});
        const fmt =
            "[!] \nexpected:\"{},{d}\", got:\"{},{d}\" for xml:\n{s}\n\n";
        expect((r.status == t.e) and (r.offset == t.o)) catch |e| {
            std.debug.print(fmt, .{
                t.e,
                t.o,
                r.status,
                r.offset,
                t.s,
            });
            return e;
        };
    }
}

test "First and last attribute" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\<Child1 childAttr="child 1" childAttr2="child 2" />
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const node1 = doc.firstChild();

    const n1first = node1.firstAttribute();
    try expectEqualStrings("attr1", n1first.name());
    try expectEqualStrings("attr 1", n1first.value());

    const n1last = node1.lastAttribute();
    try expectEqualStrings("attr3", n1last.name());
    try expectEqualStrings("attr 3", n1last.value());
}

test "Get non-existent attr name" {
    //std.debug.print("Get non-existent attr name", .{});
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\<Child1 childAttr="child 1" childAttr2="child 2" />
        \\</Node1>
    ;
    var doc: pugixml.Doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const node1 = doc.firstChild();
    const notThere: pugixml.Attribute = node1.attribute("notThere");
    try expectEqualStrings("", notThere.value());
    //std.debug.print("notThere = '{}','{s}'\n", .{
    //    @TypeOf(notThere.value()),
    //    notThere.value(),
    //});
}

test "Attribute iterator" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\<Child1 childAttr="child 1" childAttr2="child 2" />
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    try expectEqualStrings(
        "Node1",
        node1.name(),
    );
    var iter = node1.attributeIterator();
    const firstAttr = iter.next();
    try expectEqualStrings("attr1", firstAttr.?.name());
    try expectEqualStrings(
        "attr 1",
        firstAttr.?.value(),
    );
    const secondAttr = iter.next();
    try expectEqualStrings("attr2", secondAttr.?.name());
    try expectEqualStrings("attr 2", secondAttr.?.value());
    const thirdAttr = iter.next();
    try expect(!thirdAttr.?.isEmpty());
    const child1 = node1.firstChild();
    try expectEqualStrings("Child1", child1.name());
    iter = child1.attributeIterator();
    while (iter.next()) |attr| {
        try expect(!attr.isEmpty());
    }
}

test "test childIterator" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<parent>
        \\<child1><a></a></child1>
        \\<child2></child2>
        \\<child3 />
        \\</parent>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const parent = doc.firstChild();
    var iter = parent.childIterator();
    try expectEqualStrings("child1", iter.next().?.name());
    try expectEqualStrings("child2", iter.next().?.name());
    try expectEqualStrings("child3", iter.next().?.name());
}

test "test doc childiter / Nodeiterator" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
        \\<child1><kid></kid></child1>
        \\<child2></child2>
        \\<child3 />
        \\
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var iter = doc.childIterator();
    var child = iter.next();
    try expectEqualStrings("child1", child.?.name());
    child = iter.next();
    try expectEqualStrings("child2", child.?.name());
    child = iter.next();
    try expectEqualStrings("child3", child.?.name());
    // iterator should be null now
    try expect(iter.next() == null);
    // iterator should continue to be null
    try expect(iter.next() == null);

    // reset the iterator.
    iter = doc.childIterator();

    // get a buffer to create a string in
    var buf: [20]u8 = undefined;
    var count: u32 = 1;

    // Use iterator in a while loop

    while (iter.next()) |ichild| : (count += 1) {
        const childName = try std.fmt.bufPrint(
            &buf,
            "child{d}",
            .{count},
        );
        try expectEqualStrings(childName, ichild.name());
    }
}

test "doc load buffer fragment and check type" {
    var doc = pugixml.Doc.init();
    const result = doc.loadBufferFragment("foobar<node/>");
    //std.debug.print("result = {ParseResult}\n", .{result});
    try expect(result.status == pugixml.ParseStatus.ok);
    const first = doc.firstChild();
    const t = first.getType();
    try expect(t == pugixml.NodeType.node_pcdata);
    //std.debug.print("first type = {}\n", .{t});
    const second = first.nextSibling();
    try expect(second.getType() == pugixml.NodeType.node_element);
    //std.debug.print("second type = {}", .{second.getType()});
}

test "next and previous siblings" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 /><Node2></Node2><Node3 />
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const node1 = doc.child("Node1");
    const node2 = node1.nextSibling();
    try expectEqualStrings("Node2", node2.name());
    const node3 = node2.nextSibling();
    try expectEqualStrings("Node2", node3.previousSibling().name());
}

test "text.isEmpty()" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<NodeWithText>Here is the text</NodeWithText>
        \\<NodeWithEmptyText></NodeWithEmptyText>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const node1 = doc.firstChild();
    const n1txt = node1.text();
    try expect(n1txt.isEmpty() == false);
    const node2 = doc.child("NodeWithEmptyText");
    try expect(node2.isEmpty() == false);
    try expect(node2.text().isEmpty() == true);
}

test "set node name and node value" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\ text node string
        \\<Child1 childAttr="child 1" childAttr2="child 2" />
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    const setNameResult = node1.setName("NewName1");
    try expect(setNameResult == true);

    try expectEqualStrings(
        "NewName1",
        node1.name(),
    );
    try expect(!node1.isEmpty());

    // Setting value on a node can only work if the
    // node is pcdata, cdata, comment, pi (processing instr) or doc
    const setValueResult = node1.setValue("Node1 Value");
    try expectError(
        pugixml.Node.Error.WrongType,
        setValueResult,
    );

    const txtNode = node1.firstChild();
    try expect(!txtNode.isEmpty());
    const txtStr = txtNode.text().asString();
    try expectEqualStrings(
        "\n text node string\n",
        txtStr,
    );
    const newValue = "new text value";
    try txtNode.setValue(newValue);
    try expectEqualStrings(
        newValue,
        txtNode.text().asString(),
    );
}

test "remove attribute" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    try expect(!(node1.isEmpty()));
    const attr1 = node1.attribute("attr1");
    try expectEqualStrings("attr 1", attr1.value());
    const removeResult = node1.removeAttribute(attr1);
    //std.debug.print("removeResult = {}", .{removeResult});
    try expect(removeResult == true);
    node1 = doc.child("Node1");
    try expectEqualStrings(
        "attr2",
        node1.firstAttribute().name(),
    );
    try expectEqualStrings(
        "attr 2",
        node1.firstAttribute().value(),
    );
    try expect(node1.removeAttribute(node1.attribute("FOO")) == false);
}

test "remove attributes" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    const node1 = doc.child("Node1");
    try expect(!(node1.isEmpty()));
    const res = node1.removeAttributes();
    try expect(res == true);
    try expect(node1.firstAttribute().isEmpty() == true);
    try expect(node1.attribute("attr2").isEmpty() == true);
    try expect(node1.lastAttribute().isEmpty() == true);
}

test "node remove child" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="node1 attr 1" attr2="node1 attr 2"
        \\ attr3="node1 attr 3">
        \\ text node string
        \\<Child1 childAttr="child 1 attr1" childAttr2="child1 attr2" />
        \\<Child2 childAttr="child 2 attr1" childAttr2="child2 attr2" />
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    const child1 = node1.child("Child1");
    try expect(!node1.isEmpty());
    try expect(!child1.isEmpty());
    const res = node1.remove(.{ .child = child1 });
    try expect(res == true);
    try expect(node1.child("Child1").isEmpty());
}

test "node remove child with name" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\ text node string
        \\<Child1 childAttr="child 1" childAttr2="child 2" />
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    try expect(!node1.isEmpty());
    const res = node1.remove(.{ .name = "Child1" });
    try expect(res == true);
    try expect(!node1.isEmpty());
    const child = node1.child("Child1");
    try expect(child.isEmpty());
    try expectEqualStrings(
        "\n text node string\n",
        node1.firstChild().text().asString(),
    );
    // std.debug.print("Child = {Node} empty={}", .{
    //     child,
    //     child.isEmpty(),
    // });
}

test "set attr name & value" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());
    var node1 = doc.child("Node1");
    try expect(!node1.isEmpty());
    const attr1 = node1.attribute("attr1");
    var res = attr1.setValue("new value");
    try expect(res == true);
    try expectEqualStrings("new value", attr1.value());

    const attr2 = node1.attribute("attr2");
    res = attr2.setName("attr99");
    try expect(res == true);
    try expectEqualStrings("attr99", attr2.name());
}

test "append attribute" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());

    const node1 = doc.child("Node1");
    const new_attr1 = node1.appendAttribute(
        "new_attribute",
    );
    // std.debug.print(
    //     "new_attr = {Attribute}\n",
    //     .{new_attr1},
    // );
    const new_attr2 = node1.lastAttribute();
    // std.debug.print(
    //     "new_attr = {Attribute}\n",
    //     .{new_attr2},
    // );

    try expectEqualStrings(
        "new_attribute",
        new_attr2.name(),
    );
    try expectEqualStrings(
        "new_attribute",
        new_attr1.name(),
    );
    try expect(new_attr1.eql(new_attr2));
    try expect(pugixml.Attribute.eql(new_attr1, new_attr2));
}

test "addAttribute .append" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Node1 attr1="attr 1" attr2="attr 2" attr3="attr 3">
        \\</Node1>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());

    const node1 = doc.child("Node1");
    const new_attr1 = node1.addAttribute(
        "new_attribute",
        .append,
    );
    // std.debug.print(
    //     "new_attr = {Attribute}\n",
    //     .{new_attr1},
    // );
    // const new_attr2 = node1.lastAttribute();
    // std.debug.print(
    //     "new_attr = {Attribute}\n",
    //     .{new_attr2},
    // );

    try expectEqualStrings(
        "new_attribute",
        node1.lastAttribute().name(),
    );
    try expect(new_attr1.eql(node1.lastAttribute()));
}

test "addChild .append, .prepend" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Begin><stuff>hello</stuff></Begin>
        \\<End></End>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadString(xml);
    try expect(result.isOk());

    // append
    const final = doc.addChild(
        "Final",
        .append,
    );
    try expect(final.eql(doc.lastChild()));

    try expectEqualStrings(
        "Final",
        doc.lastChild().name(),
    );

    // prepend
    const start = doc.addChild(
        "Start",
        .prepend,
    );

    try expect(start.eql(doc.firstChild()));
    try expectEqualStrings(
        "Start",
        start.name(),
    );

    // add after an existing node

    const second = doc.child("Begin");
    const upperMiddle = doc.addChild(
        "UpperMiddle",
        .{ .after = second },
    );
    try expect(
        doc.child(
            "Begin",
        ).nextSibling().eql(
            upperMiddle,
        ),
    );

    // add before an existing node
    const lowerMiddle = doc.addChild(
        "LowerMiddle",
        .{
            .before = doc.child("End"),
        },
    );
    try expect(
        doc.child(
            "End",
        ).previousSibling().eql(
            lowerMiddle,
        ),
    );
    // try doc.toStderr();

    // At the end of this testing, the XML is:
    // <?xml version="1.0"?>
    // <Start />
    // <Begin>
    //  <stuff>hello</stuff>
    // </Begin>
    // <UpperMiddle />
    // <LowerMiddle />
    // <End />
    // <Final />

}

test "load invalid doc and get an error result" {
    const xml = "<node><child>text</chil></node>";
    var doc = pugixml.Doc.init();
    try expectError(
        pugixml.ParseError.EndElementMismatch,
        doc.loadStringOrError(xml),
    );
    const result = doc.parseResult.?;
    const detail = doc.contextDetail(
        xml,
        result,
        64,
    );
    // std.debug.print("{ContextDetail}\n", .{detail});
    var mem = [_:0]u8{0} ** 256; // This should hold contextLength*2
    const buf = mem[0..];

    _ = try std.fmt.bufPrint(buf, "{ContextDetail}\n", .{detail});
    // std.debug.print("buf.len={d}\n", .{buf.len});
    // std.debug.print("{s}\n", .{buf});

    const expected: []const u8 =
        "<node><child>text</chil></node>\n" ++
        "                   ^--[19]\n";
    try std.testing.expectEqualStrings(expected, buf[0..expected.len]);
}

test "NodeIteratorNamed" {
    const xml =
        \\<?xml version="1.0" encoding="UTF-8" ?>
        \\<Nope>nope1</Nope>
        \\<Good>some stuff</Good>
        \\<Other />
        \\<Good>more stuff</Good>
        \\<Bad></Bad>
        \\<Ugly></Ugly>
        \\<Good>Keep this</Good>
        \\<Other></Other>
    ;
    var doc = pugixml.Doc.init();
    const result = doc.loadBuffer(xml);
    try expect(result.isOk());
    var iter = doc.childIteratorNamed("Good");

    try expectEqualStrings("Good", iter.next().?.name());
    try expectEqualStrings("Good", iter.next().?.name());
    try expectEqualStrings("Good", iter.next().?.name());
    try expect(iter.next() == null);
    iter = doc.childIteratorNamed("Other");
    try expectEqualStrings("Other", iter.next().?.name());
    try expectEqualStrings("Other", iter.next().?.name());
    try expect(iter.next() == null);
}
