CLASS zcl_prometheus_rest_resource DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS: c_class_name TYPE seoclsname VALUE 'ZCL_PROMETHEUS_REST_RESOURCE'.

    METHODS:
      if_rest_resource~get REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prometheus_rest_resource IMPLEMENTATION.

  METHOD if_rest_resource~get.
*    DATA shr_area TYPE REF TO zcl_shr_prometheus_area.
*
*    TRY.
*        shr_area = zcl_shr_prometheus_area=>attach_for_read( ).
*        me->mo_response->create_entity( )->set_string_data( shr_area->root->test ).
*        shr_area->detach( ).
*        me->mo_response->set_status( cl_rest_status_code=>gc_success_ok ).
*      CATCH cx_root INTO DATA(x).
*        me->mo_response->set_status( cl_rest_status_code=>gc_server_error_internal ).
*        me->mo_response->set_reason( x->get_text( ) ).
*    ENDTRY.
  ENDMETHOD.

ENDCLASS.
