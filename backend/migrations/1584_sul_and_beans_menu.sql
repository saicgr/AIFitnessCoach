-- 1584_sul_and_beans_menu.sql
-- Sul & Beans — Korean bingsoo (shaved ice) dessert cafe.
-- Locations: Los Angeles, Cupertino, Irvine, Las Vegas, Frisco, and more.
-- Sources: sulandbeans.com/menu, snapcalorie.com, nutribit.app, nutritionix.com,
-- koreatimes.co.kr (bingsu calorie study), fatsecret.com, mykoreankitchen.com,
-- mynetdiary.com, eatthismuch.com, kimchimari.com, honestfoodtalks.com.
-- All values per 100g. default_serving_g = full item weight.
-- Bingsoo weights estimated at 400-500g per bowl (standard Korean cafe serving).
-- Toast weights estimated at 180-220g per piece (Korean thick toast style).
-- Drink weights based on 16oz (480ml) or 12oz (360ml) standard cafe servings.

INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_serving_g, default_weight_per_piece_g,
  source, variant_names,
  food_category, restaurant_name, default_count, notes, is_active
) VALUES

-- ══════════════════════════════════════════
-- SUL & BEANS — BINGSOO (Korean Shaved Ice)
-- ══════════════════════════════════════════

-- Injeolmi Bingsoo Combo: ~680 cal, 12P, 98C, 28F (480g) — includes rice cakes, soybean powder, condensed milk, injeolmi ice cream
-- Combo is larger than regular injeolmi bingsoo and includes extra toppings
('sul_and_beans_injeolmi_bingsoo_combo', 'Sul & Beans Injeolmi Bingsoo Combo', 142, 2.5, 20.4, 5.8,
 0.5, 14.0, 480, NULL,
 'estimated', ARRAY['sul and beans injeolmi combo', 'injeolmi bingsoo combo', 'sul beans injeolmi combo', 'sul & beans injeolmi bingsoo combo', 'korean rice cake bingsoo combo'],
 'dessert', 'Sul & Beans', 1, '680 cal. Signature combo with shaved milk ice topped with injeolmi rice cakes, soybean powder, condensed milk, and ice cream. $17.95. Shared dessert for 2-3 people.', TRUE),

-- Milk Bingsoo: ~350 cal, 8P, 52C, 12F (420g) — plain shaved milk ice with condensed milk and mochi
('sul_and_beans_milk_bingsoo', 'Sul & Beans Milk Bingsoo', 83, 1.9, 12.4, 2.9,
 0.3, 10.0, 420, NULL,
 'estimated', ARRAY['sul and beans milk bingsoo', 'milk bingsoo', 'sul beans milk bingsu', 'plain bingsoo', 'korean milk shaved ice', 'milk bingsu'],
 'dessert', 'Sul & Beans', 1, '350 cal. Classic shaved milk ice with condensed milk and mochi rice cakes. $12.50. The simplest bingsoo option.', TRUE),

-- Injeolmi Bingsoo: ~520 cal, 10P, 78C, 18F (450g) — shaved milk ice with injeolmi, soybean powder, condensed milk
('sul_and_beans_injeolmi_bingsoo', 'Sul & Beans Injeolmi Bingsoo', 116, 2.2, 17.3, 4.0,
 0.5, 12.0, 450, NULL,
 'estimated', ARRAY['sul and beans injeolmi bingsoo', 'injeolmi bingsoo', 'sul beans injeolmi bingsu', 'korean rice cake shaved ice', 'injeolmi bingsu', 'soybean powder bingsoo'],
 'dessert', 'Sul & Beans', 1, '520 cal. Shaved milk ice topped with chewy injeolmi rice cakes, roasted soybean powder, and condensed milk. $12.50.', TRUE),

-- Black Sesame Bingsoo: ~480 cal, 10P, 68C, 20F (430g) — black sesame powder, rice cakes, condensed milk
('sul_and_beans_black_sesame_bingsoo', 'Sul & Beans Black Sesame Bingsoo', 112, 2.3, 15.8, 4.7,
 0.6, 11.0, 430, NULL,
 'estimated', ARRAY['sul and beans black sesame bingsoo', 'black sesame bingsoo', 'sul beans black sesame bingsu', 'heuk imja bingsoo', 'black sesame shaved ice', 'black sesame bingsu'],
 'dessert', 'Sul & Beans', 1, '480 cal. Shaved milk ice with nutty black sesame powder, rice cakes, and condensed milk. $13.95. Rich in calcium from sesame.', TRUE),

