CLASS zcl_shr_prometheus_root DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  SHARED MEMORY ENABLED.

  PUBLIC SECTION.
    DATA:
      data TYPE zif_prometheus=>t_record_table.

    INTERFACES if_shm_build_instance.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_shr_prometheus_root IMPLEMENTATION.

  METHOD if_shm_build_instance~build.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    TRY.
        shr_area = zcl_shr_prometheus_area=>attach_for_write( inst_name = inst_name  ).
      CATCH cx_shm_attach_error.
    ENDTRY.

    CREATE OBJECT shr_root AREA HANDLE shr_area.
    shr_area->set_root( shr_root ).
    shr_area->detach_commit( ).
  ENDMETHOD.

ENDCLASS.
