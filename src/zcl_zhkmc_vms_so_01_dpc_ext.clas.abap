class ZCL_ZHKMC_VMS_SO_01_DPC_EXT definition
  public
  inheriting from ZCL_ZHKMC_VMS_SO_01_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_EXPANDED_ENTITYSET
    redefinition .
protected section.

  methods SALESORDERSET_CREATE_ENTITY
    redefinition .
  methods SALESORDERSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZHKMC_VMS_SO_01_DPC_EXT IMPLEMENTATION.


  METHOD /iwbep/if_mgw_appl_srv_runtime~get_expanded_entityset.
    DATA : lt_deep_entity TYPE TABLE OF zcl_zhkmc_vms_so_01_mpc_ext=>ty_deep_entity, "Deep Entity Type
           ls_deep_entity TYPE zcl_zhkmc_vms_so_01_mpc_ext=>ty_deep_entity.         "Deep Entity Type

    DATA: order_headers_out     TYPE TABLE OF bapisdhd,
          order_items_out       TYPE TABLE OF  bapisdit,
          order_schedules_out   TYPE  TABLE OF bapisdhedu,
          order_partners_out    TYPE  TABLE OF  bapisdpart,
          order_address_out     TYPE TABLE OF bapisdcoad,
          order_cfgs_curefs_out TYPE TABLE OF bapicurefm,
          order_cfgs_cuins_out  TYPE TABLE OF bapicuinsm,
          order_cfgs_cuvals_out TYPE TABLE OF  bapicuvalm.

    DATA : it_vbeln type table of sales_key,
           s_vbeln    TYPE  range of vbak-vbeln,
           wa_vbeln    like line of s_vbeln,
           s_matnr     TYPE RANGE OF mara-matnr,
           wa_matnr    LIKE LINE OF s_matnr,
           s_sp_kunnr  TYPE RANGE OF vbpa-kunnr,
           wa_sp_kunnr LIKE LINE OF s_sp_kunnr,
           s_vkorg     TYPE RANGE OF vbak-vkorg,
           wa_vkorg    LIKE LINE OF s_vkorg.

    IF iv_entity_set_name = 'SO_SEARCH'.


      DATA(lt_filter_select_options) = io_tech_request_context->get_filter( )->get_filter_select_options( ).


      IF lines(  lt_filter_select_options ) = 0.
        DATA: message TYPE string VALUE `Please specific $filter=Material eq 'xxx' and SalesOrg eq 'xxx' and SoldToParty = 'xxxx' `.
*      CONCATENATE 'Corresponding Sales Orders not exist' INTO message.
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = message.
      ENDIF.

      LOOP AT  lt_filter_select_options ASSIGNING FIELD-SYMBOL(<fs_filter>) .
        LOOP AT <fs_filter>-select_options ASSIGNING FIELD-SYMBOL(<fs_select_op>).

          CASE <fs_filter>-property.

            WHEN 'MATERIAL'.
              wa_matnr-option = 'EQ'.
              wa_matnr-sign = 'I'.
              wa_matnr-low = <fs_select_op>-low.
              APPEND wa_matnr TO s_matnr.

            WHEN 'SALESORG'.
              wa_vkorg-option = 'EQ'.
              wa_vkorg-sign = 'I'.
              wa_vkorg-low = <fs_select_op>-low.
              APPEND wa_vkorg TO s_vkorg.

            WHEN 'SOLDTOPARTY'.
              wa_sp_kunnr-option = 'EQ'.
              wa_sp_kunnr-sign = 'I'.

              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = <fs_select_op>-low
                IMPORTING
                  output = wa_sp_kunnr-low.
**      .
              APPEND wa_sp_kunnr TO s_sp_kunnr.
              when 'DOC_NUMBER'.

              wa_vbeln-option = 'EQ'.
              wa_vbeln-sign = 'I'.

               CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = <fs_select_op>-low
                IMPORTING
                  output =  WA_VBELN-LOW.

               append wa_vbeln to s_vbeln.

          ENDCASE.

        ENDLOOP.

      ENDLOOP.


      SELECT h~vbeln FROM vbak AS h JOIN vbap AS i ON h~vbeln = i~vbeln
                                  JOIN vbpa AS p ON h~vbeln = p~vbeln
                  INTO TABLE it_vbeln
                   WHERE i~matnr IN s_matnr
                     AND p~kunnr IN s_sp_kunnr
                     AND p~parvw = 'AG' "SOLD-TO-PARTY
                     AND h~vkorg IN s_vkorg
                     AND H~VBELN IN S_VBELN.



*    ELSEIF iv_entity_set_name = 'SO_HEADER'.


*      lt_filter_select_options = io_tech_request_context->get_filter( )->get_filter_select_options( ).
*
*      IF lines(  lt_filter_select_options ) = 0.
*        message =  `Please specific $filter=DocNumber eq 'xxxxx' `.
**      CONCATENATE 'Corresponding Sales Orders not exist' INTO message.
*        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
*          EXPORTING
*            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
*            message_unlimited = message.
*      ENDIF.


