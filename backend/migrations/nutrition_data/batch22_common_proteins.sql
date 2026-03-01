-- ============================================================================
-- Batch 22: Common Protein Foods for Fitness/Calorie Tracking
-- Total items: ~100 high-protein foods
-- Generated: 2026-02-28
-- Sources: USDA FoodData Central (fdc.nal.usda.gov), nutritionvalue.org
-- All values are per 100g of cooked/prepared food unless noted.
-- Calorie check: cal ≈ (protein*4) + (carbs*4) + (fat*9)
-- ============================================================================

-- ============================================================================
-- CHICKEN (~15 items)
-- ============================================================================

-- Chicken Breast Grilled (skinless): USDA #05064 — 165 cal, 31g protein, 0g carbs, 3.6g fat per 100g
('chicken_breast_grilled', 'Chicken Breast (Grilled, Skinless)', 165.0, 31.0, 0.0, 3.6, 0.0, 0.0, NULL, 120, 'usda', ARRAY['grilled chicken breast', 'chicken breast grilled', 'skinless chicken breast', 'plain grilled chicken'], '198 cal per grilled breast (~120g). Lean protein staple.', NULL, 'proteins', 1),

-- Chicken Breast Baked (skinless): USDA #05063 — 165 cal, 31g protein, 0g carbs, 3.6g fat per 100g
('chicken_breast_baked', 'Chicken Breast (Baked, Skinless)', 165.0, 31.0, 0.0, 3.6, 0.0, 0.0, NULL, 120, 'usda', ARRAY['baked chicken breast', 'oven baked chicken breast', 'roasted chicken breast skinless'], '198 cal per baked breast (~120g). Same as grilled, dry-heat method.', NULL, 'proteins', 1),

-- Chicken Breast Fried (breaded): ~220 cal, 24g protein, 8g carbs, 10g fat per 100g
('chicken_breast_fried', 'Chicken Breast (Fried, Breaded)', 220.0, 24.0, 8.0, 10.0, 0.3, 0.5, NULL, 140, 'usda', ARRAY['fried chicken breast', 'breaded chicken breast', 'pan fried chicken breast'], '308 cal per fried breast (~140g). Flour-coated, pan or deep fried.', NULL, 'proteins', 1),

-- Chicken Thigh Bone-In (skin on, roasted): USDA #05096 — 229 cal, 24g protein, 0g carbs, 14.2g fat per 100g
('chicken_thigh_bone_in', 'Chicken Thigh (Bone-In, Skin On)', 229.0, 24.0, 0.0, 14.2, 0.0, 0.0, 125, 125, 'usda', ARRAY['bone in chicken thigh', 'chicken thigh with skin', 'roasted chicken thigh'], '286 cal per thigh (~125g with bone). Dark meat, juicier than breast.', NULL, 'proteins', 1),

-- Chicken Thigh Boneless (skinless, roasted): USDA #05093 — 177.0 cal, 24.8g protein, 0g carbs, 8.2g fat per 100g
('chicken_thigh_boneless', 'Chicken Thigh (Boneless, Skinless)', 177.0, 24.8, 0.0, 8.2, 0.0, 0.0, 85, 170, 'usda', ARRAY['boneless skinless chicken thigh', 'chicken thigh skinless', 'boneless chicken thigh'], '150 cal per thigh (~85g). Two thighs per serving.', NULL, 'proteins', 2),

-- Chicken Wing (roasted, skin on): USDA #05100 — 266 cal, 26g protein, 0g carbs, 17.5g fat per 100g
('chicken_wing', 'Chicken Wing (Roasted, Skin On)', 266.0, 26.0, 0.0, 17.5, 0.0, 0.0, 34, 136, 'usda', ARRAY['chicken wings', 'roasted chicken wings', 'baked chicken wings', 'plain wings'], '90 cal per wing (~34g). Four wings per serving.', NULL, 'proteins', 4),

-- Chicken Drumstick (roasted, skin on): USDA #05098 — 216 cal, 27g protein, 0g carbs, 11.4g fat per 100g
('chicken_drumstick', 'Chicken Drumstick (Roasted, Skin On)', 216.0, 27.0, 0.0, 11.4, 0.0, 0.0, 76, 152, 'usda', ARRAY['chicken drumsticks', 'chicken leg', 'roasted drumstick', 'baked drumstick'], '164 cal per drumstick (~76g). Two drumsticks per serving.', NULL, 'proteins', 2),

-- Ground Chicken (cooked): ~170 cal, 20.5g protein, 0g carbs, 9.5g fat per 100g
('ground_chicken', 'Ground Chicken (Cooked)', 170.0, 20.5, 0.0, 9.5, 0.0, 0.0, NULL, 112, 'usda', ARRAY['chicken mince', 'minced chicken', 'cooked ground chicken'], '190 cal per 4oz serving (~112g). Versatile lean ground meat.', NULL, 'proteins', 1),

-- Rotisserie Chicken (meat with skin): ~190 cal, 25g protein, 0g carbs, 10g fat per 100g
('rotisserie_chicken', 'Rotisserie Chicken (Meat & Skin)', 190.0, 25.0, 0.0, 10.0, 0.0, 0.0, NULL, 140, 'usda', ARRAY['store bought rotisserie chicken', 'rotisserie chicken breast', 'costco rotisserie chicken', 'deli rotisserie chicken'], '266 cal per serving (~140g). Mixed light and dark meat with skin.', NULL, 'proteins', 1),

-- Chicken Tenders (breaded, baked): ~230 cal, 20g protein, 12g carbs, 11g fat per 100g
('chicken_tenders', 'Chicken Tenders (Breaded)', 230.0, 20.0, 12.0, 11.0, 0.5, 0.5, 35, 140, 'usda', ARRAY['chicken strips', 'chicken fingers', 'breaded chicken tenders', 'crispy chicken tenders'], '322 cal per 4 tenders (~140g). Breaded and fried/baked.', NULL, 'proteins', 4),

-- Chicken Nuggets (homemade, baked): ~245 cal, 18g protein, 14g carbs, 13g fat per 100g
('chicken_nuggets_homemade', 'Chicken Nuggets (Homemade)', 245.0, 18.0, 14.0, 13.0, 0.5, 0.5, 18, 108, 'usda', ARRAY['homemade chicken nuggets', 'baked chicken nuggets', 'chicken nuggets'], '265 cal per 6 nuggets (~108g). Homemade breaded nuggets.', NULL, 'proteins', 6),

