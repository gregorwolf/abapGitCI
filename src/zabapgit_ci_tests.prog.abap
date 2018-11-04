*&---------------------------------------------------------------------*
*& Report ZABAPGIT_CI_TESTS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zabapgit_ci_tests.

PARAMETERS: p_test TYPE flag DEFAULT abap_true.
PARAMETERS: p_delete TYPE flag.

START-OF-SELECTION.

  TYPES: BEGIN OF t_abapgit_repo_with_name,
           name         TYPE string,
           abapgit_repo TYPE REF TO zcl_abapgit_repo,
         END OF t_abapgit_repo_with_name.
  TYPES: tt_abapgit_repo_with_name TYPE STANDARD TABLE OF t_abapgit_repo_with_name WITH KEY name.

  DATA: lt_tt_abapgit_repo_with_name TYPE tt_abapgit_repo_with_name.

  DATA: lo_abapgit_ci TYPE REF TO zcl_abapgit_ci.

  CREATE OBJECT lo_abapgit_ci.

  DATA(lt_repos) = lo_abapgit_ci->get_test_repo_list( ).

  DATA(lt_abapgit_repos) = zcl_abapgit_repo_srv=>get_instance( )->list( ).

  LOOP AT lt_abapgit_repos ASSIGNING FIELD-SYMBOL(<fs_abapgit_repo>).
    APPEND INITIAL LINE TO lt_tt_abapgit_repo_with_name ASSIGNING FIELD-SYMBOL(<fs_abapgit_repo_with_name>).
    <fs_abapgit_repo_with_name>-name = <fs_abapgit_repo>->get_name( ).
    <fs_abapgit_repo_with_name>-abapgit_repo = <fs_abapgit_repo>.
  ENDLOOP.

  LOOP AT lt_repos ASSIGNING FIELD-SYMBOL(<fs_repo>).
    IF p_test = abap_true AND sy-tabix > 3.
      EXIT.
    ENDIF.
    WRITE: / <fs_repo>-name.
    READ TABLE lt_tt_abapgit_repo_with_name WITH KEY name = <fs_repo>-name ASSIGNING <fs_abapgit_repo_with_name>.
    IF sy-subrc <> 0.
      IF p_delete <> abap_true.
        DATA(lv_package) = lo_abapgit_ci->create_local_package_name( <fs_repo>-name  ).
        TRY.
            lo_abapgit_ci->create_package_if_not_existing(
                iv_package = lv_package
                is_repo    = <fs_repo>
            ).
          CATCH zcx_abapgit_exception INTO DATA(ex).
            WRITE: ex->get_longtext( ).
        ENDTRY.
      ENDIF.
    ELSE.
      TRY.
*      " Delete Repository
          DATA: is_checks TYPE zif_abapgit_definitions=>ty_delete_checks.
          IF p_delete = abap_true.
            WRITE: / 'delete'.
            TRY.
                zcl_abapgit_repo_srv=>get_instance( )->purge(
                  EXPORTING
                    io_repo               = <fs_abapgit_repo_with_name>-abapgit_repo
                    is_checks             = is_checks
                ).
              CATCH zcx_abapgit_exception INTO ex.
                WRITE: ex->get_longtext( ).
                zcl_abapgit_repo_srv=>get_instance( )->delete( io_repo = <fs_abapgit_repo_with_name>-abapgit_repo ).
                zcl_abapgit_repo_srv=>get_instance( )->purge(
                  EXPORTING
                    io_repo               = <fs_abapgit_repo_with_name>-abapgit_repo
                    is_checks             = is_checks
                ).
            ENDTRY.
          ENDIF.
        CATCH zcx_abapgit_exception INTO ex.
          WRITE: ex->get_longtext( ).
      ENDTRY.
    ENDIF.
    IF p_delete <> abap_true.
      TRY.
          " Pull Repository
          lo_abapgit_ci->pull( iv_key = <fs_abapgit_repo_with_name>-abapgit_repo->get_key( ) ).
        CATCH zcx_abapgit_exception INTO ex.
          WRITE: ex->get_longtext( ).
      ENDTRY.
    ENDIF.
  ENDLOOP.
