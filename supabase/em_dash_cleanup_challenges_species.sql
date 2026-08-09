-- Removes em dashes ("—") from daily_challenges / challenge_templates
-- (title, question, description, fun_fact, correct_answer) and from
-- plant_species (medicinal_uses, economic_importance, ecological_importance,
-- environmental_benefits), replacing each with whichever of comma / period /
-- semicolon / parentheses reads most naturally for that sentence. Part of
-- the same broader punctuation pass as care_field_em_dash_cleanup.sql and
-- ornamental_planting_advice.sql. Does NOT touch water_requirements,
-- sunlight_requirements, or planting_advice on plant_species (already
-- fixed), and does not touch en dashes (e.g. "23–35%", "5–8 cm") which are
-- correct as-is for number ranges.
--
-- Run in the Supabase SQL editor, or via:
--   npx supabase db query --linked < supabase/em_dash_cleanup_challenges_species.sql

-- ============================================================
-- daily_challenges (14 rows, in id order)
-- ============================================================

UPDATE daily_challenges SET fun_fact =
'Neem is called Ghana''s village pharmacy; its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'
WHERE id = '08c18c1c-9ccc-4ae2-8e23-0254dff11f61';

UPDATE daily_challenges SET fun_fact =
'Elaeis guineensis is native to West Africa (including Ghana). It produces more oil per hectare than any other crop on Earth.'
WHERE id = '11dd0493-00a9-4372-8c28-25fec783ffab';

UPDATE daily_challenges SET fun_fact =
'Neem is called Ghana''s village pharmacy; its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'
WHERE id = '27826d7c-b52a-491d-b790-ec040d14e2df';

UPDATE daily_challenges SET fun_fact =
'Cassava shares its family with croton, castor oil plant, and copperleaf, all of which also grow on the UENR campus.'
WHERE id = '284a1051-5e98-445e-a91e-301c078eed11';

UPDATE daily_challenges SET question =
'Griffonia simplicifolia seeds (found right here on the UENR campus) contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.'
WHERE id = '485ce73b-2d13-423a-ae28-a7a64061aba4';

UPDATE daily_challenges SET question =
'Griffonia simplicifolia seeds (found right here on the UENR campus) contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.'
WHERE id = '70f1fc1f-2046-422a-9dfc-9c06cc260d71';

UPDATE daily_challenges SET fun_fact =
'Neem is called Ghana''s village pharmacy; its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'
WHERE id = '914d3e3e-df64-4e43-9c31-f9cc92b1f68d';

UPDATE daily_challenges SET fun_fact =
'Newbouldia laevis belongs to Bignoniaceae (the same family as the African Tulip Tree). Gliricidia, Griffonia, and Millettia are all legumes.'
WHERE id = '93badc64-77c5-4520-a4c0-8a16f8133048';

UPDATE daily_challenges SET fun_fact =
'Elaeis guineensis is native to West Africa (including Ghana). It produces more oil per hectare than any other crop on Earth.'
WHERE id = 'a33cc951-33c0-460a-9f2c-5a3a108f0875';

UPDATE daily_challenges SET question =
'Griffonia simplicifolia seeds (found right here on the UENR campus) contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.'
WHERE id = 'bb0cdb1b-f9b6-4843-a9e7-479e6c460872';

UPDATE daily_challenges SET fun_fact =
'Newbouldia laevis belongs to Bignoniaceae (the same family as the African Tulip Tree). Gliricidia, Griffonia, and Millettia are all legumes.'
WHERE id = 'bd60d0d0-50ee-4712-8565-b8244c06ba9d';

UPDATE daily_challenges SET fun_fact =
'Elaeis guineensis is native to West Africa (including Ghana). It produces more oil per hectare than any other crop on Earth.'
WHERE id = 'cd952cfa-f61e-4ab7-9cdc-40b8cb9313ce';

UPDATE daily_challenges SET fun_fact =
'Cassava shares its family with croton, castor oil plant, and copperleaf, all of which also grow on the UENR campus.'
WHERE id = 'd2447eb0-796d-492f-a964-63f54c568b05';

UPDATE daily_challenges SET fun_fact =
'Cassava shares its family with croton, castor oil plant, and copperleaf, all of which also grow on the UENR campus.'
WHERE id = 'f14157e4-29b7-437e-b77a-5c203ab12801';

-- ============================================================
-- challenge_templates (5 rows, in id order)
-- ============================================================

UPDATE challenge_templates SET fun_fact =
'Cassava shares its family with croton, castor oil plant, and copperleaf, all of which also grow on the UENR campus.'
WHERE id = '0f8fd667-b354-4536-a413-3fdd5af244dd';

UPDATE challenge_templates SET fun_fact =
'Neem is called Ghana''s village pharmacy; its bark, leaves, and seeds treat over 40 health conditions in traditional medicine.'
WHERE id = '1e1b97c3-3525-4d02-9dbb-d181ed2d1a8f';

UPDATE challenge_templates SET fun_fact =
'Elaeis guineensis is native to West Africa (including Ghana). It produces more oil per hectare than any other crop on Earth.'
WHERE id = '87849771-f083-40e3-a6c4-19fb38e8d128';