-- Green Tea Bingsoo: ~460 cal, 9P, 70C, 16F (430g) — matcha powder, red bean, mochi, condensed milk
('sul_and_beans_green_tea_bingsoo', 'Sul & Beans Green Tea Bingsoo', 107, 2.1, 16.3, 3.7,
 0.5, 12.5, 430, NULL,
 'estimated', ARRAY['sul and beans green tea bingsoo', 'green tea bingsoo', 'sul beans matcha bingsu', 'matcha bingsoo', 'green tea bingsu', 'sul & beans green tea bingsoo', 'nokcha bingsoo'],
 'dessert', 'Sul & Beans', 1, '460 cal. Shaved milk ice infused with premium matcha green tea, topped with red bean, mochi, and condensed milk. $13.95.', TRUE),

-- Coffee Bingsoo: ~440 cal, 8P, 66C, 16F (430g) — espresso, condensed milk, mochi
('sul_and_beans_coffee_bingsoo', 'Sul & Beans Coffee Bingsoo', 102, 1.9, 15.3, 3.7,
 0.3, 12.0, 430, NULL,
 'estimated', ARRAY['sul and beans coffee bingsoo', 'coffee bingsoo', 'sul beans coffee bingsu', 'espresso bingsoo', 'coffee bingsu', 'sul & beans coffee bingsoo'],
 'dessert', 'Sul & Beans', 1, '440 cal. Shaved milk ice with bold espresso, condensed milk, and mochi rice cakes. $13.95.', TRUE),

-- Earl Grey Bingsoo: ~450 cal, 8P, 68C, 16F (430g) — earl grey tea, graham cracker, cream, berries
('sul_and_beans_earl_grey_bingsoo', 'Sul & Beans Earl Grey Bingsoo', 105, 1.9, 15.8, 3.7,
 0.4, 12.0, 430, NULL,
 'estimated', ARRAY['sul and beans earl grey bingsoo', 'earl grey bingsoo', 'sul beans earl grey bingsu', 'earl grey tea bingsoo', 'earl grey bingsu', 'sul & beans earl grey bingsoo'],
 'dessert', 'Sul & Beans', 1, '450 cal. Shaved milk ice infused with earl grey tea, topped with graham cracker crumbs, sea salt cream, and fresh berries. $13.95.', TRUE),

-- Fresh Strawberry Bingsoo: ~420 cal, 7P, 72C, 12F (450g) — fresh strawberries, condensed milk, mochi
('sul_and_beans_fresh_strawberry_bingsoo', 'Sul & Beans Fresh Strawberry Bingsoo', 93, 1.6, 16.0, 2.7,
 1.0, 13.0, 450, NULL,
 'estimated', ARRAY['sul and beans strawberry bingsoo', 'fresh strawberry bingsoo', 'sul beans strawberry bingsu', 'strawberry bingsoo', 'strawberry bingsu', 'sul & beans fresh strawberry bingsoo', 'ttalgi bingsoo'],
 'dessert', 'Sul & Beans', 1, '420 cal. Shaved milk ice piled high with fresh strawberries, condensed milk, and mochi. $13.95. Seasonal availability.', TRUE),

-- Fresh Mango Bingsoo: ~480 cal, 7P, 82C, 14F (460g) — fresh mango, condensed milk, mochi
('sul_and_beans_fresh_mango_bingsoo', 'Sul & Beans Fresh Mango Bingsoo', 104, 1.5, 17.8, 3.0,
 1.0, 15.0, 460, NULL,
 'estimated', ARRAY['sul and beans mango bingsoo', 'fresh mango bingsoo', 'sul beans mango bingsu', 'mango bingsoo', 'mango bingsu', 'sul & beans fresh mango bingsoo', 'manggo bingsoo'],
 'dessert', 'Sul & Beans', 1, '480 cal. Shaved milk ice loaded with fresh mango chunks, condensed milk, and mochi. $14.95. Seasonal availability.', TRUE),

