CLASS zcl_shr_prometheus_root DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  SHARED MEMORY ENABLED.

  PUBLIC SECTION.
    TYPES: BEGIN OF t_key_value,
             key   TYPE string,
             value TYPE string,
           END OF t_key_value,
           t_key_value_table TYPE HASHED TABLE OF t_key_value WITH UNIQUE KEY key.

    DATA:
      data TYPE zif_prometheus=>t_record_table.

    INTERFACES if_shm_build_instance.

    METHODS:
      clear_all_metrics,
      add_metric
        IMPORTING i_metric TYPE t_key_value
        RAISING   zcx_prometheus,
      update_metric
        IMPORTING i_metric TYPE t_key_value
        RAISING   zcx_prometheus,
      remove_metric
        IMPORTING i_key TYPE string
        RAISING   zcx_prometheus,
      get_metric
        IMPORTING i_key           TYPE string
        RETURNING VALUE(r_metric) TYPE t_key_value
        RAISING   zcx_prometheus,
      update_or_add_metric
        IMPORTING i_metric TYPE t_key_value
        RAISING   zcx_prometheus,
      get_metric_table
        RETURNING VALUE(r_metric_table) TYPE t_key_value_table.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA: metric_table  TYPE t_key_value_table.
ENDCLASS.



CLASS zcl_shr_prometheus_root IMPLEMENTATION.


  METHOD add_metric.
    INSERT i_metric INTO TABLE metric_table.
    IF ( sy-subrc <> 0 ).
      RAISE EXCEPTION TYPE zcx_prometheus.
    ENDIF.
  ENDMETHOD.


  METHOD clear_all_metrics.
    CLEAR metric_table.
  ENDMETHOD.


  METHOD get_metric.
    TRY.
        r_metric = metric_table[ key = i_key ].
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION TYPE zcx_prometheus.
    ENDTRY.
  ENDMETHOD.


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


  METHOD remove_metric.
    DELETE metric_table WHERE key = i_key.
    IF ( sy-subrc <> 0 ).
      RAISE EXCEPTION TYPE zcx_prometheus.
    ENDIF.
  ENDMETHOD.


  METHOD update_metric.
    READ TABLE metric_table WITH KEY key = i_metric-key ASSIGNING FIELD-SYMBOL(<metric>).
    IF ( sy-subrc = 0 ).
      <metric>-value = i_metric-value.
    ELSE.
      RAISE EXCEPTION TYPE zcx_prometheus.
    ENDIF.
  ENDMETHOD.


  METHOD update_or_add_metric.
    TRY.
        update_metric( i_metric ).
      CATCH zcx_prometheus.
        add_metric( i_metric ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_metric_table.
    r_metric_table = metric_table.
  ENDMETHOD.

ENDCLASS.
