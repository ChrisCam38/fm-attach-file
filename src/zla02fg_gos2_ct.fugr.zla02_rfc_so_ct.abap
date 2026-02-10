FUNCTION zla02_rfc_so_ct.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_DOC_TYPE) TYPE  AUART OPTIONAL
*"     VALUE(IV_SALES_ORG) TYPE  VKORG OPTIONAL
*"     VALUE(IV_DISTR_CHAN) TYPE  VTWEG OPTIONAL
*"     VALUE(IV_DIVISION) TYPE  SPART OPTIONAL
*"     VALUE(IV_SOLD_TO) TYPE  KUNNR OPTIONAL
*"     VALUE(IV_TEST_RUN) TYPE  CHAR1 OPTIONAL
*"     VALUE(IV_FILENAME) TYPE  GOS_S_ATTCONT-FILENAME OPTIONAL
*"     VALUE(IV_FILE_EXTENSION) TYPE  GOS_S_ATTCONT-TECH_TYPE OPTIONAL
*"     VALUE(IV_FILE_BASE64) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(EV_SALESDOC) TYPE  VBELN_VA
*"     VALUE(EV_RESULT) TYPE  STRING
*"     VALUE(EV_ATTACH_RESULT) TYPE  STRING
*"----------------------------------------------------------------------
  " Nuevo: resultado del attachment
  " Variables locales
  DATA: lv_doc_type   TYPE auart,
        lv_sales_org  TYPE vkorg,
        lv_distr_chan TYPE vtweg,
        lv_division   TYPE spart,
        lv_sold_to    TYPE kunnr,
        lv_test_run   TYPE char1,
        lv_salesdoc   TYPE vbeln_va.

  " Valores por defecto si vienen vacíos
  lv_doc_type   = COND #( WHEN iv_doc_type   IS NOT INITIAL THEN iv_doc_type   ELSE 'TA' ).
  lv_sales_org  = COND #( WHEN iv_sales_org  IS NOT INITIAL THEN iv_sales_org  ELSE '1710' ).
  lv_distr_chan = COND #( WHEN iv_distr_chan IS NOT INITIAL THEN iv_distr_chan ELSE '10' ).
  lv_division   = COND #( WHEN iv_division   IS NOT INITIAL THEN iv_division   ELSE '00' ).
  lv_sold_to    = COND #( WHEN iv_sold_to    IS NOT INITIAL THEN iv_sold_to    ELSE 'USCU_L09' ).

  " Llamada al FM que crea la Sales Order
  CALL FUNCTION 'ZLA02_CREATESO_MR'
    EXPORTING
      doc_type   = lv_doc_type
      sales_org  = lv_sales_org
      distr_chan = lv_distr_chan
      division   = lv_division
      sold_to    = lv_sold_to
      test_run   = space
    IMPORTING
      sales_doc  = lv_salesdoc.

  " Validar si se creó la Sales Order
  IF lv_salesdoc IS INITIAL.
    ev_result = 'ERROR - No se pudo crear la Sales Order'.
    CLEAR ev_salesdoc.
    CLEAR ev_attach_result.
    RETURN.
  ENDIF.

  ev_salesdoc = lv_salesdoc.
  ev_result   = |OK - Sales Order creada: { ev_salesdoc }|.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
    EXPORTING
      wait = 'X'.

  " Si se proporcionaron datos del archivo, adjuntarlo
  IF iv_file_base64 IS NOT INITIAL AND
     iv_filename IS NOT INITIAL.

    CALL FUNCTION 'Z_GOS_ATTACH_FILE_CT'
      EXPORTING
        iv_object_type    = 'BUS2032'
        iv_sales_doc_id   = lv_salesdoc
        iv_filename       = iv_filename
        iv_file_extension = iv_file_extension
        iv_file_base64    = iv_file_base64
      EXCEPTIONS
        decode_error      = 1
        gos_error         = 2
        OTHERS            = 3.

    CASE sy-subrc.
      WHEN 0.
        ev_attach_result = |OK - Archivo '{ iv_filename }' adjuntado correctamente|.
      WHEN 1.
        ev_attach_result = 'ERROR - Fallo al decodificar Base64'.
      WHEN 2.
        ev_attach_result = 'ERROR - Fallo en conversión de formato'.
      WHEN OTHERS.
        ev_attach_result = |ERROR - Fallo desconocido ({ sy-subrc })|.
    ENDCASE.

  ELSE.
    " No se proporcionaron datos de archivo
    ev_attach_result = 'INFO - No se proporcionó archivo para adjuntar'.

  ENDIF.


ENDFUNCTION.
