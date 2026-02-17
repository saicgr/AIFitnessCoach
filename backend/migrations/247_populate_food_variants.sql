-- Migration 247: Populate variant_names for ~260 foods across 14 cuisines
-- Purpose: Enable fuzzy matching for common spelling variations
-- Created: 2026-02-16
-- Note: Updates only is_primary = TRUE rows, matched by LOWER(name)

-- ============================================================================
-- INDIAN (~55 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['idly', 'idlee'] WHERE LOWER(name) = 'idli' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['dosai', 'dose', 'plain dosa', 'dosa plain'] WHERE LOWER(name) = 'dosa' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['dosai', 'dose', 'plain dosa', 'dosa plain'] WHERE LOWER(name) = 'dosa, plain' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chapati', 'chapatti', 'chapathi', 'phulka'] WHERE LOWER(name) = 'roti' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['biriyani', 'biriani', 'briyani'] WHERE LOWER(name) = 'biryani' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['daal', 'dhal', 'dhall'] WHERE LOWER(name) = 'dal' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['sambhar', 'sambaar'] WHERE LOWER(name) = 'sambar' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['sambhar', 'sambaar'] WHERE LOWER(name) = 'sambhar' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['parantha', 'parotta', 'porotta'] WHERE LOWER(name) = 'paratha' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['poori', 'pori'] WHERE LOWER(name) = 'puri' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['vadai', 'vadey'] WHERE LOWER(name) = 'vada' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['uppuma'] WHERE LOWER(name) = 'upma' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pohe', 'aval', 'atukulu'] WHERE LOWER(name) = 'poha' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['khichri', 'kitchari', 'kitchree', 'kedgeree'] WHERE LOWER(name) = 'khichdi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['gulaab jamun', 'gulab jaman'] WHERE LOWER(name) = 'gulab jamun' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['jilapi', 'jilebi', 'jilipi', 'zulbia'] WHERE LOWER(name) = 'jalebi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['ladoo', 'laddoo', 'ladu'] WHERE LOWER(name) = 'laddu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['burfi', 'barfee'] WHERE LOWER(name) = 'barfi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['halva', 'halvah', 'helva'] WHERE LOWER(name) = 'halwa' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kulfee'] WHERE LOWER(name) = 'kulfi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['lassee'] WHERE LOWER(name) = 'lassi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['panir'] WHERE LOWER(name) = 'paneer' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kurma', 'qorma'] WHERE LOWER(name) = 'korma' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['vindalho', 'bindaloo'] WHERE LOWER(name) = 'vindaloo' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['qeema', 'kheema', 'kima'] WHERE LOWER(name) = 'keema' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pakoda', 'pakodi', 'bhajia', 'bhaji'] WHERE LOWER(name) = 'pakora' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['samossa', 'samoosa'] WHERE LOWER(name) = 'samosa' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['uthappam', 'utthapam', 'oothappam'] WHERE LOWER(name) = 'uttapam' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chaaru', 'saaru'] WHERE LOWER(name) = 'rasam' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pao bhaji', 'pav baji'] WHERE LOWER(name) = 'pav bhaji' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['choley', 'chholay', 'channay'] WHERE LOWER(name) = 'chole' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rajmah'] WHERE LOWER(name) = 'rajma' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rayita'] WHERE LOWER(name) = 'raita' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['cha', 'masala chai'] WHERE LOWER(name) = 'chai' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['ghi'] WHERE LOWER(name) = 'ghee' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['payasam', 'payesh', 'phirni'] WHERE LOWER(name) = 'kheer' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rasagola', 'rosogolla'] WHERE LOWER(name) = 'rasgulla' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rossomalai', 'rasmalai'] WHERE LOWER(name) = 'ras malai' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['aappam', 'hoppers'] WHERE LOWER(name) = 'appam' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pittu'] WHERE LOWER(name) = 'puttu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pongali'] WHERE LOWER(name) = 'pongal' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chappati', 'chapathi', 'roti'] WHERE LOWER(name) = 'chapati' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['roti', 'phulka'] WHERE LOWER(name) = 'chapatti' AND is_primary = TRUE;

