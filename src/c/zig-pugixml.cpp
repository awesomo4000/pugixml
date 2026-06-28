#include "zig-pugixml.h"
#include "pugixml.hpp"
#include <iostream>
#include <cstring>


// C interface to the pugixml C++ library.
//
// pugixml's xml_node, xml_attribute and xml_text are each just a single
// pointer wrapped in a value type, so the handles below carry that pointer
// by value. Traversing the document therefore performs no heap allocation:
// child(), next_sibling(), attribute(), text() etc. all return a handle by
// value. The document and parse-result objects are heavier (and created only
// once per load), so they remain heap-allocated behind an opaque pointer.

struct xml_parse_result { pugi::xml_parse_result* obj; };
struct xml_document     { pugi::xml_document*     obj; };
struct xml_tree_walker  { pugi::xml_tree_walker*  obj; };

static_assert(sizeof(pugi::xml_node) == sizeof(void*),
              "pugi::xml_node must be pointer-sized for value handles");
static_assert(sizeof(pugi::xml_attribute) == sizeof(void*),
              "pugi::xml_attribute must be pointer-sized for value handles");
static_assert(sizeof(pugi::xml_text) == sizeof(void*),
              "pugi::xml_text must be pointer-sized for value handles");

// value-handle <-> pugixml object conversions (no allocation; just a copy of
// the underlying pointer, done via memcpy to stay within the standard).
static inline xml_node_t wrap_node(pugi::xml_node n) {
    xml_node_t h; std::memcpy(&h, &n, sizeof(h)); return h;
}
static inline pugi::xml_node as_node(xml_node_t h) {
    pugi::xml_node n; std::memcpy(&n, &h, sizeof(n)); return n;
}
static inline xml_attr_t wrap_attr(pugi::xml_attribute a) {
    xml_attr_t h; std::memcpy(&h, &a, sizeof(h)); return h;
}
static inline pugi::xml_attribute as_attr(xml_attr_t h) {
    pugi::xml_attribute a; std::memcpy(&a, &h, sizeof(a)); return a;
}
static inline xml_text_t wrap_text(pugi::xml_text t) {
    xml_text_t h; std::memcpy(&h, &t, sizeof(h)); return h;
}
static inline pugi::xml_text as_text(xml_text_t h) {
    pugi::xml_text t; std::memcpy(&t, &h, sizeof(t)); return t;
}

xml_doc_t new_xml_doc(void) {
    return new xml_document({.obj = new pugi::xml_document()});
}

void free_xml_doc(xml_doc_t document) {
    delete document->obj; delete document;
}

xml_result_t new_xml_parse_result(void) {
    return new xml_parse_result({.obj =
            new pugi::xml_parse_result() }); }

void free_xml_parse_result(xml_result_t result) {
    delete result->obj; delete result;
}

xml_node_t new_xml_node(void) {
    return wrap_node(pugi::xml_node());
}

xml_attr_t new_xml_attr(void) {
    return wrap_attr(pugi::xml_attribute());
}

xml_text_t new_xml_text(void) {
    return wrap_text(pugi::xml_text());
}

xml_node_t doc_to_node(xml_doc_t doc) {
    return wrap_node(*doc->obj);
}

xml_result_t load_string(xml_doc_t document, const char* source)
{
    pugi::xml_document* doc_obj = document->obj;
    xml_result_t c_result = new_xml_parse_result();
    pugi::xml_parse_result* pugi_res = c_result->obj;
    pugi::xml_parse_result tmp_result = doc_obj->load_string(source);
    pugi_res->encoding = tmp_result.encoding;
    pugi_res->offset = tmp_result.offset;
    pugi_res->status = tmp_result.status;
    return c_result;
}

xml_result_t load_file(xml_doc_t document, const char* path)
{
    pugi::xml_document* doc_obj = document->obj;
    xml_result_t c_result = new_xml_parse_result();
    pugi::xml_parse_result* pugi_res = c_result->obj;
    pugi::xml_parse_result tmp_result = doc_obj->load_file(path);
    pugi_res->encoding = tmp_result.encoding;
    pugi_res->offset = tmp_result.offset;
    pugi_res->status = tmp_result.status;
    return c_result;
}

