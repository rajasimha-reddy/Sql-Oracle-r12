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
        SELECT DISTINCT
            master_organization_id
        FROM
            mtl_parameters
    )
ORDER BY
    msi.segment1, msi.organization_id;