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