-- Strawberry Cheese Bingsoo: ~540 cal, 10P, 76C, 22F (460g) — strawberries, cream cheese, condensed milk
('sul_and_beans_strawberry_cheese_bingsoo', 'Sul & Beans Strawberry Cheese Bingsoo', 117, 2.2, 16.5, 4.8,
 0.8, 14.0, 460, NULL,
 'estimated', ARRAY['sul and beans strawberry cheese bingsoo', 'strawberry cheese bingsoo', 'sul beans strawberry cheese bingsu', 'cheese strawberry bingsoo', 'strawberry cheesecake bingsoo', 'strawberry cheese bingsu'],
 'dessert', 'Sul & Beans', 1, '540 cal. Shaved milk ice with fresh strawberries, cream cheese topping, and condensed milk. $14.95. Rich and indulgent.', TRUE),

-- Yogurt Berry Bingsoo: ~430 cal, 9P, 72C, 12F (450g) — mixed berries, yogurt, condensed milk
('sul_and_beans_yogurt_berry_bingsoo', 'Sul & Beans Yogurt Berry Bingsoo', 96, 2.0, 16.0, 2.7,
 1.2, 13.0, 450, NULL,
 'estimated', ARRAY['sul and beans yogurt berry bingsoo', 'yogurt berry bingsoo', 'sul beans yogurt berry bingsu', 'berry yogurt bingsoo', 'yogurt bingsoo', 'yogurt berry bingsu'],
 'dessert', 'Sul & Beans', 1, '430 cal. Shaved milk ice with tangy yogurt, mixed berries (strawberry, blueberry, raspberry), and condensed milk. $14.95.', TRUE),

-- Green Grape Bingsoo: ~400 cal, 7P, 68C, 10F (440g) — fresh green grapes, condensed milk, mochi
('sul_and_beans_green_grape_bingsoo', 'Sul & Beans Green Grape Bingsoo', 91, 1.6, 15.5, 2.3,
 0.8, 13.0, 440, NULL,
 'estimated', ARRAY['sul and beans green grape bingsoo', 'green grape bingsoo', 'sul beans green grape bingsu', 'grape bingsoo', 'green grape bingsu', 'sul & beans green grape bingsoo', 'cheongnopo bingsoo'],
 'dessert', 'Sul & Beans', 1, '400 cal. Shaved milk ice topped with fresh green grapes, condensed milk, and mochi. $13.95. Light and refreshing.', TRUE),

-- Watermelon Bingsoo: ~380 cal, 6P, 66C, 10F (460g) — fresh watermelon, condensed milk
('sul_and_beans_watermelon_bingsoo', 'Sul & Beans Watermelon Bingsoo', 83, 1.3, 14.3, 2.2,
 0.6, 12.0, 460, NULL,
 'estimated', ARRAY['sul and beans watermelon bingsoo', 'watermelon bingsoo', 'sul beans watermelon bingsu', 'subak bingsoo', 'watermelon bingsu', 'sul & beans watermelon bingsoo', 'watermelon shaved ice'],
 'dessert', 'Sul & Beans', 1, '380 cal. Shaved milk ice with fresh watermelon chunks and condensed milk. $13.95. Seasonal summer item.', TRUE),

-- Oreo Bingsoo: ~560 cal, 9P, 80C, 24F (440g) — crushed Oreos, chocolate, condensed milk, ice cream
('sul_and_beans_oreo_bingsoo', 'Sul & Beans Oreo Bingsoo', 127, 2.0, 18.2, 5.5,
 0.5, 14.0, 440, NULL,
 'estimated', ARRAY['sul and beans oreo bingsoo', 'oreo bingsoo', 'sul beans oreo bingsu', 'cookies and cream bingsoo', 'oreo bingsu', 'sul & beans oreo bingsoo', 'oreo shaved ice'],
 'dessert', 'Sul & Beans', 1, '560 cal. Shaved milk ice loaded with crushed Oreo cookies, chocolate drizzle, condensed milk, and ice cream. $13.95.', TRUE),

-- Chocolate Bingsoo: ~540 cal, 9P, 78C, 22F (430g) — chocolate, cocoa, condensed milk, ice cream
('sul_and_beans_chocolate_bingsoo', 'Sul & Beans Chocolate Bingsoo', 126, 2.1, 18.1, 5.1,
 0.6, 14.5, 430, NULL,
 'estimated', ARRAY['sul and beans chocolate bingsoo', 'chocolate bingsoo', 'sul beans chocolate bingsu', 'choco bingsoo', 'chocolate bingsu', 'sul & beans chocolate bingsoo', 'chocolate shaved ice'],
 'dessert', 'Sul & Beans', 1, '540 cal. Rich shaved milk ice with chocolate sauce, cocoa powder, condensed milk, and chocolate ice cream. $13.95.', TRUE),

