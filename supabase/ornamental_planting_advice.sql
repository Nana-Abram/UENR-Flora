-- Adds WHEN/HOW/WHERE campus planting guidance for ornamental species,
-- backing the "Planting Guide" tab on the species detail screen (Results
-- screen + Explorer's plant_detail_modal), see PlantingGuideTab and
-- PlantSpecies.plantingAdvice. Only species with growth_type = 'ornamental'
-- AND a non-null planting_advice show the tab. Two ornamental species
-- (Plumeria pudica, Terminalia mantaly) intentionally have no row below and
-- so simply won't show the tab until advice is authored for them.
--
-- Run in the Supabase SQL editor, or via:
--   npx supabase db query --linked < supabase/ornamental_planting_advice.sql

ALTER TABLE plant_species
ADD COLUMN IF NOT EXISTS planting_advice TEXT;

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the start of the rainy season (April–May) when soil moisture is reliable. Avoid transplanting during the dry harmattan months (November–February) as the plant will struggle to establish roots without consistent water.

HOW: Dig a hole twice the width of the root ball and the same depth. Mix the removed soil with organic compost at a ratio of 3:1 before backfilling. Water deeply immediately after planting and apply a layer of mulch 5–8 cm thick around the base to retain moisture. Space individual plants at least 1.5 metres apart to allow for the spreading rosette to develop without crowding.

WHERE: Best suited for dry, sunny border areas where irrigation is minimal or unavailable (particularly the open rocky margins along the eastern boundary of campus, the slopes near the engineering block, or any area where soil is sandy and drainage is excellent). Avoid planting near footpaths as the leaf tips, while soft, can still be uncomfortable at close range. Works well as a statement specimen in a large planted bed or as a focal point in a low-maintenance landscape zone.'
WHERE scientific_name = 'Agave attenuata';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. Aloe vera is one of the most forgiving plants for transplanting. The start of the wet season (April) is ideal for fastest establishment, but potted specimens can go in the ground year-round if given one or two deep waterings after planting.

HOW: Use a well-drained sandy or loamy mix. The crown of the plant (where leaves meet the root) must sit at or slightly above soil level; planting too deep causes root rot. Do not amend with heavy clay soils. For groupings, space plants 60–80 cm apart. Remove any damaged or yellowing outer leaves at planting. Water once a week for the first month, then reduce to twice a month once established.

WHERE: Excellent for borders along the medical centre, pharmacy department, or any health-adjacent building; this aligns well with its medicinal identity. Also suitable as edging along sunny paths, in rock gardens, or in decorative pots at building entrances. Requires full sun to partial shade. Avoid heavily shaded spots under large canopy trees as the plant will stretch and weaken.'
WHERE scientific_name = 'Aloe vera';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–September) for fastest establishment. Bowstring Hemp is extremely tolerant of dry conditions once rooted, so wet-season planting gives it the best start with minimal supplemental watering needed.

HOW: This plant tolerates almost any soil but must have excellent drainage; waterlogged soil is the only thing that will kill it quickly. Plant individual rosettes 30–50 cm apart for a groundcover effect, or 60–80 cm apart as standalone specimens. Keep the leaf base above soil level. After planting, water once a week for the first two weeks, then reduce to once a month; overwatering is more harmful than underwatering.

WHERE: One of the best plants for shaded indoor lobbies, covered walkways, and building interiors where natural light is limited. On campus, ideal for the entrance halls of the administration block, library foyer, or lecture hall corridors with indirect light. Outdoors, use as low-maintenance border planting beneath large canopy trees where grass and other groundcovers struggle. Highly suitable anywhere that requires a plant with zero maintenance tolerance.'
WHERE scientific_name = 'Dracaena trifasciata';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the beginning of the rainy season (April–May). Caladium tubers need warmth and consistent moisture to sprout. Dry season planting results in the tuber sitting dormant without establishing. If planting from a potted nursery specimen, any time during the wet months is suitable.