UPDATE challenge_templates SET question =
'Griffonia simplicifolia seeds (found right here on the UENR campus) contain up to 20% 5-HTP by weight, making Ghana''s the world''s primary supplier of this mental health supplement.'
WHERE id = '9caeed28-bcca-4168-9388-c51b737fc7e9';

UPDATE challenge_templates SET fun_fact =
'Newbouldia laevis belongs to Bignoniaceae (the same family as the African Tulip Tree). Gliricidia, Griffonia, and Millettia are all legumes.'
WHERE id = 'b235065e-3e0e-4d74-b16a-e93388567068';

-- ============================================================
-- plant_species (24 rows, in id order)
-- ============================================================

-- Alchornea cordifolia (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'One of the most widely used medicinal plants in West African traditional medicine. Leaves, bark, and roots are used to treat wound infections, malaria, gonorrhoea, fever, and skin diseases across Ghana, Nigeria, and Cameroon; antimicrobial and anti-inflammatory activities confirmed in multiple peer-reviewed studies.'
WHERE id = '1c131e5c-fdb8-4b8c-932e-fe8e0ea28ee5';

-- Jatropha curcas (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Seeds yield oil used in traditional medicine across West Africa as a purgative and for skin conditions; bark used for wounds. CAUTION: seeds contain curcin, a highly toxic lectin; never consume raw seeds.'
WHERE id = '20e74c05-55f3-4559-8148-1cca3c6b8a68';

-- Broussonetia papyrifera (ecological_importance)
UPDATE plant_species SET ecological_importance =
'Fleshy red fruit is a major food source for fruit bats and birds; plays a documented role in bat seed dispersal at UENR campus; pioneer species that rapidly colonises disturbed areas.'
WHERE id = '237a0f1b-e0c9-4a8d-8b2a-5dc9b77b2633';

-- Mimosa pudica (economic_importance)
UPDATE plant_species SET economic_importance =
'One of the most effective live demonstration plants for teaching plant physiology. The rapid leaf-folding response to touch is an immediate, visible illustration of plant sensory systems for UENR students.'
WHERE id = '35e0f937-e993-4186-a944-9c89f02c75ad';

-- Bambusa vulgaris (economic_importance + environmental_benefits)
UPDATE plant_species SET
  economic_importance = 'One of Ghana''s most important construction and handicraft materials. Culms used for building, furniture, scaffolding, and basketry; Bambusa vulgaris is the most commonly planted bamboo species in West Africa.',
  environmental_benefits = 'Among the fastest-growing plants on Earth (culms can grow 30 cm per day); exceptional CO2 sequestration rate; root system prevents severe erosion on slopes and riverbanks; culturally important building material across Ghana (top use index in Volta Region ethnobotany study).'
WHERE id = '5165b6ba-c867-4c99-bcc8-e8dd75fde936';

-- Solanum torvum (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Fruits used in Ghanaian traditional medicine for diabetes management, hypertension, sickle cell anaemia, and anaemia; leaves applied for skin conditions. Note: raw unripe fruits contain solanine; should be cooked before consumption.'
WHERE id = '5486e02f-e603-4598-98fe-975de6d649f6';

-- Manihot esculenta (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Leaves used in West African traditional medicine for headaches, fever, and hypertension; roots applied topically for wound healing. Caution: raw roots and leaves contain cyanogenic compounds; always cook thoroughly.'
WHERE id = '54ac116f-8393-468d-b683-8009e7f28676';

-- Caladium spp. (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'CAUTION: ALL PARTS HIGHLY TOXIC. Calcium oxalate crystals cause intense burning pain and swelling if ingested or if sap contacts mucous membranes. Keep away from children and pets. Some traditional uses reported in South American folk medicine despite toxicity.'
WHERE id = '55b63b4b-7bdc-41f5-9049-211ce3c5eb67';

-- Leucaena leucocephala (economic_importance)
UPDATE plant_species SET economic_importance =
'One of the world''s most important agroforestry trees. Used for livestock fodder (leaf protein content 23–35%), fuelwood, green manure, and live fencing across Ghana''s Northern and Brong-Ahafo regions.'
WHERE id = '5e0afcde-844b-4273-9a89-b902765c7d2a';

-- Moringa oleifera (medicinal_uses + environmental_benefits)
UPDATE plant_species SET
  medicinal_uses = 'One of the most nutritionally dense trees known. Leaves contain more vitamin C than oranges, more calcium than milk, and more iron than spinach; used in Ghanaian traditional medicine for malnutrition, anaemia, diabetes, inflammation, and fever; fourth highest medicinal use value (SUV = 10.3) in Brong Ahafo community medicinal tree study.',
  environmental_benefits = 'Drought-resistant pioneer that recovers quickly after cutting; seeds used as a natural coagulant to purify water (one of the most practical and affordable water purification methods in resource-limited tropical settings).'
WHERE id = '6a024f9c-4978-4b16-9d30-20770d8143e0';

-- Persea americana (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Fruit is nutritionally dense (highest fat content of any fruit, rich in potassium and vitamins E and K); leaves used in Ghanaian traditional medicine for hypertension and kidney stones; seed and leaf extracts studied for antimicrobial and antioxidant properties.'
WHERE id = '7e3aa75f-d3c5-431d-9744-cea227d26903';

-- Ficus benjamina (economic_importance)
UPDATE plant_species SET economic_importance =
'One of the world''s most widely planted ornamental trees on Ghanaian campuses; also a major global indoor plant (pot culture). It is a different species from Chinese Banyan (Ficus microcarpa), already in the database.'
WHERE id = '83d78e2c-ff18-4390-a7ee-9b89000676d4';

-- Musa × paradisiaca (economic_importance)
UPDATE plant_species SET economic_importance =
'Ghana''s most consumed cooking banana; plantain forms the basis of kelewele, ampesi, and fufu (culturally and nutritionally indispensable in the Brong-Ahafo diet).'
WHERE id = '8f97d8dc-8b1f-4306-8920-bd181fcf2987';

-- Blighia sapida (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Arils (cream-coloured seed coverings) eaten cooked across Ghana and West Africa. CAUTION: Only eat arils from naturally split open, fully ripe fruit; unripe arils contain hypoglycin A, a toxin causing Jamaican Vomiting Sickness. Seeds are always inedible and poisonous. Leaves and bark used in Ghanaian traditional medicine for stomach upset, diarrhoea, and migraine.'
WHERE id = '92d6c914-4ad4-425e-ba51-a51af8576a2e';

-- Azadirachta indica (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Among the most widely used medicinal trees in Ghanaian herbal practice. Bark, leaves, and seeds treat malaria, fever, skin disorders, and bacterial infections; neem oil from seeds has documented antimicrobial and antifungal properties.'
WHERE id = '9c6447bd-1914-4fd5-8300-649ab726a7ad';

-- Newbouldia laevis (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Among the most important traditional medicine plants in Ghana and West Africa. Bark, roots, and leaves used to treat epilepsy, fever, skin conditions, uterine colic, and inflammation; antimicrobial and anticonvulsant properties confirmed in peer-reviewed studies.'
WHERE id = '9f48c647-d4c5-411e-a6ee-be132583a02d';

-- Ricinus communis (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Castor oil (from seeds) used in Ghanaian traditional medicine as a purgative, skin emollient, and for treating constipation; bark and leaves applied topically for inflammation. Caution: seeds contain ricin, extremely toxic; never consume raw seeds.'
WHERE id = 'aa0ff7a1-3c50-4d49-9056-4b356d4b4a1c';

-- Tetrapleura tetraptera (economic_importance)
UPDATE plant_species SET economic_importance =
'Known as Prekese in Twi. Pods are a key flavouring ingredient in Ghanaian cooking, particularly for soups, stews, and drinks including Prekese tea; pods and bark have a significant traditional medicine market in Sunyani and across Bono Ahafo.'
WHERE id = 'ab29afba-a76c-4d62-a696-d8e0f5016880';

-- Ficus exasperata (ecological_importance)
UPDATE plant_species SET ecological_importance =
'Keystone fig species; figs provide critical food for birds, bats, and primates; documented in UENR campus bat dispersal study (6.6% of bat-dispersed seeds, Agyei-Ohemeng et al. 2016); pioneer in secondary forest regeneration.'
WHERE id = 'ca78b403-20fd-4416-b712-4b860b83e967';

-- Zea mays (economic_importance)
UPDATE plant_species SET economic_importance =
'Ghana''s most important cereal crop; basis of kenkey, banku, tuo zaafi, and akpeteshie; production concentrated in Northern and Brong-Ahafo regions.'
WHERE id = 'ceee4a35-74ed-4bd2-a976-3948bb099eef';

-- Breynia disticha (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Limited documented medicinal uses. Caution: some sources report mild toxicity; handle with care.'
WHERE id = 'd6f85cd4-0428-4c1f-b2d5-c9403c9aeafc';

-- Griffonia simplicifolia (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Seeds contain up to 20% 5-hydroxytryptophan (5-HTP) by weight, the most concentrated natural source of this serotonin precursor; 5-HTP is used globally as a supplement for depression, insomnia, and anxiety; traditional uses documented for mood enhancement and wound healing.'
WHERE id = 'e608cda4-1cdc-41fb-b0f8-b6b96f17020f';

-- Nerium oleander (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'CAUTION: ALL PARTS OF THIS PLANT ARE HIGHLY TOXIC to humans, pets, and livestock (including the smoke from burning it and honey made from its nectar). Do not handle without gloves. Despite its toxicity, bark extracts have documented antimicrobial and anticancer properties in laboratory research.'
WHERE id = 'f68b997c-eb5f-49a6-8cba-faebb8e72356';

-- Duranta erecta (medicinal_uses)
UPDATE plant_species SET medicinal_uses =
'Traditional folk medicine uses documented in Caribbean and Latin America. Caution: berries are toxic to humans and pets; do not consume.'
WHERE id = 'fb6b9630-ab82-4bb7-89ed-c31c07a16839';