-- Chicken Breast Roasted (skin on): ~197 cal, 28g protein, 0g carbs, 9g fat per 100g
('chicken_breast_roasted_skin', 'Chicken Breast (Roasted, Skin On)', 197.0, 28.0, 0.0, 9.0, 0.0, 0.0, NULL, 140, 'usda', ARRAY['roasted chicken breast skin on', 'chicken breast with skin', 'bone in chicken breast'], '276 cal per breast (~140g). Skin adds fat and flavor.', NULL, 'proteins', 1),

-- Chicken Thigh (Fried, Breaded): ~240 cal, 19g protein, 8g carbs, 15g fat per 100g
('chicken_thigh_fried', 'Chicken Thigh (Fried, Breaded)', 240.0, 19.0, 8.0, 15.0, 0.3, 0.5, 130, 130, 'usda', ARRAY['fried chicken thigh', 'breaded chicken thigh', 'crispy chicken thigh'], '312 cal per thigh (~130g). Breaded and deep or pan fried.', NULL, 'proteins', 1),

-- Chicken Sausage (Italian-style, cooked): ~160 cal, 18g protein, 3g carbs, 8g fat per 100g
('chicken_sausage_italian', 'Chicken Sausage (Italian-Style)', 160.0, 18.0, 3.0, 8.0, 0.0, 1.0, 68, 68, 'usda', ARRAY['italian chicken sausage', 'chicken italian sausage', 'chicken andouille sausage'], '109 cal per link (~68g). Leaner Italian sausage option.', NULL, 'proteins', 1),

-- Canned Chicken Breast (drained): ~127 cal, 25g protein, 0g carbs, 2.5g fat per 100g
('canned_chicken_breast', 'Canned Chicken Breast (Drained)', 127.0, 25.0, 0.0, 2.5, 0.0, 0.0, NULL, 56, 'usda', ARRAY['canned chicken', 'chicken in a can', 'canned white chicken', 'chunk chicken breast'], '71 cal per 2oz drained (~56g). Convenient pantry protein.', NULL, 'proteins', 1),

-- ============================================================================
-- BEEF (~15 items)
-- ============================================================================

-- Ground Beef 90/10 (cooked, pan-browned): USDA #23557 — 196 cal, 27.6g protein, 0g carbs, 9.0g fat per 100g
('ground_beef_90_10', 'Ground Beef 90/10 (Cooked)', 196.0, 27.6, 0.0, 9.0, 0.0, 0.0, NULL, 112, 'usda', ARRAY['90 10 ground beef', 'lean ground beef', 'extra lean ground beef', '90 percent lean beef'], '220 cal per 4oz cooked (~112g). Extra lean, great for meal prep.', NULL, 'proteins', 1),

-- Ground Beef 85/15 (cooked, pan-browned): USDA #23556 — 232 cal, 26.1g protein, 0g carbs, 13.5g fat per 100g
('ground_beef_85_15', 'Ground Beef 85/15 (Cooked)', 232.0, 26.1, 0.0, 13.5, 0.0, 0.0, NULL, 112, 'usda', ARRAY['85 15 ground beef', 'ground beef', 'lean ground beef 85'], '260 cal per 4oz cooked (~112g). Standard lean ground beef.', NULL, 'proteins', 1),

-- Ground Beef 80/20 (cooked, pan-browned): USDA #23555 — 259 cal, 25.5g protein, 0g carbs, 16.9g fat per 100g
('ground_beef_80_20', 'Ground Beef 80/20 (Cooked)', 259.0, 25.5, 0.0, 16.9, 0.0, 0.0, NULL, 112, 'usda', ARRAY['80 20 ground beef', 'regular ground beef', 'ground chuck'], '290 cal per 4oz cooked (~112g). Standard ground beef for burgers.', NULL, 'proteins', 1),

-- Sirloin Steak (grilled, trimmed): USDA #23239 — 183 cal, 29.2g protein, 0g carbs, 6.8g fat per 100g
('sirloin_steak', 'Sirloin Steak (Grilled, Trimmed)', 183.0, 29.2, 0.0, 6.8, 0.0, 0.0, NULL, 170, 'usda', ARRAY['top sirloin steak', 'grilled sirloin', 'sirloin', 'top sirloin'], '311 cal per 6oz steak (~170g). Lean, affordable steak cut.', NULL, 'proteins', 1),

-- Ribeye Steak (grilled, trimmed): USDA #13926 — 250 cal, 26.0g protein, 0g carbs, 16.0g fat per 100g
('ribeye_steak', 'Ribeye Steak (Grilled, Trimmed)', 250.0, 26.0, 0.0, 16.0, 0.0, 0.0, NULL, 200, 'usda', ARRAY['rib eye steak', 'grilled ribeye', 'ribeye', 'rib eye'], '500 cal per 7oz steak (~200g). Well-marbled, flavorful cut.', NULL, 'proteins', 1),

-- NY Strip Steak (grilled, trimmed): USDA #13920 — 217 cal, 28.0g protein, 0g carbs, 11.3g fat per 100g
('ny_strip_steak', 'NY Strip Steak (Grilled, Trimmed)', 217.0, 28.0, 0.0, 11.3, 0.0, 0.0, NULL, 200, 'usda', ARRAY['new york strip', 'strip steak', 'grilled ny strip', 'new york strip steak', 'kansas city strip'], '434 cal per 7oz steak (~200g). Classic steakhouse cut.', NULL, 'proteins', 1),

-- Filet Mignon (grilled, trimmed): USDA #13925 — 196 cal, 28.5g protein, 0g carbs, 8.6g fat per 100g
('filet_mignon', 'Filet Mignon (Grilled, Trimmed)', 196.0, 28.5, 0.0, 8.6, 0.0, 0.0, NULL, 170, 'usda', ARRAY['beef tenderloin steak', 'filet mignon steak', 'tenderloin steak', 'filet'], '333 cal per 6oz filet (~170g). Most tender, lean premium cut.', NULL, 'proteins', 1),

-- Flank Steak (grilled): USDA #23012 — 192 cal, 29.0g protein, 0g carbs, 7.7g fat per 100g
('flank_steak', 'Flank Steak (Grilled)', 192.0, 29.0, 0.0, 7.7, 0.0, 0.0, NULL, 170, 'usda', ARRAY['grilled flank steak', 'london broil', 'flank steak grilled'], '326 cal per 6oz steak (~170g). Lean, great for fajitas and stir-fry.', NULL, 'proteins', 1),

-- Chuck Roast (braised, trimmed): USDA #23039 — 238 cal, 28.0g protein, 0g carbs, 13.3g fat per 100g
('chuck_roast', 'Chuck Roast (Braised)', 238.0, 28.0, 0.0, 13.3, 0.0, 0.0, NULL, 170, 'usda', ARRAY['pot roast', 'beef chuck roast', 'braised chuck roast', 'beef pot roast'], '405 cal per 6oz serving (~170g). Slow-cooked comfort food.', NULL, 'proteins', 1),