HOW: Plant tubers 5 cm deep with the knobby side facing up. Space 30–40 cm apart for a full border effect. Caladium prefers rich, moist, well-drained soil. Mix in generous compost before planting. Mulch heavily to retain moisture. Keep consistently moist but never waterlogged. Fertilise monthly with a balanced fertiliser during the growing season for the richest leaf colour.

WHERE: Best used in shaded or partially shaded garden beds (beneath trees, along the shaded side of buildings, or in covered courtyard planters). On campus, the shaded garden beds along the library or student centre would be ideal. The vivid red and white leaf patterns make it excellent for decorative display areas and event spaces. Avoid full sun positions as the coloured leaves scorch and fade quickly. Never plant in exposed, windy positions.'
WHERE scientific_name = 'Caladium spp.';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. This species is extremely drought-tolerant and will establish with minimal water at any season. The start of the wet season is easiest for the gardener as watering needs are reduced, but harmattan planting is also viable if given two or three initial waterings.

HOW: Plant in well-drained soil or sandy soil; it will not survive in heavy clay or waterlogged ground. Space 50–70 cm apart for hedge or border use. Wear gloves during planting; the thorny stems cause skin irritation and the milky sap is a strong irritant to eyes and skin. Water twice a week for the first two weeks, then leave it completely. Once established, this plant requires almost no attention.

WHERE: CAUTION. Do not plant near children''s play areas, sports fields, or any heavily trafficked student zones. The plant is toxic and thorny. Best used as a security barrier hedge along the perimeter fence of campus, or as a specimen plant in a fenced ornamental garden where student access is managed. Very effective as a thorny deterrent hedge along boundary walls. Works well in rock gardens or dry landscape features away from main foot traffic.'
WHERE scientific_name = 'Euphorbia milii';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the beginning of the rainy season (April–May) for best establishment. Golden Cane Palm establishes quickly in warm wet conditions. Avoid dry season transplanting for large specimens as palm roots are easily disturbed.

HOW: Dig a hole at least 50 cm wide and 40 cm deep. Palms prefer a slightly acidic, fertile, well-drained soil. Mix compost into the backfill. Plant the root ball level with the surrounding soil. Do not mound soil around the base. Water deeply twice a week for the first month. For the characteristic clumping effect, plant multiple stems together at 1–1.5 metres apart. Fertilise with a palm-specific fertiliser twice a year for rich green colour.

WHERE: Excellent for entrance areas, building fronts, and ceremonial landscaping; the bright yellow-green stems create an immediately welcoming appearance. On campus, ideal for the main entrance road, the vice-chancellor''s courtyard, the administration building front, or as a backdrop to any signage area. Suitable for planter boxes or large containers at building entrances. Partial shade is tolerated but full sun produces the richest stem colour. Avoid exposed, windy hilltop positions as the fronds tear in strong wind.'
WHERE scientific_name = 'Dypsis lutescens';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the start of the rainy season (April–June) when the tree can establish roots before the dry season. Mast Tree transplants poorly when large; plant young nursery stock of 30–60 cm height for best results.

HOW: Dig a hole 60 cm wide and 60 cm deep. This tree develops a strong taproot; deep soil preparation matters more than width. Plant with the root collar at soil level. Water deeply once a week for the first dry season. No pruning is needed; the natural columnar shape develops without intervention. Allow at least 3–4 metres between trees when planting as an avenue, and 5 metres clearance from any building wall to account for the mature height of 20+ metres.

WHERE: The ideal avenue tree for UENR campus roads and pathways; its tall, narrow, columnar form provides shade without spreading widely into road space. Best planted in single or double rows along the main campus roads, outside the administration block, or along the perimeter of sports fields. Also excellent as a windbreak row along the northern boundary of campus. Avoid planting close to power lines due to mature height. Unsuitable for small garden beds; this is a large-scale landscape tree.'
WHERE scientific_name = 'Monoon longifolium';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Ming Aralia establishes readily in warm humid conditions. If planting from cuttings, the wet season provides the moisture needed for rooting.

