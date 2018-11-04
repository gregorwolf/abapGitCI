class ZCL_ABAPGIT_CI definition
  public
  create public .

public section.

  methods CREATE_LOCAL_PACKAGE_NAME
    importing
      !IV_REPO_NAME type STRING
    returning
      value(RV_PACKAGE) type DEVCLASS .
  methods CREATE_PACKAGE_IF_NOT_EXISTING
    importing
      !IV_PACKAGE type DEVCLASS
      !IS_REPO type ZABAPGIT_CI_REPO
    raising
      ZCX_ABAPGIT_EXCEPTION .
  methods PULL
    importing
      !IV_KEY type ZIF_ABAPGIT_PERSISTENCE=>TY_VALUE
    raising
      ZCX_ABAPGIT_EXCEPTION .
  methods DECISIONS
    importing
      !IS_CHECKS type ZIF_ABAPGIT_DEFINITIONS=>TY_DESERIALIZE_CHECKS
    returning
      value(RS_CHECKS) type ZIF_ABAPGIT_DEFINITIONS=>TY_DESERIALIZE_CHECKS .
  methods GET_TEST_REPO_LIST
    returning
      value(RT_REPOS) type ZABAPGIT_CI_REPOS .
  PROTECTED SECTION.
private section.
ENDCLASS.



CLASS ZCL_ABAPGIT_CI IMPLEMENTATION.


  METHOD create_local_package_name.
    rv_package = '$' && iv_repo_name.
    TRANSLATE rv_package TO UPPER CASE.
  ENDMETHOD.


  METHOD create_package_if_not_existing.
    DATA: lo_package TYPE REF TO zif_abapgit_sap_package.
    lo_package ?= zcl_abapgit_factory=>get_sap_package( iv_package = iv_package ).
    IF NOT lo_package->exists( ).
      lo_package->create_local( ).
      zcl_abapgit_repo_srv=>get_instance( )->validate_package( iv_package = iv_package  ).
      DATA(lo_repo) = zcl_abapgit_repo_srv=>get_instance( )->new_online(
        iv_url         = is_repo-clone_url
        iv_branch_name = 'refs/heads/' && is_repo-default_branch
        iv_package     = iv_package ).
    ENDIF.
  ENDMETHOD.


  METHOD decisions.

* this part can be handled by presenting the warings to the user in UI, or set via logic in code
* this is an example, adjust to fit your business requirements

    rs_checks = is_checks.

    LOOP AT rs_checks-overwrite ASSIGNING FIELD-SYMBOL(<ls_overwrite>).
* Object has been modified locally
* decision field must be filled with Y or N. Y overwrites the object
      <ls_overwrite>-decision = 'Y'.
    ENDLOOP.

    LOOP AT rs_checks-warning_package ASSIGNING FIELD-SYMBOL(<ls_warning_package>).
* Y or N if object from unexpected package should be overwritten
      <ls_warning_package>-decision = 'Y'.
    ENDLOOP.

    IF rs_checks-requirements-met = 'N'.
* code must decide if deserialization should continue or not
      rs_checks-requirements-decision = 'Y'.
    ENDIF.

    IF rs_checks-transport-required = abap_true.
      rs_checks-transport-transport = 'SOMETHING'.
    ENDIF.

  ENDMETHOD.


  METHOD get_test_repo_list.
    DATA: lv_url TYPE string VALUE 'https://api.github.com/orgs/abapGit-tests/repos'.
    DATA: lo_rest_client TYPE REF TO if_rest_client.

    cl_http_client=>create_by_url(
      EXPORTING
        url                = lv_url    " URL
        ssl_id             = 'ANONYM'     " SSL Identity
      IMPORTING
        client             = DATA(lo_http_client)    " HTTP Client Abstraction
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    TRY.

        CREATE OBJECT lo_rest_client TYPE cl_rest_http_client
          EXPORTING
            io_http_client = lo_http_client.

        lo_rest_client->get( ).
        DATA(lv_status) = lo_rest_client->get_status( ).

        IF lv_status = 200.
          DATA(lo_response) = lo_rest_client->get_response_entity( ).
          DATA(lv_content) = lo_response->get_string_data( ).

          /ui2/cl_json=>deserialize(
            EXPORTING
              json             =  lv_content   " JSON string
*    pretty_name      =     " Pretty Print property names
            CHANGING
              data             =  rt_repos   " Data to serialize
          ).

        ENDIF.

      CATCH cx_rest_client_exception INTO DATA(ex).
        WRITE: / ex->get_longtext( ).
    ENDTRY.

  ENDMETHOD.


  METHOD pull.

    DATA: lo_repo   TYPE REF TO zcl_abapgit_repo_online,
          ls_checks TYPE zif_abapgit_definitions=>ty_deserialize_checks.

    lo_repo ?= zcl_abapgit_repo_srv=>get_instance( )->get( iv_key ).

    ls_checks = lo_repo->deserialize_checks( ).

* the code must decide what to do with warnings, see example below
    ls_checks = decisions( ls_checks ).

    lo_repo->deserialize( ls_checks ).

  ENDMETHOD.
ENDCLASS.
