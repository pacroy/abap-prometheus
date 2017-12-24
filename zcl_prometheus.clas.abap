CLASS zcl_prometheus DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    INTERFACES zif_prometheus.
    ALIASES read_all FOR zif_prometheus~read_all.
    ALIASES read_single FOR zif_prometheus~read_single.
    ALIASES write_single FOR zif_prometheus~write_single.
    ALIASES write_multiple FOR zif_prometheus~write_multiple.
    ALIASES delete FOR zif_prometheus~delete.
    ALIASES get_metric_string FOR zif_prometheus~get_metric_string.

    CLASS-METHODS:
      class_constructor,
      get_instance
        IMPORTING i_root          TYPE string OPTIONAL
        RETURNING VALUE(r_result) TYPE REF TO zif_prometheus,
      get_instance_from_rest_request
        IMPORTING i_request       TYPE REF TO if_rest_request
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
                  cx_shm_attach_error,
      update_or_append
        IMPORTING
          i_record TYPE zif_prometheus=>t_record
        CHANGING
          c_data   TYPE zif_prometheus=>t_record_table.
ENDCLASS.



CLASS zcl_prometheus IMPLEMENTATION.


  METHOD attach_for_read.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( me->root ) ).
      CATCH cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( me->root ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD attach_for_update.
    DATA wait TYPE i.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( me->root ) ).
      CATCH cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( me->root ) ).
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


  METHOD get_instance_from_rest_request.
    IF ( i_request IS BOUND ).
      DATA(segments) = i_request->get_uri_segments( ).
      instance->root = to_upper( segments[ 1 ] ).
    ELSE.
      instance->root = cl_shm_area=>default_instance.
    ENDIF.
    r_result = instance.
  ENDMETHOD.


  METHOD update_or_append.
    DATA(key) = to_lower( i_record-key ).
    IF line_exists( c_data[ key = key ] ).
      FIELD-SYMBOLS <current_value> TYPE string.
      ASSIGN c_data[ key = key ]-value TO <current_value>.
      TRY.
          CASE i_record-value.
            WHEN '$INC'.  "Increment
              <current_value> = <current_value> + 1.
            WHEN OTHERS.
              <current_value> = i_record-value.
          ENDCASE.
          <current_value> = condense( <current_value> ).
        CATCH cx_root.
      ENDTRY.
    ELSE.
      IF ( i_record-value = '$INC' ).
        APPEND VALUE #( key = key value = '1' ) TO c_data.
      ELSE.
        APPEND VALUE #( key = key value = condense( i_record-value ) ) TO c_data.
      ENDIF.
    ENDIF.
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


  METHOD zif_prometheus~write_multiple.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    shr_area = attach_for_update( ).
    shr_root = CAST #( shr_area->get_root( ) ).

    LOOP AT i_record_table ASSIGNING FIELD-SYMBOL(<record>).
      me->update_or_append( EXPORTING i_record = <record>  CHANGING c_data = shr_root->data ).
    ENDLOOP.

    shr_area->detach_commit( ).
  ENDMETHOD.


  METHOD zif_prometheus~write_single.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    shr_area = attach_for_update( ).
    shr_root = CAST #( shr_area->get_root( ) ).

    me->update_or_append( EXPORTING i_record = i_record  CHANGING c_data = shr_root->data ).
    shr_area->detach_commit( ).
  ENDMETHOD.
ENDCLASS.