HOW: Plant in well-drained, slightly sandy loam. Space 60–80 cm apart for hedge use, or 1 metre apart for specimen planting. The plant can be trained into formal shapes. Begin light trimming from the first year to establish the desired form. Water twice a week during the dry season. Propagation from tip cuttings is very easy. Place cuttings in moist sand during the rainy season.

WHERE: Excellent as a formal hedge, topiary specimen, or container plant for shaded building entrances. On campus, well suited for the shaded courtyards, covered walkways, and any spot that receives bright indirect light rather than harsh direct afternoon sun. Can be grown as a bonsai in large decorative pots for reception areas and offices. Avoid exposed full-sun positions in the afternoon; the fine foliage scorches in intense direct sun. Ideal for the library garden, staff accommodation gardens, or any sheltered ornamental feature bed.'
WHERE scientific_name = 'Polyscias fruticosa';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. This conifer is not dependent on rainfall for establishment, but the wet season (May–September) reduces initial watering work. Avoid moving large specimens as they do not transplant well once established.

HOW: Plant in well-drained, slightly acidic soil. Keep the natural pyramidal shape. Do not prune the central leader (the main upward stem), as this destroys the natural symmetry permanently. Space trees at least 4–5 metres apart as they grow slowly but eventually reach 15–25 metres. Water once a week for the first year, then leave to rainfall. Fertilise lightly once a year with a general fertiliser. Do not over-fertilise, as this causes rapid but weak growth.

WHERE: Best used as a formal specimen or as a symmetrical pair flanking building entrances; the perfectly pyramidal shape gives an architectural quality to any formal entrance. On campus, ideal flanking the main gate, the administration block entrance, the vice-chancellor''s office, or the chapel. Also suitable as a Christmas tree substitute for the December season. Do not plant under power lines. Best as a standalone feature tree where its symmetry can be appreciated from a distance, not buried in a crowded planting bed.'
WHERE scientific_name = 'Araucaria heterophylla';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Oleander establishes quickly in warm conditions and will root readily from cuttings placed in moist soil during the wet months.

HOW: Plant in well-drained soil in a sunny position. Space 1–1.5 metres apart for hedge use. CRITICAL SAFETY NOTE. Wear gloves and wash hands thoroughly after handling any part of this plant. Do not burn prunings as the smoke is toxic. Pruning should be done once a year after flowering to maintain shape. Water once a week during the dry season; once established it is highly drought-tolerant.

WHERE: CAUTION. Plant only in locations where students and children cannot easily access, touch, or consume any part of the plant. All parts are highly toxic. Best used as a perimeter security hedge along boundary fences away from main student areas, or as a specimen plant in a clearly labelled fenced ornamental garden. Not recommended for planting along main student walkways, near canteens, sports areas, or any space used by large numbers of students. Road median planting along the campus perimeter road is an appropriate use where pedestrian access is limited.'
WHERE scientific_name = 'Nerium oleander';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–September). This conifer establishes well during warm wet months. Cuttings and nursery stock of 20–40 cm establish more reliably than large transplants.

HOW: Plant in well-drained soil. Oriental Arborvitae is one of the few ornamental conifers that tolerates poor, dry soil once established. Space 1–1.5 metres apart for hedge planting, or 3 metres for specimen trees. Shape with light trimming twice a year; it responds very well to formal clipping. Water once a week for the first dry season, then reduce to once every two weeks once established.

WHERE: Excellent for formal hedge lines, topiary columns, and structured garden features. On campus, suitable for formal entrance gardens, the boundary of the administration zone, or as vertical accent plants in any structured landscape design. The dense evergreen foliage provides year-round screening and wind reduction. Ideal for the sides of car parks, building corners where architectural screening is needed, or as a formal backdrop to any signage or notice board area. Tolerates partial shade but develops the densest, most attractive form in full sun.'
WHERE scientific_name = 'Platycladus orientalis';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. Oyster Plant is one of the most forgiving groundcover plants for transplanting. Cuttings root within 10–14 days when placed in moist soil during the wet season.