-- Beef Brisket (braised, trimmed): USDA #23046 — 246 cal, 27.0g protein, 0g carbs, 14.8g fat per 100g
('beef_brisket', 'Beef Brisket (Braised, Trimmed)', 246.0, 27.0, 0.0, 14.8, 0.0, 0.0, NULL, 170, 'usda', ARRAY['smoked brisket', 'bbq brisket', 'beef brisket smoked', 'brisket flat'], '418 cal per 6oz serving (~170g). Slow-smoked or braised.', NULL, 'proteins', 1),

-- Corned Beef (cooked): USDA #13346 — 251 cal, 18.2g protein, 0.5g carbs, 19.0g fat per 100g
('corned_beef', 'Corned Beef (Cooked)', 251.0, 18.2, 0.5, 19.0, 0.0, 0.0, NULL, 85, 'usda', ARRAY['corned beef brisket', 'cooked corned beef', 'deli corned beef'], '213 cal per 3oz serving (~85g). Cured, brined beef brisket.', NULL, 'proteins', 1),

-- Beef Stew Meat (braised): USDA #23052 — 215 cal, 28.5g protein, 0.0g carbs, 10.5g fat per 100g
('beef_stew_meat', 'Beef Stew Meat (Braised)', 215.0, 28.5, 0.0, 10.5, 0.0, 0.0, NULL, 140, 'usda', ARRAY['stew beef', 'beef cubes', 'braised beef cubes', 'beef chunks'], '301 cal per 5oz serving (~140g). Cubed chuck or round for stews.', NULL, 'proteins', 1),

-- T-Bone Steak (grilled, trimmed): ~205 cal, 27.5g protein, 0g carbs, 10.2g fat per 100g
('tbone_steak', 'T-Bone Steak (Grilled, Trimmed)', 205.0, 27.5, 0.0, 10.2, 0.0, 0.0, NULL, 200, 'usda', ARRAY['t-bone steak', 'grilled t bone', 'tbone', 'porterhouse steak'], '410 cal per 7oz steak (~200g). Includes strip and tenderloin portions.', NULL, 'proteins', 1),

-- Skirt Steak (grilled): ~195 cal, 26.7g protein, 0g carbs, 9.3g fat per 100g
('skirt_steak', 'Skirt Steak (Grilled)', 195.0, 26.7, 0.0, 9.3, 0.0, 0.0, NULL, 170, 'usda', ARRAY['grilled skirt steak', 'fajita steak', 'carne asada steak', 'outside skirt steak'], '332 cal per 6oz steak (~170g). Popular for fajitas and carne asada.', NULL, 'proteins', 1),

-- Ground Beef 73/27 (cooked): ~293 cal, 23.8g protein, 0g carbs, 21.5g fat per 100g
('ground_beef_73_27', 'Ground Beef 73/27 (Cooked)', 293.0, 23.8, 0.0, 21.5, 0.0, 0.0, NULL, 112, 'usda', ARRAY['73 27 ground beef', 'regular ground beef fatty', 'ground beef 70 30', 'high fat ground beef'], '328 cal per 4oz cooked (~112g). Budget-friendly, higher fat grind.', NULL, 'proteins', 1),

-- ============================================================================
-- PORK (~10 items)
-- ============================================================================

-- Pork Chop (bone-in, grilled, trimmed): USDA #10045 — 197 cal, 28.8g protein, 0g carbs, 8.4g fat per 100g
('pork_chop', 'Pork Chop (Bone-In, Grilled)', 197.0, 28.8, 0.0, 8.4, 0.0, 0.0, 150, 150, 'usda', ARRAY['grilled pork chop', 'bone in pork chop', 'pork loin chop', 'center cut pork chop'], '296 cal per chop (~150g with bone). Lean and versatile.', NULL, 'proteins', 1),

-- Pork Tenderloin (roasted): USDA #10218 — 143 cal, 26.2g protein, 0g carbs, 3.5g fat per 100g
('pork_tenderloin', 'Pork Tenderloin (Roasted)', 143.0, 26.2, 0.0, 3.5, 0.0, 0.0, NULL, 113, 'usda', ARRAY['roasted pork tenderloin', 'pork tenderloin roast', 'pork loin tenderloin'], '162 cal per 4oz serving (~113g). Leanest pork cut, comparable to chicken breast.', NULL, 'proteins', 1),

-- Pulled Pork (slow-cooked, no sauce): ~210 cal, 24g protein, 0g carbs, 12.3g fat per 100g
('pulled_pork', 'Pulled Pork (No Sauce)', 210.0, 24.0, 0.0, 12.3, 0.0, 0.0, NULL, 140, 'usda', ARRAY['slow cooked pulled pork', 'bbq pulled pork', 'smoked pulled pork', 'shredded pork'], '294 cal per 5oz serving (~140g). From pork shoulder, slow-cooked.', NULL, 'proteins', 1),

-- Ham Deli Slices (extra lean): USDA #07028 — 113 cal, 18.0g protein, 1.5g carbs, 3.5g fat per 100g
('ham_deli', 'Ham (Deli Sliced, Extra Lean)', 113.0, 18.0, 1.5, 3.5, 0.0, 1.0, NULL, 56, 'usda', ARRAY['deli ham', 'sliced ham', 'honey ham deli', 'lunch meat ham', 'ham slices'], '63 cal per 2oz serving (~56g). Low-fat deli lunch meat.', NULL, 'proteins', 1),

-- Bacon (pan-fried, cured): USDA #10124 — 541 cal, 37.0g protein, 1.4g carbs, 42.0g fat per 100g
('bacon', 'Bacon (Pan-Fried)', 541.0, 37.0, 1.4, 42.0, 0.0, 0.0, 8, 24, 'usda', ARRAY['fried bacon', 'crispy bacon', 'pork bacon', 'bacon strips', 'breakfast bacon'], '43 cal per slice (~8g cooked). Three slices per serving.', NULL, 'proteins', 3),

-- Pork Sausage Links (cooked): USDA #07066 — 339 cal, 19.4g protein, 0.3g carbs, 28.4g fat per 100g
('pork_sausage_links', 'Pork Sausage Links (Cooked)', 339.0, 19.4, 0.3, 28.4, 0.0, 0.0, 25, 75, 'usda', ARRAY['breakfast sausage links', 'pork sausage', 'breakfast sausage', 'sausage links'], '85 cal per link (~25g). Three links per serving.', NULL, 'proteins', 3),

