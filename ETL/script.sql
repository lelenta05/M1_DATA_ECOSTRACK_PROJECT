INSERT INTO analytics.fait_mesures (
    temps_sk,
    container_sk,
    capteur_sk,
    zone_sk,
    type_dechet_sk,
    agent_sk,
    vehicule_sk,
    tournee_sk,
    distance_brute_mm,
    fill_level_pct,
    volume_litre,
    timestamp_mesure,
    is_overflow,
    temperature,
    battery_pct,
    qualite_signal
)

SELECT
    dt.temps_sk,
    dc.container_sk,
    dcap.capteur_sk,
    COALESCE(dz.zone_sk, 0),
    COALESCE(dtd.type_dechet_sk, 0),
    COALESCE(da.agent_sk, 0),
    COALESCE(dv.vehicule_sk, 0),
    COALESCE(dtour.tournee_sk, 0),
    s.distance_brute_mm,
    s.fill_level_pct,
    s.volume_litre,
    s.timestamp_mesure,
    s.is_overflow,
    s.temperature,
    s.battery_pct,
    s.qualite_signal

FROM analytics.mesure_src s

LEFT JOIN analytics.dim_containers dc
ON s.id_container = dc.container_sk

LEFT JOIN analytics.dim_capteurs dcap
ON s.id_capteur = dcap.capteur_sk

LEFT JOIN analytics.dim_zones dz
ON dc.code_zone = dz.zone_code

LEFT JOIN analytics.dim_type_dechets dtd
ON dc.code_type_dechet = dtd.code_type_dechet

LEFT JOIN analytics.dim_temps dt
ON DATE(s.timestamp_mesure) = dt.date_complete

LEFT JOIN analytics.dim_tournees dtour
ON dc.container_code = dtour.container_code

LEFT JOIN analytics.dim_agents da
ON da.email = dtour.email

LEFT JOIN analytics.dim_vehicules dv
ON dv.registration_number = dtour.registration_number

WHERE dt.temps_sk IS NOT NULL AND dc.container_sk IS NOT NULL AND dcap.capteur_sk IS NOT NULL;