HOW: Plant rooted divisions or cuttings 20–30 cm apart for groundcover. The plant spreads by itself once established, filling gaps naturally. Requires almost no soil preparation. Push cuttings directly into moist garden soil and they will root. Water once a week for the first two weeks, then reduce to rainfall only. No fertiliser needed. Trim back occasionally to keep within the intended area.

WHERE: One of the most useful groundcover plants for UENR campus because it grows in deep shade where grass and most other groundcovers fail. Ideal under large canopy trees such as the Chinese Banyan, Mango, or Teak where nothing else grows. Also suitable as edging along shaded building foundations, in covered walkways, and as a carpet in any shaded courtyard garden. The vivid purple underside of leaves creates a striking two-tone effect. Grows equally well in full shade, dappled light, or full sun; almost no location on campus is unsuitable.'
WHERE scientific_name = 'Tradescantia spathacea';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. This cactus is completely indifferent to season. Even dry harmattan conditions are suitable. The plant will establish from a bare cutting pushed into sandy soil.

HOW: Plant cuttings that have been allowed to dry for 3–5 days after cutting (this prevents rot at the cut end). Push 10–15 cm into sandy, well-drained soil. No watering needed for the first two weeks; the cutting has stored water. After that, water once a month. Do not plant in clay or waterlogged soil; it will rot within weeks. Wear thick gloves during planting as the spines penetrate thin gloves.

WHERE: Best used as a dramatic specimen or accent plant in dry, sunny, difficult-to-maintain areas of campus (rocky slopes, the margins of paved areas, or any spot where regular maintenance is not practical). On campus, suitable for the exposed rocky areas near the engineering or environmental science buildings. Also works as a single statement plant in a gravel or stone garden feature. CAUTION. Do not plant near footpaths or areas used by students due to sharp spines. Minimum 2 metres clearance from any pedestrian route.'
WHERE scientific_name = 'Cereus repandus';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August) for quickest spread. Purple Heart roots from cuttings within one to two weeks when planted in moist soil. Harmattan planting is possible but requires watering twice a week for the first month.

HOW: Plant stem cuttings 5–8 cm long directly in garden soil. No rooting hormone needed. Space 20–25 cm apart for full groundcover. The plants spread by themselves and fill in gaps within one to two growing seasons. No fertiliser needed. Trim back to the intended boundary twice a year. The deeper purple colour develops in full sun; shaded specimens fade to greenish-purple.

WHERE: Best for border edging along sunny campus paths, as a groundcover on gentle slopes, or as a low-maintenance fill plant in garden beds between larger specimen plants. The vivid purple colour contrasts dramatically with green lawn grass and makes an excellent border definition line. On campus, suitable along the edges of the sports field, the border of the main car park, or any sunny garden bed edge. Avoid planting in areas of heavy foot traffic as the fleshy stems break easily when walked on.'
WHERE scientific_name = 'Tradescantia pallida';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the beginning of the rainy season (April–May). Silktree establishes quickly from young nursery stock; plant trees of 30–60 cm height for best results. Older specimens transplant poorly.

HOW: Dig a hole 60 cm wide and 50 cm deep. Mix removed soil with compost 3:1. Silktree is a nitrogen fixer; it improves the soil around it as it grows, so no fertiliser is required. Water deeply once a week for the first dry season. The feathery canopy develops best when the central leader is allowed to grow upward without pruning for the first three years. Prune lower branches to raise the canopy to 2 metres height for pedestrian clearance.