-- ============================================================================
-- CHINESE (~25 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['general tao', 'general tsao', 'general gao', 'general cho'] WHERE LOWER(name) LIKE 'general tso%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['gong bao', 'gongbao', 'kung po'] WHERE LOWER(name) LIKE 'kung pao%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['wantan', 'wuntun', 'huntun'] WHERE LOWER(name) = 'wonton' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chowmin', 'chao mian'] WHERE LOWER(name) = 'chow mein' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chowmin', 'chao mian'] WHERE LOWER(name) LIKE 'chow mein%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['dim sim', 'dian xin'] WHERE LOWER(name) = 'dim sum' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pak choi', 'bak choy'] WHERE LOWER(name) = 'bok choy' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['cha siu', 'char siew', 'cha shao'] WHERE LOWER(name) = 'char siu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['jiaozi', 'pot stickers', 'potstickers', 'guotie'] WHERE LOWER(name) = 'gyoza' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['jook', 'zhou'] WHERE LOWER(name) = 'congee' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['baozi', 'steamed buns'] WHERE LOWER(name) = 'bao' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['xiaolongbao', 'soup dumplings', 'xlb'] WHERE LOWER(name) = 'xiao long bao' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['shaomai', 'shumai'] WHERE LOWER(name) = 'siu mai' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['mapo doufu'] WHERE LOWER(name) LIKE 'mapo tofu%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['mu shu', 'mu xu'] WHERE LOWER(name) LIKE 'moo shu%' AND is_primary = TRUE;

-- ============================================================================
-- JAPANESE (~20 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['edamamme'] WHERE LOWER(name) = 'edamame' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tenpura'] WHERE LOWER(name) = 'tempura' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['terriaki', 'teriyake'] WHERE LOWER(name) LIKE 'teriyaki%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tako yaki', 'octopus balls'] WHERE LOWER(name) = 'takoyaki' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['okonomi-yaki', 'japanese pancake'] WHERE LOWER(name) = 'okonomiyaki' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['macha', 'maccha'] WHERE LOWER(name) = 'matcha' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['mochee', 'moci'] WHERE LOWER(name) = 'mochi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kara-age', 'japanese fried chicken'] WHERE LOWER(name) = 'karaage' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['ton katsu', 'pork cutlet'] WHERE LOWER(name) = 'tonkatsu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['omusubi', 'rice ball'] WHERE LOWER(name) = 'onigiri' AND is_primary = TRUE;

-- ============================================================================
-- KOREAN (~20 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['kimchee', 'kim chi', 'gimchi'] WHERE LOWER(name) = 'kimchi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['bibimbop', 'bi bim bap', 'bi bim bop'] WHERE LOWER(name) = 'bibimbap' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['bulgoki', 'bul go gi', 'boolgogi'] WHERE LOWER(name) = 'bulgogi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['ddeokbokki', 'dukbokki', 'topokki', 'tokbokki', 'ddukbokki'] WHERE LOWER(name) = 'tteokbokki' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chapchae', 'jabchae', 'japchay'] WHERE LOWER(name) = 'japchae' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kalbi'] WHERE LOWER(name) = 'galbi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['gimbap', 'kimbop'] WHERE LOWER(name) = 'kimbap' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kochujang'] WHERE LOWER(name) = 'gochujang' AND is_primary = TRUE;

-- ============================================================================
-- THAI (~18 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['phat thai', 'padthai'] WHERE LOWER(name) = 'pad thai' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['phat thai', 'padthai'] WHERE LOWER(name) LIKE 'pad thai%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tom yam', 'tomyam'] WHERE LOWER(name) = 'tom yum' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tom yam', 'tomyam'] WHERE LOWER(name) LIKE 'tom yum%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['matsaman', 'mussaman'] WHERE LOWER(name) LIKE 'massaman%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['phanaeng', 'phanang', 'penang curry'] WHERE LOWER(name) LIKE 'panang%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['sate', 'satey'] WHERE LOWER(name) = 'satay' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['laab', 'laap', 'lahb'] WHERE LOWER(name) = 'larb' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pad krapao', 'pad ka prao'] WHERE LOWER(name) = 'pad kra pao' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kao soy'] WHERE LOWER(name) = 'khao soi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['som tum', 'papaya salad'] WHERE LOWER(name) = 'som tam' AND is_primary = TRUE;

