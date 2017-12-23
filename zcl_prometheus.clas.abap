CLASS zcl_prometheus DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    INTERFACES zif_prometheus.
    ALIASES read_all FOR zif_prometheus~read_all.
    ALIASES read_single FOR zif_prometheus~read_single.
    ALIASES write FOR zif_prometheus~write.
    ALIASES delete FOR zif_prometheus~delete.
    ALIASES get_metric_string FOR zif_prometheus~get_metric_string.

    CLASS-METHODS:
      class_constructor,
      get_instance
        IMPORTING i_root          TYPE string OPTIONAL
        RETURNING VALUE(r_result) TYPE REF TO zif_prometheus.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: instance TYPE REF TO zcl_prometheus.

    DATA: root TYPE string.

    METHODS: attach_for_update
      RETURNING VALUE(r_result) TYPE REF TO zcl_shr_prometheus_area
      RAISING
                cx_shm_attach_error,
      attach_for_read
        RETURNING VALUE(r_result) TYPE REF TO zcl_shr_prometheus_area
        RAISING
                  cx_shm_attach_error.
ENDCLASS.



CLASS zcl_prometheus IMPLEMENTATION.

  METHOD attach_for_update.
    DATA wait TYPE i.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( me->root ) ).
      CATCH BEFORE UNWIND cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( me->root ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD attach_for_read.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( me->root ) ).
      CATCH BEFORE UNWIND cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( me->root ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD class_constructor.
    instance = NEW #( ).
  ENDMETHOD.


  METHOD get_instance.
    IF ( i_root IS NOT INITIAL ).
      instance->root = i_root.
    ELSE.
      instance->root = cl_shm_area=>default_instance.
    ENDIF.
    r_result = instance.
  ENDMETHOD.


  METHOD zif_prometheus~delete.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    DATA(key) = to_lower( i_key ).

    shr_area = attach_for_update( ).
    shr_root = CAST #( shr_area->get_root( ) ).
    IF line_exists( shr_root->data[ key = key ] ).
      DELETE shr_root->data WHERE key = key.
    ENDIF.
    shr_area->detach_commit( ).
  ENDMETHOD.


  METHOD zif_prometheus~get_metric_string.
    DATA(records) = me->read_all( ).
    LOOP AT records ASSIGNING FIELD-SYMBOL(<record>).
      r_result = r_result && |# TYPE { <record>-key } gauge\r\n|.
      r_result = r_result && |{ <record>-key } { <record>-value }\r\n|.
    ENDLOOP.
  ENDMETHOD.


  METHOD zif_prometheus~read_all.
    DATA shr_area TYPE REF TO zcl_shr_prometheus_area.

    shr_area = attach_for_read( ).
    r_result = shr_area->root->data.
    shr_area->detach( ).
  ENDMETHOD.


  METHOD zif_prometheus~read_single.
    DATA shr_area TYPE REF TO zcl_shr_prometheus_area.
    DATA(key) = to_lower( i_key ).

    shr_area = attach_for_read( ).
    IF line_exists( shr_area->root->data[ key = key ] ).
      r_result = shr_area->root->data[ key = key ]-value.
    ENDIF.
    shr_area->detach( ).
  ENDMETHOD.


  METHOD zif_prometheus~write.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.
    DATA(key) = to_lower( i_record-key ).

    shr_area = attach_for_update( ).
    shr_root = CAST #( shr_area->get_root( ) ).
    IF line_exists( shr_root->data[ key = key ] ).
      shr_root->data[ key = key ]-value = i_record-value.
    ELSE.
      APPEND VALUE #( key = key value = i_record-value ) TO shr_root->data.
    ENDIF.
    shr_area->detach_commit( ).
  ENDMETHOD.

ENDCLASS.