WHERE: Well suited as an ornamental shade tree in open garden areas, along campus roads where a spreading canopy is welcome, or as a specimen tree in the centre of a roundabout or garden feature. The bright pink powder-puff flowers (May–July) make it one of the most spectacular flowering trees available for UENR campus. Plant at least 5 metres from any building to allow for the spreading canopy. Best positioned where the flowers can be seen from a distance (open lawns, the front of the administration block, or near the main campus entrance).'
WHERE scientific_name = 'Albizia julibrissin';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Snowbush roots readily from cuttings in moist soil. Young nursery stock transplants successfully at any time of year if watered regularly for the first month.

HOW: Plant in well-drained, fertile soil. Space 40–50 cm apart for hedge planting. Snowbush responds very well to regular trimming. Cut back by one third twice a year to encourage dense bushy growth and maintain the vivid leaf variegation. Keep consistently moist; this is one of the few ornamentals in this list that does not tolerate prolonged dry periods. Water twice a week during the dry season.

WHERE: Best as a low formal hedge, border edge, or decorative fill plant in shaded to semi-shaded garden beds. On campus, suitable for the shaded sides of buildings, the interior of courtyards, or as a colourful low hedge separating garden zones. The white and green mottled leaves create a bright effect in shaded spots where more colourful plants do not thrive. Avoid exposed full-sun positions in the afternoon as the leaves scorch. Do not plant in waterlogged areas. Well suited for the library garden, staff quarters gardens, or any sheltered decorative bed.'
WHERE scientific_name = 'Breynia disticha';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the beginning of the rainy season (April–May). Ti Plant divisions and rooted cuttings establish quickly in warm, moist conditions. Can also be planted during the wet season from October to November in areas with two rainy seasons.

HOW: Plant in fertile, well-drained soil with good organic matter content. Space 60–80 cm apart for border planting, or 1–1.2 metres for specimen planting. Keep consistently moist but not waterlogged. The richest leaf colours (deep red, burgundy, variegated) develop in bright light; deep shade produces green foliage with faded colour. Fertilise monthly during the growing season for the most vivid leaf display.

WHERE: One of the most versatile ornamentals for UENR campus (suitable for shaded garden beds, bright courtyard planters, building entrances, and decorative features). The range of cultivars (green, red, multicolour) allows for creative colour combinations in mixed borders. On campus, excellent for the entrances of major buildings, the student centre garden, the staff lounge area, or as a colourful backdrop in any decorative bed. The palm-like form creates a tropical effect in any setting. Suitable for large decorative pots at building entrances.'
WHERE scientific_name = 'Cordyline fruticosa';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Indian Shot grows from rhizome divisions that establish quickly when the soil is warm and moist. Planting during the dry season is possible but requires watering every two to three days for the first month.

HOW: Plant rhizome sections 5–8 cm deep with the growing tip pointing upward. Space 40–60 cm apart. Indian Shot prefers moist, fertile soil with good compost content. Amend the bed before planting. Water every two to three days during dry periods. After the first year, the rhizomes multiply and spread to fill the bed. Cut back dead flower stems after flowering but leave the foliage to allow the rhizome to store energy for the next season.

WHERE: Best in moist, sunny to semi-shaded garden beds with reliable water access. On campus, well suited for the areas near water features, along the edges of drainage channels (but not in standing water), or in the regularly irrigated gardens near the administration block and main entrance. The large green or bronze leaves and bright orange-red flowers create a bold tropical effect. Plant in groups of 5–7 for the strongest visual impact. Suitable for the edges of the campus stream or pond if one exists, or any low-lying area that retains some moisture.'
WHERE scientific_name = 'Canna indica';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Copperleaf roots from cuttings within two to three weeks when planted in moist soil. Is one of the easiest ornamentals to propagate and establish on campus at low cost.

HOW: Plant cuttings 15–20 cm long directly in garden soil during the wet season. Space 40–60 cm apart for hedge planting. Copperleaf responds very well to regular trimming. Clip every 6–8 weeks to maintain dense, compact hedge form and to encourage the brightest coppery new growth. The richest leaf colours appear on the newest growth, so regular trimming directly improves ornamental quality. Water twice a week during the dry season.

