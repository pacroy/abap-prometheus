*"* use this source file for your ABAP unit test classes
CLASS ltcl_base DEFINITION DEFERRED.
CLASS zcl_shr_prometheus_root DEFINITION LOCAL FRIENDS ltcl_base.

CLASS ltcl_base DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
  PROTECTED SECTION.
    DATA: cut  TYPE REF TO zcl_shr_prometheus_root.
  PRIVATE SECTION.
    METHODS:
      setup.
ENDCLASS.

CLASS ltcl_base IMPLEMENTATION.

  METHOD setup.
    me->cut = NEW #( ).
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_test DEFINITION FINAL INHERITING FROM ltcl_base FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS:
      happy_path FOR TESTING RAISING cx_static_check,
      exceptions FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_test IMPLEMENTATION.

  METHOD happy_path.
    DATA(metric1) = VALUE cut->t_key_value( key = `KEY1` value = `VALUE1` ).
    cut->add_metric( metric1 ).
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( cut->metric_table ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric1 act = cut->get_metric( `KEY1` ) ).

    DATA(metric2) = VALUE cut->t_key_value( key = `KEY2` value = `VALUE2` ).
    cut->add_metric( metric2 ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( cut->metric_table ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric1 act = cut->get_metric( `KEY1` ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric2 act = cut->get_metric( `KEY2` ) ).

    DATA(metric3) = VALUE cut->t_key_value( key = `KEY3` value = `VALUE3` ).
    cut->add_metric( metric3 ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( cut->metric_table ) ).

    DATA(metric4) = VALUE cut->t_key_value( key = `KEY2` value = `VALUE2MOD` ).
    cut->update_metric( metric4 ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( cut->metric_table ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric4 act = cut->get_metric( `KEY2` ) ).

    cut->remove_metric( `KEY1` ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( cut->metric_table ) ).
    TRY.
        cut->get_metric( `KEY1` ).
        cl_abap_unit_assert=>fail( 'ZCX_PROMETHEUS not raised' ).
      CATCH zcx_prometheus.
    ENDTRY.

    cut->clear_all_metrics( ).
    cl_abap_unit_assert=>assert_initial( cut->metric_table ).
  ENDMETHOD.

  METHOD exceptions.
    DATA(metric1) = VALUE cut->t_key_value( key = `KEY1` value = `VALUE1` ).
    cut->add_metric( metric1 ).

    DATA(metric2) = VALUE cut->t_key_value( key = `KEY1` value = `VALUE2` ).
    TRY.
        cut->add_metric( metric2 ).
        cl_abap_unit_assert=>fail( 'ZCX_PROMETHEUS not raised' ).
      CATCH zcx_prometheus.
    ENDTRY.
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( cut->metric_table ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric1 act = cut->get_metric( `KEY1` ) ).

    DATA(metric3) = VALUE cut->t_key_value( key = `KEY3` value = `VALUE3` ).
    TRY.
        cut->update_metric( metric3 ).
        cl_abap_unit_assert=>fail( 'ZCX_PROMETHEUS not raised' ).
      CATCH zcx_prometheus.
    ENDTRY.
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( cut->metric_table ) ).
    cl_abap_unit_assert=>assert_equals( exp = metric1 act = cut->get_metric( `KEY1` ) ).

    TRY.
        cut->remove_metric( `KEY3` ).
        cl_abap_unit_assert=>fail( 'ZCX_PROMETHEUS not raised' ).
      CATCH zcx_prometheus.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
