-- =============================================================================
-- ArogyaMitra :: development seed
-- One Tamil Nadu district (Tiruvannamalai) with enough real structure to run
-- the full MVP journey from PRD 23.
--
-- The triage rules below are a DEVELOPMENT baseline for engineering the
-- workflow. They are not clinically approved. PRD 16 requires a named clinical
-- owner and an approval record before any deployment.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Versioned configuration (PRD 12.1)
-- ---------------------------------------------------------------------------
insert into public.config_versions (config_key, version, status, effective_from, notes, payload) values
  ('readiness_weights', 1, 'active', now(),
   'Baseline readiness weights. Doctor availability dominates.',
   '{"doctor":0.35,"medicines":0.20,"diagnostics":0.20,"beds":0.25,"stale_after_hours":24}'::jsonb),

  ('facility_score_weights', 1, 'active', now(),
   'Baseline facility scoring per PRD 12.1.',
   '{"travel_time":0.35,"wait":0.15,"service_match":0.30,"capacity_confidence":0.20,
     "max_radius_m":30000,"avg_speed_kmph":30}'::jsonb),

  ('referral_sla', 1, 'active', now(),
   'Acceptance SLA in minutes and recommendation expiry.',
   '{"accept_minutes":30,"emergency_accept_minutes":10,"recommendation_expiry_minutes":720}'::jsonb),

  ('followup_policy', 1, 'active', now(),
   'Post-referral follow-up scheduling.',
   '{"post_referral_days":3,"grace_days":7}'::jsonb);

-- ---------------------------------------------------------------------------
-- Administrative geography
-- ---------------------------------------------------------------------------
insert into public.states (id, code, name_en, name_local) values
  ('11111111-1111-1111-1111-111111111111', '33', 'Tamil Nadu', 'தமிழ்நாடு');

insert into public.districts (id, state_id, code, name_en, name_local, centroid) values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111',
   '3305', 'Tiruvannamalai', 'திருவண்ணாமலை',
   extensions.st_setsrid(extensions.st_makepoint(79.0747, 12.2253), 4326)::extensions.geography);

