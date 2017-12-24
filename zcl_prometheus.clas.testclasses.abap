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
      setup,
      teardown.
ENDCLASS.

CLASS ltcl_base IMPLEMENTATION.

  METHOD setup.
    me->cut = CAST #( zcl_prometheus=>get_instance( 'ABAPUNIT' ) ).
  ENDMETHOD.

  METHOD teardown.
    zcl_shr_prometheus_area=>free_instance( 'ABAPUNIT'  ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_write_read_delete DEFINITION FINAL INHERITING FROM ltcl_base FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      happy_path FOR TESTING RAISING cx_static_check,
      increment FOR TESTING RAISING cx_static_check,
      test_mode FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_write_read_delete IMPLEMENTATION.

  METHOD happy_path.
    me->cut->write_single( i_record = VALUE #( key = 'TEST{id="1"}' value = '123456' ) ).
    me->cut->write_single( i_record = VALUE #( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '123000' act = me->cut->read_single( 'TEST{id="1"}' ) ).

    me->cut->write_multiple( VALUE #( ( key = 'TEST{id="2"}' value = '456789' )
                                      ( key = 'TEST{id="3"}' value = '789123' ) ) ).
    DATA(records) = me->cut->read_all( ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123456' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="2"}' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="3"}' value = '789123' ) ).

    me->cut->delete( 'test{id="2"}' ).
    records = me->cut->read_all( ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="2"}' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="3"}' value = '789123' ) ).

    DATA(metric_str) = |test\{id="1"\} 123000\r\ntest\{id="3"\} 789123\r\n|.
    cl_abap_unit_assert=>assert_equals( exp = metric_str act = me->cut->get_metric_string( ) ).
  ENDMETHOD.

  METHOD increment.
    me->cut->write_single( i_record = VALUE #( key = 'TEST' value = '$INC' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '1' act = me->cut->read_single( 'TEST' ) ).
    me->cut->write_single( i_record = VALUE #( key = 'TEST' value = '$INC' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '2' act = me->cut->read_single( 'TEST' ) ).
  ENDMETHOD.

  METHOD test_mode.
    zcl_prometheus=>test_mode = abap_true.

    me->cut->write_single( i_record = VALUE #( key = 'TEST' value = '5' ) ).
    cl_abap_unit_assert=>assert_equals( exp = space act = me->cut->read_single( 'TEST' ) ).
    me->cut->write_single( i_record = VALUE #( key = 'TEST' value = '$INC' ) ).
    cl_abap_unit_assert=>assert_equals( exp = space act = me->cut->read_single( 'TEST' ) ).

    zcl_prometheus=>test_mode = abap_false.
  ENDMETHOD.

ENDCLASS.
