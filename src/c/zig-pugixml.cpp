#include "zig-pugixml.h"
#include "pugixml.hpp"
#include <iostream>
#include <cstring>


// C interface to the pugixml C++ library. These structs wrap 
// the pugi C++ objects in structs to allow C calls to C++ 

struct xml_parse_result { pugi::xml_parse_result* obj; };
struct xml_document     { pugi::xml_document*     obj; };
struct xml_node         { pugi::xml_node*         obj; };
struct xml_attribute    { pugi::xml_attribute*    obj; };
struct xml_text         { pugi::xml_text*         obj; };
struct xml_tree_walker  { pugi::xml_tree_walker*  obj; };

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
    return new xml_node({ 
        .obj = new pugi::xml_node()
    });
}

void free_xml_node(xml_node_t node) { 
    delete node->obj;
    delete node; 
}

xml_attr_t new_xml_attr(void) {
    return new xml_attribute({
        .obj = new pugi::xml_attribute()
    });
}

void free_xml_attr(xml_attr_t attr) { 
    delete attr->obj;
    delete attr;
}

xml_text_t new_xml_text(void) {
    return new xml_text({
        .obj = new pugi::xml_text() 
    });
}

void free_xml_text(xml_text_t text) {
    delete text->obj;
    delete text;
}

xml_node_t doc_to_node(xml_doc_t doc) {
    pugi::xml_node *docObj = doc->obj;
    return new xml_node({
        .obj = docObj
    });
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
    return new xml_node(
        { 
            .obj = new pugi::xml_node(doc->obj->child(name))
        }
        );
}

xml_node_t get_doc_first_child(xml_doc_t doc) {
    return new xml_node(
        { 
            .obj = new pugi::xml_node(doc->obj->first_child())
        }
    );
}

xml_node_t get_doc_last_child(xml_doc_t doc) {
    return new xml_node(
        { 
            .obj = new pugi::xml_node(doc->obj->last_child())
        }
    );
}

xml_node_t get_child_named(xml_node_t node, const char* name) {
    return new xml_node(
        { 
            .obj = new pugi::xml_node(node->obj->child(name))
        }
    );
}

const char * get_node_name(xml_node_t node) {
    return node->obj->name();
}

int get_node_type(xml_node_t node) {
    return node->obj->type();
}

xml_node_t get_first_child(xml_node_t node) {
    return new xml_node(
        {
            .obj = new pugi::xml_node(node->obj->first_child())
        }
    );
}

xml_node_t get_last_child(xml_node_t node) {
    return new xml_node(
        {
            .obj = new pugi::xml_node(node->obj->last_child())
        }
    );
}

xml_node_t get_next_sibling(xml_node_t node) {
     return new xml_node(
        {
            .obj = new pugi::xml_node(node->obj->next_sibling())
        }
    );
 }

xml_node_t next_sibling_named(xml_node_t node, const char* name) {
    return new xml_node(
        {
            .obj = new pugi::xml_node(node->obj->next_sibling(name))
        }
    );
}

xml_node_t get_previous_sibling(xml_node_t node) {
     return new xml_node(
        {
            .obj = new pugi::xml_node(node->obj->previous_sibling())
        }
    );
 }

xml_text_t get_node_text(xml_node_t  node) {
    return new xml_text(
        {
            .obj = new pugi::xml_text(node->obj->text())
        }
    );
}

bool nodes_eql(xml_node_t a, xml_node_t b) {
    // pugixml hash_value equality means the objects are at the 
    // same location in the document. Does not compare underlying
    // data to test two nodes for equality.
    if ((a->obj->hash_value()) == (b->obj->hash_value())) {
        return true;
    } else {
        return false; 
    }

}


bool attrs_eql(xml_attr_t a, xml_attr_t b) {
    // pugixml hash_value equality means the objects are at the 
    // same location in the document. Does not compare underlying
    // data to test two nodes for equality.
    if ((a->obj->hash_value()) == (b->obj->hash_value())) {
        return true;
    } else {
        return false; 
    }
}

xml_attr_t get_first_attr(xml_node_t node) {
    return new xml_attribute(
        {
            .obj = new pugi::xml_attribute(node->obj->first_attribute())
        }
    );
}

xml_attr_t get_last_attr(xml_node_t node) {
    return new xml_attribute(
        {
            .obj = new pugi::xml_attribute(node->obj->last_attribute())
        }
    );
}

xml_attr_t get_next_attr(xml_attr_t attr) {
    return new xml_attribute(
        {
            .obj = new pugi::xml_attribute(attr->obj->next_attribute())
        }
    );
}

xml_attr_t get_previous_attr(xml_attr_t attr) {
    return new xml_attribute(
        {
            .obj = new pugi::xml_attribute(attr->obj->previous_attribute())
        }
    );
}