insert into public.blocks (id, district_id, code, name_en, name_local) values
  ('33333333-0001-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   '330501', 'Tiruvannamalai', 'திருவண்ணாமலை'),
  ('33333333-0002-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222',
   '330502', 'Chengam', 'செங்கம்'),
  ('33333333-0003-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222',
   '330503', 'Polur', 'போளூர்'),
  ('33333333-0004-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222',
   '330504', 'Thandarampattu', 'தண்டரம்பட்டு');

insert into public.villages (id, block_id, code, name_en, name_local, centroid) values
  ('44444444-0001-0000-0000-000000000001', '33333333-0001-0000-0000-000000000001',
   '33050101', 'Adiannamalai', 'ஆதியண்ணாமலை',
   extensions.st_setsrid(extensions.st_makepoint(79.0400, 12.2380), 4326)::extensions.geography),
  ('44444444-0002-0000-0000-000000000002', '33333333-0001-0000-0000-000000000001',
   '33050102', 'Vengikkal', 'வெங்கிக்கல்',
   extensions.st_setsrid(extensions.st_makepoint(79.0950, 12.2100), 4326)::extensions.geography),
  ('44444444-0003-0000-0000-000000000003', '33333333-0002-0000-0000-000000000002',
   '33050201', 'Pudupalayam', 'புதுப்பாளையம்',
   extensions.st_setsrid(extensions.st_makepoint(78.8300, 12.2900), 4326)::extensions.geography),
  ('44444444-0004-0000-0000-000000000004', '33333333-0003-0000-0000-000000000003',
   '33050301', 'Kadaladi', 'கடலாடி',
   extensions.st_setsrid(extensions.st_makepoint(79.1500, 12.4700), 4326)::extensions.geography),
  ('44444444-0005-0000-0000-000000000005', '33333333-0004-0000-0000-000000000004',
   '33050401', 'Sathanur', 'சாத்தனூர்',
   extensions.st_setsrid(extensions.st_makepoint(78.8700, 12.1700), 4326)::extensions.geography);

-- ---------------------------------------------------------------------------
-- Service catalogue (PRD 12.3)
-- ---------------------------------------------------------------------------
insert into public.service_catalog (code, name_en, name_ta, category, min_tier, is_emergency_service) values
  ('general_opd',        'General OPD',            'பொது வெளிநோயாளர் பிரிவு', 'clinical',   1, false),
  ('emergency_care',     'Emergency care',         'அவசர சிகிச்சை',            'emergency',  2, true),
  ('trauma_care',        'Trauma care',            'விபத்து சிகிச்சை',          'emergency',  3, true),
  ('obstetrics',         'Obstetric care',         'மகப்பேறு சிகிச்சை',         'clinical',   2, false),
  ('paediatrics',        'Paediatrics',            'குழந்தை நல மருத்துவம்',     'clinical',   2, false),
  ('general_surgery',    'General surgery',        'பொது அறுவை சிகிச்சை',       'clinical',   3, false),
  ('orthopaedics',       'Orthopaedics',           'எலும்பு மருத்துவம்',        'clinical',   3, false),
  ('cardiology',         'Cardiology',             'இதய மருத்துவம்',            'clinical',   4, false),
  ('nephrology_dialysis','Dialysis',               'சிறுநீரக டயாலிசிஸ்',        'clinical',   3, false),
  ('mental_health',      'Mental health',          'மனநல சிகிச்சை',             'clinical',   2, false),
  ('tb_dots',            'TB DOTS',                'காசநோய் சிகிச்சை',          'clinical',   1, false),
  ('snakebite_care',     'Snakebite management',   'பாம்பு கடி சிகிச்சை',       'emergency',  2, true),
  ('rabies_prophylaxis', 'Anti-rabies vaccination','ரேபிஸ் தடுப்பூசி',          'clinical',   2, false),
  ('lab_basic',          'Basic laboratory',       'அடிப்படை ஆய்வகம்',          'diagnostic', 1, false),
  ('xray',               'X-ray',                  'எக்ஸ்-ரே',                  'diagnostic', 2, false),
  ('ultrasound',         'Ultrasound',             'அல்ட்ராசவுண்ட்',            'diagnostic', 2, false),
  ('ecg',                'ECG',                    'இ.சி.ஜி',                   'diagnostic', 2, false),
  ('ct_scan',            'CT scan',                'சி.டி ஸ்கேன்',              'diagnostic', 4, false),
  ('blood_bank',         'Blood bank',             'இரத்த வங்கி',               'diagnostic', 3, false),
  ('icu',                'Intensive care',         'தீவிர சிகிச்சை பிரிவு',     'clinical',   3, false),
  ('pharmacy',           'Pharmacy',               'மருந்தகம்',                 'pharmacy',   1, false);

-- ---------------------------------------------------------------------------
-- Facilities
-- ---------------------------------------------------------------------------
insert into public.facilities (
  id, hfr_id, name_en, name_local, type, state_id, district_id, block_id, village_id,
  location, address, contact_phone, emergency_phone, is_24x7, has_emergency_department, tier
) values
  ('55555555-0001-0000-0000-000000000001', 'HFR-TN-3305-0001',
   'Government Medical College Hospital, Tiruvannamalai',
   'அரசு மருத்துவக் கல்லூரி மருத்துவமனை, திருவண்ணாமலை',
   'medical_college', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0001-0000-0000-000000000001', null,
   extensions.st_setsrid(extensions.st_makepoint(79.0555, 12.2065), 4326)::extensions.geography,
   'Vengikkal, Tiruvannamalai', '04175-222100', '04175-222108', true, true, 4),

  ('55555555-0002-0000-0000-000000000002', 'HFR-TN-3305-0002',
   'District Headquarters Hospital, Tiruvannamalai',
   'மாவட்ட தலைமை மருத்துவமனை, திருவண்ணாமலை',
   'district_hospital', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0001-0000-0000-000000000001', null,
   extensions.st_setsrid(extensions.st_makepoint(79.0710, 12.2280), 4326)::extensions.geography,
   'Polur Road, Tiruvannamalai', '04175-222233', '04175-222108', true, true, 3),

  ('55555555-0003-0000-0000-000000000003', 'HFR-TN-3305-0003',
   'Community Health Centre, Chengam', 'சமூக நல மருத்துவ நிலையம், செங்கம்',
   'chc', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0002-0000-0000-000000000002', null,
   extensions.st_setsrid(extensions.st_makepoint(78.7950, 12.3100), 4326)::extensions.geography,
   'Chengam', '04188-222045', '04188-222046', true, true, 2),

  ('55555555-0004-0000-0000-000000000004', 'HFR-TN-3305-0004',
   'Primary Health Centre, Polur', 'ஆரம்ப சுகாதார நிலையம், போளூர்',
   'phc', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0003-0000-0000-000000000003', null,
   extensions.st_setsrid(extensions.st_makepoint(79.1180, 12.5030), 4326)::extensions.geography,
   'Polur', '04181-222311', null, false, false, 1),

  ('55555555-0005-0000-0000-000000000005', 'HFR-TN-3305-0005',
   'Primary Health Centre, Thandarampattu', 'ஆரம்ப சுகாதார நிலையம், தண்டரம்பட்டு',
   'phc', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0004-0000-0000-000000000004', null,
   extensions.st_setsrid(extensions.st_makepoint(78.9200, 12.2000), 4326)::extensions.geography,
   'Thandarampattu', '04175-244120', null, true, false, 1),

  ('55555555-0006-0000-0000-000000000006', 'HFR-TN-3305-0006',
   'Health Sub Centre, Adiannamalai', 'சுகாதார உட்கோட்ட நிலையம், ஆதியண்ணாமலை',
   'health_sub_centre', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0001-0000-0000-000000000001',
   '44444444-0001-0000-0000-000000000001',
   extensions.st_setsrid(extensions.st_makepoint(79.0400, 12.2380), 4326)::extensions.geography,
   'Adiannamalai', null, null, false, false, 1),

  ('55555555-0007-0000-0000-000000000007', 'HFR-TN-3305-0007',
   'Health and Wellness Centre, Vengikkal', 'நல்வாழ்வு நிலையம், வெங்கிக்கல்',
   'hwc', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', '33333333-0001-0000-0000-000000000001',
   '44444444-0002-0000-0000-000000000002',
   extensions.st_setsrid(extensions.st_makepoint(79.0950, 12.2100), 4326)::extensions.geography,
   'Vengikkal', '04175-233190', null, false, false, 1);

-- ---------------------------------------------------------------------------
-- Facility services
-- ---------------------------------------------------------------------------
-- Medical college: everything available.
insert into public.facility_services (facility_id, service_code, status)
select '55555555-0001-0000-0000-000000000001'::uuid, code,
  'available'::public.availability_status
from public.service_catalog;

-- District hospital: everything except CT and cardiology.
insert into public.facility_services (facility_id, service_code, status)
select '55555555-0002-0000-0000-000000000002'::uuid, code,
  (case when code in ('ct_scan', 'cardiology') then 'unavailable' else 'available' end)
    ::public.availability_status
from public.service_catalog;

-- CHC Chengam: secondary level.
insert into public.facility_services (facility_id, service_code, status) values
  ('55555555-0003-0000-0000-000000000003', 'general_opd', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'emergency_care', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'obstetrics', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'paediatrics', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'snakebite_care', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'rabies_prophylaxis', 'limited'),
  ('55555555-0003-0000-0000-000000000003', 'mental_health', 'limited'),
  ('55555555-0003-0000-0000-000000000003', 'tb_dots', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'lab_basic', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'xray', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'ultrasound', 'limited'),
  ('55555555-0003-0000-0000-000000000003', 'ecg', 'available'),
  ('55555555-0003-0000-0000-000000000003', 'pharmacy', 'available');

-- PHC Polur.
insert into public.facility_services (facility_id, service_code, status) values
  ('55555555-0004-0000-0000-000000000004', 'general_opd', 'available'),
  ('55555555-0004-0000-0000-000000000004', 'tb_dots', 'available'),
  ('55555555-0004-0000-0000-000000000004', 'lab_basic', 'limited'),
  ('55555555-0004-0000-0000-000000000004', 'pharmacy', 'available'),
  ('55555555-0004-0000-0000-000000000004', 'emergency_care', 'unavailable');

-- PHC Thandarampattu: 24x7 PHC with obstetric cover.
insert into public.facility_services (facility_id, service_code, status) values
  ('55555555-0005-0000-0000-000000000005', 'general_opd', 'available'),
  ('55555555-0005-0000-0000-000000000005', 'obstetrics', 'available'),
  ('55555555-0005-0000-0000-000000000005', 'emergency_care', 'limited'),
  ('55555555-0005-0000-0000-000000000005', 'snakebite_care', 'limited'),
  ('55555555-0005-0000-0000-000000000005', 'tb_dots', 'available'),
  ('55555555-0005-0000-0000-000000000005', 'lab_basic', 'available'),
  ('55555555-0005-0000-0000-000000000005', 'pharmacy', 'available');

-- Sub centre and HWC.
insert into public.facility_services (facility_id, service_code, status) values
  ('55555555-0006-0000-0000-000000000006', 'general_opd', 'limited'),
  ('55555555-0006-0000-0000-000000000006', 'pharmacy', 'limited'),
  ('55555555-0007-0000-0000-000000000007', 'general_opd', 'available'),
  ('55555555-0007-0000-0000-000000000007', 'tb_dots', 'available'),
  ('55555555-0007-0000-0000-000000000007', 'lab_basic', 'limited'),
  ('55555555-0007-0000-0000-000000000007', 'pharmacy', 'available');

-- ---------------------------------------------------------------------------
-- Facility resources -> drives readiness (PRD 12.3)
-- ---------------------------------------------------------------------------
insert into public.facility_resources (facility_id, kind, item_code, label_en, label_ta, status, quantity, capacity) values
  -- Medical college
  ('55555555-0001-0000-0000-000000000001', 'doctor', 'MO_GENERAL', 'Medical officers', 'மருத்துவ அதிகாரிகள்', 'available', 24, 28),
  ('55555555-0001-0000-0000-000000000001', 'specialist', 'CARDIOLOGIST', 'Cardiologist', 'இதய நிபுணர்', 'available', 2, 2),
  ('55555555-0001-0000-0000-000000000001', 'specialist', 'OBGYN', 'Obstetrician', 'மகப்பேறு நிபுணர்', 'available', 4, 4),
  ('55555555-0001-0000-0000-000000000001', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 900, 1000),
  ('55555555-0001-0000-0000-000000000001', 'essential_medicine', 'ASV', 'Anti-snake venom', 'பாம்பு விஷ முறிவு மருந்து', 'available', 40, 50),
  ('55555555-0001-0000-0000-000000000001', 'diagnostic', 'CT', 'CT scanner', 'சி.டி ஸ்கேனர்', 'available', 1, 1),
  ('55555555-0001-0000-0000-000000000001', 'diagnostic', 'XRAY', 'X-ray', 'எக்ஸ்-ரே', 'available', 3, 3),
  ('55555555-0001-0000-0000-000000000001', 'bed', 'GENERAL_BED', 'General beds', 'பொது படுக்கைகள்', 'available', 120, 400),
  ('55555555-0001-0000-0000-000000000001', 'icu_bed', 'ICU_BED', 'ICU beds', 'தீவிர சிகிச்சை படுக்கைகள்', 'limited', 4, 30),
  ('55555555-0001-0000-0000-000000000001', 'oxygen', 'O2_CYLINDER', 'Oxygen cylinders', 'ஆக்சிஜன்', 'available', 60, 80),

  -- District hospital
  ('55555555-0002-0000-0000-000000000002', 'doctor', 'MO_GENERAL', 'Medical officers', 'மருத்துவ அதிகாரிகள்', 'available', 12, 14),
  ('55555555-0002-0000-0000-000000000002', 'specialist', 'OBGYN', 'Obstetrician', 'மகப்பேறு நிபுணர்', 'available', 2, 2),
  ('55555555-0002-0000-0000-000000000002', 'specialist', 'ORTHO', 'Orthopaedic surgeon', 'எலும்பு அறுவை நிபுணர்', 'limited', 1, 2),
  ('55555555-0002-0000-0000-000000000002', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 400, 500),
  ('55555555-0002-0000-0000-000000000002', 'essential_medicine', 'ASV', 'Anti-snake venom', 'பாம்பு விஷ முறிவு மருந்து', 'available', 20, 25),
  ('55555555-0002-0000-0000-000000000002', 'diagnostic', 'XRAY', 'X-ray', 'எக்ஸ்-ரே', 'available', 2, 2),
  ('55555555-0002-0000-0000-000000000002', 'diagnostic', 'USG', 'Ultrasound', 'அல்ட்ராசவுண்ட்', 'available', 1, 1),
  ('55555555-0002-0000-0000-000000000002', 'bed', 'GENERAL_BED', 'General beds', 'பொது படுக்கைகள்', 'available', 60, 200),
  ('55555555-0002-0000-0000-000000000002', 'icu_bed', 'ICU_BED', 'ICU beds', 'தீவிர சிகிச்சை படுக்கைகள்', 'limited', 2, 12),
  ('55555555-0002-0000-0000-000000000002', 'oxygen', 'O2_CYLINDER', 'Oxygen cylinders', 'ஆக்சிஜன்', 'available', 30, 40),

  -- CHC Chengam
  ('55555555-0003-0000-0000-000000000003', 'doctor', 'MO_GENERAL', 'Medical officers', 'மருத்துவ அதிகாரிகள்', 'available', 4, 5),
  ('55555555-0003-0000-0000-000000000003', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 180, 200),
  ('55555555-0003-0000-0000-000000000003', 'essential_medicine', 'ASV', 'Anti-snake venom', 'பாம்பு விஷ முறிவு மருந்து', 'limited', 4, 15),
  ('55555555-0003-0000-0000-000000000003', 'diagnostic', 'XRAY', 'X-ray', 'எக்ஸ்-ரே', 'available', 1, 1),
  ('55555555-0003-0000-0000-000000000003', 'diagnostic', 'USG', 'Ultrasound', 'அல்ட்ராசவுண்ட்', 'limited', 1, 1),
  ('55555555-0003-0000-0000-000000000003', 'bed', 'GENERAL_BED', 'General beds', 'பொது படுக்கைகள்', 'available', 22, 30),
  ('55555555-0003-0000-0000-000000000003', 'oxygen', 'O2_CYLINDER', 'Oxygen cylinders', 'ஆக்சிஜன்', 'available', 10, 12),

  -- PHC Polur: doctor on leave, weak readiness on purpose
  ('55555555-0004-0000-0000-000000000004', 'doctor', 'MO_GENERAL', 'Medical officers', 'மருத்துவ அதிகாரிகள்', 'unavailable', 0, 2),
  ('55555555-0004-0000-0000-000000000004', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 60, 80),
  ('55555555-0004-0000-0000-000000000004', 'diagnostic', 'LAB', 'Basic lab', 'அடிப்படை ஆய்வகம்', 'limited', 1, 1),
  ('55555555-0004-0000-0000-000000000004', 'bed', 'GENERAL_BED', 'Observation beds', 'கண்காணிப்பு படுக்கைகள்', 'available', 4, 6),

  -- PHC Thandarampattu
  ('55555555-0005-0000-0000-000000000005', 'doctor', 'MO_GENERAL', 'Medical officers', 'மருத்துவ அதிகாரிகள்', 'available', 2, 2),
  ('55555555-0005-0000-0000-000000000005', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 90, 100),
  ('55555555-0005-0000-0000-000000000005', 'essential_medicine', 'ASV', 'Anti-snake venom', 'பாம்பு விஷ முறிவு மருந்து', 'limited', 2, 10),
  ('55555555-0005-0000-0000-000000000005', 'diagnostic', 'LAB', 'Basic lab', 'அடிப்படை ஆய்வகம்', 'available', 1, 1),
  ('55555555-0005-0000-0000-000000000005', 'bed', 'GENERAL_BED', 'Labour and observation beds', 'படுக்கைகள்', 'available', 8, 10),
  ('55555555-0005-0000-0000-000000000005', 'oxygen', 'O2_CYLINDER', 'Oxygen cylinders', 'ஆக்சிஜன்', 'limited', 2, 4),

  -- Sub centre
  ('55555555-0006-0000-0000-000000000006', 'nurse', 'ANM', 'ANM', 'ஏ.என்.எம்', 'available', 1, 1),
  ('55555555-0006-0000-0000-000000000006', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 40, 50),

  -- HWC Vengikkal
  ('55555555-0007-0000-0000-000000000007', 'doctor', 'MO_GENERAL', 'Medical officer', 'மருத்துவ அதிகாரி', 'available', 1, 1),
  ('55555555-0007-0000-0000-000000000007', 'essential_medicine', 'ORS', 'ORS packets', 'ஓ.ஆர்.எஸ்', 'available', 70, 80),
  ('55555555-0007-0000-0000-000000000007', 'diagnostic', 'LAB', 'Basic lab', 'அடிப்படை ஆய்வகம்', 'limited', 1, 1),
  ('55555555-0007-0000-0000-000000000007', 'bed', 'GENERAL_BED', 'Observation beds', 'கண்காணிப்பு படுக்கைகள்', 'available', 2, 4);

-- ---------------------------------------------------------------------------
-- Symptom catalogue (PRD 6 FR-004). Tamil is the primary label.
-- ---------------------------------------------------------------------------
insert into public.symptom_catalog (code, name_en, name_ta, body_system, is_common, icon_key, display_order) values
  ('fever',                  'Fever',                       'காய்ச்சல்',                        'general',      true,  'thermometer', 10),
  ('cough',                  'Cough',                       'இருமல்',                          'respiratory',  true,  'lungs', 20),
  ('breathlessness',         'Breathlessness',              'மூச்சுத் திணறல்',                  'respiratory',  true,  'air', 30),
  ('chest_pain',             'Chest pain',                  'மார்பு வலி',                      'cardiac',      true,  'heart', 40),
  ('headache',               'Headache',                    'தலைவலி',                          'neurological', true,  'head', 50),
  ('abdominal_pain',         'Abdominal pain',              'வயிற்று வலி',                      'digestive',    true,  'stomach', 60),
  ('vomiting',               'Vomiting',                    'வாந்தி',                          'digestive',    true,  'nausea', 70),
  ('diarrhoea',              'Loose motion',                'வயிற்றுப்போக்கு',                  'digestive',    true,  'water', 80),
  ('dizziness',              'Dizziness',                   'தலைசுற்றல்',                      'neurological', false, 'spiral', 90),
  ('unconscious',            'Unconscious',                 'சுயநினைவு இழப்பு',                 'neurological', false, 'alert', 100),
  ('seizure',                'Fits or seizure',             'வலிப்பு',                         'neurological', false, 'alert', 110),
  ('severe_bleeding',        'Heavy bleeding',              'கடுமையான இரத்தப்போக்கு',           'trauma',       false, 'blood', 120),
  ('weakness_one_side',      'Weakness on one side',        'ஒரு பக்கம் பலவீனம்',               'neurological', false, 'alert', 130),
  ('slurred_speech',         'Slurred speech',              'பேச்சுத் தடுமாற்றம்',              'neurological', false, 'speech', 140),
  ('blurred_vision',         'Blurred vision',              'மங்கலான பார்வை',                   'eye',          false, 'eye', 150),
  ('swelling_legs',          'Leg swelling',                'கால் வீக்கம்',                     'cardiac',      false, 'leg', 160),
  ('rash',                   'Skin rash',                   'தோல் அரிப்பு',                     'skin',         true,  'skin', 170),
  ('joint_pain',             'Joint pain',                  'மூட்டு வலி',                      'musculoskeletal', true, 'bone', 180),
  ('back_pain',              'Back pain',                   'முதுகு வலி',                      'musculoskeletal', true, 'spine', 190),
  ('burning_urination',      'Burning urination',           'சிறுநீர் எரிச்சல்',                'urinary',      true,  'drop', 200),
  ('reduced_urine',          'Passing very little urine',   'சிறுநீர் மிகக் குறைவு',            'urinary',      false, 'drop', 210),
  ('yellow_eyes',            'Yellow eyes or skin',         'கண் மற்றும் தோல் மஞ்சள்',          'digestive',    false, 'eye', 220),
  ('weight_loss',            'Unexplained weight loss',     'எடை குறைவு',                      'general',      false, 'scale', 230),
  ('night_sweats',           'Night sweats',                'இரவில் வியர்வை',                   'general',      false, 'sweat', 240),
  ('blood_in_sputum',        'Blood in sputum',             'சளியில் இரத்தம்',                  'respiratory',  false, 'blood', 250),
  ('snake_bite',             'Snake bite',                  'பாம்பு கடி',                      'trauma',       true,  'snake', 260),
  ('dog_bite',               'Dog or animal bite',          'நாய் கடி',                        'trauma',       true,  'paw', 270),
  ('burn_injury',            'Burn injury',                 'தீக்காயம்',                        'trauma',       false, 'fire', 280),
  ('road_injury',            'Road accident injury',        'சாலை விபத்து காயம்',               'trauma',       true,  'car', 290),
  ('poisoning',              'Swallowed poison',            'விஷம் உட்கொள்ளுதல்',               'trauma',       false, 'alert', 300),
  ('labour_pains',           'Labour pains',                'பிரசவ வலி',                       'obstetric',    false, 'baby', 310),
  ('bleeding_pregnancy',     'Bleeding during pregnancy',   'கர்ப்ப காலத்தில் இரத்தப்போக்கு',   'obstetric',    false, 'alert', 320),
  ('reduced_fetal_movement', 'Reduced baby movement',       'கருவின் அசைவு குறைவு',             'obstetric',    false, 'baby', 330),
  ('child_not_feeding',      'Child not feeding',           'குழந்தை பால் குடிக்கவில்லை',        'paediatric',   false, 'baby', 340),
  ('fast_breathing_child',   'Child breathing fast',        'குழந்தையின் வேகமான மூச்சு',        'paediatric',   false, 'air', 350),
  ('sore_throat',            'Sore throat',                 'தொண்டை வலி',                      'ent',          true,  'throat', 360),
  ('ear_pain',               'Ear pain',                    'காது வலி',                        'ent',          true,  'ear', 370),
  ('toothache',              'Toothache',                   'பல்வலி',                          'dental',       true,  'tooth', 380),
  ('eye_redness',            'Red eye',                     'கண் சிவப்பு',                      'eye',          true,  'eye', 390),
  ('low_mood',               'Low mood or anxiety',         'மனச்சோர்வு அல்லது பதற்றம்',        'mental_health', true, 'mind', 400);

-- ---------------------------------------------------------------------------
-- Triage rule set v1 (DEVELOPMENT BASELINE - not clinically approved)
-- ---------------------------------------------------------------------------
insert into public.triage_rule_sets (
  id, version, name, status, clinical_owner, approved_at, effective_from, notes
) values (
  '66666666-0001-0000-0000-000000000001', 1,
  'ArogyaMitra baseline triage v1', 'active',
  'UNASSIGNED - development placeholder', now(), now(),
  'Development baseline for workflow engineering. PRD 16 requires a named '
  'clinical owner and a documented approval before any deployment.'
);

-- Red flags. Evaluated before every other rule (PRD 6 FR-006, 20).
insert into public.triage_rules (
  rule_set_id, code, description, is_red_flag, priority, match,
  risk_level, next_action, required_services, min_facility_tier, advice_key
) values
  ('66666666-0001-0000-0000-000000000001', 'RF_UNRESPONSIVE',
   'Unconscious or actively seizing', true, 990,
   '{"any_symptoms":["unconscious","seizure"]}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','icu'], 3, 'advice.emergency.unresponsive'),

  ('66666666-0001-0000-0000-000000000001', 'RF_SEVERE_BLEEDING',
   'Uncontrolled bleeding', true, 985,
   '{"any_symptoms":["severe_bleeding"]}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','blood_bank'], 3, 'advice.emergency.bleeding'),

  ('66666666-0001-0000-0000-000000000001', 'RF_POISONING',
   'Suspected poisoning', true, 980,
   '{"any_symptoms":["poisoning"]}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','icu'], 3, 'advice.emergency.poisoning'),

  ('66666666-0001-0000-0000-000000000001', 'RF_SNAKE_BITE',
   'Snake bite - time critical, needs anti-snake venom', true, 975,
   '{"any_symptoms":["snake_bite"]}'::jsonb,
   'emergency', 'emergency_response', array['snakebite_care','emergency_care'], 2, 'advice.emergency.snakebite'),

  ('66666666-0001-0000-0000-000000000001', 'RF_STROKE',
   'Suspected stroke - one sided weakness or speech difficulty', true, 970,
   '{"any_symptoms":["weakness_one_side","slurred_speech"]}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','ct_scan'], 4, 'advice.emergency.stroke'),

  ('66666666-0001-0000-0000-000000000001', 'RF_CARDIAC_CHEST_PAIN',
   'Chest pain at cardiac risk age', true, 965,
   '{"any_symptoms":["chest_pain"],"min_age":35}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','ecg'], 3, 'advice.emergency.chest_pain'),

  ('66666666-0001-0000-0000-000000000001', 'RF_RESPIRATORY_DISTRESS',
   'Severe breathlessness', true, 960,
   '{"any_symptoms":["breathlessness"],"min_severity":4}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','icu'], 3, 'advice.emergency.breathlessness'),

  ('66666666-0001-0000-0000-000000000001', 'RF_OBSTETRIC_BLEEDING',
   'Bleeding in pregnancy', true, 955,
   '{"any_symptoms":["bleeding_pregnancy"]}'::jsonb,
   'emergency', 'emergency_response', array['obstetrics','emergency_care','blood_bank'], 3, 'advice.emergency.obstetric_bleeding'),

  ('66666666-0001-0000-0000-000000000001', 'RF_LABOUR',
   'Labour pains', true, 950,
   '{"any_symptoms":["labour_pains"]}'::jsonb,
   'emergency', 'emergency_response', array['obstetrics'], 2, 'advice.emergency.labour'),

  ('66666666-0001-0000-0000-000000000001', 'RF_FETAL_DISTRESS',
   'Reduced fetal movement', true, 945,
   '{"any_symptoms":["reduced_fetal_movement"]}'::jsonb,
   'emergency', 'emergency_response', array['obstetrics','ultrasound'], 2, 'advice.emergency.fetal_movement'),

  ('66666666-0001-0000-0000-000000000001', 'RF_SICK_CHILD',
   'Danger sign in a child under five', true, 940,
   '{"any_symptoms":["child_not_feeding","fast_breathing_child"],"max_age":5}'::jsonb,
   'emergency', 'emergency_response', array['paediatrics','emergency_care'], 2, 'advice.emergency.sick_child'),

  ('66666666-0001-0000-0000-000000000001', 'RF_MAJOR_TRAUMA',
   'Significant road traffic injury', true, 935,
   '{"any_symptoms":["road_injury"],"min_severity":3}'::jsonb,
   'emergency', 'emergency_response', array['trauma_care','emergency_care'], 3, 'advice.emergency.trauma'),

  ('66666666-0001-0000-0000-000000000001', 'RF_MAJOR_BURN',
   'Significant burn injury', true, 930,
   '{"any_symptoms":["burn_injury"],"min_severity":3}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','trauma_care'], 3, 'advice.emergency.burn'),

  ('66666666-0001-0000-0000-000000000001', 'RF_ANURIA',
   'Minimal urine output', true, 925,
   '{"any_symptoms":["reduced_urine"],"min_severity":4}'::jsonb,
   'emergency', 'emergency_response', array['emergency_care','nephrology_dialysis'], 3, 'advice.emergency.anuria');

