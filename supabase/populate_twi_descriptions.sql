-- Generated from UENR_Flora_Final_Twi_Descriptions.csv. Run this complete statement in Supabase SQL Editor.
-- It updates only plant_species.description_twi using exact scientific_name matches.
WITH twi_import(scientific_name, description_twi) AS (
  VALUES
    ('Acalypha wilkesiana', 'Ne nhaban a ɛyɛ den no ma nkoekoemmoa nketewa ne nnomaa nya ahobammɔ; nhaban akɛse a ɛhwe ase no boa ma asase no nya organic matter pii.'),
    ('Adonidia merrillii', 'Sɛ n''aduaba no yɛɛ a, ɛyɛ kɔkɔɔ, na nnomaa di, na ɛboa ma aba no trɛw; dua no atifi ma nnomaa nketewa nya baabi yɛ wɔn bere.'),
    ('Agave attenuata', 'Bere a ɛyɛ nhwiren no, ɛma anantwi anadwo, nnomaa nketewa a wɔnom nhwiren mu nsu, ne nkoekoemmoa nya nhwiren mu nsu pii.'),
    ('Albizia julibrissin', 'Ne ntini so nkwammoaa a ɛboa ma nitrogen kɔ asase mu no ma asase nya ahoɔden; ne nhwiren a nhwiren mu nsu wom pii twetwe nwoawa ne aboɔpɔnkɔ; nnomaa di aba nsina no.'),
    ('Albizia lebbeck', 'Ne ntini so nkwammoaa a ɛboa ma nitrogen kɔ asase mu no ma asase nya ahoɔden; ne nhwiren a ɛyɛ huam twetwe nwoawa ne aboɔpɔnkɔ; nnomaa di aba nsina no.'),
    ('Alchornea cordifolia', 'Ɛyɛ afifide a ɛyɛ West Africa de; ne nhwiren twetwe mmoa a wɔboa ma afifide nya aba; nnomaa di n''aduaba; ɛma kwae mu nkoekoemmoa ne mmoa nketewa nya tenabea wɔ kwae a ɛsan nyin mu.'),
    ('Aloe vera', 'Ne nhwiren ma nnomaa ne nwoawa nya nhwiren mu nsu; afifide a anya ne ho wɔ mpɔtam hɔ no boa mpɔtam hɔ nkoekoemmoa.'),
    ('Alternanthera dentata', 'Ne nhaban a ɛyɛ den no ma nkoekoemmoa nya tenabea wɔ asase ho; ne nhwiren twetwe nwoawa nketewa ne nwansena.'),
    ('Anacardium occidentale', 'Ne nhwiren ma nwoawa ne aboɔpɔnkɔ nya nhwiren mu nsu pii; ne cashew apple ma nnomaa, anantwi anadwo ne mmoa di.'),
    ('Araucaria heterophylla', 'Ne mman a wɔahyehyɛ no afam-afam no ma nnomaa nya baabi yɛ wɔn bere; nnomaa bi nso di ne aba.'),
    ('Azadirachta indica', 'Ne dua atifi a ɛyɛ den no bɔ nnomaa ne nkoekoemmoa ho ban; ne nhwiren ma nwoawa nya nhwiren mu nsu; nhaban a ɛhwe ase no ma asase nya nneɛma a nitrogen wom.'),
    ('Bambusa vulgaris', 'Bamboo akuw a ɛyɛ den no ma nnomaa nya baabi yɛ wɔn bere na wɔhome; bamboo kwae nketewa no boa mmoa nketewa ne nkoekoemmoa; ɛboa bɔ nsu kwan ho ban wɔ asubɔnten ho.'),
    ('Blighia sapida', 'Ne nhwiren ma nwoawa nya nhwiren mu nsu pii; sɛ n''aduaba bue ankasa a, nnomaa ne anantwi anadwo di; ɛyɛ aduan dua a ɛho hia wɔ Guinea kwae mpɔtam.'),
    ('Breynia disticha', 'Ne nhaban a ɛyɛ den no bɔ nkoekoemmoa ho ban; nhwiren nketewa no twetwe nwoawa nketewa; ne nyin a ɛyɛ tiawa no boa nkoekoemmoa a wɔwɔ asase ho.'),
    ('Broussonetia papyrifera', 'N''aduaba kɔkɔɔ a ɛyɛ nam no yɛ aduan titiriw ma anantwi anadwo ne nnomaa; wɔahu wɔ UENR campus sɛ ɛboa anantwi anadwo ma wɔtrɛw aba; ɛyɛ afifide a edi kan nya baabi wɔ asase a asɛe so.'),
    ('Caladium spp.', 'Ɛboa wuram mmoa kakraa bi; wɔdua no titiriw sɛ afɛfɛde, na wɔpɛ no esiane ne nhaban kɔla nti.'),
    ('Calotropis procera', 'Ne nhwiren twetwe monarch aboɔpɔnkɔ ne mmoa a wɔboa ma afifide nya aba; ɛyɛ afifide a aboɔpɔnkɔ ahorow pii wɔ Ghana de wɔn mma nyin so.'),
    ('Cananga odorata', 'N''aduaba tuntum akuw yɛ aduan a ɛho hia ma nnomaa; ne nhwiren twetwe anadwo ntontom ne mmoa afoforo a wɔboa ma afifide nya aba.'),
    ('Canna indica', 'Ne nhwiren akɛse a ɛyɛ fɛ twetwe nnomaa nketewa a wɔnom nhwiren mu nsu ne aboɔpɔnkɔ; ne nhaban a ɛkata asase so no ma nkoekoemmoa ne mmoa nketewa nya tenabea.'),
    ('Carica papaya', 'Ɛnyin ntɛm na ɛyɛ afifide a edi kan kata asase so; ne nhwiren twetwe nwoawa ne ntontom akɛse; n''aduaba ma nnomaa ne anantwi anadwo di.'),
    ('Casuarina equisetifolia', 'Ne nkabom ne Frankia bacteria a ɛwɔ asase mu no ma asase a ɛyɛ mmɔbɔ nya ahoɔden; ɛdi kan nyin wɔ asase kwa, anhwea ne asase a asɛe so; ɛma nnomaa a wodi aba nya tenabea.'),
    ('Cedrela odorata', 'Ɛyɛ dua a ɛnyin ntɛm na ne dua atifi ma nnomaa ne afifide a ɛnyin nnua so nya mmoa; ɛma wuram mmoa nya tenabea a ɛho hia.'),
    ('Cereus repandus', 'Ne nhwiren a ɛbue anadwo twetwe ntontom ne anantwi anadwo ma wɔboa ma ɛnya aba; n''aduaba kɔkɔɔ a ɛyɛ nam no nnomaa, anantwi anadwo ne mmoa di.'),
    ('Citrus sinensis', 'Ne nhwiren twetwe nwoawa ne aboɔpɔnkɔ a wɔboa ma afifide nya aba; nnomaa di n''aduaba na ɛboa ma aba no trɛw.'),
    ('Cocos nucifera', 'Akutu tumi sensɛn nsuo so na ɛkɔ so nya nkwa wɔ po nsuo mu abosome pii, enti ɛtumi trɛw ankasa wɔ mpoano; ne nhwiren twetwe nwoawa ne nkoekoemmoa nketewa; akutu no ma akɔre ne mmoa akɛse nya aduan.'),
    ('Codiaeum variegatum', 'Ne nhaban a ɛyɛ den no bɔ nkoekoemmoa nketewa ho ban; nhaban kɔla hyerɛn no twetwe nnomaa ba campus turo mu; ne nhwiren twetwe nkoekoemmoa nketewa.'),
    ('Cordyline fruticosa', 'Ne nhwiren twetwe nwoawa ne nkoekoemmoa nketewa; nnomaa di n''aduaba; nhaban no ase a ɛyɛ den bɔ akɔre nketewa ne nkoekoemmoa ho ban.'),
    ('Delonix regia', 'Ne nhwiren ma nnomaa ne aboɔpɔnkɔ nya nhwiren mu nsu pii; ne nhwiren no sɛnea wɔahyehyɛ no twetwe mmoa akɛse a wɔboa ma afifide nya aba; ne dua atifi te sɛ kyɛw ma nnomaa nya tenabea.'),
    ('Dracaena trifasciata', 'Ɛyɛ West Africa afifide kakraa bi mu baako wɔ saa din yi mu; ne nhwiren ma ntontom nya nhwiren mu nsu anadwo; ɛwɔ West Africa kwae mpɔtam a ɛtrɛw mu.'),
    ('Duranta erecta', 'Ne nhwiren twetwe aboɔpɔnkɔ ne nnomaa nketewa a wɔnom nhwiren mu nsu; n''aduaba a ɛyɛ kɔkɔɔ ne borɔdɔma ma nnomaa ne mmoa nketewa di.'),
    ('Dypsis lutescens', 'Ne nyin a ɛka bom no ma nnomaa nya baabi yɛ wɔn bere; n''aduaba nketewa nnomaa ne mmoa nketewa di.'),
    ('Elaeis guineensis', 'N''aduaba akuw nnomaa, anantwi anadwo ne mmoa a wɔte sɛ mpaninfoɔ di; ne nhaban atifi a ɛyɛ den ma kwae mu mmoa ahorow pii nya tenabea; efi tete no ɛyɛ afifide titiriw wɔ West Africa kwae ne savanna afrafra mu.'),
    ('Enterolobium cyclocarpum', 'Ne dua atifi kɛse no ma wuram mmoa nya tenabea pii; ɛboa ma nitrogen kɔ asase mu; n''aba nsina akɛse a ɛte sɛ aso no nnomaa ne mmoa di.'),
    ('Eucalyptus sp.', 'Nhwiren no ma nhwiren mu nsu pii na ɛtwetwe nwoawa ne nnomaa wɔ ahorow bi mu; nneɛma bi a ɛwɔ nhaban mu si afifide a ɛyɛ kurom a ɛwɔ dua no ase kwan.'),
    ('Euphorbia milii', 'Ne nhwiren te sɛ nhwiren a ɛkɔ so afe mu nyinaa no twetwe aboɔpɔnkɔ ne nkoekoemmoa nketewa ma wɔnya nhwiren mu nsu; ɛma afɛfɛde kɔla kɔ so afe mu nyinaa.'),
    ('Ficus benjamina', 'Ne borɔdɔma te sɛ n''aduaba ma nnomaa, anantwi anadwo ne mmoa a wodi n''aduaba nya aduan; ne dua atifi a ɛyɛ den ma wuram mmoa nya tenabea afe mu nyinaa; nkabom a ɛda fig ne wasp ntam no boa ma ɛnya aba.'),
    ('Ficus exasperata', 'Ɛyɛ fig afifide titiriw; ne aduaba yɛ aduan a ɛho hia ma nnomaa, anantwi anadwo ne mmoa a wɔte sɛ mpaninfoɔ; UENR campus nhwehwɛmu kyerɛ sɛ ɛyɛ 6.6% wɔ aba a anantwi anadwo trɛw mu (Agyei-Ohemeng et al. 2016); ɛdi kan boa kwae a ɛsan nyin.'),
    ('Ficus microcarpa', 'Ne aduaba yɛ aduan titiriw ma nnomaa, anantwi anadwo ne mmoa a wodi n''aduaba; ntini a ɛsian fi mman mu no yɛ tenabea nketewa ahorow; nkabom a ɛda fig ne wasp ntam no yɛ akwan a afifide de boa ma ɛnya aba a anya nkɔso kɛse wɔ afifide ahenni mu.'),
    ('Furcraea foetida', 'Ne nhwiren dua ma anantwi anadwo ne nkoekoemmoa akɛse nya nhwiren mu nsu; sɛ ɛyɛ nhwiren wie a, ɛyɛ bulbils, anaa afifide nketewa, pii a ɛboa ma ɛtrɛw.'),
    ('Gliricidia sepium', 'Ne ntini so nkwammoaa a ɛboa ma nitrogen kɔ asase mu no ma asase nya ahoɔden; wɔ ɔpɛ bere a afifide kakraa bi yɛ nhwiren no, ne nhwiren twetwe nwoawa ne aboɔpɔnkɔ; mman a wɔatwa no kata asase so na ɛboa ma asase yɛ fɛ.'),
    ('Gmelina arborea', 'Ɛyɛ dua a ɛnyin ntɛm na ɛboa nnomaa ne nkoekoemmoa; ne nhwiren twetwe nwoawa ansa na nhaban afi; nhaban a ɛhwe ase no ma asase nya ahoɔden ntɛm.'),
    ('Griffonia simplicifolia', 'Wɔakyerɛw ne ho wɔ UENR bat sanctuary sɛ ɛyɛ nnua no 9.3% (sɛnea Owusu-Prempeh et al. 2018 kyerɛ); aba nsina no ma nnomaa ne anantwi anadwo nya aduan; ne nyin a ɛforo nnua no boa kwae a ɛsan nyin no nhyehyɛe.'),
    ('Hibiscus rosa-sinensis', 'Ne nhwiren akɛse a ɛte sɛ torobɛntɔ twetwe nnomaa, aboɔpɔnkɔ ne nwoawa; ɛyɛ afɛfɛde afifide a ɛma nkoekoemmoa a wɔboa ma afifide nya aba wɔ campus nya nhwiren mu nsu no mu baako a ɛho hia paa.'),
    ('Ixora coccinea', 'Ne nhwiren a ɛte sɛ kotoku no yɛ nhwiren mu nsu fibea titiriw ma nnomaa, aboɔpɔnkɔ ne nwoawa; ne nhaban a ɛyɛ den bɔ nnomaa nketewa ne nkoekoemmoa ho ban.'),
    ('Jatropha curcas', 'Ne nhwiren twetwe nwoawa ne aboɔpɔnkɔ; ɛyɛ afifide a ɛnyin ntɛm na ɛdi kan kɔ asase a asɛe so.'),
    ('Lagerstroemia speciosa', 'Bere a osu bere no du ne mpɔtam no, ne nhwiren ma nwoawa ne aboɔpɔnkɔ nya nhwiren mu nsu pii; nhaban no hwe ase wɔ mmere bi mu na ɛboa ma asase nya ahoɔden.'),
    ('Leucaena leucocephala', 'Ne ntini so nkwammoaa a ɛboa ma nitrogen kɔ asase mu no ma asase nya ahoɔden; ɛnyin ntɛm na ɛdi kan kɔ asase a asɛe so; wɔabɔ amanneɛ sɛ sɛ tebea yɛ papa a ɛkyekye nitrogen kodu 500 kg N/ha afe biara.'),
    ('Mangifera indica', 'N''aduaba ma nnomaa ne anantwi anadwo di; ne dua atifi bɔ campus wuram mmoa ho ban.'),
    ('Manihot esculenta', 'Ɛnyin ntɛm na ɛboa ma asase kwa gyina pintinn; ne ntini mpɔtam boa asase mu mmoa nketewa ahorow; ɛyɛ aduan nnɔbae a etumi gyina ɔpɛ ano paa wɔ wiase.'),
    ('Mimosa pudica', 'Ne nhwiren twetwe nwoawa nketewa; ɛtrɛw fam na ɛdi kan kɔ asase a asɛe so; ne ntini so nkwammoaa boa ma nitrogen kɔ asase mu.'),
    ('Monoon longifolium', 'Ne tenten a ɛte sɛ dua a ne mu yɛ teateaa no ma campus afifide ne mmoa mpɔtam nya nhyehyɛe a ɛforo soro; nnomaa ne nkoekoemmoa nketewa de ne dua atifi yɛ wɔn bere na wɔhome.'),
    ('Moringa oleifera', 'Ne nhwiren a nhwiren mu nsu wom pii twetwe nwoawa ne aboɔpɔnkɔ; ɛnyin ntɛm na ɛkata asase so ntɛm.'),
    ('Musa × paradisiaca', 'Nhaban ne dua ntam a ɛporɔw no yɛ tenabea nketewa ma nkoekoemmoa ne asase mu mmoa; nhwiren mu nsu twetwe nnomaa ne anantwi anadwo.'),
    ('Nerium oleander', 'Ɛwom sɛ afifide no yɛ awuduru de, ne nhwiren twetwe aboɔpɔnkɔ ne nwoawa; ne nhaban a ɛyɛ den na ɛyɛ ahabammono bere nyinaa kata ade so.'),
    ('Newbouldia laevis', 'Ɛyɛ afifide a ɛdɔɔso paa wɔ UENR bat sanctuary, na ɛyɛ nnua no 19.4% (sɛnea Owusu-Prempeh et al. 2018 kyerɛ); ne nhwiren twetwe nnomaa ne nwoawa; ɛnyin ntɛm na ɛdi kan wɔ kwae a ɛsan nyin mu.'),
    ('Persea americana', 'Ne nhwiren twetwe nwoawa ma wɔboa ma ɛnya aba; tete no, mmoa akɛse a wɔn ase atɔre na wɔtrɛw n''aduaba a ɛyɛ nam no; nnɛ nnipa na wɔtrɛw no.'),
    ('Platycladus orientalis', 'Ne nhaban a ɛyɛ den na ɛyɛ ahabammono bere nyinaa bɔ nnomaa nketewa ho ban afe mu nyinaa; nnomaa bi di ne aba.'),
    ('Plumeria pudica', 'Ne nhwiren a ɛyɛ huam twetwe ntontom ne aboɔpɔnkɔ ma wɔboa ma ɛnya aba; ɛyɛ nhwiren afe mu nyinaa na ɛma nhwiren mu nsu ba daa.'),
    ('Polyscias fruticosa', 'Nwoawa nketewa ne nwansena boa ma nhwiren a ɛnyɛ fɛ kɛse no nya aba; sɛ n''aduaba tuntum a ɛyɛ kɔkɔɔ-tuntum ba a, nnomaa di.'),
    ('Pongamia pinnata', 'Ne nhwiren ma nwoawa nya nhwiren mu nsu pii; ne dua atifi a ɛtrɛw ma nnomaa nya tenabea; ne ntini so nkwammoaa boa ma nitrogen kɔ asase mu.'),
    ('Ricinus communis', 'Ɛnyin ntɛm na ɛdi kan kɔ asase a asɛe so; sɛ aba nsina no wu na ɛyow a, ɛma aba no tu fi mu gu ntɛm; ɛkata asase kwa so ntɛm.'),
    ('Senna siamea', 'Ɔpɛ bere mu no, ne nhwiren ma nwoawa ne aboɔpɔnkɔ nya nhwiren mu nsu; wɔahu no wɔ UENR bat sanctuary (Owusu-Prempeh et al. 2018), na ɛboa ma campus wuram mmoa ahorow dɔɔso.'),
    ('Solanum torvum', 'Ne nhwiren twetwe nwoawa; nnomaa di n''aduaba na ɛboa ma aba trɛw; ɛdi kan kɔ asase a asɛe so.'),
    ('Spathodea campanulata', 'Ne nhwiren akɛse a ɛyɛ fɛ ma nnomaa, nnomaa akɛse ne aboɔpɔnkɔ nya nhwiren mu nsu pii; nsuo a ɛboaboa ano wɔ nhwiren aba a ɛte sɛ toa nketewa mu no tree frogs ne nkoekoemmoa de di dwuma. ANSƐE: nhwiren mu nsu no yɛ awuduru ma nwoawa ahorow bi.'),
    ('Sphagneticola trilobata', 'Ne nhwiren twetwe nwoawa nketewa ne aboɔpɔnkɔ; ɛyɛ ntama a ɛyɛ den kata asase so na ɛma afifide a ɛyɛ kurom ntumi nyin. IUCN akyerɛ sɛ ɛyɛ wiase afifide amannɔne a ɛtrɛw bɔne no 100 no mu baako.'),
    ('Syzygium jambos', 'Ne nhwiren a ɛyɛ cream na ɛte sɛ pom-pom twetwe nwoawa ne aboɔpɔnkɔ; nnomaa ne anantwi anadwo di n''aduaba na ɛboa ma aba trɛw.'),
    ('Syzygium myrtifolium', 'Ne nhwiren twetwe nwoawa ne aboɔpɔnkɔ; ne nhaban a ɛyɛ den bɔ nnomaa nketewa ho ban.'),
    ('Tectona grandis', 'Ɛma nnomaa ne nkoekoemmoa nya baabi yɛ wɔn bere; teak plantations wɔ Ghana Brong-Ahafo boa asase mu mmoa ahorow na ɛyɛ akwan a wuram mmoa fa so.'),
    ('Terminalia catappa', 'Nnomaa, anantwi anadwo ne mmoa di n''aduaba na ɛboa ma aba no trɛw; ne dua atifi a ɛyɛ afam-afam ma wuram mmoa nya tenabea ahorow.'),
    ('Terminalia mantaly', 'Ne mman a ɛyɛ afam-afam na ɛtrɛw kɔ nkyɛn no ma nnomaa nya baabi yɛ wɔn bere; nhaban atifi biara ase ma sunsuma a wɔahyehyɛ.'),
    ('Tetrapleura tetraptera', 'Ɛyɛ kurom dua a ne dua atifi boa nnomaa, anantwi anadwo ne nkoekoemmoa; ne nhwiren twetwe mmoa a wɔboa ma afifide nya aba; nnomaa ne anantwi anadwo di n''aduaba.'),
    ('Tradescantia pallida', 'Ɛnyin fam na ɛkata asase so, na ɛbɔ asase ani ho ban fi nsuo a ɛkɔfa dɔteɛ; ne nhwiren twetwe nwoawa nketewa.'),
    ('Tradescantia spathacea', 'Ɛyɛ ntama a ɛyɛ den kata asase so fam; ɛboa wuram mmoa kakraa bi pɛ; ne nyin a ɛyɛ tiawa si nwura kwan yiye.'),
    ('Vitex trifolia', 'Ne nhwiren twetwe nwoawa ne aboɔpɔnkɔ; etumi gyina nkyene ano na ɛboa mpoano afifide; nhaban no ma aboɔpɔnkɔ mma bi nya aduan.'),
    ('Voacanga africana', 'Ɛyɛ dua ketewa a ɛwɔ kwae a ɛsan nyin ano; ne nhwiren twetwe mmoa a wɔboa ma afifide nya aba; nnomaa ne anantwi anadwo di n''aduaba na ɛboa ma aba trɛw.'),
    ('Zea mays', 'Ne pollen ma nkoekoemmoa ahorow pii nya aduan; bere a ɛyɛ ɔpɛ no, dua a ayow no bɔ mmoa nketewa ne nkoekoemmoa ho ban.')
,
  matched AS (
    SELECT i.scientific_name, i.description_twi
    FROM twi_import AS i
    INNER JOIN plant_species AS p ON p.scientific_name = i.scientific_name
  ),
  updated AS (
    UPDATE plant_species AS p
    SET description_twi = m.description_twi
    FROM matched AS m
    WHERE p.scientific_name = m.scientific_name
      AND (SELECT COUNT(*) FROM twi_import) = 76
      AND (SELECT COUNT(*) FROM plant_species) = 76
      AND (SELECT COUNT(*) FROM matched) = 76
    RETURNING p.scientific_name
  )
SELECT COUNT(*) AS updated_rows FROM updated;