-- Chocolate Banana Bingsoo: ~580 cal, 9P, 86C, 22F (460g) — chocolate, banana, condensed milk, ice cream
('sul_and_beans_chocolate_banana_bingsoo', 'Sul & Beans Chocolate Banana Bingsoo', 126, 2.0, 18.7, 4.8,
 1.0, 15.0, 460, NULL,
 'estimated', ARRAY['sul and beans chocolate banana bingsoo', 'chocolate banana bingsoo', 'sul beans chocolate banana bingsu', 'choco banana bingsoo', 'chocolate banana bingsu', 'banana chocolate bingsoo'],
 'dessert', 'Sul & Beans', 1, '580 cal. Shaved milk ice with chocolate sauce, fresh banana slices, condensed milk, and ice cream. $14.50.', TRUE),

-- Sweet Corn Bingsoo: ~420 cal, 8P, 70C, 12F (430g) — sweet corn, condensed milk, cheese
('sul_and_beans_sweet_corn_bingsoo', 'Sul & Beans Sweet Corn Bingsoo', 98, 1.9, 16.3, 2.8,
 0.8, 11.0, 430, NULL,
 'estimated', ARRAY['sul and beans sweet corn bingsoo', 'sweet corn bingsoo', 'sul beans sweet corn bingsu', 'corn bingsoo', 'sweet corn bingsu', 'sul & beans sweet corn bingsoo', 'oksusu bingsoo'],
 'dessert', 'Sul & Beans', 1, '420 cal. Shaved milk ice topped with sweet corn kernels, condensed milk, and cheese. $13.95. Sweet and savory combination.', TRUE),

-- Banana Milk Bingsoo: ~470 cal, 8P, 76C, 14F (450g) — banana, milk ice, condensed milk, mochi
('sul_and_beans_banana_milk_bingsoo', 'Sul & Beans Banana Milk Bingsoo', 104, 1.8, 16.9, 3.1,
 0.8, 13.5, 450, NULL,
 'estimated', ARRAY['sul and beans banana milk bingsoo', 'banana milk bingsoo', 'sul beans banana milk bingsu', 'banana bingsoo', 'banana milk bingsu', 'sul & beans banana milk bingsoo', 'banana uyu bingsoo'],
 'dessert', 'Sul & Beans', 1, '470 cal. Shaved milk ice with fresh banana, banana milk flavor, condensed milk, and mochi. $14.50. Inspired by Korean banana milk.', TRUE),

-- Taro Bingsoo: ~490 cal, 8P, 78C, 16F (440g) — taro powder/paste, condensed milk, mochi
('sul_and_beans_taro_bingsoo', 'Sul & Beans Taro Bingsoo', 111, 1.8, 17.7, 3.6,
 0.6, 13.0, 440, NULL,
 'estimated', ARRAY['sul and beans taro bingsoo', 'taro bingsoo', 'sul beans taro bingsu', 'taro bingsu', 'sul & beans taro bingsoo', 'taro shaved ice', 'ube bingsoo'],
 'dessert', 'Sul & Beans', 1, '490 cal. Shaved milk ice with creamy taro (purple yam) topping, condensed milk, and mochi. $13.95. Distinctive purple color.', TRUE),

-- ══════════════════════════════════════════
-- SUL & BEANS — TOAST (Korean Thick Toast)
-- ══════════════════════════════════════════

-- Injeolmi Toast: ~380 cal, 8P, 54C, 14F (200g) — thick toast with injeolmi rice cake, soybean powder, honey
('sul_and_beans_injeolmi_toast', 'Sul & Beans Injeolmi Toast', 190, 4.0, 27.0, 7.0,
 0.8, 10.0, 200, 200,
 'estimated', ARRAY['sul and beans injeolmi toast', 'injeolmi toast', 'sul beans injeolmi toast', 'korean rice cake toast', 'sul & beans injeolmi toast', 'injeolmi bread'],
 'bread', 'Sul & Beans', 1, '380 cal. Thick Korean-style toast with chewy injeolmi rice cake pieces, roasted soybean powder, and honey drizzle. $7.95.', TRUE),