-- High risk: needs a doctor today, referred to at least a CHC.
insert into public.triage_rules (
  rule_set_id, code, description, is_red_flag, priority, match,
  risk_level, next_action, required_services, min_facility_tier, advice_key
) values
  ('66666666-0001-0000-0000-000000000001', 'HR_ANIMAL_BITE',
   'Animal bite - needs wound care and rabies prophylaxis', false, 800,
   '{"any_symptoms":["dog_bite"]}'::jsonb,
   'high', 'refer', array['rabies_prophylaxis','emergency_care'], 2, 'advice.high.animal_bite'),

  ('66666666-0001-0000-0000-000000000001', 'HR_HAEMOPTYSIS',
   'Blood in sputum - rule out TB', false, 790,
   '{"any_symptoms":["blood_in_sputum"]}'::jsonb,
   'high', 'refer', array['tb_dots','xray','lab_basic'], 2, 'advice.high.haemoptysis'),

  ('66666666-0001-0000-0000-000000000001', 'HR_TB_SUSPECT',
   'Cough over two weeks with weight loss or night sweats', false, 785,
   '{"all_symptoms":["cough"],"any_symptoms":["weight_loss","night_sweats"],"min_duration_hours":336}'::jsonb,
   'high', 'refer', array['tb_dots','xray','lab_basic'], 2, 'advice.high.tb_suspect'),

  ('66666666-0001-0000-0000-000000000001', 'HR_JAUNDICE',
   'Jaundice', false, 780,
   '{"any_symptoms":["yellow_eyes"]}'::jsonb,
   'high', 'refer', array['lab_basic','general_opd'], 2, 'advice.high.jaundice'),

  ('66666666-0001-0000-0000-000000000001', 'HR_BREATHLESS',
   'Breathlessness below emergency threshold', false, 775,
   '{"any_symptoms":["breathlessness"]}'::jsonb,
   'high', 'refer', array['emergency_care','ecg','xray'], 2, 'advice.high.breathlessness'),

  ('66666666-0001-0000-0000-000000000001', 'HR_CHEST_PAIN_YOUNG',
   'Chest pain below cardiac risk age', false, 770,
   '{"any_symptoms":["chest_pain"]}'::jsonb,
   'high', 'refer', array['ecg','general_opd'], 2, 'advice.high.chest_pain_young'),

  ('66666666-0001-0000-0000-000000000001', 'HR_PERSISTENT_FEVER',
   'High fever lasting more than three days', false, 765,
   '{"any_symptoms":["fever"],"min_severity":4,"min_duration_hours":72}'::jsonb,
   'high', 'refer', array['lab_basic','general_opd'], 2, 'advice.high.persistent_fever'),

  ('66666666-0001-0000-0000-000000000001', 'HR_PREGNANCY_ANY',
   'Any symptom during pregnancy needs review', false, 760,
   '{"pregnant":true}'::jsonb,
   'high', 'refer', array['obstetrics'], 2, 'advice.high.pregnancy'),

  ('66666666-0001-0000-0000-000000000001', 'HR_DIABETIC_INFECTION',
   'Fever in a person with diabetes', false, 755,
   '{"any_symptoms":["fever"],"chronic_any":["diabetes"]}'::jsonb,
   'high', 'refer', array['lab_basic','general_opd'], 2, 'advice.high.diabetes_fever'),

  ('66666666-0001-0000-0000-000000000001', 'HR_CARDIAC_HISTORY',
   'Swelling or dizziness with a cardiac history', false, 750,
   '{"any_symptoms":["swelling_legs","dizziness"],"chronic_any":["heart_disease","hypertension"]}'::jsonb,
   'high', 'refer', array['ecg','general_opd'], 2, 'advice.high.cardiac_history');