-- Italian Sausage (cooked): USDA #07072 — 280 cal, 19.5g protein, 2.5g carbs, 21.5g fat per 100g
('italian_sausage', 'Italian Sausage (Cooked)', 280.0, 19.5, 2.5, 21.5, 0.0, 1.0, 83, 83, 'usda', ARRAY['sweet italian sausage', 'hot italian sausage', 'italian pork sausage', 'cooked italian sausage'], '232 cal per link (~83g). Sweet or hot variety.', NULL, 'proteins', 1),

-- Bratwurst (cooked): USDA #07068 — 297 cal, 13.7g protein, 2.8g carbs, 25.3g fat per 100g
('bratwurst', 'Bratwurst (Cooked)', 297.0, 13.7, 2.8, 25.3, 0.0, 0.0, 85, 85, 'usda', ARRAY['cooked bratwurst', 'grilled bratwurst', 'brat', 'beer brat'], '252 cal per link (~85g). German-style pork sausage.', NULL, 'proteins', 1),

-- Pork Belly (roasted): ~518 cal, 9.3g protein, 0g carbs, 53.0g fat per 100g
('pork_belly', 'Pork Belly (Roasted)', 518.0, 9.3, 0.0, 53.0, 0.0, 0.0, NULL, 85, 'usda', ARRAY['roasted pork belly', 'crispy pork belly', 'pork belly slices'], '440 cal per 3oz serving (~85g). Very high fat content.', NULL, 'proteins', 1),

-- Chorizo (Mexican, cooked): ~275 cal, 14.5g protein, 3.0g carbs, 23.0g fat per 100g
('chorizo', 'Chorizo (Mexican, Cooked)', 275.0, 14.5, 3.0, 23.0, 0.0, 0.0, NULL, 60, 'usda', ARRAY['mexican chorizo', 'pork chorizo', 'chorizo sausage', 'cooked chorizo'], '165 cal per 60g serving. Spiced Mexican pork sausage.', NULL, 'proteins', 1),

-- ============================================================================
-- TURKEY (~8 items)
-- ============================================================================

-- Turkey Breast (roasted, skinless): USDA #05186 — 135 cal, 30.1g protein, 0g carbs, 0.7g fat per 100g
('turkey_breast_roasted', 'Turkey Breast (Roasted, Skinless)', 135.0, 30.1, 0.0, 0.7, 0.0, 0.0, NULL, 140, 'usda', ARRAY['roasted turkey breast', 'oven roasted turkey', 'sliced turkey breast', 'white turkey meat'], '189 cal per 5oz serving (~140g). Ultra-lean protein source.', NULL, 'proteins', 1),

-- Ground Turkey 93/7 (cooked): USDA #05737 — 170 cal, 27.4g protein, 0g carbs, 6.3g fat per 100g
('ground_turkey_93_7', 'Ground Turkey 93/7 (Cooked)', 170.0, 27.4, 0.0, 6.3, 0.0, 0.0, NULL, 112, 'usda', ARRAY['93 7 ground turkey', 'lean ground turkey', 'extra lean ground turkey', '93 percent lean turkey'], '190 cal per 4oz cooked (~112g). Popular lean ground meat swap.', NULL, 'proteins', 1),

-- Ground Turkey 85/15 (cooked): USDA #05735 — 203 cal, 24.0g protein, 0g carbs, 11.5g fat per 100g
('ground_turkey_85_15', 'Ground Turkey 85/15 (Cooked)', 203.0, 24.0, 0.0, 11.5, 0.0, 0.0, NULL, 112, 'usda', ARRAY['85 15 ground turkey', 'ground turkey', 'regular ground turkey'], '227 cal per 4oz cooked (~112g). Standard ground turkey.', NULL, 'proteins', 1),

-- Turkey Deli Slices (oven-roasted): USDA #07249 — 104 cal, 18.0g protein, 2.0g carbs, 2.0g fat per 100g
('turkey_deli_slices', 'Turkey Breast Deli Slices', 104.0, 18.0, 2.0, 2.0, 0.0, 1.5, NULL, 56, 'usda', ARRAY['deli turkey', 'sliced deli turkey', 'turkey lunch meat', 'oven roasted turkey deli', 'turkey cold cuts'], '58 cal per 2oz serving (~56g). Common sandwich meat.', NULL, 'proteins', 1),

-- Turkey Bacon (cooked): ~218 cal, 27.0g protein, 1.5g carbs, 11.0g fat per 100g
('turkey_bacon', 'Turkey Bacon (Cooked)', 218.0, 27.0, 1.5, 11.0, 0.0, 1.0, 8, 24, 'usda', ARRAY['cooked turkey bacon', 'turkey bacon strips', 'turkey bacon slices'], '17 cal per slice (~8g cooked). Three slices per serving. Leaner than pork bacon.', NULL, 'proteins', 3),

-- Turkey Sausage (cooked): ~170 cal, 21.0g protein, 1.0g carbs, 8.5g fat per 100g
('turkey_sausage', 'Turkey Sausage (Cooked)', 170.0, 21.0, 1.0, 8.5, 0.0, 0.5, 56, 56, 'usda', ARRAY['turkey breakfast sausage', 'turkey sausage links', 'lean turkey sausage'], '95 cal per link (~56g). Leaner sausage alternative.', NULL, 'proteins', 1),

-- Turkey Burger Patty (cooked, 93/7): ~170 cal, 27g protein, 0g carbs, 6.5g fat per 100g
('turkey_burger_patty', 'Turkey Burger Patty (Cooked)', 170.0, 27.0, 0.0, 6.5, 0.0, 0.0, 112, 112, 'usda', ARRAY['turkey burger', 'ground turkey patty', 'turkey patty', 'lean turkey burger'], '190 cal per patty (~112g). Popular lean burger alternative.', NULL, 'proteins', 1),

-- Turkey Meatballs (baked): ~175 cal, 20.0g protein, 5.0g carbs, 8.0g fat per 100g
('turkey_meatballs', 'Turkey Meatballs (Baked)', 175.0, 20.0, 5.0, 8.0, 0.3, 1.0, 30, 120, 'usda', ARRAY['baked turkey meatballs', 'homemade turkey meatballs', 'lean turkey meatballs'], '210 cal per 4 meatballs (~120g). With breadcrumbs and egg.', NULL, 'proteins', 4),

-- ============================================================================
-- FISH (~12 items)
-- ============================================================================

-- Salmon Atlantic (baked): USDA #15236 — 208 cal, 25.4g protein, 0g carbs, 11.0g fat per 100g
('salmon_atlantic_baked', 'Salmon (Atlantic, Baked)', 208.0, 25.4, 0.0, 11.0, 0.0, 0.0, NULL, 170, 'usda', ARRAY['baked salmon', 'atlantic salmon', 'oven baked salmon', 'salmon fillet', 'grilled salmon'], '354 cal per 6oz fillet (~170g). Rich in omega-3 fatty acids.', NULL, 'proteins', 1),

