SELECT
    /* ================= Supplier Header ================= */
    sup.vendor_id                   AS supplier_id,
    sup.segment1                    AS supplier_number,
    sup.vendor_name                 AS supplier_name,
    sup.vendor_type_lookup_code     AS supplier_type,
    sup.enabled_flag                AS supplier_enabled,
    sup.creation_date               AS supplier_creation_date,
    sup.created_by                  AS supplier_created_by,

    /* ================= Operating Unit ================= */
    hou.name                        AS operating_unit,

    /* ================= Supplier Site ================= */
    site.vendor_site_id             AS supplier_site_id,
    site.vendor_site_code           AS supplier_site_code,
    site.pay_site_flag              AS pay_site_flag,
    site.purchasing_site_flag       AS purchasing_site_flag,
    site.inactive_date              AS site_inactive_date,
    site.payment_method_lookup_code AS payment_method,
    site.invoice_currency_code      AS invoice_currency,
    site.payment_currency_code      AS payment_currency,

    /* ================= Address ================= */
    loc.address1                    AS address_line_1,
    loc.address2                    AS address_line_2,
    loc.address3                    AS address_line_3,
    loc.city                        AS city,
    loc.state                       AS state,
    loc.postal_code                 AS postal_code,
    loc.country                     AS country,

    /* ================= TCA Contact Details ================= */
    hzc.party_name                  AS contact_name,
    phone.phone_number              AS contact_phone,
    email.email_address             AS contact_email

FROM
    ap_suppliers            sup,
    ap_supplier_sites_all   site,
    hr_operating_units      hou,
    hz_party_sites          hps,
    hz_locations            loc,

    /* ---- Supplier as Party ---- */
    hz_parties              hz_sup,

    /* ---- Contact relationship ---- */
    hz_relationships        rel,
    hz_parties              hzc,

    /* ---- Contact Points ---- */
    hz_contact_points       phone,
    hz_contact_points       email

WHERE
    /* Supplier ↔ Site */
    sup.vendor_id        = site.vendor_id(+)
AND site.org_id          = hou.organization_id(+)

    /* Site ↔ Address */
AND site.party_site_id   = hps.party_site_id(+)
AND hps.location_id      = loc.location_id(+)

    /* Supplier ↔ Party */
AND sup.party_id         = hz_sup.party_id

    /* Supplier ↔ Contact */
AND hz_sup.party_id      = rel.object_id(+)
AND rel.relationship_code(+) = 'CONTACT'
AND rel.subject_id       = hzc.party_id(+)

    /* Phone */
AND hzc.party_id                 = phone.owner_table_id(+)
AND phone.owner_table_name(+)    = 'HZ_PARTIES'
AND phone.contact_point_type(+)  = 'PHONE'
AND phone.status(+)              = 'A'

    /* Email */
AND hzc.party_id                 = email.owner_table_id(+)
AND email.owner_table_name(+)    = 'HZ_PARTIES'
AND email.contact_point_type(+)  = 'EMAIL'
AND email.status(+)              = 'A'

AND sup.segment1 IS NOT NULL

ORDER BY
    sup.vendor_name,
    site.vendor_site_code;
    
    
    
    
/*Updated Quety*/

