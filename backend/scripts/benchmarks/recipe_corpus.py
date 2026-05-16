"""Recipe-import test scenarios for the Phase-2 full sweep.

Two kinds:
  - TEXT recipes: pasted recipe text, varied length / cuisine / ingredient
    count / validity. Exercises POST /nutrition/recipes/import-text.
  - URLS: real recipe-site URLs. Exercises POST /nutrition/recipes/import-url.
    (Kept short — each URL fetch is a live network call.)

Handwritten-photo import (import-handwritten) needs recipe-card images; if
corpus/recipe_card/ has any, the sweep picks them up — otherwise that path
is reported as not-exercised.
"""
from typing import List, Tuple

# (label, recipe_text) — label drives the expected outcome
TEXT_RECIPES: List[Tuple[str, str]] = [
    ("simple_5ing", """Spaghetti Carbonara
Serves 4
Ingredients:
- 400g spaghetti
- 200g pancetta
- 4 large eggs
- 100g parmesan cheese
- black pepper
Steps:
1. Cook spaghetti. 2. Fry pancetta. 3. Mix eggs and cheese. 4. Combine."""),

    ("simple_4ing", """Guacamole
Serves 6
Ingredients:
- 3 ripe avocados
- 1 lime, juiced
- 1/2 red onion, diced
- salt to taste
Steps:
1. Mash avocados. 2. Add lime, onion, salt. 3. Stir."""),

    ("medium_8ing", """Chicken Stir Fry
Serves 4
Ingredients:
- 500g chicken breast
- 2 bell peppers
- 1 broccoli head
- 3 tbsp soy sauce
- 2 tbsp sesame oil
- 1 tbsp ginger
- 2 garlic cloves
- 200g jasmine rice
Steps:
1. Cook rice. 2. Stir-fry chicken. 3. Add vegetables and sauce."""),

    ("long_12ing", """Beef Chili
Serves 8
Ingredients:
- 1kg ground beef
- 2 onions
- 4 garlic cloves
- 2 cans kidney beans
- 2 cans diced tomatoes
- 3 tbsp chili powder
- 1 tbsp cumin
- 1 tbsp paprika
- 2 bell peppers
- 1 tbsp olive oil
- 1 cup beef broth
- salt and pepper
Steps:
1. Brown beef. 2. Saute aromatics. 3. Add everything. 4. Simmer 1 hour."""),

    ("regional_indian", """Chana Masala
Serves 4
Ingredients:
- 2 cans chickpeas
- 1 large onion
- 3 tomatoes
- 2 tbsp ginger garlic paste
- 2 tsp garam masala
- 1 tsp turmeric
- 1 tsp cumin seeds
- 2 tbsp vegetable oil
- fresh cilantro
Steps:
1. Saute cumin. 2. Cook onion-tomato base. 3. Add chickpeas and spices. 4. Simmer."""),

    ("regional_thai", """Thai Green Curry
Serves 4
Ingredients:
- 400ml coconut milk
- 3 tbsp green curry paste
- 500g chicken thigh
- 1 eggplant
- 100g bamboo shoots
- 2 tbsp fish sauce
- 1 tbsp palm sugar
- thai basil
Steps:
1. Fry curry paste. 2. Add coconut milk. 3. Add chicken and vegetables. 4. Season."""),

    ("baking", """Chocolate Chip Cookies
Makes 24 cookies
Ingredients:
- 250g all-purpose flour
- 170g butter
- 150g brown sugar
- 100g white sugar
- 2 eggs
- 200g chocolate chips
- 1 tsp vanilla
- 1 tsp baking soda
- pinch of salt
Steps:
1. Cream butter and sugar. 2. Add eggs and vanilla. 3. Fold in dry ingredients. 4. Bake 12 min at 180C."""),

    ("minimal_3ing", """Scrambled Eggs
Serves 1
Ingredients:
- 3 eggs
- 1 tbsp butter
- salt
Steps:
1. Whisk eggs. 2. Cook in butter. 3. Season."""),

    ("no_amounts", """Tomato Soup
Ingredients:
- tomatoes
- onion
- garlic
- vegetable stock
- cream
- basil
Steps:
1. Saute onion and garlic. 2. Add tomatoes and stock. 3. Blend. 4. Stir in cream."""),

    ("messy_format", """grandma's apple pie ~ serves 8 ~ you need: 6 apples (peeled), about 200g sugar,
a stick of butter, 2 and a half cups flour, cinnamon, a pinch of nutmeg, 1 egg for the wash.
roll the dough, fill with spiced apples, bake til golden."""),

    ("non_recipe", """The weather today is quite nice. I went for a walk in the park and saw
some ducks by the pond. Later I might read a book or watch a movie."""),

    ("ambiguous_shoppinglist", """Shopping list:
milk, eggs, bread, butter, coffee, bananas, chicken, rice, pasta sauce"""),
]

# Real recipe-site URLs — kept SHORT (live network fetch per URL).
URL_RECIPES: List[Tuple[str, str]] = [
    ("allrecipes", "https://www.allrecipes.com/recipe/16354/easy-meatloaf/"),
    ("seriouseats", "https://www.seriouseats.com/the-best-chili-recipe"),
    ("bbcgoodfood", "https://www.bbcgoodfood.com/recipes/spaghetti-bolognese-recipe"),
    ("non_recipe_url", "https://en.wikipedia.org/wiki/Soup"),
    ("bad_url", "https://this-domain-does-not-exist-zealova-test.invalid/recipe"),
]


def get_text_recipes() -> List[Tuple[str, str]]:
    return TEXT_RECIPES


def get_url_recipes() -> List[Tuple[str, str]]:
    return URL_RECIPES


if __name__ == "__main__":
    print(f"text recipes: {len(TEXT_RECIPES)}")
    print(f"url recipes:  {len(URL_RECIPES)}")