-- Tuna Canned in Water (drained): USDA #15126 — 116 cal, 25.5g protein, 0g carbs, 0.8g fat per 100g
('tuna_canned_water', 'Tuna (Canned in Water, Drained)', 116.0, 25.5, 0.0, 0.8, 0.0, 0.0, NULL, 142, 'usda', ARRAY['canned tuna', 'tuna in water', 'chunk light tuna', 'canned tuna water pack', 'starkist tuna'], '165 cal per can (~142g drained). Budget-friendly lean protein.', NULL, 'proteins', 1),

-- Tuna Canned in Oil (drained): USDA #15121 — 198 cal, 29.1g protein, 0g carbs, 8.2g fat per 100g
('tuna_canned_oil', 'Tuna (Canned in Oil, Drained)', 198.0, 29.1, 0.0, 8.2, 0.0, 0.0, NULL, 142, 'usda', ARRAY['tuna in oil', 'oil packed tuna', 'canned tuna oil'], '281 cal per can (~142g drained). Higher calorie than water-packed.', NULL, 'proteins', 1),

-- Tuna Steak (fresh, seared): ~144 cal, 30.0g protein, 0g carbs, 1.6g fat per 100g
('tuna_steak_seared', 'Tuna Steak (Fresh, Seared)', 144.0, 30.0, 0.0, 1.6, 0.0, 0.0, NULL, 170, 'usda', ARRAY['ahi tuna steak', 'seared tuna', 'yellowfin tuna steak', 'fresh tuna steak', 'tuna steak grilled'], '245 cal per 6oz steak (~170g). Lean, high-protein fish.', NULL, 'proteins', 1),

-- Tilapia (baked): USDA #15261 — 128 cal, 26.2g protein, 0g carbs, 2.7g fat per 100g
('tilapia_baked', 'Tilapia (Baked)', 128.0, 26.2, 0.0, 2.7, 0.0, 0.0, NULL, 113, 'usda', ARRAY['baked tilapia', 'tilapia fillet', 'grilled tilapia', 'oven baked tilapia'], '145 cal per 4oz fillet (~113g). Mild, affordable white fish.', NULL, 'proteins', 1),

-- Cod (baked): USDA #15016 — 105 cal, 23.0g protein, 0g carbs, 0.9g fat per 100g
('cod_baked', 'Cod (Baked)', 105.0, 23.0, 0.0, 0.9, 0.0, 0.0, NULL, 170, 'usda', ARRAY['baked cod', 'atlantic cod', 'cod fillet', 'grilled cod', 'pacific cod'], '179 cal per 6oz fillet (~170g). Very lean white fish.', NULL, 'proteins', 1),

-- Halibut (baked): USDA #15037 — 140 cal, 26.7g protein, 0g carbs, 2.9g fat per 100g
('halibut_baked', 'Halibut (Baked)', 140.0, 26.7, 0.0, 2.9, 0.0, 0.0, NULL, 170, 'usda', ARRAY['baked halibut', 'halibut fillet', 'grilled halibut', 'pacific halibut'], '238 cal per 6oz fillet (~170g). Firm, mild white fish.', NULL, 'proteins', 1),

-- Mahi Mahi (baked): ~109 cal, 23.7g protein, 0g carbs, 1.0g fat per 100g
('mahi_mahi_baked', 'Mahi Mahi (Baked)', 109.0, 23.7, 0.0, 1.0, 0.0, 0.0, NULL, 170, 'usda', ARRAY['baked mahi mahi', 'dolphinfish', 'grilled mahi mahi', 'mahi mahi fillet'], '185 cal per 6oz fillet (~170g). Lean tropical fish.', NULL, 'proteins', 1),

-- Rainbow Trout (baked): USDA #15115 — 168 cal, 23.5g protein, 0g carbs, 7.5g fat per 100g
('rainbow_trout_baked', 'Rainbow Trout (Baked)', 168.0, 23.5, 0.0, 7.5, 0.0, 0.0, NULL, 143, 'usda', ARRAY['baked trout', 'trout fillet', 'grilled trout', 'steelhead trout'], '240 cal per 5oz fillet (~143g). Good omega-3 source.', NULL, 'proteins', 1),

-- Catfish (baked): USDA #15011 — 144 cal, 18.0g protein, 0g carbs, 7.6g fat per 100g
('catfish_baked', 'Catfish (Baked)', 144.0, 18.0, 0.0, 7.6, 0.0, 0.0, NULL, 143, 'usda', ARRAY['baked catfish', 'catfish fillet', 'grilled catfish', 'fried catfish'], '206 cal per 5oz fillet (~143g). Southern favorite, mild flavor.', NULL, 'proteins', 1),

-- Sardines (canned in oil, drained): USDA #15088 — 208 cal, 24.6g protein, 0g carbs, 11.5g fat per 100g
('sardines_canned', 'Sardines (Canned in Oil, Drained)', 208.0, 24.6, 0.0, 11.5, 0.0, 0.0, NULL, 92, 'usda', ARRAY['canned sardines', 'sardines in oil', 'sardines', 'tinned sardines'], '191 cal per can (~92g drained). High in omega-3 and calcium.', NULL, 'proteins', 1),

-- Anchovies (canned in oil, drained): USDA #15001 — 210 cal, 28.9g protein, 0g carbs, 9.7g fat per 100g
('anchovies_canned', 'Anchovies (Canned in Oil, Drained)', 210.0, 28.9, 0.0, 9.7, 0.0, 0.0, 4, 20, 'usda', ARRAY['canned anchovies', 'anchovy fillets', 'anchovies in oil'], '42 cal per 5 fillets (~20g). Intense umami flavor.', NULL, 'proteins', 5),

-- ============================================================================
-- SHELLFISH (~8 items)
-- ============================================================================

-- Shrimp (cooked, steamed): USDA #15151 — 99 cal, 24.0g protein, 0.2g carbs, 0.3g fat per 100g
('shrimp_cooked', 'Shrimp (Cooked, Steamed)', 99.0, 24.0, 0.2, 0.3, 0.0, 0.0, 7, 84, 'usda', ARRAY['steamed shrimp', 'boiled shrimp', 'cooked shrimp', 'peeled shrimp', 'grilled shrimp'], '83 cal per 12 medium shrimp (~84g). Ultra-lean protein.', NULL, 'proteins', 12),

-- Crab Meat (cooked, blue crab): USDA #15137 — 97 cal, 19.4g protein, 0g carbs, 1.5g fat per 100g
('crab_meat', 'Crab Meat (Blue Crab, Cooked)', 97.0, 19.4, 0.0, 1.5, 0.0, 0.0, NULL, 85, 'usda', ARRAY['lump crab meat', 'blue crab', 'crab meat cooked', 'jumbo lump crab'], '82 cal per 3oz serving (~85g). Delicate, sweet flavor.', NULL, 'proteins', 1),

