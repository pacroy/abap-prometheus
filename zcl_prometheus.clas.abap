CLASS zcl_prometheus DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES zif_prometheus.
    ALIASES read_all FOR zif_prometheus~read_all.
    ALIASES read_single FOR zif_prometheus~read_single.
    ALIASES write FOR zif_prometheus~write.
    ALIASES delete FOR zif_prometheus~delete.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS attach_for_update
      IMPORTING
                i_root          TYPE string
      RETURNING VALUE(r_result) TYPE REF TO zcl_shr_prometheus_area
      RAISING
                cx_shm_attach_error.
ENDCLASS.



CLASS zcl_prometheus IMPLEMENTATION.


  METHOD attach_for_update.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( i_root ) ).
      CATCH cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( i_root ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD zif_prometheus~delete.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    DATA(key) = to_lower( i_key ).

    shr_area = attach_for_update( i_root ).
    shr_root = CAST #( shr_area->get_root( ) ).
    IF line_exists( shr_root->data[ key = key ] ).
      DELETE shr_root->data WHERE key = key.
    ENDIF.
    shr_area->detach_commit( ).
  ENDMETHOD.


  METHOD zif_prometheus~read_all.
    DATA shr_area TYPE REF TO zcl_shr_prometheus_area.

    shr_area = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( i_root ) ).
    r_result = shr_area->root->data.
    shr_area->detach( ).
  ENDMETHOD.


  METHOD zif_prometheus~read_single.
    DATA shr_area TYPE REF TO zcl_shr_prometheus_area.
    DATA(key) = to_lower( i_key ).

    shr_area = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( i_root ) ).
    IF line_exists( shr_area->root->data[ key = key ] ).
      r_result = shr_area->root->data[ key = key ]-value.
    ENDIF.
    shr_area->detach( ).
  ENDMETHOD.


  METHOD zif_prometheus~write.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.
    DATA(key) = to_lower( i_record-key ).

    shr_area = attach_for_update( i_root ).
    shr_root = CAST #( shr_area->get_root( ) ).
    IF line_exists( shr_root->data[ key = key ] ).
      shr_root->data[ key = key ]-value = i_record-value.
    ELSE.
      APPEND VALUE #( key = key value = i_record-value ) TO shr_root->data.
    ENDIF.
    shr_area->detach_commit( ).
  ENDMETHOD.
ENDCLASS.