bool attr_is_empty(xml_attr_t attr) {
    pugi::xml_attribute obj = *(attr->obj);
    if (obj) { 
        return false;
    } else { 
        return true; 
    }
}

const char* get_attr_name(xml_attr_t attr) {
    return attr->obj->name();
}

bool remove_attr(xml_node_t node, xml_attr_t attr) {
    const pugi::xml_attribute &attr_obj = *(attr->obj);
    bool result = node->obj->remove_attribute(attr_obj);
    return result;
}

bool remove_attr_by_name(xml_node_t node, const char* name) {
    pugi::xml_attribute attr = node->obj->attribute(name);
    return node->obj->remove_attribute(attr);
}

bool remove_attrs(xml_node_t node) {
    return node->obj->remove_attributes();
}

bool remove_child(xml_node_t node, xml_node_t child) {
    const pugi::xml_node &child_obj = *(child->obj);
    bool result = node->obj->remove_child(child_obj);
    return result;
}

bool remove_child_by_name(xml_node_t node, const char *name) {
    return node->obj->remove_child(name);
}

bool remove_children(xml_node_t node) {
    return node->obj->remove_children();
}

xml_node_t append_child (xml_node_t node, const char* name) {
    return new xml_node {
        .obj = new pugi::xml_node(
            node->obj->append_child(name)
        )
    };
}

xml_node_t prepend_child (xml_node_t node, const char* name) {
    return new xml_node {
        .obj = new pugi::xml_node(
            node->obj->prepend_child(name)
        )
    };
}

xml_node_t insert_child_after (xml_node_t node, 
                               const char* name, 
                               xml_node_t where) {
    const pugi::xml_node &where_obj = *(where->obj);
    return new xml_node {
        .obj = new pugi::xml_node(
            node->obj->insert_child_after(name, where_obj)
        )
    };
}

xml_node_t insert_child_before (xml_node_t node,
                                const char* name,
                                xml_node_t where) {
    const pugi::xml_node &where_obj = *(where->obj);
    return new xml_node {
        .obj = new pugi::xml_node(
            node->obj->insert_child_before(name, where_obj)
        )
    };
}

const char* get_child_value(xml_node_t node) {
    return node->obj->child_value();
}

xml_attr_t get_attr_by_name(xml_node_t node, const char* name) {
    return new xml_attribute(
        {
            .obj = new pugi::xml_attribute(node->obj->attribute(name))
        }
    );
}

const char* get_attr_value(xml_attr_t attr) { 
        return attr->obj->value(); 
}

bool attr_set_name(xml_attr_t attr, const char* name) {
    return attr->obj->set_name(name);
}

bool attr_set_value(xml_attr_t attr, const char* value) {
    return attr->obj->set_value(value);
}

const char* get_text_as_string(xml_text_t text) { 
    return text->obj->as_string(); 
}

bool get_text_as_bool(xml_text_t text) {
    return text->obj->as_bool(); }

int get_text_as_int(xml_text_t text) { 
    return text->obj->as_int();
}

xml_node_t get_text_data(xml_text_t text) { 
    return new xml_node(
        { 
            .obj = new pugi::xml_node(text->obj->data()) 
        }
    );
}

bool node_is_empty(xml_node_t node) {
    pugi::xml_node obj = *(node->obj);

    if (!obj) {
        return true;
    }

    if ((obj.type() == pugi::xml_node_type::node_element)
        &&  (obj.name() == "")) {
        return true;
    }

    if (obj) {
        return false;
    } else {
        return true;
    }
}

bool node_set_name(xml_node_t node, const char* name) {
    return node->obj->set_name(name);
}

bool node_set_value(xml_node_t node, const char* value) {
    return node->obj->set_value(value);
}

xml_attr_t append_attr(xml_node_t node, const char* name) {
    return new xml_attribute {
        .obj = new pugi::xml_attribute(
            node->obj->append_attribute(name)
        )
    };
}

xml_attr_t prepend_attr(xml_node_t node, const char* name) {
    return new xml_attribute {
        .obj = new pugi::xml_attribute(
            node->obj->prepend_attribute(name)
        )
    };
}

xml_attr_t insert_attr_after(xml_node_t node, const char* name, xml_attr_t attr) {
    const pugi::xml_attribute &attr_obj = *(attr->obj);
    return new xml_attribute {
        .obj = new pugi::xml_attribute(
            node->obj->insert_attribute_after(name, attr_obj)
        )
    };
}

xml_attr_t insert_attr_before(xml_node_t node, const char* name, xml_attr_t attr) {
    const pugi::xml_attribute &attr_obj = *(attr->obj);
    return new xml_attribute {
        .obj = new pugi::xml_attribute(
            node->obj->insert_attribute_before(name, attr_obj)
        )
    };
}

bool text_is_empty(xml_text_t text) {
    pugi::xml_text obj = *(text->obj);
    if (obj) { 
        return false; 
    } else { 
        return true; 
    }
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

