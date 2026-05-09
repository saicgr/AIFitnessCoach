# /suggest-substitutes — 1,000 Scenarios

**Endpoint:** `POST /api/v1/exercise-preferences/suggest-substitutes`  
**Type:** Algorithmic (no AI). Hits `exercise_library_cleaned` MV.  
**Total scenarios:** 1,000  

## Live Run Status

_(harness updates this table per-call when run with --live-status flag)_

## Block layout

| Block | Scope | Count |
|---|---|---|
| 1 | Top 50 known exercises × 14 reasons (Cartesian) | 700 |
| 2 | Remaining 30 exercises × top 7 reasons | 200 |
| 3 | Edge-case exercises × no reason | 50 |
| 4 | Edge-case exercises × rotating injury reason | 30 |
| 5 | Canonical injury pairings (high-signal) | 20 |
| **Total** | | **1,000** |

## All scenarios

| idx | block | exercise_name | reason |
|---|---|---|---|
| 1 | 1 | Barbell Back Squat | — |
| 2 | 1 | Barbell Back Squat | knee injury |
| 3 | 1 | Barbell Back Squat | shoulder pain |
| 4 | 1 | Barbell Back Squat | lower back pain |
| 5 | 1 | Barbell Back Squat | wrist injury |
| 6 | 1 | Barbell Back Squat | ankle sprain |
| 7 | 1 | Barbell Back Squat | elbow tendinitis |
| 8 | 1 | Barbell Back Squat | hip pain |
| 9 | 1 | Barbell Back Squat | neck strain |
| 10 | 1 | Barbell Back Squat | no equipment available |
| 11 | 1 | Barbell Back Squat | boring |
| 12 | 1 | Barbell Back Squat | pregnant — second trimester |
| 13 | 1 | Barbell Back Squat | post-surgery rehab |
| 14 | 1 | Barbell Back Squat | bored and want variety |
| 15 | 1 | Barbell Front Squat | — |
| 16 | 1 | Barbell Front Squat | knee injury |
| 17 | 1 | Barbell Front Squat | shoulder pain |
| 18 | 1 | Barbell Front Squat | lower back pain |
| 19 | 1 | Barbell Front Squat | wrist injury |
| 20 | 1 | Barbell Front Squat | ankle sprain |
| 21 | 1 | Barbell Front Squat | elbow tendinitis |
| 22 | 1 | Barbell Front Squat | hip pain |
| 23 | 1 | Barbell Front Squat | neck strain |
| 24 | 1 | Barbell Front Squat | no equipment available |
| 25 | 1 | Barbell Front Squat | boring |
| 26 | 1 | Barbell Front Squat | pregnant — second trimester |
| 27 | 1 | Barbell Front Squat | post-surgery rehab |
| 28 | 1 | Barbell Front Squat | bored and want variety |
| 29 | 1 | Goblet Squat | — |
| 30 | 1 | Goblet Squat | knee injury |
| 31 | 1 | Goblet Squat | shoulder pain |
| 32 | 1 | Goblet Squat | lower back pain |
| 33 | 1 | Goblet Squat | wrist injury |
| 34 | 1 | Goblet Squat | ankle sprain |
| 35 | 1 | Goblet Squat | elbow tendinitis |
| 36 | 1 | Goblet Squat | hip pain |
| 37 | 1 | Goblet Squat | neck strain |
| 38 | 1 | Goblet Squat | no equipment available |
| 39 | 1 | Goblet Squat | boring |
| 40 | 1 | Goblet Squat | pregnant — second trimester |
| 41 | 1 | Goblet Squat | post-surgery rehab |
| 42 | 1 | Goblet Squat | bored and want variety |
| 43 | 1 | Bulgarian Split Squat | — |
| 44 | 1 | Bulgarian Split Squat | knee injury |
| 45 | 1 | Bulgarian Split Squat | shoulder pain |
| 46 | 1 | Bulgarian Split Squat | lower back pain |
| 47 | 1 | Bulgarian Split Squat | wrist injury |
| 48 | 1 | Bulgarian Split Squat | ankle sprain |
| 49 | 1 | Bulgarian Split Squat | elbow tendinitis |
| 50 | 1 | Bulgarian Split Squat | hip pain |
| 51 | 1 | Bulgarian Split Squat | neck strain |
| 52 | 1 | Bulgarian Split Squat | no equipment available |
| 53 | 1 | Bulgarian Split Squat | boring |
| 54 | 1 | Bulgarian Split Squat | pregnant — second trimester |
| 55 | 1 | Bulgarian Split Squat | post-surgery rehab |
| 56 | 1 | Bulgarian Split Squat | bored and want variety |
| 57 | 1 | Pistol Squat | — |
| 58 | 1 | Pistol Squat | knee injury |
| 59 | 1 | Pistol Squat | shoulder pain |
| 60 | 1 | Pistol Squat | lower back pain |
| 61 | 1 | Pistol Squat | wrist injury |
| 62 | 1 | Pistol Squat | ankle sprain |
| 63 | 1 | Pistol Squat | elbow tendinitis |
| 64 | 1 | Pistol Squat | hip pain |
| 65 | 1 | Pistol Squat | neck strain |
| 66 | 1 | Pistol Squat | no equipment available |
| 67 | 1 | Pistol Squat | boring |
| 68 | 1 | Pistol Squat | pregnant — second trimester |
| 69 | 1 | Pistol Squat | post-surgery rehab |
| 70 | 1 | Pistol Squat | bored and want variety |
| 71 | 1 | Walking Lunges | — |
| 72 | 1 | Walking Lunges | knee injury |
| 73 | 1 | Walking Lunges | shoulder pain |
| 74 | 1 | Walking Lunges | lower back pain |
| 75 | 1 | Walking Lunges | wrist injury |
| 76 | 1 | Walking Lunges | ankle sprain |
| 77 | 1 | Walking Lunges | elbow tendinitis |
| 78 | 1 | Walking Lunges | hip pain |
| 79 | 1 | Walking Lunges | neck strain |
| 80 | 1 | Walking Lunges | no equipment available |
| 81 | 1 | Walking Lunges | boring |
| 82 | 1 | Walking Lunges | pregnant — second trimester |
| 83 | 1 | Walking Lunges | post-surgery rehab |
| 84 | 1 | Walking Lunges | bored and want variety |
| 85 | 1 | Conventional Deadlift | — |
| 86 | 1 | Conventional Deadlift | knee injury |
| 87 | 1 | Conventional Deadlift | shoulder pain |
| 88 | 1 | Conventional Deadlift | lower back pain |
| 89 | 1 | Conventional Deadlift | wrist injury |
| 90 | 1 | Conventional Deadlift | ankle sprain |
| 91 | 1 | Conventional Deadlift | elbow tendinitis |
| 92 | 1 | Conventional Deadlift | hip pain |
| 93 | 1 | Conventional Deadlift | neck strain |
| 94 | 1 | Conventional Deadlift | no equipment available |
| 95 | 1 | Conventional Deadlift | boring |
| 96 | 1 | Conventional Deadlift | pregnant — second trimester |
| 97 | 1 | Conventional Deadlift | post-surgery rehab |
| 98 | 1 | Conventional Deadlift | bored and want variety |
| 99 | 1 | Romanian Deadlift | — |
| 100 | 1 | Romanian Deadlift | knee injury |
| 101 | 1 | Romanian Deadlift | shoulder pain |
| 102 | 1 | Romanian Deadlift | lower back pain |
| 103 | 1 | Romanian Deadlift | wrist injury |
| 104 | 1 | Romanian Deadlift | ankle sprain |
| 105 | 1 | Romanian Deadlift | elbow tendinitis |
| 106 | 1 | Romanian Deadlift | hip pain |
| 107 | 1 | Romanian Deadlift | neck strain |
| 108 | 1 | Romanian Deadlift | no equipment available |
| 109 | 1 | Romanian Deadlift | boring |
| 110 | 1 | Romanian Deadlift | pregnant — second trimester |
| 111 | 1 | Romanian Deadlift | post-surgery rehab |
| 112 | 1 | Romanian Deadlift | bored and want variety |
| 113 | 1 | Sumo Deadlift | — |
| 114 | 1 | Sumo Deadlift | knee injury |
| 115 | 1 | Sumo Deadlift | shoulder pain |
| 116 | 1 | Sumo Deadlift | lower back pain |
| 117 | 1 | Sumo Deadlift | wrist injury |
| 118 | 1 | Sumo Deadlift | ankle sprain |
| 119 | 1 | Sumo Deadlift | elbow tendinitis |
| 120 | 1 | Sumo Deadlift | hip pain |
| 121 | 1 | Sumo Deadlift | neck strain |
| 122 | 1 | Sumo Deadlift | no equipment available |
| 123 | 1 | Sumo Deadlift | boring |
| 124 | 1 | Sumo Deadlift | pregnant — second trimester |
| 125 | 1 | Sumo Deadlift | post-surgery rehab |
| 126 | 1 | Sumo Deadlift | bored and want variety |
| 127 | 1 | Leg Press | — |
| 128 | 1 | Leg Press | knee injury |
| 129 | 1 | Leg Press | shoulder pain |
| 130 | 1 | Leg Press | lower back pain |
| 131 | 1 | Leg Press | wrist injury |
| 132 | 1 | Leg Press | ankle sprain |
| 133 | 1 | Leg Press | elbow tendinitis |
| 134 | 1 | Leg Press | hip pain |
| 135 | 1 | Leg Press | neck strain |
| 136 | 1 | Leg Press | no equipment available |
| 137 | 1 | Leg Press | boring |
| 138 | 1 | Leg Press | pregnant — second trimester |
| 139 | 1 | Leg Press | post-surgery rehab |
| 140 | 1 | Leg Press | bored and want variety |
| 141 | 1 | Hack Squat | — |
| 142 | 1 | Hack Squat | knee injury |
| 143 | 1 | Hack Squat | shoulder pain |
| 144 | 1 | Hack Squat | lower back pain |
| 145 | 1 | Hack Squat | wrist injury |
| 146 | 1 | Hack Squat | ankle sprain |
| 147 | 1 | Hack Squat | elbow tendinitis |
| 148 | 1 | Hack Squat | hip pain |
| 149 | 1 | Hack Squat | neck strain |
| 150 | 1 | Hack Squat | no equipment available |
| 151 | 1 | Hack Squat | boring |
| 152 | 1 | Hack Squat | pregnant — second trimester |
| 153 | 1 | Hack Squat | post-surgery rehab |
| 154 | 1 | Hack Squat | bored and want variety |
| 155 | 1 | Jump Squat | — |
| 156 | 1 | Jump Squat | knee injury |
| 157 | 1 | Jump Squat | shoulder pain |
| 158 | 1 | Jump Squat | lower back pain |
| 159 | 1 | Jump Squat | wrist injury |
| 160 | 1 | Jump Squat | ankle sprain |
| 161 | 1 | Jump Squat | elbow tendinitis |
| 162 | 1 | Jump Squat | hip pain |
| 163 | 1 | Jump Squat | neck strain |
| 164 | 1 | Jump Squat | no equipment available |
| 165 | 1 | Jump Squat | boring |
| 166 | 1 | Jump Squat | pregnant — second trimester |
| 167 | 1 | Jump Squat | post-surgery rehab |
| 168 | 1 | Jump Squat | bored and want variety |
| 169 | 1 | Barbell Bench Press | — |
| 170 | 1 | Barbell Bench Press | knee injury |
| 171 | 1 | Barbell Bench Press | shoulder pain |
| 172 | 1 | Barbell Bench Press | lower back pain |
| 173 | 1 | Barbell Bench Press | wrist injury |
| 174 | 1 | Barbell Bench Press | ankle sprain |
| 175 | 1 | Barbell Bench Press | elbow tendinitis |
| 176 | 1 | Barbell Bench Press | hip pain |
| 177 | 1 | Barbell Bench Press | neck strain |
| 178 | 1 | Barbell Bench Press | no equipment available |
| 179 | 1 | Barbell Bench Press | boring |
| 180 | 1 | Barbell Bench Press | pregnant — second trimester |
| 181 | 1 | Barbell Bench Press | post-surgery rehab |
| 182 | 1 | Barbell Bench Press | bored and want variety |
| 183 | 1 | Incline Dumbbell Press | — |
| 184 | 1 | Incline Dumbbell Press | knee injury |
| 185 | 1 | Incline Dumbbell Press | shoulder pain |
| 186 | 1 | Incline Dumbbell Press | lower back pain |
| 187 | 1 | Incline Dumbbell Press | wrist injury |
| 188 | 1 | Incline Dumbbell Press | ankle sprain |
| 189 | 1 | Incline Dumbbell Press | elbow tendinitis |
| 190 | 1 | Incline Dumbbell Press | hip pain |
| 191 | 1 | Incline Dumbbell Press | neck strain |
| 192 | 1 | Incline Dumbbell Press | no equipment available |
| 193 | 1 | Incline Dumbbell Press | boring |
| 194 | 1 | Incline Dumbbell Press | pregnant — second trimester |
| 195 | 1 | Incline Dumbbell Press | post-surgery rehab |
| 196 | 1 | Incline Dumbbell Press | bored and want variety |
| 197 | 1 | Overhead Press | — |
| 198 | 1 | Overhead Press | knee injury |
| 199 | 1 | Overhead Press | shoulder pain |
| 200 | 1 | Overhead Press | lower back pain |
| 201 | 1 | Overhead Press | wrist injury |
| 202 | 1 | Overhead Press | ankle sprain |
| 203 | 1 | Overhead Press | elbow tendinitis |
| 204 | 1 | Overhead Press | hip pain |
| 205 | 1 | Overhead Press | neck strain |
| 206 | 1 | Overhead Press | no equipment available |
| 207 | 1 | Overhead Press | boring |
| 208 | 1 | Overhead Press | pregnant — second trimester |
| 209 | 1 | Overhead Press | post-surgery rehab |
| 210 | 1 | Overhead Press | bored and want variety |
| 211 | 1 | Dumbbell Shoulder Press | — |
| 212 | 1 | Dumbbell Shoulder Press | knee injury |
| 213 | 1 | Dumbbell Shoulder Press | shoulder pain |
| 214 | 1 | Dumbbell Shoulder Press | lower back pain |
| 215 | 1 | Dumbbell Shoulder Press | wrist injury |
| 216 | 1 | Dumbbell Shoulder Press | ankle sprain |
| 217 | 1 | Dumbbell Shoulder Press | elbow tendinitis |
| 218 | 1 | Dumbbell Shoulder Press | hip pain |
| 219 | 1 | Dumbbell Shoulder Press | neck strain |
| 220 | 1 | Dumbbell Shoulder Press | no equipment available |
| 221 | 1 | Dumbbell Shoulder Press | boring |
| 222 | 1 | Dumbbell Shoulder Press | pregnant — second trimester |
| 223 | 1 | Dumbbell Shoulder Press | post-surgery rehab |
| 224 | 1 | Dumbbell Shoulder Press | bored and want variety |
| 225 | 1 | Push-Up | — |
| 226 | 1 | Push-Up | knee injury |
| 227 | 1 | Push-Up | shoulder pain |
| 228 | 1 | Push-Up | lower back pain |
| 229 | 1 | Push-Up | wrist injury |
| 230 | 1 | Push-Up | ankle sprain |
| 231 | 1 | Push-Up | elbow tendinitis |
| 232 | 1 | Push-Up | hip pain |
| 233 | 1 | Push-Up | neck strain |
| 234 | 1 | Push-Up | no equipment available |
| 235 | 1 | Push-Up | boring |
| 236 | 1 | Push-Up | pregnant — second trimester |
| 237 | 1 | Push-Up | post-surgery rehab |
| 238 | 1 | Push-Up | bored and want variety |
| 239 | 1 | Decline Bench Press | — |
| 240 | 1 | Decline Bench Press | knee injury |
| 241 | 1 | Decline Bench Press | shoulder pain |
| 242 | 1 | Decline Bench Press | lower back pain |
| 243 | 1 | Decline Bench Press | wrist injury |
| 244 | 1 | Decline Bench Press | ankle sprain |
| 245 | 1 | Decline Bench Press | elbow tendinitis |
| 246 | 1 | Decline Bench Press | hip pain |
| 247 | 1 | Decline Bench Press | neck strain |
| 248 | 1 | Decline Bench Press | no equipment available |
| 249 | 1 | Decline Bench Press | boring |
| 250 | 1 | Decline Bench Press | pregnant — second trimester |
| 251 | 1 | Decline Bench Press | post-surgery rehab |
| 252 | 1 | Decline Bench Press | bored and want variety |
| 253 | 1 | Dips | — |
| 254 | 1 | Dips | knee injury |
| 255 | 1 | Dips | shoulder pain |
| 256 | 1 | Dips | lower back pain |
| 257 | 1 | Dips | wrist injury |
| 258 | 1 | Dips | ankle sprain |
| 259 | 1 | Dips | elbow tendinitis |
| 260 | 1 | Dips | hip pain |
| 261 | 1 | Dips | neck strain |
| 262 | 1 | Dips | no equipment available |
| 263 | 1 | Dips | boring |
| 264 | 1 | Dips | pregnant — second trimester |
| 265 | 1 | Dips | post-surgery rehab |
| 266 | 1 | Dips | bored and want variety |
| 267 | 1 | Diamond Push-up | — |
| 268 | 1 | Diamond Push-up | knee injury |
| 269 | 1 | Diamond Push-up | shoulder pain |
| 270 | 1 | Diamond Push-up | lower back pain |
| 271 | 1 | Diamond Push-up | wrist injury |
| 272 | 1 | Diamond Push-up | ankle sprain |
| 273 | 1 | Diamond Push-up | elbow tendinitis |
| 274 | 1 | Diamond Push-up | hip pain |
| 275 | 1 | Diamond Push-up | neck strain |
| 276 | 1 | Diamond Push-up | no equipment available |
| 277 | 1 | Diamond Push-up | boring |
| 278 | 1 | Diamond Push-up | pregnant — second trimester |
| 279 | 1 | Diamond Push-up | post-surgery rehab |
| 280 | 1 | Diamond Push-up | bored and want variety |
| 281 | 1 | Archer Push-up | — |
| 282 | 1 | Archer Push-up | knee injury |
| 283 | 1 | Archer Push-up | shoulder pain |
| 284 | 1 | Archer Push-up | lower back pain |
| 285 | 1 | Archer Push-up | wrist injury |
| 286 | 1 | Archer Push-up | ankle sprain |
| 287 | 1 | Archer Push-up | elbow tendinitis |
| 288 | 1 | Archer Push-up | hip pain |
| 289 | 1 | Archer Push-up | neck strain |
| 290 | 1 | Archer Push-up | no equipment available |
| 291 | 1 | Archer Push-up | boring |
| 292 | 1 | Archer Push-up | pregnant — second trimester |
| 293 | 1 | Archer Push-up | post-surgery rehab |
| 294 | 1 | Archer Push-up | bored and want variety |
| 295 | 1 | Arnold Press | — |
| 296 | 1 | Arnold Press | knee injury |
| 297 | 1 | Arnold Press | shoulder pain |
| 298 | 1 | Arnold Press | lower back pain |
| 299 | 1 | Arnold Press | wrist injury |
| 300 | 1 | Arnold Press | ankle sprain |
| 301 | 1 | Arnold Press | elbow tendinitis |
| 302 | 1 | Arnold Press | hip pain |
| 303 | 1 | Arnold Press | neck strain |
| 304 | 1 | Arnold Press | no equipment available |
| 305 | 1 | Arnold Press | boring |
| 306 | 1 | Arnold Press | pregnant — second trimester |
| 307 | 1 | Arnold Press | post-surgery rehab |
| 308 | 1 | Arnold Press | bored and want variety |
| 309 | 1 | Pull-Up | — |
| 310 | 1 | Pull-Up | knee injury |
| 311 | 1 | Pull-Up | shoulder pain |
| 312 | 1 | Pull-Up | lower back pain |
| 313 | 1 | Pull-Up | wrist injury |
| 314 | 1 | Pull-Up | ankle sprain |
| 315 | 1 | Pull-Up | elbow tendinitis |
| 316 | 1 | Pull-Up | hip pain |
| 317 | 1 | Pull-Up | neck strain |
| 318 | 1 | Pull-Up | no equipment available |
| 319 | 1 | Pull-Up | boring |
| 320 | 1 | Pull-Up | pregnant — second trimester |
| 321 | 1 | Pull-Up | post-surgery rehab |
| 322 | 1 | Pull-Up | bored and want variety |
| 323 | 1 | Chin-Up | — |
| 324 | 1 | Chin-Up | knee injury |
| 325 | 1 | Chin-Up | shoulder pain |
| 326 | 1 | Chin-Up | lower back pain |
| 327 | 1 | Chin-Up | wrist injury |
| 328 | 1 | Chin-Up | ankle sprain |
| 329 | 1 | Chin-Up | elbow tendinitis |
| 330 | 1 | Chin-Up | hip pain |
| 331 | 1 | Chin-Up | neck strain |
| 332 | 1 | Chin-Up | no equipment available |
| 333 | 1 | Chin-Up | boring |
| 334 | 1 | Chin-Up | pregnant — second trimester |
| 335 | 1 | Chin-Up | post-surgery rehab |
| 336 | 1 | Chin-Up | bored and want variety |
| 337 | 1 | Barbell Row | — |
| 338 | 1 | Barbell Row | knee injury |
| 339 | 1 | Barbell Row | shoulder pain |
| 340 | 1 | Barbell Row | lower back pain |
| 341 | 1 | Barbell Row | wrist injury |
| 342 | 1 | Barbell Row | ankle sprain |
| 343 | 1 | Barbell Row | elbow tendinitis |
| 344 | 1 | Barbell Row | hip pain |
| 345 | 1 | Barbell Row | neck strain |
| 346 | 1 | Barbell Row | no equipment available |
| 347 | 1 | Barbell Row | boring |
| 348 | 1 | Barbell Row | pregnant — second trimester |
| 349 | 1 | Barbell Row | post-surgery rehab |
| 350 | 1 | Barbell Row | bored and want variety |
| 351 | 1 | Dumbbell Row | — |
| 352 | 1 | Dumbbell Row | knee injury |
| 353 | 1 | Dumbbell Row | shoulder pain |
| 354 | 1 | Dumbbell Row | lower back pain |
| 355 | 1 | Dumbbell Row | wrist injury |
| 356 | 1 | Dumbbell Row | ankle sprain |
| 357 | 1 | Dumbbell Row | elbow tendinitis |
| 358 | 1 | Dumbbell Row | hip pain |
| 359 | 1 | Dumbbell Row | neck strain |
| 360 | 1 | Dumbbell Row | no equipment available |
| 361 | 1 | Dumbbell Row | boring |
| 362 | 1 | Dumbbell Row | pregnant — second trimester |
| 363 | 1 | Dumbbell Row | post-surgery rehab |
| 364 | 1 | Dumbbell Row | bored and want variety |
| 365 | 1 | Cable Row | — |
| 366 | 1 | Cable Row | knee injury |
| 367 | 1 | Cable Row | shoulder pain |
| 368 | 1 | Cable Row | lower back pain |
| 369 | 1 | Cable Row | wrist injury |
| 370 | 1 | Cable Row | ankle sprain |
| 371 | 1 | Cable Row | elbow tendinitis |
| 372 | 1 | Cable Row | hip pain |
| 373 | 1 | Cable Row | neck strain |
| 374 | 1 | Cable Row | no equipment available |
| 375 | 1 | Cable Row | boring |
| 376 | 1 | Cable Row | pregnant — second trimester |
| 377 | 1 | Cable Row | post-surgery rehab |
| 378 | 1 | Cable Row | bored and want variety |
| 379 | 1 | Lat Pulldown | — |
| 380 | 1 | Lat Pulldown | knee injury |
| 381 | 1 | Lat Pulldown | shoulder pain |
| 382 | 1 | Lat Pulldown | lower back pain |
| 383 | 1 | Lat Pulldown | wrist injury |
| 384 | 1 | Lat Pulldown | ankle sprain |
| 385 | 1 | Lat Pulldown | elbow tendinitis |
| 386 | 1 | Lat Pulldown | hip pain |
| 387 | 1 | Lat Pulldown | neck strain |
| 388 | 1 | Lat Pulldown | no equipment available |
| 389 | 1 | Lat Pulldown | boring |
| 390 | 1 | Lat Pulldown | pregnant — second trimester |
| 391 | 1 | Lat Pulldown | post-surgery rehab |
| 392 | 1 | Lat Pulldown | bored and want variety |
| 393 | 1 | Inverted Row | — |
| 394 | 1 | Inverted Row | knee injury |
| 395 | 1 | Inverted Row | shoulder pain |
| 396 | 1 | Inverted Row | lower back pain |
| 397 | 1 | Inverted Row | wrist injury |
| 398 | 1 | Inverted Row | ankle sprain |
| 399 | 1 | Inverted Row | elbow tendinitis |
| 400 | 1 | Inverted Row | hip pain |
| 401 | 1 | Inverted Row | neck strain |
| 402 | 1 | Inverted Row | no equipment available |
| 403 | 1 | Inverted Row | boring |
| 404 | 1 | Inverted Row | pregnant — second trimester |
| 405 | 1 | Inverted Row | post-surgery rehab |
| 406 | 1 | Inverted Row | bored and want variety |
| 407 | 1 | Face Pull | — |
| 408 | 1 | Face Pull | knee injury |
| 409 | 1 | Face Pull | shoulder pain |
| 410 | 1 | Face Pull | lower back pain |
| 411 | 1 | Face Pull | wrist injury |
| 412 | 1 | Face Pull | ankle sprain |
| 413 | 1 | Face Pull | elbow tendinitis |
| 414 | 1 | Face Pull | hip pain |
| 415 | 1 | Face Pull | neck strain |
| 416 | 1 | Face Pull | no equipment available |
| 417 | 1 | Face Pull | boring |
| 418 | 1 | Face Pull | pregnant — second trimester |
| 419 | 1 | Face Pull | post-surgery rehab |
| 420 | 1 | Face Pull | bored and want variety |
| 421 | 1 | Bicep Curl | — |
| 422 | 1 | Bicep Curl | knee injury |
| 423 | 1 | Bicep Curl | shoulder pain |
| 424 | 1 | Bicep Curl | lower back pain |
| 425 | 1 | Bicep Curl | wrist injury |
| 426 | 1 | Bicep Curl | ankle sprain |
| 427 | 1 | Bicep Curl | elbow tendinitis |
| 428 | 1 | Bicep Curl | hip pain |
| 429 | 1 | Bicep Curl | neck strain |
| 430 | 1 | Bicep Curl | no equipment available |
| 431 | 1 | Bicep Curl | boring |
| 432 | 1 | Bicep Curl | pregnant — second trimester |
| 433 | 1 | Bicep Curl | post-surgery rehab |
| 434 | 1 | Bicep Curl | bored and want variety |
| 435 | 1 | Hammer Curl | — |
| 436 | 1 | Hammer Curl | knee injury |
| 437 | 1 | Hammer Curl | shoulder pain |
| 438 | 1 | Hammer Curl | lower back pain |
| 439 | 1 | Hammer Curl | wrist injury |
| 440 | 1 | Hammer Curl | ankle sprain |
| 441 | 1 | Hammer Curl | elbow tendinitis |
| 442 | 1 | Hammer Curl | hip pain |
| 443 | 1 | Hammer Curl | neck strain |
| 444 | 1 | Hammer Curl | no equipment available |
| 445 | 1 | Hammer Curl | boring |
| 446 | 1 | Hammer Curl | pregnant — second trimester |
| 447 | 1 | Hammer Curl | post-surgery rehab |
| 448 | 1 | Hammer Curl | bored and want variety |
| 449 | 1 | Tricep Extension | — |
| 450 | 1 | Tricep Extension | knee injury |
| 451 | 1 | Tricep Extension | shoulder pain |
| 452 | 1 | Tricep Extension | lower back pain |
| 453 | 1 | Tricep Extension | wrist injury |
| 454 | 1 | Tricep Extension | ankle sprain |
| 455 | 1 | Tricep Extension | elbow tendinitis |
| 456 | 1 | Tricep Extension | hip pain |
| 457 | 1 | Tricep Extension | neck strain |
| 458 | 1 | Tricep Extension | no equipment available |
| 459 | 1 | Tricep Extension | boring |
| 460 | 1 | Tricep Extension | pregnant — second trimester |
| 461 | 1 | Tricep Extension | post-surgery rehab |
| 462 | 1 | Tricep Extension | bored and want variety |
| 463 | 1 | Skull Crusher | — |
| 464 | 1 | Skull Crusher | knee injury |
| 465 | 1 | Skull Crusher | shoulder pain |
| 466 | 1 | Skull Crusher | lower back pain |
| 467 | 1 | Skull Crusher | wrist injury |
| 468 | 1 | Skull Crusher | ankle sprain |
| 469 | 1 | Skull Crusher | elbow tendinitis |
| 470 | 1 | Skull Crusher | hip pain |
| 471 | 1 | Skull Crusher | neck strain |
| 472 | 1 | Skull Crusher | no equipment available |
| 473 | 1 | Skull Crusher | boring |
| 474 | 1 | Skull Crusher | pregnant — second trimester |
| 475 | 1 | Skull Crusher | post-surgery rehab |
| 476 | 1 | Skull Crusher | bored and want variety |
| 477 | 1 | Lateral Raise | — |
| 478 | 1 | Lateral Raise | knee injury |
| 479 | 1 | Lateral Raise | shoulder pain |
| 480 | 1 | Lateral Raise | lower back pain |
| 481 | 1 | Lateral Raise | wrist injury |
| 482 | 1 | Lateral Raise | ankle sprain |
| 483 | 1 | Lateral Raise | elbow tendinitis |
| 484 | 1 | Lateral Raise | hip pain |
| 485 | 1 | Lateral Raise | neck strain |
| 486 | 1 | Lateral Raise | no equipment available |
| 487 | 1 | Lateral Raise | boring |
| 488 | 1 | Lateral Raise | pregnant — second trimester |
| 489 | 1 | Lateral Raise | post-surgery rehab |
| 490 | 1 | Lateral Raise | bored and want variety |
| 491 | 1 | Front Raise | — |
| 492 | 1 | Front Raise | knee injury |
| 493 | 1 | Front Raise | shoulder pain |
| 494 | 1 | Front Raise | lower back pain |
| 495 | 1 | Front Raise | wrist injury |
| 496 | 1 | Front Raise | ankle sprain |
| 497 | 1 | Front Raise | elbow tendinitis |
| 498 | 1 | Front Raise | hip pain |
| 499 | 1 | Front Raise | neck strain |
| 500 | 1 | Front Raise | no equipment available |
| 501 | 1 | Front Raise | boring |
| 502 | 1 | Front Raise | pregnant — second trimester |
| 503 | 1 | Front Raise | post-surgery rehab |
| 504 | 1 | Front Raise | bored and want variety |
| 505 | 1 | Rear Delt Fly | — |
| 506 | 1 | Rear Delt Fly | knee injury |
| 507 | 1 | Rear Delt Fly | shoulder pain |
| 508 | 1 | Rear Delt Fly | lower back pain |
| 509 | 1 | Rear Delt Fly | wrist injury |
| 510 | 1 | Rear Delt Fly | ankle sprain |
| 511 | 1 | Rear Delt Fly | elbow tendinitis |
| 512 | 1 | Rear Delt Fly | hip pain |
| 513 | 1 | Rear Delt Fly | neck strain |
| 514 | 1 | Rear Delt Fly | no equipment available |
| 515 | 1 | Rear Delt Fly | boring |
| 516 | 1 | Rear Delt Fly | pregnant — second trimester |
| 517 | 1 | Rear Delt Fly | post-surgery rehab |
| 518 | 1 | Rear Delt Fly | bored and want variety |
| 519 | 1 | Calf Raise | — |
| 520 | 1 | Calf Raise | knee injury |
| 521 | 1 | Calf Raise | shoulder pain |
| 522 | 1 | Calf Raise | lower back pain |
| 523 | 1 | Calf Raise | wrist injury |
| 524 | 1 | Calf Raise | ankle sprain |
| 525 | 1 | Calf Raise | elbow tendinitis |
| 526 | 1 | Calf Raise | hip pain |
| 527 | 1 | Calf Raise | neck strain |
| 528 | 1 | Calf Raise | no equipment available |
| 529 | 1 | Calf Raise | boring |
| 530 | 1 | Calf Raise | pregnant — second trimester |
| 531 | 1 | Calf Raise | post-surgery rehab |
| 532 | 1 | Calf Raise | bored and want variety |
| 533 | 1 | Leg Extension | — |
| 534 | 1 | Leg Extension | knee injury |
| 535 | 1 | Leg Extension | shoulder pain |
| 536 | 1 | Leg Extension | lower back pain |
| 537 | 1 | Leg Extension | wrist injury |
| 538 | 1 | Leg Extension | ankle sprain |
| 539 | 1 | Leg Extension | elbow tendinitis |
| 540 | 1 | Leg Extension | hip pain |
| 541 | 1 | Leg Extension | neck strain |
| 542 | 1 | Leg Extension | no equipment available |
| 543 | 1 | Leg Extension | boring |
| 544 | 1 | Leg Extension | pregnant — second trimester |
| 545 | 1 | Leg Extension | post-surgery rehab |
| 546 | 1 | Leg Extension | bored and want variety |
| 547 | 1 | Leg Curl | — |
| 548 | 1 | Leg Curl | knee injury |
| 549 | 1 | Leg Curl | shoulder pain |
| 550 | 1 | Leg Curl | lower back pain |
| 551 | 1 | Leg Curl | wrist injury |
| 552 | 1 | Leg Curl | ankle sprain |
| 553 | 1 | Leg Curl | elbow tendinitis |
| 554 | 1 | Leg Curl | hip pain |
| 555 | 1 | Leg Curl | neck strain |
| 556 | 1 | Leg Curl | no equipment available |
| 557 | 1 | Leg Curl | boring |
| 558 | 1 | Leg Curl | pregnant — second trimester |
| 559 | 1 | Leg Curl | post-surgery rehab |
| 560 | 1 | Leg Curl | bored and want variety |
| 561 | 1 | Cable Fly | — |
| 562 | 1 | Cable Fly | knee injury |
| 563 | 1 | Cable Fly | shoulder pain |
| 564 | 1 | Cable Fly | lower back pain |
| 565 | 1 | Cable Fly | wrist injury |
| 566 | 1 | Cable Fly | ankle sprain |
| 567 | 1 | Cable Fly | elbow tendinitis |
| 568 | 1 | Cable Fly | hip pain |
| 569 | 1 | Cable Fly | neck strain |
| 570 | 1 | Cable Fly | no equipment available |
| 571 | 1 | Cable Fly | boring |
| 572 | 1 | Cable Fly | pregnant — second trimester |
| 573 | 1 | Cable Fly | post-surgery rehab |
| 574 | 1 | Cable Fly | bored and want variety |
| 575 | 1 | Pec Deck | — |
| 576 | 1 | Pec Deck | knee injury |
| 577 | 1 | Pec Deck | shoulder pain |
| 578 | 1 | Pec Deck | lower back pain |
| 579 | 1 | Pec Deck | wrist injury |
| 580 | 1 | Pec Deck | ankle sprain |
| 581 | 1 | Pec Deck | elbow tendinitis |
| 582 | 1 | Pec Deck | hip pain |
| 583 | 1 | Pec Deck | neck strain |
| 584 | 1 | Pec Deck | no equipment available |
| 585 | 1 | Pec Deck | boring |
| 586 | 1 | Pec Deck | pregnant — second trimester |
| 587 | 1 | Pec Deck | post-surgery rehab |
| 588 | 1 | Pec Deck | bored and want variety |
| 589 | 1 | Plank | — |
| 590 | 1 | Plank | knee injury |
| 591 | 1 | Plank | shoulder pain |
| 592 | 1 | Plank | lower back pain |
| 593 | 1 | Plank | wrist injury |
| 594 | 1 | Plank | ankle sprain |
| 595 | 1 | Plank | elbow tendinitis |
| 596 | 1 | Plank | hip pain |
| 597 | 1 | Plank | neck strain |
| 598 | 1 | Plank | no equipment available |
| 599 | 1 | Plank | boring |
| 600 | 1 | Plank | pregnant — second trimester |
| 601 | 1 | Plank | post-surgery rehab |
| 602 | 1 | Plank | bored and want variety |
| 603 | 1 | Side Plank | — |
| 604 | 1 | Side Plank | knee injury |
| 605 | 1 | Side Plank | shoulder pain |
| 606 | 1 | Side Plank | lower back pain |
| 607 | 1 | Side Plank | wrist injury |
| 608 | 1 | Side Plank | ankle sprain |
| 609 | 1 | Side Plank | elbow tendinitis |
| 610 | 1 | Side Plank | hip pain |
| 611 | 1 | Side Plank | neck strain |
| 612 | 1 | Side Plank | no equipment available |
| 613 | 1 | Side Plank | boring |
| 614 | 1 | Side Plank | pregnant — second trimester |
| 615 | 1 | Side Plank | post-surgery rehab |
| 616 | 1 | Side Plank | bored and want variety |
| 617 | 1 | Russian Twist | — |
| 618 | 1 | Russian Twist | knee injury |
| 619 | 1 | Russian Twist | shoulder pain |
| 620 | 1 | Russian Twist | lower back pain |
| 621 | 1 | Russian Twist | wrist injury |
| 622 | 1 | Russian Twist | ankle sprain |
| 623 | 1 | Russian Twist | elbow tendinitis |
| 624 | 1 | Russian Twist | hip pain |
| 625 | 1 | Russian Twist | neck strain |
| 626 | 1 | Russian Twist | no equipment available |
| 627 | 1 | Russian Twist | boring |
| 628 | 1 | Russian Twist | pregnant — second trimester |
| 629 | 1 | Russian Twist | post-surgery rehab |
| 630 | 1 | Russian Twist | bored and want variety |
| 631 | 1 | Hanging Leg Raise | — |
| 632 | 1 | Hanging Leg Raise | knee injury |
| 633 | 1 | Hanging Leg Raise | shoulder pain |
| 634 | 1 | Hanging Leg Raise | lower back pain |
| 635 | 1 | Hanging Leg Raise | wrist injury |
| 636 | 1 | Hanging Leg Raise | ankle sprain |
| 637 | 1 | Hanging Leg Raise | elbow tendinitis |
| 638 | 1 | Hanging Leg Raise | hip pain |
| 639 | 1 | Hanging Leg Raise | neck strain |
| 640 | 1 | Hanging Leg Raise | no equipment available |
| 641 | 1 | Hanging Leg Raise | boring |
| 642 | 1 | Hanging Leg Raise | pregnant — second trimester |
| 643 | 1 | Hanging Leg Raise | post-surgery rehab |
| 644 | 1 | Hanging Leg Raise | bored and want variety |
| 645 | 1 | Ab Wheel Rollout | — |
| 646 | 1 | Ab Wheel Rollout | knee injury |
| 647 | 1 | Ab Wheel Rollout | shoulder pain |
| 648 | 1 | Ab Wheel Rollout | lower back pain |
| 649 | 1 | Ab Wheel Rollout | wrist injury |
| 650 | 1 | Ab Wheel Rollout | ankle sprain |
| 651 | 1 | Ab Wheel Rollout | elbow tendinitis |
| 652 | 1 | Ab Wheel Rollout | hip pain |
| 653 | 1 | Ab Wheel Rollout | neck strain |
| 654 | 1 | Ab Wheel Rollout | no equipment available |
| 655 | 1 | Ab Wheel Rollout | boring |
| 656 | 1 | Ab Wheel Rollout | pregnant — second trimester |
| 657 | 1 | Ab Wheel Rollout | post-surgery rehab |
| 658 | 1 | Ab Wheel Rollout | bored and want variety |
| 659 | 1 | Crunch | — |
| 660 | 1 | Crunch | knee injury |
| 661 | 1 | Crunch | shoulder pain |
| 662 | 1 | Crunch | lower back pain |
| 663 | 1 | Crunch | wrist injury |
| 664 | 1 | Crunch | ankle sprain |
| 665 | 1 | Crunch | elbow tendinitis |
| 666 | 1 | Crunch | hip pain |
| 667 | 1 | Crunch | neck strain |
| 668 | 1 | Crunch | no equipment available |
| 669 | 1 | Crunch | boring |
| 670 | 1 | Crunch | pregnant — second trimester |
| 671 | 1 | Crunch | post-surgery rehab |
| 672 | 1 | Crunch | bored and want variety |
| 673 | 1 | Dead Bug | — |
| 674 | 1 | Dead Bug | knee injury |
| 675 | 1 | Dead Bug | shoulder pain |
| 676 | 1 | Dead Bug | lower back pain |
| 677 | 1 | Dead Bug | wrist injury |
| 678 | 1 | Dead Bug | ankle sprain |
| 679 | 1 | Dead Bug | elbow tendinitis |
| 680 | 1 | Dead Bug | hip pain |
| 681 | 1 | Dead Bug | neck strain |
| 682 | 1 | Dead Bug | no equipment available |
| 683 | 1 | Dead Bug | boring |
| 684 | 1 | Dead Bug | pregnant — second trimester |
| 685 | 1 | Dead Bug | post-surgery rehab |
| 686 | 1 | Dead Bug | bored and want variety |
| 687 | 1 | Bird Dog | — |
| 688 | 1 | Bird Dog | knee injury |
| 689 | 1 | Bird Dog | shoulder pain |
| 690 | 1 | Bird Dog | lower back pain |
| 691 | 1 | Bird Dog | wrist injury |
| 692 | 1 | Bird Dog | ankle sprain |
| 693 | 1 | Bird Dog | elbow tendinitis |
| 694 | 1 | Bird Dog | hip pain |
| 695 | 1 | Bird Dog | neck strain |
| 696 | 1 | Bird Dog | no equipment available |
| 697 | 1 | Bird Dog | boring |
| 698 | 1 | Bird Dog | pregnant — second trimester |
| 699 | 1 | Bird Dog | post-surgery rehab |
| 700 | 1 | Bird Dog | bored and want variety |
| 701 | 2 | Burpee | — |
| 702 | 2 | Burpee | knee injury |
| 703 | 2 | Burpee | shoulder pain |
| 704 | 2 | Burpee | lower back pain |
| 705 | 2 | Burpee | wrist injury |
| 706 | 2 | Burpee | ankle sprain |
| 707 | 2 | Burpee | elbow tendinitis |
| 708 | 2 | Box Jump | — |
| 709 | 2 | Box Jump | knee injury |
| 710 | 2 | Box Jump | shoulder pain |
| 711 | 2 | Box Jump | lower back pain |
| 712 | 2 | Box Jump | wrist injury |
| 713 | 2 | Box Jump | ankle sprain |
| 714 | 2 | Box Jump | elbow tendinitis |
| 715 | 2 | Mountain Climber | — |
| 716 | 2 | Mountain Climber | knee injury |
| 717 | 2 | Mountain Climber | shoulder pain |
| 718 | 2 | Mountain Climber | lower back pain |
| 719 | 2 | Mountain Climber | wrist injury |
| 720 | 2 | Mountain Climber | ankle sprain |
| 721 | 2 | Mountain Climber | elbow tendinitis |
| 722 | 2 | Jumping Jacks | — |
| 723 | 2 | Jumping Jacks | knee injury |
| 724 | 2 | Jumping Jacks | shoulder pain |
| 725 | 2 | Jumping Jacks | lower back pain |
| 726 | 2 | Jumping Jacks | wrist injury |
| 727 | 2 | Jumping Jacks | ankle sprain |
| 728 | 2 | Jumping Jacks | elbow tendinitis |
| 729 | 2 | High Knees | — |
| 730 | 2 | High Knees | knee injury |
| 731 | 2 | High Knees | shoulder pain |
| 732 | 2 | High Knees | lower back pain |
| 733 | 2 | High Knees | wrist injury |
| 734 | 2 | High Knees | ankle sprain |
| 735 | 2 | High Knees | elbow tendinitis |
| 736 | 2 | Skater Jumps | — |
| 737 | 2 | Skater Jumps | knee injury |
| 738 | 2 | Skater Jumps | shoulder pain |
| 739 | 2 | Skater Jumps | lower back pain |
| 740 | 2 | Skater Jumps | wrist injury |
| 741 | 2 | Skater Jumps | ankle sprain |
| 742 | 2 | Skater Jumps | elbow tendinitis |
| 743 | 2 | Battle Ropes | — |
| 744 | 2 | Battle Ropes | knee injury |
| 745 | 2 | Battle Ropes | shoulder pain |
| 746 | 2 | Battle Ropes | lower back pain |
| 747 | 2 | Battle Ropes | wrist injury |
| 748 | 2 | Battle Ropes | ankle sprain |
| 749 | 2 | Battle Ropes | elbow tendinitis |
| 750 | 2 | Jump Rope | — |
| 751 | 2 | Jump Rope | knee injury |
| 752 | 2 | Jump Rope | shoulder pain |
| 753 | 2 | Jump Rope | lower back pain |
| 754 | 2 | Jump Rope | wrist injury |
| 755 | 2 | Jump Rope | ankle sprain |
| 756 | 2 | Jump Rope | elbow tendinitis |
| 757 | 2 | Power Clean | — |
| 758 | 2 | Power Clean | knee injury |
| 759 | 2 | Power Clean | shoulder pain |
| 760 | 2 | Power Clean | lower back pain |
| 761 | 2 | Power Clean | wrist injury |
| 762 | 2 | Power Clean | ankle sprain |
| 763 | 2 | Power Clean | elbow tendinitis |
| 764 | 2 | Snatch | — |
| 765 | 2 | Snatch | knee injury |
| 766 | 2 | Snatch | shoulder pain |
| 767 | 2 | Snatch | lower back pain |
| 768 | 2 | Snatch | wrist injury |
| 769 | 2 | Snatch | ankle sprain |
| 770 | 2 | Snatch | elbow tendinitis |
| 771 | 2 | Clean and Jerk | — |
| 772 | 2 | Clean and Jerk | knee injury |
| 773 | 2 | Clean and Jerk | shoulder pain |
| 774 | 2 | Clean and Jerk | lower back pain |
| 775 | 2 | Clean and Jerk | wrist injury |
| 776 | 2 | Clean and Jerk | ankle sprain |
| 777 | 2 | Clean and Jerk | elbow tendinitis |
| 778 | 2 | Push Press | — |
| 779 | 2 | Push Press | knee injury |
| 780 | 2 | Push Press | shoulder pain |
| 781 | 2 | Push Press | lower back pain |
| 782 | 2 | Push Press | wrist injury |
| 783 | 2 | Push Press | ankle sprain |
| 784 | 2 | Push Press | elbow tendinitis |
| 785 | 2 | Kettlebell Swing | — |
| 786 | 2 | Kettlebell Swing | knee injury |
| 787 | 2 | Kettlebell Swing | shoulder pain |
| 788 | 2 | Kettlebell Swing | lower back pain |
| 789 | 2 | Kettlebell Swing | wrist injury |
| 790 | 2 | Kettlebell Swing | ankle sprain |
| 791 | 2 | Kettlebell Swing | elbow tendinitis |
| 792 | 2 | Turkish Get-Up | — |
| 793 | 2 | Turkish Get-Up | knee injury |
| 794 | 2 | Turkish Get-Up | shoulder pain |
| 795 | 2 | Turkish Get-Up | lower back pain |
| 796 | 2 | Turkish Get-Up | wrist injury |
| 797 | 2 | Turkish Get-Up | ankle sprain |
| 798 | 2 | Turkish Get-Up | elbow tendinitis |
| 799 | 2 | Pigeon Pose | — |
| 800 | 2 | Pigeon Pose | knee injury |
| 801 | 2 | Pigeon Pose | shoulder pain |
| 802 | 2 | Pigeon Pose | lower back pain |
| 803 | 2 | Pigeon Pose | wrist injury |
| 804 | 2 | Pigeon Pose | ankle sprain |
| 805 | 2 | Pigeon Pose | elbow tendinitis |
| 806 | 2 | Downward Dog | — |
| 807 | 2 | Downward Dog | knee injury |
| 808 | 2 | Downward Dog | shoulder pain |
| 809 | 2 | Downward Dog | lower back pain |
| 810 | 2 | Downward Dog | wrist injury |
| 811 | 2 | Downward Dog | ankle sprain |
| 812 | 2 | Downward Dog | elbow tendinitis |
| 813 | 2 | Cat Cow | — |
| 814 | 2 | Cat Cow | knee injury |
| 815 | 2 | Cat Cow | shoulder pain |
| 816 | 2 | Cat Cow | lower back pain |
| 817 | 2 | Cat Cow | wrist injury |
| 818 | 2 | Cat Cow | ankle sprain |
| 819 | 2 | Cat Cow | elbow tendinitis |
| 820 | 2 | Couch Stretch | — |
| 821 | 2 | Couch Stretch | knee injury |
| 822 | 2 | Couch Stretch | shoulder pain |
| 823 | 2 | Couch Stretch | lower back pain |
| 824 | 2 | Couch Stretch | wrist injury |
| 825 | 2 | Couch Stretch | ankle sprain |
| 826 | 2 | Couch Stretch | elbow tendinitis |
| 827 | 2 | Worlds Greatest Stretch | — |
| 828 | 2 | Worlds Greatest Stretch | knee injury |
| 829 | 2 | Worlds Greatest Stretch | shoulder pain |
| 830 | 2 | Worlds Greatest Stretch | lower back pain |
| 831 | 2 | Worlds Greatest Stretch | wrist injury |
| 832 | 2 | Worlds Greatest Stretch | ankle sprain |
| 833 | 2 | Worlds Greatest Stretch | elbow tendinitis |
| 834 | 2 | Thread the Needle | — |
| 835 | 2 | Thread the Needle | knee injury |
| 836 | 2 | Thread the Needle | shoulder pain |
| 837 | 2 | Thread the Needle | lower back pain |
| 838 | 2 | Thread the Needle | wrist injury |
| 839 | 2 | Thread the Needle | ankle sprain |
| 840 | 2 | Thread the Needle | elbow tendinitis |
| 841 | 2 | Hip Flexor Stretch | — |
| 842 | 2 | Hip Flexor Stretch | knee injury |
| 843 | 2 | Hip Flexor Stretch | shoulder pain |
| 844 | 2 | Hip Flexor Stretch | lower back pain |
| 845 | 2 | Hip Flexor Stretch | wrist injury |
| 846 | 2 | Hip Flexor Stretch | ankle sprain |
| 847 | 2 | Hip Flexor Stretch | elbow tendinitis |
| 848 | 2 | 90/90 Stretch | — |
| 849 | 2 | 90/90 Stretch | knee injury |
| 850 | 2 | 90/90 Stretch | shoulder pain |
| 851 | 2 | 90/90 Stretch | lower back pain |
| 852 | 2 | 90/90 Stretch | wrist injury |
| 853 | 2 | 90/90 Stretch | ankle sprain |
| 854 | 2 | 90/90 Stretch | elbow tendinitis |
| 855 | 2 | Hip Thrust | — |
| 856 | 2 | Hip Thrust | knee injury |
| 857 | 2 | Hip Thrust | shoulder pain |
| 858 | 2 | Hip Thrust | lower back pain |
| 859 | 2 | Hip Thrust | wrist injury |
| 860 | 2 | Hip Thrust | ankle sprain |
| 861 | 2 | Hip Thrust | elbow tendinitis |
| 862 | 2 | Glute Bridge | — |
| 863 | 2 | Glute Bridge | knee injury |
| 864 | 2 | Glute Bridge | shoulder pain |
| 865 | 2 | Glute Bridge | lower back pain |
| 866 | 2 | Glute Bridge | wrist injury |
| 867 | 2 | Glute Bridge | ankle sprain |
| 868 | 2 | Glute Bridge | elbow tendinitis |
| 869 | 2 | Cable Pull-Through | — |
| 870 | 2 | Cable Pull-Through | knee injury |
| 871 | 2 | Cable Pull-Through | shoulder pain |
| 872 | 2 | Cable Pull-Through | lower back pain |
| 873 | 2 | Cable Pull-Through | wrist injury |
| 874 | 2 | Cable Pull-Through | ankle sprain |
| 875 | 2 | Cable Pull-Through | elbow tendinitis |
| 876 | 2 | Single-Leg RDL | — |
| 877 | 2 | Single-Leg RDL | knee injury |
| 878 | 2 | Single-Leg RDL | shoulder pain |
| 879 | 2 | Single-Leg RDL | lower back pain |
| 880 | 2 | Single-Leg RDL | wrist injury |
| 881 | 2 | Single-Leg RDL | ankle sprain |
| 882 | 2 | Single-Leg RDL | elbow tendinitis |
| 883 | 2 | Cossack Squat | — |
| 884 | 2 | Cossack Squat | knee injury |
| 885 | 2 | Cossack Squat | shoulder pain |
| 886 | 2 | Cossack Squat | lower back pain |
| 887 | 2 | Cossack Squat | wrist injury |
| 888 | 2 | Cossack Squat | ankle sprain |
| 889 | 2 | Cossack Squat | elbow tendinitis |
| 890 | 2 | Step-Up | — |
| 891 | 2 | Step-Up | knee injury |
| 892 | 2 | Step-Up | shoulder pain |
| 893 | 2 | Step-Up | lower back pain |
| 894 | 2 | Step-Up | wrist injury |
| 895 | 2 | Step-Up | ankle sprain |
| 896 | 2 | Step-Up | elbow tendinitis |
| 897 | 2 | Reverse Lunge | — |
| 898 | 2 | Reverse Lunge | knee injury |
| 899 | 2 | Reverse Lunge | shoulder pain |
| 900 | 2 | Reverse Lunge | lower back pain |
| 901 | 3 | Squet | — |
| 902 | 3 | Bicep Curlz | — |
| 903 | 3 | Made Up Move | — |
| 904 | 3 | ABCDEFG | — |
| 905 | 3 | Random Exercise 1 | — |
| 906 | 3 | Random Exercise 2 | — |
| 907 | 3 | Random Exercise 3 | — |
| 908 | 3 | test | — |
| 909 | 3 | TEST | — |
| 910 | 3 | TeSt MoVe | — |
| 911 | 3 |  Squat  | — |
| 912 | 3 |   Bench Press   | — |
| 913 | 3 | BENCH PRESS | — |
| 914 | 3 | bench press | — |
| 915 | 3 | Bench  Press | — |
| 916 | 3 | PUSH-UP | — |
| 917 | 3 | push-up | — |
| 918 | 3 | Push Up | — |
| 919 | 3 | Pushup | — |
| 920 | 3 | push up | — |
| 921 | 3 | Squat! | — |
| 922 | 3 | Bench-Press | — |
| 923 | 3 | Bench/Press | — |
| 924 | 3 | Bench (Press) | — |
| 925 | 3 | Bench Press 3x10 | — |
| 926 | 3 | Bench Press @ 80% | — |
| 927 | 3 | Squat 5x5 | — |
| 928 | 3 | 스쿼트 | — |
| 929 | 3 | ベンチプレス | — |
| 930 | 3 | Squat 💪 | — |
| 931 | 3 | Squat™ | — |
| 932 | 3 | Café Curl | — |
| 933 | 3 | AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA | — |
| 934 | 3 | Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat Squat  | — |
| 935 | 3 | The Most Amazing Exercise Of All Time Ever Invented | — |
| 936 | 3 | S | — |
| 937 | 3 | Sq | — |
| 938 | 3 | Squ | — |
| 939 | 3 | Squat Variation A | — |
| 940 | 3 | Squat Variation B | — |
| 941 | 3 | Bench Press Variant | — |
| 942 | 3 | Power Snatch | — |
| 943 | 3 | Hang Clean | — |
| 944 | 3 | Front Rack Lunge | — |
| 945 | 3 | Sandbag Carry | — |
| 946 | 3 | Atlas Stone Lift | — |
| 947 | 3 | Tire Flip | — |
| 948 | 3 | Wall Push-Up | — |
| 949 | 3 | Knee Push-Up | — |
| 950 | 3 | Incline Push-Up | — |
| 951 | 4 | Negative Pull-Up | knee injury |
| 952 | 4 | Assisted Pull-Up | shoulder pain |
| 953 | 4 | Band Pull-Up | lower back pain |
| 954 | 4 | Single-Arm Row | wrist injury |
| 955 | 4 | Single-Leg Bridge | ankle sprain |
| 956 | 4 | Single-Arm Press | hip pain |
| 957 | 4 | Tempo Squat | knee injury |
| 958 | 4 | Pause Bench | shoulder pain |
| 959 | 4 | Slow Push-Up | lower back pain |
| 960 | 4 | I want to do something | wrist injury |
| 961 | 4 | anything for chest | ankle sprain |
| 962 | 4 | Warrior 1 | hip pain |
| 963 | 4 | Warrior 2 | knee injury |
| 964 | 4 | Warrior 3 | shoulder pain |
| 965 | 4 | Sun Salutation A | lower back pain |
| 966 | 4 | Sun Salutation B | wrist injury |
| 967 | 4 | Pilates Hundred | ankle sprain |
| 968 | 4 | Roll-Up | hip pain |
| 969 | 4 | Single Leg Stretch | knee injury |
| 970 | 4 | Dedlift | shoulder pain |
| 971 | 4 | Skuat | lower back pain |
| 972 | 4 | Beanch Press | wrist injury |
| 973 | 4 | Pulup | ankle sprain |
| 974 | 4 | Chinup | hip pain |
| 975 | 4 | Squat 1 | knee injury |
| 976 | 4 | Squat 2 | shoulder pain |
| 977 | 4 | Squat 100 | lower back pain |
| 978 | 4 | Squat 5kg | wrist injury |
| 979 | 4 | Squat 50lb | ankle sprain |
| 980 | 4 | Bench 135 | hip pain |
| 981 | 5 | Barbell Back Squat | knee injury |
| 982 | 5 | Conventional Deadlift | lower back pain |
| 983 | 5 | Barbell Bench Press | shoulder pain |
| 984 | 5 | Overhead Press | shoulder pain |
| 985 | 5 | Pull-Up | elbow tendinitis |
| 986 | 5 | Push-Up | wrist injury |
| 987 | 5 | Box Jump | ankle sprain |
| 988 | 5 | Burpee | knee injury |
| 989 | 5 | Bicep Curl | elbow tendinitis |
| 990 | 5 | Calf Raise | ankle sprain |
| 991 | 5 | Plank | lower back pain |
| 992 | 5 | Russian Twist | lower back pain |
| 993 | 5 | Mountain Climber | wrist injury |
| 994 | 5 | Dips | shoulder pain |
| 995 | 5 | Pistol Squat | knee injury |
| 996 | 5 | Romanian Deadlift | lower back pain |
| 997 | 5 | Sumo Deadlift | hip pain |
| 998 | 5 | Hanging Leg Raise | shoulder pain |
| 999 | 5 | Walking Lunges | knee injury |
| 1000 | 5 | Crunch | neck strain |
