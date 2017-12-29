*"* use this source file for your ABAP unit test classes

CLASS ltcl_base DEFINITION DEFERRED.
CLASS zcl_prometheus DEFINITION LOCAL FRIENDS ltcl_base.

CLASS ltcl_base DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      setup,
      teardown.
ENDCLASS.

CLASS ltcl_base IMPLEMENTATION.

  METHOD setup.
    zcl_prometheus=>set_instance( 'ABAPUNIT' ).
  ENDMETHOD.

  METHOD teardown.
    zcl_shr_prometheus_area=>free_instance( 'ABAPUNIT'  ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_basic DEFINITION FINAL INHERITING FROM ltcl_base FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      happy_path FOR TESTING RAISING cx_static_check,
      increment FOR TESTING RAISING cx_static_check,
      test_mode FOR TESTING RAISING cx_static_check,
      set_inst_from_attr FOR TESTING RAISING cx_static_check,
      set_inst_from_query FOR TESTING RAISING cx_static_check,
      set_inst_from_unspecified FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_basic IMPLEMENTATION.

  METHOD happy_path.
    zcl_prometheus=>write_single( i_record = VALUE #( key = 'TEST{id="1"}' value = '123456' ) ).
    zcl_prometheus=>write_single( i_record = VALUE #( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '123000' act = zcl_prometheus=>read_single( 'TEST{id="1"}' ) ).

    zcl_prometheus=>write_multiple( VALUE #( ( key = 'TEST{id="2"}' value = '456789' )
                                      ( key = 'TEST{id="3"}' value = '789123' ) ) ).
    DATA(records) = zcl_prometheus=>read_all( ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123456' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="2"}' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="3"}' value = '789123' ) ).

    zcl_prometheus=>delete( 'test{id="2"}' ).
    records = zcl_prometheus=>read_all( ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="1"}' value = '123000' ) ).
    cl_abap_unit_assert=>assert_table_not_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="2"}' value = '456789' ) ).
    cl_abap_unit_assert=>assert_table_contains( table = records line = VALUE zif_prometheus=>t_record( key = 'test{id="3"}' value = '789123' ) ).

    DATA(metric_str) = |test\{id="1"\} 123000\r\ntest\{id="3"\} 789123\r\n|.
    cl_abap_unit_assert=>assert_equals( exp = metric_str act = zcl_prometheus=>get_metric_string( ) ).
  ENDMETHOD.

  METHOD increment.
    zcl_prometheus=>write_single( i_record = VALUE #( key = 'TEST' value = '1' command = zif_prometheus=>c_command-increment ) ).
    cl_abap_unit_assert=>assert_equals( exp = '1' act = zcl_prometheus=>read_single( 'TEST' ) ).
    zcl_prometheus=>write_single( i_record = VALUE #( key = 'TEST' value = '2' command = zif_prometheus=>c_command-increment ) ).
    cl_abap_unit_assert=>assert_equals( exp = '3' act = zcl_prometheus=>read_single( 'TEST' ) ).
  ENDMETHOD.

  METHOD test_mode.
    zcl_prometheus=>test_mode = abap_true.

    zcl_prometheus=>write_single( i_record = VALUE #( key = 'TEST' value = '5' ) ).
    cl_abap_unit_assert=>assert_equals( exp = space act = zcl_prometheus=>read_single( 'TEST' ) ).
    zcl_prometheus=>write_single( i_record = VALUE #( key = 'TEST' value = '1' command = zif_prometheus=>c_command-increment ) ).
    cl_abap_unit_assert=>assert_equals( exp = space act = zcl_prometheus=>read_single( 'TEST' ) ).

    zcl_prometheus=>test_mode = abap_false.
  ENDMETHOD.

  METHOD set_inst_from_attr.
    DATA(rest_request) = CAST if_rest_request( cl_abap_testdouble=>create( 'IF_REST_REQUEST' ) ) ##NO_TEXT.
    cl_abap_testdouble=>configure_call( rest_request )->returning( `ATTRIBUTE` ).
    rest_request->get_uri_attribute( 'instance' ).
    cl_abap_testdouble=>configure_call( rest_request )->returning( VALUE string_table( ( `FIRST` ) ( `SECOND` ) ( `THIRD` ) ) ).
    rest_request->get_uri_segments( ).

    zcl_prometheus=>set_instance_from_request( rest_request ).

    cl_abap_unit_assert=>assert_equals( exp = 'ATTRIBUTE' act = zcl_prometheus=>instance->instance_name ).
  ENDMETHOD.

  METHOD set_inst_from_query.
    DATA(rest_request) = CAST if_rest_request( cl_abap_testdouble=>create( 'IF_REST_REQUEST' ) ) ##NO_TEXT.
    cl_abap_testdouble=>configure_call( rest_request )->returning( `` ).
    rest_request->get_uri_attribute( 'instance' ).
    cl_abap_testdouble=>configure_call( rest_request )->returning( `QUERY` ).
    rest_request->get_uri_query_parameter( 'instance' ).
    cl_abap_testdouble=>configure_call( rest_request )->returning( VALUE string_table( ( `FIRST` ) ( `SECOND` ) ( `THIRD` ) ) ).
    rest_request->get_uri_segments( ).

    zcl_prometheus=>set_instance_from_request( rest_request ).

    cl_abap_unit_assert=>assert_equals( exp = 'QUERY' act = zcl_prometheus=>instance->instance_name ).
    cl_abap_testdouble=>verify_expectations(  rest_request ).
  ENDMETHOD.

  METHOD set_inst_from_unspecified.
    DATA(rest_request) = CAST if_rest_request( cl_abap_testdouble=>create( 'IF_REST_REQUEST' ) ) ##NO_TEXT.
    cl_abap_testdouble=>configure_call( rest_request )->returning( `` ).
    rest_request->get_uri_attribute( 'instance' ).
    cl_abap_testdouble=>configure_call( rest_request )->returning( `` ).
    rest_request->get_uri_query_parameter( 'instance' ).
    cl_abap_testdouble=>configure_call( rest_request )->returning( VALUE string_table( ( `FIRST` ) ( `SECOND` ) ( `THIRD` ) ) ).
    rest_request->get_uri_segments( ).

    zcl_prometheus=>set_instance_from_request( rest_request ).

    cl_abap_unit_assert=>assert_equals( exp = 'FIRST' act = zcl_prometheus=>instance->instance_name ).
    cl_abap_testdouble=>verify_expectations(  rest_request ).
  ENDMETHOD.

ENDCLASS.
