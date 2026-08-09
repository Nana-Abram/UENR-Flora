-- Removes em dashes ("—") from plant_species.origin and .flowering_season,
-- the last two user-facing plant_species columns that still had them after
-- ornamental_planting_advice.sql / care_field_em_dash_cleanup.sql /
-- em_dash_cleanup_challenges_species.sql. Both fields are shown as plain
-- text (Origin/Flowering info tiles on Results and Explorer detail
-- screens), not bulleted, so each rewrite reads as one flowing phrase.
--
-- Note: plant_species also has 4 rows with an em dash in
-- bark_description, deliberately left alone — that field (along with the
-- other morphology columns: leaf_arrangement, leaf_margin, venation,
-- leaf_shape, leaf_texture, flower_description, fruit_description) is
-- never rendered in the app UI; it exists only to give the background
-- Claude re-identification prompt richer text to compare a photo against
-- (see PlantSpecies' own doc comment / SpeciesMetadata), so it's out of
-- scope for "app text" cleanup.

UPDATE plant_species SET origin = 'West and Central Africa (native from Senegal to Democratic Republic of Congo)' WHERE scientific_name = 'Alchornea cordifolia';
UPDATE plant_species SET origin = 'West Africa (native to Ghana, Nigeria, Cameroon, Côte d''Ivoire; introduced to Jamaica in 1776)' WHERE scientific_name = 'Blighia sapida';
UPDATE plant_species SET origin = 'East Asia (China, Japan, Korea), now widely naturalised' WHERE scientific_name = 'Broussonetia papyrifera';
UPDATE plant_species SET origin = 'West Africa (native from Nigeria to Democratic Republic of Congo)' WHERE scientific_name = 'Dracaena trifasciata';
UPDATE plant_species SET origin = 'West and Central Africa (native from Guinea to Angola)' WHERE scientific_name = 'Elaeis guineensis';
UPDATE plant_species SET origin = 'West and Central Africa (native to Ghana, Côte d''Ivoire, Nigeria, Togo, Cameroon)' WHERE scientific_name = 'Griffonia simplicifolia';
UPDATE plant_species SET origin = 'Tropical Asia (China, India; uncertain wild origin)' WHERE scientific_name = 'Hibiscus rosa-sinensis';
UPDATE plant_species SET origin = 'SE Asia and India (India, Sri Lanka, Malaysia; now widely cultivated pantropically)' WHERE scientific_name = 'Ixora coccinea';
UPDATE plant_species SET origin = 'Indian subcontinent (India, Pakistan, Nepal), now pantropical in cultivation' WHERE scientific_name = 'Moringa oleifera';
UPDATE plant_species SET origin = 'West and Central Africa (native from Senegal to Democratic Republic of Congo)' WHERE scientific_name = 'Newbouldia laevis';
UPDATE plant_species SET origin = 'West and Central Africa (native from Senegal to Uganda; widely introduced across tropics)' WHERE scientific_name = 'Spathodea campanulata';
UPDATE plant_species SET origin = 'Southeast Asia (India, Malaysia), now widely naturalised in the tropics' WHERE scientific_name = 'Syzygium jambos';
UPDATE plant_species SET origin = 'West Africa (native from Senegal to Congo, including Ghana)' WHERE scientific_name = 'Tetrapleura tetraptera';
UPDATE plant_species SET origin = 'West and Central Africa (native to Ghana, Nigeria, Cameroon, Côte d''Ivoire)' WHERE scientific_name = 'Voacanga africana';

UPDATE plant_species SET flowering_season = 'Sporadic; bamboo very rarely flowers (decades apart); grown for culm production' WHERE scientific_name = 'Bambusa vulgaris';
UPDATE plant_species SET flowering_season = 'Jan–May (white fragrant flowers); flowers and pods produced almost year-round' WHERE scientific_name = 'Moringa oleifera';