-- Medium risk: see a clinician, nearest suitable facility is fine.
insert into public.triage_rules (
  rule_set_id, code, description, is_red_flag, priority, match,
  risk_level, next_action, required_services, min_facility_tier, advice_key
) values
  ('66666666-0001-0000-0000-000000000001', 'MR_DEHYDRATION',
   'Vomiting with loose motion', false, 600,
   '{"all_symptoms":["vomiting","diarrhoea"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd','pharmacy'], 1, 'advice.medium.dehydration'),

  ('66666666-0001-0000-0000-000000000001', 'MR_ABDOMINAL_PAIN',
   'Moderate or worse abdominal pain', false, 590,
   '{"any_symptoms":["abdominal_pain"],"min_severity":3}'::jsonb,
   'medium', 'visit_facility', array['general_opd','lab_basic'], 1, 'advice.medium.abdominal_pain'),

  ('66666666-0001-0000-0000-000000000001', 'MR_FEBRILE_ILLNESS',
   'Fever with cough', false, 580,
   '{"all_symptoms":["fever","cough"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd','lab_basic'], 1, 'advice.medium.febrile_illness'),

  ('66666666-0001-0000-0000-000000000001', 'MR_URINARY_INFECTION',
   'Burning urination', false, 570,
   '{"any_symptoms":["burning_urination"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd','lab_basic'], 1, 'advice.medium.uti'),

  ('66666666-0001-0000-0000-000000000001', 'MR_CHRONIC_JOINT_PAIN',
   'Joint pain lasting over a week', false, 560,
   '{"any_symptoms":["joint_pain"],"min_duration_hours":168}'::jsonb,
   'medium', 'visit_facility', array['general_opd'], 1, 'advice.medium.joint_pain'),

  ('66666666-0001-0000-0000-000000000001', 'MR_MENTAL_HEALTH',
   'Low mood or anxiety - teleconsultation is appropriate', false, 550,
   '{"any_symptoms":["low_mood"]}'::jsonb,
   'medium', 'teleconsult', array['mental_health'], 2, 'advice.medium.mental_health'),

  ('66666666-0001-0000-0000-000000000001', 'MR_VISION_CHANGE',
   'Blurred vision', false, 540,
   '{"any_symptoms":["blurred_vision"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd'], 1, 'advice.medium.vision'),

  ('66666666-0001-0000-0000-000000000001', 'MR_MINOR_BURN',
   'Minor burn', false, 530,
   '{"any_symptoms":["burn_injury"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd'], 1, 'advice.medium.minor_burn'),

  ('66666666-0001-0000-0000-000000000001', 'MR_MINOR_INJURY',
   'Minor road traffic injury', false, 520,
   '{"any_symptoms":["road_injury"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd','xray'], 1, 'advice.medium.minor_injury'),

  ('66666666-0001-0000-0000-000000000001', 'MR_DENTAL',
   'Toothache', false, 510,
   '{"any_symptoms":["toothache"]}'::jsonb,
   'medium', 'visit_facility', array['general_opd'], 1, 'advice.medium.dental');