WHERE: One of the most widely used ornamental hedge plants on Ghanaian campuses and ideal for UENR. Suitable for boundary hedges between garden zones, decorative hedging along campus paths, and as a colourful fill plant in mixed borders. On campus, excellent along the edges of the administration garden, the sports field boundary, the student hostel entrances, or any location requiring a colourful but low-maintenance hedge. Full sun produces the richest copper and red tones; partial shade produces greener, less vivid foliage.'
WHERE scientific_name = 'Acalypha wilkesiana';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–September). Golden Dewdrop establishes quickly from cuttings or nursery stock in warm wet conditions. Avoid transplanting large specimens during the dry season.

HOW: Plant in well-drained soil in a sunny to semi-shaded position. Space 1–1.5 metres apart for informal hedge or screen planting. Prune once a year after fruiting to maintain shape and encourage the next flush of flowers. The plant responds well to hard pruning if it becomes too large. Water twice a week during the dry season for the first year; once established it is moderately drought tolerant.

WHERE: CAUTION. Do not plant in areas accessible to young children. The yellow-orange berries are toxic to humans and pets. Best used as an ornamental specimen or informal screen in adult-managed garden areas, along boundary fences, or in garden zones away from the canteen and student recreation areas. On campus, suitable for the perimeter garden borders, the staff quarters garden, or as a specimen plant in any fenced ornamental feature garden. The combination of blue-purple flowers and golden berries appearing simultaneously makes it one of the most visually striking ornamental shrubs available for campus planting.'
WHERE scientific_name = 'Duranta erecta';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Croton is easily propagated from cuttings and establishes readily in warm, humid conditions. Potted nursery stock can be planted at any time with regular watering.

HOW: Plant in well-drained, fertile soil. Space 50–70 cm apart for hedge use or 80 cm–1 metre for specimen planting. The richest and most vivid leaf colours develop in full sun; shade-grown Croton produces greener, less colourful foliage. Water twice a week during the dry season. Prune lightly twice a year to maintain compact form and to encourage new growth with the freshest colours. The milky sap that appears when stems are cut is a skin irritant; wear gloves when pruning.

WHERE: One of the most widely used ornamental plants in Ghana and ideal for colourful campus landscaping. Suitable as a hedge, border plant, container plant, or colourful specimen in mixed beds. On campus, excellent along entrance paths, as a decorative hedge at building frontages, in the administration garden, or in large decorative pots at main building entrances. The extraordinary range of leaf colours (red, yellow, orange, green, variegated) allows for creative colour-themed planting schemes. Best positioned where the colours can be seen in direct sunlight for maximum visual effect.'
WHERE scientific_name = 'Codiaeum variegatum';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August) for quickest establishment. Jungle Flame is sensitive to cold and establishes best during warm wet months. Potted specimens can be transplanted at any time of year with regular watering.

HOW: Plant in well-drained, slightly acidic soil. This is one of the few campus ornamentals that performs poorly in alkaline or neutral soil. If the campus soil is alkaline, amend the bed with peat or composted pine bark before planting. Space 60–80 cm apart for hedge use. Water twice a week during the dry season. Feed monthly with a fertiliser formulated for acid-loving plants (sulphate of iron or ericaceous fertiliser) for continuous flowering.

WHERE: Best in partial shade to full sun positions with reliable moisture access. The continuous bright red flowers make it one of the most attractive year-round flowering shrubs available. On campus, excellent for the shaded sides of major buildings, the library garden, covered walkway edges, or as a low border beneath larger canopy trees. The flowers attract sunbirds which adds further ornamental value. Not suitable for very dry, exposed positions; the plant performs best where some shade protection is available in the afternoon. Ideal for any space where year-round colour is the design priority.'
WHERE scientific_name = 'Ixora coccinea';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Red Eugenia flushes vivid red new growth most dramatically in warm humid conditions. Nursery stock transplants successfully at any time of year with irrigation.

