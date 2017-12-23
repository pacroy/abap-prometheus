*"* use this source file for your ABAP unit test classes

CLASS ltcl_base DEFINITION DEFERRED.
CLASS zcl_prometheus DEFINITION LOCAL FRIENDS ltcl_base.

CLASS ltcl_base DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
  PROTECTED SECTION.
    DATA: cut  TYPE REF TO zcl_prometheus.
  PRIVATE SECTION.
    METHODS:
      setup.
ENDCLASS.

CLASS ltcl_base IMPLEMENTATION.

  METHOD setup.
    me->cut = NEW #( ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_write_read_delete DEFINITION FINAL INHERITING FROM ltcl_base FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      happy_path FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_write_read_delete IMPLEMENTATION.

  METHOD happy_path.
    CONSTANTS c_abapunit TYPE string VALUE 'ABAPUNIT' ##NO_TEXT.

    me->cut->write( i_root = c_abapunit i_record = VALUE #( key = 'TEST' value = '123456' ) ).
    me->cut->write( i_root = c_abapunit i_record = VALUE #( key = 'test' value = '123000' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '123000' act = me->cut->read_single( i_root = c_abapunit i_key = 'TEST' ) ).

    me->cut->write( i_root = c_abapunit i_record = VALUE #( key = 'TEST2' value = '456789' ) ).
    me->cut->write( i_root = c_abapunit i_record = VALUE #( key = 'TEST3' value = '789123' ) ).
    DATA(records) = me->cut->read_all( c_abapunit ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test' value = '123456' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test2' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test3' value = '789123' ) ).

    me->cut->delete( i_root = c_abapunit i_key = 'TEST2' ).
    records = me->cut->read_all( c_abapunit ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test2' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test3' value = '789123' ) ).

    zcl_shr_prometheus_area=>free_instance( CONV #( c_abapunit ) ).
  ENDMETHOD.

ENDCLASS.