*      LOOP AT  lt_filter_select_options ASSIGNING <fs_filter> WHERE property = 'DOC_NUMBER'.
*        LOOP AT <fs_filter>-select_options ASSIGNING FIELD-SYMBOL(<fs_vbeln>).
*
**
*          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*            EXPORTING
*              input  = <fs_vbeln>-low
*            IMPORTING
*              output = wa_vbeln.
***      .
*          APPEND wa_vbeln TO it_vbeln.
*        ENDLOOP.
*
*      ENDLOOP.



      DATA:  ls_ord_view       TYPE  order_view.

      ls_ord_view-header      = abap_true.
      ls_ord_view-item        = abap_true.
      ls_ord_view-sdschedule  = abap_true.
*      ls_ord_view-business    = abap_true.
      ls_ord_view-partner     = abap_true.
      ls_ord_view-address     = abap_true.
*      ls_ord_view-status_h    = abap_true.
*      ls_ord_view-status_i    = abap_true.
*      ls_ord_view-sdcond      = abap_true.
*      ls_ord_view-sdcond_add  = abap_true.
*      ls_ord_view-contract    = abap_true.
*      ls_ord_view-text        = abap_true.
*      ls_ord_view-flow        = abap_true.
*      ls_ord_view-billplan    = abap_true.
      ls_ord_view-configure   = abap_true.
*      ls_ord_view-credcard    = abap_true.
*      ls_ord_view-incomp_log  = abap_true.


      CALL FUNCTION 'BAPISDORDER_GETDETAILEDLIST'
        EXPORTING
          i_bapi_view           = ls_ord_view
*         I_MEMORY_READ         =
*         I_WITH_HEADER_CONDITIONS       = ' '
        TABLES
          sales_documents       = it_vbeln
          order_headers_out     = order_headers_out
          order_items_out       = order_items_out
          order_schedules_out   = order_schedules_out
*         ORDER_BUSINESS_OUT    =
          order_partners_out    = order_partners_out
          order_address_out     = order_address_out
*         ORDER_STATUSHEADERS_OUT        =
*         ORDER_STATUSITEMS_OUT =
*         ORDER_CONDITIONS_OUT  =
*         ORDER_COND_HEAD       =
*         ORDER_COND_ITEM       =
*         ORDER_COND_QTY_SCALE  =
*         ORDER_COND_VAL_SCALE  =
*         ORDER_CONTRACTS_OUT   =
*         ORDER_TEXTHEADERS_OUT =
*         ORDER_TEXTLINES_OUT   =
*         ORDER_FLOWS_OUT       =
          order_cfgs_curefs_out = order_cfgs_curefs_out
*         ORDER_CFGS_CUCFGS_OUT =
          order_cfgs_cuins_out  = order_cfgs_cuins_out
*         ORDER_CFGS_CUPRTS_OUT =
          order_cfgs_cuvals_out = order_cfgs_cuvals_out
*         ORDER_CFGS_CUBLBS_OUT =
*         ORDER_CFGS_CUVKS_OUT  =
*         ORDER_BILLINGPLANS_OUT         =
*         ORDER_BILLINGDATES_OUT         =
*         ORDER_CREDITCARDS_OUT =
*         EXTENSIONOUT          =
        .

      IF lines( order_headers_out ) = 0.
        message = 'Corresponding Sales Orders not exist'.