HOW: Plant in fertile, well-drained soil. Space 40–60 cm apart for formal hedge planting. Red Eugenia is one of the best formal hedge plants available; it responds beautifully to regular clipping and maintains its compact form through trimming. Clip every 6–8 weeks during the growing season to maintain the desired shape and to encourage new red growth (the new growth is where the vivid colour appears). Water twice a week during the dry season.

WHERE: Ideal as a formal ornamental hedge, topiary specimen, or structured border plant for any part of the UENR campus. The vivid red new growth creates a striking visual contrast with the surrounding greenery and makes it one of the most eye-catching hedge plants available in tropical Africa. On campus, excellent for the administration block front garden, the main entrance hedge, formal garden borders, or as a backdrop to any signage. Works equally well as a trimmed formal hedge or as a loosely pruned informal shrub. Full sun produces the most vivid red new growth colour.'
WHERE scientific_name = 'Syzygium myrtifolium';

UPDATE plant_species SET planting_advice =
'WHEN: Plant cuttings during the rainy season (May–August) for fastest establishment. Creeping Daisy is extremely easy to propagate; any stem section that touches moist soil will root spontaneously.

HOW: Plant rooted cuttings or stem divisions 20–30 cm apart. The plant will fill the gaps within one growing season. Almost no soil preparation is required. Water twice a week for the first two weeks, then leave to rainfall; it is extremely drought-tolerant once established. To prevent unwanted spread, install a root barrier (plastic edging or concrete border) around the planted area before planting. Trim back to the intended boundary every three months.

WHERE: IMPORTANT. This species is classified as one of the world''s 100 worst invasive plants and spreads aggressively if unmanaged. Only plant where a physical barrier prevents spread into natural areas or adjacent gardens. Best used on contained slopes, within concrete-edged beds, or on isolated rocky areas where spread is physically limited. On campus, suitable for the steep embankments along the main road where erosion control is needed and the physical gradient limits horizontal spread. Do not plant near the bat sanctuary, natural forest margins, or any area with native vegetation. The planting area must be inspected and trimmed quarterly.'
WHERE scientific_name = 'Sphagneticola trilobata';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at any time of year. False Agave is indifferent to season. Wet season planting is easiest but dry season establishment is also successful with minimal supplemental watering.

HOW: Plant the central rosette at ground level. Do not bury the base. Well-drained soil is essential. Space individual rosettes at least 2 metres apart to allow for the large, spreading leaf rosette that develops at maturity. Water once every two to three weeks for the first month, then leave completely to natural rainfall. After the plant flowers and dies (after several years), collect the many bulbils that form on the flower spike and replant as new specimens.

WHERE: Suitable for large-scale dry landscape features, open rocky areas, slope stabilisation, and any location where a dramatic architectural plant form is desired without ongoing maintenance. On campus, ideal for the exposed, dry margins of the campus (open ground near boundary fences, rocky slopes, and any area where irrigation is not practical). The large architectural rosette form makes it suitable as a specimen plant in large open spaces. Avoid planting near footpaths due to the size of the mature plant. Best appreciated as a solo specimen or in a widely spaced group on open ground.'
WHERE scientific_name = 'Furcraea foetida';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Chinese Hibiscus establishes quickly from cuttings in warm wet conditions. Is one of the easiest ornamental shrubs to propagate on campus.

HOW: Plant in fertile, well-drained soil. Space 60–80 cm apart for hedge planting. Chinese Hibiscus responds well to regular pruning. Trim after each major flowering flush to encourage the next wave of blooms. Water twice a week during the dry season. Feed monthly with a potassium-rich fertiliser to encourage continuous flowering. Over 5,000 cultivars exist; select flower colour based on the desired colour scheme for the planting area.

