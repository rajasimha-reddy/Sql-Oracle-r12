SELECT
    CASE
        WHEN msi.segment1 LIKE 'C%' THEN
            'CAPEX'
        WHEN msi.segment1 LIKE 'O%' THEN
            'OPEX'
        ELSE
            'OTHER'
    END                               "Item Type",
    msi.segment1                      "Item Code",
    msi.organization_id,
    msi.description                   "Item Description",
    msi.primary_uom_code              "UOM Code",
    misi.secondary_inventory_name     "Sub Inventory",
    ood.organization_name             "Inv Organization Name",
    mcv.segment1                      "Categorie seg1",
    mcv.segment2                      "Categorie seg2",
    mcv.segment3                      "Categorie seg3",
    msi.cycle_count_enabled_flag      "Cycle Count",
    msi.inspection_required_flag      "Inspection",
    msi.stock_enabled_flag            "Stockable",
    msi.mtl_transactions_enabled_flag "Transactable",
    msi.lot_control_code              "Lot Control",
    msi.location_control_code         "Location",
    msi.purchasing_enabled_flag       "Purchasable",
    msi.must_use_approved_vendor_flag "Use Approve Supplier List",
       --msi.buyer_id,
    pap.full_name                     "Buyer Name",
    msi.list_price_per_unit           "List Price",
    msi.expense_account               "Expense Account",
    msi.reservable_type               "Reservable",
    msi.purchasing_item_flag          "Purchased",
    msi.outside_operation_flag        "OSP item",
    msi.outside_operation_uom_type    "Unit Type",
    msi.receiving_routing_id          "Receive Routing",
    msi.inventory_planning_code       "Inventory Planning method",
    msi.min_minmax_quantity           "Min Max(Minimum Qty)",
    msi.max_minmax_quantity           "Min Max(Maximum Qty)",
    msi.minimum_order_quantity        "Order Qty (Minimum Qty)",
    msi.maximum_order_quantity        "Order Qty (Maximum Qty)",
    msi.source_type                   "Source Type",
    msi.source_subinventory           "Source Sub inventory",
    msi.planning_make_buy_code        "MAKE BUY",
    msi.fixed_lot_multiplier          "Fixed lot multiplier",
    msi.planner_code                  "Planner",
    msi.mrp_planning_code             "Planning method",
    msi.ato_forecast_control          "Forecast control",
    msi.end_assembly_pegging_flag     "Pegging",
    msi.release_time_fence_code       "Release Time Fence",
    msi.planning_time_fence_days      "Planning time fence",
    msi.preprocessing_lead_time       "Preprocessing",
    msi.full_lead_time                "Processing",
    msi.postprocessing_lead_time      "Post processing"
FROM
    mtl_system_items             msi,
    mtl_secondary_locators       msl,
    mtl_item_locations           mil,
    per_all_people_f             pap,
    mtl_secondary_inventories    misi,
    org_organization_definitions ood,
    mtl_item_categories          mic,
    mtl_categories_vl            mcv,
    mtl_category_sets            mcs
WHERE
        msi.inventory_item_id = msl.inventory_item_id (+)
    AND msi.organization_id = msl.organization_id (+)
    AND msl.secondary_locator = mil.inventory_location_id (+)
    AND msl.organization_id = mil.organization_id (+)
    AND pap.person_id (+) = msi.buyer_id
    AND msi.organization_id = misi.organization_id (+)
    AND ood.organization_id = msi.organization_id
    AND mic.inventory_item_id = msi.inventory_item_id
    AND mic.organization_id = msi.organization_id
    AND mcs.category_set_id = mic.category_set_id
    AND mcs.structure_id = mcv.structure_id
    AND mcv.category_id = mic.category_id
    AND msi.inventory_item_status_code = 'Active'
    AND ood.organization_id IN (
        '89'
    )
ORDER BY
    msi.segment1, msi.organization_id;
    
    
    
/*2nd query*/


