SELECT  distinct
    -- Operating Unit
    hou.name                          AS operating_unit,

    -- Party / Customer
    hp.party_id,
    hp.party_name                     AS customer_name,
    hp.party_number                   AS customer_number,

    -- Customer Account
    hca.cust_account_id,
    hca.account_number,
    hca.account_name,
    hca.status                        AS customer_status,

    -- Address
    hl.address1,
    hl.address2,
    hl.city,
    hl.state,
    hl.postal_code,
    hl.country,

    -- Site
    hcas.cust_acct_site_id,
    hcas.org_id,
    hcsu.site_use_code,

    -- ✅ TAX DETAILS (CORRECT)
    zr.registration_type_code         AS tax_type,
    zr.registration_number            AS tax_registration_number

FROM
    hz_parties                  hp,
    hz_cust_accounts            hca,
    hz_cust_acct_sites_all      hcas,
    hz_cust_site_uses_all       hcsu,
    hz_party_sites              hps,
    hz_locations                hl,
    zx_party_tax_profile        zptp,
    zx_registrations            zr,
    hr_operating_units          hou

WHERE
    -- Mandatory joins
    hp.party_id              = hca.party_id
    AND hca.cust_account_id  = hcas.cust_account_id(+)
    AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id(+)
    AND hcas.party_site_id   = hps.party_site_id(+)
    AND hps.location_id      = hl.location_id(+)

    -- ✅ Tax joins (CORRECT)
    AND hp.party_id           = zptp.party_id(+)
    AND zptp.party_tax_profile_id = zr.party_tax_profile_id(+)

    -- Operating Unit
    AND hcas.org_id           = hou.organization_id(+)

    -- Status filters
    AND hp.status = 'A'
    AND hca.status = 'A'

ORDER BY
    hp.party_name,
    hca.account_number;