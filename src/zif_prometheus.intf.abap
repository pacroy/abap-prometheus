INTERFACE zif_prometheus
  PUBLIC .
  TYPES: t_command TYPE c LENGTH 1,
         BEGIN OF t_record,
           key   TYPE string,
           value TYPE string,
         END OF t_record,
         t_record_table TYPE STANDARD TABLE OF t_record WITH KEY key,
         BEGIN OF t_modify_record.
      INCLUDE TYPE t_record.
  TYPES: command TYPE t_command,
         END OF t_modify_record,
         t_modify_record_table TYPE STANDARD TABLE OF t_modify_record WITH KEY key.

  CONSTANTS: BEGIN OF c_command,
               overwrite TYPE t_command VALUE IS INITIAL,
               increment TYPE t_command VALUE 'I',
             END OF c_command.

  CLASS-METHODS:
    read_all
      RETURNING VALUE(r_result) TYPE t_record_table
      RAISING
                cx_shm_attach_error,

    read_single
      IMPORTING i_key           TYPE string
      RETURNING VALUE(r_result) TYPE string
      RAISING
                cx_shm_attach_error,

    write_single
      IMPORTING i_record TYPE t_modify_record
      RAISING
                cx_shm_attach_error,

    write_multiple
      IMPORTING i_record_table TYPE t_modify_record_table
      RAISING
                cx_shm_attach_error,

    delete
      IMPORTING i_key TYPE string
      RAISING
                cx_shm_attach_error,

    get_metric_string
      RETURNING VALUE(r_result) TYPE string
      RAISING
                cx_shm_attach_error.
ENDINTERFACE.
