FUNCTION z_gos_attach_file_ct.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_OBJECT_TYPE) TYPE  SIBFBORIID
*"     REFERENCE(IV_FILENAME) TYPE  GOS_S_ATTCONT-FILENAME
*"     REFERENCE(IV_FILE_EXTENSION) TYPE  GOS_S_ATTCONT-TECH_TYPE
*"     REFERENCE(IV_FILE_BASE64) TYPE  STRING
*"     REFERENCE(IV_SALES_DOC_ID) TYPE  VBELN_VA
*"  EXCEPTIONS
*"      DECODE_ERROR
*"      GOS_ERROR
*"----------------------------------------------------------------------

  DATA lv_xstring     TYPE xstring.
  DATA ls_appl_object TYPE gos_s_obj.
  DATA lo_gos_api     TYPE REF TO cl_gos_api.
  DATA ls_attcont     TYPE gos_s_attcont.
  DATA lv_commit      TYPE flag.
  DATA lv_objkey      TYPE sibftypeid.
  DATA: lv_vbeln      TYPE vbeln_va.

  " Format VBELN
  CLEAR lv_vbeln.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = iv_sales_doc_id
    IMPORTING
      output = lv_vbeln.

  lv_objkey = lv_vbeln.  "Type sibftypeid

  " Base64 -> XSTRING
  CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
    EXPORTING
      input  = iv_file_base64
    IMPORTING
      output = lv_xstring
    EXCEPTIONS
      failed = 1
      OTHERS = 2.

  IF sy-subrc <> 0 OR lv_xstring IS INITIAL.
    RAISE decode_error.
  ENDIF.

  " Define GOS object (Sales order)
  ls_appl_object-typeid = iv_object_type.  " ej: BUS2032
  ls_appl_object-instid = lv_objkey.       " ej: VBELN
  ls_appl_object-catid  = 'BO'.

  " Creating intance of GOS api
  TRY.
      lo_gos_api = cl_gos_api=>create_instance( ls_appl_object ).
    CATCH cx_gos_api.
      RAISE gos_error.
  ENDTRY.

  " Attachment content
  ls_attcont-atta_cat  = cl_gos_api=>c_msg.
  ls_attcont-filename  = iv_filename.
  ls_attcont-tech_type = iv_file_extension.   " PDF, XLSX, TXT
  ls_attcont-descr     = iv_filename.
  ls_attcont-filesize  = xstrlen( lv_xstring ).
  ls_attcont-content_x = lv_xstring.


  " Insert attach
  TRY.
      lv_commit = lo_gos_api->insert_al_item(
                    is_attcont = ls_attcont
                    iv_roltype = cl_gos_api=>c_attachment ).

      IF lv_commit IS NOT INITIAL.
        COMMIT WORK.
      ENDIF.

    CATCH cx_gos_api.
      RAISE gos_error.
  ENDTRY.


ENDFUNCTION.