-- Cheese Injeolmi Toast: ~440 cal, 12P, 52C, 20F (210g) — injeolmi toast + melted cheese
('sul_and_beans_cheese_injeolmi_toast', 'Sul & Beans Cheese Injeolmi Toast', 210, 5.7, 24.8, 9.5,
 0.6, 8.0, 210, 210,
 'estimated', ARRAY['sul and beans cheese injeolmi toast', 'cheese injeolmi toast', 'sul beans cheese injeolmi toast', 'korean cheese rice cake toast', 'sul & beans cheese injeolmi toast'],
 'bread', 'Sul & Beans', 1, '440 cal. Thick Korean-style toast with injeolmi rice cake, roasted soybean powder, honey, and melted cheese. $7.95.', TRUE),

-- Sweet Corn Toast: ~400 cal, 10P, 56C, 16F (200g) — thick toast with sweet corn, mayo, cheese
('sul_and_beans_sweet_corn_toast', 'Sul & Beans Sweet Corn Toast', 200, 5.0, 28.0, 8.0,
 1.0, 6.0, 200, 200,
 'estimated', ARRAY['sul and beans sweet corn toast', 'sweet corn toast', 'sul beans corn toast', 'korean corn toast', 'sul & beans sweet corn toast', 'corn cheese toast'],
 'bread', 'Sul & Beans', 1, '400 cal. Thick Korean-style toast topped with sweet corn, creamy mayo, and melted cheese. $7.95. Sweet and savory.', TRUE),

-- Black Sesame Toast: ~410 cal, 10P, 52C, 18F (200g) — thick toast with black sesame spread
('sul_and_beans_black_sesame_toast', 'Sul & Beans Black Sesame Toast', 205, 5.0, 26.0, 9.0,
 1.0, 8.0, 200, 200,
 'estimated', ARRAY['sul and beans black sesame toast', 'black sesame toast', 'sul beans black sesame toast', 'korean black sesame toast', 'sul & beans black sesame toast', 'heuk imja toast'],
 'bread', 'Sul & Beans', 1, '410 cal. Thick Korean-style toast with rich black sesame spread and butter. $7.95. Nutty and aromatic.', TRUE),

-- Choux Cream Toast: ~420 cal, 8P, 56C, 18F (200g) — thick toast with choux cream filling
('sul_and_beans_choux_cream_toast', 'Sul & Beans Choux Cream Toast', 210, 4.0, 28.0, 9.0,
 0.4, 12.0, 200, 200,
 'estimated', ARRAY['sul and beans choux cream toast', 'choux cream toast', 'sul beans choux toast', 'korean cream toast', 'sul & beans choux cream toast', 'custard cream toast'],
 'bread', 'Sul & Beans', 1, '420 cal. Thick Korean-style toast filled with rich choux pastry cream. $7.95. Creamy and indulgent.', TRUE),

-- Sweet Potato Toast: ~390 cal, 8P, 58C, 14F (210g) — thick toast with sweet potato filling
('sul_and_beans_sweet_potato_toast', 'Sul & Beans Sweet Potato Toast', 186, 3.8, 27.6, 6.7,
 1.2, 10.0, 210, 210,
 'estimated', ARRAY['sul and beans sweet potato toast', 'sweet potato toast', 'sul beans sweet potato toast', 'korean sweet potato toast', 'sul & beans sweet potato toast', 'goguma toast'],
 'bread', 'Sul & Beans', 1, '390 cal. Thick Korean-style toast with sweet potato (goguma) filling and butter. $7.95. Naturally sweet.', TRUE),

-- Cinnamon Toast: ~370 cal, 7P, 52C, 14F (190g) — thick toast with cinnamon sugar and butter
('sul_and_beans_cinnamon_toast', 'Sul & Beans Cinnamon Toast', 195, 3.7, 27.4, 7.4,
 0.5, 12.0, 190, 190,
 'estimated', ARRAY['sul and beans cinnamon toast', 'cinnamon toast', 'sul beans cinnamon toast', 'korean cinnamon toast', 'sul & beans cinnamon toast', 'cinnamon sugar toast'],
 'bread', 'Sul & Beans', 1, '370 cal. Thick Korean-style toast with cinnamon sugar and butter. $7.95. Classic warm comfort dessert.', TRUE),

