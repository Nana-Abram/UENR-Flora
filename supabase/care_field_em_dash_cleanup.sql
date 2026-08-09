-- Replaces the em dash in water_requirements ("Level — description", all
-- 76 rows followed this exact template) with parentheses, and fixes the
-- two sunlight_requirements rows that used the same pattern. Part of a
-- broader pass removing em dashes from user-facing app text in favour of
-- commas/periods/parentheses/semicolons — see also
-- ornamental_planting_advice.sql for the (larger) planting_advice pass.

UPDATE plant_species
SET water_requirements = trim(split_part(water_requirements, '—', 1)) || ' (' || trim(split_part(water_requirements, '—', 2)) || ')'
WHERE water_requirements LIKE '%—%';

UPDATE plant_species SET sunlight_requirements = 'Full sun to full shade (remarkable adaptability)'
WHERE scientific_name = 'Tradescantia spathacea';

UPDATE plant_species SET sunlight_requirements = 'Full sun to full shade (extremely adaptable)'
WHERE scientific_name = 'Dracaena trifasciata';
