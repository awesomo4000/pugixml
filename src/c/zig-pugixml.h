// Declarations for C interface to C++ pugixml wrapper
#include <stddef.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

struct         xml_document;
typedef struct xml_document* xml_doc_t;
struct         xml_parse_result;
typedef struct xml_parse_result* xml_result_t;
struct         xml_node;
typedef struct xml_node* xml_node_t;
struct         xml_attribute;
typedef struct xml_attribute* xml_attr_t;
struct         xml_text;
typedef struct xml_text* xml_text_t;
struct         xml_tree_walker;
typedef struct xml_tree_walker* xml_tree_walker_t;

xml_doc_t    new_xml_doc           (void);
xml_result_t new_xml_parse_result  (void);
xml_node_t   new_xml_node          (void);
xml_attr_t   new_xml_attr          (void);
xml_text_t   new_xml_text          (void);
void         free_xml_doc          (xml_doc_t doc);
void         free_xml_parse_result (xml_result_t result);
void         free_xml_node         (xml_node_t node);
void         free_xml_attr         (xml_attr_t attr);
void         free_xml_text         (xml_text_t text);
xml_node_t   doc_to_node           (xml_doc_t doc);
xml_result_t load_buffer           (xml_doc_t doc, const char* source, 
                                                          size_t size);
xml_result_t load_buffer_fragment  (xml_doc_t doc, const char* source,
                                                          size_t size);
xml_result_t load_buffer_inplace   (xml_doc_t doc, void* source,
                                                          size_t size);
xml_result_t load_string           (xml_doc_t doc, const char* source);
xml_result_t load_file             (xml_doc_t doc, const char* path);
void         doc_to_stderr         (xml_doc_t doc);
int          get_status            (xml_result_t result);
size_t       get_offset            (xml_result_t result);
const char*  get_description       (xml_result_t result);
xml_node_t   get_doc_child_named   (xml_doc_t  doc, const char* name);
xml_node_t   get_doc_first_child   (xml_doc_t doc);
xml_node_t   get_doc_last_child    (xml_doc_t doc);
xml_node_t   get_child_named       (xml_node_t node, const char* name);
xml_node_t   get_first_child       (xml_node_t node);
xml_node_t   get_last_child        (xml_node_t node);
xml_node_t   get_next_sibling      (xml_node_t node);
xml_node_t   next_sibling_named    (xml_node_t node, const char* name);
xml_node_t   get_previous_sibling  (xml_node_t node);
bool         node_is_empty         (xml_node_t node);
int          get_node_type         (xml_node_t node);
const char*  get_node_name         (xml_node_t);
xml_text_t   get_node_text         (xml_node_t node);
const char*  get_child_value       (xml_node_t node);
bool         nodes_eql             (xml_node_t a, xml_node_t b);
bool         attrs_eql             (xml_attr_t a, xml_attr_t b);
xml_attr_t   get_attr_by_name      (xml_node_t node, const char* name);
const char*  get_attr_name         (xml_attr_t attr);
xml_attr_t   get_first_attr        (xml_node_t node);
xml_attr_t   get_last_attr         (xml_node_t node); 
xml_attr_t   get_next_attr         (xml_attr_t attr);
xml_attr_t   get_previous_attr     (xml_attr_t attr);
bool         attr_is_empty         (xml_attr_t attr);
const char*  get_attr_value        (xml_attr_t attr);
bool         attr_set_name         (xml_attr_t attr, const char* name);
bool         attr_set_value        (xml_attr_t attr, const char* value);
bool         remove_attr           (xml_node_t node, xml_attr_t attr);
bool         remove_attr_by_name   (xml_node_t node, const char* name);
bool         remove_attrs          (xml_node_t node);
bool         remove_child          (xml_node_t parent, xml_node_t child);
bool         remove_child_by_name  (xml_node_t, const char* name);
bool         remove_children       (xml_node_t node);
xml_node_t   append_child          (xml_node_t node, const char* name);
xml_node_t   prepend_child         (xml_node_t node, const char* name);
xml_node_t   insert_child_after    (xml_node_t node, const char* name,
                                                     xml_node_t where);
xml_node_t   insert_child_before   (xml_node_t node, const char* name,
                                                     xml_node_t where);
xml_attr_t   append_attr           (xml_node_t node, const char* name);
xml_attr_t   prepend_attr          (xml_node_t node, const char* name);
xml_attr_t   insert_attr_after     (xml_node_t node, const char* name,
                                                      xml_attr_t attr);
xml_attr_t   insert_attr_before    (xml_node_t node, const char* name,
                                                      xml_attr_t attr);
const char*  get_text_as_string    (xml_text_t text);
bool         get_text_as_bool      (xml_text_t text);
int          get_text_as_int       (xml_text_t text);
xml_node_t   get_text_data         (xml_text_t text);
bool         text_is_empty         (xml_text_t text);
// void         walk_tree             (xml_doc_t doc);
bool         node_set_name         (xml_node_t node, const char* name);
bool         node_set_value        (xml_node_t node, const char* value);

#ifdef __cplusplus
}
#endif