-- Lobster (cooked, steamed): USDA #15146 — 98 cal, 20.5g protein, 0.5g carbs, 0.6g fat per 100g
('lobster_cooked', 'Lobster (Steamed)', 98.0, 20.5, 0.5, 0.6, 0.0, 0.0, NULL, 145, 'usda', ARRAY['steamed lobster', 'lobster tail', 'boiled lobster', 'lobster meat'], '142 cal per 5oz serving (~145g). Lean luxury protein.', NULL, 'proteins', 1),

-- Scallops (cooked, steamed): USDA #15172 — 111 cal, 20.5g protein, 3.2g carbs, 1.0g fat per 100g
('scallops_cooked', 'Scallops (Cooked)', 111.0, 20.5, 3.2, 1.0, 0.0, 0.0, 15, 90, 'usda', ARRAY['sea scallops', 'pan seared scallops', 'seared scallops', 'bay scallops'], '100 cal per 6 scallops (~90g). Sweet, delicate shellfish.', NULL, 'proteins', 6),

-- Mussels (cooked, steamed): USDA #15165 — 172 cal, 23.8g protein, 7.4g carbs, 4.5g fat per 100g
('mussels_cooked', 'Mussels (Steamed)', 172.0, 23.8, 7.4, 4.5, 0.0, 0.0, 10, 150, 'usda', ARRAY['steamed mussels', 'blue mussels', 'mussels in broth'], '258 cal per 15 mussels (~150g cooked meat). High in B12 and iron.', NULL, 'proteins', 15),

-- Clams (cooked, steamed): USDA #15159 — 148 cal, 25.6g protein, 5.1g carbs, 2.0g fat per 100g
('clams_cooked', 'Clams (Steamed)', 148.0, 25.6, 5.1, 2.0, 0.0, 0.0, 10, 90, 'usda', ARRAY['steamed clams', 'littleneck clams', 'manila clams', 'clam meat'], '133 cal per 9 clams (~90g cooked meat). Excellent iron source.', NULL, 'proteins', 9),

-- Calamari (fried): ~175 cal, 18.0g protein, 7.8g carbs, 7.5g fat per 100g
('calamari_fried', 'Calamari (Fried)', 175.0, 18.0, 7.8, 7.5, 0.3, 0.0, NULL, 113, 'usda', ARRAY['fried calamari', 'fried squid', 'calamari rings', 'crispy calamari'], '198 cal per 4oz serving (~113g). Breaded and deep-fried squid rings.', NULL, 'proteins', 1),

-- Crawfish (cooked, boiled): USDA #15143 — 82 cal, 16.8g protein, 0g carbs, 1.2g fat per 100g
('crawfish_cooked', 'Crawfish (Boiled, Peeled)', 82.0, 16.8, 0.0, 1.2, 0.0, 0.0, NULL, 85, 'usda', ARRAY['boiled crawfish', 'crayfish', 'crawdads', 'mudbugs', 'crawfish tail meat'], '70 cal per 3oz serving (~85g). Southern boil staple.', NULL, 'proteins', 1),

-- ============================================================================
-- EGGS (~6 items)
-- ============================================================================

-- Whole Egg Large (raw): USDA #01123 — 143 cal, 12.6g protein, 0.7g carbs, 9.5g fat per 100g
('whole_egg_large', 'Egg (Whole, Large)', 143.0, 12.6, 0.7, 9.5, 0.0, 0.4, 50, 50, 'usda', ARRAY['large egg', 'whole egg', 'chicken egg', 'raw egg', 'one egg'], '72 cal per large egg (~50g). Complete protein with all essential amino acids.', NULL, 'proteins', 1),

-- Egg White (raw): USDA #01124 — 52 cal, 10.9g protein, 0.7g carbs, 0.2g fat per 100g
('egg_white', 'Egg White (Large)', 52.0, 10.9, 0.7, 0.2, 0.0, 0.7, 33, 99, 'usda', ARRAY['egg whites', 'liquid egg whites', 'egg white only', 'whites only'], '17 cal per egg white (~33g). Pure protein, zero fat. Three whites per serving.', NULL, 'proteins', 3),

-- Hard Boiled Egg: USDA #01129 — 155 cal, 12.6g protein, 1.1g carbs, 10.6g fat per 100g
('hard_boiled_egg', 'Egg (Hard Boiled)', 155.0, 12.6, 1.1, 10.6, 0.0, 1.1, 50, 100, 'usda', ARRAY['hard boiled egg', 'boiled egg', 'hard cooked egg', 'hardboiled egg'], '78 cal per egg (~50g). Easy meal-prep protein. Two eggs per serving.', NULL, 'proteins', 2),

-- Scrambled Eggs (with butter): USDA #01132 — 149 cal, 9.9g protein, 1.6g carbs, 11.2g fat per 100g
('scrambled_eggs', 'Scrambled Eggs (with Butter)', 149.0, 9.9, 1.6, 11.2, 0.0, 1.4, NULL, 122, 'usda', ARRAY['scrambled eggs', 'eggs scrambled', 'buttery scrambled eggs', 'fluffy scrambled eggs'], '182 cal per 2-egg serving (~122g). Made with butter and milk.', NULL, 'proteins', 1),

-- Poached Egg: USDA #01131 — 143 cal, 12.6g protein, 0.7g carbs, 9.5g fat per 100g
('poached_egg', 'Egg (Poached)', 143.0, 12.6, 0.7, 9.5, 0.0, 0.4, 50, 50, 'usda', ARRAY['poached egg', 'eggs poached', 'water cooked egg'], '72 cal per egg (~50g). No added fat cooking method.', NULL, 'proteins', 1),

-- Fried Egg (in butter): USDA #01128 — 196 cal, 13.6g protein, 0.8g carbs, 15.3g fat per 100g
('fried_egg', 'Egg (Fried in Butter)', 196.0, 13.6, 0.8, 15.3, 0.0, 0.4, 46, 46, 'usda', ARRAY['fried egg', 'sunny side up', 'over easy egg', 'over medium egg', 'eggs fried'], '90 cal per fried egg (~46g). Higher calorie due to butter.', NULL, 'proteins', 1),

-- ============================================================================
-- PLANT PROTEIN (~10 items)
-- ============================================================================

