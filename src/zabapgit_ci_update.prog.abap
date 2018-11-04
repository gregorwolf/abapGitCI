*&---------------------------------------------------------------------*
*& Report ZABAPGIT_CI_UPDATE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zabapgit_ci_update.

START-OF-SELECTION.

  DATA: lo_repo   TYPE REF TO zcl_abapgit_repo_online,
        ls_checks TYPE zif_abapgit_definitions=>ty_deserialize_checks.

  DATA: lo_abapgit_ci TYPE REF TO zcl_abapgit_ci.

  CREATE OBJECT lo_abapgit_ci.

  TRY.
      DATA(lt_repo_list) = zcl_abapgit_repo_srv=>get_instance( )->list( ).
      LOOP AT lt_repo_list ASSIGNING FIELD-SYMBOL(<fs_repo>).

        CASE  <fs_repo>->get_name( ).
          WHEN 'abapGit'.
            lo_abapgit_ci->pull( iv_key = <fs_repo>->get_key( ) ).
        ENDCASE.
      ENDLOOP.
    CATCH zcx_abapgit_exception INTO DATA(ex).
      WRITE: / ex->get_longtext( ).
  ENDTRY.

*  ls_checks = lo_repo->deserialize_checks( ).
*
** the code must decide what to do with warnings, see example below
*  ls_checks = decisions( ls_checks ).
*
*  lo_repo->deserialize( ls_checks ).
