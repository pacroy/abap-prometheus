INTERFACE zif_prometheus
  PUBLIC .
  TYPES: BEGIN OF t_record,
           key   TYPE string,
           value TYPE string,
         END OF t_record,
         t_record_table TYPE STANDARD TABLE OF t_record WITH KEY key.

  METHODS:
    read_all
      RETURNING VALUE(r_result) TYPE t_record_table
      RAISING
                cx_shm_attach_error,

    read_single
      IMPORTING i_key           TYPE string
      RETURNING VALUE(r_result) TYPE string
      RAISING
                cx_shm_attach_error,

    write
      IMPORTING i_record TYPE t_record
      RAISING
                cx_shm_attach_error,

    delete
      IMPORTING i_key  TYPE string
      RAISING
                cx_shm_attach_error,

    get_metric_string
      RETURNING VALUE(r_result) TYPE string
      RAISING
                cx_shm_attach_error.
ENDINTERFACE.