-- Tofu Firm (raw): USDA #16427 — 144 cal, 15.6g protein, 2.3g carbs, 8.7g fat per 100g
('tofu_firm', 'Tofu (Firm)', 144.0, 15.6, 2.3, 8.7, 1.2, 0.7, NULL, 126, 'usda', ARRAY['firm tofu', 'extra firm tofu', 'pressed tofu', 'bean curd firm'], '181 cal per 1/4 block (~126g). Versatile plant protein, absorbs flavors.', NULL, 'proteins', 1),

-- Tofu Silken (soft): USDA #16429 — 55 cal, 4.8g protein, 2.0g carbs, 2.7g fat per 100g
('tofu_silken', 'Tofu (Silken, Soft)', 55.0, 4.8, 2.0, 2.7, 0.1, 1.3, NULL, 126, 'usda', ARRAY['silken tofu', 'soft tofu', 'japanese tofu', 'mori-nu tofu'], '69 cal per 1/4 block (~126g). Smooth texture for soups, smoothies, desserts.', NULL, 'proteins', 1),

-- Tempeh (cooked): USDA #16114 — 195 cal, 20.3g protein, 7.6g carbs, 11.4g fat per 100g
('tempeh', 'Tempeh (Cooked)', 195.0, 20.3, 7.6, 11.4, 0.0, 0.0, NULL, 84, 'usda', ARRAY['cooked tempeh', 'soy tempeh', 'fermented soybean tempeh', 'tempeh slices'], '164 cal per 3oz serving (~84g). Fermented soy, high protein and fiber.', NULL, 'proteins', 1),

-- Seitan (wheat gluten): ~130 cal, 25.0g protein, 3.5g carbs, 0.5g fat per 100g
('seitan', 'Seitan (Wheat Gluten)', 130.0, 25.0, 3.5, 0.5, 0.3, 0.3, NULL, 85, 'usda', ARRAY['wheat gluten', 'wheat meat', 'vital wheat gluten', 'mock duck'], '111 cal per 3oz serving (~85g). Very high protein plant food.', NULL, 'proteins', 1),

-- Edamame (shelled, cooked): USDA #11212 — 121 cal, 12.0g protein, 8.9g carbs, 5.2g fat per 100g
('edamame_shelled', 'Edamame (Shelled, Cooked)', 121.0, 12.0, 8.9, 5.2, 5.2, 2.2, NULL, 78, 'usda', ARRAY['shelled edamame', 'soybeans', 'cooked edamame', 'mukimame', 'soy beans'], '94 cal per 1/2 cup (~78g). Whole soy bean, complete protein.', NULL, 'proteins', 1),

-- Beyond Burger Patty: ~230 cal, 20.0g protein, 5.0g carbs, 14.0g fat per 100g (113g patty)
('beyond_burger_patty', 'Beyond Burger Patty', 230.0, 20.0, 5.0, 14.0, 3.0, 0.0, 113, 113, 'usda', ARRAY['beyond meat burger', 'beyond beef patty', 'beyond meat patty', 'plant based burger beyond'], '260 cal per patty (~113g). Pea protein-based plant burger.', NULL, 'proteins', 1),

-- Impossible Burger Patty: ~240 cal, 19.0g protein, 9.0g carbs, 14.0g fat per 100g (113g patty)
('impossible_burger_patty', 'Impossible Burger Patty', 240.0, 19.0, 9.0, 14.0, 3.0, 0.0, 113, 113, 'usda', ARRAY['impossible meat burger', 'impossible beef patty', 'impossible patty', 'plant based burger impossible'], '271 cal per patty (~113g). Soy and potato protein-based.', NULL, 'proteins', 1),

-- Black Bean Burger Patty: ~150 cal, 9.5g protein, 17.0g carbs, 5.0g fat per 100g
('black_bean_burger_patty', 'Black Bean Burger Patty', 150.0, 9.5, 17.0, 5.0, 4.0, 1.5, 71, 71, 'usda', ARRAY['veggie burger', 'bean burger patty', 'black bean patty', 'vegetable burger'], '107 cal per patty (~71g). Lower protein, higher carb than meat.', NULL, 'proteins', 1),

-- TVP (Textured Vegetable Protein, rehydrated): ~62 cal, 10.5g protein, 4.2g carbs, 0.2g fat per 100g rehydrated
('tvp_rehydrated', 'TVP (Textured Vegetable Protein, Rehydrated)', 62.0, 10.5, 4.2, 0.2, 3.6, 2.0, NULL, 120, 'usda', ARRAY['textured vegetable protein', 'soy crumbles', 'tvp', 'textured soy protein', 'soy meat'], '74 cal per 1/2 cup rehydrated (~120g). Defatted soy flour, very high protein.', NULL, 'proteins', 1),

-- Jackfruit (canned, in brine, drained): ~35 cal, 0.6g protein, 8.0g carbs, 0.2g fat per 100g
('jackfruit_canned', 'Jackfruit (Canned, Young, Drained)', 35.0, 0.6, 8.0, 0.2, 1.5, 3.0, NULL, 150, 'usda', ARRAY['canned jackfruit', 'young jackfruit', 'pulled jackfruit', 'jackfruit meat substitute'], '53 cal per 150g serving. Meat-like texture but very low protein; use as texture sub.', NULL, 'proteins', 1),

-- ============================================================================
-- DELI / PROCESSED MEATS (~12 items)
-- ============================================================================

-- Turkey Breast Deli (oven-roasted): USDA #07249 — 104 cal, 18g protein, 2g carbs, 2g fat per 100g
('turkey_breast_deli', 'Turkey Breast (Deli, Oven-Roasted)', 104.0, 18.0, 2.0, 2.0, 0.0, 1.5, NULL, 56, 'usda', ARRAY['oven roasted turkey deli', 'deli turkey breast slices', 'boars head turkey'], '58 cal per 2oz serving (~56g). Lean lunch meat option.', NULL, 'proteins', 1),

-- Ham Deli (regular): USDA #07028 — 120 cal, 17.0g protein, 2.5g carbs, 4.5g fat per 100g
('ham_deli_regular', 'Ham (Deli Sliced, Regular)', 120.0, 17.0, 2.5, 4.5, 0.0, 2.0, NULL, 56, 'usda', ARRAY['deli ham regular', 'sliced ham lunch meat', 'virginia ham deli', 'honey ham slices'], '67 cal per 2oz serving (~56g). Classic sandwich meat.', NULL, 'proteins', 1),

-- Roast Beef Deli: USDA #07068 — 126 cal, 19.9g protein, 1.2g carbs, 4.3g fat per 100g
('roast_beef_deli', 'Roast Beef (Deli Sliced)', 126.0, 19.9, 1.2, 4.3, 0.0, 0.0, NULL, 56, 'usda', ARRAY['deli roast beef', 'sliced roast beef', 'rare roast beef deli', 'boars head roast beef'], '71 cal per 2oz serving (~56g). Lean, flavorful deli meat.', NULL, 'proteins', 1),