xml_result_t load_buffer(xml_doc_t document, const char* source,
                 size_t size)
{
    pugi::xml_document* doc_obj = document->obj;
    xml_result_t c_result = new_xml_parse_result();
    pugi::xml_parse_result* pugi_res = c_result->obj;
    pugi::xml_parse_result tmp_result =
            doc_obj->load_buffer(source, size);
    pugi_res->encoding = tmp_result.encoding;
    pugi_res->offset = tmp_result.offset;
    pugi_res->status = tmp_result.status;
    return c_result;
}

xml_result_t load_buffer_fragment(xml_doc_t document,
                                  const char* source,
                                  size_t size)
{
    pugi::xml_document* doc_obj = document->obj;
    xml_result_t c_result = new_xml_parse_result();
    pugi::xml_parse_result* pugi_res = c_result->obj;
    pugi::xml_parse_result tmp_result =
            doc_obj->load_buffer(source, size,
                pugi::parse_default | pugi::parse_fragment);
    pugi_res->encoding = tmp_result.encoding;
    pugi_res->offset = tmp_result.offset;
    pugi_res->status = tmp_result.status;
    return c_result;
}

xml_result_t load_buffer_inplace(xml_doc_t document,
                            void* source, size_t size)
{
    pugi::xml_document* doc_obj = document->obj;
    xml_result_t c_result = new_xml_parse_result();
    pugi::xml_parse_result* pugi_res = c_result->obj;
    pugi::xml_parse_result tmp_result =
            doc_obj->load_buffer_inplace(source, size);
    pugi_res->encoding = tmp_result.encoding;
    pugi_res->offset = tmp_result.offset;
    pugi_res->status = tmp_result.status;
    return c_result;
}

void doc_to_stderr(xml_doc_t document) {
    pugi::xml_document* doc_obj = document->obj;
    doc_obj->save(std::cerr, " ");
    std::cerr << std::endl;
    std::cerr.flush();
}

const char* get_description(xml_result_t result) {
    return result->obj->description();
}

int get_status(xml_result_t result) {
    return result->obj->status;
}

size_t get_offset(xml_result_t result) {
    return result->obj->offset;
}

xml_node_t get_doc_child_named(xml_doc_t doc, const char* name) {
    return wrap_node(doc->obj->child(name));
}

xml_node_t get_doc_first_child(xml_doc_t doc) {
    return wrap_node(doc->obj->first_child());
}

xml_node_t get_doc_last_child(xml_doc_t doc) {
    return wrap_node(doc->obj->last_child());
}

xml_node_t get_child_named(xml_node_t node, const char* name) {
    return wrap_node(as_node(node).child(name));
}

const char * get_node_name(xml_node_t node) {
    return as_node(node).name();
}

int get_node_type(xml_node_t node) {
    return as_node(node).type();
}

xml_node_t get_first_child(xml_node_t node) {
    return wrap_node(as_node(node).first_child());
}

xml_node_t get_last_child(xml_node_t node) {
    return wrap_node(as_node(node).last_child());
}

xml_node_t get_next_sibling(xml_node_t node) {
    return wrap_node(as_node(node).next_sibling());
}

xml_node_t next_sibling_named(xml_node_t node, const char* name) {
    return wrap_node(as_node(node).next_sibling(name));
}

xml_node_t get_previous_sibling(xml_node_t node) {
    return wrap_node(as_node(node).previous_sibling());
}

xml_text_t get_node_text(xml_node_t node) {
    return wrap_text(as_node(node).text());
}

bool nodes_eql(xml_node_t a, xml_node_t b) {
    // pugixml hash_value equality means the objects are at the
    // same location in the document. Does not compare underlying
    // data to test two nodes for equality.
    return as_node(a).hash_value() == as_node(b).hash_value();
}

bool attrs_eql(xml_attr_t a, xml_attr_t b) {
    // pugixml hash_value equality means the objects are at the
    // same location in the document. Does not compare underlying
    // data to test two nodes for equality.
    return as_attr(a).hash_value() == as_attr(b).hash_value();
}

xml_attr_t get_first_attr(xml_node_t node) {
    return wrap_attr(as_node(node).first_attribute());
}

xml_attr_t get_last_attr(xml_node_t node) {
    return wrap_attr(as_node(node).last_attribute());
}

xml_attr_t get_next_attr(xml_attr_t attr) {
    return wrap_attr(as_attr(attr).next_attribute());
}