WHERE: One of the most widely planted ornamental hedge and specimen shrubs across Ghanaian campuses. Suitable for hedge lines, building frontage planting, decorative borders, and specimen planting in mixed beds. On campus, excellent along entrance paths, as colourful hedging at the student hostel boundaries, along the sports field edges, or as a mixed-colour border in the administration garden. The large trumpet flowers attract sunbirds and butterflies, adding ecological value alongside the ornamental value. Best in full sun; partial shade reduces flowering significantly.'
WHERE scientific_name = 'Hibiscus rosa-sinensis';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August). Weeping Fig establishes best from young nursery stock during warm wet months. Avoid transplanting mature trees as they are sensitive to root disturbance.

HOW: Plant in well-drained, fertile soil with good organic matter. Allow at least 5–6 metres clearance from any building or underground pipe; the root system is extensive and invasive. Water deeply once a week for the first year. The weeping form develops naturally without pruning. If grown as an indoor specimen or in a large pot, root pruning every two to three years prevents pot-binding. Regularly sweep fallen leaves as the tree drops leaves seasonally.

WHERE: Best as a large shade tree or formal specimen in open areas of campus. On campus, suitable for open lawns, large courtyard gardens, or as a shade tree in the centre of a car park island. The large pendulous canopy provides dense shade across a wide area. Do not plant near water pipes, sewers, building foundations, or paved areas as the roots are invasive and can cause damage. Not suitable for small garden beds or areas near infrastructure. Best positioned in a large open area where the graceful weeping form can be appreciated from a distance.'
WHERE scientific_name = 'Ficus benjamina';

UPDATE plant_species SET planting_advice =
'WHEN: Plant during the rainy season (May–August) for fastest establishment. Manila Palm does not transplant well once large; always plant young nursery specimens of 30–50 cm height.

HOW: Dig a hole 40 cm wide and 40 cm deep. Manila Palm is less demanding about soil quality than many palms; it tolerates a range of well-drained soils. Plant with the root collar at soil level. Water once a week for the first dry season. Fertilise twice a year with a palm-specific fertiliser for best development. Remove dead fronds by cutting cleanly at the base. Do not pull, as this damages the trunk.

WHERE: One of the most popular ornamental palms for formal institutional landscaping in Ghana. The compact single trunk and neat crown make it ideal for formal entrance planting, avenue lines, and building frontage decoration. On campus, ideal flanking the main entrance gate (planted in pairs), as a row along the administration block frontage, or as formal specimens along the main campus access road. The bright red fruit clusters in season add significant ornamental value. Suitable for large decorative planters in paved areas. Full sun produces the best development. Avoid planting under large canopy trees.'
WHERE scientific_name = 'Adonidia merrillii';

UPDATE plant_species SET planting_advice =
'WHEN: Plant at the beginning of the rainy season (April–May). Alternanthera establishes from cuttings within one to two weeks in moist soil. Can be planted at any time of year if given regular watering.

HOW: Plant stem cuttings 8–10 cm long directly in garden soil. Space 20–25 cm apart for dense colour carpet effect. Alternanthera requires regular clipping every 4–6 weeks to maintain compact, low form; without clipping it becomes leggy and loses the carpet effect. Water twice a week during the dry season. Full sun is essential for the deepest red-burgundy colour; shaded plants produce greenish, faded foliage with poor ornamental value.

WHERE: Best used for formal colour patterning, carpet bedding, border edging, and defined geometric garden designs. On campus, suitable for the formal entrance garden, any patterned bedding display, the administration block front border, or as a colour contrast edge alongside green-leafed groundcovers. The deep burgundy-red leaf colour creates a vivid contrast against green lawns and makes it one of the most effective border definition plants available. Requires more maintenance than most groundcovers due to regular clipping needs; only plant where maintenance visits are possible every 4–6 weeks. Full sun positions only.'
WHERE scientific_name = 'Alternanthera dentata';
