*&---------------------------------------------------------------------*
*& Report  ZCAR_ABAP_PROMETHEUS_EXAMPLE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT z_prometheus_example.

DATA ls_record TYPE zif_prometheus=>t_modify_record.
DATA lo_random_int TYPE REF TO cl_abap_random_int.


START-OF-SELECTION.

  TRY.

      lo_random_int = cl_abap_random_int=>CREATE(
          SEED = sy-uzeit + 1
          MIN  = 1
          MAX  = 25
      ).

    CATCH cx_abap_random.    " Exception for CL_ABAP_RANDOM*
      ASSERT 1 = 2.
  ENDTRY.

  ls_record-key   = sy-sysid && '_' && sy-mandt && '_EXAMPLE'.
  ls_record-value = lo_random_int->get_next( ).

  TRY.
      zcl_prometheus=>set_instance( ).
      zcl_prometheus=>write_single( i_record = ls_record  ).
    CATCH cx_shm_attach_error.    " Exception with Attach
      ASSERT 1 = 2.
  ENDTRY.