xml_attr_t get_previous_attr(xml_attr_t attr) {
    return wrap_attr(as_attr(attr).previous_attribute());
}

bool attr_is_empty(xml_attr_t attr) {
    return !as_attr(attr);
}

const char* get_attr_name(xml_attr_t attr) {
    return as_attr(attr).name();
}

bool remove_attr(xml_node_t node, xml_attr_t attr) {
    return as_node(node).remove_attribute(as_attr(attr));
}

bool remove_attr_by_name(xml_node_t node, const char* name) {
    pugi::xml_node n = as_node(node);
    return n.remove_attribute(n.attribute(name));
}

bool remove_attrs(xml_node_t node) {
    return as_node(node).remove_attributes();
}

bool remove_child(xml_node_t node, xml_node_t child) {
    return as_node(node).remove_child(as_node(child));
}

bool remove_child_by_name(xml_node_t node, const char *name) {
    return as_node(node).remove_child(name);
}

bool remove_children(xml_node_t node) {
    return as_node(node).remove_children();
}

xml_node_t append_child (xml_node_t node, const char* name) {
    return wrap_node(as_node(node).append_child(name));
}

xml_node_t prepend_child (xml_node_t node, const char* name) {
    return wrap_node(as_node(node).prepend_child(name));
}

xml_node_t insert_child_after (xml_node_t node,
                               const char* name,
                               xml_node_t where) {
    return wrap_node(as_node(node).insert_child_after(name, as_node(where)));
}

xml_node_t insert_child_before (xml_node_t node,
                                const char* name,
                                xml_node_t where) {
    return wrap_node(as_node(node).insert_child_before(name, as_node(where)));
}

const char* get_child_value(xml_node_t node) {
    return as_node(node).child_value();
}

xml_attr_t get_attr_by_name(xml_node_t node, const char* name) {
    return wrap_attr(as_node(node).attribute(name));
}

const char* get_attr_value(xml_attr_t attr) {
    return as_attr(attr).value();
}

bool attr_set_name(xml_attr_t attr, const char* name) {
    return as_attr(attr).set_name(name);
}

bool attr_set_value(xml_attr_t attr, const char* value) {
    return as_attr(attr).set_value(value);
}

const char* get_text_as_string(xml_text_t text) {
    return as_text(text).as_string();
}

bool get_text_as_bool(xml_text_t text) {
    return as_text(text).as_bool(); }

int get_text_as_int(xml_text_t text) {
    return as_text(text).as_int();
}

xml_node_t get_text_data(xml_text_t text) {
    return wrap_node(as_text(text).data());
}

bool node_is_empty(xml_node_t node) {
    return !as_node(node);
}

bool node_set_name(xml_node_t node, const char* name) {
    return as_node(node).set_name(name);
}

bool node_set_value(xml_node_t node, const char* value) {
    return as_node(node).set_value(value);
}

xml_attr_t append_attr(xml_node_t node, const char* name) {
    return wrap_attr(as_node(node).append_attribute(name));
}

xml_attr_t prepend_attr(xml_node_t node, const char* name) {
    return wrap_attr(as_node(node).prepend_attribute(name));
}

xml_attr_t insert_attr_after(xml_node_t node, const char* name, xml_attr_t attr) {
    return wrap_attr(as_node(node).insert_attribute_after(name, as_attr(attr)));
}

xml_attr_t insert_attr_before(xml_node_t node, const char* name, xml_attr_t attr) {
    return wrap_attr(as_node(node).insert_attribute_before(name, as_attr(attr)));
}

bool text_is_empty(xml_text_t text) {
    return !as_text(text);
}

const char* node_types[] =
{
    "null", "document", "element", "pcdata", "cdata", \
    "comment", "pi", "declaration"
};


// tree walker
struct simple_walker: pugi::xml_tree_walker
{
    virtual bool for_each(pugi::xml_node& node)
    {
        for (int i=0; i< depth(); ++i) std::cout << " "; //indent
        std::cout   << node_types[node.type()]
                    << ": name='"
                    << node.name()
                    << "', value='"
                    << node.value()
                    << "'\n";
        return true;

    }
};

void walk_tree(xml_doc_t doc, xml_tree_walker_t walker) {
    pugi::xml_document* pugi_doc = doc->obj;
    pugi_doc->traverse(*(walker->obj));
    return;
}