-- Green Tea Toast: ~380 cal, 8P, 54C, 14F (200g) — thick toast with matcha green tea spread
('sul_and_beans_green_tea_toast', 'Sul & Beans Green Tea Toast', 190, 4.0, 27.0, 7.0,
 0.6, 9.0, 200, 200,
 'estimated', ARRAY['sul and beans green tea toast', 'green tea toast', 'sul beans matcha toast', 'korean green tea toast', 'sul & beans green tea toast', 'matcha toast'],
 'bread', 'Sul & Beans', 1, '380 cal. Thick Korean-style toast with matcha green tea spread and cream. $7.95. Earthy and slightly sweet.', TRUE),

-- ══════════════════════════════════════════
-- SUL & BEANS — DRINKS
-- ══════════════════════════════════════════

-- Sweet Rice Punch (Sikhye): ~145 cal, 2P, 34C, 0F (360g/12oz) — traditional Korean fermented rice drink
('sul_and_beans_sweet_rice_punch', 'Sul & Beans Sweet Rice Punch (Sikhye)', 40, 0.6, 9.4, 0.0,
 0.3, 4.4, 360, NULL,
 'estimated', ARRAY['sul and beans sikhye', 'sweet rice punch', 'sul beans sweet rice punch', 'sikhye', 'sikhe', 'korean rice punch', 'sul & beans sikhye', 'korean sweet rice drink'],
 'beverage', 'Sul & Beans', 1, '145 cal. Traditional Korean sweet fermented rice punch served cold. $5.00. Naturally aids digestion.', TRUE),

-- Mixed Grain Drink: ~200 cal, 6P, 30C, 6F (360g/12oz) — misutgaru multigrain powder with milk
('sul_and_beans_mixed_grain_drink', 'Sul & Beans Mixed Grain Drink', 56, 1.7, 8.3, 1.7,
 0.8, 5.0, 360, NULL,
 'estimated', ARRAY['sul and beans mixed grain', 'mixed grain drink', 'sul beans mixed grain', 'misutgaru', 'misugaru latte', 'korean multigrain drink', 'sul & beans mixed grain drink', 'misutgaru latte'],
 'beverage', 'Sul & Beans', 1, '200 cal. Traditional Korean multigrain (misutgaru) drink blended with milk and sweetener. $5.75/$6.25. Nutritious and filling.', TRUE),

-- Matcha Latte: ~220 cal, 7P, 30C, 8F (480g/16oz) — matcha green tea with steamed milk
('sul_and_beans_matcha_latte', 'Sul & Beans Matcha Latte', 46, 1.5, 6.3, 1.7,
 0.2, 5.0, 480, NULL,
 'estimated', ARRAY['sul and beans matcha latte', 'matcha latte', 'sul beans matcha latte', 'green tea latte', 'sul & beans matcha latte', 'sul and beans green tea latte'],
 'beverage', 'Sul & Beans', 1, '220 cal. Matcha green tea powder with steamed milk. $5.00. Can be served hot or iced.', TRUE),

-- Sweet Potato Latte: ~250 cal, 6P, 38C, 8F (480g/16oz) — Korean goguma sweet potato with milk
('sul_and_beans_sweet_potato_latte', 'Sul & Beans Sweet Potato Latte', 52, 1.3, 7.9, 1.7,
 0.4, 5.8, 480, NULL,
 'estimated', ARRAY['sul and beans sweet potato latte', 'sweet potato latte', 'sul beans goguma latte', 'goguma latte', 'sul & beans sweet potato latte', 'korean sweet potato latte'],
 'beverage', 'Sul & Beans', 1, '250 cal. Korean-style latte made with sweet potato (goguma) puree and steamed milk. $6.00/$6.50. Naturally sweet and creamy.', TRUE),

-- Americano: ~10 cal, 0P, 0C, 0F (480g/16oz) — espresso with hot water
('sul_and_beans_americano', 'Sul & Beans Americano', 2, 0.1, 0.0, 0.0,
 0.0, 0.0, 480, NULL,
 'estimated', ARRAY['sul and beans americano', 'americano', 'sul beans americano', 'sul & beans americano', 'sul and beans coffee', 'black coffee sul beans'],
 'beverage', 'Sul & Beans', 1, '10 cal. Double-shot espresso with hot water. $4.50/$4.95. Can be served hot or iced.', TRUE),

