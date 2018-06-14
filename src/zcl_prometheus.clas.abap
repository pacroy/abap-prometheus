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

    CLASS-DATA: test_mode TYPE abap_bool VALUE abap_false.

    CLASS-METHODS:
      class_constructor,
      set_instance
        IMPORTING i_instance_name TYPE string OPTIONAL,
      set_instance_from_request
        IMPORTING i_request TYPE REF TO if_rest_request.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: instance TYPE REF TO zcl_prometheus.

    DATA: instance_name TYPE string.

    CLASS-METHODS:
      attach_for_update
        RETURNING VALUE(r_result) TYPE REF TO zcl_shr_prometheus_area
        RAISING
                  cx_shm_attach_error,
      attach_for_read
        RETURNING VALUE(r_result) TYPE REF TO zcl_shr_prometheus_area
        RAISING
                  cx_shm_attach_error,
      update_or_append
        IMPORTING
          i_modify_record TYPE zif_prometheus=>t_modify_record
        CHANGING
          c_data          TYPE zif_prometheus=>t_record_table,
      detach
        IMPORTING
          i_shr_area TYPE REF TO zcl_shr_prometheus_area
        RAISING
          cx_shm_already_detached
          cx_shm_completion_error
          cx_shm_secondary_commit
          cx_shm_wrong_handle.
ENDCLASS.



CLASS ZCL_PROMETHEUS IMPLEMENTATION.


  METHOD attach_for_read.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( instance->instance_name ) ).
      CATCH cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_read( inst_name = CONV #( instance->instance_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD attach_for_update.
    TRY.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( instance->instance_name ) ).
      CATCH cx_shm_no_active_version.
        WAIT UP TO 1 SECONDS.
        r_result = zcl_shr_prometheus_area=>attach_for_update( inst_name = CONV #( instance->instance_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD class_constructor.
    instance = NEW #( ).
  ENDMETHOD.


  METHOD detach.
    IF ( test_mode = abap_true ).
      i_shr_area->detach_rollback( ).
    ELSE.
      i_shr_area->detach_commit( ).
    ENDIF.
  ENDMETHOD.


  METHOD set_instance.
    IF ( i_instance_name IS NOT INITIAL ).
      instance->instance_name = i_instance_name.
    ELSE.
      instance->instance_name = cl_shm_area=>default_instance.
    ENDIF.
  ENDMETHOD.


  METHOD set_instance_from_request.
    IF ( i_request IS BOUND ).
      instance->instance_name = i_request->get_uri_attribute( 'instance' ).
      IF ( instance->instance_name IS INITIAL ).
        instance->instance_name = i_request->get_uri_query_parameter( 'instance' ).
        IF ( instance->instance_name IS INITIAL ).
          DATA(segments) = i_request->get_uri_segments( ).
          instance->instance_name = to_upper( segments[ 1 ] ).
        ENDIF.
      ENDIF.
    ELSE.
      instance->instance_name = cl_shm_area=>default_instance.
    ENDIF.
  ENDMETHOD.


  METHOD update_or_append.
    DATA(key) = to_lower( i_modify_record-key ).
    IF line_exists( c_data[ key = key ] ).
      FIELD-SYMBOLS <current_value> TYPE string.
      ASSIGN c_data[ key = key ]-value TO <current_value>.
      TRY.
          CASE i_modify_record-command.
            WHEN zif_prometheus=>c_command-increment.
              <current_value> = <current_value> + i_modify_record-value.
            WHEN OTHERS.
              <current_value> = i_modify_record-value.
          ENDCASE.
          <current_value> = condense( <current_value> ).
        CATCH cx_root.
      ENDTRY.
    ELSE.
      CASE i_modify_record-command.
        WHEN zif_prometheus=>c_command-increment.
          APPEND VALUE #( key = key value = '1' ) TO c_data.
        WHEN OTHERS.
          APPEND VALUE #( key = key value = condense( i_modify_record-value ) ) TO c_data.
      ENDCASE.
      SORT c_data BY key.
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
    DATA(records) = read_all( ).
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
      update_or_append( EXPORTING i_modify_record = <record>  CHANGING c_data = shr_root->data ).
    ENDLOOP.

    detach( shr_area ).
  ENDMETHOD.


  METHOD zif_prometheus~write_single.
    DATA: shr_area TYPE REF TO zcl_shr_prometheus_area,
          shr_root TYPE REF TO zcl_shr_prometheus_root.

    shr_area = attach_for_update( ).
    shr_root = CAST #( shr_area->get_root( ) ).

    update_or_append( EXPORTING i_modify_record = i_record  CHANGING c_data = shr_root->data ).
    detach( shr_area ).
  ENDMETHOD.
ENDCLASS.