-- Low risk: self-care with clear escalation advice. Deliberately narrow -
-- any severity above mild, or a longer duration, stops these matching.
insert into public.triage_rules (
  rule_set_id, code, description, is_red_flag, priority, match,
  risk_level, next_action, required_services, min_facility_tier, advice_key
) values
  ('66666666-0001-0000-0000-000000000001', 'LR_MILD_FEVER',
   'Mild short fever with no other complaint', false, 300,
   '{"any_symptoms":["fever"],"max_severity":2,"max_duration_hours":48,
     "none_symptoms":["breathlessness","chest_pain","rash","vomiting","diarrhoea","seizure","unconscious"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.mild_fever'),

  ('66666666-0001-0000-0000-000000000001', 'LR_MILD_COUGH',
   'Mild recent cough', false, 290,
   '{"any_symptoms":["cough"],"max_severity":2,"max_duration_hours":72,
     "none_symptoms":["breathlessness","blood_in_sputum","weight_loss","night_sweats","fever"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.mild_cough'),

  ('66666666-0001-0000-0000-000000000001', 'LR_MILD_HEADACHE',
   'Mild headache', false, 280,
   '{"any_symptoms":["headache"],"max_severity":2,
     "none_symptoms":["fever","seizure","weakness_one_side","slurred_speech","blurred_vision","vomiting"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.mild_headache'),

  ('66666666-0001-0000-0000-000000000001', 'LR_SORE_THROAT',
   'Mild sore throat', false, 270,
   '{"any_symptoms":["sore_throat"],"max_severity":2,
     "none_symptoms":["breathlessness","fever"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.sore_throat'),

  ('66666666-0001-0000-0000-000000000001', 'LR_MILD_BACK_PAIN',
   'Mild back pain', false, 260,
   '{"any_symptoms":["back_pain"],"max_severity":2,
     "none_symptoms":["fever","weakness_one_side","reduced_urine","burning_urination"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.back_pain'),

  ('66666666-0001-0000-0000-000000000001', 'LR_MILD_RASH',
   'Mild skin rash', false, 250,
   '{"any_symptoms":["rash"],"max_severity":2,"none_symptoms":["fever","breathlessness"]}'::jsonb,
   'low', 'self_care', array['general_opd'], 1, 'advice.low.rash');

-- ---------------------------------------------------------------------------
-- Notification templates (PRD 18)
-- ---------------------------------------------------------------------------
insert into public.notification_templates (
  key, event_type, channel, audience_role, title_en, title_ta, body_en, body_ta, is_optional
) values
  ('referral_created.citizen', 'referral.created', 'in_app', 'citizen',
   'Referral created', 'பரிந்துரை உருவாக்கப்பட்டது',
   'Your referral {{reference_code}} to {{facility_name}} has been created.',
   'உங்கள் பரிந்துரை {{reference_code}} {{facility_name}} க்கு உருவாக்கப்பட்டது.', false),

  ('referral_sent.mo', 'referral.referral_sent', 'in_app', 'medical_officer',
   'New incoming referral', 'புதிய பரிந்துரை வந்துள்ளது',
   'Referral {{reference_code}} for {{patient_name}} is awaiting your decision.',
   '{{patient_name}} க்கான பரிந்துரை {{reference_code}} உங்கள் முடிவுக்கு காத்திருக்கிறது.', false),

  ('referral_accepted.citizen', 'referral.accepted', 'in_app', 'citizen',
   'Referral accepted', 'பரிந்துரை ஏற்கப்பட்டது',
   '{{facility_name}} has accepted referral {{reference_code}}. Please proceed.',
   '{{facility_name}} உங்கள் பரிந்துரை {{reference_code}} ஏற்றுக்கொண்டது. தயவுசெய்து செல்லுங்கள்.', false),

  ('referral_accepted.asha', 'referral.accepted', 'in_app', 'asha',
   'Referral accepted', 'பரிந்துரை ஏற்கப்பட்டது',
   '{{facility_name}} accepted referral {{reference_code}} for {{patient_name}}.',
   '{{patient_name}} க்கான பரிந்துரை {{reference_code}} {{facility_name}} ஏற்றுக்கொண்டது.', false),

  ('referral_rejected.citizen', 'referral.rejected', 'in_app', 'citizen',
   'Referral not accepted', 'பரிந்துரை ஏற்கப்படவில்லை',
   'Referral {{reference_code}} was not accepted. We are finding another facility.',
   'பரிந்துரை {{reference_code}} ஏற்கப்படவில்லை. வேறு மருத்துவமனை தேடப்படுகிறது.', false),

  ('referral_rejected.asha', 'referral.rejected', 'in_app', 'asha',
   'Referral rejected', 'பரிந்துரை மறுக்கப்பட்டது',
   'Referral {{reference_code}} for {{patient_name}} was rejected.',
   '{{patient_name}} க்கான பரிந்துரை {{reference_code}} மறுக்கப்பட்டது.', false),

  ('referral_escalated.citizen', 'referral.emergency_escalated', 'in_app', 'citizen',
   'Emergency help is being arranged', 'அவசர உதவி ஏற்பாடு செய்யப்படுகிறது',
   'Emergency care is being arranged for referral {{reference_code}}. Stay where you are.',
   'பரிந்துரை {{reference_code}} க்கு அவசர சிகிச்சை ஏற்பாடு செய்யப்படுகிறது. அங்கேயே இருங்கள்.', false),

  ('referral_escalated.mo', 'referral.emergency_escalated', 'in_app', 'medical_officer',
   'Emergency escalation', 'அவசர நிலை உயர்த்தப்பட்டது',
   'Referral {{reference_code}} for {{patient_name}} has been escalated as an emergency.',
   '{{patient_name}} க்கான பரிந்துரை {{reference_code}} அவசர நிலையாக உயர்த்தப்பட்டது.', false),

  ('followup_due.asha', 'followup.due', 'in_app', 'asha',
   'Follow-up due today', 'இன்று பின்தொடர்தல் உள்ளது',
   'Follow-up for {{patient_name}} is due today.',
   '{{patient_name}} க்கான பின்தொடர்தல் இன்று செய்ய வேண்டும்.', false),

  ('followup_due.citizen', 'followup.due', 'in_app', 'citizen',
   'Health follow-up reminder', 'சுகாதார பின்தொடர்தல் நினைவூட்டல்',
   'Your health follow-up is due today.',
   'உங்கள் சுகாதார பின்தொடர்தல் இன்று உள்ளது.', false);

-- ---------------------------------------------------------------------------
-- Readiness baseline for every facility
-- ---------------------------------------------------------------------------
do $$
declare
  v_facility uuid;
begin
  for v_facility in select id from public.facilities loop
    perform app.compute_readiness(v_facility);
  end loop;
end;
$$;