-- Cappuccino: ~130 cal, 7P, 10C, 7F (360g/12oz) — espresso with steamed milk foam
('sul_and_beans_cappuccino', 'Sul & Beans Cappuccino', 36, 1.9, 2.8, 1.9,
 0.0, 2.5, 360, NULL,
 'estimated', ARRAY['sul and beans cappuccino', 'cappuccino', 'sul beans cappuccino', 'sul & beans cappuccino', 'sul and beans cappucino'],
 'beverage', 'Sul & Beans', 1, '130 cal. Double-shot espresso with equal parts steamed milk and milk foam. $5.75/$6.25. Classic Italian-style.', TRUE),

-- Cafe Latte: ~190 cal, 10P, 15C, 10F (480g/16oz) — espresso with steamed milk
('sul_and_beans_cafe_latte', 'Sul & Beans Cafe Latte', 40, 2.1, 3.1, 2.1,
 0.0, 3.0, 480, NULL,
 'estimated', ARRAY['sul and beans cafe latte', 'cafe latte', 'sul beans cafe latte', 'sul & beans cafe latte', 'sul and beans latte', 'caffe latte sul beans'],
 'beverage', 'Sul & Beans', 1, '190 cal. Double-shot espresso with steamed milk. $5.75/$6.25. Can be served hot or iced.', TRUE),

-- Cream Top Matcha: ~310 cal, 8P, 36C, 16F (480g/16oz) — matcha latte with cream cheese foam topping
('sul_and_beans_cream_top_matcha', 'Sul & Beans Cream Top Matcha', 65, 1.7, 7.5, 3.3,
 0.2, 5.5, 480, NULL,
 'estimated', ARRAY['sul and beans cream top matcha', 'cream top matcha', 'sul beans cream top matcha', 'matcha cream top', 'sul & beans cream top matcha', 'cream cheese matcha'],
 'beverage', 'Sul & Beans', 1, '310 cal. Matcha latte topped with rich whipped cream cheese foam. $5.75/$6.25. Creamy and indulgent.', TRUE),

-- Cream Top Matcha Strawberry: ~340 cal, 7P, 42C, 16F (480g/16oz) — matcha with strawberry and cream foam
('sul_and_beans_cream_top_matcha_strawberry', 'Sul & Beans Cream Top Matcha Strawberry', 71, 1.5, 8.8, 3.3,
 0.3, 6.5, 480, NULL,
 'estimated', ARRAY['sul and beans cream top matcha strawberry', 'cream top matcha strawberry', 'sul beans cream matcha strawberry', 'matcha strawberry cream top', 'sul & beans cream top matcha strawberry'],
 'beverage', 'Sul & Beans', 1, '340 cal. Matcha latte with fresh strawberry puree, topped with cream cheese foam. $5.75/$6.25.', TRUE),

-- Cream Top Americano: ~160 cal, 3P, 10C, 12F (480g/16oz) — americano with cream cheese foam topping
('sul_and_beans_cream_top_americano', 'Sul & Beans Cream Top Americano', 33, 0.6, 2.1, 2.5,
 0.0, 1.5, 480, NULL,
 'estimated', ARRAY['sul and beans cream top americano', 'cream top americano', 'sul beans cream top americano', 'americano cream top', 'sul & beans cream top americano', 'cream cheese americano'],
 'beverage', 'Sul & Beans', 1, '160 cal. Americano topped with rich whipped cream cheese foam. $5.75/$6.25.', TRUE),

-- Strawberry Citron Tea: ~120 cal, 0P, 30C, 0F (480g/16oz) — strawberry and yuzu citron fruit tea
('sul_and_beans_strawberry_citron_tea', 'Sul & Beans Strawberry Citron Tea', 25, 0.1, 6.3, 0.0,
 0.2, 5.8, 480, NULL,
 'estimated', ARRAY['sul and beans strawberry citron tea', 'strawberry citron tea', 'sul beans strawberry citron', 'strawberry yuzu tea', 'sul & beans strawberry citron tea', 'ttalgi yuzu cha'],
 'beverage', 'Sul & Beans', 1, '120 cal. Hot or iced fruit tea with strawberry and Korean citron (yuzu) preserve. $5.75/$6.25. Caffeine-free.', TRUE),