*      CONCATENATE 'Corresponding Sales Orders not exist' INTO message.
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_busi_exception=>business_error_unlimited
            message_unlimited = message.
      ENDIF.
      DATA: s_atnam  TYPE RANGE OF cabn-atnam,
            wa_atnam LIKE LINE OF s_atnam.

      LOOP AT order_cfgs_cuvals_out ASSIGNING FIELD-SYMBOL(<fs_config>).
        wa_atnam-low = <fs_config>-charc.
        APPEND wa_atnam TO s_atnam.
      ENDLOOP.

      IF s_atnam[] IS NOT INITIAL.

        SELECT a~atnam, at~atbez, b~atwrt, c~atwtb
         FROM cabn AS a
          JOIN cabnt AS at
          ON  a~atinn = at~atinn
          AND a~adzhl = at~adzhl
          JOIN cawn AS b
         ON   a~atinn = b~atinn
         AND  a~adzhl = b~adzhl
         JOIN cawnt AS c
          ON  b~atinn = c~atinn
         AND  b~atzhl = c~atzhl
         INTO TABLE @DATA(lt_char_text)
         FOR ALL ENTRIES IN @s_atnam
         WHERE a~atnam = @s_atnam-low
         AND  at~spras = 'E'
         AND   c~spras = 'E'
         AND   c~lkenz = @space.
      ENDIF.

      select parvw, VTEXT FROM TPART INTO TABLE @data(IT_PARTNER_ROLE) where spras = 'E'.



      "header
      ls_deep_entity-doc_number = wa_vbeln-low.
      ls_deep_entity-material = wa_matnr-low.
      ls_deep_entity-salesorg = wa_vkorg-low.
      ls_deep_entity-soldtoparty = wa_sp_kunnr-low.

      ls_deep_entity-searchtoheader = CORRESPONDING #( order_headers_out ).

      LOOP AT  ls_deep_entity-searchtoheader ASSIGNING FIELD-SYMBOL(<fs_header>).
       <FS_HEADER>-headertoitem = VALUE #( FOR ls_item IN  order_items_out WHERE ( doc_number = <fs_header>-doc_number )
                                         ( doc_number = ls_item-doc_number
                                           itm_number = ls_item-itm_number
                                           material = ls_item-material
                                           plant = ls_item-plant
                                           store_loc  = ls_item-stge_loc
                                           itemtoschedule = VALUE #( FOR <fs_schedule> in order_schedules_out where ( doc_number =  ls_item-doc_number  and itm_number = ls_item-itm_number )
                                           (    doc_number =  <fs_schedule>-doc_number
                                                itm_number =  <fs_schedule>-itm_number
                                                sched_line =  <fs_schedule>-sched_line
                                                req_date   =  <fs_schedule>-req_date
                                                req_qty    =  <fs_schedule>-req_qty
                                                confir_qty =  <fs_schedule>-confir_qty
                                                sales_unit =  <fs_schedule>-sales_unit
                                                avail_con  =  <fs_schedule>-avail_con
                                                tp_date =  <fs_schedule>-tp_date
                                                load_date =  <fs_schedule>-load_date
                                                                        gi_date =  <fs_schedule>-gi_date ) )
                                         itemtopartner = value #( for <fs_partner> in order_partners_out where ( sd_doc =  ls_item-doc_number )
                                                                  for <fs_address> in order_address_out where ( doc_number =  ls_item-doc_number and  address = <fs_partner>-address )
                                                                  FOR <FS_PARTNER_ROLE_txt> in IT_PARTNER_ROLE where ( PARVW =  <fs_partner>-partn_role )
                                                                    ( doc_number = <fs_partner>-sd_doc
                                                                     partn_role = <FS_PARTNER_ROLE_txt>-vtext
                                                                     partn_numb = <fs_partner>-customer
                                                                     itm_number = <fs_partner>-itm_number
                                                                     name = <fs_address>-name ) )
                                         itemtoconfig = value #( for <fs_ref> in  order_cfgs_curefs_out where ( sd_doc = ls_item-doc_number and posex = ls_item-itm_number  )
                                                                for <fs_inst> in  order_cfgs_cuins_out where ( sd_doc = ls_item-doc_number and inst_id = <fs_ref>-inst_id and config_id = <fs_ref>-config_id )
                                                                  ( posex = <fs_ref>-posex
                                                                   config_id = <fs_inst>-config_id
                                                                   doc_number = <fs_inst>-sd_doc
                                                                   root_id = <fs_inst>-inst_id
                                                                   obj_type = <fs_inst>-obj_type
                                                                   class_type = <fs_inst>-class_type
                                                                   obj_key = <fs_inst>-obj_key
                                                                   quantity = <fs_inst>-quantity
                                                                   quantity_unit = <fs_inst>-quantity_unit
                                                                   configtovalue = value #(  for <fs_value> in order_cfgs_cuvals_out where ( sd_doc = <fs_header>-doc_number and inst_id = <fs_inst>-inst_id and config_id =  <fs_inst>-config_id  )
                                                                                             for <fs_char_text> in lt_char_text where ( atnam = <fs_value>-charc and atwrt = <fs_value>-value )
                                                                                          ( doc_number =  <fs_value>-sd_doc
                                                                                            config_id =  <fs_value>-config_id
                                                                                            inst_id =  <fs_value>-inst_id
                                                                                            charc =  <fs_value>-charc
                                                                                            charc_txt =  <fs_char_text>-atbez
                                                                                            value =  <fs_value>-value
                                                                                            value_txt =  <fs_char_text>-atwtb ) )
*                                                                    valcode =  <fs_value>-valcode ) )
                )  ) ) ) .
*
      ENDLOOP.

      APPEND ls_deep_entity TO lt_deep_entity.
      CLEAR ls_deep_entity.




      CALL METHOD me->/iwbep/if_mgw_conv_srv_runtime~copy_data_to_ref
        EXPORTING
          is_data = lt_deep_entity
        CHANGING
          cr_data = er_entityset.
    ENDIF.

  ENDMETHOD.


  method SALESORDERSET_CREATE_ENTITY.
 DATA : sales_order type ZCL_ZHKMC_VMS_SO_01_MPC_EXT=>ts_so_create_simple.


 io_data_provider->read_entry_data( importing es_data = sales_order ).

  endmethod.


  method SALESORDERSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->SALESORDERSET_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.
  endmethod.
ENDCLASS.