-- Salami (Genoa): USDA #07063 — 378 cal, 22.6g protein, 2.4g carbs, 30.7g fat per 100g
('salami_genoa', 'Salami (Genoa)', 378.0, 22.6, 2.4, 30.7, 0.0, 0.8, NULL, 28, 'usda', ARRAY['genoa salami', 'salami slices', 'italian salami', 'hard salami'], '106 cal per 1oz serving (~28g). Cured Italian sausage, high fat.', NULL, 'proteins', 1),

-- Pepperoni (sliced): USDA #07057 — 504 cal, 22.5g protein, 2.0g carbs, 44.8g fat per 100g
('pepperoni', 'Pepperoni (Sliced)', 504.0, 22.5, 2.0, 44.8, 0.0, 1.0, 2, 28, 'usda', ARRAY['pepperoni slices', 'pizza pepperoni', 'hormel pepperoni', 'sliced pepperoni'], '141 cal per 1oz (~28g, ~14 slices). Classic pizza topping.', NULL, 'proteins', 14),

-- Prosciutto (dry-cured): USDA #07028 — 250 cal, 26.0g protein, 0.5g carbs, 16.0g fat per 100g
('prosciutto', 'Prosciutto (Dry-Cured)', 250.0, 26.0, 0.5, 16.0, 0.0, 0.0, NULL, 28, 'usda', ARRAY['prosciutto di parma', 'prosciutto crudo', 'italian prosciutto', 'dry cured ham'], '70 cal per 1oz serving (~28g). Thin-sliced Italian cured ham.', NULL, 'proteins', 1),

-- Hot Dog (beef): USDA #07023 — 290 cal, 10.3g protein, 2.1g carbs, 26.1g fat per 100g
('hot_dog_beef', 'Hot Dog (Beef)', 290.0, 10.3, 2.1, 26.1, 0.0, 1.3, 52, 52, 'usda', ARRAY['beef hot dog', 'beef frank', 'beef frankfurter', 'all beef hot dog'], '151 cal per frank (~52g). All-beef frank, no bun.', NULL, 'proteins', 1),

-- Beef Jerky: USDA #07955 — 410 cal, 33.2g protein, 11.0g carbs, 25.6g fat per 100g
('beef_jerky', 'Beef Jerky', 410.0, 33.2, 11.0, 25.6, 0.5, 9.0, NULL, 28, 'usda', ARRAY['jerky', 'dried beef jerky', 'jack links jerky', 'beef jerky snack'], '115 cal per 1oz serving (~28g). High-protein portable snack.', NULL, 'proteins', 1),

-- Chicken Sausage (cooked): ~150 cal, 17.5g protein, 2.5g carbs, 7.5g fat per 100g
('chicken_sausage', 'Chicken Sausage (Cooked)', 150.0, 17.5, 2.5, 7.5, 0.0, 1.5, 68, 68, 'usda', ARRAY['cooked chicken sausage', 'aidells chicken sausage', 'al fresco chicken sausage', 'apple chicken sausage'], '102 cal per link (~68g). Lean sausage alternative.', NULL, 'proteins', 1),

-- Kielbasa (cooked): USDA #07059 — 325 cal, 14.0g protein, 3.0g carbs, 28.7g fat per 100g
('kielbasa', 'Kielbasa (Polish Sausage, Cooked)', 325.0, 14.0, 3.0, 28.7, 0.0, 2.0, NULL, 56, 'usda', ARRAY['polish sausage', 'polska kielbasa', 'smoked kielbasa', 'hillshire kielbasa'], '182 cal per 2oz serving (~56g). Smoked Polish sausage.', NULL, 'proteins', 1),

-- Spam (classic): USDA #07071 — 315 cal, 13.0g protein, 2.5g carbs, 27.5g fat per 100g
('spam', 'Spam (Classic)', 315.0, 13.0, 2.5, 27.5, 0.0, 1.0, NULL, 56, 'usda', ARRAY['spam classic', 'canned spam', 'hormel spam', 'spam luncheon meat'], '176 cal per 2oz serving (~56g). Canned pork luncheon meat.', NULL, 'proteins', 1),

-- Corned Beef Hash (canned): ~164 cal, 8.0g protein, 10.0g carbs, 10.0g fat per 100g
('corned_beef_hash', 'Corned Beef Hash (Canned)', 164.0, 8.0, 10.0, 10.0, 0.8, 0.5, NULL, 236, 'usda', ARRAY['canned corned beef hash', 'hormel corned beef hash', 'marys corned beef hash'], '387 cal per cup (~236g). Corned beef with diced potatoes.', NULL, 'proteins', 1),

-- Bologna (beef): USDA #07007 — 310 cal, 11.0g protein, 3.0g carbs, 28.0g fat per 100g
('bologna_beef', 'Bologna (Beef)', 310.0, 11.0, 3.0, 28.0, 0.0, 2.5, 28, 56, 'usda', ARRAY['beef bologna', 'bologna slices', 'oscar mayer bologna', 'lunch meat bologna'], '174 cal per 2 slices (~56g). Classic processed deli meat.', NULL, 'proteins', 2),

-- Liverwurst (pork): ~327 cal, 14.5g protein, 2.5g carbs, 28.5g fat per 100g
('liverwurst', 'Liverwurst (Braunschweiger)', 327.0, 14.5, 2.5, 28.5, 0.0, 0.0, NULL, 56, 'usda', ARRAY['braunschweiger', 'liver sausage', 'pork liverwurst', 'liver pate'], '183 cal per 2oz serving (~56g). Pork liver sausage, high in B12 and iron.', NULL, 'proteins', 1),

-- Bison (ground, cooked): USDA #17158 — 179 cal, 25.5g protein, 0g carbs, 8.0g fat per 100g
('bison_ground', 'Bison (Ground, Cooked)', 179.0, 25.5, 0.0, 8.0, 0.0, 0.0, NULL, 112, 'usda', ARRAY['ground bison', 'buffalo meat ground', 'bison burger', 'ground buffalo'], '200 cal per 4oz cooked (~112g). Leaner than beef, slightly gamey flavor.', NULL, 'proteins', 1),

-- Lamb Chop (loin, grilled, trimmed): ~217 cal, 26g protein, 0g carbs, 12g fat per 100g
('lamb_chop', 'Lamb Chop (Loin, Grilled, Trimmed)', 217.0, 26.0, 0.0, 12.0, 0.0, 0.0, 85, 170, 'usda', ARRAY['grilled lamb chop', 'lamb loin chop', 'lamb chops', 'lamb cutlet'], '184 cal per chop (~85g). Two chops per serving.', NULL, 'proteins', 2),