-- Honey Orange Lemon & Grapefruit Tea: ~130 cal, 0P, 32C, 0F (480g/16oz) — citrus fruit tea with honey
('sul_and_beans_honey_orange_lemon_grapefruit_tea', 'Sul & Beans Honey Orange, Lemon & Grapefruit Tea', 27, 0.1, 6.7, 0.0,
 0.2, 6.0, 480, NULL,
 'estimated', ARRAY['sul and beans honey orange lemon grapefruit tea', 'honey orange lemon grapefruit tea', 'sul beans citrus tea', 'orange lemon grapefruit tea', 'sul & beans honey citrus tea', 'honey citrus fruit tea'],
 'beverage', 'Sul & Beans', 1, '130 cal. Citrus fruit tea blend with honey, orange, lemon, and grapefruit. $5.75/$6.25. Rich in vitamin C. Caffeine-free.', TRUE),

-- Pomegranate Mint Tea: ~90 cal, 0P, 22C, 0F (480g/16oz) — pomegranate with fresh mint
('sul_and_beans_pomegranate_mint_tea', 'Sul & Beans Pomegranate Mint Tea', 19, 0.1, 4.6, 0.0,
 0.1, 4.0, 480, NULL,
 'estimated', ARRAY['sul and beans pomegranate mint tea', 'pomegranate mint tea', 'sul beans pomegranate tea', 'pomegranate tea', 'sul & beans pomegranate mint tea', 'pomegranate mint cha'],
 'beverage', 'Sul & Beans', 1, '90 cal. Pomegranate tea with fresh mint. $5.75/$6.25. Antioxidant-rich and refreshing. Caffeine-free.', TRUE),

-- Honey Lemon Tea: ~100 cal, 0P, 26C, 0F (480g/16oz) — honey and lemon citrus tea
('sul_and_beans_honey_lemon_tea', 'Sul & Beans Honey Lemon Tea', 21, 0.1, 5.4, 0.0,
 0.1, 5.0, 480, NULL,
 'estimated', ARRAY['sul and beans honey lemon tea', 'honey lemon tea', 'sul beans honey lemon tea', 'lemon honey tea', 'sul & beans honey lemon tea', 'honey lemon cha'],
 'beverage', 'Sul & Beans', 1, '100 cal. Warm honey and lemon tea. $5.75/$6.25. Soothing and caffeine-free.', TRUE),

-- Honey Ginger Tea: ~80 cal, 0P, 20C, 0F (480g/16oz) — honey and ginger tea, traditional Korean style
('sul_and_beans_honey_ginger_tea', 'Sul & Beans Honey Ginger Tea', 17, 0.1, 4.2, 0.0,
 0.1, 3.8, 480, NULL,
 'estimated', ARRAY['sul and beans honey ginger tea', 'honey ginger tea', 'sul beans honey ginger tea', 'ginger honey tea', 'sul & beans honey ginger tea', 'saenggang cha', 'korean ginger tea'],
 'beverage', 'Sul & Beans', 1, '80 cal. Traditional Korean ginger tea with honey. $5.75/$6.25. Aids digestion and warms the body. Caffeine-free.', TRUE),

-- Burdock Tea: ~15 cal, 0P, 3C, 0F (480g/16oz) — roasted burdock root tea
('sul_and_beans_burdock_tea', 'Sul & Beans Burdock Tea', 3, 0.1, 0.6, 0.0,
 0.2, 0.1, 480, NULL,
 'estimated', ARRAY['sul and beans burdock tea', 'burdock tea', 'sul beans burdock tea', 'ueong cha', 'ugong cha', 'sul & beans burdock tea', 'korean burdock root tea', 'burdock root tea'],
 'beverage', 'Sul & Beans', 1, '15 cal. Roasted burdock root tea, naturally caffeine-free with a mild earthy nutty flavor. $5.75/$6.25. Low calorie, rich in fiber and prebiotic inulin.', TRUE)

ON CONFLICT (food_name_normalized) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g = EXCLUDED.protein_per_100g,
  carbs_per_100g = EXCLUDED.carbs_per_100g,
  fat_per_100g = EXCLUDED.fat_per_100g,
  fiber_per_100g = EXCLUDED.fiber_per_100g,
  sugar_per_100g = EXCLUDED.sugar_per_100g,
  default_serving_g = EXCLUDED.default_serving_g,
  default_weight_per_piece_g = EXCLUDED.default_weight_per_piece_g,
  source = EXCLUDED.source,
  variant_names = EXCLUDED.variant_names,
  food_category = EXCLUDED.food_category,
  restaurant_name = EXCLUDED.restaurant_name,
  default_count = EXCLUDED.default_count,
  notes = EXCLUDED.notes,
  is_active = EXCLUDED.is_active;
