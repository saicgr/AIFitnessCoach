# Wrong Food Database Matches

Foods where the lookup returns a completely wrong or misleading entry.
These need generic entries added or variant_names fixed.

## Audit Date: 2026-04-03

### Wrong Variant Matches (variant_names returns wrong food)
| User Types | Gets Matched To | Cal/100g | Problem |
|-----------|-----------------|----------|---------|
| "dressing" | Stuffing (Prepared) | 177 | Salad dressing ≠ bread stuffing/dressing |
| "custard" | Chocolate Pudding | 119 | Different dessert, different nutrition |
| "paneer" | Cottage Cheese | 98 | Paneer is 265 cal/100g, not 98 |

### Wrong Trigram Matches (fuzzy matching returns wrong food)
| User Types | Gets Matched To | Similarity | Problem |
|-----------|-----------------|------------|---------|
| "guac" | Guava | 0.38 | Guacamole ≠ guava (160 vs 68 cal) |
| "mousse" | Moussaka | 0.45 | Chocolate mousse ≠ Greek casserole |
| "chapati" | Cham Cham (Bengali Sweet) | 0.30 | Indian flatbread ≠ Bengali dessert |
| "candy" | Caramel | 0.50 | Generic candy ≠ just caramel |
| "cereal" | Trix | 0.58 | Should match generic cereal, not specific brand |

### Substring Fallback Wrong Matches
| User Types | Gets Matched To | Problem |
|-----------|-----------------|---------|
| "water" | Smoothie King Hydration Watermelon | Water = 0 cal, not 47 cal smoothie |
| "salt" | Taco Bell Salted Caramel Churros | Salt = 0 cal, not 295 cal churros |
| "pepper" | Casey's Pepperoni Pizza | Black pepper ≠ pepperoni pizza |
| "oil" | Potato (boiled) | Oil = 884 cal/100g, not 87 cal potato |
| "cola" | Hershey's Milk Chocolate Bar | Cola = 42 cal/100g, not 512 cal chocolate |
| "melon" | Smoothie King Watermelon | Melon = 34 cal/100g, not 47 cal smoothie |

### Foods Needing Generic Entries (to prevent wrong matches)
| Food | Correct Cal/100g | Category | Status |
|------|-----------------|----------|--------|
| water | 0 | beverage | NEEDS ENTRY |
| salt | 0 | condiment | NEEDS ENTRY |
| pepper (black) | 251 | condiment | NEEDS ENTRY |
| oil (vegetable) | 884 | oils_fats | NEEDS ENTRY |
| cola | 42 | beverage | NEEDS ENTRY |
| melon (cantaloupe) | 34 | fruit | NEEDS ENTRY |
| dressing (salad, avg) | 200 | condiment | NEEDS FIX - remove "dressing" from stuffing variants |
| custard | 122 | dessert | NEEDS ENTRY |
| paneer | 265 | dairy | NEEDS ENTRY |
| guac / guacamole | 160 | condiment | NEEDS "guac" added to guacamole variants |
| mousse (chocolate) | 195 | dessert | NEEDS ENTRY |
| chapati | 300 | bread | NEEDS ENTRY |
| candy (generic) | 400 | snack | NEEDS ENTRY |
| cereal (generic) | 379 | breakfast | CHECK - may need "cereal" variant on generic entry |
