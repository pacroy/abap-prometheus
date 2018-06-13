CLASS zcl_prometheus_rest_resource DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS: c_class_name TYPE seoclsname VALUE 'ZCL_PROMETHEUS_REST_RESOURCE'.

    METHODS:
      constructor,
      if_rest_resource~get REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_prometheus_rest_resource IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).

  ENDMETHOD.

  METHOD if_rest_resource~get.
    TRY.
        zcl_prometheus=>set_instance_from_request( me->mo_request ).
        me->mo_response->create_entity( )->set_string_data( zcl_prometheus=>get_metric_string( ) ).
        me->mo_response->set_status( cl_rest_status_code=>gc_success_ok ).
        me->mo_response->set_header_field( iv_name = 'Content-Type' iv_value = if_rest_media_type=>gc_text_plain ).
      CATCH cx_root INTO DATA(x).
        me->mo_response->set_status( cl_rest_status_code=>gc_server_error_internal ).
        me->mo_response->set_reason( x->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