SELECT
    /* ================= Supplier Header ================= */
    sup.vendor_id                   AS supplier_id,
    sup.segment1                    AS supplier_number,
    sup.vendor_name                 AS supplier_name,
    sup.vendor_type_lookup_code     AS supplier_type,
    sup.enabled_flag                AS supplier_enabled,
    sup.creation_date               AS supplier_creation_date,
    sup.created_by                  AS supplier_created_by,

    /* ================= Operating Unit ================= */
    hou.name                        AS operating_unit,

    /* ================= Supplier Site ================= */
    site.vendor_site_id             AS supplier_site_id,
    site.vendor_site_code           AS supplier_site_code,
    site.pay_site_flag              AS pay_site_flag,
    site.purchasing_site_flag       AS purchasing_site_flag,
    site.inactive_date              AS site_inactive_date,
    site.payment_method_lookup_code AS payment_method,
    site.invoice_currency_code      AS invoice_currency,
    site.payment_currency_code      AS payment_currency,

    /* ================= Address ================= */
    loc.address1                    AS address_line_1,
    loc.address2                    AS address_line_2,
    loc.address3                    AS address_line_3,
    loc.city                        AS city,
    loc.state                       AS state,
    loc.postal_code                 AS postal_code,
    loc.country                     AS country,

    /* ================= TCA Contact Details ================= */
    hzc.party_name                  AS contact_name,

    /* ================= Contact Email (Priority Logic) ================= */
    DECODE(
        sup.vendor_type_lookup_code,
        'EMPLOYEE', 
        papf.email_address,
        /* Non-EMPLOYEE: Site Email -> Party Email -> Related Contact Email */
        NVL(hcp_site_ems.email_address, 
            NVL(hcp_pty_ems.email_address, 
                (SELECT RTRIM(XMLAGG(XMLELEMENT(c, hcp_rel.email_address || ',')).EXTRACT('//text()'), ',')
                 FROM hz_contact_points hcp_rel
                 WHERE hcp_rel.owner_table_id   = rel.party_id
                   AND hcp_rel.owner_table_name = 'HZ_PARTIES'
                   AND hcp_rel.contact_point_type = 'EMAIL'
                   AND hcp_rel.status           = 'A'
                   AND hcp_rel.primary_flag     = 'Y')
            )
        )
    ) AS contact_email,

    /* ================= Contact Phone (Priority Logic) ================= */
    DECODE(
        sup.vendor_type_lookup_code,
        'EMPLOYEE',
        ph.phone_number,
        DECODE(hcp_site_ph.phone_area_code, NULL, hcp_site_ph.phone_number, 
               hcp_site_ph.phone_area_code || '-' || hcp_site_ph.phone_number)
    ) AS contact_phone,

    /* ================= India Localization: Tax Registrations ================= */
    /* GSTN: Site-level GST registration (India) */
    (
        SELECT jprl.registration_number
        FROM   ja.jai_party_regs jpr, ja.jai_party_reg_lines jprl
        WHERE  jpr.party_reg_id = jprl.party_reg_id
          AND  jpr.party_type_code = 'THIRD_PARTY_SITE'
          AND  NVL(jpr.supplier_flag, '$') = 'Y'
          AND  TRUNC(SYSDATE) BETWEEN jprl.effective_from AND NVL(jprl.effective_to, TRUNC(SYSDATE))
          AND  jpr.party_id = sup.vendor_id
          AND  jprl.registration_type_code = 'GSTREG'
          AND  jpr.party_site_id = site.vendor_site_id
          AND  ROWNUM = 1
    ) AS suppl_gstn,

    /* PAN Number: Site-level fallback to Vendor-level (TDS Header) */
    NVL(
        (SELECT pan_no FROM ja.jai_ap_tds_vendor_hdrs
         WHERE vendor_id = sup.vendor_id AND vendor_site_id = site.vendor_site_id),
        (SELECT pan_no FROM ja.jai_ap_tds_vendor_hdrs
         WHERE vendor_id = sup.vendor_id AND vendor_site_id = 0 AND ROWNUM = 1)
    ) AS pan_number,

    /* TDS Registration Number: Site-level fallback to Vendor-level (Party Regs) */
    NVL(
        (SELECT jprl.registration_number
         FROM   ja.jai_party_regs jrp, ja.jai_party_reg_lines jprl, ja.jai_regimes jr
         WHERE  jrp.party_reg_id = jprl.party_reg_id
           AND  jrp.party_id = sup.vendor_id
           AND  jrp.party_site_id = site.vendor_site_id
           AND  jr.regime_code = 'TDS'
           AND  jprl.regime_id = jr.regime_id
           AND  jrp.org_id = site.org_id
           AND  jprl.effective_to IS NULL
           AND  ROWNUM = 1),
        (SELECT jprl.registration_number
         FROM   ja.jai_party_regs jrp, ja.jai_party_reg_lines jprl, ja.jai_regimes jr
         WHERE  jrp.party_reg_id = jprl.party_reg_id
           AND  jrp.party_id = sup.vendor_id
           AND  jrp.party_site_id IS NULL
           AND  jr.regime_code = 'TDS'
           AND  jprl.regime_id = jr.regime_id
           AND  jprl.effective_to IS NULL
           AND  ROWNUM = 1)
    ) AS pan,

    /* Service Tax Registration Number (India Localization) */
    (SELECT service_tax_regno
     FROM   ja.jai_cmn_vendor_sites
     WHERE  vendor_id = sup.vendor_id
       AND  vendor_site_id = site.vendor_site_id) AS service_tax_number,

    /* CST/TIN Registration Number (India Localization) */
    (SELECT cst_reg_no
     FROM   ja.jai_cmn_vendor_sites
     WHERE  vendor_id = sup.vendor_id
       AND  vendor_site_id = site.vendor_site_id) AS tin_cst,

    /* ================= India Localization: Bank Details (Priority Logic) ================= */
    /* Bank Name: Site-level -> Org-level -> Global fallback */
    NVL(
        NVL(
            NVL(
                /* Priority 1: Site + Org + Preference=1 */
                (SELECT eb.bank_name
                 FROM   iby.iby_ext_bank_accounts eba,
                        iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb,
                        apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep,
                        iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.supplier_site_id = site.vendor_site_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1),
                /* Priority 2: Org-level only (no site filter) */
                (SELECT eb.bank_name
                 FROM   iby.iby_ext_bank_accounts eba,
                        iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb,
                        apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep,
                        iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1)
            ),
            /* Priority 3: Global fallback (no site/org filter) */
            (SELECT eb.bank_name
             FROM   iby.iby_ext_bank_accounts eba,
                    iby.iby_account_owners ao,
                    apps.iby_ext_banks_v eb,
                    apps.iby_ext_bank_branches_v ebb,
                    iby.iby_external_payees_all iep,
                    iby.iby_pmt_instr_uses_all ipi
             WHERE  ao.account_owner_party_id = sup.party_id
               AND  eba.ext_bank_account_id = ao.ext_bank_account_id
               AND  eb.bank_party_id = ebb.bank_party_id
               AND  eba.branch_id = ebb.branch_party_id
               AND  eba.bank_id = eb.bank_party_id
               AND  iep.ext_payee_id = ipi.ext_pmt_party_id
               AND  ipi.instrument_id = eba.ext_bank_account_id
               AND  ipi.order_of_preference = 1
               AND  ipi.instrument_type = 'BANKACCOUNT'
               AND  supplier_site_id IS NULL
               AND  party_site_id IS NULL
               AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  ROWNUM = 1)
        ),
        /* Priority 4: Minimal fallback via external payees */
        (SELECT (SELECT bank_name FROM apps.iby_ext_banks_v WHERE bank_party_id = eba.bank_id)
         FROM   iby.iby_external_payees_all epa,
                iby.iby_pmt_instr_uses_all piu,
                iby.iby_ext_bank_accounts eba
         WHERE  epa.payee_party_id = sup.party_id
           AND  epa.ext_payee_id = piu.ext_pmt_party_id
           AND  piu.instrument_id = eba.ext_bank_account_id
           AND  supplier_site_id IS NULL
           AND  party_site_id IS NULL
           AND  piu.order_of_preference = 1
           AND  NVL(piu.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
           AND  ROWNUM = 1)
    ) AS bank_name,

    /* Bank Account Number: Same priority logic as bank_name */
    NVL(
        NVL(
            NVL(
                (SELECT eba.bank_account_num
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.supplier_site_id = site.vendor_site_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1),
                (SELECT eba.bank_account_num
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1)
            ),
            (SELECT eba.bank_account_num
             FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                    apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                    iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
             WHERE  ao.account_owner_party_id = sup.party_id
               AND  eba.ext_bank_account_id = ao.ext_bank_account_id
               AND  eb.bank_party_id = ebb.bank_party_id
               AND  eba.branch_id = ebb.branch_party_id
               AND  eba.bank_id = eb.bank_party_id
               AND  iep.ext_payee_id = ipi.ext_pmt_party_id
               AND  ipi.instrument_id = eba.ext_bank_account_id
               AND  ipi.order_of_preference = 1
               AND  ipi.instrument_type = 'BANKACCOUNT'
               AND  supplier_site_id IS NULL
               AND  party_site_id IS NULL
               AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  ROWNUM = 1)
        ),
        (SELECT eba.bank_account_num
         FROM   iby.iby_external_payees_all epa, iby.iby_pmt_instr_uses_all piu,
                iby.iby_ext_bank_accounts eba
         WHERE  epa.payee_party_id = sup.party_id
           AND  epa.ext_payee_id = piu.ext_pmt_party_id
           AND  piu.instrument_id = eba.ext_bank_account_id
           AND  supplier_site_id IS NULL
           AND  party_site_id IS NULL
           AND  piu.order_of_preference = 1
           AND  NVL(piu.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
           AND  ROWNUM = 1)
    ) AS bank_account_num,

    /* Bank Branch Name: Same priority logic */
    NVL(
        NVL(
            NVL(
                (SELECT ebb.bank_branch_name
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.supplier_site_id = site.vendor_site_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1),
                (SELECT ebb.bank_branch_name
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1)
            ),
            (SELECT ebb.bank_branch_name
             FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                    apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                    iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
             WHERE  ao.account_owner_party_id = sup.party_id
               AND  eba.ext_bank_account_id = ao.ext_bank_account_id
               AND  eb.bank_party_id = ebb.bank_party_id
               AND  eba.branch_id = ebb.branch_party_id
               AND  eba.bank_id = eb.bank_party_id
               AND  iep.ext_payee_id = ipi.ext_pmt_party_id
               AND  ipi.instrument_id = eba.ext_bank_account_id
               AND  ipi.order_of_preference = 1
               AND  ipi.instrument_type = 'BANKACCOUNT'
               AND  supplier_site_id IS NULL
               AND  party_site_id IS NULL
               AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  ROWNUM = 1)
        ),
        (SELECT (SELECT bank_branch_name FROM apps.iby_ext_bank_branches_v WHERE branch_party_id = eba.branch_id)
         FROM   iby.iby_external_payees_all epa, iby.iby_pmt_instr_uses_all piu,
                iby.iby_ext_bank_accounts eba
         WHERE  epa.payee_party_id = sup.party_id
           AND  epa.ext_payee_id = piu.ext_pmt_party_id
           AND  piu.instrument_id = eba.ext_bank_account_id
           AND  supplier_site_id IS NULL
           AND  party_site_id IS NULL
           AND  piu.order_of_preference = 1
           AND  NVL(piu.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
           AND  ROWNUM = 1)
    ) AS branch_name,

    /* IFSC Code (Branch Number): Same priority logic */
    NVL(
        NVL(
            NVL(
                (SELECT ebb.branch_number
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.supplier_site_id = site.vendor_site_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1),
                (SELECT ebb.branch_number
                 FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                        apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                        iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
                 WHERE  ao.account_owner_party_id = sup.party_id
                   AND  eba.ext_bank_account_id = ao.ext_bank_account_id
                   AND  eb.bank_party_id = ebb.bank_party_id
                   AND  eba.branch_id = ebb.branch_party_id
                   AND  eba.bank_id = eb.bank_party_id
                   AND  iep.org_id = site.org_id
                   AND  iep.ext_payee_id = ipi.ext_pmt_party_id
                   AND  ipi.instrument_id = eba.ext_bank_account_id
                   AND  ipi.order_of_preference = 1
                   AND  ipi.instrument_type = 'BANKACCOUNT'
                   AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
                   AND  ROWNUM = 1)
            ),
            (SELECT ebb.branch_number
             FROM   iby.iby_ext_bank_accounts eba, iby.iby_account_owners ao,
                    apps.iby_ext_banks_v eb, apps.iby_ext_bank_branches_v ebb,
                    iby.iby_external_payees_all iep, iby.iby_pmt_instr_uses_all ipi
             WHERE  ao.account_owner_party_id = sup.party_id
               AND  eba.ext_bank_account_id = ao.ext_bank_account_id
               AND  eb.bank_party_id = ebb.bank_party_id
               AND  eba.branch_id = ebb.branch_party_id
               AND  eba.bank_id = eb.bank_party_id
               AND  iep.ext_payee_id = ipi.ext_pmt_party_id
               AND  ipi.instrument_id = eba.ext_bank_account_id
               AND  ipi.order_of_preference = 1
               AND  ipi.instrument_type = 'BANKACCOUNT'
               AND  supplier_site_id IS NULL
               AND  party_site_id IS NULL
               AND  NVL(eba.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ebb.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  NVL(ipi.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
               AND  ROWNUM = 1)
        ),
        (SELECT (SELECT branch_number FROM apps.iby_ext_bank_branches_v WHERE branch_party_id = eba.branch_id)
         FROM   iby.iby_external_payees_all epa, iby.iby_pmt_instr_uses_all piu,
                iby.iby_ext_bank_accounts eba
         WHERE  epa.payee_party_id = sup.party_id
           AND  epa.ext_payee_id = piu.ext_pmt_party_id
           AND  piu.instrument_id = eba.ext_bank_account_id
           AND  supplier_site_id IS NULL
           AND  party_site_id IS NULL
           AND  piu.order_of_preference = 1
           AND  NVL(piu.end_date, TRUNC(SYSDATE)) >= TRUNC(SYSDATE)
           AND  ROWNUM = 1)
    ) AS ifsc,

    /* ================= Audit & Status Fields ================= */
    /* Supplier Status: Derived from end_date_active */
    CASE
        WHEN sup.end_date_active IS NULL THEN 'Active'
        WHEN TRUNC(sup.end_date_active) > TRUNC(SYSDATE) THEN 'Active'
        ELSE 'In_Active'
    END AS status,

    /* Created By: User name from FND_USER */
    (SELECT user_name FROM applsys.fnd_user WHERE user_id = sup.created_by) AS created_by,

    /* Creation Date */
    sup.creation_date,

    /* Payment Method: Primary payment method from IBY */
    (SELECT ppm.payment_method_code
     FROM   iby.iby_external_payees_all epa,
            iby_ext_party_pmt_mthds ppm
     WHERE  epa.supplier_site_id = site.vendor_site_id
       AND  epa.payee_party_id = sup.party_id
       AND  epa.ext_payee_id = ppm.ext_pmt_party_id
       AND  ppm.inactive_date IS NULL
       AND  epa.inactive_date IS NULL
       AND  ppm.primary_flag = 'Y'
       AND  ROWNUM = 1) AS payment_method

FROM
    ap_suppliers           sup,
    ap_supplier_sites_all  site,
    hr_operating_units     hou,
    hz_party_sites         hps,
    hz_locations           loc,
    hz_parties             hz_sup,
    hz_relationships       rel,
    hz_parties             hzc,
    /* ---- Employee Tables ---- */
    hr.per_all_people_f    papf,
    hr.per_phones          ph,
    /* ---- Supplier Contact Point Tables ---- */
    hz_contact_points      hcp_site_ems,
    hz_contact_points      hcp_pty_ems,
    hz_contact_points      hcp_site_ph

WHERE
    /* Supplier <-> Site */
    sup.vendor_id        = site.vendor_id(+)
AND site.org_id          = hou.organization_id(+)

    /* Site <-> Address */
AND site.party_site_id   = hps.party_site_id(+)
AND hps.location_id      = loc.location_id(+)

    /* Supplier <-> Party */
AND sup.party_id         = hz_sup.party_id

    /* Supplier <-> Contact */
AND hz_sup.party_id      = rel.object_id(+)
AND rel.relationship_code(+) = 'CONTACT'
AND rel.status(+)        = 'A'
AND rel.subject_id       = hzc.party_id(+)

    /* ---- Employee Joins ---- */
AND sup.employee_id      = papf.person_id(+)
AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date(+)) AND TRUNC(papf.effective_end_date(+))
AND papf.person_id       = ph.parent_id(+)
AND ph.phone_type(+)     = 'M'

    /* ---- Site Email Join ---- */
AND site.party_site_id       = hcp_site_ems.owner_table_id(+)
AND hcp_site_ems.owner_table_name(+) = 'HZ_PARTY_SITES'
AND hcp_site_ems.contact_point_type(+) = 'EMAIL'
AND hcp_site_ems.status(+)           = 'A'
AND hcp_site_ems.primary_flag(+)     = 'Y'

    /* ---- Party Email Join ---- */
AND sup.party_id             = hcp_pty_ems.owner_table_id(+)
AND hcp_pty_ems.owner_table_name(+) = 'HZ_PARTIES'
AND hcp_pty_ems.contact_point_type(+) = 'EMAIL'
AND hcp_pty_ems.status(+)           = 'A'
AND hcp_pty_ems.primary_flag(+)     = 'Y'

    /* ---- Site Phone Join ---- */
AND site.party_site_id       = hcp_site_ph.owner_table_id(+)
AND hcp_site_ph.owner_table_name(+) = 'HZ_PARTY_SITES'
AND hcp_site_ph.contact_point_type(+) = 'PHONE'
AND hcp_site_ph.phone_line_type(+)   = 'GEN'
AND hcp_site_ph.status(+)           = 'A'
AND hcp_site_ph.primary_flag(+)     = 'Y'

AND sup.segment1 IS NOT NULL

ORDER BY
    sup.vendor_name,
    site.vendor_site_code;