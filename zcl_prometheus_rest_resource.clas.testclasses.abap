*"* use this source file for your ABAP unit test classes

CLASS ltcl_base DEFINITION DEFERRED.
CLASS zcl_prometheus_rest_resource DEFINITION LOCAL FRIENDS ltcl_base.

CLASS ltcl_base DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
  PROTECTED SECTION.
    DATA: cut  TYPE REF TO zcl_prometheus_rest_resource.
  PRIVATE SECTION.
    METHODS:
      setup.
ENDCLASS.

CLASS ltcl_base IMPLEMENTATION.

  METHOD setup.
    me->cut = NEW #( ).
  ENDMETHOD.

ENDCLASS.

class ltcl_get definition final inheriting from ltcl_base for testing
  duration short
  risk level harmless.

  private section.
    methods:
      happy_path for testing raising cx_static_check.
endclass.


class ltcl_get implementation.

  method happy_path.
  endmethod.

endclass.