-- ============================================================================
-- VIETNAMESE (~12 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['pho bo', 'pho ga'] WHERE LOWER(name) = 'pho' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['bahn mi'] WHERE LOWER(name) = 'banh mi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['summer roll', 'fresh spring roll', 'rice paper roll'] WHERE LOWER(name) = 'goi cuon' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['vietnamese crepe'] WHERE LOWER(name) = 'banh xeo' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['broken rice'] WHERE LOWER(name) = 'com tam' AND is_primary = TRUE;

-- ============================================================================
-- MIDDLE EASTERN (~20 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['houmous', 'hommus', 'humus', 'hummous'] WHERE LOWER(name) = 'hummus' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['shawerma', 'shwarma', 'shoarma'] WHERE LOWER(name) = 'shawarma' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['felafel'] WHERE LOWER(name) = 'falafel' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kabob', 'kabab', 'kebap', 'cabob'] WHERE LOWER(name) = 'kebab' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['baba ghanoush', 'baba ghanouj', 'mutabal', 'moutabal'] WHERE LOWER(name) = 'baba ganoush' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tabouleh', 'tabouli', 'tabbouli'] WHERE LOWER(name) = 'tabbouleh' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tahina', 'tehina'] WHERE LOWER(name) = 'tahini' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kebbe', 'kibbe', 'kubbeh'] WHERE LOWER(name) = 'kibbeh' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['shakshouka', 'chakchouka'] WHERE LOWER(name) = 'shakshuka' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kunafa', 'kanafeh', 'kunefe'] WHERE LOWER(name) = 'knafeh' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pitta', 'khubz'] WHERE LOWER(name) = 'pita' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pitta', 'khubz'] WHERE LOWER(name) LIKE 'pita%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['haloumi', 'hellim'] WHERE LOWER(name) = 'halloumi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kafta', 'kefta', 'kofte'] WHERE LOWER(name) = 'kofta' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['lahmajun'] WHERE LOWER(name) = 'lahmacun' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['zaatar', 'zatar'] WHERE LOWER(name) = 'za''atar' AND is_primary = TRUE;