SELECT DISTINCT
    org.organization_code,
    msi.segment1                                                                item,
    msi.description,
    msi.primary_unit_of_measure,
    glcc1.concatenated_segments                                                 cost_of_sales_account,
    glcc2.concatenated_segments                                                 expense_account,
    decode(msi.planning_make_buy_code, '2', 'BUY', '1', 'MAKE')                 make_buy_code,
    ml.meaning                                                                  item_type,
    (
        SELECT
            msi.inventory_item_status_code
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_item_status_code'
    )                                                                           item_status,
    (
        SELECT
            msi.purchasing_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.purchasing_item_flag'
    )                                                                           purchased,
    (
        SELECT
            msi.shippable_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.shippable_item_flag'
    )                                                                           shippable,
    (
        SELECT
            msi.mtl_transactions_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.mtl_transactions_enabled_flag'
    )                                                                           transactable,
    (
        SELECT
            msi.so_transactions_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.so_transactions_flag'
    )                                                                           oe_transactable,
    (
        SELECT
            msi.internal_order_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.internal_order_enabled_flag'
    )                                                                           internal_orders_enabled,
    (
        SELECT
            msi.customer_order_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           om_customer_ordered,
    (
        SELECT
            msi.returnable_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           om_returnable_flag,
    (
        SELECT
            msi.customer_order_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           customer_orders_enabled,
    (
        SELECT
            msi.purchasing_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.purchasing_enabled_flag'
    )                                                                           purchasable,
    msi.outside_operation_uom_type,
    (
        SELECT
            msi.inventory_asset_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_asset_flag'
    )                                                                           inventory_asset_value,
    msi.costing_enabled_flag,
    msi.default_include_in_rollup_flag                                          include_in_rollup,
    (
        SELECT
            msi.eng_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.eng_item_flag'
    )                                                                           engineering_item,
    (
        SELECT
            msi.inventory_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_item_flag'
    )                                                                           inventory_item,
    (
        SELECT
            msi.must_use_approved_vendor_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.service_item_flag'
    )                                                                           use_approved_supplier,
    (
        SELECT
            msi.internal_order_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.internal_order_flag'
    )                                                                           internal_ordered,
    (
        SELECT
            msi.build_in_wip_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.build_in_wip_flag'
    )                                                                           build_in_wip,
    (
        SELECT
            msi.bom_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.bom_enabled_flag'
    )                                                                           bom_allowed,
    decode(msi.wip_supply_type, 1, 'PUSH', 2, 'ASSEMBLY_PULL',
           3, 'OPERATION_PULL', 4, 'BULK', 5,
           'SUPPLIER', 6, 'PHANTOM')                                            wip_supply_type,
    (
        SELECT
            msi.stock_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.stock_enabled_flag'
    )                                                                           stockable,
    msi.so_transactions_flag                                                    om_transactions,
    msi.mtl_transactions_enabled_flag                                           mtl_transactions_enabled,
    (
        SELECT
            msi.invoiceable_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.INVOICEABLE_ITEM_FLAG'
    )                                                                           invoiceable_item_flag,
    (
        SELECT
            msi.invoice_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.INVOICE_ENABLED_FLAG'
    )                                                                           invoice_enabled_flag,
    (
        SELECT
            name
        FROM
            apps.hr_all_organization_units
        WHERE
            organization_id = msi.default_shipping_org
    )                                                                           default_shipping_orgnization,
    msi.attribute11                                                             sona_dmr_code,
    msi.attribute12                                                             sona_item_issue_type,
    msi.attribute10                                                             sona_sales_tax_number,
    msi.attribute9                                                              sona_tools_planned_life,
    decode(msi.inventory_planning_code, 6, 'Not Planned', 2, 'Min-Max',
           1, 'Reorder Point', 7, 'Vendor Managed')                             "INVENTORY PLANNING CODE",
    msi.planner_code,
    decode(msi.subcontracting_component, 1, 'Prepositioned', 2, 'Synchronized',
           NULL, NULL)                                                          "SUBCONTRACTING COMPONENT",
    msi.min_minmax_quantity,
    msi.max_minmax_quantity,
    msi.minimum_order_quantity,
    msi.maximum_order_quantity,
    msi.order_cost                                                              "Cost Order",
    msi.carrying_cost                                                           "Cost Carrying %",
    decode(msi.source_type, 1, 'Inventory', 2, 'Supplier',
           3, 'Subinventory', NULL, NULL)                                       "Source Type",
    org1.organization_code                                                      "Source Organization",
    org1.organization_name                                                      "Source Organization Name",
    msi.source_subinventory,
    decode(msi.mrp_safety_stock_code, 1, 'Non-MRP Planned', 2, 'MRP Planned %') "Safety Stock Method",
    msi.safety_stock_bucket_days                                                "Safety Stock Bucket Days",
    msi.mrp_safety_stock_percent                                                "Safety Stock Percent",
    decode(msi.mrp_planning_code, 3, 'MRP Planned', 4, 'MPS Planned',
           6, 'Not Planned', 7, 'MRP/MPP Planned', 8,
           'MPS/MPP Planned', 9, 'MPP Planned', NULL)                           "MRP Planning Method",
    msi.fixed_order_quantity,
    msi.fixed_days_supply,
    msi.fixed_lot_multiplier,
    msi.vmi_minimum_units                                                       "VM Min Quantity",
    msi.vmi_minimum_days                                                        "VM Min Days of Supply",
    msi.vmi_maximum_units                                                       "VM Max Quantity",
    msi.vmi_maximum_days                                                        "VM Max Days of Supply",
    msi.vmi_fixed_order_quantity                                                "VM Fixed Quantity",
    decode(msi.so_authorization_flag, 1, 'Customer', 2, 'Supplier',
           NULL, 'None')                                                        "VM Release Autho Required",
    decode(msi.consigned_flag, 1, 'Yes', 2, 'No')                               consigned,
    decode(msi.asn_autoexpire_flag, 1, 'Yes', 2, 'No')                          "VM Auto Expire ASN",
    decode(msi.vmi_forecast_type, 1, 'Order Forecast', 2, 'Sales Forecast',
           3, 'Historical Sales', NULL, NULL)                                   "VM Forecast Type",
    msi.forecast_horizon                                                        "VM Window Days",
    (
        SELECT
            regime_code
        FROM
            apps.jai_rgm_itm_regns a
        WHERE
                a.organization_id = msi.organization_id
            AND a.inventory_item_id = msi.inventory_item_id
            AND a.regime_code = 'EXCISE'
    )                                                                           "Regime Excise",
    (
        SELECT
            regime_code
        FROM
            apps.jai_rgm_itm_regns b
        WHERE
                b.organization_id = msi.organization_id
            AND b.inventory_item_id = msi.inventory_item_id
            AND b.regime_code = 'VAT'
    )                                                                           "Regime VAT",
    msi.organization_id,
    decode(msi.inspection_required_flag, 'Y', 'Inspection Required', 'N', 'Inspection Not Required',
           NULL)                                                                item_inspection,
    ms.category_set_name,
    ms.category_concat_segs                                                     "Category Segments"
FROM
    apps.fnd_lookup_values            ml,
    apps.mtl_system_items_b           msi,
    apps.org_organization_definitions org,
    apps.org_organization_definitions org1,
    apps.mtl_item_categories_v        ms,
          --apps.org_organization_definitions org2,
    apps.hr_organization_units        hou,
    apps.gl_code_combinations_kfv     glcc1,
    apps.gl_code_combinations_kfv     glcc2
WHERE
        1 = 1
         -- AND msi.organization_id = :organization_id
    AND msi.item_type = ml.lookup_code (+)
    AND ml.lookup_type (+) = 'ITEM_TYPE'
    AND msi.organization_id = org.organization_id
    AND msi.inventory_item_id = ms.inventory_item_id
    AND msi.organization_id = ms.organization_id
    AND msi.organization_id = hou.organization_id
    AND msi.source_organization_id = org1.organization_id (+)
    AND msi.cost_of_sales_account = glcc1.code_combination_id
    AND msi.expense_account = glcc2.code_combination_id
    AND hou.business_group_id = 5095;
    
    
/*3rd Query*/


SELECT distinct
        (SELECT mo.organization_NAME
         FROM org_organization_definitions mo
         WHERE mo.ORGANIZATION_ID = mp.MASTER_ORGANIZATION_ID) AS MASTER_ORGANIZATION_NAME,
        CASE 
         WHEN SUBSTR(i.ITEM_CODE,1,1) = 'C' THEN 'CAPEX'
         WHEN SUBSTR(i.ITEM_CODE,1,1) = 'O' THEN 'OPEX'
         ELSE 'OTHER'
       END AS ITEM_CATEGORY,
       i.ITEM_CODE,
       i.TEMPLATE_NAME,
       i.ITEM_CLASSIFICATION,
       m.SEGMENT1 AS ITEM_NUMBER,
       m.DESCRIPTION AS ITEM_DESCRIPTION,
       o.ORGANIZATION_ID,
       o.NAME AS ORGANIZATION_NAME,
       mp.MASTER_ORGANIZATION_ID,
       r.REPORTING_USAGE,
       r.REGIME_NAME,
       r.REPORTING_TYPE_NAME,
       r.REPORTING_TYPE_CODE,
       r.REPORTING_CODE,
       r.REPORTING_CODE_DESCRIPTION,
       r.EFFECTIVE_FROM,
       r.EFFECTIVE_TO
FROM JAI_ITEM_TEMPL_HDR_V i
JOIN JAI_REPORTING_ASSOCIATIONS_V r
     ON i.TEMPLATE_HDR_ID = r.ENTITY_ID
    AND r.ENTITY_CODE = 'ITEM'
JOIN MTL_SYSTEM_ITEMS_B m
     ON i.INVENTORY_ITEM_ID = m.INVENTORY_ITEM_ID
    AND i.ORGANIZATION_ID   = m.ORGANIZATION_ID
JOIN HR_ALL_ORGANIZATION_UNITS o
     ON i.ORGANIZATION_ID = o.ORGANIZATION_ID
JOIN MTL_PARAMETERS mp
     ON i.ORGANIZATION_ID = mp.ORGANIZATION_ID
WHERE mp.MASTER_ORGANIZATION_ID = '5156'
order by 10, 3;


/*Joining 2nd and 3rd Query*/


SELECT DISTINCT    
    org.organization_code,
    msi.segment1                                                                item,
    msi.description,
    msi.primary_unit_of_measure,
    glcc1.concatenated_segments                                                 cost_of_sales_account,
    glcc2.concatenated_segments                                                 expense_account,
    decode(msi.planning_make_buy_code, '2', 'BUY', '1', 'MAKE')                 make_buy_code,
    ml.meaning                                                                  item_type,
    (
        SELECT
            msi.inventory_item_status_code
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_item_status_code'
    )                                                                           item_status,
    (
        SELECT
            msi.purchasing_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.purchasing_item_flag'
    )                                                                           purchased,
    (
        SELECT
            msi.shippable_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.shippable_item_flag'
    )                                                                           shippable,
    (
        SELECT
            msi.mtl_transactions_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.mtl_transactions_enabled_flag'
    )                                                                           transactable,
    (
        SELECT
            msi.so_transactions_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.so_transactions_flag'
    )                                                                           oe_transactable,
    (
        SELECT
            msi.internal_order_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.internal_order_enabled_flag'
    )                                                                           internal_orders_enabled,
    (
        SELECT
            msi.customer_order_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           om_customer_ordered,
    (
        SELECT
            msi.returnable_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           om_returnable_flag,
    (
        SELECT
            msi.customer_order_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.customer_order_enabled_flag'
    )                                                                           customer_orders_enabled,
    (
        SELECT
            msi.purchasing_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.purchasing_enabled_flag'
    )                                                                           purchasable,
    msi.outside_operation_uom_type,
    (
        SELECT
            msi.inventory_asset_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_asset_flag'
    )                                                                           inventory_asset_value,
    msi.costing_enabled_flag,
    msi.default_include_in_rollup_flag                                          include_in_rollup,
    (
        SELECT
            msi.eng_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.eng_item_flag'
    )                                                                           engineering_item,
    (
        SELECT
            msi.inventory_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.inventory_item_flag'
    )                                                                           inventory_item,
    (
        SELECT
            msi.must_use_approved_vendor_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.service_item_flag'
    )                                                                           use_approved_supplier,
    (
        SELECT
            msi.internal_order_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.internal_order_flag'
    )                                                                           internal_ordered,
    (
        SELECT
            msi.build_in_wip_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.build_in_wip_flag'
    )                                                                           build_in_wip,
    (
        SELECT
            msi.bom_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.bom_enabled_flag'
    )                                                                           bom_allowed,
    decode(msi.wip_supply_type, 1, 'PUSH', 2, 'ASSEMBLY_PULL',
           3, 'OPERATION_PULL', 4, 'BULK', 5,
           'SUPPLIER', 6, 'PHANTOM')                                            wip_supply_type,
    (
        SELECT
            msi.stock_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.stock_enabled_flag'
    )                                                                           stockable,
    msi.so_transactions_flag                                                    om_transactions,
    msi.mtl_transactions_enabled_flag                                           mtl_transactions_enabled,
    (
        SELECT
            msi.invoiceable_item_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.INVOICEABLE_ITEM_FLAG'
    )                                                                           invoiceable_item_flag,
    (
        SELECT
            msi.invoice_enabled_flag
        FROM
            apps.mtl_item_attributes_v ia
        WHERE
            lower(ia.attribute_name) = 'mtl_system_items.INVOICE_ENABLED_FLAG'
    )                                                                           invoice_enabled_flag,
    (
        SELECT
            name
        FROM
            apps.hr_all_organization_units
        WHERE
            organization_id = msi.default_shipping_org
    )                                                                           default_shipping_orgnization,
    msi.attribute11                                                             sona_dmr_code,
    msi.attribute12                                                             sona_item_issue_type,
    msi.attribute10                                                             sona_sales_tax_number,
    msi.attribute9                                                              sona_tools_planned_life,
    decode(msi.inventory_planning_code, 6, 'Not Planned', 2, 'Min-Max',
           1, 'Reorder Point', 7, 'Vendor Managed')                             "INVENTORY PLANNING CODE",
    msi.planner_code,
    decode(msi.subcontracting_component, 1, 'Prepositioned', 2, 'Synchronized',
           NULL, NULL)                                                          "SUBCONTRACTING COMPONENT",
    msi.min_minmax_quantity,
    msi.max_minmax_quantity,
    msi.minimum_order_quantity,
    msi.maximum_order_quantity,
    msi.order_cost                                                              "Cost Order",
    msi.carrying_cost                                                           "Cost Carrying %",
    decode(msi.source_type, 1, 'Inventory', 2, 'Supplier',
           3, 'Subinventory', NULL, NULL)                                       "Source Type",
    org1.organization_code                                                      "Source Organization",
    org1.organization_name                                                      "Source Organization Name",
    msi.source_subinventory,
    decode(msi.mrp_safety_stock_code, 1, 'Non-MRP Planned', 2, 'MRP Planned %') "Safety Stock Method",
    msi.safety_stock_bucket_days                                                "Safety Stock Bucket Days",
    msi.mrp_safety_stock_percent                                                "Safety Stock Percent",
    decode(msi.mrp_planning_code, 3, 'MRP Planned', 4, 'MPS Planned',
           6, 'Not Planned', 7, 'MRP/MPP Planned', 8,
           'MPS/MPP Planned', 9, 'MPP Planned', NULL)                           "MRP Planning Method",
    msi.fixed_order_quantity,
    msi.fixed_days_supply,
    msi.fixed_lot_multiplier,
    msi.vmi_minimum_units                                                       "VM Min Quantity",
    msi.vmi_minimum_days                                                        "VM Min Days of Supply",
    msi.vmi_maximum_units                                                       "VM Max Quantity",
    msi.vmi_maximum_days                                                        "VM Max Days of Supply",
    msi.vmi_fixed_order_quantity                                                "VM Fixed Quantity",
    decode(msi.so_authorization_flag, 1, 'Customer', 2, 'Supplier',
           NULL, 'None')                                                        "VM Release Autho Required",
    decode(msi.consigned_flag, 1, 'Yes', 2, 'No')                               consigned,
    decode(msi.asn_autoexpire_flag, 1, 'Yes', 2, 'No')                          "VM Auto Expire ASN",
    decode(msi.vmi_forecast_type, 1, 'Order Forecast', 2, 'Sales Forecast',
           3, 'Historical Sales', NULL, NULL)                                   "VM Forecast Type",
    msi.forecast_horizon                                                        "VM Window Days",
    (
        SELECT
            regime_code
        FROM
            apps.jai_rgm_itm_regns a
        WHERE
                a.organization_id = msi.organization_id
            AND a.inventory_item_id = msi.inventory_item_id
            AND a.regime_code = 'EXCISE'
    )                                                                           "Regime Excise",
    (
        SELECT
            regime_code
        FROM
            apps.jai_rgm_itm_regns b
        WHERE
                b.organization_id = msi.organization_id
            AND b.inventory_item_id = msi.inventory_item_id
            AND b.regime_code = 'VAT'
    )                                                                           "Regime VAT",
    msi.organization_id,
    decode(msi.inspection_required_flag, 'Y', 'Inspection Required', 'N', 'Inspection Not Required',
           NULL)                                                                item_inspection,
    ms.category_set_name,
    ms.category_concat_segs                                                     "Category Segments",
    -- New columns from JAI_ITEM_TEMPL_HDR_V
    i.item_code,
    i.template_name,
    i.item_classification,
    -- New columns from JAI_REPORTING_ASSOCIATIONS_V
    r.reporting_usage,
    r.regime_name,
    r.reporting_type_name,
    r.reporting_type_code,
    r.reporting_code,
    r.reporting_code_description,
    r.effective_from,
    r.effective_to
FROM
    apps.fnd_lookup_values            ml,
    apps.mtl_system_items_b           msi,
    apps.org_organization_definitions org,
    apps.org_organization_definitions org1,
    apps.mtl_item_categories_v        ms,
    apps.hr_organization_units        hou,
    apps.gl_code_combinations_kfv     glcc1,
    apps.gl_code_combinations_kfv     glcc2,
    apps.jai_item_templ_hdr_v         i,
    apps.jai_reporting_associations_v r
WHERE
        1 = 1
    AND msi.item_type = ml.lookup_code (+)
    AND ml.lookup_type (+) = 'ITEM_TYPE'
    AND msi.organization_id = org.organization_id
    AND msi.inventory_item_id = ms.inventory_item_id
    AND msi.organization_id = ms.organization_id
    AND msi.organization_id = hou.organization_id
    AND msi.source_organization_id = org1.organization_id (+)
    AND msi.cost_of_sales_account = glcc1.code_combination_id
    AND msi.expense_account = glcc2.code_combination_id
    AND hou.business_group_id = 5095
    -- Joins added from second query
    AND i.inventory_item_id = msi.inventory_item_id
    AND i.organization_id   = msi.organization_id
    AND i.template_hdr_id   = r.entity_id
    AND r.entity_code       = 'ITEM';