-- ============================================================================
-- MEXICAN / LATIN (~20 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['quesadiya'] WHERE LOWER(name) = 'quesadilla' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['quesadiya'] WHERE LOWER(name) LIKE 'quesadilla%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['guac'] WHERE LOWER(name) = 'guacamole' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['enchillada'] WHERE LOWER(name) = 'enchilada' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['enchillada'] WHERE LOWER(name) LIKE 'enchilada%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tamal', 'tamales'] WHERE LOWER(name) = 'tamale' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['posole'] WHERE LOWER(name) = 'pozole' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['seviche', 'cebiche'] WHERE LOWER(name) = 'ceviche' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['chilequiles'] WHERE LOWER(name) = 'chilaquiles' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['orchata'] WHERE LOWER(name) = 'horchata' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['empanadas'] WHERE LOWER(name) = 'empanada' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['arepas'] WHERE LOWER(name) = 'arepa' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['burito'] WHERE LOWER(name) = 'burrito' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['burito'] WHERE LOWER(name) LIKE 'burrito%' AND is_primary = TRUE;

-- ============================================================================
-- ITALIAN (~20 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['bruchetta', 'bruscetta'] WHERE LOWER(name) = 'bruschetta' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['gnochi', 'gnocci', 'nochi'] WHERE LOWER(name) = 'gnocchi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['prosciuto', 'proscuitto'] WHERE LOWER(name) = 'prosciutto' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['foccacia', 'focacia'] WHERE LOWER(name) = 'focaccia' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['marscapone', 'mascapone'] WHERE LOWER(name) = 'mascarpone' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['fettucine', 'fettuchini', 'fettuccini'] WHERE LOWER(name) = 'fettuccine' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['fettucine', 'fettuchini', 'fettuccini'] WHERE LOWER(name) LIKE 'fettuccine%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['canoli'] WHERE LOWER(name) = 'cannoli' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rissotto', 'risoto'] WHERE LOWER(name) = 'risotto' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['rissotto', 'risoto'] WHERE LOWER(name) LIKE 'risotto%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['bolognaise', 'bolognase'] WHERE LOWER(name) LIKE '%bolognese%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['ciabata'] WHERE LOWER(name) = 'ciabatta' AND is_primary = TRUE;

-- ============================================================================
-- GREEK (~15 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['gyros', 'yeero', 'yiro'] WHERE LOWER(name) = 'gyro' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tsatziki', 'tzaziki', 'zaziki', 'cacik'] WHERE LOWER(name) = 'tzatziki' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['mousaka', 'musaka'] WHERE LOWER(name) = 'moussaka' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['spanikopita', 'spinach pie'] WHERE LOWER(name) = 'spanakopita' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['baklawa', 'baclava'] WHERE LOWER(name) = 'baklava' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['souvlakia', 'kalamaki'] WHERE LOWER(name) = 'souvlaki' AND is_primary = TRUE;

-- ============================================================================
-- ETHIOPIAN / AFRICAN (~15 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['enjera'] WHERE LOWER(name) = 'injera' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['doro wot', 'doro wet'] WHERE LOWER(name) = 'doro wat' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['jollof', 'jolof'] WHERE LOWER(name) = 'jollof rice' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['foofoo', 'foutou', 'foufou'] WHERE LOWER(name) = 'fufu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['nsima', 'sadza', 'pap'] WHERE LOWER(name) = 'ugali' AND is_primary = TRUE;

-- ============================================================================
-- EASTERN EUROPEAN (~15 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['perogi', 'perogies', 'pyrohy', 'varenyky', 'vareniki'] WHERE LOWER(name) = 'pierogi' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['perogi', 'perogies', 'pyrohy', 'varenyky', 'vareniki'] WHERE LOWER(name) LIKE 'pierogi%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['borsch', 'borsht', 'borshch'] WHERE LOWER(name) = 'borscht' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['kielbasi', 'kolbasa', 'kobasa'] WHERE LOWER(name) = 'kielbasa' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['gulyas', 'gulasch'] WHERE LOWER(name) = 'goulash' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['blin', 'bliny', 'blintz', 'blintzes'] WHERE LOWER(name) = 'blini' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['saurkraut'] WHERE LOWER(name) = 'sauerkraut' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['schnitzle'] WHERE LOWER(name) = 'schnitzel' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['schnitzle'] WHERE LOWER(name) LIKE 'schnitzel%' AND is_primary = TRUE;

-- ============================================================================
-- FILIPINO (~15 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['lunpia'] WHERE LOWER(name) = 'lumpia' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['lunpia'] WHERE LOWER(name) LIKE 'lumpia%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pansit'] WHERE LOWER(name) = 'pancit' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pansit'] WHERE LOWER(name) LIKE 'pancit%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['haluhalo'] WHERE LOWER(name) = 'halo-halo' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['sizzling sisig'] WHERE LOWER(name) = 'sisig' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['adobong'] WHERE LOWER(name) = 'adobo' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['adobong'] WHERE LOWER(name) LIKE 'adobo%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['bibinka'] WHERE LOWER(name) = 'bibingka' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['longanisa'] WHERE LOWER(name) = 'longganisa' AND is_primary = TRUE;

-- ============================================================================
-- INDONESIAN / MALAYSIAN (~15 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['nasigoreng'] WHERE LOWER(name) = 'nasi goreng' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['randang'] WHERE LOWER(name) = 'rendang' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['mi goreng', 'mie goreng'] WHERE LOWER(name) = 'mee goreng' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['roti chanai', 'roti prata'] WHERE LOWER(name) = 'roti canai' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['tempe'] WHERE LOWER(name) = 'tempeh' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['char kuey teow', 'char koay teow', 'ckt'] WHERE LOWER(name) = 'char kway teow' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['baso'] WHERE LOWER(name) = 'bakso' AND is_primary = TRUE;

-- ============================================================================
-- CROSS-CUISINE (~10 foods)
-- ============================================================================

UPDATE food_database SET variant_names = ARRAY['yoghurt', 'yogourt', 'curd'] WHERE LOWER(name) = 'yogurt' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['yoghurt', 'yogourt', 'curd'] WHERE LOWER(name) LIKE 'yogurt%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['pilau', 'pulao', 'polov', 'palov', 'pilav'] WHERE LOWER(name) = 'pilaf' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['cous cous'] WHERE LOWER(name) = 'couscous' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['cous cous'] WHERE LOWER(name) LIKE 'couscous%' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['doufu', 'bean curd', 'tauhu'] WHERE LOWER(name) = 'tofu' AND is_primary = TRUE;
UPDATE food_database SET variant_names = ARRAY['doufu', 'bean curd', 'tauhu'] WHERE LOWER(name) LIKE 'tofu%' AND is_primary = TRUE;
