# Hyper-Regional Indian Foods — Nutrition Research

**Generated:** 2026-04-13 via 5-agent Sonnet swarm
**Rows:** 1000 unique hyper-regional Indian dishes with full 34-column nutrition
**Target table:** `food_nutrition_overrides` (Supabase project `hpbzfahijszqmgsybuor`)
**Idempotency tag:** every row has `hyperregional-apr2026` in `notes`

## Regional coverage

| Part | Region | Agent | Rows |
|------|--------|-------|------|
| 1 | Karnataka + Tamil Nadu | Sonnet | 200 |
| 2 | Kerala + Andhra/Telangana + Hyderabadi | Sonnet | 200 |
| 3 | Bengali + Odia + Assamese + North-East | Sonnet | 200 |
| 4 | Gujarati + Maharashtrian + Goan + Rajasthani | Sonnet | 200 |
| 5 | Punjabi + Kashmiri + Awadhi + UP/Bihar/Haryana/Delhi | Sonnet | 200 |

## Companion files

- **SQL file:** `food_nutrition_hyperregional_indian.sql` — apply this to the DB
- **Raw parts:** (removed after merge) — `_hyperregional_parts/part[1-5].md`

## Verification queries

```sql
SELECT COUNT(*) FROM food_nutrition_overrides WHERE notes LIKE '%hyperregional-apr2026%';
-- Expected: 1000

SELECT country_name, region, COUNT(*) FROM food_nutrition_overrides
WHERE notes LIKE '%hyperregional-apr2026%' GROUP BY country_name, region;
```

## Table of contents (grouped by region)


### South India (400 rows)

- `plain_appam_palappam_indian`
- `egg_appam_indian`
- `sweet_coconut_appam_indian`
- `appam_coconut_milk_stew_bundle_indian`
- `plain_puttu_indian`
- `puttu_kadala_curry_bundle_indian`
- `wheat_puttu_indian`
- `ragi_puttu_indian`
- `meen_moilee_plain_indian`
- `meen_moilee_rich_coconut_indian`
- `meen_moilee_appam_bundle_indian`
- `alleppey_fish_curry_raw_mango_indian`
- `alleppey_prawn_curry_indian`
- `alleppey_fish_curry_coconut_heavy_indian`
- `kerala_beef_ularthiyathu_indian`
- `kerala_beef_fry_coconut_oil_indian`
- `kerala_beef_roast_dry_masala_indian`
- `nadan_kozhi_curry_indian`
- `kozhi_varutharacha_curry_indian`
- `pidi_kozhi_kerala_indian`
- `malabar_parotta_plain_indian`
- `malabar_parotta_beef_curry_indian`
- `malabar_parotta_egg_curry_indian`
- `thalassery_mutton_dum_biryani_indian`
- `thalassery_chicken_dum_biryani_indian`
- `kallappam_plain_indian`
- `kallappam_egg_indian`
- `kerala_ishtu_vegetable_indian`
- `kerala_ishtu_chicken_indian`
- `kerala_ishtu_mutton_indian`
- `avial_kerala_plain_indian`
- `avial_extra_coconut_indian`
- `olan_plain_indian`
- `olan_blackeyed_peas_indian`
- `kaalan_raw_banana_indian`
- `kaalan_yam_indian`
- `erissery_pumpkin_coconut_indian`
- `erissery_raw_banana_indian`
- `cabbage_thoran_kerala_indian`
- `beans_thoran_kerala_indian`
- `beetroot_thoran_kerala_indian`
- `raw_banana_thoran_kerala_indian`
- `ada_pradhaman_kerala_indian`
- `parippu_payasam_kerala_indian`
- `palada_payasam_kerala_indian`
- `paal_payasam_rich_kerala_indian`
- `unniyappam_plain_kerala_indian`
- `unniyappam_banana_kerala_indian`
- `palada_milk_dessert_kerala_indian`
- `kerala_banana_chips_coconut_oil_indian`
- `kerala_banana_chips_salt_chilli_indian`
- `pesarattu_plain_andhra_indian`
- `pesarattu_ginger_chutney_indian`
- `mla_pesarattu_upma_stuffed_indian`
- `gongura_fish_curry_andhra_indian`
- `gongura_prawn_curry_andhra_indian`
- `andhra_chepala_pulusu_tamarind_indian`
- `chepala_pulusu_rohu_indian`
- `royyala_iguru_andhra_masala_indian`
- `royyala_iguru_coconut_andhra_indian`
- `natu_kodi_pulusu_andhra_indian`
- `natu_kodi_pulusu_sesame_andhra_indian`
- `kodi_vepudu_andhra_bone_indian`
- `kodi_vepudu_boneless_andhra_indian`
- `guntur_chicken_curry_spicy_indian`
- `guntur_chicken_fry_andhra_indian`
- `ulavacharu_chicken_curry_indian`
- `ulavacharu_mutton_curry_indian`
- `andhra_pulihora_tamarind_rice_indian`
- `andhra_pulihora_sesame_indian`
- `bagara_baingan_andhra_indian`
- `gutti_vankaya_kura_andhra_indian`
- `gutti_vankaya_sesame_peanut_indian`
- `dondakaya_fry_andhra_indian`
- `dondakaya_palli_kura_indian`
- `tomato_pappu_andhra_indian`
- `palakoora_pappu_andhra_indian`
- `dosakaya_pappu_andhra_indian`
- `pappu_charu_andhra_indian`
- `pachi_pulusu_andhra_indian`
- `andhra_sakinalu_snack_indian`
- `pootharekulu_plain_andhra_indian`
- `pootharekulu_ghee_jaggery_indian`
- `kobbari_annam_fresh_andhra_indian`
- `daddojanam_plain_curd_rice_indian`
- `daddojanam_spiced_andhra_indian`
- `punugulu_plain_andhra_indian`
- `punugulu_onion_chilli_andhra_indian`
- `maagaya_andhra_raw_mango_pickle_indian`
- `avakaya_fresh_unaged_andhra_indian`
- `hyderabadi_mutton_kacchi_dum_biryani_indian`
- `hyderabadi_mutton_pakki_biryani_indian`
- `hyderabadi_chicken_dum_plain_biryani_indian`
- `hyderabadi_egg_dum_biryani_plain_indian`
- `hyderabadi_veg_dum_biryani_plain_indian`
- `hyderabadi_prawn_dum_biryani_plain_indian`
- `hyderabadi_mutton_haleem_plain_indian`
- `hyderabadi_chicken_haleem_plain_indian`
- `hyderabadi_mixed_haleem_indian`
- `pathar_ka_gosht_hyderabadi_indian`
- `dum_ka_murgh_whole_hyderabadi_indian`
- `dum_ka_murgh_boneless_hyderabadi_indian`
- `murgh_kali_mirch_hyderabadi_plain_indian`
- `murgh_kali_mirch_rich_gravy_hyderabadi_indian`
- `baghare_baingan_hyderabadi_plain_indian`
- `baghare_baingan_tamarind_heavy_indian`
- `khatti_dal_hyderabadi_plain_indian`
- `khatti_dal_spinach_hyderabadi_indian`
- `tala_hua_gosht_plain_hyderabadi_indian`
- `tala_hua_gosht_liver_hyderabadi_indian`
- `shikampuri_kebab_plain_hyderabadi_indian`
- `shikampuri_kebab_paneer_hyderabadi_indian`
- `tahari_vegetable_hyderabadi_indian`
- `tahari_mutton_hyderabadi_indian`
- `mutton_marag_plain_hyderabadi_indian`
- `mutton_marag_spiced_hyderabadi_indian`
- `dalcha_lamb_lentil_hyderabadi_indian`
- `dalcha_vegetarian_hyderabadi_indian`
- `khubani_ka_meetha_plain_hyderabadi_indian`
- `khubani_ka_meetha_cream_hyderabadi_indian`
- `sheer_khurma_plain_hyderabadi_indian`
- `sheer_khurma_rich_nuts_hyderabadi_indian`
- `hyderabadi_mutton_kofta_curry_indian`
- `hyderabadi_chicken_kofta_curry_indian`
- `paradise_biryani_prawn_hyderabadi_indian`
- `shah_ghouse_mutton_haleem_indian`
- `hyderabadi_fish_dum_biryani_indian`
- `hyderabadi_mirchi_ka_salan_plain_indian`
- `hyderabadi_mirchi_ka_salan_peanut_indian`
- `double_ka_meetha_plain_hyderabadi_indian`
- `double_ka_meetha_rabri_hyderabadi_indian`
- `kerala_sadya_matta_rice_indian`
- `kerala_sadya_full_plate_bundle_indian`
- `nei_payasam_ghee_kerala_indian`
- `nei_payasam_rice_based_kerala_indian`
- `kerala_meen_curry_coconut_oil_kodampuli_indian`
- `kerala_meen_curry_tamarind_base_indian`
- `chemeen_biryani_kerala_plain_indian`
- `chemeen_biryani_malabar_style_indian`
- `kerala_prawn_theeyal_indian`
- `kerala_fish_theeyal_indian`
- `karimeen_pollichathu_plain_kerala_indian`
- `karimeen_pollichathu_spicy_kerala_indian`
- `kerala_mutton_stew_coconut_milk_indian`
- `kerala_mutton_stew_appam_bundle_indian`
- `andhra_fish_biryani_rohu_indian`
- `andhra_fish_biryani_pomfret_indian`
- `andhra_egg_pulusu_curry_indian`
- `andhra_egg_curry_dry_indian`
- `telangana_chicken_gongura_curry_indian`
- `telangana_mutton_curry_spicy_indian`
- `telangana_mutton_pulusu_indian`
- `hyderabadi_lukhmi_minced_meat_indian`
- `hyderabadi_lukhmi_chicken_indian`
- `hyderabadi_nihari_beef_indian`
- `hyderabadi_nihari_mutton_indian`
- `hyderabadi_paya_trotter_soup_indian`
- `hyderabadi_paya_roti_bundle_indian`
- `andhra_gongura_mutton_biryani_indian`
- `andhra_gongura_chicken_biryani_indian`
- `kerala_beef_mappas_coconut_milk_indian`
- `kerala_beef_mappas_appam_bundle_indian`
- `andhra_royyalu_biryani_plain_indian`
- `andhra_royyalu_biryani_spicy_indian`
- `kerala_neimeen_seer_fish_curry_indian`
- `kerala_neimeen_tawa_fry_indian`
- `kerala_chemmeen_ularthiyathu_indian`
- `kerala_chemmeen_masala_roast_indian`
- `hyderabadi_chicken65_restaurant_indian`
- `hyderabadi_chicken65_boneless_indian`
- `andhra_nattu_kodi_vepudu_dry_indian`
- `andhra_nattu_kodi_vepudu_bone_indian`
- `kerala_kappa_biryani_plain_indian`
- `kerala_kappa_biryani_beef_indian`
- `andhra_pesara_garelu_plain_indian`
- `andhra_pesara_garelu_coconut_chutney_indian`
- `hyderabadi_lamb_shorba_indian`
- `hyderabadi_chicken_shorba_indian`
- `kerala_kozhi_nirachathu_plain_indian`
- `kerala_kozhi_nirachathu_gravy_indian`
- `andhra_boti_intestine_curry_indian`
- `andhra_boti_dry_fry_indian`
- `hyderabadi_baingan_chutney_indian`
- `hyderabadi_tomato_chutney_indian`
- `kerala_ada_plain_rice_pancake_indian`
- `kerala_ada_banana_jaggery_stuffed_indian`
- `atukulu_upma_andhra_plain_indian`
- `atukulu_upma_vegetables_andhra_indian`
- `thalassery_fish_biryani_plain_indian`
- `thalassery_fish_biryani_pomfret_indian`
- `hyderabadi_mutton_qorma_indian`
- `hyderabadi_chicken_qorma_indian`
- `andhra_crab_curry_peetha_indian`
- `andhra_crab_masala_dry_indian`
- `kerala_tuna_curry_choora_indian`
- `kerala_tuna_fry_choora_indian`
- `hyderabadi_gosht_everyday_curry_indian`
- `hyderabadi_gosht_masala_dry_indian`
- `kerala_papadum_unfried_indian`
- `kerala_papadum_fried_coconut_oil_indian`
- `udupi_masala_dosa_indian`
- `udupi_brahmin_sambar_indian`
- `karnataka_saaru_indian`
- `mangalore_biryani_indian`
- `karnataka_veg_pulao_indian`
- `coorg_bamboo_shoot_curry_indian`
- `coorg_chicken_curry_noolputtu_indian`
- `maddur_vada_karnataka_indian`
- `karnataka_set_dosa_indian`
- `karnataka_set_dosa_saagu_indian`
- `chettinad_egg_curry_indian`
- `chettinad_paneer_kuzhambu_indian`
- `tamilnadu_chicken_65_indian`
- `keerai_kootu_tamilnadu_indian`
- `murungai_sambar_tamilnadu_indian`
- `vengaya_sambar_tamilnadu_indian`
- `tamilnadu_rasam_indian`
- `tomato_rasam_tamilnadu_indian`
- `kara_kuzhambu_tamilnadu_indian`
- `mor_kuzhambu_tamilnadu_indian`
- `beans_poriyal_tamilnadu_indian`
- `cabbage_poriyal_tamilnadu_indian`
- `vanjaram_fish_fry_indian`
- `karuvadu_kuzhambu_indian`
- `eral_masala_tamilnadu_indian`
- `paal_kozhukattai_kongunadu_indian`
- `kozhukattai_savory_tamilnadu_indian`
- `ven_pongal_tamilnadu_indian`
- `sakkarai_pongal_tamilnadu_indian`
- `uppu_kozhukattai_tamilnadu_indian`
- `karnataka_paddu_indian`
- `karnataka_paddu_chutney_indian`
- `rava_idli_karnataka_indian`
- `rava_idli_with_sambar_indian`
- `shavige_bath_karnataka_indian`
- `akki_shavige_karnataka_indian`
- `karnataka_puliyogare_indian`
- `vangi_bath_karnataka_indian`
- `palak_thovve_karnataka_indian`
- `hesaru_kalu_palya_karnataka_indian`
- `paal_payasam_tamilnadu_indian`
- `semiya_payasam_tamilnadu_indian`
- `kesari_tamilnadu_indian`
- `tirunelveli_halwa_indian`
- `madurai_kari_dosa_indian`
- `paruthi_paal_tamilnadu_indian`
- `sol_kadhi_karnataka_indian`
- `ragi_kanji_karnataka_indian`
- `puli_inji_tamilnadu_indian`
- `thambuli_karnataka_indian`
- `mosaru_bajji_karnataka_indian`
- `mangalore_buns_indian`
- `mangalore_buns_chutney_indian`
- `karwar_prawn_curry_indian`
- `tisrya_sukka_karnataka_indian`
- `ragi_sangati_karnataka_indian`
- `soppina_saaru_karnataka_indian`
- `nuchinunde_karnataka_indian`
- `tuppa_dosa_karnataka_indian`
- `ambode_karnataka_indian`
- `paruppusili_tamilnadu_indian`
- `kathirikai_gothsu_tamilnadu_indian`
- `avial_tamilnadu_indian`
- `tamilnadu_chicken_varuval_indian`
- `mutton_sukka_tamilnadu_indian`
- `tamilnadu_home_chicken_biryani_indian`
- `tamilnadu_egg_biryani_indian`
- `tamilnadu_veg_biryani_indian`
- `chettinad_veg_biryani_indian`
- `kola_urundai_tamilnadu_indian`
- `vaazhaipoo_kootu_tamilnadu_indian`
- `raw_jackfruit_biryani_tamilnadu_indian`
- `sambar_drumstick_brinjal_tamilnadu_indian`
- `majjige_huli_karnataka_indian`
- `karnataka_gojju_indian`
- `chutney_pudi_karnataka_indian`
- `ragi_ladoo_karnataka_indian`
- `holige_with_ghee_indian`
- `veg_uttapam_karnataka_indian`
- `onion_uttapam_tamilnadu_indian`
- `tomato_uttapam_tamilnadu_indian`
- `godhuma_dosa_karnataka_indian`
- `neer_dosa_fish_curry_indian`
- `mangalore_soorna_curry_indian`
- `chettinad_black_rice_halwa_indian`
- `kongunadu_kaalaan_kulambu_indian`
- `ambur_prawn_biryani_indian`
- `chettinad_nandu_masala_indian`
- `hayagreeva_maddi_karnataka_indian`
- `mysore_chitranna_indian`
- `idiyappam_sweet_coconut_milk_indian`
- `vazhaipazham_bajji_tamilnadu_indian`
- `saggubiyyam_upma_karnataka_indian`
- `meen_puttu_tamilnadu_indian`
- `kollu_rasam_tamilnadu_indian`
- `kollu_sambar_tamilnadu_indian`
- `bele_saaru_karnataka_indian`
- `keerai_vadai_tamilnadu_indian`
- `dindigul_egg_biryani_indian`
- `chettinad_idiyappam_indian`
- `chicken_donne_biryani_indian`
- `chicken_boneless_donne_biryani_indian`
- `mutton_donne_biryani_indian`
- `egg_donne_biryani_indian`
- `veg_donne_biryani_indian`
- `mylari_dosa_plain_indian`
- `mylari_dosa_ghee_indian`
- `mylari_dosa_masala_indian`
- `mylari_dosa_butter_indian`
- `ragi_mudde_with_mutton_curry_indian`
- `ragi_mudde_with_palya_indian`
- `ragi_mudde_with_chicken_saaru_indian`
- `ragi_ball_plain_indian`
- `ragi_roti_indian`
- `ragi_dosa_onion_indian`
- `ragi_dosa_egg_indian`
- `neer_dosa_with_coconut_chutney_indian`
- `neer_dosa_kori_rotti_curry_indian`
- `kori_rotti_indian`
- `kori_rotti_mutton_indian`
- `mangalore_ghee_roast_chicken_indian`
- `mangalore_ghee_roast_mutton_indian`
- `mangalore_ghee_roast_prawns_indian`
- `mangalore_fish_curry_with_neer_dosa_indian`
- `udupi_goli_baje_indian`
- `kosambari_karnataka_indian`
- `jolada_rotti_indian`
- `jolada_rotti_with_ennegayi_indian`
- `uppittu_karnataka_indian`
- `uppittu_with_vegetables_indian`
- `chiroti_karnataka_indian`
- `holige_obbattu_indian`
- `holige_coconut_filling_indian`
- `thatte_idli_indian`
- `thatte_idli_with_sambar_indian`
- `kundapura_chicken_indian`
- `kundapura_chicken_neer_dosa_indian`
- `koli_saaru_karnataka_indian`
- `koli_saaru_with_ragi_mudde_indian`
- `chow_chow_bath_indian`
- `khara_bath_bangalore_indian`
- `kesari_bath_bangalore_indian`
- `bisi_bele_bath_with_papad_indian`
- `bisi_bele_bath_ghee_indian`
- `coorg_pandi_curry_neer_dosa_indian`
- `coorg_kachampuli_pandi_curry_indian`
- `akki_roti_with_onion_chilli_indian`
- `akki_roti_coconut_dill_indian`
- `benne_dosa_potato_palya_indian`
- `davangere_benne_dosa_indian`
- `chettinad_pepper_chicken_indian`
- `chettinad_fish_curry_indian`
- `chettinad_prawn_masala_indian`
- `chettinad_kavuni_arisi_pudding_indian`
- `kongunadu_mutton_kari_indian`
- `kongunadu_chicken_kari_indian`
- `dindigul_biryani_thalappakatti_indian`
- `dindigul_mutton_biryani_indian`
- `ambur_star_chicken_biryani_indian`
- `ambur_mutton_biryani_indian`
- `karaikudi_chicken_dry_indian`
- `karaikudi_mutton_fry_indian`
- `kuzhi_paniyaram_sweet_indian`
- `kuzhi_paniyaram_savory_indian`
- `idiyappam_with_coconut_milk_indian`
- `idiyappam_with_kurma_indian`
- `idiyappam_with_egg_curry_indian`
- `kothu_parotta_chicken_indian`
- `kothu_parotta_veg_indian`
- `kothu_parotta_mutton_indian`
- `plain_parotta_tamilnadu_indian`
- `ceylon_parotta_indian`
- `parotta_with_chicken_salna_indian`
- `madurai_jigarthanda_indian`
- `kal_dosa_tamilnadu_indian`
- `kal_dosa_with_sambar_indian`
- `adai_tamilnadu_indian`
- `adai_aviyal_tamilnadu_indian`
- `vellam_dosai_indian`
- `meen_kuzhambu_tamilnadu_indian`
- `chettinad_meen_kuzhambu_indian`
- `nethili_fry_tamilnadu_indian`
- `nethili_kuzhambu_indian`
- `vaazhaipoo_vadai_tamilnadu_indian`
- `tamilnadu_rice_murukku_indian`
- `paruppu_murukku_indian`
- `mysore_pak_karnataka_indian`
- `soft_mysore_pak_indian`
- `thalappakatti_veg_biryani_indian`
- `thalappakatti_chicken_biryani_indian`
- `tamilnadu_sambar_rice_indian`
- `thayir_sadam_tamilnadu_indian`
- `puliyodarai_tamilnadu_indian`
- `elumichai_sadam_tamilnadu_indian`
- `thenga_sadam_tamilnadu_indian`
- `kothamalli_chutney_indian`
- `tomato_kothamalli_chutney_indian`
- `peanut_chutney_tamilnadu_indian`
- `vengaya_thakkali_chutney_indian`
- `thengai_chutney_tamilnadu_indian`

### North India (200 rows)

- `sarson_ka_saag_with_ghee_punjabi_indian`
- `sarson_ka_saag_plain_punjabi_indian`
- `sarson_ka_saag_paneer_punjabi_indian`
- `sarson_ka_saag_dhaba_style_punjabi_indian`
- `makki_di_roti_plain_punjabi_indian`
- `makki_di_roti_with_ghee_punjabi_indian`
- `makki_di_roti_thick_village_punjabi_indian`
- `bhatura_classic_punjabi_indian`
- `bhatura_stuffed_paneer_punjabi_indian`
- `amritsari_kulcha_paneer_punjabi_indian`
- `amritsari_kulcha_gobi_punjabi_indian`
- `amritsari_kulcha_keema_punjabi_indian`
- `amritsari_kulcha_plain_butter_punjabi_indian`
- `chicken_chole_punjabi_indian`
- `paneer_chole_punjabi_indian`
- `pindi_chana_rawalpindi_punjabi_indian`
- `amritsari_fish_fry_classic_punjabi_indian`
- `amritsari_fish_fry_mustard_punjabi_indian`
- `tandoori_pomfret_punjabi_indian`
- `seekh_kebab_mutton_punjabi_indian`
- `seekh_kebab_paneer_punjabi_indian`
- `reshmi_kebab_chicken_punjabi_indian`
- `malai_tikka_chicken_punjabi_indian`
- `punjabi_samosa_aloo_indian`
- `punjabi_samosa_keema_indian`
- `pakora_onion_punjabi_indian`
- `pakora_paneer_punjabi_indian`
- `pakora_gobi_punjabi_indian`
- `pakora_mirchi_punjabi_indian`
- `aloo_tikki_punjabi_style_indian`
- `papdi_chaat_punjabi_indian`
- `mango_lassi_punjabi_style_indian`
- `salted_lassi_punjabi_style_indian`
- `mah_di_dal_punjabi_indian`
- `langar_wali_dal_punjabi_indian`
- `dal_makhani_classic_punjabi_indian`
- `dal_makhani_restaurant_style_punjabi_indian`
- `rajma_chawal_kashmiri_rajma_indian`
- `rajma_chitra_himachali_indian`
- `rajma_red_punjabi_classic_indian`
- `butter_chicken_classic_punjabi_indian`
- `butter_chicken_dhaba_style_punjabi_indian`
- `butter_chicken_makhmali_punjabi_indian`
- `tandoori_chicken_full_punjabi_indian`
- `tandoori_chicken_tikka_punjabi_indian`
- `laccha_paratha_punjabi_layered_indian`
- `punjabi_kadhi_pakora_homestyle_indian`
- `patiala_chicken_punjabi_indian`
- `saag_murgh_punjabi_indian`
- `rogan_josh_kashmiri_pandit_indian`
- `rogan_josh_kashmiri_muslim_indian`
- `yakhni_mutton_kashmiri_indian`
- `yakhni_chicken_kashmiri_indian`
- `yakhni_lotus_stem_kashmiri_indian`
- `gushtaba_wazwan_kashmiri_indian`
- `rista_kashmiri_indian`
- `tabak_maaz_fried_ribs_kashmiri_indian`
- `matschgand_kashmiri_minced_mutton_indian`
- `methi_maaz_kashmiri_fenugreek_mutton_indian`
- `kabargah_kashmiri_milk_fried_ribs_indian`
- `aab_gosht_kashmiri_milk_mutton_indian`
- `kashmiri_dum_aloo_pandit_style_indian`
- `nadru_yakhni_kashmiri_lotus_stem_indian`
- `haak_saag_kashmiri_mustard_greens_indian`
- `chaman_kaliya_kashmiri_paneer_indian`
- `nadir_palak_kashmiri_lotus_spinach_indian`
- `nadur_monje_kashmiri_lotus_pakora_indian`
- `monje_haakh_kashmiri_kohlrabi_indian`
- `kashmiri_pulao_saffron_dry_fruits_indian`
- `modur_pulao_sweet_kashmiri_rice_indian`
- `kashmiri_sheermal_saffron_bread_indian`
- `kashmiri_phirni_saffron_clay_indian`
- `shufta_kashmiri_dry_fruit_dessert_indian`
- `kashmiri_harissa_mutton_overnight_indian`
- `wazwan_roghan_josh_feast_kashmiri_indian`
- `wazwan_seekh_platter_kashmiri_indian`
- `galouti_kebab_chicken_lucknowi_indian`
- `galouti_kebab_veg_lucknowi_indian`
- `galouti_kebab_soya_lucknowi_indian`
- `tunday_kebab_mutton_lucknowi_style_indian`
- `shami_kebab_chicken_lucknowi_indian`
- `nargisi_kofta_lucknowi_indian`
- `biryani_awadhi_mutton_lucknowi_indian`
- `biryani_awadhi_chicken_lucknowi_indian`
- `nihari_lucknowi_mutton_slow_cooked_indian`
- `korma_lucknowi_chicken_awadhi_indian`
- `korma_lucknowi_mutton_awadhi_indian`
- `korma_lucknowi_shahi_veg_awadhi_indian`
- `pasanda_mutton_lucknowi_indian`
- `pasanda_chicken_lucknowi_indian`
- `murgh_mussallam_lucknowi_indian`
- `makhan_malai_lucknowi_winter_dessert_indian`
- `nimish_lucknowi_frothy_dessert_indian`
- `kulfi_falooda_lucknowi_indian`
- `zafrani_phirni_lucknowi_saffron_indian`
- `shahi_tukda_lucknowi_awadhi_indian`
- `gilafi_seekh_kebab_lucknowi_indian`
- `khameeri_roti_lucknowi_leavened_indian`
- `roomali_roti_lucknowi_thin_indian`
- `ulte_tawe_ka_paratha_lucknowi_indian`
- `kakori_kebab_mutton_lucknowi_style_indian`
- `litti_chokha_sattu_classic_bihari_indian`
- `litti_chokha_aloo_baingan_bihari_indian`
- `litti_chokha_tomato_bihari_indian`
- `litti_mutton_stuffed_bihari_indian`
- `champaran_mutton_handi_bihari_indian`
- `thekua_bihari_festival_cookie_indian`
- `sattu_paratha_bihari_style_indian`
- `sattu_sherbet_bihari_summer_drink_indian`
- `banarasi_kachori_sabzi_up_indian`
- `banarasi_tamatar_chaat_up_indian`
- `banarasi_dahi_gol_gappe_up_indian`
- `aloo_tikki_banarasi_style_up_indian`
- `peda_mathura_classic_up_indian`
- `old_delhi_nihari_mutton_indian`
- `old_delhi_mutton_korma_indian`
- `haryanvi_bajra_khichdi_winter_indian`
- `singri_ki_sabzi_haryanvi_indian`
- `kachri_ki_sabzi_haryanvi_indian`
- `bathua_raita_haryanvi_indian`
- `banarasi_jalebi_up_style_indian`
- `rasmalai_up_lucknowi_style_indian`
- `gujiya_up_holi_sweet_indian`
- `missi_roti_punjabi_besan_indian`
- `butter_naan_punjabi_tandoor_indian`
- `garlic_naan_punjabi_tandoor_indian`
- `tandoori_pomfret_ajwain_punjabi_indian`
- `punjabi_chicken_curry_dhaba_indian`
- `pinni_punjabi_winter_sweet_indian`
- `punjabi_chicken_keema_indian`
- `rajma_jammu_chikkar_style_indian`
- `paneer_tikka_punjabi_tandoor_indian`
- `paneer_tikka_malai_punjabi_indian`
- `chicken_tikka_masala_punjabi_indian`
- `achari_chicken_punjabi_indian`
- `handi_chicken_punjabi_clay_pot_indian`
- `kashmiri_methi_chicken_indian`
- `kashmiri_dum_aloo_muslim_style_indian`
- `kashmiri_mutton_seekh_kebab_indian`
- `kashmiri_kehwa_saffron_tea_indian`
- `wazwan_tabak_maaz_feast_kashmiri_indian`
- `goshtaba_kashmiri_meatball_indian`
- `wazwan_aab_gosht_kashmiri_indian`
- `shami_kebab_mutton_lucknowi_awadhi_indian`
- `biryani_awadhi_veg_dum_pukht_indian`
- `dahi_kebab_lucknowi_awadhi_indian`
- `sheermal_lucknowi_saffron_bread_indian`
- `warqi_paratha_lucknowi_awadhi_indian`
- `seekh_kebab_lucknowi_mutton_awadhi_indian`
- `biryani_awadhi_egg_lucknowi_indian`
- `malpua_lucknowi_awadhi_rabri_indian`
- `biryani_awadhi_prawn_lucknowi_indian`
- `nihari_lucknowi_with_sheermal_indian`
- `galouti_on_roomali_roti_lucknowi_indian`
- `litti_with_ghee_no_chokha_bihari_indian`
- `bihari_kebab_mutton_skewer_up_indian`
- `shahi_paneer_delhi_mughlai_indian`
- `mutton_biryani_old_delhi_style_indian`
- `aloo_chaat_chandni_chowk_delhi_indian`
- `dahi_bhalla_delhi_up_indian`
- `kachori_delhi_urad_dal_indian`
- `bajra_roti_haryanvi_pearl_millet_indian`
- `chaas_haryanvi_buttermilk_indian`
- `singri_achar_haryanvi_pickle_indian`
- `champaran_chicken_handi_bihari_indian`
- `paan_banarasi_meetha_up_indian`
- `imarti_up_jalebi_cousin_indian`
- `kheer_up_chawal_rice_pudding_indian`
- `suji_halwa_up_semolina_indian`
- `bhang_ki_chutney_up_hemp_indian`
- `bhuna_gosht_delhi_up_indian`
- `delhi_ke_aloo_chatpate_indian`
- `parwal_ki_mithai_up_banarasi_indian`
- `kalakand_up_mathura_style_indian`
- `petha_agra_up_ash_gourd_sweet_indian`
- `bihari_chana_sattu_roasted_flour_indian`
- `arhar_dal_up_tadka_indian`
- `dalmoth_delhi_haldirams_namkeen_indian`
- `kadhi_haryanvi_sour_yogurt_indian`
- `masala_chai_up_kadak_indian`
- `palak_paneer_lucknowi_awadhi_indian`
- `aloo_dum_lucknowi_awadhi_small_potato_indian`
- `gulab_jamun_up_khoya_classic_indian`
- `paneer_pasanda_delhi_mughlai_indian`
- `moong_dal_halwa_up_indian`
- `puri_sabzi_up_breakfast_indian`
- `punjabi_mutton_curry_desi_indian`
- `amritsari_kulcha_onion_punjabi_indian`
- `punjabi_saag_gosht_mustard_mutton_indian`
- `kashmiri_lamb_ribs_tabak_variant_indian`
- `kashmiri_roghan_gosht_dry_spice_indian`
- `lucknowi_kulfi_pista_kesar_indian`
- `lucknowi_kesar_badam_kheer_indian`
- `awadhi_gosht_aloo_curry_indian`
- `bihari_chuda_dahi_flattened_rice_indian`
- `tilkut_magahi_bihari_sesame_sweet_indian`
- `aloo_chokha_bihari_roasted_potato_indian`
- `baingan_chokha_bihari_roasted_eggplant_indian`
- `khichdi_up_arhar_dal_rice_indian`
- `old_delhi_sewaiyan_meethi_indian`

### East India (120 rows)

- `bhapa_ilish_bengali_indian`
- `daab_chingri_bengali_indian`
- `ilish_tel_jhol_bengali_indian`
- `rui_macher_jhol_bengali_indian`
- `katla_macher_jhol_bengali_indian`
- `macher_kalia_rui_bengali_indian`
- `kosha_mangsho_chicken_bengali_indian`
- `kosha_mangsho_veg_bengali_indian`
- `murgir_jhol_bengali_indian`
- `murgir_jhol_narikol_bengali_indian`
- `chingri_malai_curry_bengali_indian`
- `chingri_bhapa_mustard_bengali_indian`
- `luchi_plain_bengali_indian`
- `luchi_aloo_dom_bengali_indian`
- `alur_dom_bengali_spicy_indian`
- `cholar_dal_bengali_indian`
- `begun_bhaja_mustard_bengali_indian`
- `aloo_posto_bengali_indian`
- `jhinge_posto_bengali_indian`
- `shukto_bengali_indian`
- `mochar_ghonto_bengali_indian`
- `kathi_roll_chicken_kolkata_indian`
- `kathi_roll_egg_kolkata_indian`
- `kathi_roll_mutton_kolkata_indian`
- `kathi_roll_paneer_kolkata_indian`
- `kolkata_biryani_mutton_indian`
- `kolkata_biryani_chicken_indian`
- `kolkata_biryani_egg_indian`
- `phuchka_kolkata_indian`
- `rosogolla_bengali_indian`
- `rosogolla_sponge_bengali_indian`
- `sandesh_nolen_gur_bengali_indian`
- `sandesh_plain_bengali_indian`
- `chomchom_bengali_indian`
- `pantua_bengali_indian`
- `langcha_bengali_indian`
- `kheer_kadam_bengali_indian`
- `patishapta_bengali_indian`
- `nolen_gurer_sandesh_bengali_indian`
- `mishti_doi_bengali_indian`
- `dalma_odia_tarkari_indian`
- `dalma_odia_kumro_indian`
- `pakhala_bhata_plain_odia_indian`
- `pakhala_badi_chura_odia_indian`
- `basi_pakhala_odia_indian`
- `chhena_poda_odia_indian`
- `rasagola_odia_indian`
- `macha_besara_odia_indian`
- `macha_ghanta_odia_indian`
- `chhena_gaja_odia_indian`
- `chhena_jhili_odia_indian`
- `poda_pitha_odia_indian`
- `arisa_pitha_odia_indian`
- `enduri_pitha_odia_indian`
- `kakara_pitha_odia_indian`
- `kanika_odia_indian`
- `khechedi_odia_indian`
- `chungdi_malai_odia_indian`
- `dahi_baigana_odia_indian`
- `baigana_bhaja_odia_indian`
- `khatta_odia_indian`
- `masor_tenga_tomato_assam_indian`
- `masor_tenga_outenga_assam_indian`
- `masor_tenga_thekera_assam_indian`
- `khar_assamese_indian`
- `aloo_pitika_assamese_indian`
- `bilahi_aloo_pitika_assam_indian`
- `duck_curry_assamese_indian`
- `hanhor_mangxo_assam_indian`
- `masor_jol_assam_indian`
- `masor_muri_ghonto_assam_indian`
- `xaak_bhaji_assam_indian`
- `gahori_mangxo_assam_indian`
- `bor_mach_curry_assam_indian`
- `til_pitha_assam_indian`
- `narikol_pitha_assam_indian`
- `paayoxh_assam_indian`
- `jolpan_assam_indian`
- `bhekuri_bamboo_assam_indian`
- `shorshe_rui_bengali_indian`
- `macher_paturi_rui_bengali_indian`
- `doi_maach_bengali_indian`
- `doi_ilish_bengali_indian`
- `chingri_cutlet_bengali_indian`
- `muri_ghonto_bengali_indian`
- `sorshe_bata_maach_bengali_indian`
- `aloo_posto_cream_bengali_indian`
- `potol_posto_bengali_indian`
- `koraishutir_kochuri_bengali_indian`
- `nimki_bengali_indian`
- `ghugni_bengali_indian`
- `dhokar_dalna_bengali_indian`
- `enchor_dalna_bengali_indian`
- `aamer_dal_bengali_indian`
- `sorse_ilish_dum_bengali_indian`
- `pakhala_jeera_odia_indian`
- `santula_odia_indian`
- `macha_mahura_odia_indian`
- `odia_khatta_indian`
- `chhena_podo_plain_odia_indian`
- `manda_pitha_coconut_odia_indian`
- `chakuli_pitha_odia_indian`
- `kheeri_odia_indian`
- `masor_tenga_jolphai_assam_indian`
- `duck_curry_coconut_assam_indian`
- `khar_papaya_assam_indian`
- `jolpan_doi_assam_indian`
- `bamboo_curry_assam_pork_indian`
- `pitha_til_assam_indian`
- `sunga_pitha_assam_indian`
- `luchi_kosha_set_bengali_indian`
- `posto_bora_bengali_indian`
- `narkel_naru_bengali_indian`
- `til_naru_bengali_indian`
- `moa_murmura_bengali_indian`
- `kolkata_egg_roll_indian`
- `apong_rice_beer_assam_indian`
- `chhena_rasgulla_odia_indian`
- `aloo_potol_dalna_bengali_indian`
- `masor_tenga_bilahi_assam_indian`

### North-East India (80 rows)

- `axone_pork_naga_indian`
- `axone_chicken_naga_indian`
- `axone_smoked_pork_naga_indian`
- `axone_beef_naga_indian`
- `axone_veg_naga_indian`
- `smoked_pork_naga_style_indian`
- `anishi_naga_indian`
- `galho_naga_indian`
- `galho_pork_naga_indian`
- `bamboo_pork_naga_indian`
- `naga_raja_mircha_chutney_indian`
- `eromba_dry_fish_manipur_indian`
- `eromba_pork_manipur_indian`
- `eromba_veg_manipur_indian`
- `chamthong_manipuri_indian`
- `kangshoi_manipuri_indian`
- `morok_metpa_manipur_indian`
- `chagempomba_manipuri_indian`
- `nga_thongba_manipur_indian`
- `ooti_manipuri_indian`
- `jadoh_chicken_meghalaya_indian`
- `jadoh_pork_meghalaya_indian`
- `jadoh_beef_meghalaya_indian`
- `dohkhlieh_meghalaya_indian`
- `doh_snam_meghalaya_indian`
- `tungtap_meghalaya_indian`
- `pumaloi_meghalaya_indian`
- `nakham_bitchi_meghalaya_indian`
- `kappa_meghalaya_indian`
- `bai_mizoram_indian`
- `bai_veg_mizoram_indian`
- `vawksa_rep_mizoram_indian`
- `koat_pitha_mizoram_indian`
- `chhangban_mizoram_indian`
- `berma_tripura_indian`
- `wahan_mosdeng_tripura_indian`
- `chakhwi_tripura_indian`
- `bangui_rice_tripura_indian`
- `thukpa_arunachali_indian`
- `pika_pila_arunachal_indian`
- `marua_arunachal_indian`
- `lukter_arunachal_indian`
- `pehak_arunachal_indian`
- `phagshapa_sikkim_indian`
- `sha_phaley_sikkim_indian`
- `sha_phaley_veg_sikkim_indian`
- `thenthuk_sikkim_indian`
- `thenthuk_pork_sikkim_indian`
- `gundruk_sikkim_indian`
- `gundruk_soup_sikkim_indian`
- `kinema_sikkim_indian`
- `kinema_curry_sikkim_indian`
- `sinki_sikkim_indian`
- `sinki_soup_sikkim_indian`
- `axone_bamboo_naga_indian`
- `galho_chicken_naga_indian`
- `pork_blood_curry_naga_indian`
- `snail_curry_naga_indian`
- `eromba_smoked_fish_manipur_indian`
- `singju_salad_manipur_indian`
- `nganou_paaknam_manipur_indian`
- `chamthong_chicken_manipur_indian`
- `doh_jem_meghalaya_indian`
- `pumaloi_egg_meghalaya_indian`
- `bai_bamboo_mizoram_indian`
- `sawhchiar_mizoram_indian`
- `bamboo_pickle_mizoram_indian`
- `koat_pitha_coconut_mizoram_indian`
- `chakhwi_pork_tripura_indian`
- `mui_borok_tripura_indian`
- `chowmein_tripura_indian`
- `thukpa_arunachali_veg_indian`
- `thukpa_arunachali_chicken_indian`
- `pika_pila_pork_arunachal_indian`
- `phagshapa_radish_sikkim_indian`
- `sel_roti_sikkim_indian`
- `kinema_dry_sikkim_indian`
- `gundruk_achar_sikkim_indian`
- `sinki_curry_sikkim_indian`
- `sha_phaley_beef_sikkim_indian`

### West India (200 rows)

- `undhiyu_surti_style_indian`
- `undhiyu_kathiawadi_style_indian`
- `methi_thepla_gujarati_indian`
- `bajra_thepla_gujarati_indian`
- `mooli_thepla_gujarati_indian`
- `mix_veg_thepla_gujarati_indian`
- `besan_dhokla_steamed_indian`
- `white_dhokla_gujarati_indian`
- `khaman_gujarati_fresh_indian`
- `rava_dhokla_suji_indian`
- `fafda_plain_gujarati_indian`
- `fafda_masala_gujarati_indian`
- `jalebi_gujarati_style_indian`
- `jalebi_jamnagari_indian`
- `gathiya_plain_gujarati_indian`
- `gathiya_tikha_gujarati_indian`
- `gathiya_nylon_gujarati_indian`
- `sev_tikha_gujarati_indian`
- `sev_sada_gujarati_indian`
- `sev_masala_gujarati_indian`
- `bajra_bhakri_gujarati_indian`
- `jowar_bhakri_maharashtrian_indian`
- `nachni_bhakri_indian`
- `dal_dhokli_gujarati_style_indian`
- `dal_dhokli_spicy_indian`
- `khichu_rice_gujarati_indian`
- `khichu_bajra_gujarati_indian`
- `patra_gujarati_colocasia_indian`
- `patra_fried_gujarati_indian`
- `muthia_steamed_green_indian`
- `muthia_fried_gujarati_indian`
- `kadhi_gujarati_sweet_indian`
- `kadhi_pakora_gujarati_indian`
- `rotlo_bajra_gujarati_indian`
- `rotlo_jowar_gujarati_indian`
- `sev_khamani_gujarati_indian`
- `khakhra_methi_gujarati_indian`
- `khakhra_masala_gujarati_indian`
- `khakhra_bajra_gujarati_indian`
- `doodhpak_gujarati_indian`
- `doodhpak_kesar_elaichi_indian`
- `shrikhand_kesar_gujarati_indian`
- `shrikhand_elaichi_gujarati_indian`
- `shrikhand_mango_amrakhand_indian`
- `ghughra_sweet_dry_fruit_indian`
- `ghughra_coconut_cardamom_indian`
- `mohanthal_ghee_rich_indian`
- `mohanthal_kesar_pista_indian`
- `misal_pav_puneri_indian`
- `misal_pav_nashik_indian`
- `misal_pav_mumbai_style_indian`
- `puran_poli_with_ghee_indian`
- `puran_poli_katachi_amti_indian`
- `vada_pav_street_mumbai_indian`
- `vada_pav_cheese_indian`
- `pav_bhaji_keema_indian`
- `pav_bhaji_paneer_indian`
- `pav_bhaji_cheese_indian`
- `tambda_rassa_with_rice_indian`
- `pandhra_rassa_chicken_indian`
- `malvani_chicken_curry_indian`
- `malvani_fish_curry_indian`
- `malvani_crab_curry_indian`
- `bombil_fry_semolina_indian`
- `bombil_fry_masala_indian`
- `sukka_mutton_kolhapuri_indian`
- `sukka_chicken_kolhapuri_indian`
- `matki_usal_maharashtrian_indian`
- `kala_vatana_usal_maharashtrian_indian`
- `moong_usal_maharashtrian_indian`
- `kothimbir_vadi_maharashtrian_indian`
- `kothimbir_vadi_fried_indian`
- `pithla_maharashtrian_indian`
- `pithla_dry_zunka_indian`
- `thalipeeth_bhajani_indian`
- `thalipeeth_with_butter_indian`
- `modak_kesar_stuffed_indian`
- `modak_chocolate_modern_indian`
- `modak_dry_fruit_maharashtrian_indian`
- `solkadhi_kokum_coconut_indian`
- `solkadhi_garlic_goan_indian`
- `amti_goda_masala_indian`
- `varan_ghee_rice_maharashtrian_indian`
- `basundi_maharashtrian_thick_indian`
- `shrikhand_pune_style_indian`
- `xacuti_mutton_goan_indian`
- `xacuti_pork_goan_indian`
- `vindaloo_chicken_goan_authentic_indian`
- `vindaloo_mutton_goan_indian`
- `vindaloo_prawn_goan_indian`
- `sorpotel_pork_traditional_indian`
- `sorpotel_beef_liver_goan_indian`
- `cafreal_mutton_goan_indian`
- `cafreal_prawn_goan_indian`
- `balchao_fish_goan_indian`
- `balchao_pork_goan_indian`
- `rechado_fish_goan_indian`
- `rechado_prawn_goan_indian`
- `rechado_pork_goan_indian`
- `goan_pork_chorizo_sausage_indian`
- `goan_chorizo_pulao_indian`
- `bebinca_traditional_goan_indian`
- `bebinca_egg_yolk_rich_indian`
- `dodol_goan_coconut_indian`
- `dodol_chocolate_goan_indian`
- `serradura_portuguese_goan_indian`
- `serradura_coffee_goan_indian`
- `ambot_tik_shark_goan_indian`
- `ambot_tik_prawn_goan_indian`
- `patoleo_goan_turmeric_leaf_indian`
- `patoleo_jackfruit_variant_indian`
- `sanna_coconut_toddy_indian`
- `sanna_sweet_coconut_indian`
- `poee_goan_bread_indian`
- `poee_with_chorizo_goan_indian`
- `baati_ghee_dunked_rajasthani_indian`
- `churma_sweet_rajasthani_indian`
- `panchmela_dal_rajasthani_indian`
- `laal_maas_mathania_chili_indian`
- `laal_maas_wild_game_junglee_indian`
- `safed_maas_white_rajasthani_indian`
- `gatte_ki_sabzi_yogurt_gravy_indian`
- `gatte_pulao_rajasthani_indian`
- `ker_sangri_with_bajra_roti_indian`
- `ker_sangri_pickle_rajasthani_indian`
- `ghevar_malai_rajasthani_indian`
- `ghevar_kesar_rajasthani_indian`
- `ghevar_mawa_rajasthani_indian`
- `mirchi_vada_jodhpur_indian`
- `mirchi_badi_rajasthani_indian`
- `bikaneri_bhujia_original_indian`
- `bikaneri_bhujia_masala_indian`
- `rabdi_rajasthani_style_indian`
- `rabdi_jalebi_rajasthani_indian`
- `moong_dal_kachori_rajasthani_indian`
- `hing_ki_kachori_rajasthani_indian`
- `raj_kachori_chaat_rajasthani_indian`
- `pitod_ki_sabzi_rajasthani_indian`
- `papad_ki_sabzi_rajasthani_indian`
- `bajre_ki_roti_ghee_rajasthani_indian`
- `lahsun_ki_chutney_rajasthani_indian`
- `mohan_maas_rajasthani_indian`
- `besan_chakki_rajasthani_indian`
- `lilva_kachori_surti_deep_fried_indian`
- `lilva_kachori_baked_healthy_indian`
- `handvo_gujarati_baked_indian`
- `handvo_pan_fried_gujarati_indian`
- `besan_ladoo_maharashtrian_indian`
- `rava_ladoo_maharashtrian_indian`
- `motichoor_ladoo_maharashtrian_indian`
- `sabudana_khichdi_peanut_rich_indian`
- `sabudana_vada_fried_variant_indian`
- `aamras_alphonso_maharashtrian_indian`
- `aamras_puri_combo_indian`
- `prawn_curry_goan_red_indian`
- `fish_curry_goan_coconut_red_indian`
- `thalipeeth_jowar_wheat_indian`
- `vada_pav_dry_garlic_chutney_indian`
- `kanda_bhaji_maharashtrian_indian`
- `batata_vada_standalone_indian`
- `gavhachi_roti_whole_wheat_maha_indian`
- `mawa_kachori_rajasthani_filled_indian`
- `dal_makhani_rajasthani_black_indian`
- `laapsi_rajasthani_wheat_halwa_indian`
- `bajre_ki_khichdi_rajasthani_indian`
- `dahi_kachori_rajasthani_indian`
- `malpua_rajasthani_rabdi_indian`
- `gatte_ki_kadhi_rajasthani_indian`
- `makki_ki_roti_rajasthani_indian`
- `dhokla_sandwich_gujarati_indian`
- `sev_tameta_nu_shaak_gujarati_indian`
- `gujarati_thali_complete_indian`
- `vaghareli_khichdi_gujarati_indian`
- `chorafali_gujarati_indian`
- `methi_na_gota_gujarati_indian`
- `papdi_chaat_gujarati_indian`
- `dudhi_muthia_baked_indian`
- `kachori_moong_dal_gujarati_indian`
- `mathia_gujarati_fried_wafer_indian`
- `lasan_chutney_gujarati_indian`
- `sukhdi_gujarati_wheat_sweet_indian`
- `dhokli_no_vagharo_gujarati_indian`
- `chaas_gujarati_spiced_indian`
- `kolhapuri_egg_curry_indian`
- `bharleli_vangi_maharashtrian_indian`
- `kombdi_vade_malvani_indian`
- `shev_bhaji_maharashtrian_indian`
- `chakli_maharashtrian_diwali_indian`
- `shankarpali_maharashtrian_indian`
- `caldeirada_goan_fish_stew_indian`
- `prawn_rava_fry_goan_indian`
- `goan_fish_cutlet_indian`
- `goan_prawn_curry_white_indian`
- `pez_goan_rice_gruel_indian`
- `churma_laddoo_rajasthani_indian`
- `ker_sangri_jowar_combo_indian`
- `raab_rajasthani_millet_drink_indian`
- `jodhpuri_kabab_rajasthani_indian`
- `bajra_raab_winter_soup_indian`
- `makhan_bada_rajasthani_indian`


## Full SQL (inline copy)

```sql
INSERT INTO food_nutrition_overrides (food_name_normalized, display_name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, sugar_per_100g, default_weight_per_piece_g, default_serving_g, default_count, source, notes, variant_names, is_active, restaurant_name, food_category, sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g, potassium_mg, calcium_mg, iron_mg, vitamin_a_ug, vitamin_c_mg, vitamin_d_iu, magnesium_mg, zinc_mg, phosphorus_mg, selenium_ug, omega3_g, region, country_name)
VALUES
('plain_appam_palappam_indian', 'Plain Appam (Palappam)', 158, 3.4, 29.8, 2.9, 1.1, 1.8, 50, 100, 2, 'manual', 'hyperregional-apr2026;ICMR;nutritionix;recipe-estimated', ARRAY['palappam_indian','plain_appam_indian','vellai_appam'], true, NULL, 'bread_pancake', 180, 0, 2.1, 0, 90, 22, 1.1, 8, 0.5, 0, 18, 0.8, 80, 5.5, 0.05, 'South India', 'India'),
('egg_appam_indian', 'Egg Appam', 198, 8.2, 28.1, 5.8, 0.9, 1.4, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutta_appam_indian','egg_hoppers_kerala'], true, NULL, 'bread_pancake', 210, 112, 3.2, 0, 105, 38, 1.4, 62, 0.4, 8, 14, 1.0, 98, 8.2, 0.08, 'South India', 'India'),
('sweet_coconut_appam_indian', 'Sweet Coconut Appam', 210, 3.1, 36.5, 6.2, 0.8, 8.4, 55, 110, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['coconut_appam_sweet_indian','thenga_appam'], true, NULL, 'bread_pancake', 120, 0, 5.4, 0, 85, 18, 0.9, 2, 0.2, 0, 14, 0.6, 72, 4.8, 0.04, 'South India', 'India'),
('appam_coconut_milk_stew_bundle_indian', 'Appam with Coconut Milk Stew Bundle', 182, 5.8, 26.4, 6.4, 1.2, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['appam_ishtu_bundle_indian','appam_stew_kerala'], true, NULL, 'bread_pancake', 240, 18, 4.8, 0, 148, 32, 1.2, 24, 4.2, 2, 22, 0.9, 88, 6.4, 0.06, 'South India', 'India'),
('plain_puttu_indian', 'Plain Rice Puttu', 165, 3.6, 34.2, 1.9, 1.4, 0.8, 100, 150, 1, 'manual', 'hyperregional-apr2026;ICMR', ARRAY['rice_puttu_kerala','puttu_plain_kerala'], true, NULL, 'breakfast', 85, 0, 1.4, 0, 78, 12, 1.2, 0, 0, 0, 16, 0.7, 68, 4.2, 0.02, 'South India', 'India'),
('puttu_kadala_curry_bundle_indian', 'Puttu with Kadala Curry Bundle', 195, 9.4, 31.8, 4.2, 4.8, 1.2, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['puttu_kadala_indian','puttu_chickpea_bundle'], true, NULL, 'breakfast', 248, 0, 2.8, 0, 248, 42, 2.8, 4, 1.8, 0, 36, 1.2, 118, 7.4, 0.04, 'South India', 'India'),
('wheat_puttu_indian', 'Wheat Puttu (Gothambu Puttu)', 172, 5.1, 33.4, 2.4, 2.2, 1.0, 100, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['gothambu_puttu_indian','wheat_puttu_kerala'], true, NULL, 'breakfast', 90, 0, 1.6, 0, 92, 18, 1.8, 0, 0, 0, 22, 0.9, 88, 5.2, 0.03, 'South India', 'India'),
('ragi_puttu_indian', 'Ragi Puttu (Finger Millet Puttu)', 168, 4.8, 34.1, 1.8, 2.6, 1.4, 100, 150, 1, 'manual', 'hyperregional-apr2026;ICMR', ARRAY['finger_millet_puttu_kerala','kezhvaragu_puttu'], true, NULL, 'breakfast', 78, 0, 1.2, 0, 98, 48, 2.4, 0, 0, 0, 38, 0.9, 94, 4.8, 0.02, 'South India', 'India'),
('meen_moilee_plain_indian', 'Meen Moilee (Kerala Fish Molee)', 118, 14.2, 3.8, 5.4, 0.8, 1.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fish_molee_kerala','meen_moilee_coconut_milk'], true, NULL, 'fish_curry', 320, 58, 4.2, 0, 298, 28, 1.2, 22, 4.8, 24, 28, 0.9, 128, 18.4, 0.48, 'South India', 'India'),
('meen_moilee_rich_coconut_indian', 'Meen Moilee Rich Coconut Milk', 142, 13.8, 4.1, 8.2, 0.6, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rich_fish_molee_kerala'], true, NULL, 'fish_curry', 310, 54, 6.8, 0, 278, 24, 1.0, 18, 3.8, 20, 24, 0.8, 118, 16.8, 0.44, 'South India', 'India'),
('meen_moilee_appam_bundle_indian', 'Meen Moilee with Appam Bundle', 168, 11.4, 21.6, 5.2, 1.0, 2.2, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fish_molee_appam_bundle'], true, NULL, 'fish_curry', 290, 34, 3.8, 0, 224, 28, 1.2, 14, 2.8, 12, 22, 0.8, 112, 12.4, 0.28, 'South India', 'India'),
('alleppey_fish_curry_raw_mango_indian', 'Alleppey Fish Curry (Raw Mango)', 128, 15.6, 6.2, 4.8, 1.2, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['alappuzha_fish_curry_indian','alleppey_meen_curry'], true, NULL, 'fish_curry', 348, 62, 3.6, 0, 312, 32, 1.4, 28, 6.4, 22, 26, 1.0, 134, 19.2, 0.52, 'South India', 'India'),
('alleppey_prawn_curry_indian', 'Alleppey Prawn Curry', 132, 16.8, 5.4, 5.2, 0.8, 1.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['alappuzha_prawn_curry_indian','alleppey_chemmeen_curry'], true, NULL, 'fish_curry', 368, 122, 4.2, 0, 288, 68, 1.8, 24, 4.2, 18, 32, 1.4, 148, 22.4, 0.38, 'South India', 'India'),
('alleppey_fish_curry_coconut_heavy_indian', 'Alleppey Fish Curry Coconut Heavy', 158, 14.2, 6.8, 8.4, 1.0, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['coconut_alleppey_fish_curry'], true, NULL, 'fish_curry', 328, 56, 6.8, 0, 292, 28, 1.2, 22, 4.8, 18, 22, 0.8, 118, 16.2, 0.46, 'South India', 'India'),
('kerala_beef_ularthiyathu_indian', 'Kerala Beef Ularthiyathu', 242, 22.4, 5.8, 14.6, 1.8, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beef_ularthiyathu_kerala','beef_olathiyathu_kerala'], true, NULL, 'meat_dry', 418, 78, 6.2, 0, 348, 28, 3.8, 12, 2.4, 4, 28, 4.8, 188, 18.4, 0.08, 'South India', 'India'),
('kerala_beef_fry_coconut_oil_indian', 'Kerala Beef Fry (Coconut Oil)', 268, 21.8, 4.2, 18.2, 1.4, 0.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beef_fry_coconut_oil_kerala','nadan_beef_fry_kerala'], true, NULL, 'meat_dry', 448, 82, 8.4, 0, 312, 24, 3.4, 8, 1.8, 4, 26, 4.6, 178, 16.8, 0.06, 'South India', 'India'),
('kerala_beef_roast_dry_masala_indian', 'Kerala Beef Roast (Dry Masala)', 258, 23.1, 6.4, 15.8, 1.6, 1.0, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beef_roast_kerala_indian','nadan_beef_roast'], true, NULL, 'meat_dry', 428, 80, 7.2, 0, 328, 26, 3.6, 10, 2.0, 4, 27, 4.7, 182, 17.4, 0.07, 'South India', 'India'),
('nadan_kozhi_curry_indian', 'Nadan Kozhi Curry (Country Chicken)', 168, 18.4, 5.2, 8.6, 1.2, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['country_chicken_curry_kerala','nadan_chicken_curry_kerala'], true, NULL, 'chicken_curry', 368, 68, 3.8, 0, 288, 32, 1.8, 24, 3.8, 6, 28, 1.8, 148, 12.4, 0.12, 'South India', 'India'),
('kozhi_varutharacha_curry_indian', 'Kozhi Varutharacha Curry', 192, 17.8, 6.4, 11.2, 1.4, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['varutharacha_chicken_curry_kerala','roasted_coconut_chicken_kerala'], true, NULL, 'chicken_curry', 378, 64, 5.6, 0, 268, 36, 2.2, 18, 3.2, 6, 32, 2.0, 156, 13.8, 0.14, 'South India', 'India'),
('pidi_kozhi_kerala_indian', 'Pidi Kozhi (Rice Dumplings with Chicken)', 188, 12.6, 24.8, 4.8, 1.6, 1.2, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pidi_chicken_curry_kerala','kerala_rice_dumpling_chicken'], true, NULL, 'rice_dumpling', 312, 42, 2.4, 0, 228, 28, 1.8, 14, 2.8, 4, 22, 1.4, 128, 9.8, 0.08, 'South India', 'India'),
('malabar_parotta_plain_indian', 'Malabar Parotta Plain', 298, 6.8, 46.2, 9.8, 1.4, 1.8, 80, 160, 2, 'manual', 'hyperregional-apr2026;nutritionix;recipe-estimated', ARRAY['kerala_parotta_plain','malabar_porotta_plain'], true, NULL, 'bread_pancake', 348, 0, 4.2, 0, 112, 18, 1.8, 0, 0, 0, 14, 0.8, 88, 6.2, 0.04, 'South India', 'India'),
('malabar_parotta_beef_curry_indian', 'Malabar Parotta with Beef Curry', 318, 16.4, 38.6, 12.8, 1.6, 1.4, 280, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['parotta_beef_kerala','porotta_beef_curry_kerala'], true, NULL, 'bread_pancake', 398, 48, 5.8, 0, 198, 28, 2.8, 8, 1.4, 2, 22, 2.8, 148, 10.8, 0.06, 'South India', 'India'),
('malabar_parotta_egg_curry_indian', 'Malabar Parotta with Egg Curry', 308, 12.8, 40.4, 11.4, 1.4, 1.6, 280, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['parotta_egg_curry_kerala','porotta_mutta_curry_kerala'], true, NULL, 'bread_pancake', 378, 112, 5.2, 0, 168, 42, 2.2, 58, 1.2, 8, 18, 1.6, 128, 9.2, 0.08, 'South India', 'India'),
('thalassery_mutton_dum_biryani_indian', 'Thalassery Mutton Dum Biryani', 218, 14.8, 28.4, 5.8, 1.2, 1.4, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['thalassery_mutton_biryani','kozhikodan_mutton_biryani'], true, NULL, 'biryani', 428, 58, 2.8, 0, 268, 32, 2.4, 14, 2.4, 4, 28, 2.8, 148, 11.8, 0.12, 'South India', 'India'),
('thalassery_chicken_dum_biryani_indian', 'Thalassery Chicken Dum Biryani', 204, 14.2, 28.8, 4.6, 1.0, 1.2, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['thalassery_chicken_biryani','kozhikodan_chicken_biryani'], true, NULL, 'biryani', 398, 48, 2.2, 0, 248, 28, 2.0, 12, 2.0, 4, 24, 2.2, 138, 10.4, 0.10, 'South India', 'India'),
('kallappam_plain_indian', 'Kallappam (Lace Hopper)', 152, 3.2, 28.6, 2.8, 1.0, 1.6, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kalla_appam_kerala','lace_appam_kerala'], true, NULL, 'bread_pancake', 164, 0, 2.2, 0, 82, 18, 0.9, 4, 0.4, 0, 14, 0.6, 72, 4.8, 0.04, 'South India', 'India'),
('kallappam_egg_indian', 'Kallappam with Egg', 188, 7.8, 27.2, 5.6, 0.9, 1.4, 70, 140, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['egg_kallappam_kerala','mutta_kallappam'], true, NULL, 'bread_pancake', 192, 108, 3.4, 0, 96, 36, 1.2, 58, 0.3, 6, 12, 0.9, 88, 6.8, 0.08, 'South India', 'India'),
('kerala_ishtu_vegetable_indian', 'Kerala Vegetable Ishtu (Stew)', 92, 3.4, 8.6, 5.2, 2.4, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kerala_veg_stew_ishtu','vegetable_stew_coconut_kerala'], true, NULL, 'vegetable_stew', 268, 0, 4.4, 0, 248, 28, 0.8, 18, 8.4, 0, 18, 0.4, 68, 2.8, 0.04, 'South India', 'India'),
('kerala_ishtu_chicken_indian', 'Kerala Chicken Ishtu (Stew)', 128, 11.8, 6.8, 6.4, 1.4, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kerala_chicken_stew_coconut','kozhi_ishtu_kerala'], true, NULL, 'vegetable_stew', 298, 48, 5.2, 0, 268, 24, 1.2, 12, 4.8, 4, 22, 1.2, 108, 7.2, 0.08, 'South India', 'India'),
('kerala_ishtu_mutton_indian', 'Kerala Mutton Ishtu (Stew)', 148, 12.4, 7.2, 8.2, 1.2, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_ishtu_kerala','mutton_stew_coconut_kerala'], true, NULL, 'vegetable_stew', 318, 62, 6.4, 0, 278, 28, 1.8, 8, 3.8, 4, 24, 2.4, 128, 10.2, 0.06, 'South India', 'India'),
('avial_kerala_plain_indian', 'Avial Kerala Style (Coconut Curd)', 96, 2.8, 9.4, 5.6, 2.8, 2.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['aviyal_kerala_plain','avial_sadya_style'], true, NULL, 'vegetable', 142, 0, 4.8, 0, 268, 36, 0.9, 28, 6.4, 0, 22, 0.5, 72, 2.8, 0.06, 'South India', 'India'),
('avial_extra_coconut_indian', 'Avial with Extra Coconut', 118, 2.6, 8.8, 8.2, 2.4, 2.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['avial_rich_coconut_kerala'], true, NULL, 'vegetable', 128, 0, 7.2, 0, 248, 32, 0.8, 22, 5.6, 0, 20, 0.4, 68, 2.4, 0.05, 'South India', 'India'),
('olan_plain_indian', 'Olan (Ash Gourd Coconut Milk)', 78, 1.8, 8.2, 4.4, 1.8, 2.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['olan_kerala_plain','ash_gourd_coconut_milk_curry_kerala'], true, NULL, 'vegetable', 112, 0, 3.8, 0, 198, 18, 0.5, 8, 3.8, 0, 14, 0.3, 48, 1.8, 0.06, 'South India', 'India'),
('olan_blackeyed_peas_indian', 'Olan with Black-Eyed Peas', 98, 4.2, 12.4, 4.2, 2.8, 2.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['olan_vanpayar_kerala','blackeyed_peas_olan_kerala'], true, NULL, 'vegetable', 128, 0, 3.6, 0, 228, 28, 1.2, 6, 3.2, 0, 22, 0.6, 68, 2.4, 0.05, 'South India', 'India'),
('kaalan_raw_banana_indian', 'Kaalan (Raw Banana Yogurt Curry)', 112, 2.6, 14.8, 4.8, 1.8, 3.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kaalan_plain_kerala','raw_banana_kaalan_kerala'], true, NULL, 'vegetable', 148, 8, 4.2, 0, 228, 58, 0.5, 8, 4.2, 0, 18, 0.4, 68, 2.2, 0.03, 'South India', 'India'),
('kaalan_yam_indian', 'Kaalan with Yam', 128, 3.2, 18.4, 4.6, 2.4, 3.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['yam_kaalan_kerala','chena_kaalan_kerala'], true, NULL, 'vegetable', 158, 8, 4.0, 0, 268, 52, 0.7, 6, 4.8, 0, 22, 0.5, 78, 2.6, 0.03, 'South India', 'India'),
('erissery_pumpkin_coconut_indian', 'Erissery (Pumpkin Coconut)', 102, 2.4, 12.6, 5.2, 2.2, 3.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mathanga_erissery','pumpkin_erissery_kerala'], true, NULL, 'vegetable', 118, 0, 4.4, 0, 248, 28, 0.8, 128, 6.8, 0, 18, 0.4, 68, 2.2, 0.05, 'South India', 'India'),
('erissery_raw_banana_indian', 'Erissery with Raw Banana', 118, 2.8, 16.4, 5.4, 2.6, 3.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['raw_banana_erissery_kerala','kaya_erissery'], true, NULL, 'vegetable', 128, 0, 4.6, 0, 268, 24, 0.9, 62, 5.8, 0, 20, 0.4, 72, 2.4, 0.04, 'South India', 'India'),
('cabbage_thoran_kerala_indian', 'Cabbage Thoran (Kerala)', 82, 2.4, 7.8, 4.8, 2.8, 3.2, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['cabbage_thoran_kerala','muttakos_thoran'], true, NULL, 'vegetable', 108, 0, 4.2, 0, 218, 42, 0.6, 8, 28.4, 0, 12, 0.3, 52, 1.4, 0.04, 'South India', 'India'),
('beans_thoran_kerala_indian', 'Beans Thoran (Kerala)', 88, 3.6, 9.2, 4.6, 3.4, 2.4, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['green_beans_thoran_kerala','beans_stir_fry_kerala'], true, NULL, 'vegetable', 112, 0, 3.8, 0, 228, 38, 1.0, 28, 12.8, 0, 18, 0.4, 62, 1.8, 0.06, 'South India', 'India'),
('beetroot_thoran_kerala_indian', 'Beetroot Thoran (Kerala)', 92, 2.2, 11.4, 4.4, 2.6, 6.8, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beetroot_thoran_kerala','beet_stir_fry_kerala'], true, NULL, 'vegetable', 118, 0, 3.8, 0, 268, 18, 0.8, 2, 4.8, 0, 18, 0.3, 52, 1.2, 0.04, 'South India', 'India'),
('raw_banana_thoran_kerala_indian', 'Raw Banana Thoran (Kerala)', 112, 2.0, 16.8, 4.8, 2.4, 3.6, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kaya_thoran_kerala','raw_banana_stir_fry_kerala'], true, NULL, 'vegetable', 108, 0, 4.2, 0, 248, 14, 0.5, 8, 6.4, 0, 16, 0.3, 58, 1.6, 0.04, 'South India', 'India'),
('ada_pradhaman_kerala_indian', 'Ada Pradhaman (Rice Flake Payasam)', 198, 3.4, 32.8, 6.8, 0.4, 24.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['ada_payasam_kerala','rice_ada_pradhaman'], true, NULL, 'dessert', 58, 12, 5.4, 0, 148, 58, 0.8, 18, 1.2, 4, 18, 0.4, 78, 3.8, 0.04, 'South India', 'India'),
('parippu_payasam_kerala_indian', 'Parippu Payasam (Lentil Payasam)', 182, 4.8, 34.2, 4.2, 1.8, 22.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dal_payasam_kerala','lentil_payasam_kerala'], true, NULL, 'dessert', 62, 8, 3.6, 0, 178, 52, 1.2, 4, 0.8, 2, 22, 0.6, 88, 3.2, 0.04, 'South India', 'India'),
('palada_payasam_kerala_indian', 'Palada Payasam (Milk Payasam)', 176, 5.2, 28.6, 5.4, 0.2, 21.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['palada_pradhaman_kerala','milk_payasam_ada'], true, NULL, 'dessert', 68, 18, 3.8, 0, 168, 138, 0.2, 28, 0.8, 8, 14, 0.6, 112, 4.2, 0.06, 'South India', 'India'),
('paal_payasam_rich_kerala_indian', 'Paal Payasam (Rich Milk Payasam)', 168, 5.8, 26.4, 5.2, 0.1, 19.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['paal_payasam_kerala','rice_milk_payasam_kerala'], true, NULL, 'dessert', 72, 22, 3.4, 0, 158, 148, 0.2, 32, 0.6, 8, 12, 0.6, 118, 4.6, 0.06, 'South India', 'India'),
('unniyappam_plain_kerala_indian', 'Unniyappam Plain (Sweet Rice Ball)', 248, 3.8, 38.4, 9.2, 1.2, 16.8, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['unni_appam_plain_kerala','sweet_rice_ball_kerala'], true, NULL, 'snack_sweet', 88, 0, 7.8, 0, 128, 18, 1.4, 2, 0.4, 0, 14, 0.6, 78, 3.8, 0.04, 'South India', 'India'),
('unniyappam_banana_kerala_indian', 'Unniyappam with Banana', 258, 3.6, 41.2, 9.0, 1.4, 18.6, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['banana_unniyappam_kerala','pazham_unniyappam'], true, NULL, 'snack_sweet', 82, 0, 7.6, 0, 168, 14, 1.2, 4, 1.8, 0, 16, 0.5, 72, 3.6, 0.04, 'South India', 'India'),
('palada_milk_dessert_kerala_indian', 'Palada (Rice Ada in Sweetened Milk)', 162, 4.6, 26.8, 4.4, 0.2, 18.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['palada_kerala_dessert','ada_milk_sweet_kerala'], true, NULL, 'dessert', 62, 16, 3.2, 0, 148, 128, 0.2, 26, 0.6, 6, 12, 0.5, 98, 3.8, 0.05, 'South India', 'India'),
('kerala_banana_chips_coconut_oil_indian', 'Kerala Banana Chips (Coconut Oil)', 524, 2.6, 58.4, 30.8, 4.8, 8.2, 30, 30, 1, 'manual', 'hyperregional-apr2026;nutritionix;recipe-estimated', ARRAY['nendran_chips_coconut_oil','kerala_nendran_banana_chips'], true, NULL, 'snack', 248, 0, 26.4, 0, 428, 12, 1.2, 18, 4.8, 0, 22, 0.4, 52, 2.4, 0.04, 'South India', 'India'),
('kerala_banana_chips_salt_chilli_indian', 'Kerala Banana Chips Salt and Chilli', 518, 2.4, 57.2, 30.2, 4.6, 6.8, 30, 30, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['spicy_banana_chips_kerala','salt_chilli_banana_chips_kerala'], true, NULL, 'snack', 288, 0, 25.8, 0, 412, 10, 1.0, 12, 4.2, 0, 20, 0.4, 48, 2.2, 0.04, 'South India', 'India'),
('pesarattu_plain_andhra_indian', 'Pesarattu Plain (Green Gram Crepe)', 148, 7.8, 22.4, 3.2, 2.8, 1.4, 80, 160, 2, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['green_gram_dosa_andhra','moong_dal_crepe_andhra'], true, NULL, 'breakfast', 148, 0, 1.2, 0, 228, 28, 1.8, 12, 2.4, 0, 28, 0.8, 108, 4.8, 0.06, 'South India', 'India'),
('pesarattu_ginger_chutney_indian', 'Pesarattu with Ginger Chutney', 162, 7.6, 24.6, 3.8, 2.4, 1.8, 90, 180, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pesarattu_allam_chutney','ginger_pesarattu_andhra'], true, NULL, 'breakfast', 168, 0, 1.4, 0, 238, 30, 1.9, 8, 2.8, 0, 26, 0.8, 112, 4.6, 0.06, 'South India', 'India'),
('mla_pesarattu_upma_stuffed_indian', 'MLA Pesarattu (Upma Stuffed)', 198, 8.4, 32.8, 4.4, 2.6, 1.6, 120, 240, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['upma_pesarattu_andhra','stuffed_pesarattu_mla_canteen'], true, NULL, 'breakfast', 218, 0, 1.6, 0, 258, 32, 2.0, 8, 2.4, 0, 30, 0.9, 118, 5.2, 0.06, 'South India', 'India'),
('gongura_fish_curry_andhra_indian', 'Gongura Fish Curry (Andhra)', 142, 16.8, 6.4, 5.8, 1.4, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sorrel_fish_curry_andhra','gongura_meen_curry_andhra'], true, NULL, 'fish_curry', 348, 62, 2.8, 0, 328, 38, 1.6, 24, 8.4, 22, 28, 1.0, 138, 18.6, 0.52, 'South India', 'India'),
('gongura_prawn_curry_andhra_indian', 'Gongura Prawn Curry (Andhra)', 148, 17.4, 5.8, 6.2, 1.2, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sorrel_prawn_curry_andhra','gongura_royyalu_curry'], true, NULL, 'seafood', 368, 128, 3.4, 0, 298, 72, 1.8, 18, 6.8, 18, 32, 1.4, 152, 22.8, 0.42, 'South India', 'India'),
('andhra_chepala_pulusu_tamarind_indian', 'Andhra Chepala Pulusu (Tamarind Fish)', 136, 15.8, 8.4, 4.8, 1.6, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chepala_pulusu_andhra','andhra_fish_tamarind_curry'], true, NULL, 'fish_curry', 368, 58, 1.8, 0, 312, 34, 1.4, 22, 6.8, 18, 26, 0.9, 128, 17.8, 0.48, 'South India', 'India'),
('chepala_pulusu_rohu_indian', 'Chepala Pulusu with Rohu Fish', 128, 14.6, 7.8, 4.2, 1.4, 2.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rohu_fish_pulusu_andhra','rohu_chepala_pulusu'], true, NULL, 'fish_curry', 342, 54, 1.6, 0, 292, 28, 1.2, 18, 5.8, 16, 22, 0.8, 118, 15.8, 0.44, 'South India', 'India'),
('royyala_iguru_andhra_masala_indian', 'Royyala Iguru (Andhra Prawn Masala)', 162, 18.6, 5.2, 7.4, 1.0, 1.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['prawn_iguru_andhra','royyalu_iguru_spicy'], true, NULL, 'seafood', 388, 134, 2.4, 0, 308, 74, 1.8, 14, 4.8, 18, 34, 1.4, 158, 24.2, 0.38, 'South India', 'India'),
('royyala_iguru_coconut_andhra_indian', 'Royyala Iguru with Coconut (Andhra)', 178, 17.8, 5.8, 9.2, 1.2, 1.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['coconut_prawn_iguru_andhra'], true, NULL, 'seafood', 372, 128, 4.8, 0, 288, 68, 1.6, 12, 4.2, 16, 30, 1.2, 148, 22.4, 0.36, 'South India', 'India'),
('natu_kodi_pulusu_andhra_indian', 'Natu Kodi Pulusu (Country Chicken Curry)', 158, 17.4, 6.8, 7.2, 1.4, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['country_chicken_pulusu_andhra','natu_kodi_curry_andhra'], true, NULL, 'chicken_curry', 378, 68, 2.8, 0, 278, 28, 1.6, 18, 3.4, 6, 26, 1.6, 142, 11.8, 0.12, 'South India', 'India'),
('natu_kodi_pulusu_sesame_andhra_indian', 'Natu Kodi Pulusu Rich Sesame Version', 178, 16.8, 7.4, 9.4, 1.6, 2.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sesame_country_chicken_pulusu_andhra'], true, NULL, 'chicken_curry', 388, 64, 4.2, 0, 258, 32, 1.8, 14, 3.0, 6, 28, 1.8, 152, 12.8, 0.14, 'South India', 'India'),
('kodi_vepudu_andhra_bone_indian', 'Kodi Vepudu (Andhra Fried Chicken)', 228, 24.8, 4.2, 13.2, 0.8, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_chicken_fry_kodi_vepudu','kodi_vepudu_spicy'], true, NULL, 'chicken_dry', 428, 82, 4.8, 0, 288, 24, 1.4, 12, 1.8, 6, 28, 2.0, 178, 14.8, 0.08, 'South India', 'India'),
('kodi_vepudu_boneless_andhra_indian', 'Kodi Vepudu Boneless (Andhra)', 238, 26.4, 3.8, 14.2, 0.6, 1.0, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['boneless_kodi_vepudu_andhra','andhra_chicken_fry_boneless'], true, NULL, 'chicken_dry', 438, 88, 5.4, 0, 298, 22, 1.2, 8, 1.4, 6, 26, 2.2, 188, 15.8, 0.08, 'South India', 'India'),
('guntur_chicken_curry_spicy_indian', 'Guntur Chicken Curry (Very Spicy)', 182, 18.8, 6.2, 9.4, 1.4, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['guntur_mirchi_chicken_curry','spicy_guntur_kozhi'], true, NULL, 'chicken_curry', 408, 72, 3.8, 0, 298, 28, 1.8, 16, 3.8, 6, 28, 2.0, 158, 13.4, 0.12, 'South India', 'India'),
('guntur_chicken_fry_andhra_indian', 'Guntur Chicken Fry (Andhra)', 244, 25.2, 5.8, 14.2, 1.2, 1.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['guntur_kodi_vepudu','guntur_chicken_dry_fry'], true, NULL, 'chicken_dry', 448, 84, 5.6, 0, 308, 24, 1.6, 12, 2.8, 6, 26, 2.2, 168, 15.2, 0.10, 'South India', 'India'),
('ulavacharu_chicken_curry_indian', 'Ulavacharu Chicken Curry (Horsegram)', 172, 16.4, 8.6, 8.4, 2.4, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ulavacharu_kozhi_curry','horsegram_chicken_curry_andhra'], true, NULL, 'chicken_curry', 388, 64, 3.2, 0, 368, 38, 2.8, 14, 2.4, 6, 36, 1.8, 168, 12.8, 0.10, 'South India', 'India'),
('ulavacharu_mutton_curry_indian', 'Ulavacharu Mutton Curry (Horsegram)', 188, 17.8, 8.2, 9.8, 2.6, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ulavacharu_mutton_stew','horsegram_mutton_curry_andhra'], true, NULL, 'mutton_curry', 408, 74, 4.2, 0, 388, 42, 3.2, 8, 2.0, 4, 38, 3.2, 178, 14.4, 0.08, 'South India', 'India'),
('andhra_pulihora_tamarind_rice_indian', 'Andhra Pulihora (Tamarind Rice)', 168, 3.4, 32.4, 3.8, 1.4, 1.8, 150, 200, 1, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['andhra_tamarind_rice_pulihora','chintapandu_pulihora'], true, NULL, 'rice', 368, 0, 0.8, 0, 148, 18, 1.4, 8, 1.8, 0, 22, 0.8, 88, 4.8, 0.04, 'South India', 'India'),
('andhra_pulihora_sesame_indian', 'Andhra Pulihora with Sesame Seeds', 182, 4.2, 30.8, 5.6, 1.6, 1.6, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sesame_pulihora_andhra','nuvvulu_pulihora'], true, NULL, 'rice', 348, 0, 1.2, 0, 162, 48, 1.8, 6, 1.4, 0, 28, 1.0, 102, 5.4, 0.06, 'South India', 'India'),
('bagara_baingan_andhra_indian', 'Bagara Baingan (Andhra Stuffed Eggplant)', 128, 3.2, 10.4, 8.8, 3.4, 4.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['stuffed_brinjal_andhra','gutti_vankaya_andhra'], true, NULL, 'vegetable', 218, 0, 1.8, 0, 298, 38, 1.2, 12, 4.8, 0, 22, 0.4, 68, 2.4, 0.08, 'South India', 'India'),
('gutti_vankaya_kura_andhra_indian', 'Gutti Vankaya Kura (Stuffed Brinjal Curry)', 138, 3.8, 9.8, 9.4, 3.6, 3.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['stuffed_brinjal_curry_andhra','gutti_vankaya_gravy_andhra'], true, NULL, 'vegetable', 228, 0, 2.0, 0, 308, 42, 1.4, 10, 4.4, 0, 24, 0.5, 72, 2.6, 0.08, 'South India', 'India'),
('gutti_vankaya_sesame_peanut_indian', 'Gutti Vankaya Sesame-Peanut Masala', 148, 4.4, 9.2, 10.8, 3.8, 3.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['vankaya_nuvvulu_groundnut_masala'], true, NULL, 'vegetable', 218, 0, 2.2, 0, 318, 48, 1.6, 8, 4.0, 0, 26, 0.6, 82, 3.0, 0.10, 'South India', 'India'),
('dondakaya_fry_andhra_indian', 'Dondakaya Fry (Ivy Gourd Andhra)', 88, 1.8, 7.8, 5.8, 2.6, 3.2, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ivy_gourd_fry_andhra','tindora_fry_andhra'], true, NULL, 'vegetable', 128, 0, 1.2, 0, 218, 28, 0.6, 8, 12.4, 0, 14, 0.3, 48, 1.4, 0.04, 'South India', 'India'),
('dondakaya_palli_kura_indian', 'Dondakaya Palli Kura (Ivy Gourd Peanut)', 108, 3.4, 8.2, 7.2, 2.8, 3.0, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ivy_gourd_peanut_andhra','dondakaya_groundnut_curry'], true, NULL, 'vegetable', 138, 0, 1.6, 0, 238, 32, 0.8, 6, 10.8, 0, 18, 0.5, 62, 1.8, 0.06, 'South India', 'India'),
('tomato_pappu_andhra_indian', 'Tomato Pappu (Andhra Tomato Dal)', 112, 6.4, 14.8, 3.2, 3.4, 4.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_tomato_dal','tamata_pappu_andhra'], true, NULL, 'dal', 248, 0, 0.8, 0, 318, 38, 2.2, 28, 12.8, 0, 28, 0.8, 108, 3.8, 0.04, 'South India', 'India'),
('palakoora_pappu_andhra_indian', 'Palakoora Pappu (Spinach Dal Andhra)', 108, 7.2, 12.4, 3.8, 3.8, 1.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['spinach_dal_andhra','palak_pappu_andhra'], true, NULL, 'dal', 228, 0, 0.8, 0, 368, 78, 3.2, 128, 18.4, 0, 38, 1.0, 118, 4.2, 0.08, 'South India', 'India'),
('dosakaya_pappu_andhra_indian', 'Dosakaya Pappu (Yellow Cucumber Dal)', 102, 6.8, 13.2, 2.8, 2.8, 2.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['yellow_cucumber_dal_andhra','dosakaya_dal_andhra'], true, NULL, 'dal', 218, 0, 0.6, 0, 298, 28, 1.8, 8, 6.4, 0, 24, 0.7, 98, 3.4, 0.04, 'South India', 'India'),
('pappu_charu_andhra_indian', 'Pappu Charu (Andhra Dal Rasam)', 78, 4.8, 10.4, 2.2, 2.6, 2.8, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_dal_rasam_pappu_charu','tamarind_dal_soup_andhra'], true, NULL, 'dal', 318, 0, 0.5, 0, 278, 28, 1.4, 12, 6.8, 0, 18, 0.5, 82, 2.8, 0.04, 'South India', 'India'),
('pachi_pulusu_andhra_indian', 'Pachi Pulusu (Raw Tamarind Rasam Andhra)', 48, 1.2, 9.4, 1.2, 1.0, 3.8, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['raw_tamarind_rasam_andhra','uncooked_tamarind_soup_andhra'], true, NULL, 'soup_rasam', 298, 0, 0.3, 0, 148, 18, 0.8, 8, 4.2, 0, 12, 0.3, 38, 1.4, 0.02, 'South India', 'India'),
('andhra_sakinalu_snack_indian', 'Sakinalu (Andhra Rice Ring Snack)', 398, 6.8, 68.4, 10.8, 2.4, 1.8, 20, 60, 3, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sakinalu_telangana_snack','rice_rings_andhra_snack'], true, NULL, 'snack', 348, 0, 2.4, 0, 98, 24, 2.4, 2, 0.4, 0, 18, 0.6, 82, 3.8, 0.02, 'South India', 'India'),
('pootharekulu_plain_andhra_indian', 'Pootharekulu Plain (Andhra Rice Paper Sweet)', 368, 4.8, 64.2, 10.4, 0.8, 42.8, 20, 40, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rice_paper_sweet_andhra','pootharekulu_atreyapuram'], true, NULL, 'dessert', 48, 8, 8.2, 0, 88, 18, 0.8, 4, 0.4, 0, 8, 0.4, 68, 2.4, 0.02, 'South India', 'India'),
('pootharekulu_ghee_jaggery_indian', 'Pootharekulu Ghee and Jaggery', 388, 4.6, 62.8, 13.2, 0.6, 48.4, 20, 40, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ghee_pootharekulu','jaggery_pootharekulu_andhra'], true, NULL, 'dessert', 42, 18, 10.8, 0, 78, 22, 0.7, 8, 0.2, 4, 6, 0.3, 62, 2.2, 0.02, 'South India', 'India'),
('kobbari_annam_fresh_andhra_indian', 'Kobbari Annam Fresh Coconut Rice (Andhra)', 192, 3.6, 32.4, 6.2, 1.8, 2.4, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fresh_coconut_rice_andhra','kobbarannam_andhra'], true, NULL, 'rice', 148, 0, 5.4, 0, 148, 8, 0.8, 2, 0.4, 0, 18, 0.5, 78, 3.2, 0.04, 'South India', 'India'),
('daddojanam_plain_curd_rice_indian', 'Daddojanam Plain (Andhra Curd Rice)', 128, 4.2, 21.8, 3.2, 0.6, 2.8, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_curd_rice_plain','perugu_annam_andhra'], true, NULL, 'rice', 168, 12, 2.2, 0, 138, 98, 0.4, 8, 0.8, 2, 12, 0.6, 92, 3.4, 0.04, 'South India', 'India'),
('daddojanam_spiced_andhra_indian', 'Daddojanam Spiced Mustard Curry Leaves', 138, 4.4, 21.4, 4.2, 0.8, 2.4, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['perugu_annam_spiced','curd_rice_andhra_tempering'], true, NULL, 'rice', 178, 12, 2.4, 0, 148, 102, 0.5, 12, 1.2, 2, 14, 0.6, 96, 3.6, 0.04, 'South India', 'India'),
('punugulu_plain_andhra_indian', 'Punugulu Plain (Andhra Batter Fritters)', 248, 6.8, 32.4, 10.8, 1.6, 1.2, 20, 100, 5, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['batter_fritters_andhra','punugulu_crispy_snack'], true, NULL, 'snack', 328, 0, 2.4, 0, 118, 28, 1.4, 8, 0.8, 0, 18, 0.6, 82, 3.8, 0.04, 'South India', 'India'),
('punugulu_onion_chilli_andhra_indian', 'Punugulu Onion and Chilli (Andhra)', 258, 7.2, 33.2, 11.2, 1.8, 1.4, 20, 100, 5, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['onion_punugulu_andhra','masala_punugulu_andhra'], true, NULL, 'snack', 338, 0, 2.6, 0, 128, 30, 1.6, 6, 1.4, 0, 20, 0.7, 86, 4.0, 0.04, 'South India', 'India'),
('maagaya_andhra_raw_mango_pickle_indian', 'Maagaya Raw Mango Pickle (Andhra)', 128, 1.6, 12.8, 8.2, 2.4, 6.4, 20, 20, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['maagaya_andhra_mango','mamidikaya_pickle_andhra'], true, NULL, 'pickle_condiment', 2248, 0, 1.2, 0, 128, 22, 0.8, 18, 4.8, 0, 12, 0.3, 28, 1.2, 0.04, 'South India', 'India'),
('avakaya_fresh_unaged_andhra_indian', 'Avakaya Fresh Unaged (Andhra Mango Pickle)', 138, 1.8, 13.4, 8.8, 2.6, 5.8, 20, 20, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fresh_avakaya_andhra','raw_avakaya_andhra'], true, NULL, 'pickle_condiment', 2148, 0, 1.4, 0, 138, 24, 1.0, 22, 5.2, 0, 14, 0.3, 32, 1.4, 0.04, 'South India', 'India'),
('hyderabadi_mutton_kacchi_dum_biryani_indian', 'Hyderabadi Mutton Kacchi Dum Biryani', 248, 16.8, 28.4, 8.2, 1.2, 1.8, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kacchi_mutton_dum_biryani_hyderabad','raw_mutton_biryani_hyderabad'], true, NULL, 'biryani', 468, 68, 4.2, 0, 298, 32, 2.8, 18, 2.8, 4, 32, 3.4, 168, 14.2, 0.14, 'South India', 'India'),
('hyderabadi_mutton_pakki_biryani_indian', 'Hyderabadi Mutton Pakki Dum Biryani', 238, 15.8, 29.2, 7.8, 1.0, 1.6, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pakki_mutton_biryani_hyderabad','cooked_mutton_biryani_hyderabad'], true, NULL, 'biryani', 448, 64, 3.8, 0, 278, 28, 2.4, 14, 2.4, 4, 28, 3.0, 158, 12.8, 0.12, 'South India', 'India'),
('hyderabadi_chicken_dum_plain_biryani_indian', 'Hyderabadi Chicken Dum Biryani', 224, 15.4, 28.8, 6.4, 0.8, 1.4, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyd_chicken_dum_biryani','hyderabadi_murgh_biryani'], true, NULL, 'biryani', 428, 54, 2.8, 0, 258, 26, 2.0, 12, 2.0, 4, 24, 2.4, 148, 11.4, 0.10, 'South India', 'India'),
('hyderabadi_egg_dum_biryani_plain_indian', 'Hyderabadi Egg Dum Biryani', 212, 9.8, 32.4, 5.8, 0.8, 1.2, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['anda_dum_biryani_hyderabad','egg_biryani_hyderabad'], true, NULL, 'biryani', 408, 148, 2.4, 0, 218, 42, 1.8, 62, 1.6, 8, 22, 1.6, 128, 10.2, 0.08, 'South India', 'India'),
('hyderabadi_veg_dum_biryani_plain_indian', 'Hyderabadi Vegetable Dum Biryani', 196, 5.4, 34.8, 5.2, 2.4, 2.8, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['veg_dum_biryani_hyderabad','sabzi_dum_biryani_hyd'], true, NULL, 'biryani', 388, 0, 2.4, 0, 238, 28, 1.8, 38, 4.8, 0, 26, 1.0, 118, 8.4, 0.08, 'South India', 'India'),
('hyderabadi_prawn_dum_biryani_plain_indian', 'Hyderabadi Prawn Dum Biryani', 228, 14.8, 30.2, 5.8, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['jheenga_dum_biryani_hyderabad','prawn_biryani_hyderabad'], true, NULL, 'biryani', 448, 112, 2.4, 0, 268, 58, 1.8, 12, 1.8, 12, 28, 1.8, 158, 14.8, 0.28, 'South India', 'India'),
('hyderabadi_mutton_haleem_plain_indian', 'Hyderabadi Mutton Haleem Plain', 182, 14.8, 16.4, 7.2, 2.4, 1.2, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_haleem_plain_hyderabad','hyderabadi_harees_mutton'], true, NULL, 'stew_porridge', 448, 62, 2.8, 0, 318, 42, 2.8, 12, 1.8, 4, 36, 3.2, 178, 12.4, 0.10, 'South India', 'India'),
('hyderabadi_chicken_haleem_plain_indian', 'Hyderabadi Chicken Haleem', 162, 14.2, 16.8, 5.8, 2.2, 1.0, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chicken_haleem_hyderabad_plain','murgh_haleem_hyderabad'], true, NULL, 'stew_porridge', 428, 54, 2.2, 0, 298, 38, 2.4, 8, 1.4, 4, 32, 2.2, 158, 11.2, 0.08, 'South India', 'India'),
('hyderabadi_mixed_haleem_indian', 'Hyderabadi Mixed Mutton Chicken Haleem', 172, 14.6, 16.6, 6.4, 2.2, 1.0, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mixed_haleem_hyderabad','combo_haleem_hyderabad'], true, NULL, 'stew_porridge', 438, 58, 2.5, 0, 308, 40, 2.6, 10, 1.6, 4, 34, 2.8, 168, 11.8, 0.09, 'South India', 'India'),
('pathar_ka_gosht_hyderabadi_indian', 'Pathar Ka Gosht (Stone-Grilled Mutton)', 262, 26.4, 3.8, 16.4, 0.6, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['stone_grilled_mutton_hyderabad','pathar_gosht_hyderabad'], true, NULL, 'meat_dry', 448, 88, 7.2, 0, 368, 28, 3.2, 8, 1.8, 4, 28, 4.8, 188, 18.2, 0.06, 'South India', 'India'),
('dum_ka_murgh_whole_hyderabadi_indian', 'Dum Ka Murgh Whole (Hyderabadi)', 218, 20.8, 6.4, 13.2, 1.0, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dum_chicken_hyderabad_whole','dum_ka_murgh_hyd'], true, NULL, 'chicken_curry', 428, 78, 5.8, 0, 308, 28, 1.8, 24, 2.4, 6, 28, 2.2, 168, 14.4, 0.12, 'South India', 'India'),
('dum_ka_murgh_boneless_hyderabadi_indian', 'Dum Ka Murgh Boneless (Hyderabadi)', 228, 22.4, 5.8, 14.2, 0.8, 2.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['boneless_dum_murgh_hyderabad'], true, NULL, 'chicken_curry', 438, 82, 6.2, 0, 318, 24, 1.6, 18, 2.0, 6, 26, 2.4, 178, 15.2, 0.12, 'South India', 'India'),
('murgh_kali_mirch_hyderabadi_plain_indian', 'Murgh Kali Mirch (Black Pepper Chicken Hyd)', 212, 21.8, 4.8, 13.4, 0.8, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['black_pepper_chicken_hyderabad','kali_mirch_murgh_hyd'], true, NULL, 'chicken_curry', 418, 76, 5.4, 0, 298, 26, 1.6, 14, 1.8, 6, 24, 2.0, 162, 13.8, 0.10, 'South India', 'India'),
('murgh_kali_mirch_rich_gravy_hyderabadi_indian', 'Murgh Kali Mirch Rich Gravy (Hyderabadi)', 228, 20.8, 5.4, 14.8, 0.6, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rich_black_pepper_chicken_hyd'], true, NULL, 'chicken_curry', 428, 78, 6.8, 0, 288, 24, 1.4, 12, 1.4, 6, 22, 1.8, 158, 13.2, 0.10, 'South India', 'India'),
('baghare_baingan_hyderabadi_plain_indian', 'Baghare Baingan (Hyderabadi Stuffed Brinjal)', 142, 3.4, 10.8, 9.8, 3.8, 4.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_brinjal_gravy','baingan_masala_hyderabadi'], true, NULL, 'vegetable', 228, 0, 1.8, 0, 318, 42, 1.4, 12, 5.2, 0, 24, 0.5, 72, 2.6, 0.10, 'South India', 'India'),
('baghare_baingan_tamarind_heavy_indian', 'Baghare Baingan Tamarind Heavy Version', 152, 3.2, 12.4, 10.2, 3.6, 5.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['tamarind_baghare_baingan','khatti_baingan_hyderabad'], true, NULL, 'vegetable', 238, 0, 1.9, 0, 328, 38, 1.5, 10, 4.8, 0, 22, 0.4, 68, 2.4, 0.09, 'South India', 'India'),
('khatti_dal_hyderabadi_plain_indian', 'Khatti Dal Plain (Hyderabadi Sour Lentil)', 112, 6.8, 14.8, 3.4, 3.2, 3.8, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_sour_dal','tamarind_lentil_hyd_khatti'], true, NULL, 'dal', 308, 0, 0.8, 0, 308, 32, 2.4, 12, 6.4, 0, 28, 0.8, 108, 4.2, 0.04, 'South India', 'India'),
('khatti_dal_spinach_hyderabadi_indian', 'Khatti Dal with Spinach (Hyderabadi)', 118, 7.4, 14.4, 3.6, 3.8, 3.2, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_palak_khatti_dal'], true, NULL, 'dal', 318, 0, 0.9, 0, 348, 58, 3.2, 98, 8.4, 0, 34, 0.9, 118, 4.6, 0.06, 'South India', 'India'),
('tala_hua_gosht_plain_hyderabadi_indian', 'Tala Hua Gosht Plain (Hyderabadi Fried Mutton)', 288, 24.8, 4.4, 19.2, 0.8, 1.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_fried_mutton','tala_gosht_hyd'], true, NULL, 'meat_dry', 468, 92, 8.4, 0, 358, 28, 3.4, 8, 1.8, 4, 28, 4.8, 188, 18.4, 0.06, 'South India', 'India'),
('tala_hua_gosht_liver_hyderabadi_indian', 'Tala Hua Gosht with Liver (Hyderabadi)', 298, 26.2, 5.2, 19.8, 0.8, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['liver_fried_mutton_hyd','kaleji_gosht_tala_hyd'], true, NULL, 'meat_dry', 478, 248, 8.8, 0, 378, 32, 8.2, 78, 2.2, 4, 32, 4.4, 198, 22.4, 0.06, 'South India', 'India'),
('shikampuri_kebab_plain_hyderabadi_indian', 'Shikampuri Kebab Plain (Hyderabadi)', 228, 18.4, 12.8, 12.4, 1.8, 2.4, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['shikampur_kebab_hyderabad','hyderabadi_stuffed_kebab'], true, NULL, 'kebab', 448, 78, 5.2, 0, 298, 42, 2.8, 14, 1.8, 4, 26, 2.8, 178, 14.8, 0.08, 'South India', 'India'),
('shikampuri_kebab_paneer_hyderabadi_indian', 'Shikampuri Kebab Paneer Stuffed (Hyderabadi)', 238, 17.8, 13.4, 13.2, 1.6, 2.6, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['paneer_stuffed_shikampuri','veg_stuffed_shikampuri_hyd'], true, NULL, 'kebab', 428, 68, 5.8, 0, 288, 68, 2.4, 22, 1.4, 6, 28, 2.4, 188, 13.8, 0.08, 'South India', 'India'),
('tahari_vegetable_hyderabadi_indian', 'Tahari Vegetable (Hyderabadi)', 188, 4.2, 32.8, 5.4, 2.2, 2.8, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['vegetable_tahari_hyderabad','sabzi_tahari_hyd'], true, NULL, 'rice', 368, 0, 2.4, 0, 228, 28, 1.8, 38, 4.8, 0, 24, 0.8, 108, 6.4, 0.08, 'South India', 'India'),
('tahari_mutton_hyderabadi_indian', 'Tahari with Mutton (Hyderabadi)', 228, 14.2, 28.4, 7.4, 1.4, 1.8, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_tahari_hyderabad','gosht_tahari_hyd'], true, NULL, 'rice', 418, 58, 3.4, 0, 278, 32, 2.4, 12, 2.8, 4, 28, 2.8, 148, 11.4, 0.10, 'South India', 'India'),
('mutton_marag_plain_hyderabadi_indian', 'Mutton Marag Plain (Hyderabadi Bone Soup)', 112, 12.4, 4.8, 5.2, 0.8, 1.2, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_mutton_bone_soup','marag_shorba_hyd'], true, NULL, 'soup_rasam', 428, 52, 2.4, 0, 268, 38, 2.2, 8, 1.2, 2, 18, 2.8, 138, 8.8, 0.10, 'South India', 'India'),
('mutton_marag_spiced_hyderabadi_indian', 'Mutton Marag Spiced (Hyderabadi)', 122, 13.2, 5.2, 5.8, 1.0, 1.4, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['masaledar_marag_hyd','spiced_bone_soup_hyderabad'], true, NULL, 'soup_rasam', 438, 56, 2.6, 0, 278, 42, 2.4, 10, 1.4, 2, 20, 3.0, 148, 9.4, 0.10, 'South India', 'India'),
('dalcha_lamb_lentil_hyderabadi_indian', 'Dalcha Lamb Lentil Stew (Hyderabadi)', 152, 10.8, 14.8, 5.8, 3.4, 2.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_dalcha_lamb','dal_gosht_hyderabadi_dalcha'], true, NULL, 'stew_porridge', 358, 42, 2.4, 0, 318, 42, 2.8, 12, 2.4, 4, 32, 2.4, 148, 9.8, 0.08, 'South India', 'India'),
('dalcha_vegetarian_hyderabadi_indian', 'Dalcha Vegetarian (Hyderabadi)', 128, 6.8, 16.4, 4.2, 4.2, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['veg_dalcha_hyderabad','vegetarian_dalcha_hyd'], true, NULL, 'dal', 328, 0, 1.4, 0, 298, 48, 2.4, 18, 4.2, 0, 28, 0.8, 118, 4.8, 0.06, 'South India', 'India'),
('khubani_ka_meetha_plain_hyderabadi_indian', 'Khubani Ka Meetha Plain (Hyderabadi)', 198, 2.8, 42.8, 2.8, 3.4, 34.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['apricot_dessert_hyderabad','khubani_meetha_hyd'], true, NULL, 'dessert', 12, 12, 0.8, 0, 248, 18, 1.2, 18, 2.4, 2, 12, 0.3, 38, 1.4, 0.02, 'South India', 'India'),
('khubani_ka_meetha_cream_hyderabadi_indian', 'Khubani Ka Meetha with Cream (Hyderabadi)', 228, 3.2, 42.4, 6.4, 3.2, 34.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['apricot_dessert_cream_hyderabad','khubani_cream_hyd'], true, NULL, 'dessert', 18, 24, 4.2, 0, 238, 28, 1.0, 28, 2.0, 2, 10, 0.3, 42, 1.8, 0.04, 'South India', 'India'),
('sheer_khurma_plain_hyderabadi_indian', 'Sheer Khurma Plain (Hyderabadi)', 198, 5.8, 28.4, 7.8, 0.8, 22.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_sheer_khurma_plain','vermicelli_milk_dessert_hyd'], true, NULL, 'dessert', 88, 24, 5.4, 0, 218, 148, 0.4, 38, 0.8, 8, 18, 0.8, 128, 5.2, 0.06, 'South India', 'India'),
('sheer_khurma_rich_nuts_hyderabadi_indian', 'Sheer Khurma Rich Nuts (Hyderabadi)', 248, 6.8, 28.8, 12.4, 1.2, 22.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_sheer_khurma_rich','eid_sheer_khurma_hyd'], true, NULL, 'dessert', 92, 28, 6.8, 0, 248, 158, 0.6, 42, 0.6, 8, 22, 0.9, 138, 6.2, 0.08, 'South India', 'India'),
('hyderabadi_mutton_kofta_curry_indian', 'Hyderabadi Mutton Kofta Curry', 218, 16.8, 8.4, 14.2, 1.4, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_kofta_hyderabad','gosht_kofta_gravy_hyd'], true, NULL, 'mutton_curry', 438, 74, 6.2, 0, 308, 38, 2.8, 16, 2.4, 4, 28, 3.2, 168, 13.8, 0.08, 'South India', 'India'),
('hyderabadi_chicken_kofta_curry_indian', 'Hyderabadi Chicken Kofta Curry', 198, 16.2, 8.8, 12.4, 1.2, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chicken_kofta_hyderabad','murgh_kofta_gravy_hyd'], true, NULL, 'chicken_curry', 418, 68, 5.4, 0, 288, 32, 1.8, 14, 2.0, 4, 24, 2.2, 158, 12.4, 0.08, 'South India', 'India'),
('paradise_biryani_prawn_hyderabadi_indian', 'Paradise Biryani Prawn (Hyderabadi)', 232, 15.2, 30.4, 6.0, 0.8, 1.4, 350, 350, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated', ARRAY['paradise_jheenga_biryani','paradise_prawn_biryani_hyd'], true, 'Paradise Biryani', 'biryani', 452, 118, 2.6, 0, 272, 62, 1.8, 12, 1.8, 12, 28, 1.8, 162, 15.2, 0.28, 'South India', 'India'),
('shah_ghouse_mutton_haleem_indian', 'Shah Ghouse Mutton Haleem (Hyderabadi)', 188, 15.4, 16.8, 7.6, 2.4, 1.4, 250, 250, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated', ARRAY['shah_ghouse_haleem','tolichowki_haleem_hyd'], true, 'Shah Ghouse Hotel', 'stew_porridge', 458, 64, 3.0, 0, 328, 44, 2.8, 12, 1.8, 4, 36, 3.2, 182, 12.8, 0.10, 'South India', 'India'),
('hyderabadi_fish_dum_biryani_indian', 'Hyderabadi Fish Dum Biryani', 218, 14.6, 29.8, 5.4, 0.8, 1.4, 350, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fish_dum_biryani_hyderabad','meen_biryani_hyd'], true, NULL, 'biryani', 428, 56, 2.2, 0, 262, 32, 1.6, 10, 1.6, 10, 24, 1.8, 148, 13.4, 0.24, 'South India', 'India'),
('hyderabadi_mirchi_ka_salan_plain_indian', 'Hyderabadi Mirchi Ka Salan Plain', 132, 3.2, 8.4, 10.2, 2.4, 3.2, 100, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_chilli_curry','green_chilli_salan_hyd'], true, NULL, 'vegetable', 228, 0, 1.8, 0, 248, 38, 1.0, 14, 8.4, 0, 22, 0.4, 62, 2.2, 0.08, 'South India', 'India'),
('hyderabadi_mirchi_ka_salan_peanut_indian', 'Mirchi Ka Salan with Peanut Gravy (Hyd)', 148, 4.2, 8.8, 11.4, 2.8, 3.0, 100, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['peanut_mirchi_salan_hyd','groundnut_chilli_curry_hyd'], true, NULL, 'vegetable', 238, 0, 2.0, 0, 268, 42, 1.2, 12, 7.8, 0, 26, 0.6, 72, 2.6, 0.10, 'South India', 'India'),
('double_ka_meetha_plain_hyderabadi_indian', 'Hyderabadi Double Ka Meetha Plain', 288, 6.8, 42.4, 10.8, 0.8, 28.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['bread_halwa_hyderabad','double_meetha_hyd'], true, NULL, 'dessert', 148, 38, 6.8, 0, 148, 108, 0.8, 28, 0.4, 6, 14, 0.6, 98, 5.2, 0.06, 'South India', 'India'),
('double_ka_meetha_rabri_hyderabadi_indian', 'Double Ka Meetha with Rabri (Hyderabadi)', 318, 7.4, 44.2, 13.2, 0.6, 30.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['double_meetha_rabri_hyd','bread_halwa_rabri_hyderabad'], true, NULL, 'dessert', 158, 48, 8.4, 0, 162, 128, 0.6, 32, 0.2, 6, 12, 0.5, 108, 5.8, 0.06, 'South India', 'India'),
('kerala_sadya_matta_rice_indian', 'Kerala Sadya Matta Rice (Boiled)', 148, 3.2, 31.4, 0.8, 1.4, 0.6, 150, 200, 1, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['matta_rice_kerala_boiled','red_rice_kerala_sadya'], true, NULL, 'rice', 8, 0, 0.3, 0, 88, 8, 0.6, 0, 0, 0, 22, 0.8, 78, 4.2, 0.02, 'South India', 'India'),
('kerala_sadya_full_plate_bundle_indian', 'Kerala Sadya Full Plate Bundle', 168, 4.8, 28.4, 4.2, 2.8, 3.4, 600, 600, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['onam_sadya_kerala','vishu_sadya_bundle'], true, NULL, 'meal_bundle', 188, 4, 2.2, 0, 228, 48, 1.2, 28, 6.8, 2, 22, 0.6, 88, 4.8, 0.04, 'South India', 'India'),
('nei_payasam_ghee_kerala_indian', 'Nei Payasam (Kerala Ghee Payasam)', 288, 4.2, 44.8, 10.8, 0.2, 32.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ghee_payasam_kerala','nei_payasam_rice'], true, NULL, 'dessert', 42, 28, 8.4, 0, 128, 42, 0.6, 8, 0.4, 4, 8, 0.4, 78, 3.2, 0.04, 'South India', 'India'),
('nei_payasam_rice_based_kerala_indian', 'Nei Payasam Rice-Based (Kerala)', 298, 3.8, 46.2, 11.4, 0.1, 34.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rice_ghee_payasam_kerala','nei_payasam_plain_rice'], true, NULL, 'dessert', 38, 24, 9.2, 0, 112, 38, 0.4, 6, 0.2, 4, 6, 0.3, 68, 2.8, 0.04, 'South India', 'India'),
('kerala_meen_curry_coconut_oil_kodampuli_indian', 'Kerala Meen Curry Coconut Oil Kodampuli', 138, 15.4, 5.8, 6.2, 1.0, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kodampuli_fish_curry_kerala','gamboge_fish_curry_kerala'], true, NULL, 'fish_curry', 342, 58, 4.8, 0, 302, 28, 1.2, 18, 4.2, 18, 24, 0.9, 122, 16.8, 0.48, 'South India', 'India'),
('kerala_meen_curry_tamarind_base_indian', 'Kerala Meen Curry Tamarind Base', 122, 14.8, 4.8, 5.4, 1.2, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['tamarind_fish_curry_kerala','puli_meen_curry_kerala'], true, NULL, 'fish_curry', 358, 54, 3.8, 0, 288, 24, 1.0, 14, 5.8, 16, 22, 0.8, 112, 15.2, 0.44, 'South India', 'India'),
('chemeen_biryani_kerala_plain_indian', 'Chemeen Biryani Kerala Style (Prawn)', 208, 13.8, 29.4, 5.2, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['prawn_biryani_kerala_style','chemmeen_biryani_plain_kerala'], true, NULL, 'biryani', 428, 108, 2.4, 0, 258, 52, 1.6, 10, 1.6, 10, 26, 1.6, 148, 14.2, 0.28, 'South India', 'India'),
('chemeen_biryani_malabar_style_indian', 'Chemeen Biryani Malabar Style', 218, 14.2, 29.8, 5.8, 0.8, 1.6, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['malabar_prawn_biryani','kozhikode_chemeen_biryani'], true, NULL, 'biryani', 438, 114, 2.8, 0, 268, 56, 1.8, 12, 1.8, 12, 28, 1.8, 158, 15.2, 0.30, 'South India', 'India'),
('kerala_prawn_theeyal_indian', 'Kerala Prawn Theeyal (Roasted Coconut Curry)', 152, 14.8, 8.4, 7.2, 1.8, 2.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chemmeen_theeyal_kerala','prawn_roasted_coconut_curry'], true, NULL, 'seafood', 358, 118, 3.8, 0, 278, 62, 1.8, 12, 3.8, 16, 28, 1.2, 138, 20.4, 0.38, 'South India', 'India'),
('kerala_fish_theeyal_indian', 'Kerala Fish Theeyal (Roasted Coconut)', 142, 13.8, 7.8, 6.8, 1.6, 2.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['meen_theeyal_kerala','fish_roasted_coconut_curry_kerala'], true, NULL, 'fish_curry', 338, 54, 3.4, 0, 258, 28, 1.2, 14, 4.2, 16, 24, 0.8, 118, 16.8, 0.44, 'South India', 'India'),
('karimeen_pollichathu_plain_kerala_indian', 'Karimeen Pollichathu Plain (Pearl Spot Fish)', 192, 18.4, 4.8, 11.2, 1.2, 1.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pearl_spot_pollichathu_kerala','karimeen_banana_leaf_kerala'], true, NULL, 'fish_curry', 388, 74, 3.4, 0, 318, 32, 1.4, 18, 2.8, 18, 28, 1.0, 148, 22.4, 0.28, 'South India', 'India'),
('karimeen_pollichathu_spicy_kerala_indian', 'Karimeen Pollichathu Spicy (Pearl Spot)', 202, 18.8, 5.2, 12.4, 1.4, 1.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['spicy_karimeen_pollichathu','karimeen_hot_banana_leaf'], true, NULL, 'fish_curry', 408, 78, 3.8, 0, 328, 34, 1.6, 16, 2.6, 18, 30, 1.0, 158, 23.8, 0.28, 'South India', 'India'),
('kerala_mutton_stew_coconut_milk_indian', 'Kerala Mutton Stew Coconut Milk', 158, 13.2, 8.4, 8.6, 1.6, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_coconut_stew_kerala','nadan_mutton_stew_kerala'], true, NULL, 'mutton_curry', 318, 64, 6.8, 0, 278, 32, 1.8, 8, 3.8, 4, 24, 2.4, 138, 10.8, 0.08, 'South India', 'India'),
('kerala_mutton_stew_appam_bundle_indian', 'Kerala Mutton Stew with Appam Bundle', 192, 11.8, 22.4, 7.8, 1.4, 2.4, 400, 400, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_stew_appam_kerala','appam_mutton_stew_bundle'], true, NULL, 'mutton_curry', 298, 38, 5.4, 0, 238, 28, 1.4, 8, 2.8, 2, 20, 1.8, 118, 8.4, 0.06, 'South India', 'India'),
('andhra_fish_biryani_rohu_indian', 'Andhra Fish Biryani Rohu', 208, 13.8, 29.2, 5.6, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['rohu_fish_biryani_andhra','andhra_meen_biryani_rohu'], true, NULL, 'biryani', 418, 52, 2.2, 0, 248, 28, 1.6, 8, 1.6, 8, 22, 1.2, 138, 12.4, 0.34, 'South India', 'India'),
('andhra_fish_biryani_pomfret_indian', 'Andhra Fish Biryani Pomfret', 218, 14.4, 29.8, 5.8, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pomfret_biryani_andhra','andhra_meen_biryani_pomfret'], true, NULL, 'biryani', 428, 58, 2.4, 0, 258, 30, 1.6, 10, 1.4, 8, 24, 1.4, 142, 13.2, 0.28, 'South India', 'India'),
('andhra_egg_pulusu_curry_indian', 'Andhra Egg Pulusu (Egg Tamarind Curry)', 148, 8.8, 8.4, 9.2, 1.2, 2.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['egg_tamarind_curry_andhra','kodi_guddu_pulusu_andhra'], true, NULL, 'egg_curry', 348, 188, 2.8, 0, 218, 42, 1.6, 68, 2.8, 8, 14, 1.2, 118, 10.4, 0.08, 'South India', 'India'),
('andhra_egg_curry_dry_indian', 'Andhra Egg Curry Dry Masala', 162, 10.4, 6.8, 10.8, 0.8, 1.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dry_egg_curry_andhra','kodi_guddu_vepudu_andhra'], true, NULL, 'egg_curry', 368, 204, 3.4, 0, 228, 44, 1.4, 72, 2.2, 8, 16, 1.4, 128, 11.2, 0.08, 'South India', 'India'),
('telangana_chicken_gongura_curry_indian', 'Telangana Chicken Curry (Gongura Base)', 178, 18.2, 6.8, 9.4, 1.4, 2.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['telangana_gongura_kozhi','telangana_sorrel_chicken'], true, NULL, 'chicken_curry', 388, 68, 3.6, 0, 308, 28, 1.8, 16, 6.4, 6, 28, 1.8, 152, 13.2, 0.12, 'South India', 'India'),
('telangana_mutton_curry_spicy_indian', 'Telangana Mutton Curry Spicy', 198, 18.8, 7.2, 11.4, 1.4, 2.0, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['spicy_mutton_curry_telangana','telangana_gosht_curry'], true, NULL, 'mutton_curry', 418, 76, 4.8, 0, 358, 34, 2.8, 10, 2.4, 4, 30, 3.2, 168, 14.8, 0.08, 'South India', 'India'),
('telangana_mutton_pulusu_indian', 'Telangana Mutton Pulusu (Tamarind Mutton)', 182, 16.8, 9.4, 9.2, 1.8, 3.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_tamarind_curry_telangana','gosht_pulusu_telangana'], true, NULL, 'mutton_curry', 398, 72, 3.8, 0, 338, 32, 2.4, 8, 3.2, 4, 28, 2.8, 158, 13.4, 0.08, 'South India', 'India'),
('hyderabadi_lukhmi_minced_meat_indian', 'Hyderabadi Lukhmi (Minced Meat Pastry)', 298, 12.4, 24.8, 17.4, 1.2, 1.8, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['lukhmi_keema_pastry_hyd','hyderabadi_puff_meat'], true, NULL, 'snack', 428, 48, 6.8, 0, 198, 32, 1.8, 8, 1.2, 2, 18, 1.6, 128, 8.4, 0.06, 'South India', 'India'),
('hyderabadi_lukhmi_chicken_indian', 'Lukhmi Chicken Filling (Hyderabadi)', 288, 12.8, 24.2, 16.8, 1.0, 1.6, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chicken_lukhmi_hyderabad','murgh_lukhmi_hyd'], true, NULL, 'snack', 418, 44, 6.4, 0, 188, 28, 1.4, 6, 1.0, 2, 16, 1.4, 118, 7.8, 0.06, 'South India', 'India'),
('hyderabadi_nihari_beef_indian', 'Hyderabadi Nihari Slow Beef Stew', 178, 16.8, 8.2, 9.4, 1.2, 1.8, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_nalli_nihari','slow_beef_stew_hyderabad'], true, NULL, 'stew_porridge', 448, 64, 3.8, 0, 318, 28, 2.4, 8, 1.2, 2, 22, 3.4, 158, 12.4, 0.08, 'South India', 'India'),
('hyderabadi_nihari_mutton_indian', 'Hyderabadi Nihari Mutton', 188, 17.4, 8.4, 10.2, 1.4, 1.6, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['mutton_nihari_hyderabad','gosht_nihari_hyd'], true, NULL, 'stew_porridge', 458, 68, 4.2, 0, 328, 32, 2.6, 6, 1.0, 2, 24, 3.6, 168, 13.2, 0.08, 'South India', 'India'),
('hyderabadi_paya_trotter_soup_indian', 'Hyderabadi Paya (Trotter Soup)', 118, 12.8, 4.2, 6.2, 0.6, 1.0, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['paya_soup_hyderabad','trotter_soup_hyd'], true, NULL, 'soup_rasam', 438, 58, 2.8, 0, 258, 34, 1.8, 4, 0.8, 0, 14, 2.2, 118, 8.2, 0.08, 'South India', 'India'),
('hyderabadi_paya_roti_bundle_indian', 'Hyderabadi Paya with Roti Bundle', 198, 11.4, 22.4, 7.4, 1.4, 1.2, 450, 450, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['paya_roti_bundle_hyd','trotter_soup_roti_hyderabad'], true, NULL, 'soup_rasam', 388, 34, 2.6, 0, 228, 32, 1.6, 4, 0.6, 0, 16, 1.8, 108, 6.8, 0.06, 'South India', 'India'),
('andhra_gongura_mutton_biryani_indian', 'Andhra Gongura Mutton Biryani', 234, 15.8, 28.6, 7.4, 1.0, 1.8, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sorrel_mutton_biryani_andhra','gongura_gosht_biryani'], true, NULL, 'biryani', 448, 62, 3.4, 0, 278, 30, 2.4, 14, 4.4, 4, 28, 2.8, 152, 12.8, 0.12, 'South India', 'India'),
('andhra_gongura_chicken_biryani_indian', 'Andhra Gongura Chicken Biryani', 224, 15.2, 29.2, 6.8, 0.8, 1.6, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['sorrel_chicken_biryani_andhra','gongura_kozhi_biryani'], true, NULL, 'biryani', 428, 54, 2.8, 0, 258, 26, 1.8, 12, 4.0, 4, 24, 2.2, 142, 11.4, 0.10, 'South India', 'India'),
('kerala_beef_mappas_coconut_milk_indian', 'Kerala Beef Mappas (Beef in Coconut Milk)', 228, 18.8, 6.4, 15.2, 1.4, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beef_coconut_milk_curry_kerala','nadan_beef_mappas'], true, NULL, 'meat_curry', 368, 78, 8.4, 0, 318, 28, 2.8, 8, 2.4, 4, 24, 3.8, 168, 14.8, 0.08, 'South India', 'India'),
('kerala_beef_mappas_appam_bundle_indian', 'Kerala Beef Mappas with Appam Bundle', 242, 16.2, 22.8, 13.4, 1.2, 2.4, 400, 400, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['beef_mappas_appam_kerala','appam_beef_coconut_bundle'], true, NULL, 'meat_curry', 328, 48, 7.2, 0, 268, 26, 2.2, 8, 1.8, 2, 20, 2.8, 148, 11.2, 0.06, 'South India', 'India'),
('andhra_royyalu_biryani_plain_indian', 'Andhra Royyalu Biryani Plain (Prawn)', 222, 14.8, 30.4, 5.6, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_prawn_biryani_plain','royyalu_biryani_andhra'], true, NULL, 'biryani', 438, 112, 2.4, 0, 258, 56, 1.6, 10, 1.6, 10, 26, 1.6, 148, 14.4, 0.28, 'South India', 'India'),
('andhra_royyalu_biryani_spicy_indian', 'Andhra Royyalu Biryani Spicy Version', 232, 15.4, 30.8, 6.2, 0.8, 1.6, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['spicy_prawn_biryani_andhra','guntur_royyalu_biryani'], true, NULL, 'biryani', 448, 118, 2.6, 0, 268, 58, 1.8, 12, 2.0, 10, 28, 1.8, 152, 15.2, 0.28, 'South India', 'India'),
('kerala_neimeen_seer_fish_curry_indian', 'Kerala Neimeen Seer Fish Curry', 148, 17.8, 4.2, 6.8, 0.8, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['seer_fish_curry_kerala','neimeen_meen_curry'], true, NULL, 'fish_curry', 348, 64, 3.2, 0, 328, 28, 1.0, 12, 2.8, 18, 26, 1.0, 148, 20.4, 0.48, 'South India', 'India'),
('kerala_neimeen_tawa_fry_indian', 'Kerala Neimeen Tawa Fry (Seer Fish)', 198, 22.4, 4.8, 10.4, 0.6, 1.0, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['seer_fish_tawa_fry_kerala','neimeen_fry_tawa'], true, NULL, 'fish_dry', 388, 72, 2.8, 0, 358, 22, 0.8, 8, 1.8, 14, 22, 0.9, 168, 24.4, 0.52, 'South India', 'India'),
('kerala_chemmeen_ularthiyathu_indian', 'Kerala Chemmeen Ularthiyathu (Dry Prawn)', 172, 18.8, 5.4, 9.2, 1.0, 1.8, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dry_prawn_ularthiyathu_kerala','chemmeen_dry_roast_kerala'], true, NULL, 'seafood', 458, 134, 3.8, 0, 298, 68, 2.0, 12, 3.8, 16, 32, 1.4, 148, 24.2, 0.38, 'South India', 'India'),
('kerala_chemmeen_masala_roast_indian', 'Kerala Chemmeen Masala Roast', 182, 19.4, 5.8, 10.2, 1.2, 1.6, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['prawn_masala_roast_kerala','chemmeen_roast_spicy'], true, NULL, 'seafood', 468, 142, 4.2, 0, 308, 72, 2.2, 14, 3.4, 16, 34, 1.6, 158, 25.8, 0.38, 'South India', 'India'),
('hyderabadi_chicken65_restaurant_indian', 'Hyderabadi Chicken 65 Restaurant Style', 248, 22.4, 12.8, 13.2, 0.8, 1.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chicken_65_hyderabad_style','hyd_chicken65_restaurant'], true, NULL, 'chicken_dry', 468, 84, 4.8, 0, 308, 24, 1.4, 12, 1.8, 6, 26, 2.0, 178, 15.4, 0.08, 'South India', 'India'),
('hyderabadi_chicken65_boneless_indian', 'Hyderabadi Chicken 65 Boneless', 258, 24.2, 12.4, 14.2, 0.6, 1.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['boneless_chicken65_hyd','chicken65_boneless_hyderabad'], true, NULL, 'chicken_dry', 478, 88, 5.2, 0, 318, 22, 1.2, 8, 1.4, 6, 24, 2.2, 188, 16.4, 0.08, 'South India', 'India'),
('andhra_nattu_kodi_vepudu_dry_indian', 'Andhra Nattu Kodi Vepudu Dry', 234, 24.8, 5.4, 13.8, 0.8, 1.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['andhra_country_chicken_dry_fry','nattu_kodi_fry_andhra'], true, NULL, 'chicken_dry', 448, 82, 5.2, 0, 298, 22, 1.4, 10, 2.0, 6, 26, 2.0, 172, 14.8, 0.10, 'South India', 'India'),
('andhra_nattu_kodi_vepudu_bone_indian', 'Andhra Nattu Kodi Vepudu Bone-in', 224, 22.4, 5.8, 13.2, 1.0, 1.6, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['bone_in_nattu_kodi_vepudu_andhra','andhra_country_chicken_bone_fry'], true, NULL, 'chicken_dry', 438, 78, 4.8, 0, 288, 24, 1.6, 12, 2.4, 6, 28, 1.8, 162, 13.8, 0.10, 'South India', 'India'),
('kerala_kappa_biryani_plain_indian', 'Kerala Kappa Biryani (Tapioca with Beef)', 178, 10.4, 28.2, 4.2, 2.4, 1.8, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['tapioca_biryani_kerala','kappa_beef_kerala'], true, NULL, 'biryani', 318, 38, 2.2, 0, 368, 22, 1.2, 4, 2.8, 2, 24, 1.6, 108, 8.4, 0.06, 'South India', 'India'),
('kerala_kappa_biryani_beef_indian', 'Kerala Kappa Biryani Beef Variant', 198, 14.2, 26.4, 5.8, 2.8, 1.6, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kappa_beef_biryani_kerala','tapioca_beef_biryani'], true, NULL, 'biryani', 348, 52, 2.8, 0, 388, 24, 1.6, 4, 2.4, 2, 26, 2.4, 128, 10.2, 0.06, 'South India', 'India'),
('andhra_pesara_garelu_plain_indian', 'Andhra Pesara Garelu Plain (Moong Dal Vada)', 248, 10.4, 28.8, 11.2, 2.8, 1.4, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['moong_dal_vada_andhra','pesara_garelu_andhra_plain'], true, NULL, 'snack', 328, 0, 2.4, 0, 248, 32, 2.2, 8, 2.8, 0, 28, 0.9, 112, 4.8, 0.06, 'South India', 'India'),
('andhra_pesara_garelu_coconut_chutney_indian', 'Andhra Pesara Garelu with Coconut Chutney', 262, 10.2, 30.4, 11.8, 2.6, 2.2, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pesara_garelu_chutney_bundle','moong_vada_coconut_andhra'], true, NULL, 'snack', 338, 0, 2.8, 0, 258, 36, 2.0, 6, 2.4, 0, 26, 0.8, 116, 5.0, 0.06, 'South India', 'India'),
('hyderabadi_lamb_shorba_indian', 'Hyderabadi Lamb Shorba (Clear Soup)', 88, 9.8, 4.2, 3.8, 0.6, 1.0, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['lamb_shorba_hyderabad','gosht_shorba_hyd'], true, NULL, 'soup_rasam', 418, 42, 1.6, 0, 238, 18, 1.2, 4, 0.8, 0, 12, 1.8, 98, 6.4, 0.08, 'South India', 'India'),
('hyderabadi_chicken_shorba_indian', 'Hyderabadi Chicken Shorba (Clear Soup)', 78, 9.2, 3.8, 3.2, 0.4, 0.8, 250, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['chicken_shorba_hyderabad','murgh_shorba_hyd'], true, NULL, 'soup_rasam', 398, 38, 1.2, 0, 218, 14, 0.8, 4, 0.6, 0, 10, 1.4, 88, 5.8, 0.06, 'South India', 'India'),
('kerala_kozhi_nirachathu_plain_indian', 'Kerala Kozhi Nirachathu Plain (Stuffed Chicken)', 218, 22.4, 4.8, 13.2, 0.8, 1.8, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['stuffed_chicken_kerala_nirachathu','kozhi_nirachathu_plain'], true, NULL, 'chicken_curry', 408, 88, 5.4, 0, 298, 28, 1.6, 12, 1.8, 6, 26, 2.2, 168, 14.8, 0.10, 'South India', 'India'),
('kerala_kozhi_nirachathu_gravy_indian', 'Kerala Kozhi Nirachathu with Gravy', 228, 22.8, 6.4, 13.8, 1.0, 2.2, 250, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['stuffed_chicken_gravy_kerala','kozhi_nirachathu_gravy_kerala'], true, NULL, 'chicken_curry', 418, 92, 5.8, 0, 308, 30, 1.8, 14, 2.2, 6, 28, 2.4, 178, 15.4, 0.10, 'South India', 'India'),
('andhra_boti_intestine_curry_indian', 'Andhra Boti Curry (Goat Intestine)', 172, 16.4, 6.8, 9.4, 1.0, 1.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['goat_boti_curry_andhra','andhra_offal_curry_boti'], true, NULL, 'offal', 388, 168, 4.2, 0, 298, 22, 3.2, 8, 1.4, 2, 14, 2.4, 128, 12.8, 0.04, 'South India', 'India'),
('andhra_boti_dry_fry_indian', 'Andhra Boti Dry Fry (Goat Intestine)', 188, 18.2, 5.4, 11.2, 0.8, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['goat_boti_fry_andhra','dry_boti_vepudu_andhra'], true, NULL, 'offal', 408, 178, 4.8, 0, 308, 24, 3.6, 6, 1.2, 2, 16, 2.6, 138, 13.8, 0.04, 'South India', 'India'),
('hyderabadi_baingan_chutney_indian', 'Hyderabadi Baingan Chutney (Smoked Eggplant)', 72, 1.8, 8.4, 3.8, 2.8, 4.2, 50, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['smoked_eggplant_chutney_hyd','baingan_ka_raita_hyd'], true, NULL, 'pickle_condiment', 218, 0, 0.8, 0, 218, 18, 0.6, 4, 4.2, 0, 14, 0.3, 38, 1.4, 0.04, 'South India', 'India'),
('hyderabadi_tomato_chutney_indian', 'Hyderabadi Tomato Chutney', 68, 1.4, 9.2, 3.2, 1.8, 5.4, 50, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['tamatar_chutney_hyderabad','tomato_relish_hyd'], true, NULL, 'pickle_condiment', 248, 0, 0.6, 0, 198, 18, 0.6, 28, 8.4, 0, 12, 0.2, 28, 1.2, 0.04, 'South India', 'India'),
('kerala_ada_plain_rice_pancake_indian', 'Kerala Ada Plain (Thin Rice Pancake)', 148, 2.8, 30.4, 1.8, 1.0, 1.2, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ada_plain_kerala','thin_rice_ada_kerala'], true, NULL, 'breakfast', 78, 0, 1.2, 0, 72, 8, 0.6, 0, 0, 0, 12, 0.4, 58, 3.2, 0.02, 'South India', 'India'),
('kerala_ada_banana_jaggery_stuffed_indian', 'Kerala Ada Banana Jaggery Stuffed', 198, 3.2, 40.8, 3.6, 1.6, 18.4, 70, 140, 2, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['ada_banana_jaggery_kerala','sweet_ada_kerala'], true, NULL, 'breakfast', 62, 0, 2.8, 0, 128, 14, 0.8, 2, 1.8, 0, 14, 0.4, 62, 3.4, 0.03, 'South India', 'India'),
('atukulu_upma_andhra_plain_indian', 'Atukulu Upma Plain (Andhra Flattened Rice)', 168, 4.2, 28.4, 4.8, 1.4, 1.2, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['poha_upma_andhra','beaten_rice_upma_andhra'], true, NULL, 'breakfast', 228, 0, 1.4, 0, 168, 22, 1.2, 8, 2.8, 0, 16, 0.6, 82, 4.2, 0.04, 'South India', 'India'),
('atukulu_upma_vegetables_andhra_indian', 'Atukulu Upma with Vegetables (Andhra)', 178, 4.8, 29.2, 5.2, 2.2, 1.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['veg_poha_upma_andhra','vegetable_atukulu_andhra'], true, NULL, 'breakfast', 238, 0, 1.6, 0, 198, 28, 1.4, 18, 4.2, 0, 18, 0.7, 88, 4.6, 0.04, 'South India', 'India'),
('thalassery_fish_biryani_plain_indian', 'Thalassery Fish Biryani Plain', 212, 14.8, 28.4, 5.8, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['kerala_fish_biryani_thalassery','kozhikode_fish_biryani'], true, NULL, 'biryani', 418, 56, 2.4, 0, 252, 28, 1.4, 8, 1.6, 8, 24, 1.4, 138, 12.8, 0.28, 'South India', 'India'),
('thalassery_fish_biryani_pomfret_indian', 'Thalassery Fish Biryani Pomfret', 218, 15.2, 28.8, 6.2, 0.8, 1.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['pomfret_thalassery_biryani','malabar_pomfret_biryani'], true, NULL, 'biryani', 428, 62, 2.6, 0, 258, 30, 1.6, 10, 1.4, 8, 26, 1.6, 142, 13.4, 0.28, 'South India', 'India'),
('hyderabadi_mutton_qorma_indian', 'Hyderabadi Mutton Qorma (Korma)', 228, 16.8, 8.4, 14.8, 1.0, 2.8, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_gosht_korma','mutton_qorma_hyderabad'], true, NULL, 'mutton_curry', 418, 72, 6.8, 0, 308, 34, 2.4, 14, 2.0, 4, 26, 2.8, 162, 13.4, 0.08, 'South India', 'India'),
('hyderabadi_chicken_qorma_indian', 'Hyderabadi Chicken Qorma (Korma)', 208, 16.2, 8.8, 12.4, 0.8, 2.6, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['hyderabadi_murgh_korma','chicken_qorma_hyderabad'], true, NULL, 'chicken_curry', 398, 66, 5.6, 0, 288, 28, 1.6, 12, 1.6, 4, 22, 2.0, 152, 12.2, 0.08, 'South India', 'India'),
('andhra_crab_curry_peetha_indian', 'Andhra Crab Curry (Peetha Curry)', 118, 14.8, 5.4, 4.8, 0.8, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['peetha_curry_andhra','crab_curry_andhra_spicy'], true, NULL, 'seafood', 358, 72, 1.8, 0, 278, 62, 1.2, 8, 2.8, 8, 26, 2.8, 148, 18.4, 0.14, 'South India', 'India'),
('andhra_crab_masala_dry_indian', 'Andhra Crab Masala Dry', 138, 16.4, 5.8, 6.2, 1.0, 1.2, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dry_crab_masala_andhra','peetha_vepudu_andhra'], true, NULL, 'seafood', 378, 82, 2.2, 0, 298, 68, 1.4, 6, 2.4, 8, 28, 3.0, 158, 20.2, 0.14, 'South India', 'India'),
('kerala_tuna_curry_choora_indian', 'Kerala Tuna Curry (Choora Curry)', 158, 18.8, 4.2, 7.4, 0.8, 1.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['choora_curry_kerala','tuna_coconut_curry_kerala'], true, NULL, 'fish_curry', 368, 42, 2.8, 0, 348, 28, 1.4, 12, 2.8, 16, 28, 0.8, 158, 22.4, 0.62, 'South India', 'India'),
('kerala_tuna_fry_choora_indian', 'Kerala Tuna Fry (Choora Fry)', 208, 24.4, 4.8, 10.8, 0.6, 0.8, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['choora_fry_kerala','tuna_fry_kerala_spicy'], true, NULL, 'fish_dry', 408, 52, 2.4, 0, 378, 22, 1.2, 8, 1.8, 12, 24, 0.9, 178, 26.4, 0.68, 'South India', 'India'),
('hyderabadi_gosht_everyday_curry_indian', 'Hyderabadi Gosht Everyday Curry', 198, 16.4, 7.8, 12.2, 1.2, 2.4, 200, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['everyday_mutton_curry_hyd','gosht_curry_hyderabad_plain'], true, NULL, 'mutton_curry', 428, 68, 5.4, 0, 298, 28, 2.4, 10, 2.0, 4, 24, 2.6, 152, 12.4, 0.08, 'South India', 'India'),
('hyderabadi_gosht_masala_dry_indian', 'Hyderabadi Gosht Masala Dry', 242, 22.8, 5.2, 15.8, 0.8, 1.4, 150, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['dry_gosht_masala_hyderabad','mutton_dry_hyd_masala'], true, NULL, 'mutton_curry', 458, 84, 7.2, 0, 328, 24, 3.0, 8, 1.8, 4, 26, 4.2, 172, 16.4, 0.06, 'South India', 'India'),
('kerala_papadum_unfried_indian', 'Kerala Papadum Unfried (Appalam)', 368, 22.4, 58.4, 4.8, 2.4, 1.8, 15, 15, 1, 'manual', 'hyperregional-apr2026;ICMR;recipe-estimated', ARRAY['appalam_kerala_unfried','papadum_uncooked_kerala'], true, NULL, 'snack', 1248, 0, 0.8, 0, 188, 48, 4.8, 0, 0.8, 0, 48, 1.4, 228, 8.4, 0.04, 'South India', 'India'),
('kerala_papadum_fried_coconut_oil_indian', 'Kerala Papadum Fried (Coconut Oil)', 488, 20.8, 52.4, 24.8, 2.2, 1.4, 15, 15, 1, 'manual', 'hyperregional-apr2026;recipe-estimated', ARRAY['fried_papadum_coconut_oil_kerala','appalam_fried_kerala'], true, NULL, 'snack', 1148, 0, 20.4, 0, 168, 42, 4.2, 0, 0.6, 0, 42, 1.2, 208, 7.8, 0.04, 'South India', 'India'),
('bhapa_ilish_bengali_indian','Bhapa Ilish',195,16.8,2.4,13.2,0.2,0.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['steamed_hilsa','hilsa_paturi_steam','bhapa_hilsa'],true,NULL,'fish_curry',310,62,3.1,0,305,45,1.1,22,1.8,120,20,0.8,198,16,1.7,'East India','India'),
('daab_chingri_bengali_indian','Daab Chingri',182,16.2,5.8,11.0,0.8,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tender_coconut_prawn','coconut_shell_prawn'],true,NULL,'seafood_curry',340,145,4.2,0,380,48,1.4,18,3.5,90,28,1.1,225,22,0.9,'East India','India'),
('ilish_tel_jhol_bengali_indian','Ilish Macher Tel Jhol',210,17.0,3.0,14.5,0.3,0.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['ilish_tel_jhal','hilsa_oil_curry'],true,NULL,'fish_curry',355,65,3.5,0,298,42,1.2,24,2.0,115,21,0.9,205,17,1.8,'East India','India'),
('rui_macher_jhol_bengali_indian','Rui Macher Jhol',142,18.5,4.2,5.8,0.5,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['rohu_fish_curry','rui_maach_jhol'],true,NULL,'fish_curry',285,55,1.5,0,355,58,1.5,15,4.5,88,28,0.9,215,18,0.6,'East India','India'),
('katla_macher_jhol_bengali_indian','Katla Macher Jhol',148,19.2,3.8,6.0,0.4,0.6,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['catla_fish_curry','katla_jhol'],true,NULL,'fish_curry',295,58,1.6,0,362,62,1.6,12,4.2,85,29,1.0,218,20,0.5,'East India','India'),
('macher_kalia_rui_bengali_indian','Macher Kalia Rui',175,19.0,4.5,8.5,0.5,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['rui_kalia','rohu_kalia'],true,NULL,'fish_curry',420,62,2.2,0,348,52,1.8,18,3.8,82,26,1.0,208,19,0.7,'East India','India'),
('kosha_mangsho_chicken_bengali_indian','Kosha Mangsho Chicken',198,22.5,5.2,9.8,0.8,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;nutritionix',ARRAY['chicken_kosha','bengali_chicken_dry_curry'],true,NULL,'chicken_curry',485,88,2.8,0,398,38,2.2,42,5.5,68,32,2.5,248,28,0.4,'East India','India'),
('kosha_mangsho_veg_bengali_indian','Kosha Mangsho Veg',145,6.8,14.2,7.5,3.5,3.2,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['niramish_kosha','veg_kosha_mangsho'],true,NULL,'vegetable_curry',385,0,1.8,0,425,62,2.5,55,8.5,0,38,0.8,142,5,0.1,'East India','India'),
('murgir_jhol_bengali_indian','Murgir Jhol Bengali',165,20.8,5.5,6.8,0.8,1.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_chicken_curry','murgir_jhol_bangla'],true,NULL,'chicken_curry',445,78,1.8,0,388,42,1.8,38,5.8,65,28,1.8,222,24,0.3,'East India','India'),
('murgir_jhol_narikol_bengali_indian','Murgir Jhol Narikol',195,19.5,6.2,10.5,0.8,2.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['coconut_chicken_curry_bengali','narkel_murgir_jhol'],true,NULL,'chicken_curry',468,82,4.5,0,405,52,2.0,35,4.5,62,30,1.9,228,25,0.4,'East India','India'),
('chingri_malai_curry_bengali_indian','Chingri Malai Curry Bengali',220,17.5,5.8,14.2,0.5,3.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_prawn_malai','prawn_coconut_cream'],true,NULL,'seafood_curry',488,158,7.5,0,398,58,1.8,22,3.8,78,32,1.2,235,26,1.1,'East India','India'),
('chingri_bhapa_mustard_bengali_indian','Chingri Bhapa Mustard',185,18.2,3.5,11.0,0.3,0.8,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['steamed_prawn_mustard','bhapa_chingri'],true,NULL,'seafood_curry',395,148,2.2,0,368,52,1.6,18,2.5,72,28,1.1,218,24,0.8,'East India','India'),
('luchi_plain_bengali_indian','Luchi Plain',340,7.2,48.5,13.5,1.5,0.5,35,70,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bengali_puri','luchi_maida'],true,NULL,'bread',380,0,2.8,0,95,22,1.8,0,0,0,12,0.5,68,8,0.0,'East India','India'),
('luchi_aloo_dom_bengali_indian','Luchi with Aloo Dom',285,6.5,42.0,10.5,2.2,1.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['luchi_alur_dom','bengali_luchi_dum_aloo'],true,NULL,'bread_curry',445,0,2.2,0,285,38,2.2,12,8.5,0,22,0.6,98,9,0.0,'East India','India'),
('alur_dom_bengali_spicy_indian','Alur Dom Bengali Spicy',142,3.2,22.5,4.8,2.8,2.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_dum_aloo','aloo_dum_bengali'],true,NULL,'vegetable_curry',398,0,0.8,0,485,32,1.8,12,18.5,0,28,0.5,82,3,0.0,'East India','India'),
('cholar_dal_bengali_indian','Cholar Dal Bengali',178,9.5,26.5,4.2,5.5,2.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['chana_dal_bengali','bengali_cholar_dal'],true,NULL,'lentil',348,0,1.5,0,425,58,3.2,12,3.5,0,48,1.2,168,8,0.1,'East India','India'),
('begun_bhaja_mustard_bengali_indian','Begun Bhaja Mustard Oil',125,2.8,14.5,6.8,3.2,4.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bengali_fried_eggplant','brinjal_bhaja'],true,NULL,'vegetable_fry',285,0,1.0,0,278,18,0.8,5,3.2,0,15,0.3,52,2,0.0,'East India','India'),
('aloo_posto_bengali_indian','Aloo Posto Bengali',155,3.5,20.8,7.0,2.5,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['potato_poppy_seed','bengali_aloo_posto'],true,NULL,'vegetable_curry',298,0,1.2,0,368,148,2.2,5,12.5,0,42,1.5,195,4,0.0,'East India','India'),
('jhinge_posto_bengali_indian','Jhinge Posto Bengali',115,3.2,12.5,6.0,2.2,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['ridge_gourd_poppy','jhinge_posto_bengali'],true,NULL,'vegetable_curry',265,0,1.0,0,312,128,1.5,12,8.5,0,35,1.2,158,3,0.0,'East India','India'),
('shukto_bengali_indian','Shukto Bengali',98,3.8,10.5,5.0,3.5,2.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_bitter_mixed_veg','shukto_niramish'],true,NULL,'vegetable_curry',242,0,1.5,0,285,48,1.5,45,12.5,0,32,0.6,75,5,0.0,'East India','India'),
('mochar_ghonto_bengali_indian','Mochar Ghonto Bengali',132,4.5,16.8,5.8,4.5,3.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['banana_flower_curry','banana_blossom_bengali'],true,NULL,'vegetable_curry',288,0,1.8,0,398,38,2.8,12,5.5,0,42,0.8,88,5,0.0,'East India','India'),
('kathi_roll_chicken_kolkata_indian','Kathi Roll Chicken Kolkata',285,18.5,32.5,8.5,2.2,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated;nutritionix',ARRAY['chicken_kati_roll','kolkata_chicken_roll'],true,NULL,'street_food',588,78,2.2,0,388,58,2.5,32,5.5,48,32,1.8,198,22,0.2,'East India','India'),
('kathi_roll_egg_kolkata_indian','Kathi Roll Egg Kolkata',265,12.5,33.8,9.2,2.0,2.2,NULL,160,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['egg_kati_roll','dim_roll_kolkata'],true,NULL,'street_food',545,145,2.5,0,218,62,2.2,45,3.5,42,22,1.2,148,18,0.2,'East India','India'),
('kathi_roll_mutton_kolkata_indian','Kathi Roll Mutton Kolkata',310,20.5,32.0,11.5,2.0,2.2,NULL,190,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mutton_kati_roll','kolkata_mutton_roll'],true,NULL,'street_food',612,88,3.5,0,352,48,3.2,28,3.8,42,28,2.5,212,25,0.3,'East India','India'),
('kathi_roll_paneer_kolkata_indian','Kathi Roll Paneer Kolkata',278,14.2,33.5,9.8,2.2,3.5,NULL,170,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['paneer_kati_roll','kolkata_paneer_roll'],true,NULL,'street_food',568,35,3.2,0,285,148,1.8,28,3.5,28,25,0.8,178,16,0.1,'East India','India'),
('kolkata_biryani_mutton_indian','Kolkata Biryani Mutton',295,16.5,35.2,9.8,1.2,2.5,NULL,350,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['kolkata_mutton_biryani','bengali_biryani_mutton'],true,NULL,'biryani',685,72,3.2,0,295,45,2.8,25,3.2,45,28,2.2,182,18,0.3,'East India','India'),
('kolkata_biryani_chicken_indian','Kolkata Biryani Chicken',272,15.8,35.8,8.2,1.2,2.5,NULL,350,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['kolkata_chicken_biryani','bengali_biryani_chicken'],true,NULL,'biryani',668,68,2.5,0,288,42,2.5,22,3.0,42,26,1.8,175,15,0.2,'East India','India'),
('kolkata_biryani_egg_indian','Kolkata Biryani Egg',248,10.5,37.5,7.5,1.0,2.2,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['kolkata_egg_biryani','dim_biryani_kolkata'],true,NULL,'biryani',598,158,2.2,0,252,52,2.2,55,2.5,38,22,1.2,148,12,0.1,'East India','India'),
('phuchka_kolkata_indian','Phuchka Kolkata Style',185,4.5,32.5,5.2,3.5,3.8,20,80,4,'manual','hyperregional-apr2026;recipe-estimated;nutritionix',ARRAY['puchka_kolkata','golgappa_kolkata_style'],true,NULL,'street_food',365,0,1.0,0,185,28,2.5,8,5.5,0,18,0.5,88,6,0.0,'East India','India'),
('rosogolla_bengali_indian','Rosogolla Bengali',186,4.8,38.5,2.5,0.2,35.5,50,100,2,'manual','hyperregional-apr2026;ICMR-NIN;nutritionix',ARRAY['rasgulla_bengali','bengali_soft_rosogolla'],true,NULL,'sweet',48,12,1.2,0,92,118,0.5,15,0.5,8,12,0.4,115,5,0.1,'East India','India'),
('rosogolla_sponge_bengali_indian','Rosogolla Sponge Type',175,4.5,36.8,2.2,0.1,34.0,50,100,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sponge_rasgulla','soft_sponge_rosogolla'],true,NULL,'sweet',42,10,1.0,0,88,112,0.4,12,0.5,8,10,0.4,108,4,0.1,'East India','India'),
('sandesh_nolen_gur_bengali_indian','Sandesh Nolen Gur',325,8.5,48.5,11.5,0.2,42.5,40,80,2,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['nolen_gur_sandesh','date_palm_jaggery_sandesh'],true,NULL,'sweet',85,38,5.5,0,142,198,0.5,22,0.5,25,15,0.5,165,8,0.1,'East India','India'),
('sandesh_plain_bengali_indian','Sandesh Plain Bengali',310,8.2,46.5,10.8,0.1,42.0,40,80,2,'manual','hyperregional-apr2026;ICMR-NIN',ARRAY['plain_sandesh','sada_sandesh'],true,NULL,'sweet',82,36,5.2,0,135,188,0.4,20,0.4,22,14,0.5,158,7,0.1,'East India','India'),
('chomchom_bengali_indian','Chomchom Bengali',280,6.5,52.5,6.5,0.2,48.5,60,120,2,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['chom_chom','bengali_chomchom_sweet'],true,NULL,'sweet',78,32,3.5,0,125,168,0.5,18,0.4,20,12,0.4,148,6,0.1,'East India','India'),
('pantua_bengali_indian','Pantua Bengali',295,6.8,48.5,9.0,0.2,44.5,45,90,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bengali_pantua_sweet','pantua_mithai'],true,NULL,'sweet',82,35,4.5,0,128,178,0.5,18,0.4,22,13,0.4,152,7,0.1,'East India','India'),
('langcha_bengali_indian','Langcha Bengali',305,7.2,50.2,9.5,0.2,45.5,55,110,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bengali_langcha','shaktigarh_langcha'],true,NULL,'sweet',88,36,4.8,0,132,182,0.5,20,0.4,22,14,0.4,155,7,0.1,'East India','India'),
('kheer_kadam_bengali_indian','Kheer Kadam Bengali',345,9.5,52.5,12.0,0.2,46.5,65,130,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['kheerkandom','kheer_kandom_bengali'],true,NULL,'sweet',95,42,6.2,0,145,205,0.6,25,0.5,28,16,0.6,172,9,0.2,'East India','India'),
('patishapta_bengali_indian','Patishapta Bengali',265,6.5,42.5,8.5,1.5,28.5,NULL,120,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_patisapta','coconut_crepe_bengali'],true,NULL,'sweet',82,28,4.0,0,128,125,1.2,12,0.5,18,22,0.5,138,7,0.1,'East India','India'),
('nolen_gurer_sandesh_bengali_indian','Nolen Gurer Sandesh Bengali',335,9.0,51.5,11.8,0.2,46.0,40,80,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['date_jaggery_sandesh_bengali','nolen_gur_sandesh_west_bengal'],true,NULL,'sweet',88,40,5.8,0,148,202,0.5,22,0.5,26,15,0.5,168,8,0.1,'East India','India'),
('mishti_doi_bengali_indian','Mishti Doi Bengali',145,5.5,22.5,4.2,0.0,20.5,NULL,150,1,'manual','hyperregional-apr2026;ICMR-NIN;nutritionix',ARRAY['mishti_dahi','bengali_sweet_yogurt'],true,NULL,'dairy',68,18,2.5,0,198,165,0.2,15,0.5,18,14,0.5,128,5,0.1,'East India','India'),
('dalma_odia_tarkari_indian','Dalma Odia Tarkari',165,9.2,24.5,4.5,5.5,3.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['odia_dalma_mixed_veg','dalma_with_vegetables'],true,NULL,'lentil',368,0,1.2,0,488,62,3.5,35,12.5,0,52,1.2,188,8,0.1,'East India','India'),
('dalma_odia_kumro_indian','Dalma Odia Kumro',155,8.8,23.2,3.8,5.2,4.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['dalma_with_pumpkin','odia_kumro_dalma'],true,NULL,'lentil',355,0,1.0,0,468,55,3.2,88,10.5,0,48,1.1,178,7,0.1,'East India','India'),
('pakhala_bhata_plain_odia_indian','Pakhala Bhata Plain',112,2.8,24.5,0.5,0.5,0.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['pakhala_bhat_plain','fermented_rice_water_odisha'],true,NULL,'rice',125,0,0.1,0,98,22,0.8,0,0.5,0,12,0.3,48,2,0.0,'East India','India'),
('pakhala_badi_chura_odia_indian','Pakhala with Badi Chura',145,5.5,26.8,2.5,1.5,1.0,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['pakhala_badi','odia_rice_with_lentil_dumpling'],true,NULL,'rice',185,0,0.5,0,128,32,1.2,0,0.5,0,18,0.5,68,3,0.0,'East India','India'),
('basi_pakhala_odia_indian','Basi Pakhala Fermented',118,3.0,25.8,0.8,0.5,0.8,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['basi_pakhala_bhat','overnight_fermented_rice_odisha'],true,NULL,'rice',135,0,0.2,0,105,25,0.9,0,0.5,0,14,0.3,52,2,0.0,'East India','India'),
('chhena_poda_odia_indian','Chhena Poda Odia',295,10.5,42.5,9.5,0.2,35.5,NULL,120,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['odia_burnt_chhena','chhena_poda_odisha'],true,NULL,'sweet',105,42,5.5,0,158,212,0.5,25,0.5,28,16,0.6,175,9,0.2,'East India','India'),
('rasagola_odia_indian','Rasagola Odia Style',178,4.5,36.5,2.8,0.1,33.5,55,110,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_rasagola','odisha_rasgulla'],true,NULL,'sweet',52,12,1.5,0,95,122,0.4,15,0.5,10,11,0.4,112,5,0.1,'East India','India'),
('macha_besara_odia_indian','Macha Besara Odia',155,18.5,5.2,6.5,0.8,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_fish_mustard','macha_besara_odisha'],true,NULL,'fish_curry',358,58,1.5,0,345,55,1.5,18,4.5,85,26,0.9,205,17,0.5,'East India','India'),
('macha_ghanta_odia_indian','Macha Ghanta Odia',138,16.8,4.8,5.8,1.2,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_fish_head_curry','macha_ghanta_odisha'],true,NULL,'fish_curry',328,62,1.2,0,325,58,1.8,15,5.5,82,25,0.9,198,16,0.5,'East India','India'),
('chhena_gaja_odia_indian','Chhena Gaja Odia',315,9.8,46.5,10.5,0.2,40.5,55,110,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_chhena_gaja','nimapara_chhena_gaja'],true,NULL,'sweet',98,42,5.8,0,148,195,0.5,22,0.4,25,14,0.5,162,8,0.2,'East India','India'),
('chhena_jhili_odia_indian','Chhena Jhili Odia',285,9.2,43.5,9.0,0.2,38.5,45,90,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_chhena_jhili','nimapara_chhena'],true,NULL,'sweet',92,38,4.8,0,138,188,0.4,20,0.4,22,13,0.5,155,7,0.1,'East India','India'),
('poda_pitha_odia_indian','Poda Pitha Odia',248,6.5,42.5,6.8,1.5,22.5,NULL,120,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_burnt_pitha','poda_pitha_odisha'],true,NULL,'sweet',95,18,3.0,0,128,82,1.2,8,0.5,15,22,0.5,125,6,0.0,'East India','India'),
('arisa_pitha_odia_indian','Arisa Pitha Odia',268,4.2,50.5,6.5,1.2,28.5,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arisa_pitha_odisha','odia_rice_jaggery_pitha'],true,NULL,'sweet',88,12,3.2,0,85,45,1.5,0,0.5,0,15,0.4,78,5,0.0,'East India','India'),
('enduri_pitha_odia_indian','Enduri Pitha Odia',192,5.8,32.5,5.2,2.5,8.5,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['enduri_pitha_odisha','turmeric_leaf_pitha'],true,NULL,'sweet',78,22,1.8,0,98,52,1.2,12,1.5,0,18,0.5,88,4,0.0,'East India','India'),
('kakara_pitha_odia_indian','Kakara Pitha Odia',235,5.5,38.5,7.2,1.8,18.5,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['kakara_pitha_odisha','odia_fried_rice_pitha'],true,NULL,'sweet',85,18,3.5,0,92,48,1.5,0,0.5,0,16,0.4,82,5,0.0,'East India','India'),
('kanika_odia_indian','Kanika Odia Rice',245,5.2,42.5,6.5,0.5,8.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_sweet_rice','kanika_sweet_pulao'],true,NULL,'rice',198,0,3.5,0,95,25,1.2,12,0.5,0,15,0.4,68,4,0.0,'East India','India'),
('khechedi_odia_indian','Khechedi Odia',185,7.5,32.5,3.8,2.5,1.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['odia_khichdi','khichdi_odia_style'],true,NULL,'rice',285,0,1.2,0,248,38,1.8,12,2.5,0,28,0.8,118,6,0.0,'East India','India'),
('chungdi_malai_odia_indian','Chungdi Malai Odia',205,17.8,6.5,12.5,0.5,3.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_prawn_malai','chingudi_malai_odia'],true,NULL,'seafood_curry',468,148,5.5,0,385,52,1.6,20,3.5,72,28,1.1,218,22,0.9,'East India','India'),
('dahi_baigana_odia_indian','Dahi Baigana Odia',112,4.5,12.8,5.2,2.5,5.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_dahi_baingan','yogurt_eggplant_odia'],true,NULL,'vegetable_curry',265,12,2.2,0,288,78,0.8,8,3.5,8,18,0.4,72,3,0.0,'East India','India'),
('baigana_bhaja_odia_indian','Baigana Bhaja Odia',118,2.8,13.5,6.5,3.0,4.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_brinjal_fry','baigana_bhaja_odisha'],true,NULL,'vegetable_fry',275,0,1.0,0,268,18,0.8,5,3.0,0,14,0.3,50,2,0.0,'East India','India'),
('khatta_odia_indian','Khatta Odia',95,1.5,22.5,0.8,1.5,18.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_tamarind_khatta','odia_sweet_sour_chutney'],true,NULL,'condiment',215,0,0.1,0,185,22,1.2,0,2.5,0,12,0.2,25,2,0.0,'East India','India'),
('masor_tenga_tomato_assam_indian','Masor Tenga Tomato Assam',128,16.5,5.8,4.5,0.8,2.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['assamese_sour_fish_tomato','tenga_maas_bilahi'],true,NULL,'fish_curry',298,52,1.0,0,385,42,1.2,18,8.5,72,22,0.8,188,14,0.4,'East India','India'),
('masor_tenga_outenga_assam_indian','Masor Tenga Outenga Assam',118,15.8,4.5,4.0,0.8,2.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_sour_fish_elephant_apple','tenga_outenga'],true,NULL,'fish_curry',278,50,0.9,0,355,40,1.1,10,5.5,68,20,0.7,182,13,0.4,'East India','India'),
('masor_tenga_thekera_assam_indian','Masor Tenga Thekera Assam',122,16.2,4.8,4.2,0.8,2.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_sour_fish_kokum','tenga_thekera_maas'],true,NULL,'fish_curry',288,52,0.9,0,368,42,1.2,10,4.5,70,21,0.8,185,14,0.4,'East India','India'),
('khar_assamese_indian','Khar Assamese',85,3.5,10.5,3.2,2.5,1.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_khar_curry','alkali_curry_assam'],true,NULL,'vegetable_curry',488,0,0.5,0,298,52,1.5,15,5.5,0,28,0.5,75,4,0.0,'East India','India'),
('aloo_pitika_assamese_indian','Aloo Pitika Assamese',98,2.2,18.5,2.5,2.0,1.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_mashed_potato','pitika_assam'],true,NULL,'vegetable',285,0,0.5,0,385,22,1.0,5,8.5,0,22,0.4,65,2,0.0,'East India','India'),
('bilahi_aloo_pitika_assam_indian','Bilahi Aloo Pitika Assam',88,2.0,16.5,2.2,2.2,3.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tomato_potato_pitika','assamese_tomato_mash'],true,NULL,'vegetable',265,0,0.4,0,368,18,0.8,22,12.5,0,18,0.3,58,2,0.0,'East India','India'),
('duck_curry_assamese_indian','Duck Curry Assamese',242,20.5,4.8,15.8,0.5,1.2,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_duck_curry','hans_mangxo_assam'],true,NULL,'poultry_curry',528,92,5.2,0,388,32,2.5,35,3.5,48,28,2.8,225,28,0.4,'East India','India'),
('hanhor_mangxo_assam_indian','Hanhor Mangxo Assam',255,21.2,5.2,16.8,0.5,1.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_han_mangxo','duck_lauki_assam'],true,NULL,'poultry_curry',545,95,5.5,0,398,35,2.8,38,3.8,50,30,2.9,232,29,0.4,'East India','India'),
('masor_jol_assam_indian','Masor Jol Assam',115,15.5,4.2,3.8,0.5,1.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_fish_stew','masor_jhol_assam'],true,NULL,'fish_curry',268,48,0.8,0,355,38,1.0,12,4.5,65,20,0.7,178,12,0.3,'East India','India'),
('masor_muri_ghonto_assam_indian','Masor Muri Ghonto Assam',148,16.8,5.5,6.2,0.8,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_fish_head_rice','fish_head_rice_assam'],true,NULL,'fish_curry',298,58,1.5,0,348,45,1.5,15,4.0,70,22,0.9,195,15,0.4,'East India','India'),
('xaak_bhaji_assam_indian','Xaak Bhaji Assam',72,3.5,6.8,3.5,3.5,1.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_saag','xak_bhaji_assam'],true,NULL,'vegetable_fry',228,0,0.5,0,385,105,3.5,285,18.5,0,38,0.6,58,5,0.0,'East India','India'),
('gahori_mangxo_assam_indian','Gahori Mangxo Assam',268,22.5,4.5,18.5,1.5,1.0,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_pork_bamboo','pork_bamboo_shoot_assam'],true,NULL,'pork_curry',565,88,6.5,0,408,32,2.2,25,5.5,42,28,2.5,228,25,0.5,'East India','India'),
('bor_mach_curry_assam_indian','Bor Mach Curry Assam',162,19.5,4.0,7.5,0.5,1.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_big_fish_curry','bor_maas_assam'],true,NULL,'fish_curry',318,62,1.8,0,368,48,1.5,15,4.5,78,24,0.9,208,16,0.6,'East India','India'),
('til_pitha_assam_indian','Til Pitha Assam',285,6.8,40.5,11.5,2.5,18.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_sesame_rice_cake','til_pitha_bihu'],true,NULL,'sweet',88,8,1.8,0,125,215,3.5,0,0.5,0,45,1.5,188,10,0.2,'East India','India'),
('narikol_pitha_assam_indian','Narikol Pitha Assam',272,5.5,42.5,10.5,2.0,22.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_coconut_rice_cake','narikol_pitha_bihu'],true,NULL,'sweet',82,8,7.5,0,115,38,1.5,0,0.5,0,28,0.8,105,8,0.2,'East India','India'),
('paayoxh_assam_indian','Paayoxh Assam',185,4.8,32.5,5.2,0.2,22.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_rice_kheer','payox_assam'],true,NULL,'sweet',68,18,3.0,0,148,142,0.5,15,0.5,18,14,0.4,115,5,0.1,'East India','India'),
('jolpan_assam_indian','Jolpan Assam',198,4.2,38.5,4.5,2.0,8.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_jolpan','assam_bihu_breakfast'],true,NULL,'breakfast',62,8,1.8,0,128,28,1.2,0,0.5,0,18,0.4,68,5,0.0,'East India','India'),
('bhekuri_bamboo_assam_indian','Bhekuri Bamboo Assam',95,3.8,8.5,5.5,3.5,1.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_bamboo_shoot_curry','khorisa_curry_assam'],true,NULL,'vegetable_curry',285,0,0.8,0,268,28,1.2,8,3.5,0,22,0.4,52,3,0.0,'East India','India'),
('axone_pork_naga_indian','Axone Pork Naga',298,22.5,3.5,22.0,1.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_pork_naga','fermented_soybean_pork_nagaland'],true,NULL,'pork_curry',855,88,8.5,0,428,35,2.8,22,5.5,32,32,2.5,248,28,0.6,'North-East India','India'),
('axone_chicken_naga_indian','Axone Chicken Naga',245,24.5,3.8,15.2,1.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_chicken_naga','fermented_soybean_chicken_nagaland'],true,NULL,'chicken_curry',788,82,4.8,0,405,38,2.5,28,5.0,32,30,2.2,235,24,0.3,'North-East India','India'),
('axone_smoked_pork_naga_indian','Axone Smoked Pork Naga',335,20.5,3.2,26.5,1.2,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_smoked_pork','fermented_soy_smoked_pork_naga'],true,NULL,'pork_curry',1125,92,10.5,0,418,32,2.5,18,4.5,28,28,2.2,235,26,0.7,'North-East India','India'),
('axone_beef_naga_indian','Axone Beef Naga',265,25.2,3.5,16.8,1.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_beef_naga','fermented_soybean_beef_nagaland'],true,NULL,'beef_curry',825,88,5.8,0,418,38,3.2,18,5.0,30,32,2.8,248,28,0.4,'North-East India','India'),
('axone_veg_naga_indian','Axone Veg Naga',145,8.5,8.5,9.5,2.5,1.0,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_veg_naga','fermented_soy_vegetable_naga'],true,NULL,'vegetable_curry',688,0,1.5,0,398,52,2.5,22,5.5,0,38,1.2,148,12,0.2,'North-East India','India'),
('smoked_pork_naga_style_indian','Smoked Pork Naga Style',415,28.5,0.0,33.5,0.0,0.0,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_smoked_pork','dried_smoked_pork_nagaland'],true,NULL,'pork',1285,112,12.5,0,388,22,2.2,0,0.0,18,25,2.8,228,32,0.8,'North-East India','India'),
('anishi_naga_indian','Anishi Naga',285,20.5,8.5,19.5,2.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['anishi_pork_naga','yam_leaf_pork_nagaland'],true,NULL,'pork_curry',785,82,7.5,0,408,42,2.8,12,5.5,28,30,2.5,235,26,0.5,'North-East India','India'),
('galho_naga_indian','Galho Naga',165,8.5,28.5,2.8,1.5,0.8,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_rice_porridge','galho_nagaland'],true,NULL,'rice',368,22,0.8,0,268,28,1.5,8,3.5,18,22,0.8,105,8,0.1,'North-East India','India'),
('galho_pork_naga_indian','Galho Pork Naga',198,12.5,27.5,5.8,1.5,0.8,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_pork_rice_porridge','galho_pork_nagaland'],true,NULL,'rice',488,42,2.2,0,298,32,1.8,8,3.5,18,25,1.2,128,10,0.2,'North-East India','India'),
('bamboo_pork_naga_indian','Bamboo Shoot Pork Naga',258,21.8,5.5,17.2,2.5,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_bamboo_pork','pork_bamboo_nagaland'],true,NULL,'pork_curry',728,85,6.2,0,428,38,2.5,18,5.5,28,30,2.2,238,25,0.5,'North-East India','India'),
('naga_raja_mircha_chutney_indian','Naga Raja Mircha Chutney',45,1.8,8.5,1.2,3.5,4.5,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bhut_jolokia_chutney','ghost_pepper_chutney_naga'],true,NULL,'condiment',388,0,0.2,0,325,15,0.8,28,122.5,0,18,0.3,38,2,0.0,'North-East India','India'),
('eromba_dry_fish_manipur_indian','Eromba Dry Fish Manipur',125,8.5,10.5,6.5,3.5,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_eromba_nga','fermented_fish_eromba'],true,NULL,'vegetable_curry',785,28,1.2,0,368,48,2.5,22,8.5,0,32,0.9,148,12,0.3,'North-East India','India'),
('eromba_pork_manipur_indian','Eromba Pork Manipur',165,12.5,9.8,9.5,3.0,2.0,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_pork_eromba','eromba_with_pork'],true,NULL,'pork_curry',728,45,3.5,0,388,45,2.2,18,7.5,0,28,1.0,155,14,0.3,'North-East India','India'),
('eromba_veg_manipur_indian','Eromba Veg Manipur',95,4.5,11.5,4.2,4.0,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_veg_eromba','eromba_niramish'],true,NULL,'vegetable_curry',465,0,0.8,0,355,52,2.2,28,10.5,0,35,0.8,125,8,0.1,'North-East India','India'),
('chamthong_manipuri_indian','Chamthong Manipuri',88,4.2,12.5,2.5,4.0,2.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_vegetable_stew','chamthong_veg'],true,NULL,'vegetable_curry',268,0,0.4,0,385,52,2.0,55,12.5,0,32,0.6,88,5,0.0,'North-East India','India'),
('kangshoi_manipuri_indian','Kangshoi Manipuri',75,3.5,10.5,2.2,3.5,2.0,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_kangshoi','kangshoi_veg_broth'],true,NULL,'vegetable_curry',248,0,0.4,0,365,48,1.8,48,10.5,0,28,0.5,78,5,0.0,'North-East India','India'),
('morok_metpa_manipur_indian','Morok Metpa Manipur',55,2.5,8.5,1.8,3.5,3.5,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_chilli_paste','chilli_paste_manipur'],true,NULL,'condiment',388,0,0.2,0,315,18,1.2,28,65.5,0,18,0.4,42,3,0.0,'North-East India','India'),
('chagempomba_manipuri_indian','Chagempomba Manipuri',178,6.5,32.5,3.2,2.5,1.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_fermented_fish_rice','chagem_pomba'],true,NULL,'rice',588,18,0.8,0,248,32,1.5,12,3.5,0,22,0.6,98,8,0.2,'North-East India','India'),
('nga_thongba_manipur_indian','Nga Thongba Manipur',132,16.8,5.5,5.2,0.8,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_fish_curry','nga_thongba_manipuri'],true,NULL,'fish_curry',328,52,1.2,0,348,42,1.2,15,4.5,65,22,0.8,188,14,0.4,'North-East India','India'),
('ooti_manipuri_indian','Ooti Manipuri',162,9.8,24.5,4.0,5.5,2.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_black_gram_dal','ooti_manipur'],true,NULL,'lentil',348,0,1.2,0,388,58,3.2,15,3.5,0,48,1.2,165,8,0.1,'North-East India','India'),
('jadoh_chicken_meghalaya_indian','Jadoh Chicken Meghalaya',265,18.5,32.5,6.8,0.8,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_chicken_rice','jadoh_khasi_chicken'],true,NULL,'rice',488,72,2.2,0,338,38,2.2,28,3.5,42,28,1.8,185,18,0.2,'North-East India','India'),
('jadoh_pork_meghalaya_indian','Jadoh Pork Meghalaya',298,20.5,31.8,10.2,0.8,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_pork_rice','jadoh_khasi_pork'],true,NULL,'rice',528,78,3.5,0,348,35,2.5,22,3.2,38,26,1.9,192,20,0.3,'North-East India','India'),
('jadoh_beef_meghalaya_indian','Jadoh Beef Meghalaya',285,19.5,32.5,9.5,0.8,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_beef_rice','jadoh_khasi_beef'],true,NULL,'rice',515,75,3.2,0,342,36,3.0,20,3.0,36,25,2.0,188,19,0.3,'North-East India','India'),
('dohkhlieh_meghalaya_indian','Dohkhlieh Meghalaya',185,18.5,4.5,11.0,0.5,1.0,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_pork_salad','doh_khleh_meghalaya'],true,NULL,'pork_salad',628,82,4.2,0,408,28,2.2,8,4.5,28,26,2.0,218,24,0.4,'North-East India','India'),
('doh_snam_meghalaya_indian','Doh Snam Meghalaya',195,18.8,3.5,12.5,0.5,0.8,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_pork_blood_salad','doh_snam_khasi'],true,NULL,'pork_salad',648,88,4.8,0,398,28,2.5,8,3.5,25,24,1.9,215,22,0.4,'North-East India','India'),
('tungtap_meghalaya_indian','Tungtap Meghalaya',128,22.5,2.5,3.5,0.0,0.5,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_fermented_fish','tungtap_khasi'],true,NULL,'condiment',1250,72,1.0,0,388,32,1.8,5,0.5,25,28,1.2,298,35,0.8,'North-East India','India'),
('pumaloi_meghalaya_indian','Pumaloi Meghalaya',178,3.5,38.5,1.2,1.0,0.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_steamed_rice','pumaloi_khasi'],true,NULL,'rice_cake',5,0,0.3,0,88,8,0.8,0,0.0,0,12,0.3,65,4,0.0,'North-East India','India'),
('nakham_bitchi_meghalaya_indian','Nakham Bitchi Meghalaya',145,24.5,3.5,4.2,0.0,0.5,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_dried_fish_chutney','nakham_bitchi_khasi'],true,NULL,'condiment',1480,68,1.2,0,368,28,2.2,5,0.5,22,26,1.5,285,32,0.7,'North-East India','India'),
('kappa_meghalaya_indian','Kappa Tapioca Meghalaya',162,1.5,38.5,0.5,1.8,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['meghalaya_tapioca','kappa_meghalaya_boiled'],true,NULL,'vegetable',8,0,0.1,0,271,16,0.5,0,20.6,0,21,0.3,27,0,0.0,'North-East India','India'),
('bai_mizoram_indian','Bai Mizoram',238,19.5,6.5,15.5,2.5,1.0,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_pork_stew','bai_mizo_pork'],true,NULL,'pork_curry',588,82,5.8,0,418,35,2.2,18,5.5,28,28,2.2,228,25,0.5,'North-East India','India'),
('bai_veg_mizoram_indian','Bai Veg Mizoram',98,4.5,10.5,4.8,3.5,1.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_vegetable_stew','bai_niramish_mizo'],true,NULL,'vegetable_curry',288,0,0.8,0,385,48,2.0,28,8.5,0,32,0.6,88,6,0.0,'North-East India','India'),
('vawksa_rep_mizoram_indian','Vawksa Rep Mizoram',385,26.5,0.5,30.5,0.0,0.0,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_smoked_pork','vawksa_mizoram'],true,NULL,'pork',1185,108,11.5,0,378,22,2.0,0,0.0,18,24,2.5,222,30,0.7,'North-East India','India'),
('koat_pitha_mizoram_indian','Koat Pitha Mizoram',245,5.5,40.5,7.5,1.5,18.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_fried_banana_cake','koat_pitha_mizo'],true,NULL,'sweet',85,8,2.8,0,225,18,0.8,5,5.5,0,18,0.4,68,5,0.0,'North-East India','India'),
('chhangban_mizoram_indian','Chhangban Mizoram',198,8.5,35.5,3.8,2.0,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_rice_noodles','chhangban_mizo'],true,NULL,'noodles',328,0,0.8,0,128,18,1.2,0,0.5,0,18,0.5,88,6,0.0,'North-East India','India'),
('berma_tripura_indian','Berma Tripura',155,26.5,2.5,4.5,0.0,0.5,NULL,20,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_fermented_fish','berma_dried_fish'],true,NULL,'condiment',1385,72,1.2,0,398,28,2.5,5,0.5,22,28,1.5,292,36,0.9,'North-East India','India'),
('wahan_mosdeng_tripura_indian','Wahan Mosdeng Tripura',198,18.5,5.5,12.0,0.8,1.0,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_pork_chilli_salad','wahan_mosdeng_boro'],true,NULL,'pork_salad',688,78,4.5,0,408,25,2.2,8,5.5,22,24,1.9,212,22,0.4,'North-East India','India'),
('chakhwi_tripura_indian','Chakhwi Tripura',85,3.5,11.5,3.0,4.0,2.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_vegetable_stew','chakhwi_boro'],true,NULL,'vegetable_curry',268,0,0.5,0,378,48,2.0,45,10.5,0,30,0.5,82,5,0.0,'North-East India','India'),
('bangui_rice_tripura_indian','Bangui Rice Tripura',148,3.2,32.5,0.8,0.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_sticky_rice','bangui_chaal'],true,NULL,'rice',5,0,0.2,0,88,8,0.8,0,0.0,0,10,0.3,62,3,0.0,'North-East India','India'),
('thukpa_arunachali_indian','Thukpa Arunachali',185,12.5,26.5,4.5,2.0,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_thukpa','thukpa_arunachal_pradesh'],true,NULL,'noodles',588,42,1.5,0,328,38,2.2,22,4.5,28,28,1.5,165,15,0.2,'North-East India','India'),
('pika_pila_arunachal_indian','Pika Pila Arunachal',65,2.5,8.5,2.8,3.5,2.0,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_bamboo_pickle','pika_pila_pickle'],true,NULL,'condiment',488,0,0.4,0,198,18,0.8,8,3.5,0,15,0.3,38,2,0.0,'North-East India','India'),
('marua_arunachal_indian','Marua Finger Millet Arunachal',355,7.5,72.5,4.2,3.5,1.5,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['ragi_arunachal','finger_millet_arunachal'],true,NULL,'grain',8,0,0.8,0,408,344,3.9,0,0.0,0,137,2.3,283,2,0.0,'North-East India','India'),
('lukter_arunachal_indian','Lukter Arunachal Dried Beef',298,35.5,0.0,17.5,0.0,0.0,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_dried_beef','sun_dried_beef_arunachal'],true,NULL,'beef',985,108,6.8,0,398,18,3.5,0,0.0,18,28,4.2,318,38,0.5,'North-East India','India'),
('pehak_arunachal_indian','Pehak Arunachal Fermented Soy',198,18.5,10.5,10.2,4.5,1.0,NULL,50,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_fermented_soybean','pehak_paste'],true,NULL,'condiment',888,0,1.5,0,528,88,3.5,8,1.5,0,72,1.8,248,15,0.3,'North-East India','India'),
('phagshapa_sikkim_indian','Phagshapa Sikkim',275,20.5,4.5,20.0,1.0,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_pork_radish','phagshapa_sikkimese'],true,NULL,'pork_curry',628,88,7.5,0,418,32,2.5,12,8.5,28,28,2.2,232,26,0.5,'North-East India','India'),
('sha_phaley_sikkim_indian','Sha Phaley Sikkim',295,16.5,28.5,12.5,1.5,1.0,75,150,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_stuffed_bread','shaphaley_beef'],true,NULL,'bread',548,72,4.5,0,298,38,2.5,22,2.5,28,28,2.0,188,22,0.3,'North-East India','India'),
('sha_phaley_veg_sikkim_indian','Sha Phaley Veg Sikkim',265,10.5,32.5,10.2,2.0,1.5,70,140,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_veg_stuffed_bread','shaphaley_veg'],true,NULL,'bread',468,15,3.2,0,268,52,2.2,18,2.8,22,26,0.8,168,15,0.1,'North-East India','India'),
('thenthuk_sikkim_indian','Thenthuk Sikkim',178,10.5,28.5,3.8,2.0,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_hand_pulled_noodle','thenthuk_sikkimese'],true,NULL,'noodles',528,32,1.2,0,318,38,2.0,18,4.5,25,26,1.2,155,14,0.2,'North-East India','India'),
('thenthuk_pork_sikkim_indian','Thenthuk Pork Sikkim',215,14.5,27.5,7.2,2.0,1.5,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_pork_noodle_soup','thenthuk_pork_sikkimese'],true,NULL,'noodles',628,52,2.5,0,348,35,2.2,18,4.0,25,28,1.5,168,16,0.3,'North-East India','India'),
('gundruk_sikkim_indian','Gundruk Sikkim',65,5.5,8.5,1.5,4.5,1.0,NULL,50,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_fermented_greens','gundruk_sikkimese'],true,NULL,'vegetable',288,0,0.2,0,368,85,2.8,85,8.5,0,38,0.6,68,5,0.0,'North-East India','India'),
('gundruk_soup_sikkim_indian','Gundruk Soup Sikkim',55,4.2,6.8,1.2,3.5,0.8,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['fermented_greens_soup_sikkim','gundruk_ko_jhol'],true,NULL,'soup',348,0,0.2,0,298,72,2.2,65,6.5,0,32,0.5,55,4,0.0,'North-East India','India'),
('kinema_sikkim_indian','Kinema Sikkim',215,18.5,14.5,9.5,5.5,1.5,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_fermented_soybean','kinema_sikkimese'],true,NULL,'legume',388,0,1.5,0,648,198,3.8,5,1.5,0,68,2.2,248,15,0.3,'North-East India','India'),
('kinema_curry_sikkim_indian','Kinema Curry Sikkim',185,14.5,15.5,8.2,4.5,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_kinema_curry','kinema_tarkari'],true,NULL,'legume',428,0,1.5,0,568,168,3.2,8,2.5,0,58,1.8,228,12,0.2,'North-East India','India'),
('sinki_sikkim_indian','Sinki Radish Sikkim',48,2.5,8.5,0.8,3.5,1.5,NULL,50,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_fermented_radish','sinki_sikkimese'],true,NULL,'condiment',368,0,0.1,0,248,38,0.8,0,4.5,0,18,0.4,38,3,0.0,'North-East India','India'),
('sinki_soup_sikkim_indian','Sinki Soup Sikkim',42,2.2,6.5,0.8,3.0,1.2,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['fermented_radish_soup_sikkim','sinki_ko_jhol'],true,NULL,'soup',328,0,0.1,0,218,32,0.6,0,3.5,0,15,0.3,32,2,0.0,'North-East India','India'),
('shorshe_rui_bengali_indian','Shorshe Rui Bengali',168,19.5,3.8,8.2,0.4,0.6,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['mustard_rohu','rohu_mustard_curry'],true,NULL,'fish_curry',368,58,1.8,0,355,52,1.5,15,4.5,82,24,0.9,210,18,0.6,'East India','India'),
('macher_paturi_rui_bengali_indian','Macher Paturi Rui',178,19.8,3.5,9.5,0.3,0.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['rohu_banana_leaf','rui_paturi'],true,NULL,'fish_curry',348,60,2.0,0,362,48,1.5,12,3.5,80,22,0.9,208,17,0.6,'East India','India'),
('doi_maach_bengali_indian','Doi Maach Bengali',172,19.2,6.5,8.0,0.4,3.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['yogurt_fish_bengali','doi_maach_bangla'],true,NULL,'fish_curry',328,62,2.2,0,348,68,1.2,12,3.0,75,22,0.9,202,16,0.5,'East India','India'),
('doi_ilish_bengali_indian','Doi Ilish Bengali',205,17.5,6.8,12.5,0.3,3.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['hilsa_yogurt','dahi_ilish'],true,NULL,'fish_curry',358,68,3.2,0,310,55,1.2,22,2.2,118,22,0.9,205,18,1.7,'East India','India'),
('chingri_cutlet_bengali_indian','Chingri Cutlet Bengali',248,15.5,22.5,10.8,1.5,1.5,60,120,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['prawn_cutlet_bengali','chingri_cutlet_kolkata'],true,NULL,'street_food',528,142,2.8,0,298,62,1.8,22,2.5,48,28,1.2,215,22,0.7,'East India','India'),
('muri_ghonto_bengali_indian','Muri Ghonto Bengali',158,12.5,14.5,6.2,1.5,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['fish_head_rice_bengali','muri_ghonto_bangla'],true,NULL,'fish_curry',368,65,1.8,0,328,68,2.0,12,3.5,78,25,1.0,198,16,0.5,'East India','India'),
('sorshe_bata_maach_bengali_indian','Sorshe Bata Maach Bengali',165,18.8,3.8,8.5,0.4,0.6,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mustard_paste_fish','sorshe_maach'],true,NULL,'fish_curry',345,56,1.8,0,350,50,1.3,15,4.0,80,22,0.9,205,17,0.5,'East India','India'),
('aloo_posto_cream_bengali_indian','Aloo Posto Cream Bengali',168,3.8,21.5,8.2,2.5,1.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['potato_poppy_cream','posto_aloo_rich'],true,NULL,'vegetable_curry',308,0,1.5,0,372,155,2.2,5,12.0,0,44,1.6,198,4,0.0,'East India','India'),
('potol_posto_bengali_indian','Potol Posto Bengali',108,3.2,11.5,5.8,2.0,2.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['pointed_gourd_poppy','parwal_posto'],true,NULL,'vegetable_curry',258,0,0.9,0,298,118,1.4,10,8.5,0,32,1.1,148,3,0.0,'East India','India'),
('koraishutir_kochuri_bengali_indian','Koraishutir Kochuri Bengali',285,8.5,42.5,9.5,3.5,1.5,45,90,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['green_pea_stuffed_puri','kochuri_koraishuti'],true,NULL,'bread',368,0,2.2,0,198,38,2.5,8,5.5,0,28,0.8,118,8,0.0,'East India','India'),
('nimki_bengali_indian','Nimki Bengali',498,8.5,55.5,27.5,2.0,0.5,NULL,50,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bengali_namkeen','nimki_salt_crisp'],true,NULL,'snack',588,0,5.5,0,88,18,2.2,0,0.0,0,15,0.5,78,8,0.0,'East India','India'),
('ghugni_bengali_indian','Ghugni Bengali',185,9.5,28.5,4.5,6.5,2.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated;ICMR-NIN',ARRAY['bengali_white_pea_curry','ghugni_kolkata'],true,NULL,'street_food',448,0,1.0,0,445,48,3.5,12,5.5,0,38,1.2,165,8,0.1,'East India','India'),
('dhokar_dalna_bengali_indian','Dhokar Dalna Bengali',188,9.5,22.5,7.5,3.5,2.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['lentil_cake_curry','dhoka_dalna'],true,NULL,'vegetable_curry',448,0,1.8,0,398,72,3.0,15,5.5,0,45,1.2,168,8,0.1,'East India','India'),
('enchor_dalna_bengali_indian','Enchor Dalna Bengali',145,4.2,22.5,5.2,3.5,4.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['jackfruit_curry_bengali','echor_dalna'],true,NULL,'vegetable_curry',358,0,0.8,0,385,42,1.5,5,12.5,0,32,0.5,62,4,0.0,'East India','India'),
('aamer_dal_bengali_indian','Aamer Dal Bengali',155,8.5,22.5,3.8,4.5,4.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mango_lentil_bengali','raw_mango_dal'],true,NULL,'lentil',328,0,0.8,0,398,42,2.5,18,8.5,0,38,0.8,145,6,0.0,'East India','India'),
('sorse_ilish_dum_bengali_indian','Sorse Ilish Dum Bengali',225,17.8,3.5,16.2,0.3,0.6,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['dum_hilsa_mustard','ilish_dum_sorse'],true,NULL,'fish_curry',388,68,4.2,0,302,48,1.2,24,1.8,118,20,0.9,208,17,1.8,'East India','India'),
('pakhala_jeera_odia_indian','Pakhala Jeera Odia',125,3.2,26.8,1.2,0.5,0.8,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['pakhala_with_cumin','odia_pakhala_jeera'],true,NULL,'rice',145,0,0.2,0,108,25,0.9,0,0.5,0,14,0.3,52,2,0.0,'East India','India'),
('santula_odia_indian','Santula Odia',88,3.5,12.5,2.8,3.5,2.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_steamed_veg','santula_odisha'],true,NULL,'vegetable_curry',248,0,0.4,0,385,42,1.8,38,10.5,0,28,0.5,75,4,0.0,'East India','India'),
('macha_mahura_odia_indian','Macha Mahura Odia',148,17.8,6.5,5.5,1.0,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_fish_curry_spiced','macha_mahura_odisha'],true,NULL,'fish_curry',338,55,1.2,0,338,48,1.4,15,4.5,78,22,0.8,195,15,0.5,'East India','India'),
('odia_khatta_indian','Odia Khatta Sweet Sour',98,1.8,24.5,0.5,1.5,20.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_meetha_khatta','tamarind_jaggery_chutney_odia'],true,NULL,'condiment',225,0,0.1,0,188,22,1.2,5,3.5,0,12,0.2,28,2,0.0,'East India','India'),
('chhena_podo_plain_odia_indian','Chhena Podo Plain Odia',302,10.8,44.5,9.8,0.2,38.5,NULL,120,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_chhena_poda_plain','burnt_cheese_cake_odisha'],true,NULL,'sweet',108,44,5.8,0,155,208,0.5,22,0.5,26,15,0.6,172,9,0.2,'East India','India'),
('manda_pitha_coconut_odia_indian','Manda Pitha Coconut Odia',228,5.8,38.5,6.8,1.5,18.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_steamed_coconut_dumpling','manda_pitha_odisha'],true,NULL,'sweet',68,8,3.5,0,108,42,1.2,5,0.5,0,18,0.5,88,5,0.1,'East India','India'),
('chakuli_pitha_odia_indian','Chakuli Pitha Odia',215,4.5,40.5,4.8,1.5,1.0,NULL,100,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_rice_pancake','chakuli_pitha_odisha'],true,NULL,'sweet',125,0,0.8,0,88,28,1.2,0,0.5,0,15,0.4,72,4,0.0,'East India','India'),
('kheeri_odia_indian','Kheeri Odia Rice Pudding',188,5.5,30.5,6.2,0.2,22.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_rice_pudding','kheeri_odisha'],true,NULL,'sweet',72,22,3.5,0,148,148,0.5,18,0.5,18,15,0.5,118,5,0.1,'East India','India'),
('masor_tenga_jolphai_assam_indian','Masor Tenga Jolphai Assam',125,16.0,5.2,4.0,0.8,1.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_olive_fish_curry','tenga_jolphai'],true,NULL,'fish_curry',282,50,0.9,0,358,40,1.1,12,4.8,68,20,0.7,182,13,0.4,'East India','India'),
('duck_curry_coconut_assam_indian','Duck Curry Coconut Assam',265,21.0,6.5,17.2,0.8,2.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_duck_coconut','coconut_duck_assam'],true,NULL,'poultry_curry',548,95,7.2,0,408,42,2.8,35,3.5,48,30,2.9,235,28,0.5,'East India','India'),
('khar_papaya_assam_indian','Khar Papaya Assam',78,2.8,10.5,2.5,2.5,3.5,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['papaya_khar_assam','raw_papaya_khar'],true,NULL,'vegetable_curry',468,0,0.4,0,285,42,1.2,15,25.5,0,25,0.4,65,3,0.0,'East India','India'),
('jolpan_doi_assam_indian','Jolpan Doi Assam',215,6.5,38.5,5.8,2.0,12.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_jolpan_curd','jolpan_dahi'],true,NULL,'breakfast',72,14,2.8,0,148,98,1.2,8,0.5,10,20,0.5,88,6,0.0,'East India','India'),
('bamboo_curry_assam_pork_indian','Bamboo Curry Assam Pork',198,16.5,6.5,13.2,2.5,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['pork_bamboo_shoot_assam_curry','khorisa_pork'],true,NULL,'pork_curry',548,72,4.8,0,398,30,2.0,18,4.5,28,26,1.9,215,22,0.4,'East India','India'),
('pitha_til_assam_indian','Pitha Til Assam',292,7.0,41.5,11.5,2.5,18.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_sesame_pitha','til_pitha_sesame'],true,NULL,'sweet',88,8,1.8,0,125,215,3.5,0,0.5,0,45,1.5,188,10,0.2,'East India','India'),
('sunga_pitha_assam_indian','Sunga Pitha Bamboo Tube Assam',215,5.5,38.5,5.5,1.5,12.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['bamboo_tube_rice_cake','sunga_pitha_assam'],true,NULL,'sweet',15,8,1.5,0,108,18,1.0,0,0.5,0,15,0.3,75,4,0.0,'East India','India'),
('luchi_kosha_set_bengali_indian','Luchi Kosha Mangsho Set',365,18.5,38.5,15.8,1.5,2.2,NULL,350,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['luchi_mutton_kosha_set','bengali_sunday_meal'],true,NULL,'bread_curry',588,78,5.5,0,348,52,3.2,28,5.0,52,30,2.5,212,22,0.3,'East India','India'),
('posto_bora_bengali_indian','Posto Bora Bengali',215,6.5,22.5,11.5,2.0,1.5,40,80,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['poppy_seed_fritter','posto_bora_bengali'],true,NULL,'snack',288,18,2.0,0,198,178,2.5,8,2.5,0,42,1.5,195,6,0.0,'East India','India'),
('narkel_naru_bengali_indian','Narkel Naru Bengali',455,5.5,68.5,18.5,4.5,60.5,30,60,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['coconut_ball_bengali','naru_bengali_sweet'],true,NULL,'sweet',48,0,16.5,0,245,15,1.2,0,0.5,0,28,0.5,88,5,0.0,'East India','India'),
('til_naru_bengali_indian','Til Naru Bengali',485,10.5,62.5,22.5,3.5,52.5,25,50,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sesame_ball_bengali','tiler_naru'],true,NULL,'sweet',32,0,3.2,0,225,488,4.2,0,0.5,0,125,2.5,365,12,0.2,'East India','India'),
('moa_murmura_bengali_indian','Moa Murmura Bengali',398,6.5,80.5,7.5,1.5,48.5,50,100,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['puffed_rice_sweet_ball','moa_bengali'],true,NULL,'sweet',48,0,3.5,0,98,28,2.5,0,0.5,0,22,0.5,88,5,0.0,'East India','India'),
('kolkata_egg_roll_indian','Kolkata Egg Roll',272,11.5,33.5,9.8,2.0,2.5,NULL,160,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['kolkata_dim_roll','egg_roll_street_kolkata'],true,NULL,'street_food',548,148,2.8,0,225,58,2.2,42,3.2,40,22,1.2,148,16,0.2,'East India','India'),
('axone_bamboo_naga_indian','Axone Bamboo Naga',178,10.5,8.5,11.5,2.5,0.8,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['akhuni_bamboo_veg','axone_bamboo_nagaland'],true,NULL,'vegetable_curry',728,0,1.8,0,398,48,2.5,18,4.5,0,35,1.0,148,10,0.2,'North-East India','India'),
('galho_chicken_naga_indian','Galho Chicken Naga',188,14.5,26.5,4.5,1.5,0.8,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_chicken_porridge','galho_chicken_nagaland'],true,NULL,'rice',458,52,1.5,0,318,30,1.8,22,3.5,18,24,1.2,145,12,0.2,'North-East India','India'),
('pork_blood_curry_naga_indian','Pork Blood Curry Naga',198,15.5,5.5,13.5,0.5,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_pork_blood_dish','pork_blood_nagaland'],true,NULL,'pork_curry',728,198,5.2,0,308,18,3.5,0,2.5,18,18,2.5,178,28,0.4,'North-East India','India'),
('snail_curry_naga_indian','Snail Curry Naga',118,14.5,5.5,4.5,0.5,0.8,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['naga_snail_dish','escargot_naga_style'],true,NULL,'seafood_curry',388,72,1.0,0,268,88,3.5,8,2.5,18,28,1.5,148,18,0.3,'North-East India','India'),
('eromba_smoked_fish_manipur_indian','Eromba Smoked Fish Manipur',138,10.5,10.5,6.5,3.5,2.0,NULL,180,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_eromba_smoked_fish','smoked_fish_eromba'],true,NULL,'vegetable_curry',888,30,1.2,0,368,48,2.5,22,8.5,0,32,0.9,148,14,0.4,'North-East India','India'),
('singju_salad_manipur_indian','Singju Salad Manipuri',88,4.5,12.5,3.2,5.5,2.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_salad','singju_manipuri_salad'],true,NULL,'salad',248,0,0.5,0,388,52,2.5,45,12.5,0,32,0.6,78,5,0.0,'North-East India','India'),
('nganou_paaknam_manipur_indian','Nganou Paaknam Manipuri',165,18.5,8.5,6.2,1.0,1.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_fish_cake','nganou_paknam'],true,NULL,'fish_cake',488,68,1.8,0,348,42,1.5,18,4.5,65,25,1.0,198,18,0.5,'North-East India','India'),
('chamthong_chicken_manipur_indian','Chamthong Chicken Manipur',155,18.5,8.5,5.5,2.5,2.0,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['manipuri_chicken_stew','chamthong_chicken_manipuri'],true,NULL,'chicken_curry',368,68,1.5,0,398,48,1.8,38,8.5,28,28,1.5,185,18,0.2,'North-East India','India'),
('doh_jem_meghalaya_indian','Doh Jem Meghalaya',188,22.5,5.5,8.5,0.5,0.5,NULL,150,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_pork_liver','doh_jem_khasi'],true,NULL,'pork_offal',548,298,3.2,0,318,8,8.5,2285,10.5,18,15,3.5,255,32,0.3,'North-East India','India'),
('pumaloi_egg_meghalaya_indian','Pumaloi Egg Meghalaya',215,9.5,36.5,4.8,1.0,0.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['khasi_steamed_rice_egg','pumaloi_doh'],true,NULL,'rice_cake',168,158,1.5,0,148,28,1.2,55,0.5,18,18,0.8,115,12,0.1,'North-East India','India'),
('bai_bamboo_mizoram_indian','Bai Bamboo Mizoram',255,20.5,8.5,16.5,3.0,1.0,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_pork_bamboo_stew','bai_bamboo_mizo'],true,NULL,'pork_curry',628,86,6.2,0,428,32,2.2,18,5.5,28,28,2.2,228,24,0.5,'North-East India','India'),
('sawhchiar_mizoram_indian','Sawhchiar Mizoram',158,8.5,26.5,3.2,1.5,0.8,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_rice_porridge','sawhchiar_mizo'],true,NULL,'rice',428,28,1.0,0,268,28,1.5,8,3.0,18,22,0.8,105,8,0.2,'North-East India','India'),
('bamboo_pickle_mizoram_indian','Bamboo Shoot Pickle Mizoram',55,2.5,8.5,1.8,4.5,1.5,NULL,30,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_bamboo_pickle','hmarchha_bamboo'],true,NULL,'condiment',688,0,0.3,0,268,18,0.8,8,2.5,0,15,0.3,38,2,0.0,'North-East India','India'),
('koat_pitha_coconut_mizoram_indian','Koat Pitha Coconut Mizoram',258,5.8,42.5,8.5,2.0,22.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['mizo_coconut_banana_cake','koat_pitha_narikel'],true,NULL,'sweet',88,8,6.5,0,228,22,0.8,5,5.5,0,20,0.4,72,5,0.1,'North-East India','India'),
('chakhwi_pork_tripura_indian','Chakhwi Pork Tripura',198,17.5,10.5,11.0,3.5,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_pork_stew','chakhwi_pork_boro'],true,NULL,'pork_curry',588,72,4.2,0,398,38,2.0,28,8.5,22,26,1.8,195,20,0.4,'North-East India','India'),
('mui_borok_tripura_indian','Mui Borok Tripura',138,16.5,5.5,5.8,0.8,1.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_fish_curry','mui_borok_boro'],true,NULL,'fish_curry',688,52,1.2,0,338,42,1.5,15,5.5,65,22,0.8,188,14,0.4,'North-East India','India'),
('chowmein_tripura_indian','Chowmein Tripura Street Style',285,10.5,42.5,8.5,2.0,2.5,NULL,250,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['tripura_street_noodles','chowmein_agartala'],true,NULL,'noodles',748,28,2.2,0,228,28,1.8,22,3.5,18,22,0.8,128,12,0.1,'North-East India','India'),
('thukpa_arunachali_veg_indian','Thukpa Arunachali Veg',165,6.5,28.5,3.5,2.5,2.0,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_veg_noodle_soup','thukpa_veg_arunachal'],true,NULL,'noodles',448,0,0.8,0,298,35,1.8,35,5.5,0,25,0.8,115,10,0.1,'North-East India','India'),
('thukpa_arunachali_chicken_indian','Thukpa Arunachali Chicken',205,15.5,26.5,5.8,2.0,1.8,NULL,300,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_chicken_noodle_soup','thukpa_chicken_arunachal'],true,NULL,'noodles',568,52,1.8,0,328,38,2.0,22,4.5,25,26,1.5,165,15,0.2,'North-East India','India'),
('pika_pila_pork_arunachal_indian','Pika Pila Pork Arunachal',245,20.5,6.5,16.5,2.5,1.0,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['arunachal_bamboo_pork','pika_pila_pork_dish'],true,NULL,'pork_curry',588,82,6.0,0,408,28,2.2,15,4.5,25,26,1.8,215,22,0.4,'North-East India','India'),
('apong_rice_beer_assam_indian','Apong Rice Beer Assam',45,0.5,8.5,0.2,0.0,1.5,NULL,330,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_rice_beer','apong_assam'],true,NULL,'beverage',5,0,0.0,0,52,5,0.2,0,0.0,0,5,0.1,18,1,0.0,'East India','India'),
('phagshapa_radish_sikkim_indian','Phagshapa Radish Sikkim',255,20.0,6.5,17.5,1.5,1.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_pork_radish_stew','phagshapa_mula'],true,NULL,'pork_curry',618,86,6.5,0,408,35,2.5,10,9.5,25,28,2.2,228,25,0.5,'North-East India','India'),
('sel_roti_sikkim_indian','Sel Roti Sikkim Style',365,5.5,58.5,13.5,1.5,18.5,60,120,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_sel_roti','sikkimese_ring_bread'],true,NULL,'sweet',88,8,3.5,0,98,18,1.5,0,0.5,0,15,0.4,88,6,0.0,'North-East India','India'),
('kinema_dry_sikkim_indian','Kinema Dry Fermented Soy Sikkim',245,22.5,16.5,10.5,6.5,1.5,NULL,80,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_dry_kinema','kinema_fermented_soy_dry'],true,NULL,'legume',428,0,1.8,0,668,218,4.2,5,1.5,0,75,2.5,265,16,0.3,'North-East India','India'),
('gundruk_achar_sikkim_indian','Gundruk Ko Achar Sikkim',58,4.5,7.5,1.5,4.0,1.5,NULL,50,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['fermented_greens_pickle_sikkim','gundruk_achaar'],true,NULL,'condiment',368,0,0.2,0,298,72,2.2,62,5.5,0,32,0.5,55,4,0.0,'North-East India','India'),
('sinki_curry_sikkim_indian','Sinki Curry Sikkim',65,3.2,9.5,2.2,3.0,1.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['fermented_radish_curry','sinki_tarkari_sikkim'],true,NULL,'vegetable_curry',388,0,0.4,0,248,38,0.8,0,4.5,0,18,0.4,38,3,0.0,'North-East India','India'),
('sha_phaley_beef_sikkim_indian','Sha Phaley Beef Sikkim',315,18.5,28.5,14.5,1.5,1.0,75,150,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['sikkim_beef_stuffed_bread','shaphaley_beef_sikkim'],true,NULL,'bread',568,78,5.5,0,308,38,3.2,18,2.5,28,26,2.5,198,24,0.4,'North-East India','India'),
('chhena_rasgulla_odia_indian','Chhena Rasgulla Odia',182,4.8,37.5,2.5,0.1,34.5,50,100,2,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['odia_rasgulla_chhena','odia_chhena_ball'],true,NULL,'sweet',48,12,1.2,0,92,115,0.4,12,0.5,8,11,0.4,108,5,0.1,'East India','India'),
('aloo_potol_dalna_bengali_indian','Aloo Potol Dalna Bengali',132,3.8,19.5,5.2,2.5,2.5,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['potato_pointed_gourd_curry','alu_potol_dalna'],true,NULL,'vegetable_curry',358,0,0.8,0,342,38,1.2,12,8.5,0,28,0.5,72,4,0.0,'East India','India'),
('masor_tenga_bilahi_assam_indian','Masor Tenga Bilahi Assam',120,15.8,5.0,4.2,0.8,2.2,NULL,200,1,'manual','hyperregional-apr2026;recipe-estimated',ARRAY['assamese_tomato_sour_fish','tenga_bilahi_maas'],true,NULL,'fish_curry',278,50,0.9,0,362,40,1.1,18,8.0,68,20,0.7,180,13,0.4,'East India','India'),
('undhiyu_surti_style_indian', 'Surti Undhiyu', 198, 5.8, 20.1, 10.2, 5.1, 3.2, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN mixed-veg curry reference', ARRAY['surti_undhiyu','undhiyo_surti'], true, NULL, 'mixed_veg_curry', 380, 0, 2.8, 0, 420, 85, 2.2, 68, 12.4, 0, 42, 1.1, 90, 3.2, 0.18, 'West India', 'India'),
('undhiyu_kathiawadi_style_indian', 'Kathiawadi Undhiyu', 215, 5.4, 18.8, 12.1, 5.5, 2.9, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;higher ghee ratio vs Surti; ICMR reference', ARRAY['kathiawadi_undhiyu','saurashtra_undhiyu'], true, NULL, 'mixed_veg_curry', 390, 8, 4.2, 0, 410, 80, 2.1, 60, 10.8, 0, 40, 1.0, 88, 3.0, 0.16, 'West India', 'India'),
('methi_thepla_gujarati_indian', 'Methi Thepla (Gujarati)', 280, 8.2, 42.0, 8.5, 4.8, 2.1, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR flatbread reference;fenugreek leaves', ARRAY['fenugreek_thepla','methi_na_thepla'], true, NULL, 'flatbread', 420, 0, 1.2, 0, 310, 72, 3.8, 85, 8.2, 0, 55, 1.2, 115, 4.5, 0.08, 'West India', 'India'),
('bajra_thepla_gujarati_indian', 'Bajra Thepla (Gujarati)', 295, 7.8, 44.5, 9.2, 5.2, 1.8, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet flatbread variant', ARRAY['bajra_na_thepla','millet_thepla'], true, NULL, 'flatbread', 380, 0, 1.4, 0, 340, 42, 4.2, 15, 2.1, 0, 110, 1.8, 210, 5.2, 0.06, 'West India', 'India'),
('mooli_thepla_gujarati_indian', 'Mooli Thepla (Gujarati)', 272, 7.5, 41.8, 8.0, 4.5, 2.4, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;radish-stuffed/mixed flatbread', ARRAY['radish_thepla','mooli_na_thepla'], true, NULL, 'flatbread', 398, 0, 1.1, 0, 295, 68, 3.5, 10, 14.2, 0, 48, 1.1, 108, 4.1, 0.07, 'West India', 'India'),
('mix_veg_thepla_gujarati_indian', 'Mix Veg Thepla (Gujarati)', 278, 8.0, 42.5, 8.3, 4.7, 2.2, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;carrot+spinach+fenugreek variant', ARRAY['mixed_vegetable_thepla','mixed_thepla'], true, NULL, 'flatbread', 410, 0, 1.2, 0, 320, 75, 3.6, 55, 9.5, 0, 50, 1.2, 110, 4.2, 0.08, 'West India', 'India'),
('besan_dhokla_steamed_indian', 'Besan Dhokla (Steamed)', 155, 7.2, 22.8, 3.8, 1.8, 2.5, 30, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chickpea flour steamed cake;ICMR snack reference', ARRAY['gram_flour_dhokla','chickpea_dhokla'], true, NULL, 'steamed_snack', 520, 0, 0.6, 0, 180, 45, 1.8, 8, 1.2, 0, 22, 0.8, 95, 3.8, 0.04, 'West India', 'India'),
('white_dhokla_gujarati_indian', 'White Dhokla (Rice & Urad)', 148, 5.5, 25.2, 2.8, 1.2, 1.8, 30, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rice+urad dal fermented dhokla', ARRAY['safed_dhokla','rice_dhokla','khatta_white_dhokla'], true, NULL, 'steamed_snack', 480, 0, 0.5, 0, 145, 38, 1.2, 4, 0.8, 0, 18, 0.6, 72, 2.8, 0.03, 'West India', 'India'),
('khaman_gujarati_fresh_indian', 'Khaman (Fresh Gujarati)', 160, 7.8, 23.5, 4.2, 1.5, 3.2, 35, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fresh-made khaman distinct from packaged khaman_dhokla', ARRAY['soft_khaman','fresh_khaman'], true, NULL, 'steamed_snack', 540, 0, 0.7, 0, 190, 48, 1.9, 10, 1.5, 0, 24, 0.9, 98, 4.0, 0.04, 'West India', 'India'),
('rava_dhokla_suji_indian', 'Rava Dhokla (Suji)', 162, 5.8, 26.5, 3.5, 1.0, 2.8, 30, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;semolina dhokla variant', ARRAY['sooji_dhokla','semolina_dhokla'], true, NULL, 'steamed_snack', 490, 0, 0.5, 0, 155, 35, 1.0, 6, 0.9, 0, 15, 0.5, 68, 2.5, 0.02, 'West India', 'India'),
('fafda_plain_gujarati_indian', 'Fafda (Plain Gujarati)', 458, 10.5, 52.8, 22.5, 2.8, 1.2, 15, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;deep-fried chickpea flour snack', ARRAY['plain_fafda','sada_fafda'], true, NULL, 'fried_snack', 620, 0, 4.2, 0, 185, 42, 2.8, 5, 0.5, 0, 28, 1.0, 120, 5.2, 0.05, 'West India', 'India'),
('fafda_masala_gujarati_indian', 'Masala Fafda (Gujarati)', 468, 10.8, 52.2, 23.5, 2.9, 1.0, 15, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced fafda with black pepper and ajwain', ARRAY['spiced_fafda','pepper_fafda'], true, NULL, 'fried_snack', 680, 0, 4.5, 0, 190, 45, 3.0, 8, 0.8, 0, 30, 1.1, 125, 5.5, 0.05, 'West India', 'India'),
('jalebi_gujarati_style_indian', 'Jalebi (Gujarati Style)', 385, 3.2, 75.8, 8.5, 0.5, 45.2, 25, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin crispy Gujarati jalebi, less syrup', ARRAY['gujarati_jalebi','thin_jalebi_gujarati'], true, NULL, 'sweet_fried', 45, 0, 3.8, 0, 62, 22, 1.5, 2, 0.2, 0, 8, 0.3, 35, 1.2, 0.02, 'West India', 'India'),
('jalebi_jamnagari_indian', 'Jamnagari Jalebi', 395, 3.5, 77.2, 8.8, 0.4, 48.5, 30, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Jamnagar-style thick crispy jalebi, kesar-flavored', ARRAY['jamnagar_jalebi','kesar_jalebi_gujarat'], true, NULL, 'sweet_fried', 48, 0, 4.0, 0, 58, 25, 1.4, 5, 0.1, 0, 7, 0.3, 32, 1.0, 0.02, 'West India', 'India'),
('gathiya_plain_gujarati_indian', 'Gathiya (Plain)', 492, 11.2, 55.8, 24.8, 3.5, 1.5, NULL, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;plain besan fried snack', ARRAY['sada_gathiya','plain_gathiya_gujarat'], true, NULL, 'fried_snack', 580, 0, 4.8, 0, 195, 50, 3.2, 8, 0.5, 0, 32, 1.2, 130, 5.8, 0.05, 'West India', 'India'),
('gathiya_tikha_gujarati_indian', 'Tikha Gathiya (Spicy)', 498, 11.5, 55.2, 25.5, 3.6, 1.2, NULL, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spicy peppery gathiya', ARRAY['spicy_gathiya','tikha_gathiya'], true, NULL, 'fried_snack', 650, 0, 5.0, 0, 198, 52, 3.3, 12, 1.2, 0, 34, 1.3, 132, 6.0, 0.05, 'West India', 'India'),
('gathiya_nylon_gujarati_indian', 'Nylon Gathiya (Fine)', 505, 11.8, 54.8, 26.2, 3.4, 1.0, NULL, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ultra-fine delicate gathiya variety', ARRAY['nylon_sev_gathiya','fine_gathiya'], true, NULL, 'fried_snack', 540, 0, 5.2, 0, 192, 48, 3.1, 6, 0.4, 0, 30, 1.2, 128, 5.5, 0.05, 'West India', 'India'),
('sev_tikha_gujarati_indian', 'Tikha Sev (Spicy)', 516, 12.2, 53.5, 27.8, 3.8, 0.8, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coarse spicy besan sev', ARRAY['spicy_sev','tikha_besan_sev'], true, NULL, 'fried_snack', 720, 0, 5.5, 0, 200, 55, 3.5, 10, 1.5, 0, 35, 1.4, 135, 6.2, 0.06, 'West India', 'India'),
('sev_sada_gujarati_indian', 'Sada Sev (Plain)', 510, 11.8, 54.2, 26.8, 3.5, 0.5, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;plain mild besan sev', ARRAY['plain_sev','sada_besan_sev'], true, NULL, 'fried_snack', 580, 0, 5.0, 0, 192, 50, 3.2, 6, 0.4, 0, 32, 1.2, 128, 5.8, 0.05, 'West India', 'India'),
('sev_masala_gujarati_indian', 'Masala Sev (Gujarati)', 518, 12.0, 53.8, 27.2, 3.6, 1.2, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;masala-coated besan sev', ARRAY['masala_besan_sev','flavored_sev'], true, NULL, 'fried_snack', 680, 0, 5.2, 0, 196, 52, 3.4, 15, 2.0, 0, 33, 1.3, 130, 5.9, 0.05, 'West India', 'India'),
('bajra_bhakri_gujarati_indian', 'Bajra Bhakri (Gujarati)', 310, 8.5, 52.8, 7.5, 6.2, 1.0, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet thick flatbread, ICMR NIN', ARRAY['bajra_rotlo','millet_bhakri'], true, NULL, 'flatbread', 12, 0, 1.5, 0, 320, 28, 4.8, 5, 0.5, 0, 120, 1.8, 215, 5.8, 0.06, 'West India', 'India'),
('jowar_bhakri_maharashtrian_indian', 'Jowar Bhakri (Maharashtrian)', 302, 8.8, 55.2, 6.2, 5.8, 1.2, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sorghum thick flatbread;ICMR NIN jowar reference', ARRAY['jowar_rotla','sorghum_bhakri'], true, NULL, 'flatbread', 8, 0, 1.0, 0, 280, 22, 3.5, 4, 0.8, 0, 80, 1.2, 185, 4.5, 0.05, 'West India', 'India'),
('nachni_bhakri_indian', 'Nachni Bhakri (Finger Millet)', 298, 7.8, 54.5, 6.0, 5.5, 1.5, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ragi/nachni flatbread;ICMR NIN finger millet', ARRAY['ragi_bhakri','finger_millet_bhakri'], true, NULL, 'flatbread', 10, 0, 1.0, 0, 295, 344, 3.9, 6, 1.0, 0, 82, 1.1, 188, 3.8, 0.06, 'West India', 'India'),
('dal_dhokli_gujarati_style_indian', 'Dal Dhokli (Gujarati)', 185, 6.8, 28.5, 5.2, 3.8, 4.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;wheat dumplings in tuvar dal; sweet-savory', ARRAY['gujarati_dal_dhokli','dal_dhokri'], true, NULL, 'lentil_soup_with_dumpling', 420, 0, 1.2, 0, 310, 55, 2.8, 42, 5.2, 0, 38, 1.0, 118, 4.2, 0.08, 'West India', 'India'),
('dal_dhokli_spicy_indian', 'Dal Dhokli (Spicy Variant)', 190, 7.0, 28.8, 5.8, 3.9, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;less sweet, more pungent variant', ARRAY['tikha_dal_dhokli'], true, NULL, 'lentil_soup_with_dumpling', 480, 0, 1.5, 0, 318, 58, 2.9, 38, 4.8, 0, 40, 1.0, 120, 4.4, 0.08, 'West India', 'India'),
('khichu_rice_gujarati_indian', 'Khichu (Rice Flour)', 152, 3.2, 30.8, 2.5, 0.8, 0.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;steamed rice flour snack with cumin', ARRAY['papad_no_khichu','rice_khichu'], true, NULL, 'steamed_snack', 580, 0, 0.8, 0, 88, 12, 0.8, 2, 1.2, 0, 18, 0.4, 62, 1.8, 0.02, 'West India', 'India'),
('khichu_bajra_gujarati_indian', 'Khichu (Bajra Flour)', 158, 4.5, 29.5, 3.2, 1.2, 0.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet khichu variant', ARRAY['bajra_khichu','millet_khichu'], true, NULL, 'steamed_snack', 550, 0, 1.0, 0, 115, 18, 1.8, 3, 0.8, 0, 58, 0.8, 88, 2.5, 0.03, 'West India', 'India'),
('patra_gujarati_colocasia_indian', 'Patra (Colocasia Leaf Roll)', 175, 5.2, 25.8, 5.5, 3.2, 6.8, 25, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;colocasia/taro leaf rolled with besan paste', ARRAY['alu_patra','arbi_patra_gujarat'], true, NULL, 'steamed_snack', 380, 0, 1.0, 0, 480, 68, 2.5, 120, 8.5, 0, 35, 0.8, 85, 3.2, 0.10, 'West India', 'India'),
('patra_fried_gujarati_indian', 'Patra (Fried Variant)', 225, 5.5, 24.8, 12.5, 3.0, 5.5, 25, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pan-fried/deep-fried patra variant', ARRAY['fried_patra','taleli_patra'], true, NULL, 'fried_snack', 420, 0, 2.5, 0, 462, 65, 2.4, 115, 7.8, 0, 33, 0.8, 82, 3.0, 0.09, 'West India', 'India'),
('muthia_steamed_green_indian', 'Muthia (Steamed, Methi)', 195, 7.5, 28.2, 5.8, 4.2, 3.5, 30, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;steamed fenugreek dumplings, besan base', ARRAY['methi_muthia_steamed','fenugreek_muthia'], true, NULL, 'steamed_snack', 420, 0, 1.2, 0, 320, 78, 3.8, 90, 9.5, 0, 48, 1.1, 108, 4.5, 0.08, 'West India', 'India'),
('muthia_fried_gujarati_indian', 'Muthia (Fried/Sauteed)', 248, 7.8, 27.5, 12.2, 4.0, 3.0, 30, 130, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pan-fried mustard-tempered muthia', ARRAY['taleli_muthia','sauteed_muthia'], true, NULL, 'fried_snack', 480, 0, 2.5, 0, 308, 75, 3.6, 85, 8.8, 0, 45, 1.0, 105, 4.2, 0.07, 'West India', 'India'),
('kadhi_gujarati_sweet_indian', 'Gujarati Kadhi (Sweet)', 82, 3.2, 8.5, 3.8, 0.2, 5.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;yogurt-besan sweet thin kadhi, Gujarati style', ARRAY['sweet_kadhi','meethi_kadhi_gujarat'], true, NULL, 'curry_sauce', 380, 12, 2.2, 0, 165, 112, 0.8, 28, 1.5, 2, 12, 0.5, 98, 2.2, 0.05, 'West India', 'India'),
('kadhi_pakora_gujarati_indian', 'Kadhi Pakora (Gujarati)', 112, 4.5, 10.8, 5.5, 0.8, 4.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;with besan pakora dumplings', ARRAY['kadhi_with_pakora','Gujarat_kadhi_pakora'], true, NULL, 'curry_sauce', 420, 15, 2.8, 0, 175, 118, 1.2, 32, 1.8, 2, 15, 0.6, 102, 2.5, 0.05, 'West India', 'India'),
('rotlo_bajra_gujarati_indian', 'Rotlo (Bajra, Gujarati)', 318, 8.8, 54.2, 7.8, 6.0, 1.2, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thicker coarser millet flatbread with ghee', ARRAY['bajra_rotlo','millet_rotlo'], true, NULL, 'flatbread', 18, 8, 2.8, 0, 328, 30, 5.0, 6, 0.5, 0, 125, 1.9, 218, 6.0, 0.06, 'West India', 'India'),
('rotlo_jowar_gujarati_indian', 'Rotlo (Jowar, Gujarati)', 305, 8.5, 56.0, 6.5, 5.5, 1.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sorghum rotlo with sesame', ARRAY['jowar_rotlo'], true, NULL, 'flatbread', 12, 5, 1.8, 0, 285, 24, 3.8, 5, 0.8, 0, 82, 1.2, 190, 4.8, 0.05, 'West India', 'India'),
('sev_khamani_gujarati_indian', 'Sev Khamani (Gujarati)', 178, 7.2, 20.5, 7.5, 2.8, 4.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crushed khaman topped with sev and tempering', ARRAY['sev_na_khamani','chura_khamani'], true, NULL, 'steamed_snack', 580, 0, 1.5, 0, 195, 52, 2.2, 18, 2.8, 0, 28, 1.0, 108, 4.0, 0.04, 'West India', 'India'),
('khakhra_methi_gujarati_indian', 'Methi Khakhra (Fenugreek)', 420, 11.5, 60.5, 14.2, 5.8, 1.5, 8, 40, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin crispy fenugreek cracker', ARRAY['fenugreek_khakhra','methi_na_khakhra'], true, NULL, 'cracker_snack', 540, 0, 2.5, 0, 285, 68, 4.2, 88, 8.5, 0, 52, 1.2, 118, 5.0, 0.08, 'West India', 'India'),
('khakhra_masala_gujarati_indian', 'Masala Khakhra (Spiced)', 425, 11.8, 60.2, 14.8, 5.5, 1.2, 8, 40, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced wheat khakhra with cumin and chili', ARRAY['spiced_khakhra','masala_na_khakhra'], true, NULL, 'cracker_snack', 620, 0, 2.8, 0, 278, 65, 4.0, 15, 2.5, 0, 48, 1.1, 115, 4.8, 0.07, 'West India', 'India'),
('khakhra_bajra_gujarati_indian', 'Bajra Khakhra (Millet)', 415, 10.8, 62.5, 13.5, 6.5, 1.0, 8, 40, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet khakhra variant', ARRAY['millet_khakhra','bajra_na_khakhra'], true, NULL, 'cracker_snack', 380, 0, 2.2, 0, 310, 35, 5.2, 8, 0.8, 0, 115, 1.8, 205, 6.0, 0.06, 'West India', 'India'),
('doodhpak_gujarati_indian', 'Doodhpak (Gujarati Rice Pudding)', 185, 4.8, 28.5, 6.2, 0.2, 22.5, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rich rice cooked in whole milk with sugar and saffron', ARRAY['doodh_pak','gujarati_rice_kheer'], true, NULL, 'sweet_dessert', 65, 22, 3.8, 0, 195, 148, 0.5, 52, 1.5, 12, 18, 0.5, 118, 2.8, 0.08, 'West India', 'India'),
('doodhpak_kesar_elaichi_indian', 'Doodhpak (Kesar-Elaichi)', 195, 5.0, 29.8, 6.5, 0.2, 24.8, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;saffron+cardamom flavored variant, richer', ARRAY['kesar_doodhpak','saffron_rice_pudding_gujarati'], true, NULL, 'sweet_dessert', 68, 24, 4.0, 0, 198, 152, 0.5, 58, 1.5, 14, 19, 0.5, 120, 2.9, 0.08, 'West India', 'India'),
('shrikhand_kesar_gujarati_indian', 'Shrikhand (Kesar)', 238, 6.5, 32.8, 9.2, 0, 30.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;strained yogurt dessert with saffron', ARRAY['kesar_shrikhand','saffron_shrikhand'], true, NULL, 'sweet_dessert', 58, 28, 5.8, 0, 220, 195, 0.2, 48, 1.2, 12, 14, 0.6, 148, 3.2, 0.05, 'West India', 'India'),
('shrikhand_elaichi_gujarati_indian', 'Shrikhand (Elaichi)', 235, 6.5, 32.2, 9.0, 0, 29.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;cardamom-flavored strained yogurt', ARRAY['elaichi_shrikhand','cardamom_shrikhand'], true, NULL, 'sweet_dessert', 55, 26, 5.5, 0, 218, 192, 0.2, 38, 1.0, 12, 13, 0.6, 145, 3.0, 0.05, 'West India', 'India'),
('shrikhand_mango_amrakhand_indian', 'Amrakhand (Mango Shrikhand)', 248, 6.2, 36.5, 9.0, 0.5, 32.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;alphonso mango shrikhand, Gujarati-Maharashtrian', ARRAY['amrakhand','mango_shrikhand'], true, NULL, 'sweet_dessert', 52, 25, 5.5, 0, 245, 188, 0.5, 68, 8.5, 12, 15, 0.6, 142, 3.0, 0.05, 'West India', 'India'),
('ghughra_sweet_dry_fruit_indian', 'Ghughra (Sweet Dry Fruit)', 388, 7.2, 52.5, 17.5, 3.2, 18.5, 30, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Gujarati sweet fried dumpling with dry fruit filling', ARRAY['gujiya_gujarati','sweet_ghughra'], true, NULL, 'sweet_fried', 85, 12, 7.2, 0, 188, 45, 2.5, 12, 1.0, 0, 28, 0.8, 88, 3.2, 0.06, 'West India', 'India'),
('ghughra_coconut_cardamom_indian', 'Ghughra (Coconut-Cardamom)', 372, 6.8, 50.2, 16.8, 3.5, 15.8, 30, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coconut+cardamom filled ghughra variant', ARRAY['coconut_ghughra','nariyal_ghughra'], true, NULL, 'sweet_fried', 78, 10, 10.5, 0, 178, 18, 2.2, 5, 1.5, 0, 22, 0.6, 72, 2.8, 0.05, 'West India', 'India'),
('mohanthal_ghee_rich_indian', 'Mohanthal (Ghee-Rich, Traditional)', 488, 9.5, 58.2, 24.5, 2.8, 30.5, 40, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;traditional besan fudge with high ghee', ARRAY['mohanthal_mithai','gujarati_besan_barfi_mohanthal'], true, NULL, 'sweet_mithai', 88, 45, 14.8, 0, 245, 65, 3.5, 18, 0.5, 0, 42, 1.2, 148, 5.5, 0.06, 'West India', 'India'),
('mohanthal_kesar_pista_indian', 'Mohanthal (Kesar-Pista)', 495, 10.2, 57.8, 25.2, 3.0, 31.5, 40, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;saffron and pistachio variant', ARRAY['kesar_mohanthal','pistachio_mohanthal'], true, NULL, 'sweet_mithai', 92, 48, 15.2, 0, 268, 72, 3.8, 25, 0.8, 0, 48, 1.4, 158, 6.0, 0.07, 'West India', 'India'),
('misal_pav_puneri_indian', 'Puneri Misal Pav', 198, 8.5, 28.2, 5.8, 5.5, 2.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Pune-style misal, moderately spiced tarri', ARRAY['pune_misal','puneri_misal'], true, NULL, 'curry_with_bread', 520, 0, 1.2, 0, 385, 68, 3.8, 28, 6.5, 0, 52, 1.5, 148, 5.2, 0.12, 'West India', 'India'),
('misal_pav_nashik_indian', 'Nashik Misal Pav', 205, 8.8, 28.8, 6.2, 5.8, 2.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Nashik-style dry usal topped with farsan', ARRAY['nashik_misal'], true, NULL, 'curry_with_bread', 545, 0, 1.5, 0, 395, 72, 4.0, 32, 7.2, 0, 55, 1.6, 152, 5.5, 0.12, 'West India', 'India'),
('misal_pav_mumbai_style_indian', 'Mumbai Misal Pav', 210, 8.2, 30.5, 6.5, 5.2, 3.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mumbai street-style misal with pav and farsan garnish', ARRAY['mumbai_misal'], true, NULL, 'curry_with_bread', 560, 0, 1.5, 0, 378, 65, 3.6, 25, 5.8, 0, 48, 1.4, 145, 5.0, 0.11, 'West India', 'India'),
('puran_poli_with_ghee_indian', 'Puran Poli (with Ghee)', 312, 7.8, 52.5, 8.5, 3.2, 18.5, 80, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Maharashtrian sweet flatbread with chana dal-jaggery filling', ARRAY['puran_poli_ghee','sweet_poli'], true, NULL, 'sweet_flatbread', 85, 18, 4.2, 0, 268, 58, 3.5, 12, 2.5, 0, 42, 1.0, 125, 4.8, 0.07, 'West India', 'India'),
('puran_poli_katachi_amti_indian', 'Puran Poli with Katachi Amti', 295, 9.2, 48.5, 7.2, 4.5, 12.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;complete meal with leftover dal curry', ARRAY['pooran_poli_amti','puran_poli_dal'], true, NULL, 'sweet_flatbread', 92, 8, 2.8, 0, 312, 72, 4.2, 18, 4.8, 0, 48, 1.2, 138, 5.2, 0.10, 'West India', 'India'),
('vada_pav_street_mumbai_indian', 'Vada Pav (Mumbai Street)', 252, 7.5, 38.5, 7.8, 3.2, 4.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mumbai street-style with green chutney and dry garlic chutney', ARRAY['mumbai_vada_pav','street_vada_pav'], true, NULL, 'street_food_snack', 680, 8, 2.0, 0, 285, 52, 2.5, 5, 8.5, 0, 32, 0.8, 98, 3.5, 0.06, 'West India', 'India'),
('vada_pav_cheese_indian', 'Cheese Vada Pav', 298, 10.5, 38.2, 10.5, 2.8, 4.8, NULL, 220, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;modern variant with processed cheese slice', ARRAY['cheesy_vada_pav','cheese_vada_pav'], true, NULL, 'street_food_snack', 820, 28, 4.5, 0, 275, 182, 2.2, 35, 7.8, 2, 28, 1.2, 185, 5.2, 0.06, 'West India', 'India'),
('pav_bhaji_keema_indian', 'Keema Pav Bhaji', 268, 14.5, 22.8, 12.2, 4.2, 4.5, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;minced mutton/chicken added to pav bhaji', ARRAY['mutton_pav_bhaji','meat_pav_bhaji'], true, NULL, 'street_food_main', 685, 45, 4.2, 0, 385, 48, 3.8, 18, 22.5, 0, 38, 2.8, 188, 8.5, 0.15, 'West India', 'India'),
('pav_bhaji_paneer_indian', 'Paneer Pav Bhaji', 255, 10.8, 25.5, 11.5, 4.5, 5.2, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;paneer chunks in bhaji', ARRAY['paneer_bhaji_pav'], true, NULL, 'street_food_main', 620, 18, 4.8, 0, 345, 188, 2.8, 32, 21.5, 0, 28, 1.0, 195, 4.8, 0.08, 'West India', 'India'),
('pav_bhaji_cheese_indian', 'Cheese Pav Bhaji', 265, 9.5, 26.8, 11.8, 4.2, 5.5, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;with butter and processed cheese topping', ARRAY['cheese_bhaji_pav','cheesy_pav_bhaji'], true, NULL, 'street_food_main', 760, 32, 5.5, 0, 328, 195, 2.5, 38, 20.8, 2, 25, 1.0, 192, 5.2, 0.07, 'West India', 'India'),
('tambda_rassa_with_rice_indian', 'Tambda Rassa with Rice', 165, 12.5, 18.2, 5.5, 1.8, 1.2, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kolhapuri red spicy mutton curry with rice serving', ARRAY['red_rassa_rice','tambda_rassa_bhat'], true, NULL, 'mutton_curry_with_rice', 485, 48, 1.8, 0, 312, 38, 2.8, 22, 3.5, 0, 28, 3.2, 168, 8.5, 0.18, 'West India', 'India'),
('pandhra_rassa_chicken_indian', 'Pandhra Rassa (Chicken)', 118, 11.2, 4.8, 6.2, 0.5, 1.0, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kolhapuri white coconut-based chicken broth', ARRAY['white_rassa_chicken','pandhra_chicken_rassa'], true, NULL, 'chicken_curry_soup', 425, 52, 2.5, 0, 285, 28, 1.5, 12, 2.8, 0, 22, 1.5, 145, 6.2, 0.15, 'West India', 'India'),
('malvani_chicken_curry_indian', 'Malvani Chicken Curry', 178, 15.8, 5.2, 10.5, 1.5, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Konkan-style coconut+malvani masala chicken', ARRAY['malvani_chicken','coastal_maharashtrian_chicken'], true, NULL, 'chicken_curry', 485, 68, 3.8, 0, 348, 38, 2.5, 22, 8.5, 0, 32, 2.2, 185, 8.8, 0.20, 'West India', 'India'),
('malvani_fish_curry_indian', 'Malvani Fish Curry', 162, 14.5, 6.8, 8.8, 1.2, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Konkan-style red coconut-based fish curry', ARRAY['malvani_fish','konkan_fish_curry'], true, NULL, 'fish_curry', 520, 58, 3.2, 0, 385, 42, 1.8, 18, 6.8, 0, 28, 1.8, 192, 28.5, 0.52, 'West India', 'India'),
('malvani_crab_curry_indian', 'Malvani Crab Curry', 145, 15.5, 5.5, 7.5, 1.0, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fresh crab in malvani masala coconut base', ARRAY['khekda_malvani','crab_curry_malvani'], true, NULL, 'seafood_curry', 498, 78, 2.8, 0, 312, 88, 1.5, 15, 5.5, 0, 35, 3.8, 215, 32.5, 0.42, 'West India', 'India'),
('bombil_fry_semolina_indian', 'Bombil Fry (Rava Coated)', 195, 16.5, 12.5, 8.2, 0.5, 0.8, 80, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Bombay duck fish pan-fried with semolina coating', ARRAY['bombay_duck_fry','bombil_rawa_fry'], true, NULL, 'fried_fish', 485, 68, 2.0, 0, 285, 28, 0.8, 18, 2.5, 0, 22, 0.8, 185, 22.5, 0.45, 'West India', 'India'),
('bombil_fry_masala_indian', 'Bombil Fry (Masala Marinated)', 205, 17.2, 10.5, 9.5, 0.8, 1.2, 80, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spice-marinated Bombay duck fried', ARRAY['masala_bombil_fry','spiced_bombil'], true, NULL, 'fried_fish', 520, 72, 2.5, 0, 295, 32, 1.0, 22, 3.5, 0, 25, 1.0, 190, 24.5, 0.48, 'West India', 'India'),
('sukka_mutton_kolhapuri_indian', 'Sukka Mutton (Kolhapuri Dry)', 228, 22.5, 5.2, 13.5, 1.2, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry-cooked mutton with Kolhapuri spice blend', ARRAY['dry_mutton_kolhapuri','kolhapuri_sukka'], true, NULL, 'mutton_dry', 485, 82, 4.8, 0, 358, 28, 3.2, 18, 2.5, 0, 32, 4.5, 205, 12.5, 0.18, 'West India', 'India'),
('sukka_chicken_kolhapuri_indian', 'Sukka Chicken (Kolhapuri Dry)', 212, 22.0, 5.5, 12.2, 1.0, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry-cooked chicken with Kolhapuri masala', ARRAY['dry_chicken_kolhapuri','kolhapuri_chicken_sukka'], true, NULL, 'chicken_dry', 462, 75, 4.2, 0, 342, 22, 2.5, 15, 2.8, 0, 28, 3.8, 192, 10.5, 0.15, 'West India', 'India'),
('matki_usal_maharashtrian_indian', 'Matki Usal (Moth Bean)', 142, 9.2, 20.5, 3.2, 6.8, 2.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sprouted moth bean curry, Maharashtrian style', ARRAY['moth_bean_usal','matki_chi_usal'], true, NULL, 'lentil_curry', 385, 0, 0.8, 0, 468, 52, 3.8, 8, 4.2, 0, 62, 1.5, 185, 4.8, 0.08, 'West India', 'India'),
('kala_vatana_usal_maharashtrian_indian', 'Kala Vatana Usal (Black Pea)', 155, 10.5, 22.8, 2.8, 7.5, 2.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;black-eyed pea/dark pea usal used in Kolhapuri misal', ARRAY['black_pea_usal','kala_vatana_chi_usal'], true, NULL, 'lentil_curry', 398, 0, 0.6, 0, 485, 58, 4.2, 5, 3.8, 0, 58, 1.8, 192, 5.2, 0.09, 'West India', 'India'),
('moong_usal_maharashtrian_indian', 'Moong Usal (Sprouted Moong)', 135, 9.8, 18.5, 2.5, 5.5, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sprouted green gram curry', ARRAY['green_gram_usal','moong_chi_usal'], true, NULL, 'lentil_curry', 352, 0, 0.5, 0, 428, 42, 3.2, 12, 8.5, 0, 48, 1.2, 168, 4.2, 0.07, 'West India', 'India'),
('kothimbir_vadi_maharashtrian_indian', 'Kothimbir Vadi (Steamed)', 188, 8.2, 24.5, 6.5, 3.8, 1.5, 25, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coriander-besan steamed then pan-fried cake', ARRAY['coriander_vadi','kothimbir_vade'], true, NULL, 'steamed_snack', 485, 0, 1.5, 0, 298, 62, 3.5, 42, 12.5, 0, 38, 1.0, 108, 4.5, 0.08, 'West India', 'India'),
('kothimbir_vadi_fried_indian', 'Kothimbir Vadi (Fried Crispy)', 245, 8.5, 23.8, 12.8, 3.5, 1.2, 25, 130, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;deep-fried coriander-besan vadi', ARRAY['fried_kothimbir_vadi'], true, NULL, 'fried_snack', 520, 0, 2.8, 0, 288, 58, 3.2, 38, 11.5, 0, 35, 0.9, 105, 4.2, 0.07, 'West India', 'India'),
('pithla_maharashtrian_indian', 'Pithla (Besan Curry)', 118, 5.8, 15.2, 4.5, 2.8, 1.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;soft besan-based gravy, Maharashtra', ARRAY['besan_curry_maharashtra','pithle'], true, NULL, 'curry_sauce', 385, 0, 1.2, 0, 215, 38, 2.5, 12, 3.2, 0, 28, 0.8, 88, 3.5, 0.04, 'West India', 'India'),
('pithla_dry_zunka_indian', 'Pithla (Dry / Zunka Variant)', 155, 7.2, 18.5, 6.2, 3.2, 1.0, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry roasted besan preparation without water, zunka style', ARRAY['zunka_pithla','dry_besan_sabzi'], true, NULL, 'dry_curry', 420, 0, 1.5, 0, 228, 42, 2.8, 15, 3.5, 0, 32, 0.9, 95, 3.8, 0.04, 'West India', 'India'),
('thalipeeth_bhajani_indian', 'Thalipeeth (Bhajani Flour)', 285, 9.5, 46.5, 7.2, 5.5, 1.8, 80, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;multi-grain roasted flour flatbread, Maharashtrian', ARRAY['bhajani_thalipeeth','multigrain_thalipeeth'], true, NULL, 'flatbread', 285, 0, 1.5, 0, 358, 52, 4.2, 18, 2.8, 0, 88, 1.5, 195, 5.5, 0.08, 'West India', 'India'),
('thalipeeth_with_butter_indian', 'Thalipeeth (with White Butter)', 325, 9.8, 45.8, 11.5, 5.2, 1.5, 80, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;bhajani thalipeeth served with loni/white butter', ARRAY['thalipeeth_loni','buttered_thalipeeth'], true, NULL, 'flatbread', 295, 18, 5.5, 0, 352, 65, 4.0, 28, 2.5, 0, 85, 1.5, 192, 5.2, 0.08, 'West India', 'India'),
('modak_kesar_stuffed_indian', 'Modak (Kesar-Stuffed)', 248, 4.2, 42.5, 7.5, 2.8, 22.5, 35, 105, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;steamed rice modak with kesar coconut filling', ARRAY['kesar_modak','saffron_modak'], true, NULL, 'sweet_dumpling', 28, 5, 3.8, 0, 185, 18, 1.2, 10, 2.8, 0, 22, 0.5, 72, 2.5, 0.06, 'West India', 'India'),
('modak_chocolate_modern_indian', 'Chocolate Modak (Modern)', 338, 5.5, 48.5, 14.5, 2.5, 32.8, 35, 105, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chocolate ganache-filled steamed rice modak, fusion', ARRAY['choco_modak','modern_chocolate_modak'], true, NULL, 'sweet_dumpling', 38, 12, 7.5, 0, 215, 28, 2.2, 5, 1.5, 0, 28, 0.6, 85, 2.8, 0.05, 'West India', 'India'),
('modak_dry_fruit_maharashtrian_indian', 'Modak (Dry Fruit Stuffed)', 298, 5.8, 44.5, 11.5, 3.5, 24.5, 35, 105, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry fruit and coconut filling modak', ARRAY['dry_fruit_modak','dryfruit_stuffed_modak'], true, NULL, 'sweet_dumpling', 32, 8, 4.5, 0, 228, 22, 1.8, 8, 2.5, 0, 28, 0.8, 82, 3.0, 0.07, 'West India', 'India'),
('solkadhi_kokum_coconut_indian', 'Solkadhi (Kokum-Coconut)', 68, 1.2, 5.5, 4.5, 0.5, 3.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;digestive kokum+coconut milk drink/curry accompaniment', ARRAY['sol_kadhi','kokum_solkadhi'], true, NULL, 'digestive_drink', 285, 0, 3.8, 0, 212, 15, 0.5, 5, 2.8, 0, 18, 0.4, 52, 1.2, 0.08, 'West India', 'India'),
('solkadhi_garlic_goan_indian', 'Solkadhi (Garlic, Goan Style)', 72, 1.5, 5.8, 4.8, 0.5, 3.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;garlic-heavy Goan variant of kokum coconut kadhi', ARRAY['goan_solkadhi','garlic_kokum_kadhi'], true, NULL, 'digestive_drink', 295, 0, 4.0, 0, 218, 18, 0.5, 8, 3.2, 0, 20, 0.4, 55, 1.5, 0.08, 'West India', 'India'),
('amti_goda_masala_indian', 'Amti (Goda Masala)', 98, 5.2, 14.8, 2.2, 4.5, 2.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Maharashtrian toor dal with goda masala tempering', ARRAY['goda_masala_amti','marathi_amti'], true, NULL, 'lentil_curry', 385, 0, 0.5, 0, 388, 42, 3.2, 18, 5.8, 0, 48, 1.0, 145, 4.2, 0.08, 'West India', 'India'),
('varan_ghee_rice_maharashtrian_indian', 'Varan Bhaat (with Ghee)', 145, 5.5, 28.5, 2.8, 2.8, 1.2, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;simple toor dal rice comfort food with ghee', ARRAY['varan_bhat','marathi_dal_rice'], true, NULL, 'lentil_with_rice', 185, 8, 1.5, 0, 312, 28, 2.5, 10, 3.2, 0, 35, 0.8, 118, 3.8, 0.08, 'West India', 'India'),
('basundi_maharashtrian_thick_indian', 'Basundi (Thick, Maharashtrian)', 205, 7.2, 28.5, 7.5, 0, 26.8, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow-reduced milk dessert, Maharashtra style', ARRAY['maharashtrian_basundi','thick_basundi'], true, NULL, 'sweet_dessert', 88, 28, 4.8, 0, 245, 228, 0.2, 68, 2.2, 14, 22, 0.8, 185, 3.8, 0.08, 'West India', 'India'),
('shrikhand_pune_style_indian', 'Shrikhand (Pune Style, Rich)', 252, 7.0, 35.5, 9.8, 0, 33.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Pune-style thick creamy shrikhand, nutmeg-flavored', ARRAY['pune_shrikhand','marathi_shrikhand'], true, NULL, 'sweet_dessert', 62, 30, 6.2, 0, 228, 198, 0.2, 42, 1.0, 12, 16, 0.6, 150, 3.2, 0.05, 'West India', 'India'),
('xacuti_mutton_goan_indian', 'Mutton Xacuti (Goan)', 248, 18.5, 8.2, 16.5, 2.2, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;poppy seed+coconut+red chili Goan mutton curry', ARRAY['mutton_xacuti','goan_mutton_xacuti'], true, NULL, 'mutton_curry', 485, 78, 6.8, 0, 378, 42, 3.5, 18, 5.8, 0, 38, 4.2, 215, 12.5, 0.20, 'West India', 'India'),
('xacuti_pork_goan_indian', 'Pork Xacuti (Goan)', 285, 17.8, 7.5, 20.2, 2.0, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pork xacuti, rich fat content, Goan Catholic', ARRAY['pork_xacuti_goa','goan_pork_xacuti'], true, NULL, 'pork_curry', 498, 88, 8.5, 0, 365, 38, 3.2, 15, 5.2, 0, 35, 3.8, 205, 14.5, 0.18, 'West India', 'India'),
('vindaloo_chicken_goan_authentic_indian', 'Chicken Vindaloo (Goan Authentic)', 195, 16.8, 6.5, 11.5, 1.5, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;authentic Goan Catholic chicken vindaloo with coconut vinegar', ARRAY['goan_chicken_vindaloo','authentic_chicken_vindaloo'], true, NULL, 'chicken_curry', 485, 75, 4.2, 0, 358, 28, 2.5, 18, 8.5, 0, 28, 2.2, 185, 9.8, 0.15, 'West India', 'India'),
('vindaloo_mutton_goan_indian', 'Mutton Vindaloo (Goan)', 255, 18.2, 7.2, 16.8, 1.8, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan mutton vindaloo with palm vinegar and spices', ARRAY['goan_mutton_vindaloo','mutton_vindaloo_goa'], true, NULL, 'mutton_curry', 498, 85, 6.5, 0, 368, 32, 3.0, 15, 7.8, 0, 32, 4.0, 210, 12.8, 0.18, 'West India', 'India'),
('vindaloo_prawn_goan_indian', 'Prawn Vindaloo (Goan)', 168, 14.5, 8.5, 8.5, 1.5, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;prawn vindaloo, tangy spicy Goan style', ARRAY['goan_prawn_vindaloo','prawn_vindaloo_goa'], true, NULL, 'prawn_curry', 528, 152, 2.8, 0, 312, 62, 2.8, 15, 7.5, 0, 32, 1.8, 215, 28.5, 0.35, 'West India', 'India'),
('sorpotel_pork_traditional_indian', 'Sorpotel (Traditional Pork)', 295, 18.5, 5.5, 22.5, 1.2, 1.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow-cooked pork offal+meat in spiced vinegar, Goan feast dish', ARRAY['traditional_sorpotel','pork_sorpotel_goa'], true, NULL, 'pork_offal_curry', 620, 92, 8.2, 0, 368, 22, 4.2, 8, 3.5, 0, 28, 3.8, 228, 18.5, 0.15, 'West India', 'India'),
('sorpotel_beef_liver_goan_indian', 'Sorpotel (Beef/Liver Variant)', 278, 19.5, 5.8, 19.5, 1.0, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;beef+liver variant of sorpotel, Goan Catholic', ARRAY['beef_sorpotel','liver_sorpotel_goa'], true, NULL, 'offal_curry', 598, 185, 7.5, 0, 385, 18, 6.8, 385, 5.2, 0, 22, 5.2, 248, 22.5, 0.12, 'West India', 'India'),
('cafreal_mutton_goan_indian', 'Cafreal (Mutton, Goan)', 235, 18.8, 4.5, 16.2, 1.5, 1.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mutton cafreal, Goan green herb-marinated mutton', ARRAY['mutton_cafreal_goa','goan_mutton_cafreal'], true, NULL, 'mutton_dry', 438, 82, 5.8, 0, 355, 28, 3.2, 18, 6.5, 0, 32, 4.0, 205, 12.8, 0.18, 'West India', 'India'),
('cafreal_prawn_goan_indian', 'Cafreal (Prawn, Goan)', 165, 15.2, 5.5, 8.8, 1.5, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;prawn cafreal, green herb Goan preparation', ARRAY['prawn_cafreal_goa'], true, NULL, 'prawn_dry', 448, 148, 3.0, 0, 298, 58, 2.5, 15, 6.8, 0, 28, 1.5, 208, 26.5, 0.32, 'West India', 'India'),
('balchao_fish_goan_indian', 'Fish Balchao (Goan)', 188, 15.2, 8.5, 10.5, 1.2, 2.8, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spicy fermented shrimp paste fish pickle-curry', ARRAY['fish_balchao_goa','goan_fish_balchao'], true, NULL, 'fish_pickle_curry', 850, 65, 3.8, 0, 315, 38, 2.5, 15, 5.5, 0, 28, 1.5, 195, 22.5, 0.42, 'West India', 'India'),
('balchao_pork_goan_indian', 'Pork Balchao (Goan)', 225, 16.5, 7.8, 14.8, 1.0, 3.5, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pork balchao pickle-curry, tangy and spicy', ARRAY['pork_balchao_goa'], true, NULL, 'pork_pickle_curry', 920, 85, 5.8, 0, 342, 28, 3.2, 8, 4.5, 0, 25, 3.2, 218, 16.5, 0.12, 'West India', 'India'),
('rechado_fish_goan_indian', 'Rechado Fish (Goan Stuffed Fry)', 215, 18.5, 8.5, 12.5, 1.0, 2.2, 120, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan stuffed fish with rechado masala (red vinegar spice paste)', ARRAY['recheado_fish','rechado_masala_fish'], true, NULL, 'fried_fish', 658, 72, 4.2, 0, 358, 42, 2.2, 18, 6.5, 0, 32, 1.8, 205, 28.5, 0.52, 'West India', 'India'),
('rechado_prawn_goan_indian', 'Rechado Prawn (Goan)', 182, 16.8, 7.5, 10.2, 1.0, 2.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;prawn with rechado red masala paste', ARRAY['recheado_prawn','rechado_masala_prawn'], true, NULL, 'prawn_curry', 695, 158, 3.5, 0, 322, 62, 2.8, 15, 7.2, 0, 32, 1.8, 218, 30.5, 0.38, 'West India', 'India'),
('rechado_pork_goan_indian', 'Rechado Pork (Goan)', 268, 17.5, 7.2, 18.8, 1.0, 2.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pork slices with rechado spiced paste', ARRAY['recheado_pork','goan_rechado_pork'], true, NULL, 'pork_curry', 712, 88, 7.5, 0, 348, 28, 3.0, 8, 5.8, 0, 28, 3.5, 215, 18.5, 0.12, 'West India', 'India'),
('goan_pork_chorizo_sausage_indian', 'Goan Pork Chorizo', 385, 18.2, 5.5, 32.5, 0.8, 2.5, 40, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan spiced pork sausage with red vinegar, very high fat', ARRAY['goan_chorizo','chourico_goan'], true, NULL, 'pork_sausage', 1280, 95, 12.5, 0, 285, 18, 2.2, 8, 3.5, 0, 22, 2.8, 195, 22.5, 0.15, 'West India', 'India'),
('goan_chorizo_pulao_indian', 'Goan Chorizo Pulao', 228, 9.5, 32.5, 7.5, 1.5, 2.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rice cooked with Goan pork chorizo', ARRAY['chourico_pulao','goan_sausage_rice'], true, NULL, 'rice_dish', 695, 45, 3.5, 0, 285, 22, 1.8, 8, 3.2, 0, 28, 1.8, 155, 12.5, 0.12, 'West India', 'India'),
('bebinca_traditional_goan_indian', 'Bebinca (Traditional, 7-layer)', 325, 5.5, 48.5, 13.2, 0.5, 32.5, 60, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;layered coconut pudding, Goan Portuguese-heritage dessert', ARRAY['bibinca','traditional_bebinca'], true, NULL, 'sweet_dessert', 85, 125, 8.5, 0, 145, 35, 1.5, 38, 1.2, 8, 22, 0.5, 88, 3.5, 0.05, 'West India', 'India'),
('bebinca_egg_yolk_rich_indian', 'Bebinca (Egg-Yolk Rich)', 365, 6.5, 50.2, 16.5, 0.5, 36.5, 60, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;extra egg-yolk heavy variant, richer and denser', ARRAY['rich_bebinca','egg_bebinca'], true, NULL, 'sweet_dessert', 92, 185, 10.8, 0, 155, 38, 1.8, 85, 1.0, 12, 22, 0.6, 95, 5.5, 0.05, 'West India', 'India'),
('dodol_goan_coconut_indian', 'Dodol (Goan Coconut)', 355, 3.2, 58.5, 13.5, 2.5, 45.8, 30, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coconut milk+jaggery+rice flour fudge, Goan Christmas sweet', ARRAY['goan_dodol','coconut_dodol'], true, NULL, 'sweet_confection', 45, 5, 11.5, 0, 288, 18, 2.8, 2, 2.5, 0, 28, 0.5, 52, 2.2, 0.08, 'West India', 'India'),
('dodol_chocolate_goan_indian', 'Dodol (Chocolate, Modern)', 378, 3.8, 60.5, 14.5, 3.0, 48.5, 30, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;modern chocolate dodol variant, Goa', ARRAY['chocolate_dodol_goa'], true, NULL, 'sweet_confection', 48, 8, 9.5, 0, 295, 22, 3.2, 3, 1.5, 0, 32, 0.6, 58, 2.8, 0.07, 'West India', 'India'),
('serradura_portuguese_goan_indian', 'Serradura (Goan-Portuguese)', 295, 5.2, 35.8, 15.5, 0.5, 28.5, NULL, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;cream+Marie biscuit crumb layered dessert, Goan Portuguese heritage', ARRAY['sawdust_pudding_goa','marie_biscuit_cream_dessert'], true, NULL, 'sweet_dessert', 125, 58, 9.5, 0, 185, 88, 0.8, 38, 0.5, 8, 12, 0.4, 78, 2.5, 0.08, 'West India', 'India'),
('serradura_coffee_goan_indian', 'Serradura (Coffee Variant)', 305, 5.5, 36.2, 16.2, 0.5, 29.5, NULL, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coffee-flavored serradura, Goan cafe version', ARRAY['coffee_serradura_goa'], true, NULL, 'sweet_dessert', 128, 62, 9.8, 0, 192, 90, 0.9, 32, 0.5, 8, 13, 0.4, 80, 2.8, 0.08, 'West India', 'India'),
('ambot_tik_shark_goan_indian', 'Ambot Tik (Shark, Goan)', 155, 14.8, 6.5, 8.2, 1.2, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sour-spicy Goan shark curry with kokum', ARRAY['shark_ambot_tik','goan_shark_curry'], true, NULL, 'fish_curry', 578, 55, 2.8, 0, 342, 35, 1.8, 12, 6.8, 0, 28, 1.5, 185, 22.5, 0.45, 'West India', 'India'),
('ambot_tik_prawn_goan_indian', 'Ambot Tik (Prawn, Goan)', 148, 13.5, 7.2, 7.5, 1.2, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sour-spicy prawn curry with kokum and chili', ARRAY['prawn_ambot_tik','goan_prawn_sour_curry'], true, NULL, 'prawn_curry', 595, 148, 2.5, 0, 325, 62, 2.2, 12, 7.2, 0, 28, 1.5, 195, 28.5, 0.38, 'West India', 'India'),
('patoleo_goan_turmeric_leaf_indian', 'Patoleo (Turmeric Leaf Steamed)', 225, 3.8, 42.5, 5.5, 3.2, 18.5, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rice+coconut+jaggery filled turmeric leaf parcel', ARRAY['patole','goan_sweet_parcel'], true, NULL, 'steamed_sweet', 18, 0, 4.2, 0, 195, 18, 1.5, 5, 2.5, 0, 22, 0.5, 65, 2.2, 0.08, 'West India', 'India'),
('patoleo_jackfruit_variant_indian', 'Patoleo (Jackfruit Variant)', 238, 4.0, 45.5, 5.8, 3.5, 20.5, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ripe jackfruit+coconut filling variant', ARRAY['jackfruit_patoleo'], true, NULL, 'steamed_sweet', 20, 0, 4.5, 0, 215, 20, 1.8, 8, 5.5, 0, 25, 0.5, 68, 2.5, 0.08, 'West India', 'India'),
('sanna_coconut_toddy_indian', 'Sanna (Coconut Toddy Fermented)', 178, 4.2, 35.5, 2.5, 1.5, 3.5, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan steamed rice cakes with coconut toddy fermentation', ARRAY['goan_idli_sanna','coconut_sanna'], true, NULL, 'steamed_rice_cake', 285, 0, 0.8, 0, 145, 22, 0.8, 2, 0.5, 0, 18, 0.5, 72, 2.5, 0.04, 'West India', 'India'),
('sanna_sweet_coconut_indian', 'Sanna (Sweet Coconut)', 192, 4.0, 38.5, 3.2, 1.5, 12.5, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sweet variant with coconut milk and jaggery', ARRAY['sweet_sanna','mitho_sanna'], true, NULL, 'steamed_rice_cake', 195, 0, 2.5, 0, 165, 18, 0.8, 3, 0.5, 0, 18, 0.5, 68, 2.2, 0.05, 'West India', 'India'),
('poee_goan_bread_indian', 'Poee (Goan Bread)', 255, 8.5, 52.8, 2.5, 3.5, 2.8, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan hollow wheat bread made with toddy, slightly tangy', ARRAY['poi_bread','goan_poi'], true, NULL, 'bread', 385, 0, 0.5, 0, 148, 22, 2.8, 0, 0.2, 0, 22, 0.8, 82, 5.2, 0.04, 'West India', 'India'),
('poee_with_chorizo_goan_indian', 'Poee with Chorizo (Goan)', 318, 13.2, 48.5, 9.5, 3.2, 3.5, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan breakfast: poee stuffed with chorizo', ARRAY['poee_chorizo','goan_sausage_bread'], true, NULL, 'bread_with_filling', 680, 45, 4.2, 0, 212, 28, 2.5, 8, 2.8, 0, 25, 1.8, 118, 12.5, 0.12, 'West India', 'India'),
('baati_ghee_dunked_rajasthani_indian', 'Baati (Ghee-Dunked, Rajasthani)', 428, 9.5, 52.8, 20.5, 4.8, 2.5, 80, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;hard wheat balls baked in cow dung/oven and dunked in ghee', ARRAY['ghee_baati','rajasthani_baati'], true, NULL, 'baked_bread', 185, 42, 11.5, 0, 195, 28, 3.2, 8, 0.5, 0, 32, 1.0, 118, 4.5, 0.06, 'West India', 'India'),
('churma_sweet_rajasthani_indian', 'Churma (Sweet, Rajasthani)', 488, 9.0, 65.5, 21.5, 4.2, 25.8, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coarsely ground baati sweetened with jaggery+ghee', ARRAY['sweet_churma','ghee_churma'], true, NULL, 'sweet_crumble', 88, 38, 12.5, 0, 205, 32, 3.5, 8, 0.5, 0, 35, 1.0, 125, 4.8, 0.07, 'West India', 'India'),
('panchmela_dal_rajasthani_indian', 'Panchmela Dal (Rajasthani Five-Lentil)', 148, 9.5, 20.8, 4.5, 7.2, 3.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;five-lentil dal served with baati; robust Marwari flavors', ARRAY['panchmel_dal','five_dal_rajasthan'], true, NULL, 'lentil_curry', 485, 0, 1.2, 0, 498, 68, 4.8, 22, 5.5, 0, 62, 1.8, 205, 6.5, 0.12, 'West India', 'India'),
('laal_maas_mathania_chili_indian', 'Laal Maas (Mathania Chili, Authentic)', 285, 20.5, 6.8, 20.2, 2.0, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Rajasthani fiery red mutton curry with Mathania red chilies', ARRAY['mathania_laal_maas','authentic_laal_maas'], true, NULL, 'mutton_curry', 548, 88, 7.5, 0, 385, 35, 3.5, 22, 5.5, 0, 35, 4.5, 218, 12.8, 0.18, 'West India', 'India'),
('laal_maas_wild_game_junglee_indian', 'Junglee Maas (Wild, Rajasthani)', 268, 22.5, 4.5, 17.5, 1.5, 1.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;minimal spice robust game meat curry, hunter style', ARRAY['junglee_maas_raj','wild_meat_curry'], true, NULL, 'game_meat_curry', 412, 92, 6.8, 0, 398, 28, 3.8, 15, 3.5, 0, 32, 4.8, 225, 14.5, 0.15, 'West India', 'India'),
('safed_maas_white_rajasthani_indian', 'Safed Maas (White Mutton, Rajasthani)', 312, 18.5, 5.5, 24.5, 1.2, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;creamy white mutton curry with cream/khoya and cashews', ARRAY['white_mutton_curry_raj','safed_maas_rajasthani'], true, NULL, 'mutton_curry', 385, 92, 9.8, 0, 362, 62, 2.5, 18, 2.8, 0, 28, 3.8, 215, 11.5, 0.15, 'West India', 'India'),
('gatte_ki_sabzi_yogurt_gravy_indian', 'Gatte ki Sabzi (Yogurt Gravy)', 168, 7.5, 18.5, 7.8, 3.5, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;besan dumplings in tangy yogurt-based gravy', ARRAY['besan_gatte_sabzi','yogurt_gatte'], true, NULL, 'curry', 485, 12, 2.8, 0, 285, 78, 3.2, 18, 4.5, 0, 38, 1.0, 118, 4.5, 0.06, 'West India', 'India'),
('gatte_pulao_rajasthani_indian', 'Gatte Pulao (Besan Dumplings in Rice)', 198, 7.8, 28.5, 6.8, 3.2, 2.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rice cooked with besan gatte, Rajasthani', ARRAY['gatte_rice','besan_dumpling_rice'], true, NULL, 'rice_with_curry', 425, 8, 2.0, 0, 258, 55, 2.5, 12, 3.5, 0, 32, 0.9, 108, 4.2, 0.05, 'West India', 'India'),
('ker_sangri_with_bajra_roti_indian', 'Ker Sangri with Bajra Roti', 245, 9.2, 38.5, 7.2, 8.5, 4.2, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;desert berry+beans sabzi served with millet bread', ARRAY['ker_sangri_bajra_combo','desert_vegetable_millet'], true, NULL, 'dry_vegetable_with_bread', 385, 0, 1.5, 0, 458, 35, 4.5, 18, 6.5, 0, 68, 1.5, 188, 5.8, 0.08, 'West India', 'India'),
('ker_sangri_pickle_rajasthani_indian', 'Ker Sangri Pickle (Rajasthani)', 185, 5.5, 18.5, 10.8, 7.5, 3.5, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;oil-preserved ker sangri pickle condiment', ARRAY['ker_sangri_achaar'], true, NULL, 'pickle_condiment', 1285, 0, 1.8, 0, 388, 28, 4.2, 15, 5.8, 0, 62, 1.2, 158, 4.8, 0.08, 'West India', 'India'),
('ghevar_malai_rajasthani_indian', 'Malai Ghevar (Clotted Cream)', 425, 7.5, 58.5, 19.5, 0.8, 32.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lattice fried sweet topped with clotted cream', ARRAY['malai_ghevar','cream_ghevar'], true, NULL, 'sweet_fried', 125, 58, 10.5, 0, 178, 88, 1.8, 55, 0.5, 12, 15, 0.5, 98, 3.5, 0.07, 'West India', 'India'),
('ghevar_kesar_rajasthani_indian', 'Kesar Ghevar (Saffron)', 418, 7.2, 60.5, 18.8, 0.8, 35.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;saffron+dry fruit topped ghevar', ARRAY['saffron_ghevar','kesar_mawa_ghevar'], true, NULL, 'sweet_fried', 118, 52, 9.8, 0, 185, 92, 1.5, 62, 0.5, 12, 14, 0.5, 95, 3.2, 0.06, 'West India', 'India'),
('ghevar_mawa_rajasthani_indian', 'Mawa Ghevar (Khoya Topped)', 455, 9.5, 62.5, 21.2, 0.8, 38.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lattice sweet topped with reduced milk mawa', ARRAY['mawa_ghevar_raj','khoya_ghevar'], true, NULL, 'sweet_fried', 132, 62, 12.5, 0, 195, 112, 1.5, 68, 0.5, 14, 18, 0.6, 112, 3.8, 0.07, 'West India', 'India'),
('mirchi_vada_jodhpur_indian', 'Mirchi Vada (Jodhpur)', 248, 5.5, 28.5, 13.2, 3.5, 2.5, 80, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;large green chili stuffed with potato+besan batter fried, Jodhpur', ARRAY['jodhpur_mirchi_vada','stuffed_chili_fritter'], true, NULL, 'fried_street_snack', 685, 0, 2.8, 0, 385, 42, 2.8, 28, 45.5, 0, 38, 0.8, 88, 3.5, 0.06, 'West India', 'India'),
('mirchi_badi_rajasthani_indian', 'Mirchi Badi (Sun-Dried Chili)', 285, 9.5, 38.5, 11.5, 8.5, 5.2, 20, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dried chili balls with besan filling, Rajasthani sun-dried', ARRAY['mirchi_bari','dried_chili_badi'], true, NULL, 'dried_condiment_snack', 1285, 0, 2.2, 0, 528, 55, 5.5, 35, 18.5, 0, 52, 1.2, 128, 5.0, 0.08, 'West India', 'India'),
('bikaneri_bhujia_original_indian', 'Bikaneri Bhujia (Original)', 545, 17.5, 52.5, 29.8, 4.5, 2.5, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fine moth bean sev, Bikaner specialty, FSSAI reference', ARRAY['bikaner_bhujia','bhujia_bikaneri'], true, NULL, 'fried_snack', 720, 0, 5.5, 0, 555, 68, 5.8, 12, 2.8, 0, 68, 2.2, 248, 8.5, 0.08, 'West India', 'India'),
('bikaneri_bhujia_masala_indian', 'Bikaneri Bhujia (Masala Variant)', 552, 17.8, 52.2, 30.5, 4.5, 2.8, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced variant with extra chili and spices', ARRAY['masala_bhujia_bikaner','spiced_bhujia'], true, NULL, 'fried_snack', 785, 0, 5.8, 0, 562, 72, 6.0, 15, 3.5, 0, 70, 2.2, 252, 8.8, 0.08, 'West India', 'India'),
('rabdi_rajasthani_style_indian', 'Rabdi (Rajasthani, Thick)', 272, 7.5, 32.5, 13.2, 0, 28.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thick reduced sweetened milk dessert, Rajasthani', ARRAY['rabri_rajasthani','thick_rabdi'], true, NULL, 'sweet_dessert', 85, 48, 8.5, 0, 265, 268, 0.2, 78, 2.5, 14, 24, 0.8, 195, 3.8, 0.08, 'West India', 'India'),
('rabdi_jalebi_rajasthani_indian', 'Rabdi with Jalebi (Rajasthani)', 335, 6.5, 52.8, 11.5, 0.2, 38.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;hot jalebi dipped in cold thick rabdi, festival dessert', ARRAY['jalebi_rabdi_rajasthan','rabdi_jalebis'], true, NULL, 'sweet_dessert', 88, 38, 6.5, 0, 225, 225, 0.5, 68, 2.0, 12, 20, 0.6, 165, 3.2, 0.07, 'West India', 'India'),
('moong_dal_kachori_rajasthani_indian', 'Moong Dal Kachori (Rajasthani)', 358, 9.5, 45.8, 16.5, 4.5, 2.5, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fried kachori with spiced moong dal filling', ARRAY['mung_dal_kachori','moong_kachori_raj'], true, NULL, 'fried_snack', 485, 0, 3.8, 0, 285, 42, 3.5, 15, 2.5, 0, 42, 1.2, 128, 5.2, 0.07, 'West India', 'India'),
('hing_ki_kachori_rajasthani_indian', 'Hing Ki Kachori (Asafoetida)', 368, 9.8, 46.5, 17.2, 4.2, 2.0, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fried kachori with asafoetida-flavored filling', ARRAY['asafoetida_kachori','hing_kachori'], true, NULL, 'fried_snack', 520, 0, 4.0, 0, 278, 45, 3.8, 12, 2.0, 0, 40, 1.2, 125, 5.0, 0.07, 'West India', 'India'),
('raj_kachori_chaat_rajasthani_indian', 'Raj Kachori (Chaat Filling)', 285, 8.5, 38.5, 11.5, 5.5, 6.5, 120, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;large crisp kachori filled with sprouts, chutneys, dahi; Rajasthani chaat', ARRAY['rajasthani_raj_kachori','big_kachori_chaat'], true, NULL, 'fried_chaat', 680, 5, 2.8, 0, 348, 88, 3.8, 28, 12.5, 0, 45, 1.2, 138, 5.5, 0.08, 'West India', 'India'),
('pitod_ki_sabzi_rajasthani_indian', 'Pitod ki Sabzi (Besan Cake Curry)', 162, 6.8, 18.5, 7.5, 3.2, 3.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fried besan cake pieces in yogurt gravy, Rajasthani', ARRAY['pitod_sabzi','besan_cake_curry'], true, NULL, 'curry', 485, 8, 2.5, 0, 268, 68, 2.8, 18, 4.2, 0, 35, 1.0, 108, 4.2, 0.05, 'West India', 'India'),
('papad_ki_sabzi_rajasthani_indian', 'Papad ki Sabzi (Rajasthani)', 145, 5.2, 15.5, 7.2, 2.8, 3.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crushed papad in spiced yogurt gravy, desert region dish', ARRAY['papad_sabzi','pappadums_curry_rajasthan'], true, NULL, 'curry', 920, 8, 2.2, 0, 245, 58, 2.2, 15, 3.5, 0, 28, 0.8, 95, 3.8, 0.04, 'West India', 'India'),
('bajre_ki_roti_ghee_rajasthani_indian', 'Bajre ki Roti (with Ghee, Rajasthani)', 338, 9.0, 55.2, 10.5, 6.5, 1.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet flatbread served hot with ghee, Rajasthani', ARRAY['bajra_roti_ghee','millet_roti_rajasthan'], true, NULL, 'flatbread', 15, 12, 4.5, 0, 335, 30, 5.0, 8, 0.5, 0, 122, 1.9, 218, 6.0, 0.07, 'West India', 'India'),
('lahsun_ki_chutney_rajasthani_indian', 'Lahsun ki Chutney (Rajasthani Garlic)', 185, 5.8, 18.5, 10.5, 3.5, 4.5, NULL, 30, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;roasted garlic chutney with dry red chili, Marwari essential condiment', ARRAY['garlic_chutney_rajasthan','lasan_chutney_raj'], true, NULL, 'chutney_condiment', 585, 0, 1.8, 0, 448, 42, 2.2, 5, 12.5, 0, 25, 0.8, 108, 2.5, 0.05, 'West India', 'India'),
('mohan_maas_rajasthani_indian', 'Mohan Maas (Royal Rajasthani)', 342, 18.5, 6.5, 27.5, 1.2, 2.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rich royal mutton cooked in milk/cream and ghee, Marwari', ARRAY['mohan_maas_raj','royal_mutton_curry'], true, NULL, 'mutton_curry', 388, 95, 10.5, 0, 368, 65, 2.8, 28, 2.5, 0, 28, 4.2, 225, 12.5, 0.15, 'West India', 'India'),
('besan_chakki_rajasthani_indian', 'Besan Chakki (Rajasthani Sweet)', 465, 9.8, 60.5, 21.5, 3.2, 32.5, 40, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;roasted besan fudge-like sweet, Rajasthani mithai', ARRAY['besan_chikki_raj','chakki_mithai'], true, NULL, 'sweet_mithai', 95, 42, 12.5, 0, 248, 58, 3.8, 15, 0.5, 0, 42, 1.2, 145, 5.5, 0.06, 'West India', 'India'),
('lilva_kachori_surti_deep_fried_indian', 'Lilva Kachori (Surti, Deep Fried)', 362, 8.5, 42.5, 18.5, 5.2, 3.5, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Surti fresh green pigeon pea kachori, deep fried', ARRAY['surti_lilva_kachori','green_vatana_kachori'], true, NULL, 'fried_snack', 485, 0, 3.8, 0, 325, 42, 3.5, 22, 8.5, 0, 48, 1.2, 128, 5.2, 0.10, 'West India', 'India'),
('lilva_kachori_baked_healthy_indian', 'Lilva Kachori (Baked Variant)', 298, 8.8, 42.0, 12.5, 5.5, 3.2, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;oven-baked healthier version of lilva kachori', ARRAY['baked_lilva_kachori'], true, NULL, 'baked_snack', 420, 0, 2.5, 0, 335, 45, 3.8, 25, 9.5, 0, 50, 1.3, 132, 5.5, 0.10, 'West India', 'India'),
('handvo_gujarati_baked_indian', 'Handvo (Baked, Gujarati)', 195, 8.5, 28.5, 5.8, 4.5, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mixed lentil+rice+vegetable baked savory cake', ARRAY['baked_handvo','vegetable_handvo'], true, NULL, 'baked_savory_cake', 485, 0, 1.2, 0, 348, 65, 3.5, 35, 8.5, 0, 48, 1.2, 118, 4.8, 0.08, 'West India', 'India'),
('handvo_pan_fried_gujarati_indian', 'Handvo (Pan Fried, Tava)', 218, 8.8, 27.8, 8.2, 4.2, 2.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;tava-cooked crispy handvo, Gujarati', ARRAY['tava_handvo','pan_handvo'], true, NULL, 'fried_savory_cake', 510, 0, 1.8, 0, 342, 62, 3.2, 32, 7.8, 0, 45, 1.1, 115, 4.5, 0.07, 'West India', 'India'),
('besan_ladoo_maharashtrian_indian', 'Besan Ladoo (Maharashtrian)', 475, 9.8, 60.5, 22.5, 3.2, 38.5, 35, 70, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;roasted chickpea flour sweet ball with ghee', ARRAY['besan_ladu_maharashtra','gram_flour_ladoo'], true, NULL, 'sweet_mithai', 88, 38, 13.5, 0, 245, 58, 3.8, 12, 0.5, 0, 38, 1.2, 145, 5.5, 0.06, 'West India', 'India'),
('rava_ladoo_maharashtrian_indian', 'Rava Ladoo (Maharashtrian)', 438, 6.5, 62.5, 19.5, 1.5, 35.5, 30, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;semolina+coconut sweet ball, Maharashtra', ARRAY['sooji_ladoo_maharashtra','semolina_ladoo'], true, NULL, 'sweet_mithai', 55, 32, 11.5, 0, 188, 25, 1.5, 5, 0.5, 0, 22, 0.5, 98, 3.2, 0.05, 'West India', 'India'),
('motichoor_ladoo_maharashtrian_indian', 'Motichoor Ladoo (Maharashtrian)', 455, 6.2, 68.5, 18.5, 1.8, 42.5, 30, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fine besan boondi ladoo, Maharashtrian festival style', ARRAY['motichur_ladoo_maha','boondi_ladoo_maharashtra'], true, NULL, 'sweet_mithai', 62, 28, 10.5, 0, 198, 45, 2.2, 8, 0.5, 0, 28, 0.8, 118, 4.2, 0.04, 'West India', 'India'),
('sabudana_khichdi_peanut_rich_indian', 'Sabudana Khichdi (Peanut-Rich)', 325, 7.8, 52.5, 10.5, 2.5, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;tapioca pearl pilaf with generous peanuts, fasting food', ARRAY['sago_khichdi_peanut','sabudana_khichdi_upvas'], true, NULL, 'fasting_food', 285, 0, 1.8, 0, 278, 28, 1.8, 5, 2.5, 0, 45, 0.8, 115, 3.8, 0.06, 'West India', 'India'),
('sabudana_vada_fried_variant_indian', 'Sabudana Vada (Crispy Fried)', 285, 5.8, 38.5, 13.5, 2.0, 2.5, 40, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crispy pan-fried sago-potato patty, vrat food', ARRAY['sago_vada_fried','crispy_sabudana_vada'], true, NULL, 'fasting_food', 325, 0, 2.8, 0, 258, 22, 1.5, 5, 8.5, 0, 28, 0.6, 88, 3.0, 0.05, 'West India', 'India'),
('aamras_alphonso_maharashtrian_indian', 'Aamras (Alphonso, Maharashtrian)', 98, 0.8, 24.5, 0.5, 1.5, 22.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Alphonso mango pulp with milk, Maharashtra summer dish', ARRAY['hapus_aamras','alphonso_mango_pulp'], true, NULL, 'fruit_dessert', 5, 2, 0.1, 0, 285, 18, 0.5, 68, 28.5, 0, 12, 0.2, 22, 0.5, 0.05, 'West India', 'India'),
('aamras_puri_combo_indian', 'Aamras Puri (Complete Meal)', 312, 6.5, 52.5, 9.5, 2.8, 18.5, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;alphonso mango pulp served with fried wheat puri, festive', ARRAY['aamras_with_puri','mango_pulp_puri'], true, NULL, 'festive_meal', 285, 8, 2.5, 0, 298, 32, 2.5, 58, 22.5, 0, 22, 0.5, 88, 3.5, 0.06, 'West India', 'India'),
('prawn_curry_goan_red_indian', 'Prawn Curry (Goan Red)', 158, 14.5, 8.5, 8.2, 1.5, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan red coconut prawn curry with kokum souring', ARRAY['goan_red_prawn_curry','red_prawn_curry_goa'], true, NULL, 'prawn_curry', 545, 155, 3.5, 0, 318, 58, 2.5, 15, 7.5, 0, 28, 1.5, 205, 28.5, 0.38, 'West India', 'India'),
('fish_curry_goan_coconut_red_indian', 'Fish Curry (Goan, Coconut-Red)', 148, 14.2, 7.8, 7.5, 1.5, 2.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan red fish curry with coconut milk and dry red chilies', ARRAY['goan_red_fish_curry_variant','kokum_fish_curry_goa'], true, NULL, 'fish_curry', 512, 58, 3.0, 0, 348, 42, 1.8, 18, 6.5, 0, 28, 1.5, 198, 28.5, 0.55, 'West India', 'India'),
('thalipeeth_jowar_wheat_indian', 'Thalipeeth (Jowar-Wheat Mix)', 278, 9.2, 47.8, 6.8, 6.0, 1.5, 80, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;jowar+wheat+spice mixed flour flatbread', ARRAY['jowar_thalipeeth'], true, NULL, 'flatbread', 268, 0, 1.2, 0, 342, 45, 4.0, 15, 2.2, 0, 82, 1.3, 192, 5.2, 0.07, 'West India', 'India'),
('vada_pav_dry_garlic_chutney_indian', 'Vada Pav Dry Garlic Chutney (Standalone)', 385, 12.5, 38.5, 21.5, 8.5, 3.5, NULL, 20, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Maharashtrian dry garlic+peanut+coconut chutney used in vada pav', ARRAY['sukha_lehsun_chutney','dry_garlic_chutney_mumbai'], true, NULL, 'chutney_condiment', 485, 0, 3.8, 0, 485, 42, 4.2, 5, 2.5, 0, 52, 1.2, 148, 5.5, 0.10, 'West India', 'India'),
('kanda_bhaji_maharashtrian_indian', 'Kanda Bhaji (Onion Fritters, Maharashtrian)', 278, 6.2, 32.5, 14.5, 3.5, 4.5, 15, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crunchy onion pakora, Maharashtra monsoon snack', ARRAY['onion_bhaji_maharashtra','kanda_pakora_maharashtra'], true, NULL, 'fried_snack', 485, 0, 2.5, 0, 218, 42, 2.5, 5, 8.5, 0, 22, 0.8, 78, 3.2, 0.05, 'West India', 'India'),
('batata_vada_standalone_indian', 'Batata Vada (Standalone, Maharashtrian)', 212, 5.5, 28.5, 9.5, 3.0, 2.5, 55, 110, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced potato ball in chickpea batter, fried, Maharashtra', ARRAY['aloo_vada_maharashtra','potato_vada'], true, NULL, 'fried_snack', 485, 0, 1.8, 0, 285, 38, 2.2, 5, 9.5, 0, 28, 0.8, 82, 3.0, 0.05, 'West India', 'India'),
('gavhachi_roti_whole_wheat_maha_indian', 'Gavhachi Roti (Whole Wheat, Maharashtrian)', 268, 8.5, 49.5, 5.2, 5.8, 1.2, 60, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Maharashtrian whole wheat soft roti with ghee', ARRAY['whole_wheat_roti_maharashtra','gavhachi_poli'], true, NULL, 'flatbread', 12, 5, 2.0, 0, 228, 28, 3.2, 5, 0.8, 0, 62, 1.0, 148, 4.5, 0.06, 'West India', 'India'),
('mawa_kachori_rajasthani_filled_indian', 'Mawa Kachori (Khoya Filled, Jodhpur)', 428, 8.5, 55.5, 20.5, 2.5, 22.5, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Jodhpur specialty fried kachori with khoya sweet filling', ARRAY['jodhpuri_mawa_kachori','khoya_kachori_raj'], true, NULL, 'sweet_fried', 95, 28, 9.5, 0, 218, 68, 2.5, 22, 0.5, 0, 32, 0.8, 118, 4.5, 0.06, 'West India', 'India'),
('dal_makhani_rajasthani_black_indian', 'Dal Makhani (Rajasthani Style, with Desi Ghee)', 218, 9.8, 22.5, 10.5, 7.5, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow-cooked black urad dal with desi ghee, Rajasthani version', ARRAY['rajasthani_dal_makhani','desi_ghee_dal_makhani'], true, NULL, 'lentil_curry', 485, 22, 5.8, 0, 498, 58, 4.5, 35, 3.5, 0, 58, 1.8, 205, 5.5, 0.10, 'West India', 'India'),
('laapsi_rajasthani_wheat_halwa_indian', 'Laapsi (Broken Wheat Halwa, Rajasthani)', 355, 5.5, 52.5, 14.5, 4.2, 22.5, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;coarse wheat halwa with ghee and jaggery, Rajasthani dessert', ARRAY['lapsi_rajasthan','broken_wheat_halwa_raj'], true, NULL, 'sweet_dessert', 45, 28, 8.5, 0, 198, 25, 2.8, 5, 0.5, 0, 32, 0.8, 108, 4.2, 0.06, 'West India', 'India'),
('bajre_ki_khichdi_rajasthani_indian', 'Bajre ki Khichdi (Rajasthani Millet Porridge)', 218, 6.5, 38.5, 5.8, 6.0, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet+moong dal porridge, cold weather Rajasthani food', ARRAY['bajra_khichdi_raj','millet_khichdi_rajasthan'], true, NULL, 'porridge', 285, 8, 2.5, 0, 338, 35, 4.2, 8, 1.5, 0, 88, 1.2, 195, 5.8, 0.07, 'West India', 'India'),
('dahi_kachori_rajasthani_indian', 'Dahi Kachori (Yogurt, Rajasthani)', 295, 8.5, 40.5, 12.5, 4.5, 8.5, 60, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;kachori topped with dahi and chutneys, Rajasthani chaat', ARRAY['curd_kachori_raj','yogurt_kachori'], true, NULL, 'fried_chaat', 585, 5, 2.8, 0, 298, 88, 3.5, 25, 8.5, 0, 38, 1.0, 128, 4.5, 0.07, 'West India', 'India'),
('malpua_rajasthani_rabdi_indian', 'Malpua (Rajasthani, with Rabdi)', 365, 6.5, 55.5, 13.5, 1.5, 35.5, 40, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sweetened wheat+milk pancake fried in ghee, served with rabdi', ARRAY['rajasthani_malpua','malpua_with_rabdi'], true, NULL, 'sweet_fried', 85, 42, 7.5, 0, 218, 155, 1.5, 58, 1.0, 10, 20, 0.8, 135, 3.8, 0.07, 'West India', 'India'),
('gatte_ki_kadhi_rajasthani_indian', 'Gatte ki Kadhi (Besan Dumplings in Kadhi)', 148, 6.8, 15.5, 6.8, 3.2, 4.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;besan gatte in buttermilk-besan kadhi gravy', ARRAY['gatte_kadhi_raj','besan_dumpling_kadhi'], true, NULL, 'curry_sauce', 485, 10, 2.5, 0, 272, 88, 2.8, 22, 4.2, 0, 35, 0.9, 112, 4.2, 0.05, 'West India', 'India'),
('makki_ki_roti_rajasthani_indian', 'Makki ki Roti (Corn, Rajasthani)', 298, 7.2, 56.5, 6.5, 5.5, 2.5, 70, 140, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;corn flour flatbread served with sarson ka saag, Rajasthani winter', ARRAY['maize_roti_raj','corn_flatbread_rajasthan'], true, NULL, 'flatbread', 8, 0, 1.2, 0, 248, 8, 2.8, 15, 0.5, 0, 48, 0.8, 158, 3.8, 0.05, 'West India', 'India'),
('dhokla_sandwich_gujarati_indian', 'Dhokla Sandwich (Layered)', 168, 7.5, 24.8, 4.5, 2.2, 3.8, 50, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;khaman dhokla layered with chutney filling', ARRAY['sandwich_dhokla','layered_khaman'], true, NULL, 'steamed_snack', 545, 0, 0.8, 0, 188, 48, 2.0, 12, 2.5, 0, 25, 0.9, 100, 4.0, 0.04, 'West India', 'India'),
('sev_tameta_nu_shaak_gujarati_indian', 'Sev Tameta nu Shaak (Tomato-Sev)', 112, 3.5, 14.5, 5.2, 2.5, 6.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Gujarati tomato curry topped with sev, simple weekday sabzi', ARRAY['sev_tomato_sabzi','tameta_sev_shaak'], true, NULL, 'vegetable_curry', 385, 0, 1.2, 0, 325, 28, 1.8, 38, 18.5, 0, 22, 0.6, 48, 2.5, 0.08, 'West India', 'India'),
('gujarati_thali_complete_indian', 'Gujarati Thali (Complete, Traditional)', 185, 6.8, 26.5, 6.5, 3.8, 5.5, NULL, 500, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mixed thali average per 100g: rotli+dal+shaak+chaas+farsan', ARRAY['full_gujarati_thali','traditional_thali_gujarat'], true, NULL, 'thali_meal', 385, 8, 1.8, 0, 285, 58, 2.5, 28, 6.5, 0, 32, 0.8, 98, 3.5, 0.06, 'West India', 'India'),
('vaghareli_khichdi_gujarati_indian', 'Vaghareli Khichdi (Tempered)', 195, 7.5, 32.5, 5.2, 3.5, 1.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;tempered rice+moong dal khichdi, Gujarati comfort food', ARRAY['khichdi_vaghareli','gujarati_khichdi'], true, NULL, 'rice_lentil_porridge', 285, 0, 1.2, 0, 318, 35, 2.8, 18, 2.5, 0, 38, 1.0, 128, 4.2, 0.06, 'West India', 'India'),
('chorafali_gujarati_indian', 'Chorafali (Flat Fried Snack)', 485, 14.5, 55.5, 24.5, 4.5, 1.5, 5, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin flat fried urad dal+besan wafer, Gujarati festive snack', ARRAY['chorafalli','flat_farsan_gujarat'], true, NULL, 'fried_snack', 520, 0, 4.5, 0, 388, 55, 4.2, 8, 0.5, 0, 45, 1.5, 155, 6.2, 0.06, 'West India', 'India'),
('methi_na_gota_gujarati_indian', 'Methi na Gota (Fenugreek Fritter)', 265, 8.5, 32.5, 12.5, 4.5, 2.5, 20, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;besan+fenugreek leaf fritter, Gujarati monsoon snack', ARRAY['methi_gota','fenugreek_fritter_gujarat'], true, NULL, 'fried_snack', 485, 0, 2.5, 0, 325, 68, 3.8, 85, 8.5, 0, 48, 1.1, 112, 4.5, 0.08, 'West India', 'India'),
('papdi_chaat_gujarati_indian', 'Papdi Chaat (Gujarati Style)', 225, 6.2, 32.5, 9.5, 3.5, 8.5, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crispy papdi with sweet chutneys, dahi and sev, Gujarati version', ARRAY['gujarati_papdi_chaat','papdi_chaat_gujarat'], true, NULL, 'chaat', 585, 5, 2.2, 0, 268, 78, 2.5, 25, 8.5, 0, 28, 0.8, 98, 3.5, 0.06, 'West India', 'India'),
('dudhi_muthia_baked_indian', 'Dudhi Muthia (Bottlegourd Steamed)', 185, 7.2, 26.5, 5.5, 4.2, 3.8, 30, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;bottle gourd+besan steamed dumpling', ARRAY['lauki_muthia','bottlegourd_muthia'], true, NULL, 'steamed_snack', 398, 0, 1.0, 0, 298, 72, 2.8, 12, 6.5, 0, 38, 0.9, 95, 3.8, 0.07, 'West India', 'India'),
('kachori_moong_dal_gujarati_indian', 'Moong Dal Kachori (Gujarati)', 355, 9.2, 44.5, 17.5, 4.5, 2.5, 55, 110, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Gujarati fried kachori with spiced moong dal filling', ARRAY['gujarati_moong_kachori','mung_kachori_gujarat'], true, NULL, 'fried_snack', 468, 0, 3.5, 0, 275, 40, 3.2, 12, 2.2, 0, 40, 1.1, 122, 4.8, 0.07, 'West India', 'India'),
('mathia_gujarati_fried_wafer_indian', 'Mathia (Gujarati Fried Wafer)', 488, 12.5, 55.8, 25.5, 4.8, 1.2, 5, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin flat fried moong dal wafer snack, Gujarat', ARRAY['mathiya','mathia_farsan'], true, NULL, 'fried_snack', 498, 0, 4.8, 0, 362, 45, 3.5, 8, 0.5, 0, 42, 1.3, 138, 5.8, 0.06, 'West India', 'India'),
('lasan_chutney_gujarati_indian', 'Lasan Chutney (Gujarati Garlic)', 195, 6.5, 20.5, 10.8, 4.0, 3.5, NULL, 20, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Gujarati garlic+red chili chutney served with thepla and bhakri', ARRAY['garlic_chutney_gujarat','lasan_na_chutney'], true, NULL, 'chutney_condiment', 498, 0, 1.8, 0, 425, 48, 2.5, 8, 12.5, 0, 22, 0.8, 102, 2.5, 0.05, 'West India', 'India'),
('sukhdi_gujarati_wheat_sweet_indian', 'Sukhdi (Wheat Flour Sweet)', 465, 7.5, 60.5, 22.5, 2.8, 32.5, 30, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;roasted whole wheat flour+ghee+jaggery quick sweet', ARRAY['golpapdi','gol_papdi_sukhdi'], true, NULL, 'sweet_mithai', 55, 35, 13.5, 0, 195, 28, 3.2, 5, 0.5, 0, 32, 0.8, 115, 4.5, 0.06, 'West India', 'India'),
('dhokli_no_vagharo_gujarati_indian', 'Dhokli no Vagharo (Tempered Dhokli)', 175, 6.5, 26.5, 5.2, 3.5, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;leftover dal dhokli stir-fried with mustard tempering', ARRAY['vaghareli_dhokli','tempered_dhokli'], true, NULL, 'stir_fried_snack', 395, 0, 1.0, 0, 288, 52, 2.5, 38, 5.2, 0, 35, 0.9, 108, 4.0, 0.07, 'West India', 'India'),
('chaas_gujarati_spiced_indian', 'Chaas (Gujarati Spiced Buttermilk)', 35, 1.5, 4.5, 1.2, 0.2, 4.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin cumin+ginger+coriander spiced buttermilk, essential Gujarat accompaniment', ARRAY['gujarati_chaas','masala_buttermilk_gujarat'], true, NULL, 'beverage_drink', 195, 5, 0.8, 0, 155, 115, 0.1, 18, 0.5, 2, 12, 0.4, 92, 1.5, 0.02, 'West India', 'India'),
('kolhapuri_egg_curry_indian', 'Kolhapuri Egg Curry (Anda Kolhapuri)', 172, 12.5, 6.5, 11.5, 1.8, 1.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;hard-boiled eggs in Kolhapuri masala red gravy', ARRAY['anda_kolhapuri','egg_kolhapuri_masala'], true, NULL, 'egg_curry', 485, 210, 3.8, 0, 258, 52, 2.5, 95, 3.5, 12, 12, 1.2, 175, 15.5, 0.08, 'West India', 'India'),
('bharleli_vangi_maharashtrian_indian', 'Bharleli Vangi (Stuffed Brinjal, Maharashtrian)', 128, 3.5, 12.5, 7.8, 4.2, 5.5, 60, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;small brinjals stuffed with coconut-peanut-masala filling', ARRAY['stuffed_eggplant_maharashtra','bharli_vangi'], true, NULL, 'vegetable_curry', 385, 0, 1.5, 0, 338, 28, 1.5, 18, 5.5, 0, 22, 0.6, 58, 2.5, 0.08, 'West India', 'India'),
('kombdi_vade_malvani_indian', 'Kombdi Vade (Malvani Chicken + Fried Bread)', 268, 14.5, 28.5, 11.5, 3.5, 2.5, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Malvani spiced chicken served with crispy vade fried bread', ARRAY['chicken_vade_malvani','kombdi_vade'], true, NULL, 'chicken_with_bread', 545, 62, 4.0, 0, 348, 38, 2.8, 18, 8.5, 0, 28, 2.0, 178, 9.5, 0.18, 'West India', 'India'),
('shev_bhaji_maharashtrian_indian', 'Shev Bhaji (Maharashtrian Sev Curry)', 145, 5.8, 16.5, 7.5, 3.5, 3.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced sev (besan noodles) in thin gravy, rural Maharashtra', ARRAY['sev_bhaji_maharashtra','farsan_curry_maharashtra'], true, NULL, 'curry', 485, 0, 1.8, 0, 245, 45, 2.5, 12, 4.5, 0, 28, 0.8, 95, 3.8, 0.05, 'West India', 'India'),
('chakli_maharashtrian_diwali_indian', 'Chakli (Maharashtrian, Diwali)', 498, 10.5, 58.5, 25.5, 4.2, 1.5, 15, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fried spiral rice+wheat+besan snack, Diwali must', ARRAY['chakri_maharashtra','diwali_chakli'], true, NULL, 'fried_snack', 595, 0, 4.8, 0, 248, 38, 3.2, 8, 0.5, 0, 32, 1.0, 115, 4.5, 0.06, 'West India', 'India'),
('shankarpali_maharashtrian_indian', 'Shankarpali (Diwali Sweet Diamond)', 458, 7.5, 62.5, 21.5, 2.5, 22.5, 5, 60, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;diamond-shaped fried dough sweet, Maharashtrian Diwali', ARRAY['shankarpale','diamond_sweet_maharashtra'], true, NULL, 'sweet_fried', 65, 28, 9.5, 0, 145, 28, 2.2, 8, 0.5, 0, 18, 0.5, 88, 3.2, 0.04, 'West India', 'India'),
('caldeirada_goan_fish_stew_indian', 'Caldeirada (Goan Fish Stew)', 125, 13.5, 7.5, 5.2, 1.5, 2.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Portuguese-Goan layered fish and potato stew', ARRAY['goan_caldeirada','portuguese_fish_stew_goa'], true, NULL, 'fish_stew', 385, 58, 1.5, 0, 398, 35, 1.5, 15, 12.5, 0, 28, 1.2, 195, 26.5, 0.52, 'West India', 'India'),
('prawn_rava_fry_goan_indian', 'Prawn Rava Fry (Goan)', 212, 16.5, 14.5, 10.5, 0.8, 0.8, 15, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Goan spice-marinated prawn pan-fried with semolina crust', ARRAY['goan_prawn_fry','rawa_prawn_goa'], true, NULL, 'fried_prawn', 698, 155, 3.2, 0, 298, 62, 2.2, 15, 5.5, 0, 28, 1.5, 208, 30.5, 0.38, 'West India', 'India'),
('goan_fish_cutlet_indian', 'Goan Fish Cutlet (Croquette)', 228, 15.5, 18.5, 10.5, 1.5, 2.5, 50, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;minced fish+potato patty breadcrumbed and fried, Goan snack', ARRAY['fish_croquette_goa','goan_fish_patty'], true, NULL, 'fried_snack', 545, 68, 3.2, 0, 285, 42, 1.8, 12, 5.5, 0, 25, 1.2, 185, 22.5, 0.42, 'West India', 'India'),
('goan_prawn_curry_white_indian', 'Goan Prawn Curry (White Coconut)', 145, 13.5, 6.5, 8.2, 1.2, 2.5, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mild white coconut milk prawn curry, Goan Hindu style', ARRAY['white_coconut_prawn_goa','prawn_white_curry_goan'], true, NULL, 'prawn_curry', 425, 148, 5.5, 0, 305, 28, 2.0, 8, 4.5, 0, 25, 1.5, 195, 28.5, 0.38, 'West India', 'India'),
('pez_goan_rice_gruel_indian', 'Pez (Goan Rice Gruel)', 58, 1.5, 12.5, 0.5, 0.5, 0.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin rice porridge/gruel, Goan convalescent food', ARRAY['goan_pej','rice_gruel_goa'], true, NULL, 'porridge', 95, 0, 0.1, 0, 45, 8, 0.5, 0, 0.2, 0, 8, 0.2, 28, 1.0, 0.01, 'West India', 'India'),
('churma_laddoo_rajasthani_indian', 'Churma Laddoo (Rajasthani Ball)', 495, 9.2, 64.5, 22.8, 4.0, 28.5, 45, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;churma shaped into balls with ghee and dry fruits', ARRAY['churma_ladoo','rajasthani_churma_ball'], true, NULL, 'sweet_mithai', 92, 40, 13.2, 0, 212, 35, 3.5, 8, 0.5, 0, 36, 1.0, 128, 5.0, 0.07, 'West India', 'India'),
('ker_sangri_jowar_combo_indian', 'Ker Sangri Jowar Bhakri Combo', 252, 9.5, 40.5, 7.2, 8.5, 4.0, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Rajasthani desert berry sabzi with jowar flatbread, complete meal', ARRAY['ker_sangri_jowar','desert_berry_jowar'], true, NULL, 'dry_vegetable_with_bread', 388, 0, 1.5, 0, 462, 32, 4.5, 16, 6.8, 0, 70, 1.5, 192, 5.8, 0.08, 'West India', 'India'),
('raab_rajasthani_millet_drink_indian', 'Raab (Rajasthani Millet Drink)', 88, 2.5, 16.5, 2.2, 2.5, 5.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;fermented bajra gruel drink, Rajasthani summer cooling food', ARRAY['rabri_bajra_drink','bajra_fermented_gruel'], true, NULL, 'fermented_drink', 115, 5, 1.2, 0, 188, 42, 2.5, 5, 0.5, 0, 55, 0.8, 95, 3.5, 0.04, 'West India', 'India'),
('jodhpuri_kabab_rajasthani_indian', 'Jodhpuri Kabab (Rajasthani Mutton)', 245, 20.5, 8.5, 15.5, 1.5, 1.5, 40, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced mutton kebab Jodhpur style with raw papaya tenderizer', ARRAY['jodhpur_kabab','rajasthani_mutton_kebab'], true, NULL, 'mutton_kebab', 485, 85, 5.5, 0, 348, 28, 3.0, 15, 3.5, 0, 28, 3.8, 205, 12.5, 0.15, 'West India', 'India'),
('bajra_raab_winter_soup_indian', 'Bajra Raab (Winter Thick Soup)', 105, 3.2, 18.5, 2.8, 3.5, 3.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thick bajra+jaggery+ghee porridge, Rajasthani winter warming food', ARRAY['thick_raab','winter_raab_bajra'], true, NULL, 'porridge', 122, 8, 1.5, 0, 198, 35, 3.0, 5, 0.5, 0, 60, 0.8, 98, 3.8, 0.05, 'West India', 'India'),
('makhan_bada_rajasthani_indian', 'Makhan Bada (Butter Soaked Sweet)', 445, 7.5, 58.5, 22.5, 2.8, 28.5, 50, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;large soft baked flour sweet soaked in butter/ghee, Rajasthani', ARRAY['makkhan_bada','butter_bada_raj'], true, NULL, 'sweet_baked', 88, 45, 12.5, 0, 195, 35, 2.5, 12, 0.5, 0, 22, 0.6, 105, 4.2, 0.06, 'West India', 'India'),
('sarson_ka_saag_with_ghee_punjabi_indian', 'Sarson Ka Saag with Ghee (Punjabi)', 138, 4.2, 8.6, 9.8, 3.4, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;mustard greens cooked with ghee tadka', ARRAY['sarson_saag_ghee','sarson_ka_saag_desi_ghee'], true, NULL, 'vegetable_curry', 420, 18, 5.8, 0, 480, 210, 3.2, 580, 42, 0, 38, 0.8, 88, 2.1, 0.18, 'North India', 'India'),
('sarson_ka_saag_plain_punjabi_indian', 'Sarson Ka Saag Plain (Punjabi)', 96, 3.8, 8.2, 5.1, 3.6, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;mustard greens with minimal fat', ARRAY['sarson_saag_plain','plain_sarson_saag'], true, NULL, 'vegetable_curry', 310, 0, 1.8, 0, 460, 195, 3.0, 560, 40, 0, 36, 0.7, 82, 2.0, 0.14, 'North India', 'India'),
('sarson_ka_saag_paneer_punjabi_indian', 'Sarson Ka Saag with Paneer (Punjabi)', 162, 7.8, 7.4, 11.2, 3.1, 1.1, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mustard greens with cubed paneer', ARRAY['palak_paneer_sarson_variant','sarson_paneer'], true, NULL, 'vegetable_curry', 380, 24, 6.4, 0, 420, 280, 2.8, 510, 36, 4, 40, 1.2, 140, 3.2, 0.12, 'North India', 'India'),
('sarson_ka_saag_dhaba_style_punjabi_indian', 'Sarson Ka Saag Dhaba Style (Punjabi)', 152, 4.6, 9.1, 10.8, 3.2, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dhaba-style with white butter makhan on top', ARRAY['dhaba_sarson_saag','sarson_saag_makkhan'], true, NULL, 'vegetable_curry', 460, 24, 6.6, 0, 490, 220, 3.1, 590, 38, 2, 39, 0.9, 92, 2.2, 0.20, 'North India', 'India'),
('makki_di_roti_plain_punjabi_indian', 'Makki Di Roti Plain (Punjabi)', 248, 5.6, 44.2, 6.4, 3.8, 0.6, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;cornmeal flatbread plain', ARRAY['makki_roti','maize_roti_punjabi','corn_roti_punjabi'], true, NULL, 'bread', 180, 0, 1.2, 0, 180, 12, 1.8, 18, 0, 0, 28, 0.6, 92, 4.2, 0.06, 'North India', 'India'),
('makki_di_roti_with_ghee_punjabi_indian', 'Makki Di Roti with Ghee (Punjabi)', 298, 5.4, 43.8, 11.8, 3.6, 0.6, 90, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;cornmeal flatbread with desi ghee', ARRAY['makki_roti_ghee','ghee_makki_roti'], true, NULL, 'bread', 190, 28, 6.8, 0, 175, 14, 1.7, 20, 0, 0, 27, 0.6, 90, 4.0, 0.06, 'North India', 'India'),
('makki_di_roti_thick_village_punjabi_indian', 'Makki Di Roti Thick Village Style (Punjabi)', 262, 5.8, 46.0, 7.2, 4.0, 0.7, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;village-style thick makki roti', ARRAY['mota_makki_roti','village_makki_roti'], true, NULL, 'bread', 185, 0, 1.4, 0, 182, 14, 1.9, 20, 0, 0, 30, 0.7, 95, 4.4, 0.07, 'North India', 'India'),
('bhatura_classic_punjabi_indian', 'Bhatura Classic (Punjabi)', 312, 7.2, 42.6, 12.8, 1.4, 1.8, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;deep fried leavened bread', ARRAY['bhature','bhatoora_classic'], true, NULL, 'bread', 320, 0, 2.4, 0.2, 88, 28, 2.2, 0, 0, 0, 18, 0.6, 82, 6.8, 0.04, 'North India', 'India'),
('bhatura_stuffed_paneer_punjabi_indian', 'Bhatura Stuffed with Paneer (Punjabi)', 338, 9.4, 40.2, 15.2, 1.2, 1.6, 95, 95, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;deep fried bhatura stuffed with spiced paneer', ARRAY['paneer_bhatoora','stuffed_bhatura'], true, NULL, 'bread', 340, 18, 5.2, 0.1, 92, 88, 2.0, 12, 0, 2, 20, 0.8, 110, 6.2, 0.04, 'North India', 'India'),
('amritsari_kulcha_paneer_punjabi_indian', 'Amritsari Kulcha Paneer (Punjabi)', 292, 10.2, 38.4, 11.4, 1.8, 1.4, 120, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Amritsari-style tandoor kulcha stuffed with paneer', ARRAY['paneer_kulcha_amritsari','amritsari_paneer_kulcha'], true, NULL, 'bread', 360, 22, 4.8, 0, 145, 142, 2.4, 18, 1, 2, 24, 1.0, 148, 8.2, 0.06, 'North India', 'India'),
('amritsari_kulcha_gobi_punjabi_indian', 'Amritsari Kulcha Gobi (Punjabi)', 268, 7.8, 40.6, 8.8, 2.4, 1.8, 120, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Amritsari kulcha stuffed with spiced cauliflower', ARRAY['gobi_kulcha_amritsari','amritsari_cauliflower_kulcha'], true, NULL, 'bread', 340, 0, 2.2, 0, 168, 68, 2.6, 12, 22, 0, 22, 0.8, 98, 6.4, 0.05, 'North India', 'India'),
('amritsari_kulcha_keema_punjabi_indian', 'Amritsari Kulcha Keema (Punjabi)', 318, 14.2, 36.8, 13.6, 1.6, 1.2, 130, 130, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Amritsari kulcha stuffed with minced mutton keema', ARRAY['keema_kulcha_amritsari','mutton_kulcha_amritsari'], true, NULL, 'bread', 420, 42, 5.4, 0.1, 188, 52, 3.2, 8, 0, 0, 26, 2.2, 158, 10.4, 0.08, 'North India', 'India'),
('amritsari_kulcha_plain_butter_punjabi_indian', 'Amritsari Kulcha Plain with Butter (Punjabi)', 282, 7.4, 41.8, 9.6, 1.6, 1.6, 110, 110, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;plain Amritsari kulcha with white butter topping', ARRAY['plain_amritsari_kulcha','makkhan_kulcha'], true, 'Kulcha Land (reference style)', 'bread', 330, 20, 4.8, 0, 130, 58, 2.2, 22, 0, 0, 20, 0.8, 102, 7.2, 0.06, 'North India', 'India'),
('chicken_chole_punjabi_indian', 'Chicken Chole (Punjabi)', 186, 16.8, 14.2, 7.2, 4.2, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chickpea curry with chicken pieces', ARRAY['murgh_chole','chicken_chana'], true, NULL, 'chicken_curry', 520, 52, 2.0, 0, 420, 58, 3.8, 32, 6, 0, 38, 1.8, 182, 12.2, 0.12, 'North India', 'India'),
('paneer_chole_punjabi_indian', 'Paneer Chole (Punjabi)', 198, 11.4, 16.2, 9.8, 4.0, 0.9, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chickpea curry with paneer cubes', ARRAY['chana_paneer','chole_paneer'], true, NULL, 'paneer_curry', 480, 28, 4.2, 0, 380, 168, 3.4, 48, 4, 2, 40, 1.2, 162, 8.8, 0.08, 'North India', 'India'),
('pindi_chana_rawalpindi_punjabi_indian', 'Pindi Chana Rawalpindi Style (Punjabi)', 178, 9.2, 22.4, 5.8, 7.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry-style chickpea with amchur and pomegranate', ARRAY['pindi_chhole','rawalpindi_chana','sookha_pindi_chana'], true, NULL, 'lentil_curry', 460, 0, 0.8, 0, 420, 72, 4.2, 18, 8, 0, 48, 1.6, 148, 6.8, 0.10, 'North India', 'India'),
('amritsari_fish_fry_classic_punjabi_indian', 'Amritsari Fish Fry Classic (Punjabi)', 248, 22.4, 12.8, 12.2, 0.8, 0.4, 120, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;batter-fried sole/singhara with ajwain besan', ARRAY['amritsari_machhi','amritsari_fish_pakora'], true, NULL, 'seafood', 580, 82, 2.8, 0.2, 320, 48, 1.8, 28, 2, 48, 28, 0.8, 242, 28.4, 0.42, 'North India', 'India'),
('amritsari_fish_fry_mustard_punjabi_indian', 'Amritsari Fish Fry Mustard Marinated (Punjabi)', 238, 22.8, 10.4, 11.8, 0.6, 0.2, 120, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;batter-fried fish with mustard oil marinade', ARRAY['amritsari_fish_mustard','machhi_sarson'], true, NULL, 'seafood', 560, 80, 2.4, 0.2, 330, 52, 1.9, 30, 2, 50, 30, 0.9, 248, 29.0, 0.48, 'North India', 'India'),
('tandoori_pomfret_punjabi_indian', 'Tandoori Pomfret (Punjabi)', 168, 24.6, 4.2, 6.0, 0.2, 0.6, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;whole pomfret marinated in tandoori spices', ARRAY['tandoori_pomfret_fish','pomfret_tandoor'], true, NULL, 'seafood', 520, 92, 1.8, 0, 380, 62, 1.2, 42, 2, 80, 38, 0.8, 268, 32.0, 0.62, 'North India', 'India'),
('seekh_kebab_mutton_punjabi_indian', 'Seekh Kebab Mutton (Punjabi)', 268, 20.8, 6.4, 17.8, 0.6, 0.4, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;minced mutton seekh on skewer grilled in tandoor', ARRAY['mutton_seekh_kebab_punjabi','lamb_seekh_punjabi'], true, NULL, 'kebab', 580, 78, 7.2, 0.1, 320, 28, 2.8, 18, 2, 0, 24, 3.2, 188, 14.8, 0.24, 'North India', 'India'),
('seekh_kebab_paneer_punjabi_indian', 'Seekh Kebab Paneer (Punjabi)', 218, 11.2, 8.8, 16.4, 0.8, 0.8, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;minced paneer and vegetable seekh on skewer', ARRAY['paneer_seekh_kebab_punjabi','veg_seekh_punjabi'], true, NULL, 'kebab', 420, 42, 7.8, 0, 280, 188, 1.2, 28, 2, 4, 22, 0.8, 148, 6.2, 0.08, 'North India', 'India'),
('reshmi_kebab_chicken_punjabi_indian', 'Reshmi Kebab Chicken (Punjabi)', 238, 22.4, 5.6, 14.2, 0.2, 0.8, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;cream-marinated chicken kebab grilled on skewer', ARRAY['reshmi_kabab_chicken','silky_kebab_chicken'], true, NULL, 'kebab', 420, 82, 5.8, 0, 320, 38, 1.2, 48, 2, 8, 22, 1.4, 182, 12.8, 0.12, 'North India', 'India'),
('malai_tikka_chicken_punjabi_indian', 'Malai Tikka Chicken (Punjabi)', 248, 23.8, 4.2, 15.2, 0.1, 1.2, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;cream-cheese marinated chicken tikka', ARRAY['malai_chicken_tikka','cream_tikka_punjabi'], true, NULL, 'kebab', 380, 88, 6.8, 0, 340, 48, 1.0, 62, 2, 8, 24, 1.6, 192, 13.2, 0.10, 'North India', 'India'),
('punjabi_samosa_aloo_indian', 'Punjabi Samosa Aloo (Punjabi)', 292, 5.8, 36.4, 14.2, 3.4, 1.2, 90, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;large Punjabi-style deep fried aloo samosa', ARRAY['aloo_samosa_punjabi','potato_samosa_punjabi'], true, NULL, 'snack', 380, 0, 2.8, 0.4, 320, 28, 2.4, 12, 12, 0, 22, 0.6, 72, 4.2, 0.06, 'North India', 'India'),
('punjabi_samosa_keema_indian', 'Punjabi Samosa Keema (Punjabi)', 318, 12.4, 32.8, 16.4, 2.6, 0.8, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;large Punjabi-style samosa with spiced minced meat filling', ARRAY['keema_samosa_punjabi','mutton_samosa_punjabi'], true, NULL, 'snack', 460, 38, 6.2, 0.2, 340, 32, 3.2, 8, 4, 0, 24, 1.8, 98, 7.8, 0.08, 'North India', 'India'),
('pakora_onion_punjabi_indian', 'Pakora Onion (Punjabi)', 248, 6.2, 28.4, 13.2, 2.8, 1.8, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;crispy besan-coated onion fritters', ARRAY['pyaz_pakora_punjabi','onion_bhaji_punjabi'], true, NULL, 'snack', 320, 0, 2.4, 0.4, 148, 48, 2.2, 4, 4, 0, 18, 0.6, 78, 4.8, 0.06, 'North India', 'India'),
('pakora_paneer_punjabi_indian', 'Pakora Paneer (Punjabi)', 298, 11.8, 24.6, 17.4, 1.8, 0.8, 30, 120, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;besan-coated paneer deep fried pakora', ARRAY['paneer_pakora_punjabi','cheese_pakora'], true, NULL, 'snack', 340, 32, 7.2, 0.2, 108, 248, 2.0, 28, 2, 4, 22, 1.0, 188, 6.8, 0.06, 'North India', 'India'),
('pakora_gobi_punjabi_indian', 'Pakora Gobi (Punjabi)', 238, 6.8, 26.8, 12.4, 3.2, 1.6, 30, 120, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;besan-coated cauliflower deep fried fritters', ARRAY['gobi_pakora_punjabi','cauliflower_pakora'], true, NULL, 'snack', 290, 0, 2.0, 0.4, 188, 42, 2.4, 6, 28, 0, 20, 0.6, 82, 5.2, 0.06, 'North India', 'India'),
('pakora_mirchi_punjabi_indian', 'Pakora Mirchi Green Chilli (Punjabi)', 228, 5.4, 28.2, 11.2, 3.4, 2.2, 30, 120, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;large green chilli stuffed with spiced besan and deep fried', ARRAY['mirchi_pakora_punjabi','hari_mirch_pakora'], true, NULL, 'snack', 300, 0, 1.8, 0.4, 248, 38, 2.8, 18, 68, 0, 22, 0.6, 72, 4.8, 0.06, 'North India', 'India'),
('aloo_tikki_punjabi_style_indian', 'Aloo Tikki Punjabi Style', 218, 4.2, 32.4, 8.8, 3.2, 1.2, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;pan fried potato patties with chutneys', ARRAY['punjabi_aloo_tikki','potato_tikki_punjabi'], true, NULL, 'snack', 380, 0, 1.8, 0.2, 420, 22, 2.2, 2, 12, 0, 28, 0.6, 62, 3.8, 0.04, 'North India', 'India'),
('papdi_chaat_punjabi_indian', 'Papdi Chaat (Punjabi)', 198, 5.8, 28.2, 7.4, 3.8, 6.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;crispy papdi with yogurt chutneys and sev', ARRAY['papri_chaat','papri_chaat_punjabi'], true, NULL, 'snack', 420, 12, 2.4, 0, 320, 88, 2.0, 18, 6, 2, 22, 0.8, 88, 4.2, 0.06, 'North India', 'India'),
('mango_lassi_punjabi_style_indian', 'Mango Lassi Punjabi Style', 118, 3.2, 18.4, 3.8, 0.4, 16.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thick Punjabi mango lassi with dahi and alphonso', ARRAY['punjabi_mango_lassi','aam_lassi_punjabi'], true, NULL, 'beverage', 62, 14, 2.2, 0, 220, 118, 0.2, 42, 8, 4, 18, 0.4, 88, 2.8, 0.04, 'North India', 'India'),
('salted_lassi_punjabi_style_indian', 'Salted Lassi Punjabi Style (Namkeen)', 72, 3.6, 6.8, 3.2, 0, 4.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;salty yogurt drink with roasted cumin', ARRAY['namkeen_lassi_punjabi','punjabi_salted_lassi'], true, NULL, 'beverage', 380, 14, 1.8, 0, 188, 122, 0.2, 8, 0, 4, 14, 0.4, 82, 2.4, 0.04, 'North India', 'India'),
('mah_di_dal_punjabi_indian', 'Mah Di Dal (Punjabi Black Lentil)', 148, 9.2, 18.4, 4.2, 5.8, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;whole black urad dal cooked slow with tadka', ARRAY['maa_di_dal','kaali_dal_punjabi','whole_urad_dal_punjabi'], true, NULL, 'lentil_curry', 420, 0, 0.8, 0, 380, 42, 3.2, 8, 2, 0, 52, 1.4, 148, 5.8, 0.08, 'North India', 'India'),
('langar_wali_dal_punjabi_indian', 'Langar Wali Dal (Punjabi Gurdwara Dal)', 138, 8.8, 20.2, 2.8, 6.2, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Sikh langar-style mixed dal with whole spices', ARRAY['gurudwara_dal','langar_dal','sikh_dal'], true, 'Golden Temple Langar (reference style)', 'lentil_curry', 280, 0, 0.4, 0, 420, 48, 3.6, 4, 2, 0, 56, 1.6, 158, 6.2, 0.10, 'North India', 'India'),
('dal_makhani_classic_punjabi_indian', 'Dal Makhani Classic (Punjabi)', 198, 8.4, 16.8, 10.8, 5.2, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;slow-cooked black lentil with butter and cream', ARRAY['dal_makhni_classic','makhani_dal_classic'], true, NULL, 'lentil_curry', 480, 28, 5.8, 0, 360, 82, 3.4, 48, 2, 4, 48, 1.2, 152, 6.4, 0.12, 'North India', 'India'),
('dal_makhani_restaurant_style_punjabi_indian', 'Dal Makhani Restaurant Style (Punjabi)', 242, 8.8, 16.4, 14.2, 4.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;restaurant-style dal makhani heavy cream and butter', ARRAY['dal_makhni_restaurant','creamy_dal_makhani'], true, 'Moti Mahal (reference style)', 'lentil_curry', 520, 48, 8.2, 0, 340, 92, 3.2, 62, 2, 6, 44, 1.2, 148, 6.2, 0.10, 'North India', 'India'),
('rajma_chawal_kashmiri_rajma_indian', 'Rajma Chawal Kashmiri Rajma', 168, 8.2, 24.8, 4.2, 6.8, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;small Kashmiri-specific kidney beans cooked in tomato gravy', ARRAY['kashmiri_rajma_chawal','red_kidney_bean_kashmiri'], true, NULL, 'lentil_curry', 380, 0, 0.8, 0, 440, 48, 3.8, 18, 6, 0, 52, 1.4, 148, 5.8, 0.08, 'North India', 'India'),
('rajma_chitra_himachali_indian', 'Rajma Chitra Himachali Style', 158, 8.6, 22.4, 3.8, 7.2, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spotted Chitra beans from Himachal cooked Punjabi style', ARRAY['chitra_rajma','spotted_beans_punjabi'], true, NULL, 'lentil_curry', 340, 0, 0.6, 0, 460, 52, 4.0, 12, 4, 0, 54, 1.6, 152, 6.0, 0.08, 'North India', 'India'),
('rajma_red_punjabi_classic_indian', 'Rajma Red Classic (Punjabi)', 172, 8.4, 24.2, 4.6, 6.4, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;classic red kidney bean curry Punjab-style', ARRAY['lal_rajma_punjabi','red_kidney_bean_punjabi'], true, NULL, 'lentil_curry', 360, 0, 0.8, 0, 450, 50, 3.8, 15, 5, 0, 50, 1.4, 145, 5.8, 0.08, 'North India', 'India'),
('butter_chicken_classic_punjabi_indian', 'Butter Chicken Classic Murg Makhani (Punjabi)', 192, 17.8, 8.4, 10.2, 1.2, 3.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;classic butter chicken with tomato-cream sauce', ARRAY['murgh_makhani_classic','makhani_chicken_classic'], true, 'Moti Mahal (reference style)', 'chicken_curry', 520, 72, 4.8, 0, 420, 38, 1.8, 88, 6, 8, 28, 1.4, 182, 14.2, 0.14, 'North India', 'India'),
('butter_chicken_dhaba_style_punjabi_indian', 'Butter Chicken Dhaba Style (Punjabi)', 228, 18.4, 9.2, 13.2, 1.4, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dhaba-style with more spice and less cream', ARRAY['dhaba_murgh_makhani','dhaba_butter_chicken'], true, NULL, 'chicken_curry', 580, 78, 5.8, 0, 440, 32, 2.0, 72, 5, 4, 30, 1.6, 188, 14.8, 0.14, 'North India', 'India'),
('butter_chicken_makhmali_punjabi_indian', 'Butter Chicken Makhmali Velvety (Punjabi)', 218, 16.8, 7.8, 13.4, 0.8, 4.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;velvety smooth extra-cream butter chicken variant', ARRAY['makhmali_murgh_makhani','velvet_butter_chicken'], true, NULL, 'chicken_curry', 480, 88, 7.2, 0, 400, 48, 1.6, 98, 4, 8, 26, 1.2, 178, 13.8, 0.12, 'North India', 'India'),
('tandoori_chicken_full_punjabi_indian', 'Tandoori Chicken Full (Punjabi)', 172, 24.8, 3.6, 7.2, 0.4, 1.2, 500, 500, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;whole chicken marinated and cooked in tandoor', ARRAY['full_tandoori_chicken','poora_tandoori_murgh'], true, NULL, 'chicken', 480, 92, 2.4, 0, 380, 22, 1.8, 38, 2, 4, 26, 2.0, 198, 22.4, 0.12, 'North India', 'India'),
('tandoori_chicken_tikka_punjabi_indian', 'Tandoori Chicken Tikka (Punjabi)', 168, 25.2, 4.2, 5.8, 0.4, 1.4, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;boneless chicken tikka grilled in tandoor', ARRAY['chicken_tikka_tandoori','tikka_tandoor_punjabi'], true, NULL, 'chicken', 440, 88, 2.0, 0, 360, 18, 1.6, 32, 2, 4, 24, 1.8, 192, 20.8, 0.10, 'North India', 'India'),
('laccha_paratha_punjabi_layered_indian', 'Laccha Paratha Punjabi Layered', 282, 7.4, 38.8, 11.4, 2.8, 0.8, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;multi-layered whole wheat paratha with ghee', ARRAY['layered_paratha_punjabi','lachha_paratha_punjabi'], true, NULL, 'bread', 360, 22, 5.8, 0, 148, 28, 2.8, 0, 0, 0, 28, 0.8, 118, 8.4, 0.06, 'North India', 'India'),
('punjabi_kadhi_pakora_homestyle_indian', 'Punjabi Kadhi Pakora Homestyle', 148, 5.8, 16.4, 6.8, 1.8, 3.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;yogurt-besan kadhi with onion pakora', ARRAY['kadhi_pakodi_punjabi','homestyle_kadhi_pakora'], true, NULL, 'vegetable_curry', 480, 18, 2.2, 0, 248, 148, 1.8, 38, 2, 4, 28, 0.8, 98, 4.8, 0.08, 'North India', 'India'),
('patiala_chicken_punjabi_indian', 'Patiala Chicken (Punjabi)', 208, 19.2, 7.8, 11.8, 1.2, 2.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;royal Patiala-style rich chicken with cream and spices', ARRAY['murgh_patiala','patiala_murgh'], true, NULL, 'chicken_curry', 540, 82, 5.2, 0, 380, 42, 2.2, 68, 4, 6, 28, 1.6, 188, 15.8, 0.12, 'North India', 'India'),
('saag_murgh_punjabi_indian', 'Saag Murgh Chicken with Mustard Greens (Punjabi)', 178, 17.2, 7.4, 9.2, 2.8, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken cooked in sarson saag base', ARRAY['murgh_saag','chicken_saag_punjabi'], true, NULL, 'chicken_curry', 460, 72, 3.2, 0, 420, 82, 2.8, 280, 24, 4, 32, 1.6, 178, 14.2, 0.16, 'North India', 'India'),
('rogan_josh_kashmiri_pandit_indian', 'Rogan Josh Kashmiri Pandit Style (No Onion)', 212, 18.4, 4.8, 13.8, 0.8, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;Kashmiri Pandit rogan josh without onion-garlic, ratanjot color', ARRAY['pandit_rogan_josh','vegetarian_kashmiri_rogan_josh_base'], true, NULL, 'mutton_curry', 420, 72, 5.8, 0, 320, 32, 2.8, 38, 4, 0, 24, 2.8, 182, 12.4, 0.22, 'North India', 'India'),
('rogan_josh_kashmiri_muslim_indian', 'Rogan Josh Kashmiri Muslim Style (With Onion)', 222, 18.8, 5.6, 14.4, 0.6, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Muslim Waza style rogan josh with onion and Kashmiri mirch', ARRAY['waza_rogan_josh','muslim_rogan_josh'], true, NULL, 'mutton_curry', 480, 78, 6.2, 0, 340, 28, 3.0, 42, 2, 0, 26, 3.0, 188, 13.2, 0.20, 'North India', 'India'),
('yakhni_mutton_kashmiri_indian', 'Yakhni Mutton (Kashmiri)', 188, 18.2, 4.2, 11.2, 0.4, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri mutton in yogurt-fennel-cardamom sauce', ARRAY['mutton_yakhni_kashmiri','gosht_yakhni_kashmiri'], true, NULL, 'mutton_curry', 380, 72, 4.8, 0, 340, 42, 2.6, 12, 2, 0, 22, 2.8, 178, 12.2, 0.18, 'North India', 'India'),
('yakhni_chicken_kashmiri_indian', 'Yakhni Chicken (Kashmiri)', 168, 19.4, 4.6, 8.4, 0.4, 1.6, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken in Kashmiri yogurt-fennel broth', ARRAY['murgh_yakhni_kashmiri','chicken_yakhni_kashmiri'], true, NULL, 'chicken_curry', 340, 68, 3.2, 0, 360, 38, 1.4, 8, 2, 0, 20, 1.6, 172, 14.2, 0.14, 'North India', 'India'),
('yakhni_lotus_stem_kashmiri_indian', 'Yakhni Lotus Stem Nadir (Kashmiri)', 128, 4.2, 14.8, 6.2, 2.8, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lotus root nadru in yogurt yakhni sauce', ARRAY['nadru_yakhni_kashmiri','lotus_stem_yakhni'], true, NULL, 'vegetable_curry', 280, 8, 2.8, 0, 420, 48, 2.2, 4, 18, 0, 28, 0.6, 88, 2.8, 0.08, 'North India', 'India'),
('gushtaba_wazwan_kashmiri_indian', 'Gushtaba Wazwan (Kashmiri Meatball in Cream)', 248, 19.2, 6.2, 16.4, 0.4, 1.8, 60, 240, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;pounded mutton meatballs in cream-yogurt sauce wazwan', ARRAY['gosht_gufta_kashmiri','kashmiri_meatball_cream'], true, NULL, 'mutton_curry', 420, 82, 7.8, 0, 300, 58, 2.4, 18, 2, 0, 22, 2.4, 178, 11.8, 0.18, 'North India', 'India'),
('rista_kashmiri_indian', 'Rista Kashmiri (Meatballs in Red Gravy)', 232, 18.4, 5.8, 15.2, 0.6, 1.4, 55, 220, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;fine-minced mutton meatballs in spiced red Kashmiri gravy', ARRAY['kashmiri_rista','rista_gosht'], true, NULL, 'mutton_curry', 440, 78, 6.8, 0, 310, 32, 2.6, 42, 2, 0, 24, 2.6, 182, 12.4, 0.20, 'North India', 'India'),
('tabak_maaz_fried_ribs_kashmiri_indian', 'Tabak Maaz Fried Lamb Ribs (Kashmiri)', 342, 22.8, 4.2, 26.4, 0.2, 0.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;deep fried lamb ribs after slow-cooking in milk', ARRAY['tabakh_maaz','kashmiri_fried_ribs','tabak_lamb'], true, NULL, 'mutton', 460, 98, 11.2, 0.2, 280, 28, 2.2, 12, 0, 0, 20, 2.8, 188, 14.8, 0.24, 'North India', 'India'),
('matschgand_kashmiri_minced_mutton_indian', 'Matschgand Kashmiri Minced Mutton', 268, 20.2, 6.4, 18.2, 0.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;minced mutton in fiery Kashmiri red chilli gravy', ARRAY['matsyagand','kashmiri_keema_curry','methi_maaz_variant'], true, NULL, 'mutton_curry', 480, 82, 7.8, 0, 320, 28, 3.0, 42, 2, 0, 24, 3.0, 188, 13.8, 0.22, 'North India', 'India'),
('methi_maaz_kashmiri_fenugreek_mutton_indian', 'Methi Maaz Kashmiri (Mutton with Fenugreek)', 238, 18.8, 7.2, 15.4, 2.2, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri mutton cooked with fresh fenugreek leaves', ARRAY['fenugreek_mutton_kashmiri','kashmiri_methi_gosht'], true, NULL, 'mutton_curry', 440, 72, 6.4, 0, 360, 68, 3.4, 82, 8, 0, 32, 2.8, 182, 12.8, 0.20, 'North India', 'India'),
('kabargah_kashmiri_milk_fried_ribs_indian', 'Kabargah Kashmiri Milk Fried Ribs', 322, 21.4, 6.8, 23.8, 0.2, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lamb ribs slow cooked in milk spices then shallow fried', ARRAY['kashmiri_kabargah','kabarab_kashmiri'], true, NULL, 'mutton', 420, 92, 9.8, 0, 270, 48, 2.2, 22, 0, 4, 22, 2.6, 182, 13.8, 0.22, 'North India', 'India'),
('aab_gosht_kashmiri_milk_mutton_indian', 'Aab Gosht Kashmiri (Mutton in Milk Gravy)', 218, 18.6, 5.4, 13.6, 0.2, 2.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri mutton braised in milk with cardamom', ARRAY['milk_gosht_kashmiri','kashmiri_doodh_gosht'], true, NULL, 'mutton_curry', 320, 78, 5.8, 0, 320, 68, 2.4, 18, 0, 4, 22, 2.4, 178, 12.2, 0.18, 'North India', 'India'),
('kashmiri_dum_aloo_pandit_style_indian', 'Kashmiri Dum Aloo Pandit Style', 142, 3.4, 18.8, 6.4, 3.2, 2.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;small potatoes in fennel-asafoetida-yogurt gravy no onion garlic', ARRAY['dum_aloo_kashmiri_pandit','kashmiri_aloo_dum'], true, NULL, 'vegetable_curry', 380, 8, 2.8, 0, 480, 48, 2.2, 18, 8, 0, 32, 0.8, 82, 4.2, 0.08, 'North India', 'India'),
('nadru_yakhni_kashmiri_lotus_stem_indian', 'Nadru Yakhni Kashmiri Lotus Stem in Yogurt', 132, 4.8, 15.2, 6.2, 3.0, 1.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lotus root cooked in fennel-yogurt Kashmiri sauce', ARRAY['lotus_stem_yakhni_kashmiri','nadir_in_yakhni'], true, NULL, 'vegetable_curry', 290, 8, 2.8, 0, 430, 52, 2.4, 4, 20, 0, 30, 0.6, 90, 2.8, 0.08, 'North India', 'India'),
('haak_saag_kashmiri_mustard_greens_indian', 'Haak Saag Kashmiri (Collard Greens)', 62, 3.2, 6.4, 2.4, 4.2, 0.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;Kashmiri collard greens in asafoetida mustard oil', ARRAY['kashmiri_haak','haak_saag_kashmiri'], true, NULL, 'vegetable_curry', 320, 0, 0.4, 0, 480, 220, 3.8, 620, 62, 0, 42, 0.6, 72, 2.2, 0.12, 'North India', 'India'),
('chaman_kaliya_kashmiri_paneer_indian', 'Chaman Kaliya Kashmiri Paneer Curry', 228, 10.8, 8.4, 17.2, 0.8, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri paneer in yellow turmeric-fennel gravy', ARRAY['kashmiri_chaman','paneer_kaliya_kashmiri'], true, NULL, 'paneer_curry', 360, 38, 7.8, 0, 210, 298, 1.2, 42, 2, 4, 28, 1.0, 188, 6.8, 0.08, 'North India', 'India'),
('nadir_palak_kashmiri_lotus_spinach_indian', 'Nadir Palak Kashmiri (Lotus Stem Spinach)', 118, 5.2, 10.8, 6.2, 4.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lotus stem with spinach Kashmiri style', ARRAY['lotus_stem_spinach_kashmiri','nadru_spinach'], true, NULL, 'vegetable_curry', 340, 0, 1.2, 0, 520, 168, 3.8, 420, 32, 0, 48, 0.8, 98, 3.2, 0.12, 'North India', 'India'),
('nadur_monje_kashmiri_lotus_pakora_indian', 'Nadur Monje Kashmiri Lotus Stem Fritters', 228, 5.8, 28.4, 11.2, 3.4, 0.8, 30, 120, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;lotus root slices dipped in besan batter and deep fried', ARRAY['nadir_pakora','lotus_root_fritters_kashmiri'], true, NULL, 'snack', 280, 0, 1.8, 0.2, 380, 48, 2.8, 4, 12, 0, 32, 0.6, 88, 4.2, 0.08, 'North India', 'India'),
('monje_haakh_kashmiri_kohlrabi_indian', 'Monje Haakh Kashmiri (Kohlrabi Greens)', 58, 2.8, 6.2, 2.2, 3.6, 1.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;kohlrabi greens cooked with asafoetida mustard oil', ARRAY['kohlrabi_greens_kashmiri','kashmiri_monje'], true, NULL, 'vegetable_curry', 290, 0, 0.4, 0, 420, 192, 2.8, 380, 52, 0, 38, 0.6, 68, 1.8, 0.10, 'North India', 'India'),
('kashmiri_pulao_saffron_dry_fruits_indian', 'Kashmiri Pulao Saffron with Dry Fruits', 218, 4.8, 36.2, 6.4, 1.2, 4.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;saffron rice with dry fruits and whole spices', ARRAY['kashmiri_saffron_pulao','zafrani_pulao_kashmiri'], true, NULL, 'rice', 180, 12, 2.8, 0, 188, 42, 1.8, 18, 2, 0, 32, 0.8, 92, 6.2, 0.08, 'North India', 'India'),
('modur_pulao_sweet_kashmiri_rice_indian', 'Modur Pulao Sweet Kashmiri Rice', 242, 4.2, 42.8, 7.2, 0.8, 14.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;sweet rice with jaggery saffron dry fruits Kashmiri festival', ARRAY['sweet_kashmiri_pulao','shirin_pulao_kashmiri'], true, NULL, 'rice', 140, 14, 3.2, 0, 148, 38, 1.4, 12, 1, 0, 22, 0.6, 78, 4.8, 0.06, 'North India', 'India'),
('kashmiri_sheermal_saffron_bread_indian', 'Kashmiri Sheermal Saffron Bread', 288, 7.2, 46.2, 9.2, 1.2, 8.4, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri saffron-milk enriched flatbread', ARRAY['kashmiri_sheermal','saffron_naan_kashmiri'], true, NULL, 'bread', 240, 28, 4.2, 0, 128, 62, 2.4, 18, 0, 4, 20, 0.8, 108, 8.2, 0.06, 'North India', 'India'),
('kashmiri_phirni_saffron_clay_indian', 'Kashmiri Phirni Saffron in Clay Bowl', 178, 4.8, 28.4, 6.2, 0.2, 20.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ground rice milk pudding with saffron in shikora clay pot', ARRAY['shikora_phirni','saffron_phirni_kashmiri'], true, NULL, 'dessert', 82, 22, 3.2, 0, 148, 148, 0.4, 28, 0, 4, 16, 0.4, 112, 4.8, 0.04, 'North India', 'India'),
('shufta_kashmiri_dry_fruit_dessert_indian', 'Shufta Kashmiri Dry Fruit Dessert', 468, 8.4, 48.2, 28.4, 4.2, 32.8, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri dry fruit and cheese dessert with sugar syrup', ARRAY['kashmiri_shufta','dry_fruit_halwa_kashmiri'], true, NULL, 'dessert', 42, 22, 6.8, 0, 480, 88, 2.8, 8, 4, 0, 48, 1.2, 148, 8.4, 0.12, 'North India', 'India'),
('kashmiri_harissa_mutton_overnight_indian', 'Kashmiri Harissa Mutton Overnight', 268, 22.4, 14.8, 13.8, 1.8, 0.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow-cooked mutton pounded into porridge winter breakfast', ARRAY['kashmiri_harisa_mutton','overnight_mutton_harissa'], true, NULL, 'mutton_curry', 480, 82, 5.8, 0, 320, 48, 3.2, 18, 2, 0, 28, 3.2, 198, 14.8, 0.22, 'North India', 'India'),
('wazwan_roghan_josh_feast_kashmiri_indian', 'Wazwan Rogan Josh Feast Plate (Kashmiri)', 218, 18.6, 5.2, 14.2, 0.6, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;traditional Kashmiri wazwan feast portion of rogan josh', ARRAY['wazwan_rogan_josh','kashmiri_wazwan_gosht'], true, NULL, 'mutton_curry', 460, 78, 6.2, 0, 330, 30, 2.8, 42, 3, 0, 25, 2.9, 185, 12.8, 0.20, 'North India', 'India'),
('wazwan_seekh_platter_kashmiri_indian', 'Wazwan Seekh Platter (Kashmiri)', 272, 21.2, 6.8, 18.2, 0.8, 0.6, 50, 200, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri wazwan-style seekh platter with charcoal', ARRAY['wazwan_seekh_kebab_platter','kashmiri_wazwan_seekh'], true, NULL, 'kebab', 480, 82, 7.8, 0, 290, 28, 2.6, 18, 2, 0, 22, 3.0, 185, 13.8, 0.22, 'North India', 'India'),
('galouti_kebab_chicken_lucknowi_indian', 'Galouti Kebab Chicken (Lucknowi)', 278, 16.8, 5.2, 21.4, 0.6, 0.6, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;melt-in-mouth chicken galouti with 160+ spices', ARRAY['galawati_kebab_chicken','chicken_galouti_lucknow'], true, 'Tunday Kababi (reference style)', 'kebab', 560, 72, 8.8, 0, 260, 18, 1.2, 28, 2, 0, 20, 1.4, 172, 11.8, 0.14, 'North India', 'India'),
('galouti_kebab_veg_lucknowi_indian', 'Galouti Kebab Vegetarian (Lucknowi)', 248, 8.2, 12.4, 19.8, 2.8, 1.4, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;vegetarian galouti with rajma and paneer base', ARRAY['veg_galouti_kebab','vegetarian_galawati'], true, NULL, 'kebab', 440, 14, 6.8, 0, 240, 68, 1.8, 18, 2, 0, 22, 0.8, 98, 5.8, 0.08, 'North India', 'India'),
('galouti_kebab_soya_lucknowi_indian', 'Galouti Kebab Soya (Lucknowi)', 258, 14.8, 10.8, 18.2, 3.2, 1.2, 25, 100, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;soya-based galouti kebab Awadhi style', ARRAY['soya_galouti_kebab','soy_galawati'], true, NULL, 'kebab', 420, 0, 3.2, 0, 280, 42, 2.4, 8, 2, 0, 28, 0.8, 112, 6.2, 0.10, 'North India', 'India'),
('tunday_kebab_mutton_lucknowi_style_indian', 'Tunday Kebab Mutton Lucknowi Style', 298, 18.4, 4.8, 22.8, 0.6, 0.8, 25, 100, 4, 'manual_branded', 'hyperregional-apr2026;nutritionix;Tunday Kababi Lucknow recipe-estimated;legendary one-armed Haji Murad Ali recipe style', ARRAY['tunde_kebab','tunday_kababi_kebab'], true, 'Tunday Kababi', 'kebab', 620, 72, 9.4, 0.1, 280, 18, 2.8, 38, 0.8, 0, 22, 3.2, 182, 12.8, 0.22, 'North India', 'India'),
('shami_kebab_chicken_lucknowi_indian', 'Shami Kebab Chicken (Lucknowi)', 218, 17.4, 8.4, 13.2, 1.4, 0.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken shami kebab with chana dal patty Awadhi style', ARRAY['chicken_shami_lucknow','murgh_shami_awadhi'], true, NULL, 'kebab', 480, 62, 5.2, 0, 280, 32, 1.8, 18, 2, 0, 22, 1.4, 168, 11.2, 0.12, 'North India', 'India'),
('nargisi_kofta_lucknowi_indian', 'Nargisi Kofta Lucknowi (Egg Stuffed Meatball)', 268, 18.8, 6.8, 18.8, 0.8, 1.2, 70, 210, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;boiled egg wrapped in minced mutton in rich gravy', ARRAY['nargisi_kofta_awadhi','egg_stuffed_meatball_lucknowi'], true, NULL, 'mutton_curry', 520, 188, 7.8, 0, 310, 52, 2.8, 88, 2, 8, 24, 2.4, 198, 14.2, 0.18, 'North India', 'India'),
('biryani_awadhi_mutton_lucknowi_indian', 'Biryani Awadhi Mutton Lucknowi Dum', 218, 13.8, 24.8, 7.4, 1.2, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;Lucknowi pakki dum biryani mutton kewra saffron', ARRAY['lucknowi_mutton_biryani','awadhi_gosht_biryani'], true, NULL, 'rice', 420, 48, 2.8, 0, 280, 38, 2.2, 28, 2, 0, 32, 2.2, 168, 12.4, 0.14, 'North India', 'India'),
('biryani_awadhi_chicken_lucknowi_indian', 'Biryani Awadhi Chicken Lucknowi Dum', 198, 13.2, 24.2, 6.2, 1.0, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi pakki dum chicken biryani kewra rose water', ARRAY['lucknowi_chicken_biryani','awadhi_murgh_biryani'], true, NULL, 'rice', 380, 42, 2.2, 0, 260, 32, 1.8, 22, 2, 0, 28, 1.8, 158, 11.2, 0.12, 'North India', 'India'),
('nihari_lucknowi_mutton_slow_cooked_indian', 'Nihari Lucknowi Mutton Slow Cooked', 228, 18.2, 8.4, 14.2, 1.4, 0.6, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow overnight-cooked mutton shank nihari Lucknow style', ARRAY['lucknowi_nihari','awadhi_nihari_mutton'], true, NULL, 'mutton_curry', 520, 82, 6.2, 0, 360, 38, 3.4, 18, 2, 0, 28, 3.0, 192, 14.8, 0.22, 'North India', 'India'),
('korma_lucknowi_chicken_awadhi_indian', 'Korma Lucknowi Chicken (Awadhi)', 198, 17.8, 6.4, 12.2, 0.8, 2.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;white Awadhi chicken korma with cashew-cream sauce', ARRAY['awadhi_chicken_korma','white_korma_lucknow'], true, NULL, 'chicken_curry', 440, 72, 4.8, 0, 320, 42, 1.4, 28, 2, 4, 24, 1.4, 178, 13.2, 0.12, 'North India', 'India'),
('korma_lucknowi_mutton_awadhi_indian', 'Korma Lucknowi Mutton (Awadhi)', 228, 18.8, 6.8, 14.8, 0.8, 2.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow dum mutton korma Awadhi style thick yogurt gravy', ARRAY['awadhi_mutton_korma','gosht_korma_lucknowi'], true, NULL, 'mutton_curry', 480, 82, 6.2, 0, 340, 38, 2.6, 22, 2, 0, 26, 2.6, 188, 14.2, 0.20, 'North India', 'India'),
('korma_lucknowi_shahi_veg_awadhi_indian', 'Korma Lucknowi Shahi Veg (Awadhi)', 178, 6.8, 12.4, 12.2, 2.4, 3.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;shahi vegetable korma Awadhi style with cashew cream', ARRAY['shahi_veg_korma_lucknowi','awadhi_vegetable_korma'], true, NULL, 'vegetable_curry', 360, 14, 4.8, 0, 280, 88, 1.4, 42, 6, 4, 28, 0.8, 108, 5.8, 0.08, 'North India', 'India'),
('pasanda_mutton_lucknowi_indian', 'Pasanda Mutton Lucknowi (Flattened Mutton)', 242, 20.4, 6.2, 15.8, 0.6, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;tender flattened mutton escalopes in almond cream gravy', ARRAY['mutton_pasanda_lucknowi','gosht_pasanda_awadhi'], true, NULL, 'mutton_curry', 460, 82, 6.8, 0, 330, 38, 2.4, 22, 2, 0, 24, 2.8, 188, 13.8, 0.20, 'North India', 'India'),
('pasanda_chicken_lucknowi_indian', 'Pasanda Chicken Lucknowi (Flat Escalopes)', 218, 19.8, 5.8, 13.4, 0.4, 1.6, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;flat chicken breast escalopes in Awadhi almond gravy', ARRAY['chicken_pasanda_awadhi','murgh_pasanda_lucknowi'], true, NULL, 'chicken_curry', 420, 72, 5.2, 0, 350, 34, 1.4, 18, 2, 4, 22, 1.6, 182, 14.2, 0.12, 'North India', 'India'),
('murgh_mussallam_lucknowi_indian', 'Murgh Mussallam Lucknowi (Whole Stuffed Chicken)', 198, 20.4, 6.8, 10.8, 0.8, 2.4, 800, 800, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;whole chicken stuffed with egg and spices slow cooked', ARRAY['murg_mussalam_lucknow','whole_stuffed_chicken_awadhi'], true, NULL, 'chicken', 420, 142, 4.2, 0, 380, 52, 2.2, 68, 4, 8, 28, 2.0, 198, 18.4, 0.14, 'North India', 'India'),
('makhan_malai_lucknowi_winter_dessert_indian', 'Makhan Malai Lucknowi Winter Dessert', 168, 3.8, 12.4, 12.2, 0, 10.8, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;airy whipped cream dessert made overnight in cold dew', ARRAY['malai_makhan_lucknow','doodh_ki_malai_lucknowi'], true, NULL, 'dessert', 62, 42, 7.2, 0, 128, 108, 0.2, 82, 0, 4, 12, 0.2, 88, 3.8, 0.06, 'North India', 'India'),
('nimish_lucknowi_frothy_dessert_indian', 'Nimish Lucknowi Frothy Cream Dessert', 142, 3.2, 10.8, 10.2, 0, 9.4, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi winter frothy milk dessert similar to makhan malai', ARRAY['lucknowi_nimish','daulat_ki_chaat_lucknowi_variant'], true, NULL, 'dessert', 58, 38, 5.8, 0, 118, 102, 0.2, 72, 0, 4, 10, 0.2, 82, 3.4, 0.06, 'North India', 'India'),
('kulfi_falooda_lucknowi_indian', 'Kulfi Falooda Lucknowi', 168, 4.2, 24.8, 6.4, 0.8, 18.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;kulfi served over falooda noodles with rose syrup', ARRAY['falooda_kulfi_lucknow','kulfi_with_falooda'], true, NULL, 'dessert', 68, 22, 3.8, 0, 168, 128, 0.4, 42, 2, 4, 14, 0.4, 98, 4.2, 0.04, 'North India', 'India'),
('zafrani_phirni_lucknowi_saffron_indian', 'Zafrani Phirni Lucknowi Saffron Rice Pudding', 182, 4.6, 28.8, 6.2, 0.2, 20.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi saffron phirni in earthen bowl', ARRAY['saffron_phirni_awadhi','zafran_phirni_lucknow'], true, NULL, 'dessert', 72, 22, 3.4, 0, 152, 152, 0.4, 28, 0, 4, 16, 0.4, 112, 4.8, 0.04, 'North India', 'India'),
('shahi_tukda_lucknowi_awadhi_indian', 'Shahi Tukda Lucknowi (Awadhi Bread Pudding)', 328, 6.8, 44.2, 14.4, 0.6, 28.4, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;fried bread in saffron rabri Lucknowi style', ARRAY['double_ka_meetha_lucknowi_variant','shahi_tukra_awadhi'], true, NULL, 'dessert', 148, 38, 8.2, 0, 178, 148, 0.8, 62, 0, 6, 18, 0.4, 118, 5.8, 0.06, 'North India', 'India'),
('gilafi_seekh_kebab_lucknowi_indian', 'Gilafi Seekh Kebab Lucknowi (Bell Pepper Wrapped)', 262, 19.4, 7.8, 17.4, 1.4, 1.8, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;seekh kebab wrapped in diced bell peppers and onion', ARRAY['gilafi_kebab_lucknow','coloured_pepper_seekh'], true, NULL, 'kebab', 540, 72, 6.8, 0, 310, 28, 2.4, 82, 28, 0, 22, 2.4, 178, 12.8, 0.18, 'North India', 'India'),
('khameeri_roti_lucknowi_leavened_indian', 'Khameeri Roti Lucknowi (Leavened Flatbread)', 238, 7.8, 42.8, 5.2, 2.2, 1.4, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;naturally leavened whole wheat flatbread Awadhi style', ARRAY['khamiri_roti_lucknow','fermented_roti_awadhi'], true, NULL, 'bread', 280, 4, 1.4, 0, 128, 28, 2.8, 0, 0, 0, 26, 0.8, 112, 8.2, 0.06, 'North India', 'India'),
('roomali_roti_lucknowi_thin_indian', 'Roomali Roti Lucknowi Thin Handkerchief Bread', 228, 6.8, 44.2, 3.2, 1.8, 0.8, 50, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ultra-thin roti flipped on inverted kadai Awadhi style', ARRAY['rumaali_roti_lucknowi','thin_roti_awadhi'], true, NULL, 'bread', 240, 0, 0.6, 0, 112, 18, 2.4, 0, 0, 0, 22, 0.6, 98, 7.2, 0.04, 'North India', 'India'),
('ulte_tawe_ka_paratha_lucknowi_indian', 'Ulte Tawe Ka Paratha Lucknowi (Inverted Griddle)', 268, 7.4, 40.4, 9.8, 2.8, 0.8, 90, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;paratha cooked on inverted tawa Awadhi specialty', ARRAY['ulta_tawa_paratha','inverted_griddle_paratha'], true, NULL, 'bread', 310, 12, 3.8, 0, 138, 28, 2.6, 4, 0, 0, 26, 0.8, 108, 7.8, 0.06, 'North India', 'India'),
('kakori_kebab_mutton_lucknowi_style_indian', 'Kakori Kebab Mutton Lucknowi Style', 288, 17.8, 5.8, 21.8, 0.6, 0.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;melt-in-mouth minced mutton kakori kebab on skewer', ARRAY['kakori_kabab_lucknow','kakori_seekh'], true, NULL, 'kebab', 580, 68, 9.2, 0, 270, 22, 2.6, 28, 0.8, 0, 21, 3.0, 178, 12.4, 0.22, 'North India', 'India'),
('litti_chokha_sattu_classic_bihari_indian', 'Litti Chokha Sattu Classic (Bihari)', 318, 11.4, 48.2, 9.8, 5.4, 1.2, 80, 240, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;sattu-filled wheat dough balls baked on cow dung fire', ARRAY['sattu_litti_chokha','litti_baati_bihari'], true, NULL, 'main_course', 420, 0, 2.2, 0, 380, 42, 3.8, 12, 8, 0, 48, 1.4, 148, 6.8, 0.10, 'North India', 'India'),
('litti_chokha_aloo_baingan_bihari_indian', 'Litti Chokha Aloo Baingan (Bihari)', 288, 9.8, 44.8, 8.4, 5.8, 2.4, 80, 320, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;litti with roasted potato-brinjal chokha accompaniment', ARRAY['litti_with_baingan_chokha','bihari_litti_baingan'], true, NULL, 'main_course', 380, 0, 1.8, 0, 420, 38, 3.4, 8, 12, 0, 42, 1.2, 128, 5.8, 0.08, 'North India', 'India'),
('litti_chokha_tomato_bihari_indian', 'Litti Chokha Tomato Chokha (Bihari)', 278, 10.2, 44.2, 7.8, 5.2, 3.8, 80, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;litti with roasted tomato chokha variant', ARRAY['litti_tamatar_chokha','bihari_litti_tomato'], true, NULL, 'main_course', 360, 0, 1.6, 0, 440, 32, 3.2, 22, 18, 0, 40, 1.2, 118, 5.4, 0.08, 'North India', 'India'),
('litti_mutton_stuffed_bihari_indian', 'Litti Mutton Stuffed (Bihari)', 368, 16.8, 40.4, 15.8, 4.2, 1.0, 100, 300, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;litti stuffed with spiced minced mutton keema', ARRAY['keema_litti','mutton_litti_bihari'], true, NULL, 'main_course', 480, 42, 5.4, 0.1, 360, 38, 3.8, 8, 4, 0, 38, 2.4, 168, 10.8, 0.12, 'North India', 'India'),
('champaran_mutton_handi_bihari_indian', 'Champaran Mutton Handi Ahuna (Bihari)', 258, 22.4, 5.4, 16.8, 0.8, 1.2, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;slow cooked mutton in sealed earthen pot Champaran district', ARRAY['ahuna_mutton','champaran_handi_gosht','bihari_mutton_handi'], true, NULL, 'mutton_curry', 480, 88, 6.8, 0, 360, 32, 3.2, 18, 2, 0, 28, 3.4, 192, 16.8, 0.24, 'North India', 'India'),
('thekua_bihari_festival_cookie_indian', 'Thekua Bihari Festival Cookie (Chhath)', 418, 6.8, 62.4, 16.4, 2.2, 22.8, 30, 90, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;deep fried wheat jaggery cookie Chhath Puja prasad', ARRAY['thekua_chhath','bihari_thekua_sweet','wheat_jaggery_cookie_bihari'], true, NULL, 'snack', 82, 12, 6.8, 0.4, 148, 38, 2.8, 4, 0, 0, 22, 0.8, 92, 5.4, 0.06, 'North India', 'India'),
('sattu_paratha_bihari_style_indian', 'Sattu Paratha Bihari Style', 278, 12.4, 38.8, 9.2, 5.8, 1.2, 90, 90, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;roasted chana sattu filled wheat paratha', ARRAY['bihari_sattu_paratha','sattu_stuffed_paratha_bihari'], true, NULL, 'bread', 380, 4, 2.2, 0, 320, 42, 3.8, 8, 4, 0, 52, 1.4, 158, 7.8, 0.10, 'North India', 'India'),
('sattu_sherbet_bihari_summer_drink_indian', 'Sattu Sherbet Bihari Summer Drink', 98, 5.2, 16.4, 1.8, 3.2, 2.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;roasted chana flour drink with lemon raw mango', ARRAY['sattu_drink_bihari','sattu_sharbat','bihari_sattu_beverage'], true, NULL, 'beverage', 280, 0, 0.2, 0, 288, 28, 2.2, 4, 8, 0, 48, 0.8, 118, 4.2, 0.04, 'North India', 'India'),
('banarasi_kachori_sabzi_up_indian', 'Banarasi Kachori Sabzi (UP/Banaras)', 348, 8.4, 46.2, 15.2, 5.2, 1.8, 60, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Banarasi thick urad dal kachori with aloo sabzi', ARRAY['banaras_kachori_sabji','kachori_sabzi_varanasi'], true, NULL, 'snack', 420, 0, 3.2, 0.4, 340, 32, 3.2, 8, 12, 0, 32, 0.8, 98, 5.8, 0.08, 'North India', 'India'),
('banarasi_tamatar_chaat_up_indian', 'Banarasi Tamatar Chaat (UP/Banaras)', 148, 4.2, 22.4, 5.2, 4.2, 6.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Varanasi-style sweet-sour tomato chaat with chutney', ARRAY['tamatar_chaat_banaras','varanasi_tomato_chaat'], true, NULL, 'snack', 380, 0, 1.2, 0, 420, 28, 2.4, 88, 28, 0, 28, 0.6, 72, 3.8, 0.06, 'North India', 'India'),
('banarasi_dahi_gol_gappe_up_indian', 'Banarasi Dahi Gol Gappe (UP/Banaras)', 168, 5.4, 26.8, 5.2, 2.8, 8.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pani puri with yogurt filling Banaras style', ARRAY['dahi_golgappa_banaras','dahi_puri_banarasi'], true, NULL, 'snack', 320, 12, 2.4, 0, 280, 88, 1.8, 12, 4, 2, 18, 0.6, 78, 3.8, 0.04, 'North India', 'India'),
('aloo_tikki_banarasi_style_up_indian', 'Aloo Tikki Banarasi Style (UP)', 228, 5.2, 32.8, 9.8, 3.8, 2.4, 70, 140, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Varanasi-style large potato tikki with matar and chutney', ARRAY['varanasi_aloo_tikki','banaras_tikki'], true, NULL, 'snack', 380, 0, 1.8, 0.2, 440, 28, 2.8, 8, 12, 0, 30, 0.8, 78, 4.2, 0.06, 'North India', 'India'),
('peda_mathura_classic_up_indian', 'Peda Mathura Classic (UP/Mathura)', 388, 8.4, 58.2, 14.8, 0.4, 48.4, 25, 75, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;Mathura khoa peda with cardamom saffron', ARRAY['mathura_peda','mathura_ka_peda'], true, NULL, 'dessert', 68, 28, 8.8, 0, 248, 188, 0.4, 28, 0, 4, 18, 0.4, 198, 5.8, 0.04, 'North India', 'India'),
('old_delhi_nihari_mutton_indian', 'Old Delhi Nihari Mutton (Dilli Nihari)', 238, 19.8, 8.8, 14.8, 1.6, 0.6, NULL, 300, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated;Karim-style Old Delhi mutton nihari slow cooked overnight', ARRAY['dilli_nihari','old_delhi_mutton_nihari','karim_nihari'], true, 'Karim''s Hotel (reference style)', 'mutton_curry', 540, 88, 6.4, 0, 370, 40, 3.6, 18, 2, 0, 30, 3.2, 196, 15.8, 0.24, 'North India', 'India'),
('old_delhi_mutton_korma_indian', 'Old Delhi Mutton Korma (Dilli Korma)', 248, 20.2, 7.2, 16.2, 1.0, 2.8, NULL, 250, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated;Karim-style Old Delhi mughlai mutton korma', ARRAY['dilli_mutton_korma','karim_korma','old_delhi_gosht_korma'], true, 'Karim''s Hotel (reference style)', 'mutton_curry', 500, 82, 7.2, 0, 345, 42, 2.8, 24, 2, 0, 26, 2.8, 188, 14.4, 0.20, 'North India', 'India'),
('haryanvi_bajra_khichdi_winter_indian', 'Haryanvi Bajra Khichdi Winter (Haryana)', 168, 6.8, 28.4, 3.8, 4.2, 0.6, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pearl millet khichdi Haryanvi winter staple', ARRAY['bajra_khichdi_haryana','haryana_bajra_khichdi'], true, NULL, 'main_course', 280, 0, 0.8, 0, 240, 32, 3.2, 8, 2, 0, 58, 1.2, 128, 4.8, 0.08, 'North India', 'India'),
('singri_ki_sabzi_haryanvi_indian', 'Singri Ki Sabzi Haryanvi (Dried Moth Bean Pods)', 142, 7.8, 18.4, 4.8, 8.4, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dried moth bean pods cooked in yogurt gravy Haryana', ARRAY['singri_sabzi','dried_moth_bean_pods_haryana'], true, NULL, 'vegetable_curry', 320, 0, 0.8, 0, 380, 48, 3.8, 18, 4, 0, 52, 1.2, 138, 5.4, 0.08, 'North India', 'India'),
('kachri_ki_sabzi_haryanvi_indian', 'Kachri Ki Sabzi Haryanvi (Wild Cucumber)', 88, 3.2, 12.4, 3.2, 3.8, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;wild cucumber Cucumis pubescens sabzi Haryanvi style', ARRAY['kachri_sabzi_haryana','wild_cucumber_haryana'], true, NULL, 'vegetable_curry', 290, 0, 0.6, 0, 340, 38, 1.8, 12, 18, 0, 28, 0.6, 62, 2.8, 0.06, 'North India', 'India'),
('bathua_raita_haryanvi_indian', 'Bathua Raita Haryanvi (Chenopodium Yogurt)', 68, 3.8, 6.2, 2.8, 1.8, 3.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chenopodium/bathua leaves mixed in yogurt', ARRAY['bathua_dahi_raita','chenopodium_raita_haryana'], true, NULL, 'condiment', 240, 12, 1.4, 0, 248, 128, 1.8, 188, 18, 2, 22, 0.6, 88, 2.8, 0.06, 'North India', 'India'),
('banarasi_jalebi_up_style_indian', 'Banarasi Jalebi UP Style (Varanasi)', 368, 4.2, 62.8, 12.4, 0.4, 42.8, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;thick Banarasi jalebi fried in desi ghee with mawa rabri', ARRAY['banaras_jalebi','varanasi_jalebi'], true, NULL, 'dessert', 62, 12, 5.4, 0, 68, 28, 0.8, 4, 0, 0, 12, 0.4, 48, 3.2, 0.04, 'North India', 'India'),
('rasmalai_up_lucknowi_style_indian', 'Rasmalai UP Lucknowi Style', 218, 7.8, 28.4, 8.8, 0.2, 24.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;soft chena discs in saffron-cardamom milk Lucknowi variant', ARRAY['rasmalai_lucknowi','up_rasmalai'], true, NULL, 'dessert', 82, 32, 5.2, 0, 148, 148, 0.4, 38, 0, 4, 14, 0.4, 118, 4.4, 0.04, 'North India', 'India'),
('gujiya_up_holi_sweet_indian', 'Gujiya UP Holi Sweet (Mawa Stuffed)', 398, 7.4, 52.8, 18.4, 1.8, 28.4, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;deep fried mawa-coconut stuffed pastry UP Holi festival', ARRAY['gujhiya_up','karanji_up_variant','holi_gujiya'], true, NULL, 'dessert', 92, 22, 7.8, 0.4, 128, 58, 1.8, 12, 0, 0, 18, 0.6, 88, 5.2, 0.06, 'North India', 'India'),
('missi_roti_punjabi_besan_indian', 'Missi Roti Punjabi Besan Flatbread', 258, 10.8, 36.4, 8.2, 5.8, 1.4, 70, 70, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;besan-atta mixed flatbread with fenugreek', ARRAY['besan_atta_roti_punjabi','punjabi_missi_roti'], true, NULL, 'bread', 320, 0, 1.4, 0, 248, 58, 3.4, 12, 4, 0, 52, 1.2, 148, 8.8, 0.08, 'North India', 'India'),
('butter_naan_punjabi_tandoor_indian', 'Butter Naan Punjabi Tandoor', 268, 7.8, 44.2, 7.4, 1.6, 2.4, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;leavened naan cooked in tandoor with butter topping', ARRAY['naan_butter_punjabi','tandoor_butter_naan'], true, NULL, 'bread', 340, 18, 3.8, 0, 142, 38, 2.4, 12, 0, 0, 22, 0.8, 112, 8.2, 0.06, 'North India', 'India'),
('garlic_naan_punjabi_tandoor_indian', 'Garlic Naan Punjabi Tandoor', 272, 8.2, 44.8, 7.6, 1.8, 2.2, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;leavened naan with roasted garlic topping', ARRAY['lahsun_naan','garlic_tandoor_naan'], true, NULL, 'bread', 380, 18, 3.4, 0, 158, 36, 2.6, 8, 2, 0, 24, 0.8, 114, 8.4, 0.06, 'North India', 'India'),
('tandoori_pomfret_ajwain_punjabi_indian', 'Tandoori Pomfret with Ajwain (Punjabi)', 162, 24.2, 3.8, 6.2, 0.2, 0.4, 300, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;pomfret marinated with ajwain carom seed tandoor', ARRAY['ajwain_pomfret_tandoor','carom_pomfret_punjabi'], true, NULL, 'seafood', 510, 90, 1.6, 0, 370, 60, 1.2, 40, 2, 80, 36, 0.8, 262, 30.0, 0.60, 'North India', 'India'),
('punjabi_chicken_curry_dhaba_indian', 'Punjabi Chicken Curry Dhaba Style', 192, 17.8, 8.4, 10.2, 2.2, 2.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rustic dhaba Punjabi chicken curry with whole spices', ARRAY['daba_chicken_curry_punjabi','dhaba_murgh_punjabi'], true, NULL, 'chicken_curry', 520, 72, 3.8, 0, 420, 38, 2.4, 42, 8, 0, 28, 1.6, 182, 14.8, 0.14, 'North India', 'India'),
('pinni_punjabi_winter_sweet_indian', 'Pinni Punjabi Winter Sweet', 468, 9.8, 54.2, 24.8, 3.4, 28.4, 40, 80, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;atta-ghee-jaggery-dry fruit winter energy balls', ARRAY['punjabi_pinni','atta_pinni','winter_laddu_punjabi'], true, NULL, 'dessert', 62, 28, 12.4, 0, 288, 68, 3.8, 8, 0, 0, 48, 1.4, 148, 7.8, 0.14, 'North India', 'India'),
('punjabi_chicken_keema_indian', 'Punjabi Chicken Keema (Minced Chicken)', 218, 22.4, 6.8, 12.2, 1.8, 1.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced minced chicken with peas Punjabi style', ARRAY['chicken_keema_punjabi','murgh_keema_punjabi'], true, NULL, 'chicken_curry', 480, 82, 4.8, 0, 380, 28, 2.2, 42, 8, 0, 26, 1.6, 178, 14.2, 0.12, 'North India', 'India'),
('rajma_jammu_chikkar_style_indian', 'Rajma Jammu Chikkar Style (J&K)', 182, 9.2, 24.8, 5.2, 7.0, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Jammu-style red kidney bean thick gravy with ghee', ARRAY['jammu_rajma','chikkar_rajma'], true, NULL, 'lentil_curry', 370, 8, 2.2, 0, 445, 52, 4.0, 14, 5, 0, 50, 1.4, 148, 5.8, 0.08, 'North India', 'India'),
('paneer_tikka_punjabi_tandoor_indian', 'Paneer Tikka Punjabi Tandoor', 248, 13.2, 8.8, 18.4, 0.8, 2.2, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;marinated paneer cubes grilled in tandoor', ARRAY['tandoori_paneer_tikka','punjabi_paneer_tikka'], true, NULL, 'paneer', 420, 42, 8.8, 0, 188, 348, 1.4, 42, 2, 4, 28, 1.2, 228, 8.2, 0.08, 'North India', 'India'),
('paneer_tikka_malai_punjabi_indian', 'Paneer Tikka Malai Punjabi', 278, 12.8, 7.2, 22.4, 0.4, 2.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;cream-marinated paneer tikka in tandoor', ARRAY['malai_paneer_tikka','creamy_paneer_tikka'], true, NULL, 'paneer', 380, 52, 11.2, 0, 168, 358, 1.2, 58, 2, 6, 26, 1.0, 218, 7.8, 0.06, 'North India', 'India'),
('chicken_tikka_masala_punjabi_indian', 'Chicken Tikka Masala (Punjabi)', 168, 16.8, 8.4, 8.2, 1.4, 3.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;grilled chicken tikka in creamy tomato masala sauce', ARRAY['tikka_masala_chicken','murgh_tikka_masala'], true, NULL, 'chicken_curry', 500, 68, 3.8, 0, 400, 42, 1.8, 78, 6, 6, 28, 1.4, 178, 13.4, 0.12, 'North India', 'India'),
('achari_chicken_punjabi_indian', 'Achari Chicken Punjabi (Pickle-Spiced)', 188, 18.4, 7.2, 10.4, 1.6, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken cooked in pickling spices mustard fennel', ARRAY['chicken_achari','achari_murgh_punjabi'], true, NULL, 'chicken_curry', 560, 72, 3.2, 0, 380, 32, 2.0, 38, 4, 0, 26, 1.6, 178, 14.2, 0.12, 'North India', 'India'),
('handi_chicken_punjabi_clay_pot_indian', 'Handi Chicken Punjabi Clay Pot', 202, 18.8, 7.8, 11.2, 1.8, 2.2, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken slow cooked in sealed clay handi pot', ARRAY['clay_pot_chicken_punjabi','matka_chicken_punjabi'], true, NULL, 'chicken_curry', 480, 78, 4.4, 0, 400, 36, 2.0, 48, 4, 0, 28, 1.6, 182, 14.4, 0.12, 'North India', 'India'),
('kashmiri_methi_chicken_indian', 'Kashmiri Methi Chicken (Fenugreek)', 178, 18.8, 5.8, 9.8, 2.4, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;chicken with fresh fenugreek Kashmiri style', ARRAY['murgh_methi_kashmiri','fenugreek_chicken_kashmiri'], true, NULL, 'chicken_curry', 400, 68, 3.2, 0, 360, 52, 2.2, 72, 8, 0, 28, 1.4, 172, 13.2, 0.14, 'North India', 'India'),
('kashmiri_dum_aloo_muslim_style_indian', 'Kashmiri Dum Aloo Muslim Style (With Onion)', 158, 3.8, 18.4, 8.2, 3.6, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Muslim-style Kashmiri dum aloo with onion tomato', ARRAY['dum_aloo_kashmiri_muslim','kashmiri_dum_aloo_onion'], true, NULL, 'vegetable_curry', 420, 8, 3.2, 0, 500, 48, 2.4, 22, 10, 0, 32, 0.8, 82, 4.4, 0.08, 'North India', 'India'),
('kashmiri_mutton_seekh_kebab_indian', 'Kashmiri Mutton Seekh Kebab', 272, 21.4, 5.8, 18.2, 0.6, 0.6, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri-spiced mutton seekh with fennel cardamom', ARRAY['kashmiri_seekh_mutton','wazwan_seekh_mutton'], true, NULL, 'kebab', 460, 78, 7.8, 0, 295, 28, 2.8, 18, 2, 0, 22, 3.0, 185, 13.4, 0.22, 'North India', 'India'),
('kashmiri_kehwa_saffron_tea_indian', 'Kashmiri Kehwa Saffron Tea', 48, 0.8, 8.4, 1.2, 0.4, 6.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri green tea with saffron almonds cardamom', ARRAY['kehwa_kashmiri_tea','qahwa_kashmiri'], true, NULL, 'beverage', 12, 0, 0.4, 0, 88, 28, 0.4, 4, 2, 0, 12, 0.2, 22, 0.8, 0.04, 'North India', 'India'),
('wazwan_tabak_maaz_feast_kashmiri_indian', 'Wazwan Tabak Maaz Feast Portion (Kashmiri)', 332, 22.2, 4.4, 25.8, 0.2, 0.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kashmiri wazwan deep fried lamb chops with saffron', ARRAY['tabak_maaz_wazwan','kashmiri_fried_chops_wazwan'], true, NULL, 'mutton', 450, 96, 10.8, 0.2, 278, 30, 2.2, 14, 0, 0, 20, 2.8, 188, 14.4, 0.24, 'North India', 'India'),
('goshtaba_kashmiri_meatball_indian', 'Goshtaba Kashmiri Meatball', 242, 18.8, 5.8, 16.2, 0.4, 1.6, 55, 220, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;pounded mutton balls in yogurt-cream sauce; note: gushtaba and goshtaba are regional spelling variants', ARRAY['kashmiri_goshtaba','pounded_mutton_balls_kashmiri'], true, NULL, 'mutton_curry', 410, 80, 7.4, 0, 305, 56, 2.4, 18, 2, 0, 22, 2.4, 178, 11.8, 0.18, 'North India', 'India'),
('wazwan_aab_gosht_kashmiri_indian', 'Wazwan Aab Gosht (Kashmiri Milk Mutton)', 212, 18.2, 5.2, 13.4, 0.2, 2.6, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;wazwan component mutton in full cream milk sauce', ARRAY['wazwan_milk_gosht','aab_gosht_wazwan_portion'], true, NULL, 'mutton_curry', 318, 76, 5.6, 0, 315, 70, 2.4, 16, 0, 4, 22, 2.4, 175, 12.0, 0.18, 'North India', 'India'),
('shami_kebab_mutton_lucknowi_awadhi_indian', 'Shami Kebab Mutton Lucknowi (Awadhi)', 228, 18.2, 8.2, 14.2, 1.6, 0.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;mutton chana dal patty kebab Lucknowi style', ARRAY['mutton_shami_awadhi','gosht_shami_lucknowi'], true, NULL, 'kebab', 500, 68, 5.8, 0, 290, 36, 2.4, 18, 2, 0, 24, 2.0, 172, 12.2, 0.18, 'North India', 'India'),
('biryani_awadhi_veg_dum_pukht_indian', 'Biryani Awadhi Veg Dum Pukht (Lucknowi)', 182, 5.8, 28.8, 5.8, 2.8, 1.4, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;vegetarian dum pukht biryani Awadhi style kewra', ARRAY['awadhi_veg_biryani','lucknowi_vegetable_biryani'], true, NULL, 'rice', 320, 8, 1.8, 0, 240, 48, 1.8, 28, 4, 0, 28, 0.8, 118, 8.2, 0.08, 'North India', 'India'),
('dahi_kebab_lucknowi_awadhi_indian', 'Dahi Kebab Lucknowi (Yogurt Patty)', 198, 9.8, 14.2, 12.4, 1.4, 2.8, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;hung curd and paneer patty Awadhi specialty', ARRAY['yogurt_kebab_lucknowi','dahi_kabab_awadhi'], true, NULL, 'kebab', 360, 28, 5.8, 0, 188, 148, 0.8, 38, 2, 4, 18, 0.6, 142, 6.8, 0.06, 'North India', 'India'),
('sheermal_lucknowi_saffron_bread_indian', 'Sheermal Lucknowi Saffron Flatbread', 292, 7.6, 46.8, 9.8, 1.2, 8.2, 100, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi-style saffron milk enriched leavened flatbread', ARRAY['lucknowi_sheermal','sheermal_awadhi'], true, NULL, 'bread', 238, 30, 4.4, 0, 130, 64, 2.4, 18, 0, 4, 20, 0.8, 108, 8.4, 0.06, 'North India', 'India'),
('warqi_paratha_lucknowi_awadhi_indian', 'Warqi Paratha Lucknowi (Layered Mughlai)', 298, 7.8, 40.8, 12.8, 2.2, 1.2, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;puff-pastry style layered paratha Awadhi mughlai', ARRAY['warqi_paratha_awadhi','lucknowi_warqi_bread'], true, NULL, 'bread', 320, 22, 5.4, 0, 138, 30, 2.6, 4, 0, 0, 24, 0.8, 108, 7.8, 0.06, 'North India', 'India'),
('seekh_kebab_lucknowi_mutton_awadhi_indian', 'Seekh Kebab Lucknowi Mutton (Awadhi)', 278, 19.8, 5.4, 20.2, 0.6, 0.6, 50, 150, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi mutton seekh with mace and kewra', ARRAY['lucknowi_seekh_kebab','awadhi_seekh_mutton'], true, NULL, 'kebab', 560, 70, 8.4, 0, 272, 22, 2.6, 22, 0.6, 0, 21, 3.0, 180, 12.6, 0.22, 'North India', 'India'),
('biryani_awadhi_egg_lucknowi_indian', 'Biryani Awadhi Egg Lucknowi (Anda Biryani)', 188, 9.4, 24.2, 6.4, 0.8, 0.6, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi dum biryani with hard boiled eggs', ARRAY['anda_biryani_lucknowi','egg_awadhi_biryani'], true, NULL, 'rice', 360, 88, 2.2, 0, 248, 38, 1.8, 38, 2, 8, 24, 1.2, 148, 10.2, 0.10, 'North India', 'India'),
('malpua_lucknowi_awadhi_rabri_indian', 'Malpua Lucknowi with Rabri (Awadhi)', 342, 7.8, 52.4, 12.8, 0.6, 28.8, 60, 180, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi malpua pancake with saffron rabri topping', ARRAY['awadhi_malpua','lucknowi_malpua_sweet'], true, NULL, 'dessert', 88, 38, 6.8, 0, 148, 148, 0.8, 62, 0, 6, 16, 0.4, 118, 5.2, 0.06, 'North India', 'India'),
('biryani_awadhi_prawn_lucknowi_indian', 'Biryani Awadhi Prawn Lucknowi', 198, 14.2, 24.8, 5.4, 0.8, 0.6, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi dum biryani with prawns kewra saffron', ARRAY['jhinga_biryani_lucknowi','prawn_awadhi_biryani'], true, NULL, 'rice', 400, 82, 1.8, 0, 288, 82, 2.2, 28, 2, 0, 32, 1.8, 188, 14.8, 0.18, 'North India', 'India'),
('nihari_lucknowi_with_sheermal_indian', 'Nihari Lucknowi with Sheermal Set', 258, 16.4, 18.4, 14.8, 1.8, 3.2, NULL, 400, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi nihari served as set meal with sheermal bread', ARRAY['nihari_sheermal_set','lucknowi_nihari_set'], true, NULL, 'mutton_curry', 530, 82, 6.8, 0, 350, 58, 3.2, 18, 2, 4, 28, 2.8, 192, 14.2, 0.22, 'North India', 'India'),
('galouti_on_roomali_roti_lucknowi_indian', 'Galouti on Roomali Roti Lucknowi (Street)', 282, 14.8, 24.4, 14.8, 1.4, 1.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;galouti kebab served rolled in roomali roti street style', ARRAY['galouti_roomali_roll','lucknowi_galouti_wrap'], true, NULL, 'kebab', 500, 52, 5.8, 0, 258, 42, 2.2, 18, 2, 0, 22, 2.0, 162, 10.2, 0.14, 'North India', 'India'),
('litti_with_ghee_no_chokha_bihari_indian', 'Litti with Ghee Only (Bihari)', 348, 10.8, 46.2, 14.2, 5.2, 0.8, 80, 240, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;plain sattu litti rolled in ghee without chokha', ARRAY['litti_ghee_bihari','ghee_litti'], true, NULL, 'main_course', 380, 28, 6.4, 0, 360, 38, 3.4, 8, 4, 0, 44, 1.2, 138, 6.2, 0.10, 'North India', 'India'),
('bihari_kebab_mutton_skewer_up_indian', 'Bihari Kebab Mutton Skewer (UP/Bihar)', 268, 19.8, 7.4, 18.2, 1.0, 1.2, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;flat-pressed marinated mutton strips on skewer Bihari style', ARRAY['bihari_kabab_mutton','up_bihari_kebab'], true, NULL, 'kebab', 520, 72, 7.2, 0.1, 280, 28, 2.8, 18, 2, 0, 22, 2.8, 178, 12.4, 0.18, 'North India', 'India'),
('shahi_paneer_delhi_mughlai_indian', 'Shahi Paneer Delhi Mughlai Style', 248, 11.2, 9.8, 19.4, 1.2, 3.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rich Delhi mughlai paneer with cashew-cream gravy', ARRAY['mughlai_paneer_delhi','delhi_shahi_paneer'], true, NULL, 'paneer_curry', 420, 42, 8.8, 0, 248, 298, 1.2, 58, 4, 6, 28, 1.0, 218, 7.8, 0.08, 'North India', 'India'),
('mutton_biryani_old_delhi_style_indian', 'Mutton Biryani Old Delhi Karim Style', 228, 13.8, 26.4, 8.2, 1.4, 0.8, NULL, 350, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated;Old Delhi Mughlai mutton biryani cooked dum style', ARRAY['dilli_mutton_biryani','karim_biryani','old_delhi_biryani'], true, 'Karim''s Hotel (reference style)', 'rice', 450, 52, 3.2, 0, 290, 38, 2.4, 22, 2, 0, 32, 2.4, 172, 12.8, 0.14, 'North India', 'India'),
('aloo_chaat_chandni_chowk_delhi_indian', 'Aloo Chaat Chandni Chowk Delhi Style', 198, 4.4, 30.8, 7.8, 4.2, 4.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Old Delhi Chandni Chowk style tamarind potato chaat', ARRAY['chandni_chowk_chaat','delhi_aloo_chaat'], true, NULL, 'snack', 460, 0, 1.8, 0, 460, 28, 2.8, 8, 14, 0, 30, 0.8, 72, 4.2, 0.06, 'North India', 'India'),
('dahi_bhalla_delhi_up_indian', 'Dahi Bhalla Delhi/UP Style', 178, 7.8, 22.4, 6.4, 3.2, 8.2, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;soft urad dal vada soaked in yogurt with chutneys', ARRAY['dahi_vada_delhi','dahi_bada_up'], true, NULL, 'snack', 380, 14, 2.8, 0, 288, 108, 2.2, 18, 4, 2, 24, 0.8, 98, 4.8, 0.06, 'North India', 'India'),
('kachori_delhi_urad_dal_indian', 'Kachori Delhi Style Urad Dal', 368, 8.8, 44.8, 18.4, 4.2, 0.8, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;deep fried urad dal kachori Delhi breakfast style', ARRAY['dal_kachori_delhi','urad_kachori_delhi'], true, NULL, 'snack', 340, 0, 3.2, 0.4, 248, 28, 2.8, 4, 4, 0, 22, 0.6, 88, 4.4, 0.06, 'North India', 'India'),
('bajra_roti_haryanvi_pearl_millet_indian', 'Bajra Roti Haryanvi (Pearl Millet Flatbread)', 218, 7.2, 36.8, 5.4, 4.8, 0.8, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;Haryana pearl millet flatbread with ghee', ARRAY['haryana_bajra_roti','millet_roti_haryanvi'], true, NULL, 'bread', 180, 0, 0.8, 0, 210, 28, 3.8, 8, 2, 0, 62, 1.2, 128, 4.8, 0.08, 'North India', 'India'),
('chaas_haryanvi_buttermilk_indian', 'Chaas Haryanvi Buttermilk (Spiced)', 48, 2.4, 4.8, 1.6, 0, 3.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Haryanvi thin spiced buttermilk with cumin and ginger', ARRAY['mattha_haryanvi','spiced_chaas_haryana'], true, NULL, 'beverage', 280, 8, 0.8, 0, 148, 88, 0.2, 8, 0, 2, 12, 0.2, 62, 1.8, 0.04, 'North India', 'India'),
('singri_achar_haryanvi_pickle_indian', 'Singri Achar Haryanvi (Moth Pod Pickle)', 88, 3.4, 10.8, 4.2, 5.8, 1.8, NULL, 30, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dried moth bean pod pickle Haryana seasonal', ARRAY['singri_pickle_haryana','dried_moth_bean_pickle'], true, NULL, 'condiment', 1280, 0, 0.6, 0, 248, 38, 2.8, 8, 4, 0, 38, 0.8, 92, 3.2, 0.06, 'North India', 'India'),
('champaran_chicken_handi_bihari_indian', 'Champaran Chicken Handi (Bihari)', 218, 20.8, 5.2, 13.2, 0.8, 1.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Champaran-style sealed handi chicken Bihar', ARRAY['bihari_chicken_handi','ahuna_chicken_bihari'], true, NULL, 'chicken_curry', 450, 78, 4.8, 0, 355, 28, 2.2, 18, 2, 0, 26, 1.8, 185, 14.8, 0.16, 'North India', 'India'),
('paan_banarasi_meetha_up_indian', 'Paan Banarasi Meetha (Betel Leaf Sweet UP)', 48, 1.2, 8.4, 1.4, 2.8, 6.2, 15, 15, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Banarasi sweet betel leaf paan with gulkand', ARRAY['meetha_paan_banaras','banarasi_sweet_paan'], true, NULL, 'condiment', 22, 0, 0.4, 0, 88, 58, 0.8, 8, 4, 0, 14, 0.2, 18, 0.8, 0.02, 'North India', 'India'),
('imarti_up_jalebi_cousin_indian', 'Imarti UP Style (Urad Dal Sweet)', 362, 5.2, 60.4, 12.8, 0.8, 42.8, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;deep fried urad dal imarti in sugar syrup UP style', ARRAY['amriti_up','jhangri_up_variant'], true, NULL, 'dessert', 58, 0, 3.8, 0, 78, 28, 1.8, 0, 0, 0, 12, 0.4, 48, 2.8, 0.04, 'North India', 'India'),
('kheer_up_chawal_rice_pudding_indian', 'Kheer UP Chawal Rice Pudding', 168, 4.8, 26.8, 5.8, 0.2, 20.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;traditional UP rice kheer with cardamom saffron', ARRAY['chawal_ki_kheer_up','rice_pudding_up'], true, NULL, 'dessert', 68, 18, 3.2, 0, 158, 148, 0.4, 28, 0, 4, 14, 0.4, 112, 4.4, 0.04, 'North India', 'India'),
('suji_halwa_up_semolina_indian', 'Suji Halwa UP Semolina (Prasad Style)', 322, 5.4, 48.4, 12.8, 0.8, 24.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;semolina halwa with ghee dry fruits UP puja prasad', ARRAY['rava_halwa_up','suji_ka_halwa_up'], true, NULL, 'dessert', 42, 18, 6.4, 0, 88, 18, 1.2, 4, 0, 0, 18, 0.4, 58, 4.8, 0.06, 'North India', 'India'),
('bhang_ki_chutney_up_hemp_indian', 'Bhang Ki Chutney UP (Hemp Seed Chutney)', 92, 4.2, 6.8, 5.2, 2.8, 2.4, NULL, 30, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;traditional UP hemp seed chutney with spices', ARRAY['hemp_chutney_up','cannabis_seed_chutney_up'], true, NULL, 'condiment', 320, 0, 0.8, 0, 288, 48, 1.8, 8, 4, 0, 42, 0.8, 88, 2.8, 0.28, 'North India', 'India'),
('bhuna_gosht_delhi_up_indian', 'Bhuna Gosht Delhi/UP Style (Dry Mutton)', 248, 22.4, 5.2, 16.2, 1.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;dry-spiced roasted mutton Delhi street style', ARRAY['bhuna_mutton_delhi','roasted_gosht_up'], true, NULL, 'mutton_curry', 480, 82, 6.8, 0, 340, 28, 3.2, 22, 4, 0, 26, 3.0, 185, 14.8, 0.22, 'North India', 'India'),
('delhi_ke_aloo_chatpate_indian', 'Delhi Ke Aloo Chatpate Street Potatoes', 178, 3.2, 28.8, 6.4, 3.8, 2.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spiced chatpata potatoes Old Delhi street food', ARRAY['chatpate_aloo_delhi','delhi_spiced_potato'], true, NULL, 'snack', 420, 0, 1.2, 0, 480, 22, 2.2, 6, 14, 0, 28, 0.6, 68, 3.8, 0.04, 'North India', 'India'),
('parwal_ki_mithai_up_banarasi_indian', 'Parwal Ki Mithai UP Banarasi (Stuffed Gourd Sweet)', 298, 5.4, 46.8, 11.4, 2.2, 34.2, 30, 90, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;pointed gourd parwal stuffed with khoya sweet UP', ARRAY['parval_mithai_up','pointed_gourd_sweet_banaras'], true, NULL, 'dessert', 48, 22, 5.8, 0, 148, 88, 0.8, 12, 8, 0, 14, 0.4, 78, 3.8, 0.04, 'North India', 'India'),
('kalakand_up_mathura_style_indian', 'Kalakand UP Mathura Style (Milk Cake)', 348, 10.4, 46.8, 14.2, 0, 36.4, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;grainy cooked milk sweet Mathura UP style', ARRAY['milk_cake_up','mathura_kalakand'], true, NULL, 'dessert', 88, 38, 8.4, 0, 188, 298, 0.4, 38, 0, 4, 18, 0.4, 198, 5.8, 0.04, 'North India', 'India'),
('petha_agra_up_ash_gourd_sweet_indian', 'Petha Agra UP Ash Gourd Sweet', 298, 1.2, 72.4, 0.4, 1.8, 62.8, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;Agra-style white pumpkin/ash gourd candy', ARRAY['agra_petha','ash_gourd_petha_up'], true, NULL, 'dessert', 28, 0, 0.1, 0, 52, 18, 0.4, 2, 4, 0, 8, 0.2, 18, 0.8, 0.02, 'North India', 'India'),
('bihari_chana_sattu_roasted_flour_indian', 'Bihari Chana Sattu Roasted Flour', 388, 22.4, 56.8, 8.2, 8.4, 2.8, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;roasted black chickpea flour Bihari staple', ARRAY['sattu_chana','roasted_gram_flour_bihari','black_chana_sattu'], true, NULL, 'ingredient', 42, 0, 1.4, 0, 480, 48, 5.2, 8, 4, 0, 82, 2.4, 288, 8.8, 0.10, 'North India', 'India'),
('arhar_dal_up_tadka_indian', 'Arhar Dal UP Tadka (Pigeon Pea)', 148, 9.2, 20.4, 4.2, 5.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;toor dal with UP-style tadka ghee cumin tomato', ARRAY['toor_dal_up','pigeon_pea_dal_up'], true, NULL, 'lentil_curry', 380, 0, 1.2, 0, 360, 42, 2.8, 22, 8, 0, 48, 1.2, 148, 5.8, 0.08, 'North India', 'India'),
('dalmoth_delhi_haldirams_namkeen_indian', 'Dalmoth Delhi Haldiram Style Namkeen', 498, 18.4, 52.4, 24.8, 6.2, 1.2, NULL, 50, 1, 'manual_branded', 'hyperregional-apr2026;recipe-estimated;Haldiram-style Delhi dalmoth lentil snack mix', ARRAY['dal_moth_haldirams','dalmot_delhi'], true, 'Haldiram''s (reference style)', 'snack', 780, 0, 4.2, 0.4, 480, 42, 3.8, 8, 4, 0, 62, 1.8, 188, 8.8, 0.08, 'North India', 'India'),
('kadhi_haryanvi_sour_yogurt_indian', 'Kadhi Haryanvi Sour Yogurt (Haryana)', 138, 5.2, 14.8, 6.4, 1.6, 4.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;thin sour yogurt kadhi Haryana village style', ARRAY['haryana_kadhi','desi_kadhi_haryanvi'], true, NULL, 'vegetable_curry', 460, 14, 2.2, 0, 240, 138, 1.6, 38, 2, 4, 24, 0.8, 92, 4.4, 0.08, 'North India', 'India'),
('masala_chai_up_kadak_indian', 'Masala Chai UP Kadak Strong', 48, 1.2, 6.4, 1.8, 0.2, 5.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;strong spiced milk tea ginger cardamom UP roadside', ARRAY['kadak_chai_up','up_masala_tea'], true, NULL, 'beverage', 32, 8, 0.8, 0, 68, 52, 0.2, 8, 0, 0, 8, 0.2, 32, 0.8, 0.04, 'North India', 'India'),
('palak_paneer_lucknowi_awadhi_indian', 'Palak Paneer Lucknowi Awadhi Style', 178, 9.8, 7.4, 13.2, 3.4, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;spinach paneer Awadhi style with kewra hint', ARRAY['awadhi_palak_paneer','lucknowi_spinach_paneer'], true, NULL, 'paneer_curry', 380, 32, 6.2, 0, 440, 298, 3.8, 420, 28, 4, 42, 1.2, 188, 8.4, 0.12, 'North India', 'India'),
('aloo_dum_lucknowi_awadhi_small_potato_indian', 'Aloo Dum Lucknowi Awadhi Small Potato', 138, 3.2, 18.4, 5.8, 3.4, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;small potatoes in Awadhi dum style with spices', ARRAY['lucknowi_dum_aloo','awadhi_aloo_dum'], true, NULL, 'vegetable_curry', 360, 0, 1.8, 0, 480, 42, 2.0, 14, 8, 0, 30, 0.8, 78, 4.0, 0.08, 'North India', 'India'),
('gulab_jamun_up_khoya_classic_indian', 'Gulab Jamun UP Khoya Classic', 368, 6.8, 56.2, 13.8, 0.4, 44.2, 30, 90, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;khoya-based gulab jamun UP-style in sugar syrup', ARRAY['khoya_gulab_jamun_up','mawa_gulab_jamun_up'], true, NULL, 'dessert', 68, 22, 7.8, 0, 128, 102, 0.8, 18, 0, 2, 14, 0.4, 88, 4.8, 0.04, 'North India', 'India'),
('paneer_pasanda_delhi_mughlai_indian', 'Paneer Pasanda Delhi Mughlai Style', 268, 12.4, 10.8, 20.2, 1.4, 3.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;flat paneer escalopes stuffed fried in mughlai gravy Delhi', ARRAY['mughlai_paneer_pasanda','delhi_paneer_pasanda'], true, NULL, 'paneer_curry', 400, 42, 9.8, 0, 248, 318, 1.2, 52, 4, 4, 28, 1.0, 218, 8.0, 0.08, 'North India', 'India'),
('moong_dal_halwa_up_indian', 'Moong Dal Halwa UP Winter Dessert', 368, 8.8, 48.2, 17.2, 2.8, 28.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;slow-cooked moong dal with ghee and sugar UP style', ARRAY['moong_halwa_up','mung_dal_halwa_up'], true, NULL, 'dessert', 52, 28, 8.8, 0, 248, 52, 2.8, 8, 4, 0, 48, 1.2, 148, 6.2, 0.08, 'North India', 'India'),
('puri_sabzi_up_breakfast_indian', 'Puri Sabzi UP Breakfast Style', 298, 6.8, 36.4, 14.2, 3.8, 1.8, 40, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;deep fried puri with aloo sabzi UP roadside breakfast', ARRAY['puri_aloo_up','up_style_puri_sabzi'], true, NULL, 'main_course', 380, 0, 2.8, 0.2, 380, 28, 2.4, 12, 12, 0, 28, 0.6, 78, 4.4, 0.06, 'North India', 'India'),
('punjabi_mutton_curry_desi_indian', 'Punjabi Mutton Curry Desi Style', 222, 19.8, 6.4, 13.8, 1.6, 1.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;rustic Punjabi mutton curry with whole spices', ARRAY['desi_mutton_curry_punjabi','gosht_curry_punjabi'], true, NULL, 'mutton_curry', 500, 82, 5.8, 0, 360, 32, 3.0, 22, 4, 0, 26, 3.0, 188, 14.8, 0.22, 'North India', 'India'),
('amritsari_kulcha_onion_punjabi_indian', 'Amritsari Kulcha Onion (Punjabi)', 262, 7.6, 41.0, 8.8, 2.0, 2.2, 115, 115, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Amritsari kulcha stuffed with spiced caramelised onion', ARRAY['onion_kulcha_amritsari','pyaz_kulcha_amritsari'], true, NULL, 'bread', 345, 0, 1.8, 0, 155, 52, 2.4, 4, 4, 0, 21, 0.7, 94, 6.2, 0.05, 'North India', 'India'),
('punjabi_saag_gosht_mustard_mutton_indian', 'Punjabi Saag Gosht Mustard Mutton', 198, 17.4, 7.8, 11.4, 3.0, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;mutton cooked in sarson/mustard green base', ARRAY['saag_mutton_punjabi','gosht_sarson_punjabi'], true, NULL, 'mutton_curry', 460, 72, 4.8, 0, 420, 102, 3.2, 320, 26, 0, 34, 2.6, 182, 13.4, 0.18, 'North India', 'India'),
('kashmiri_lamb_ribs_tabak_variant_indian', 'Kashmiri Lamb Ribs Tabak Light Fried', 298, 21.8, 3.8, 22.2, 0.2, 0.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;lighter shallow-fried Kashmiri lamb rib variant', ARRAY['kashmiri_light_tabak','tabak_maaz_shallow'], true, NULL, 'mutton', 440, 92, 9.2, 0.1, 272, 26, 2.0, 10, 0, 0, 20, 2.6, 182, 14.0, 0.22, 'North India', 'India'),
('kashmiri_roghan_gosht_dry_spice_indian', 'Kashmiri Roghan Gosht Dry Spiced', 218, 18.6, 5.4, 14.0, 0.8, 1.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;drier version of rogan josh Kashmiri with reduced gravy', ARRAY['dry_rogan_josh','kashmiri_bhuna_gosht'], true, NULL, 'mutton_curry', 445, 76, 6.0, 0, 328, 28, 2.8, 40, 3, 0, 24, 2.9, 185, 12.6, 0.20, 'North India', 'India'),
('lucknowi_kulfi_pista_kesar_indian', 'Lucknowi Kulfi Pista Kesar (Lucknow)', 218, 6.4, 22.8, 12.4, 0.4, 18.8, 80, 80, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknow-style pistachio saffron kulfi on stick', ARRAY['pista_kesar_kulfi_lucknow','lucknowi_pistachio_kulfi'], true, NULL, 'dessert', 72, 28, 6.8, 0, 218, 188, 0.4, 28, 0, 4, 18, 0.6, 148, 5.8, 0.06, 'North India', 'India'),
('lucknowi_kesar_badam_kheer_indian', 'Lucknowi Kesar Badam Kheer (Almond Saffron)', 198, 6.8, 26.4, 9.2, 0.8, 22.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Lucknowi saffron almond milk kheer with rose water', ARRAY['almond_saffron_kheer_lucknow','kesar_badam_kheer_awadhi'], true, NULL, 'dessert', 78, 24, 4.8, 0, 188, 168, 0.6, 32, 0, 4, 18, 0.6, 148, 5.2, 0.06, 'North India', 'India'),
('awadhi_gosht_aloo_curry_indian', 'Awadhi Gosht Aloo Curry (Mutton Potato)', 218, 16.8, 10.4, 13.2, 2.2, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Awadhi style mutton with potato in thick gravy', ARRAY['gosht_aloo_awadhi','mutton_potato_lucknowi'], true, NULL, 'mutton_curry', 470, 72, 5.6, 0, 390, 36, 3.0, 18, 6, 0, 26, 2.6, 178, 13.2, 0.18, 'North India', 'India'),
('bihari_chuda_dahi_flattened_rice_indian', 'Bihari Chuda Dahi Poha Curd (Bihar)', 178, 5.8, 32.4, 3.8, 1.8, 4.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;flattened rice soaked in curd Bihar style', ARRAY['chiwda_dahi_bihari','poha_dahi_bihar'], true, NULL, 'snack', 188, 12, 1.6, 0, 188, 108, 1.8, 12, 2, 2, 24, 0.8, 82, 4.0, 0.04, 'North India', 'India'),
('tilkut_magahi_bihari_sesame_sweet_indian', 'Tilkut Magahi Bihari Sesame Sweet', 478, 10.2, 56.4, 26.4, 4.8, 38.4, 30, 90, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Gaya Magahi-style sesame and jaggery sweet Bihar', ARRAY['magahi_tilkut','gaya_tilkut_bihari'], true, NULL, 'dessert', 42, 0, 4.8, 0, 248, 288, 3.8, 4, 0, 0, 82, 2.2, 188, 8.2, 0.12, 'North India', 'India'),
('aloo_chokha_bihari_roasted_potato_indian', 'Aloo Chokha Bihari Roasted Potato Mash', 98, 2.4, 18.8, 2.4, 2.8, 1.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;roasted mashed potato with mustard oil and chilli', ARRAY['bihari_aloo_chokha','roasted_potato_mash_bihari'], true, NULL, 'side_dish', 280, 0, 0.4, 0, 480, 18, 1.8, 6, 16, 0, 30, 0.6, 62, 2.8, 0.06, 'North India', 'India'),
('baingan_chokha_bihari_roasted_eggplant_indian', 'Baingan Chokha Bihari Roasted Eggplant', 78, 2.2, 10.4, 3.2, 3.8, 3.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR;roasted eggplant mash with mustard oil chilli Bihar', ARRAY['bihari_baingan_chokha','roasted_brinjal_bihar'], true, NULL, 'side_dish', 260, 0, 0.4, 0, 368, 18, 0.8, 8, 8, 0, 22, 0.4, 42, 1.8, 0.06, 'North India', 'India'),
('khichdi_up_arhar_dal_rice_indian', 'Khichdi UP Arhar Dal Rice (Pigeon Pea)', 148, 7.2, 24.8, 3.2, 4.4, 0.6, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN;UP-style toor dal rice khichdi with ghee tadka', ARRAY['toor_dal_khichdi_up','arhar_khichdi_up'], true, NULL, 'main_course', 280, 8, 1.2, 0, 320, 38, 2.8, 22, 8, 0, 48, 1.2, 138, 5.8, 0.08, 'North India', 'India'),
('old_delhi_sewaiyan_meethi_indian', 'Old Delhi Sewaiyan Meethi (Vermicelli Sweet)', 348, 8.4, 56.2, 12.4, 1.2, 28.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Old Delhi Eid-style sweet vermicelli with khoya dry fruits', ARRAY['meethi_sewaiyan_delhi','eid_sewain_delhi'], true, NULL, 'dessert', 68, 22, 6.8, 0, 148, 128, 1.4, 22, 0, 2, 18, 0.6, 118, 5.2, 0.06, 'North India', 'India'),
('udupi_masala_dosa_indian', 'Udupi Masala Dosa', 162, 4.8, 26.8, 5.2, 1.8, 1.2, 120, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Udupi-hotel-cuisine', ARRAY['udupi_masala_dose','udupi_hotel_masala_dosa'], true, NULL, 'breakfast_dish', 328, 4, 0.8, 0.0, 188, 38, 1.2, 18, 5.8, 0, 22, 0.6, 88, 4.2, 0.04, 'South India', 'India'),
('udupi_brahmin_sambar_indian', 'Udupi Brahmin Sambar', 78, 4.2, 9.4, 2.4, 3.2, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Udupi-cuisine-reference', ARRAY['udupi_sambar_coconut','udupi_brahmin_saaru','satvic_sambar_udupi'], true, NULL, 'soup', 368, 0, 0.6, 0.0, 288, 58, 1.8, 18, 4.8, 0, 32, 0.4, 78, 3.8, 0.04, 'South India', 'India'),
('karnataka_saaru_indian', 'Karnataka Saaru', 38, 1.8, 4.8, 1.2, 1.2, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rasam-reference', ARRAY['karnataka_rasam','mysore_saaru','pepper_saaru_karnataka'], true, NULL, 'soup', 388, 0, 0.2, 0.0, 188, 28, 0.8, 28, 4.8, 0, 18, 0.2, 38, 1.8, 0.02, 'South India', 'India'),
('mangalore_biryani_indian', 'Mangalore Chicken Biryani', 186, 9.8, 22.4, 6.4, 1.2, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-cuisine', ARRAY['mangalorean_biryani','tulu_chicken_biryani','coastal_karnataka_biryani'], true, NULL, 'rice_dish', 428, 42, 2.0, 0.0, 168, 28, 1.4, 36, 2.0, 0, 22, 1.0, 142, 8.8, 0.12, 'South India', 'India'),
('karnataka_veg_pulao_indian', 'Karnataka Veg Pulao', 168, 4.4, 28.8, 4.8, 1.8, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['karnataka_pulav','veg_pulao_karnataka'], true, NULL, 'rice_dish', 328, 0, 0.8, 0.0, 198, 32, 1.2, 28, 3.8, 0, 24, 0.5, 88, 3.8, 0.04, 'South India', 'India'),
('coorg_bamboo_shoot_curry_indian', 'Coorg Bamboo Shoot Curry', 88, 4.8, 8.4, 4.2, 3.8, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coorg-Kodagu-cuisine', ARRAY['kodava_bamboo_curry','bonth_curry_coorg','coorg_bamboo_curry'], true, NULL, 'vegetable_curry', 388, 0, 0.8, 0.0, 348, 58, 1.4, 18, 4.8, 0, 34, 0.6, 78, 2.8, 0.04, 'South India', 'India'),
('coorg_chicken_curry_noolputtu_indian', 'Coorg Chicken with Noolputtu', 192, 12.4, 18.4, 7.8, 1.4, 0.8, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coorg-Kodagu-cuisine', ARRAY['noolputtu_chicken','coorg_string_hopper_chicken','kodava_noolputtu'], true, NULL, 'main_course', 448, 58, 2.4, 0.0, 268, 42, 1.6, 38, 2.4, 0, 26, 1.2, 162, 9.8, 0.14, 'South India', 'India'),
('maddur_vada_karnataka_indian', 'Maddur Vada', 312, 7.8, 34.8, 15.4, 2.8, 1.8, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-snack-reference', ARRAY['maddur_wade','maddur_vade','karnataka_maddur_vada'], true, NULL, 'snack', 368, 0, 2.4, 0.1, 148, 32, 2.2, 8, 2.4, 0, 22, 0.6, 98, 4.8, 0.04, 'South India', 'India'),
('karnataka_set_dosa_indian', 'Karnataka Set Dosa', 152, 4.2, 26.4, 3.8, 1.4, 0.6, 60, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['set_dose_karnataka','set_dosa_karnataka'], true, NULL, 'breakfast_dish', 268, 0, 0.6, 0.0, 88, 22, 0.8, 0, 0.0, 0, 14, 0.3, 58, 2.8, 0.02, 'South India', 'India'),
('karnataka_set_dosa_saagu_indian', 'Karnataka Set Dosa with Saagu', 162, 5.8, 26.4, 4.8, 2.4, 1.2, NULL, 220, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['set_dose_saagu','set_dosa_with_saagu'], true, NULL, 'breakfast_dish', 348, 2, 0.8, 0.0, 198, 52, 1.4, 28, 4.2, 0, 24, 0.5, 82, 3.8, 0.06, 'South India', 'India'),
('chettinad_egg_curry_indian', 'Chettinad Egg Curry', 172, 9.8, 7.8, 11.2, 1.4, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_muttai_curry','chettinad_anda_curry'], true, NULL, 'egg_dish', 488, 228, 3.4, 0.0, 288, 68, 1.6, 88, 4.2, 8, 24, 1.0, 168, 12.4, 0.14, 'South India', 'India'),
('chettinad_paneer_kuzhambu_indian', 'Chettinad Paneer Kuzhambu', 188, 9.4, 9.4, 13.2, 1.6, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_paneer_curry','paneer_kuzhambu_chettinad'], true, NULL, 'vegetarian_curry', 448, 38, 5.8, 0.0, 248, 128, 1.2, 88, 3.8, 0, 22, 0.8, 148, 6.8, 0.08, 'South India', 'India'),
('tamilnadu_chicken_65_indian', 'Tamil Nadu Chicken 65', 262, 20.4, 12.4, 14.8, 1.2, 1.8, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-starter', ARRAY['chicken_65_tamilnadu','chicken_sixty_five_tamil'], true, NULL, 'chicken_dish', 588, 82, 3.4, 0.0, 318, 42, 1.4, 58, 3.8, 0, 24, 1.4, 188, 12.8, 0.12, 'South India', 'India'),
('keerai_kootu_tamilnadu_indian', 'Tamil Nadu Keerai Kootu', 108, 6.4, 10.8, 4.2, 4.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['spinach_kootu','murungai_keerai_kootu','keerai_kootu'], true, NULL, 'vegetable_curry', 288, 0, 0.6, 0.0, 388, 148, 3.4, 248, 12.4, 0, 48, 0.8, 98, 4.8, 0.06, 'South India', 'India'),
('murungai_sambar_tamilnadu_indian', 'Tamil Nadu Murungai Sambar', 88, 4.8, 10.8, 2.8, 3.4, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sambar-variants', ARRAY['drumstick_sambar','murungakkai_sambar','murungai_sambar'], true, NULL, 'soup', 428, 2, 0.6, 0.0, 328, 68, 1.8, 48, 18.4, 0, 38, 0.6, 88, 4.2, 0.06, 'South India', 'India'),
('vengaya_sambar_tamilnadu_indian', 'Tamil Nadu Vengaya Sambar', 82, 4.4, 10.4, 2.4, 3.0, 3.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sambar-variants', ARRAY['pearl_onion_sambar','chinna_vengaya_sambar','shallot_sambar'], true, NULL, 'soup', 408, 0, 0.4, 0.0, 298, 52, 1.6, 38, 8.4, 0, 28, 0.4, 78, 3.6, 0.04, 'South India', 'India'),
('tamilnadu_rasam_indian', 'Tamil Nadu Rasam', 32, 1.4, 4.4, 0.8, 1.0, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rasam-reference', ARRAY['rasam_tamilnadu','pepper_rasam_tamil','milagu_rasam'], true, NULL, 'soup', 368, 0, 0.2, 0.0, 168, 22, 0.6, 22, 4.8, 0, 14, 0.2, 32, 1.4, 0.02, 'South India', 'India'),
('tomato_rasam_tamilnadu_indian', 'Tamil Nadu Tomato Rasam', 38, 1.6, 5.4, 1.0, 1.2, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rasam-reference', ARRAY['thakkali_rasam','tomato_rasam_tamil','tamatar_rasam_tamilnadu'], true, NULL, 'soup', 348, 0, 0.2, 0.0, 228, 28, 0.6, 48, 8.4, 0, 14, 0.2, 38, 1.6, 0.02, 'South India', 'India'),
('kara_kuzhambu_tamilnadu_indian', 'Tamil Nadu Kara Kuzhambu', 98, 3.8, 8.8, 5.4, 2.4, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-curry', ARRAY['kara_kulambu','kari_kuzhambu','spicy_tamarind_kuzhambu'], true, NULL, 'curry', 528, 0, 0.8, 0.0, 298, 52, 1.6, 38, 4.8, 0, 28, 0.4, 68, 3.2, 0.06, 'South India', 'India'),
('mor_kuzhambu_tamilnadu_indian', 'Tamil Nadu Mor Kuzhambu', 68, 3.2, 6.4, 3.2, 1.2, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-curry', ARRAY['mor_kulambu','buttermilk_curry_tamilnadu','majjiga_pulusu_style'], true, NULL, 'curry', 368, 8, 1.4, 0.0, 178, 88, 0.4, 18, 1.8, 0, 14, 0.4, 78, 2.4, 0.02, 'South India', 'India'),
('beans_poriyal_tamilnadu_indian', 'Tamil Nadu Beans Poriyal', 88, 3.4, 10.4, 4.0, 4.4, 2.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['beans_poriyal','green_beans_stir_fry_tamilnadu','french_beans_poriyal'], true, NULL, 'vegetable_dish', 248, 0, 0.6, 0.0, 248, 42, 1.4, 28, 6.4, 0, 28, 0.4, 62, 2.8, 0.04, 'South India', 'India'),
('cabbage_poriyal_tamilnadu_indian', 'Tamil Nadu Cabbage Poriyal', 78, 2.8, 8.4, 3.8, 3.2, 3.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['muttaikose_poriyal','cabbage_stir_fry_tamilnadu'], true, NULL, 'vegetable_dish', 228, 0, 0.6, 0.0, 228, 48, 0.6, 8, 22.4, 0, 18, 0.3, 42, 1.8, 0.04, 'South India', 'India'),
('vanjaram_fish_fry_indian', 'Vanjaram Fish Fry', 228, 22.8, 6.4, 12.4, 0.6, 0.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['seer_fish_fry','king_fish_fry_tamilnadu','vanjaram_varuval'], true, NULL, 'seafood_dish', 588, 78, 2.8, 0.0, 428, 42, 1.4, 38, 2.4, 0, 38, 1.2, 248, 18.4, 0.28, 'South India', 'India'),
('karuvadu_kuzhambu_indian', 'Karuvadu Kuzhambu', 148, 18.4, 6.8, 5.8, 1.8, 1.2, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['dried_fish_curry','karuvadu_kulambu','salted_fish_kuzhambu'], true, NULL, 'seafood_dish', 1248, 68, 1.4, 0.0, 388, 128, 2.4, 28, 3.8, 0, 34, 0.8, 188, 14.8, 0.34, 'South India', 'India'),
('eral_masala_tamilnadu_indian', 'Tamil Nadu Eral Masala', 182, 16.8, 7.4, 9.8, 1.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['prawn_masala_tamilnadu','eral_thokku','tamilnadu_eral_curry'], true, NULL, 'seafood_dish', 568, 138, 2.4, 0.0, 358, 78, 1.4, 48, 4.8, 0, 34, 1.2, 228, 16.4, 0.26, 'South India', 'India'),
('paal_kozhukattai_kongunadu_indian', 'Kongunadu Paal Kozhukattai', 198, 4.2, 34.8, 5.4, 0.8, 18.4, 30, 180, 6, 'manual', 'hyperregional-apr2026;recipe-estimated;Kongunadu-sweets', ARRAY['paal_kozhukattai','milk_rice_dumpling_kongunadu','sweet_kozhukattai'], true, NULL, 'sweet', 48, 12, 2.8, 0.0, 128, 68, 0.4, 8, 0.4, 0, 12, 0.3, 68, 2.4, 0.02, 'South India', 'India'),
('kozhukattai_savory_tamilnadu_indian', 'Tamil Nadu Savory Kozhukattai', 162, 4.4, 26.8, 4.8, 2.2, 0.6, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['savory_kozhukattai','kaara_kozhukattai','spicy_modak_tamilnadu'], true, NULL, 'breakfast_dish', 288, 0, 0.8, 0.0, 128, 22, 0.8, 8, 1.2, 0, 18, 0.3, 62, 2.4, 0.04, 'South India', 'India'),
('ven_pongal_tamilnadu_indian', 'Tamil Nadu Ven Pongal', 178, 6.4, 26.8, 5.4, 1.8, 0.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['ven_pongal','khara_pongal_tamilnadu','savoury_pongal_tamilnadu'], true, NULL, 'breakfast_dish', 348, 4, 1.8, 0.0, 148, 28, 1.4, 8, 0.4, 0, 22, 0.6, 98, 4.8, 0.04, 'South India', 'India'),
('sakkarai_pongal_tamilnadu_indian', 'Tamil Nadu Sakkarai Pongal', 248, 5.8, 38.8, 8.4, 1.4, 22.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-festival', ARRAY['sakkarai_pongal','sweet_pongal_tamilnadu','chakkarai_pongal'], true, NULL, 'sweet', 28, 14, 4.2, 0.0, 128, 38, 1.4, 12, 0.2, 0, 22, 0.5, 88, 3.8, 0.04, 'South India', 'India'),
('uppu_kozhukattai_tamilnadu_indian', 'Tamil Nadu Uppu Kozhukattai', 148, 3.2, 24.8, 4.2, 1.4, 0.4, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['uppu_kozhukattai','salt_modak_tamilnadu'], true, NULL, 'breakfast_dish', 268, 0, 0.8, 0.0, 88, 14, 0.6, 0, 0.0, 0, 12, 0.2, 48, 1.8, 0.02, 'South India', 'India'),
('karnataka_paddu_indian', 'Karnataka Paddu', 148, 4.2, 24.8, 3.8, 1.4, 0.6, 20, 120, 6, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['paddu','guliyappa','paniyaram_karnataka','yeriyappa'], true, NULL, 'breakfast_dish', 278, 0, 0.6, 0.0, 88, 22, 0.8, 0, 0.2, 0, 14, 0.3, 58, 2.8, 0.02, 'South India', 'India'),
('karnataka_paddu_chutney_indian', 'Karnataka Paddu with Coconut Chutney', 172, 4.4, 23.8, 6.2, 1.8, 1.4, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['paddu_coconut_chutney','guliyappa_chutney'], true, NULL, 'breakfast_dish', 288, 0, 2.8, 0.0, 148, 28, 0.8, 0, 1.2, 0, 16, 0.3, 62, 2.8, 0.04, 'South India', 'India'),
('rava_idli_karnataka_indian', 'Karnataka Rava Idli', 152, 4.8, 22.4, 5.2, 1.8, 1.4, 60, 180, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-MTR-breakfast', ARRAY['rava_idly','semolina_idli_karnataka','MTR_rava_idli'], true, NULL, 'breakfast_dish', 368, 0, 0.8, 0.0, 108, 28, 1.2, 12, 1.4, 0, 18, 0.4, 78, 3.8, 0.04, 'South India', 'India'),
('rava_idli_with_sambar_indian', 'Karnataka Rava Idli with Sambar', 162, 6.4, 22.8, 5.4, 2.8, 1.6, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-MTR-breakfast', ARRAY['rava_idli_sambar','semolina_idli_sambar'], true, NULL, 'breakfast_dish', 448, 2, 0.8, 0.0, 218, 56, 1.8, 22, 3.4, 0, 26, 0.5, 98, 4.8, 0.06, 'South India', 'India'),
('shavige_bath_karnataka_indian', 'Karnataka Shavige Bath', 158, 4.2, 26.8, 4.4, 1.2, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['shavige_baath','vermicelli_upma_karnataka','semiya_bath_karnataka'], true, NULL, 'breakfast_dish', 328, 0, 0.6, 0.0, 128, 18, 1.2, 8, 1.8, 0, 14, 0.3, 58, 2.8, 0.04, 'South India', 'India'),
('akki_shavige_karnataka_indian', 'Karnataka Akki Shavige', 178, 3.4, 32.8, 4.2, 0.8, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['akki_shavige','rice_vermicelli_karnataka','rice_noodle_karnataka'], true, NULL, 'breakfast_dish', 268, 0, 0.6, 0.0, 88, 8, 0.4, 0, 0.0, 0, 8, 0.2, 42, 1.8, 0.02, 'South India', 'India'),
('karnataka_puliyogare_indian', 'Karnataka Puliyogare', 182, 3.8, 28.4, 6.8, 2.8, 2.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['puliyogare_karnataka','tamarind_rice_karnataka','huli_anna'], true, NULL, 'rice_dish', 568, 0, 1.0, 0.0, 238, 28, 2.4, 12, 3.2, 0, 26, 0.6, 92, 4.4, 0.06, 'South India', 'India'),
('vangi_bath_karnataka_indian', 'Karnataka Vangi Bath', 168, 3.8, 26.8, 5.4, 2.8, 2.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['vangi_baath','brinjal_rice_karnataka','baingan_rice_karnataka'], true, NULL, 'rice_dish', 348, 0, 0.8, 0.0, 248, 32, 1.4, 18, 3.8, 0, 22, 0.4, 78, 3.8, 0.06, 'South India', 'India'),
('palak_thovve_karnataka_indian', 'Karnataka Palak Thovve', 98, 5.8, 10.4, 3.2, 4.2, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-dal-reference', ARRAY['palak_tovve','spinach_dal_karnataka','soppu_thovve'], true, NULL, 'dal', 288, 0, 0.6, 0.0, 388, 98, 2.8, 188, 14.4, 0, 44, 0.6, 88, 4.2, 0.06, 'South India', 'India'),
('hesaru_kalu_palya_karnataka_indian', 'Karnataka Hesaru Kalu Palya', 118, 8.4, 12.8, 4.2, 4.8, 1.6, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-vegetarian', ARRAY['moong_sprout_palya','hesarukalu_palya','green_moong_stir_fry_karnataka'], true, NULL, 'vegetable_dish', 228, 0, 0.6, 0.0, 368, 42, 2.4, 18, 3.8, 0, 42, 0.8, 98, 3.8, 0.06, 'South India', 'India'),
('paal_payasam_tamilnadu_indian', 'Tamil Nadu Paal Payasam', 168, 4.8, 28.4, 4.2, 0.2, 22.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sweet', ARRAY['paal_payasam','milk_payasam_tamilnadu','rice_milk_kheer_tamilnadu'], true, NULL, 'sweet', 68, 18, 2.4, 0.0, 178, 148, 0.4, 28, 0.4, 0, 14, 0.4, 98, 2.4, 0.04, 'South India', 'India'),
('semiya_payasam_tamilnadu_indian', 'Tamil Nadu Semiya Payasam', 188, 4.4, 30.8, 5.8, 0.6, 22.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sweet', ARRAY['semiya_kheer','vermicelli_payasam_tamilnadu','sheer_khurma_style'], true, NULL, 'sweet', 72, 18, 3.4, 0.0, 148, 128, 0.4, 22, 0.4, 0, 12, 0.3, 82, 2.4, 0.04, 'South India', 'India'),
('kesari_tamilnadu_indian', 'Tamil Nadu Kesari', 298, 4.4, 42.4, 12.8, 0.8, 28.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sweet', ARRAY['rava_kesari','sooji_kesari_tamilnadu','tamilnadu_sheera'], true, NULL, 'sweet', 28, 28, 6.8, 0.0, 68, 18, 0.6, 8, 0.2, 0, 8, 0.2, 42, 2.4, 0.04, 'South India', 'India'),
('tirunelveli_halwa_indian', 'Tirunelveli Wheat Halwa', 378, 3.8, 62.4, 14.8, 1.2, 48.4, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tirunelveli-sweet-reference', ARRAY['tirunelveli_wheat_halwa','goduma_halwa_tirunelveli','gothambu_halwa'], true, NULL, 'sweet', 28, 18, 7.4, 0.0, 88, 18, 1.8, 8, 0.4, 0, 18, 0.4, 68, 3.4, 0.04, 'South India', 'India'),
('madurai_kari_dosa_indian', 'Madurai Kari Dosa', 198, 10.4, 22.4, 8.2, 1.4, 0.8, 140, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Madurai-street-food', ARRAY['kari_dosa_madurai','meat_dosa_madurai','mutton_dosa_madurai'], true, NULL, 'street_food', 428, 48, 2.8, 0.0, 248, 38, 1.8, 42, 2.4, 0, 22, 1.2, 158, 9.8, 0.14, 'South India', 'India'),
('paruthi_paal_tamilnadu_indian', 'Paruthi Paal', 128, 3.8, 18.4, 5.2, 1.2, 12.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-traditional-drink', ARRAY['cotton_seed_milk','paruthi_pal','parutti_paal'], true, NULL, 'beverage', 28, 0, 0.8, 0.0, 168, 48, 1.2, 0, 0.4, 0, 22, 0.4, 88, 2.4, 0.06, 'South India', 'India'),
('sol_kadhi_karnataka_indian', 'Mangalore Sol Kadhi', 68, 0.8, 5.8, 4.4, 0.8, 3.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-beverage', ARRAY['solkadhi_mangalore','kokum_coconut_milk_drink','kokum_kadhi_karnataka'], true, NULL, 'beverage', 128, 0, 3.8, 0.0, 128, 18, 0.4, 0, 3.4, 0, 12, 0.3, 42, 1.4, 0.06, 'South India', 'India'),
('ragi_kanji_karnataka_indian', 'Ragi Kanji', 88, 2.8, 15.8, 1.4, 2.4, 0.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-ragi-data', ARRAY['ragi_porridge','finger_millet_kanji','ragi_ambali'], true, NULL, 'breakfast_dish', 28, 0, 0.2, 0.0, 128, 68, 1.6, 4, 0.0, 0, 28, 0.4, 78, 2.4, 0.02, 'South India', 'India'),
('puli_inji_tamilnadu_indian', 'Tamil Nadu Puli Inji', 118, 1.2, 22.8, 2.8, 2.4, 14.4, NULL, 30, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['puli_inji_chutney','tamarind_ginger_preserve','inji_puli_tamilnadu'], true, NULL, 'condiment', 448, 0, 0.4, 0.0, 248, 38, 2.4, 8, 2.8, 0, 18, 0.4, 38, 1.8, 0.04, 'South India', 'India'),
('thambuli_karnataka_indian', 'Karnataka Thambuli', 88, 2.8, 6.4, 6.2, 1.8, 2.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-Udupi-condiment', ARRAY['thambli','tambuli_karnataka','karnataka_coconut_buttermilk'], true, NULL, 'condiment', 148, 8, 3.8, 0.0, 168, 58, 0.6, 8, 2.4, 0, 14, 0.3, 68, 1.8, 0.06, 'South India', 'India'),
('mosaru_bajji_karnataka_indian', 'Karnataka Mosaru Bajji', 248, 5.8, 28.4, 12.4, 1.2, 2.8, 30, 120, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-snack-reference', ARRAY['curd_bajji_karnataka','mosarubajji','yogurt_fritter_karnataka'], true, NULL, 'snack', 368, 18, 2.4, 0.1, 88, 48, 1.2, 8, 0.4, 0, 16, 0.4, 68, 3.8, 0.04, 'South India', 'India'),
('mangalore_buns_indian', 'Mangalore Buns', 298, 6.4, 44.8, 10.8, 1.8, 12.4, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['mangalorean_banana_buns','banana_poori_mangalore','buns_mangalore'], true, NULL, 'breakfast_dish', 188, 0, 2.4, 0.0, 188, 22, 1.4, 8, 3.8, 0, 22, 0.4, 72, 3.4, 0.04, 'South India', 'India'),
('mangalore_buns_chutney_indian', 'Mangalore Buns with Coconut Chutney', 308, 6.4, 44.2, 12.8, 2.2, 12.0, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['mangalorean_buns_chutney','banana_buns_coconut_chutney'], true, NULL, 'breakfast_dish', 218, 0, 5.2, 0.0, 218, 28, 1.4, 8, 4.2, 0, 22, 0.4, 76, 3.4, 0.06, 'South India', 'India'),
('karwar_prawn_curry_indian', 'Karwar Prawn Curry', 182, 14.8, 7.8, 10.4, 1.4, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-cuisine', ARRAY['karwar_eral_curry','north_karnataka_prawn_curry','uttara_kannada_prawn'], true, NULL, 'seafood_dish', 588, 128, 4.2, 0.0, 338, 78, 1.2, 42, 3.8, 0, 34, 1.0, 218, 16.2, 0.26, 'South India', 'India'),
('tisrya_sukka_karnataka_indian', 'Karwar Tisrya Sukka', 148, 12.8, 7.4, 7.8, 1.2, 0.8, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-cuisine', ARRAY['clam_sukka_karnataka','tisryo_dry_fry','karwar_clam'], true, NULL, 'seafood_dish', 548, 68, 2.4, 0.0, 298, 88, 3.8, 38, 3.4, 0, 28, 1.2, 198, 16.8, 0.28, 'South India', 'India'),
('ragi_sangati_karnataka_indian', 'Karnataka Ragi Sangati', 122, 3.2, 22.4, 1.8, 3.0, 0.4, 180, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-ragi-data', ARRAY['ragi_sangati','ragi_mudde_sangati','finger_millet_lump_karnataka'], true, NULL, 'staple', 12, 0, 0.3, 0.0, 192, 98, 2.4, 4, 0.0, 0, 42, 0.6, 118, 3.2, 0.02, 'South India', 'India'),
('soppina_saaru_karnataka_indian', 'Karnataka Soppina Saaru', 42, 2.4, 4.8, 1.4, 1.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-soup-reference', ARRAY['greens_saaru','soppu_saaru','leafy_green_rasam_karnataka'], true, NULL, 'soup', 348, 0, 0.2, 0.0, 248, 78, 1.4, 148, 8.4, 0, 28, 0.3, 42, 1.8, 0.04, 'South India', 'India'),
('nuchinunde_karnataka_indian', 'Karnataka Nuchinunde', 148, 8.8, 18.4, 4.2, 4.8, 0.8, 30, 150, 5, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['nuchina_unde','steamed_lentil_dumpling_karnataka','nuchinunDe'], true, NULL, 'breakfast_dish', 248, 0, 0.6, 0.0, 228, 52, 2.4, 18, 1.8, 0, 36, 0.8, 108, 4.8, 0.04, 'South India', 'India'),
('tuppa_dosa_karnataka_indian', 'Karnataka Tuppa Dosa', 182, 3.8, 24.4, 7.8, 1.0, 0.6, 100, 140, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['tuppa_dose','ghee_dosa_karnataka','udupi_tuppa_dosa'], true, NULL, 'breakfast_dish', 288, 14, 4.4, 0.0, 82, 20, 0.8, 18, 0.0, 0, 12, 0.3, 58, 2.8, 0.02, 'South India', 'India'),
('ambode_karnataka_indian', 'Karnataka Ambode', 288, 12.4, 24.8, 14.8, 4.8, 1.4, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-snack-reference', ARRAY['ambodde','chana_dal_vada_karnataka','masala_vada_karnataka'], true, NULL, 'snack', 328, 0, 2.2, 0.0, 248, 42, 2.8, 18, 2.4, 0, 32, 0.8, 118, 5.8, 0.04, 'South India', 'India'),
('paruppusili_tamilnadu_indian', 'Tamil Nadu Paruppusili', 178, 10.8, 16.4, 7.8, 5.2, 1.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['paruppu_usili','lentil_crumble_tamilnadu','beans_paruppusili'], true, NULL, 'vegetable_dish', 228, 0, 1.2, 0.0, 348, 58, 2.8, 28, 4.8, 0, 42, 0.8, 128, 5.8, 0.06, 'South India', 'India'),
('kathirikai_gothsu_tamilnadu_indian', 'Tamil Nadu Kathirikai Gothsu', 88, 2.4, 10.4, 4.4, 3.4, 2.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['brinjal_gothsu','kathirikai_gojju_tamilnadu','eggplant_gothsu'], true, NULL, 'vegetable_curry', 348, 0, 0.6, 0.0, 278, 28, 0.8, 18, 3.8, 0, 18, 0.3, 48, 2.4, 0.04, 'South India', 'India'),
('avial_tamilnadu_indian', 'Tamil Nadu Avial', 108, 2.8, 10.8, 6.4, 3.8, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['aviyal_tamilnadu','mixed_veg_avial_tamilnadu'], true, NULL, 'vegetable_dish', 178, 0, 3.8, 0.0, 328, 28, 1.2, 48, 8.4, 0, 28, 0.4, 68, 2.8, 0.06, 'South India', 'India'),
('tamilnadu_chicken_varuval_indian', 'Tamil Nadu Chicken Varuval', 234, 22.4, 4.8, 13.8, 1.4, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-chicken', ARRAY['chicken_varuval_tamilnadu','koli_varuval_tamilnadu','chicken_dry_fry_tamil'], true, NULL, 'chicken_dish', 568, 88, 3.8, 0.0, 318, 38, 1.8, 52, 3.4, 0, 26, 1.4, 192, 13.2, 0.14, 'South India', 'India'),
('mutton_sukka_tamilnadu_indian', 'Tamil Nadu Mutton Sukka', 248, 20.4, 5.4, 15.8, 1.4, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-mutton', ARRAY['mutton_chukka','aattu_kari_sukka','mutton_dry_roast_tamilnadu'], true, NULL, 'mutton_dish', 588, 88, 6.2, 0.0, 348, 38, 2.4, 48, 2.8, 0, 26, 2.2, 208, 14.2, 0.18, 'South India', 'India'),
('tamilnadu_home_chicken_biryani_indian', 'Tamil Nadu Home-Style Chicken Biryani', 194, 10.2, 22.8, 7.4, 1.4, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-biryani', ARRAY['tamilnadu_chicken_biryani','tamil_chicken_biriyani'], true, NULL, 'rice_dish', 448, 46, 2.2, 0.0, 186, 28, 1.6, 36, 2.2, 0, 22, 1.2, 152, 9.4, 0.12, 'South India', 'India'),
('tamilnadu_egg_biryani_indian', 'Tamil Nadu Egg Biryani', 176, 7.8, 23.2, 6.2, 1.2, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-biryani', ARRAY['tamilnadu_egg_biriyani','muttai_biryani_tamilnadu'], true, NULL, 'rice_dish', 398, 112, 1.8, 0.0, 148, 32, 1.4, 58, 1.8, 8, 20, 0.9, 132, 9.8, 0.08, 'South India', 'India'),
('tamilnadu_veg_biryani_indian', 'Tamil Nadu Veg Biryani', 162, 4.4, 27.4, 4.8, 2.2, 1.6, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-biryani', ARRAY['tamilnadu_vegetable_biryani','veg_biriyani_tamilnadu'], true, NULL, 'rice_dish', 368, 4, 1.2, 0.0, 218, 44, 1.4, 52, 4.8, 0, 28, 0.8, 102, 5.4, 0.06, 'South India', 'India'),
('chettinad_veg_biryani_indian', 'Chettinad Veg Biryani', 172, 5.2, 27.8, 5.4, 2.4, 1.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_vegetable_biryani','chettinad_seeraga_samba_veg_biryani'], true, NULL, 'rice_dish', 388, 0, 1.4, 0.0, 228, 48, 1.6, 54, 5.2, 0, 30, 0.8, 108, 5.8, 0.06, 'South India', 'India'),
('kola_urundai_tamilnadu_indian', 'Tamil Nadu Kola Urundai', 228, 16.4, 12.4, 13.2, 2.4, 1.4, 30, 150, 5, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-snack-reference', ARRAY['kola_urundai','meat_balls_chettinad','mutton_kola_urundai'], true, NULL, 'snack', 488, 68, 4.2, 0.0, 308, 52, 2.4, 42, 2.4, 0, 26, 1.6, 168, 10.8, 0.16, 'South India', 'India'),
('vaazhaipoo_kootu_tamilnadu_indian', 'Tamil Nadu Vaazhaipoo Kootu', 118, 5.8, 12.4, 5.4, 5.2, 1.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-vegetarian', ARRAY['banana_flower_kootu','vazhaipoo_kootu_tamilnadu'], true, NULL, 'vegetable_dish', 248, 0, 0.8, 0.0, 368, 52, 2.8, 8, 4.4, 0, 36, 0.6, 98, 4.2, 0.04, 'South India', 'India'),
('raw_jackfruit_biryani_tamilnadu_indian', 'Tamil Nadu Raw Jackfruit Biryani', 158, 3.8, 26.8, 4.8, 3.2, 2.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-biryani', ARRAY['palakkai_biryani','jackfruit_biriyani_tamilnadu','palaa_kottai_biryani'], true, NULL, 'rice_dish', 348, 0, 1.2, 0.0, 228, 28, 1.4, 28, 4.2, 0, 24, 0.4, 82, 3.8, 0.06, 'South India', 'India'),
('sambar_drumstick_brinjal_tamilnadu_indian', 'Tamil Nadu Drumstick Brinjal Sambar', 92, 5.2, 11.2, 3.0, 3.8, 2.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sambar-variants', ARRAY['murungakkai_kathirikai_sambar','drumstick_brinjal_sambar'], true, NULL, 'soup', 438, 2, 0.6, 0.0, 348, 68, 1.8, 48, 16.4, 0, 36, 0.5, 82, 4.2, 0.06, 'South India', 'India'),
('majjige_huli_karnataka_indian', 'Karnataka Majjige Huli', 72, 3.4, 7.2, 3.2, 1.4, 2.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-curry-reference', ARRAY['majjige_saaru','buttermilk_curry_karnataka','moru_kuzhambu_karnataka'], true, NULL, 'curry', 348, 8, 1.4, 0.0, 168, 82, 0.4, 18, 1.8, 0, 14, 0.3, 72, 2.4, 0.02, 'South India', 'India'),
('karnataka_gojju_indian', 'Karnataka Gojju', 98, 2.4, 14.4, 4.2, 2.8, 6.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-curry-reference', ARRAY['huli_gojju','karnataka_sweet_sour_curry','menasina_gojju'], true, NULL, 'curry', 388, 0, 0.6, 0.0, 288, 42, 1.4, 22, 4.8, 0, 22, 0.4, 58, 3.2, 0.04, 'South India', 'India'),
('chutney_pudi_karnataka_indian', 'Karnataka Chutney Pudi', 468, 18.4, 28.4, 34.4, 6.4, 2.8, NULL, 20, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-condiment-reference', ARRAY['chutney_powder_karnataka','groundnut_chutney_pudi','kadale_bele_pudi'], true, NULL, 'condiment', 488, 0, 5.4, 0.0, 448, 78, 3.8, 8, 1.4, 0, 62, 1.4, 198, 8.4, 0.04, 'South India', 'India'),
('ragi_ladoo_karnataka_indian', 'Karnataka Ragi Ladoo', 388, 7.8, 52.4, 18.4, 3.8, 28.4, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-sweet-reference', ARRAY['ragi_laddu','finger_millet_ladoo','nachni_ladu'], true, NULL, 'sweet', 28, 14, 4.8, 0.0, 228, 118, 2.8, 4, 0.2, 0, 48, 0.8, 148, 5.8, 0.04, 'South India', 'India'),
('holige_with_ghee_indian', 'Holige Served with Ghee', 342, 6.6, 53.2, 11.4, 2.4, 18.6, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-festival-sweet', ARRAY['obbattu_ghee','holige_with_ghee','puranpoli_ghee_karnataka'], true, NULL, 'sweet', 68, 22, 5.2, 0.0, 148, 44, 2.2, 22, 0.8, 0, 28, 0.6, 88, 4.4, 0.04, 'South India', 'India'),
('veg_uttapam_karnataka_indian', 'Karnataka Veg Uttapam', 148, 4.8, 23.8, 4.4, 1.8, 1.4, 120, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['veg_uttappa_karnataka','vegetable_oothappam_karnataka'], true, NULL, 'breakfast_dish', 288, 0, 0.8, 0.0, 158, 38, 1.0, 24, 4.8, 0, 18, 0.4, 72, 3.4, 0.04, 'South India', 'India'),
('onion_uttapam_tamilnadu_indian', 'Tamil Nadu Onion Uttapam', 152, 4.4, 24.4, 4.2, 1.6, 1.8, 120, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['vengaya_oothappam','onion_oothappam_tamilnadu','vengaya_uttapam'], true, NULL, 'breakfast_dish', 282, 0, 0.6, 0.0, 148, 32, 0.8, 8, 2.8, 0, 16, 0.3, 68, 3.2, 0.04, 'South India', 'India'),
('tomato_uttapam_tamilnadu_indian', 'Tamil Nadu Tomato Uttapam', 148, 4.2, 24.2, 4.0, 1.8, 2.8, 120, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['thakkali_oothappam','tomato_oothappam_tamilnadu'], true, NULL, 'breakfast_dish', 278, 0, 0.6, 0.0, 188, 34, 0.8, 28, 6.4, 0, 16, 0.3, 68, 3.2, 0.04, 'South India', 'India'),
('godhuma_dosa_karnataka_indian', 'Karnataka Godhuma Dosa', 158, 5.4, 26.8, 3.8, 2.4, 0.8, 80, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['wheat_dosa_karnataka','godhuma_dose','atta_dosa_karnataka'], true, NULL, 'breakfast_dish', 248, 0, 0.6, 0.0, 128, 18, 1.4, 4, 0.2, 0, 20, 0.6, 88, 3.8, 0.04, 'South India', 'India'),
('neer_dosa_fish_curry_indian', 'Neer Dosa with Fish Curry', 154, 9.2, 18.4, 5.8, 1.2, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['neer_dose_fish_curry','neer_dosa_meen_curry'], true, NULL, 'main_course', 488, 56, 2.0, 0.0, 328, 68, 1.2, 32, 3.4, 0, 28, 0.8, 158, 11.2, 0.36, 'South India', 'India'),
('mangalore_soorna_curry_indian', 'Mangalore Soorna Curry', 108, 3.4, 14.8, 4.8, 3.8, 1.4, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['soorna_curry_mangalore','taro_root_curry_mangalore','mangalore_colacasia_curry'], true, NULL, 'vegetable_curry', 328, 0, 1.4, 0.0, 368, 28, 0.8, 8, 4.8, 0, 28, 0.4, 68, 2.8, 0.04, 'South India', 'India'),
('chettinad_black_rice_halwa_indian', 'Chettinad Black Rice Halwa', 348, 4.2, 58.4, 12.4, 1.4, 38.8, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-sweets-reference', ARRAY['kavuni_arisi_halwa','black_rice_halwa_chettinad'], true, NULL, 'sweet', 28, 18, 6.8, 0.0, 148, 28, 1.2, 0, 0.2, 0, 18, 0.4, 72, 3.4, 0.04, 'South India', 'India'),
('kongunadu_kaalaan_kulambu_indian', 'Kongunadu Kaalaan Kulambu', 98, 4.8, 9.4, 5.2, 2.4, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kongunadu-cuisine-reference', ARRAY['mushroom_kulambu_kongunadu','kaalaan_kuzhambu_kongunadu'], true, NULL, 'vegetable_curry', 388, 0, 0.8, 0.0, 348, 8, 1.2, 0, 2.8, 0, 18, 0.6, 88, 4.8, 0.06, 'South India', 'India'),
('ambur_prawn_biryani_indian', 'Ambur Prawn Biryani', 198, 10.8, 22.4, 7.4, 1.2, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Ambur-biryani-reference', ARRAY['ambur_eral_biryani','prawn_biryani_ambur'], true, NULL, 'rice_dish', 468, 82, 2.2, 0.0, 208, 38, 1.4, 32, 2.0, 0, 24, 0.8, 158, 10.2, 0.18, 'South India', 'India'),
('chettinad_nandu_masala_indian', 'Chettinad Nandu Masala', 148, 16.4, 6.8, 6.4, 1.4, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_crab_curry','nandu_kuzhambu_chettinad','crab_masala_chettinad'], true, NULL, 'seafood_dish', 578, 88, 1.8, 0.0, 368, 98, 1.2, 38, 4.8, 0, 42, 3.4, 248, 18.4, 0.28, 'South India', 'India'),
('hayagreeva_maddi_karnataka_indian', 'Karnataka Hayagreeva Maddi', 298, 9.8, 44.8, 10.4, 4.8, 22.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-temple-sweet', ARRAY['hayagreeva_sweet','chana_dal_sweet_karnataka','temple_prasad_karnataka'], true, NULL, 'sweet', 28, 14, 3.8, 0.0, 248, 42, 2.8, 8, 0.4, 0, 38, 0.8, 128, 5.8, 0.04, 'South India', 'India'),
('mysore_chitranna_indian', 'Mysore Chitranna', 172, 3.6, 28.2, 5.8, 1.6, 0.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['mysore_lemon_rice','chitranna_mysore','mosaranna_mysore'], true, NULL, 'rice_dish', 398, 0, 0.8, 0.0, 152, 18, 1.0, 4, 5.4, 0, 18, 0.4, 68, 3.4, 0.04, 'South India', 'India'),
('idiyappam_sweet_coconut_milk_indian', 'Idiyappam with Sweet Coconut Milk', 188, 3.0, 30.2, 7.2, 1.2, 8.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['idiyappam_sweet_thengai_paal','string_hoppers_sweetened_coconut_milk'], true, NULL, 'breakfast_dish', 68, 0, 5.4, 0.0, 158, 18, 0.6, 0, 1.2, 0, 14, 0.3, 62, 2.4, 0.04, 'South India', 'India'),
('vazhaipazham_bajji_tamilnadu_indian', 'Tamil Nadu Vazhaipazham Bajji', 248, 3.2, 34.8, 11.4, 1.6, 12.8, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-snack', ARRAY['banana_bajji_tamilnadu','bale_bajji_tamilnadu','pazham_bajji'], true, NULL, 'snack', 228, 0, 2.4, 0.0, 228, 28, 0.8, 8, 4.8, 0, 18, 0.4, 58, 2.8, 0.04, 'South India', 'India'),
('saggubiyyam_upma_karnataka_indian', 'Karnataka Sabudana Khichdi', 248, 3.2, 38.4, 8.8, 0.8, 2.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['sabudana_khichdi_karnataka','sago_upma_karnataka','sabbakki_uppittu'], true, NULL, 'breakfast_dish', 68, 0, 1.4, 0.0, 148, 18, 0.8, 0, 4.8, 0, 18, 0.4, 58, 2.4, 0.04, 'South India', 'India'),
('meen_puttu_tamilnadu_indian', 'Tamil Nadu Meen Puttu', 178, 16.4, 8.4, 8.8, 1.2, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['fish_puttu_tamilnadu','meen_putttu','steamed_fish_tamilnadu'], true, NULL, 'seafood_dish', 488, 68, 2.2, 0.0, 388, 68, 1.2, 38, 2.8, 0, 34, 0.8, 198, 14.8, 0.34, 'South India', 'India'),
('kollu_rasam_tamilnadu_indian', 'Tamil Nadu Kollu Rasam', 48, 3.2, 6.4, 0.8, 2.4, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rasam-reference', ARRAY['horsegram_rasam','kulthi_rasam_tamilnadu','ulavacharu_tamilnadu'], true, NULL, 'soup', 348, 0, 0.2, 0.0, 348, 42, 2.8, 8, 2.4, 0, 32, 0.8, 88, 4.2, 0.04, 'South India', 'India'),
('kollu_sambar_tamilnadu_indian', 'Tamil Nadu Kollu Sambar', 92, 6.8, 10.4, 2.4, 4.8, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-sambar-variants', ARRAY['horsegram_sambar','kulthi_sambar_tamilnadu'], true, NULL, 'soup', 388, 2, 0.4, 0.0, 368, 58, 3.2, 12, 2.8, 0, 42, 0.8, 108, 5.8, 0.04, 'South India', 'India'),
('bele_saaru_karnataka_indian', 'Karnataka Bele Saaru', 68, 4.8, 8.4, 1.4, 2.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-soup-reference', ARRAY['bele_rasam','dal_rasam_karnataka','toor_dal_saaru_karnataka'], true, NULL, 'soup', 348, 0, 0.2, 0.0, 268, 32, 1.4, 18, 2.4, 0, 24, 0.4, 78, 3.4, 0.04, 'South India', 'India'),
('keerai_vadai_tamilnadu_indian', 'Tamil Nadu Keerai Vadai', 228, 9.4, 20.8, 12.4, 4.4, 0.8, 40, 120, 3, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-snack', ARRAY['spinach_vada_tamilnadu','keerai_vade','greens_fritter_tamilnadu'], true, NULL, 'snack', 318, 0, 2.0, 0.0, 298, 68, 2.8, 148, 8.4, 0, 42, 0.8, 108, 5.8, 0.04, 'South India', 'India'),
('dindigul_egg_biryani_indian', 'Dindigul Egg Biryani', 178, 7.8, 23.4, 6.4, 1.2, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Dindigul-biryani-reference', ARRAY['dindigul_muttai_biryani','thalappakatti_egg_biryani'], true, NULL, 'rice_dish', 408, 114, 1.8, 0.0, 152, 32, 1.4, 58, 1.8, 8, 20, 0.9, 136, 9.8, 0.08, 'South India', 'India'),
('chettinad_idiyappam_indian', 'Chettinad Spiced Idiyappam', 158, 3.4, 28.4, 4.2, 1.2, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_string_hoppers','chettinad_idiyappam_spiced'], true, NULL, 'breakfast_dish', 228, 0, 0.8, 0.0, 98, 18, 0.6, 4, 1.2, 0, 12, 0.3, 58, 2.4, 0.02, 'South India', 'India'),
('chicken_donne_biryani_indian', 'Chicken Donne Biryani', 182, 9.2, 22.1, 6.8, 1.2, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;FSSAI-NIN-biryani-range', ARRAY['donne_biriyani_chicken','chicken_donne_biriyani','bangalore_donne_biryani'], true, NULL, 'rice_dish', 420, 38, 2.1, 0.0, 160, 28, 1.4, 42, 2.1, 0, 22, 1.1, 140, 8.5, 0.12, 'South India', 'India'),
('chicken_boneless_donne_biryani_indian', 'Chicken Boneless Donne Biryani', 188, 12.4, 21.9, 5.1, 1.1, 0.7, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;FSSAI-NIN-biryani-range', ARRAY['boneless_donne_biryani','chicken_boneless_donne_biriyani'], true, NULL, 'rice_dish', 410, 42, 1.6, 0.0, 175, 26, 1.5, 38, 2.3, 0, 24, 1.3, 155, 9.2, 0.10, 'South India', 'India'),
('mutton_donne_biryani_indian', 'Mutton Donne Biryani', 196, 10.8, 21.5, 8.2, 1.1, 0.7, NULL, 320, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;FSSAI-NIN-biryani-range', ARRAY['mutton_donne_biriyani','goat_donne_biryani'], true, NULL, 'rice_dish', 440, 48, 3.1, 0.0, 180, 24, 1.8, 36, 1.8, 0, 20, 2.1, 148, 10.2, 0.15, 'South India', 'India'),
('egg_donne_biryani_indian', 'Egg Donne Biryani', 172, 7.8, 22.8, 5.9, 1.2, 0.9, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;FSSAI-NIN-biryani-range', ARRAY['egg_donne_biriyani','anda_donne_biryani'], true, NULL, 'rice_dish', 390, 110, 1.8, 0.0, 145, 30, 1.3, 55, 1.5, 8, 18, 0.9, 128, 9.8, 0.08, 'South India', 'India'),
('veg_donne_biryani_indian', 'Veg Donne Biryani', 158, 4.2, 26.8, 4.1, 2.1, 1.4, NULL, 280, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;FSSAI-NIN-biryani-range', ARRAY['vegetable_donne_biryani','veg_donne_biriyani'], true, NULL, 'rice_dish', 350, 5, 1.2, 0.0, 190, 42, 1.2, 68, 4.2, 0, 28, 0.7, 98, 4.2, 0.05, 'South India', 'India'),
('mylari_dosa_plain_indian', 'Mylari Dosa Plain', 142, 3.8, 24.2, 3.6, 1.0, 0.5, 100, 110, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mysore-street-food-reference', ARRAY['mylari_dosa','mysore_mylari_dosa'], true, NULL, 'breakfast_dish', 280, 0, 0.8, 0.0, 82, 18, 0.9, 0, 0.0, 0, 12, 0.4, 62, 3.1, 0.02, 'South India', 'India'),
('mylari_dosa_ghee_indian', 'Mylari Dosa with Ghee', 168, 3.9, 23.8, 6.2, 0.9, 0.5, 105, 115, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mysore-street-food-reference', ARRAY['mylari_dosa_with_ghee','ghee_mylari_dosa'], true, NULL, 'breakfast_dish', 285, 12, 3.4, 0.0, 80, 20, 0.9, 18, 0.0, 0, 12, 0.4, 62, 3.2, 0.02, 'South India', 'India'),
('mylari_dosa_masala_indian', 'Mylari Masala Dosa', 158, 4.6, 25.8, 4.8, 1.4, 0.9, 120, 130, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mysore-street-food-reference', ARRAY['mylari_masala_dosa','masala_mylari_dosa'], true, NULL, 'breakfast_dish', 320, 4, 1.2, 0.0, 148, 28, 1.1, 12, 4.5, 0, 18, 0.6, 88, 3.8, 0.03, 'South India', 'India'),
('mylari_dosa_butter_indian', 'Mylari Dosa with Butter', 172, 3.9, 23.6, 6.8, 0.9, 0.5, 105, 115, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mysore-street-food-reference', ARRAY['butter_mylari_dosa','mylari_dosa_with_butter'], true, NULL, 'breakfast_dish', 290, 14, 3.8, 0.1, 80, 22, 0.9, 22, 0.0, 0, 12, 0.4, 62, 3.2, 0.02, 'South India', 'India'),
('ragi_mudde_with_mutton_curry_indian', 'Ragi Mudde with Mutton Curry', 148, 9.4, 18.2, 4.8, 2.8, 0.4, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-ragi-data', ARRAY['ragi_ball_mutton_curry','ragi_mudde_mutton'], true, NULL, 'main_course', 380, 44, 1.8, 0.0, 280, 110, 3.2, 18, 1.2, 0, 48, 1.8, 168, 6.2, 0.18, 'South India', 'India'),
('ragi_mudde_with_palya_indian', 'Ragi Mudde with Palya', 128, 3.8, 22.4, 2.6, 3.4, 1.2, 150, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-ragi-data', ARRAY['ragi_ball_palya','ragi_mudde_palya_veg'], true, NULL, 'main_course', 220, 0, 0.5, 0.0, 310, 128, 2.8, 42, 6.8, 0, 52, 0.9, 142, 4.8, 0.04, 'South India', 'India'),
('ragi_mudde_with_chicken_saaru_indian', 'Ragi Mudde with Chicken Saaru', 142, 10.8, 18.6, 3.8, 2.6, 0.5, 150, 210, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-ragi-data', ARRAY['ragi_ball_chicken_curry','ragi_mudde_koli_saaru'], true, NULL, 'main_course', 340, 38, 1.1, 0.0, 268, 108, 2.6, 24, 2.4, 0, 44, 1.4, 158, 7.2, 0.14, 'South India', 'India'),
('ragi_ball_plain_indian', 'Ragi Ball Plain', 118, 2.8, 22.8, 1.6, 3.2, 0.3, 120, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-finger-millet', ARRAY['ragi_mudde_plain','finger_millet_ball'], true, NULL, 'staple', 8, 0, 0.3, 0.0, 188, 96, 2.4, 4, 0.0, 0, 42, 0.6, 118, 3.2, 0.02, 'South India', 'India'),
('ragi_roti_indian', 'Ragi Roti', 168, 4.2, 30.4, 3.2, 3.8, 0.6, 80, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-finger-millet', ARRAY['finger_millet_roti','nachni_roti_karnataka'], true, NULL, 'flatbread', 180, 0, 0.6, 0.0, 218, 102, 2.6, 8, 0.2, 0, 44, 0.7, 128, 3.8, 0.03, 'South India', 'India'),
('ragi_dosa_onion_indian', 'Ragi Dosa with Onion', 132, 3.6, 22.8, 3.0, 2.4, 1.2, 90, 110, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-finger-millet', ARRAY['ragi_dosa_onion','finger_millet_dosa_onion'], true, NULL, 'breakfast_dish', 248, 0, 0.5, 0.0, 168, 88, 1.8, 6, 2.8, 0, 36, 0.5, 108, 3.2, 0.02, 'South India', 'India'),
('ragi_dosa_egg_indian', 'Ragi Dosa with Egg', 152, 7.2, 20.8, 4.8, 2.2, 0.8, 110, 130, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-finger-millet', ARRAY['egg_ragi_dosa','ragi_egg_dosa'], true, NULL, 'breakfast_dish', 302, 112, 1.2, 0.0, 188, 92, 2.0, 48, 1.4, 8, 38, 0.8, 128, 6.2, 0.04, 'South India', 'India'),
('neer_dosa_with_coconut_chutney_indian', 'Neer Dosa with Coconut Chutney', 128, 2.4, 22.4, 3.2, 1.0, 0.8, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['neer_dose_coconut_chutney','mangalore_neer_dosa_chutney'], true, NULL, 'breakfast_dish', 210, 0, 1.8, 0.0, 108, 18, 0.8, 0, 1.2, 0, 16, 0.4, 58, 2.4, 0.04, 'South India', 'India'),
('neer_dosa_kori_rotti_curry_indian', 'Neer Dosa with Kori Rotti Curry', 164, 8.8, 18.2, 6.8, 1.2, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['neer_dosa_chicken_curry','neer_dose_kori_curry'], true, NULL, 'main_course', 388, 42, 2.2, 0.0, 218, 38, 1.6, 32, 2.8, 0, 26, 1.2, 148, 8.2, 0.14, 'South India', 'India'),
('kori_rotti_indian', 'Kori Rotti', 188, 12.4, 16.8, 7.8, 1.4, 0.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['kori_rotty','mangalore_chicken_kori_rotti','tulu_kori_rotti'], true, NULL, 'main_course', 448, 58, 2.4, 0.0, 248, 48, 1.8, 38, 3.2, 0, 28, 1.4, 168, 9.8, 0.16, 'South India', 'India'),
('kori_rotti_mutton_indian', 'Mutton Kori Rotti', 198, 13.2, 16.4, 8.8, 1.4, 0.7, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['mutton_kori_rotty','mangalore_mutton_kori_rotti'], true, NULL, 'main_course', 468, 64, 3.4, 0.0, 258, 44, 2.2, 34, 2.8, 0, 26, 2.2, 178, 11.2, 0.18, 'South India', 'India'),
('mangalore_ghee_roast_chicken_indian', 'Mangalore Ghee Roast Chicken', 228, 18.2, 8.4, 14.2, 1.2, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['ghee_roast_chicken_mangalore','chicken_ghee_roast_mangalorean'], true, NULL, 'chicken_dish', 580, 82, 5.8, 0.0, 288, 42, 1.8, 68, 3.2, 0, 28, 1.6, 188, 12.4, 0.14, 'South India', 'India'),
('mangalore_ghee_roast_mutton_indian', 'Mangalore Ghee Roast Mutton', 242, 17.4, 8.2, 16.2, 1.1, 1.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['ghee_roast_mutton_mangalore','mutton_ghee_roast_mangalorean'], true, NULL, 'mutton_dish', 598, 88, 6.8, 0.0, 278, 38, 2.4, 58, 2.8, 0, 24, 2.4, 192, 13.8, 0.16, 'South India', 'India'),
('mangalore_ghee_roast_prawns_indian', 'Mangalore Ghee Roast Prawns', 218, 16.8, 8.8, 13.2, 0.8, 1.4, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['prawn_ghee_roast_mangalore','jhinga_ghee_roast_mangalorean'], true, NULL, 'seafood_dish', 620, 128, 5.2, 0.0, 318, 68, 1.6, 48, 4.2, 0, 32, 1.4, 228, 18.2, 0.24, 'South India', 'India'),
('mangalore_fish_curry_with_neer_dosa_indian', 'Mangalore Fish Curry with Neer Dosa', 168, 10.8, 16.4, 6.8, 1.4, 1.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Mangalore-cuisine-reference', ARRAY['fish_curry_neer_dosa_mangalore'], true, NULL, 'seafood_dish', 488, 58, 2.8, 0.0, 348, 82, 1.4, 42, 4.8, 0, 34, 0.8, 178, 14.2, 0.38, 'South India', 'India'),
('udupi_goli_baje_indian', 'Udupi Goli Baje', 282, 6.2, 34.8, 12.8, 1.2, 2.4, 20, 80, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Udupi-cuisine-reference', ARRAY['goli_baje','golibaje','mangalore_bajji','udupi_fritter'], true, NULL, 'snack', 368, 18, 2.4, 0.1, 88, 62, 1.8, 8, 0.4, 0, 18, 0.6, 78, 4.8, 0.04, 'South India', 'India'),
('kosambari_karnataka_indian', 'Karnataka Kosambari', 88, 4.8, 10.2, 2.8, 2.4, 2.2, NULL, 100, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Udupi-Karnataka-satvic-cuisine', ARRAY['kosambri','kosambari_salad','cucumber_moong_kosambari'], true, NULL, 'salad', 188, 0, 0.4, 0.0, 248, 42, 1.2, 28, 8.4, 0, 28, 0.6, 78, 2.4, 0.06, 'South India', 'India'),
('jolada_rotti_indian', 'Jolada Rotti', 172, 4.8, 32.4, 2.4, 3.2, 0.8, 80, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;ICMR-NIN-sorghum-data', ARRAY['jolada_rotty','jowar_roti_karnataka','sorghum_roti_karnataka'], true, NULL, 'flatbread', 48, 0, 0.4, 0.0, 208, 28, 2.2, 0, 0.0, 0, 38, 0.4, 118, 3.8, 0.02, 'South India', 'India'),
('jolada_rotti_with_ennegayi_indian', 'Jolada Rotti with Ennegayi', 168, 5.2, 28.4, 4.8, 3.8, 2.4, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;North-Karnataka-cuisine', ARRAY['jolada_rotty_ennegayi','jowar_roti_stuffed_brinjal'], true, NULL, 'main_course', 288, 0, 0.8, 0.0, 318, 58, 2.4, 18, 4.8, 0, 42, 0.6, 128, 4.2, 0.06, 'South India', 'India'),
('uppittu_karnataka_indian', 'Karnataka Uppittu', 148, 3.8, 24.8, 4.2, 1.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['uppittu','karnataka_upma','rava_uppittu'], true, NULL, 'breakfast_dish', 348, 0, 0.6, 0.0, 148, 28, 1.4, 8, 2.8, 0, 22, 0.5, 78, 4.2, 0.04, 'South India', 'India'),
('uppittu_with_vegetables_indian', 'Vegetable Uppittu', 158, 4.2, 25.4, 4.6, 2.4, 1.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['veg_uppittu','vegetable_upma_karnataka'], true, NULL, 'breakfast_dish', 362, 0, 0.7, 0.0, 218, 38, 1.6, 28, 6.4, 0, 28, 0.6, 88, 4.8, 0.05, 'South India', 'India'),
('chiroti_karnataka_indian', 'Karnataka Chiroti', 398, 6.8, 52.4, 18.2, 1.2, 22.8, 40, 80, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-festival-sweet', ARRAY['chirote','chiroti_sweet','karnataka_chiroti'], true, NULL, 'sweet_snack', 68, 28, 4.8, 0.1, 88, 48, 1.8, 22, 0.4, 0, 12, 0.4, 68, 4.2, 0.04, 'South India', 'India'),
('holige_obbattu_indian', 'Holige / Obbattu', 312, 6.4, 52.8, 8.2, 2.4, 18.4, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-festival-sweet', ARRAY['holige','obbattu','puran_poli_karnataka','obbattu_karnataka'], true, NULL, 'sweet', 88, 12, 2.4, 0.0, 148, 42, 2.2, 18, 0.8, 0, 28, 0.6, 88, 4.2, 0.04, 'South India', 'India'),
('holige_coconut_filling_indian', 'Coconut Holige', 318, 5.8, 50.4, 10.8, 2.8, 20.4, 80, 120, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-festival-sweet', ARRAY['coconut_obbattu','tengina_obbattu','kobri_holige'], true, NULL, 'sweet', 68, 8, 6.4, 0.0, 168, 28, 1.6, 8, 0.8, 0, 22, 0.4, 72, 3.8, 0.06, 'South India', 'India'),
('thatte_idli_indian', 'Thatte Idli', 138, 3.8, 26.4, 1.8, 1.2, 0.4, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-idli-reference', ARRAY['thatte_idly','thattu_idli','plate_idli_karnataka'], true, NULL, 'breakfast_dish', 248, 0, 0.3, 0.0, 82, 22, 0.8, 0, 0.0, 0, 14, 0.3, 52, 2.8, 0.02, 'South India', 'India'),
('thatte_idli_with_sambar_indian', 'Thatte Idli with Sambar', 148, 5.2, 26.8, 2.4, 2.4, 0.8, NULL, 220, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-idli-reference', ARRAY['thatte_idli_sambar','thattu_idli_sambar'], true, NULL, 'breakfast_dish', 388, 2, 0.4, 0.0, 188, 48, 1.4, 18, 2.4, 0, 24, 0.5, 88, 3.8, 0.04, 'South India', 'India'),
('kundapura_chicken_indian', 'Kundapura Chicken', 218, 18.4, 6.8, 13.2, 1.8, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-cuisine', ARRAY['kundapur_chicken','kundapura_koli','tulu_chicken_curry'], true, NULL, 'chicken_dish', 568, 82, 4.2, 0.0, 298, 48, 1.8, 58, 3.8, 0, 28, 1.4, 188, 12.2, 0.16, 'South India', 'India'),
('kundapura_chicken_neer_dosa_indian', 'Kundapura Chicken with Neer Dosa', 188, 12.8, 16.2, 9.2, 1.4, 1.0, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coastal-Karnataka-cuisine', ARRAY['kundapur_chicken_neer_dosa','tulu_chicken_neer_dose'], true, NULL, 'main_course', 488, 58, 3.2, 0.0, 228, 38, 1.4, 42, 2.8, 0, 22, 1.0, 158, 9.8, 0.12, 'South India', 'India'),
('koli_saaru_karnataka_indian', 'Karnataka Koli Saaru', 78, 8.4, 4.2, 2.8, 0.8, 0.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-chicken-curry', ARRAY['koli_saru','chicken_saaru_karnataka','karnataka_chicken_rasam'], true, NULL, 'soup', 388, 38, 0.8, 0.0, 218, 28, 0.8, 28, 2.4, 0, 18, 0.8, 118, 7.2, 0.12, 'South India', 'India'),
('koli_saaru_with_ragi_mudde_indian', 'Koli Saaru with Ragi Mudde', 132, 9.2, 16.8, 3.2, 2.8, 0.5, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-chicken-curry', ARRAY['chicken_saaru_ragi_mudde','koli_saru_ragi_ball'], true, NULL, 'main_course', 322, 32, 0.9, 0.0, 268, 98, 1.8, 24, 1.8, 0, 38, 1.1, 148, 8.4, 0.12, 'South India', 'India'),
('chow_chow_bath_indian', 'Chow Chow Bath', 218, 4.8, 34.8, 7.2, 1.8, 12.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Bangalore-breakfast-reference', ARRAY['chowchow_bath','khara_bath_kesari_bath','bangalore_chow_chow_bath'], true, NULL, 'breakfast_dish', 248, 8, 2.2, 0.0, 148, 32, 1.4, 28, 1.8, 0, 18, 0.4, 78, 4.2, 0.04, 'South India', 'India'),
('khara_bath_bangalore_indian', 'Bangalore Khara Bath', 168, 3.8, 26.8, 5.4, 1.8, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Bangalore-breakfast-reference', ARRAY['khara_baath','bangalore_khara_bath','savory_rava_bath'], true, NULL, 'breakfast_dish', 328, 0, 0.8, 0.0, 168, 28, 1.2, 12, 3.8, 0, 22, 0.4, 82, 4.4, 0.04, 'South India', 'India'),
('kesari_bath_bangalore_indian', 'Bangalore Kesari Bath', 248, 4.2, 38.4, 9.2, 1.2, 18.8, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Bangalore-breakfast-reference', ARRAY['kesari_baath','bangalore_kesari_bath','sweet_rava_bath','sheera_bangalore'], true, NULL, 'sweet', 68, 22, 4.8, 0.0, 82, 28, 0.8, 12, 0.4, 0, 12, 0.3, 58, 2.8, 0.04, 'South India', 'India'),
('bisi_bele_bath_with_papad_indian', 'Bisi Bele Bath with Papad', 162, 6.2, 24.8, 4.8, 3.2, 1.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['bisi_bele_bath_papad','bisibelebath_with_papadum'], true, NULL, 'rice_dish', 448, 4, 1.2, 0.0, 268, 58, 2.2, 28, 4.8, 0, 38, 0.8, 128, 6.4, 0.06, 'South India', 'India'),
('bisi_bele_bath_ghee_indian', 'Bisi Bele Bath with Ghee', 184, 6.4, 24.4, 7.2, 3.0, 1.3, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-rice-dish', ARRAY['ghee_bisi_bele_bath','bisibelebath_ghee'], true, NULL, 'rice_dish', 428, 18, 3.8, 0.0, 258, 56, 2.0, 32, 4.4, 0, 36, 0.8, 122, 6.2, 0.06, 'South India', 'India'),
('coorg_pandi_curry_neer_dosa_indian', 'Coorg Pandi Curry with Neer Dosa', 186, 11.4, 16.8, 8.4, 1.4, 0.8, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coorg-Kodagu-cuisine', ARRAY['pandi_curry_neer_dosa','kodava_pandi_curry_with_neer_dose'], true, NULL, 'main_course', 488, 68, 3.2, 0.0, 298, 32, 1.8, 28, 2.2, 0, 22, 1.6, 158, 10.2, 0.14, 'South India', 'India'),
('coorg_kachampuli_pandi_curry_indian', 'Coorg Kachampuli Pandi Curry', 228, 14.8, 8.2, 14.4, 1.6, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Coorg-Kodagu-cuisine', ARRAY['kachampuli_pork_curry','kodava_kachampuli_pork','coorg_pork_kachampuli'], true, NULL, 'main_course', 528, 78, 5.4, 0.0, 328, 28, 1.8, 22, 1.8, 0, 24, 1.8, 178, 12.4, 0.16, 'South India', 'India'),
('akki_roti_with_onion_chilli_indian', 'Akki Roti with Onion and Chilli', 182, 3.8, 32.8, 4.2, 1.4, 0.8, 80, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['akki_rotty_onion','rice_roti_onion_karnataka'], true, NULL, 'breakfast_dish', 288, 0, 0.6, 0.0, 128, 14, 0.6, 8, 2.4, 0, 16, 0.3, 62, 2.8, 0.02, 'South India', 'India'),
('akki_roti_coconut_dill_indian', 'Akki Roti with Coconut and Dill', 192, 3.6, 31.2, 6.2, 1.6, 0.6, 80, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-breakfast-reference', ARRAY['akki_rotty_coconut','rice_roti_coconut_dill'], true, NULL, 'breakfast_dish', 218, 0, 3.8, 0.0, 148, 22, 0.6, 0, 1.2, 0, 18, 0.3, 68, 2.8, 0.04, 'South India', 'India'),
('benne_dosa_potato_palya_indian', 'Benne Dosa with Potato Palya', 178, 3.8, 24.8, 7.2, 1.6, 1.2, 120, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Davangere-Karnataka-reference', ARRAY['butter_dosa_potato','benne_dose_aloo'], true, NULL, 'breakfast_dish', 318, 14, 3.8, 0.1, 228, 28, 0.8, 18, 4.2, 0, 22, 0.4, 78, 3.4, 0.04, 'South India', 'India'),
('davangere_benne_dosa_indian', 'Davangere Benne Dosa', 192, 3.6, 24.2, 9.2, 1.4, 1.0, 120, 160, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Davangere-Karnataka-reference', ARRAY['davanagere_benne_dose','davanagere_butter_dosa','davangere_benne_dose'], true, NULL, 'breakfast_dish', 308, 24, 5.4, 0.2, 118, 24, 0.8, 28, 0.2, 0, 14, 0.3, 62, 3.2, 0.04, 'South India', 'India'),
('chettinad_pepper_chicken_indian', 'Chettinad Pepper Chicken', 212, 19.4, 5.8, 12.4, 1.4, 0.8, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['pepper_chicken_chettinad','milagu_chicken_chettinad'], true, NULL, 'chicken_dish', 548, 88, 3.8, 0.0, 308, 42, 1.8, 58, 3.8, 0, 28, 1.4, 192, 12.8, 0.14, 'South India', 'India'),
('chettinad_fish_curry_indian', 'Chettinad Fish Curry', 148, 14.8, 8.2, 6.4, 1.6, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_meen_kulambu','chettinad_fish_kuzhambu','nattukozhi_fish_curry_chettinad'], true, NULL, 'seafood_dish', 528, 68, 1.8, 0.0, 388, 78, 1.4, 42, 4.8, 0, 34, 0.8, 188, 14.8, 0.42, 'South India', 'India'),
('chettinad_prawn_masala_indian', 'Chettinad Prawn Masala', 188, 16.8, 7.4, 10.2, 1.2, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-cuisine-reference', ARRAY['chettinad_eral_masala','chettinad_prawn_curry','eral_kuzhambu_chettinad'], true, NULL, 'seafood_dish', 588, 138, 2.8, 0.0, 348, 82, 1.4, 48, 4.2, 0, 36, 1.2, 228, 16.4, 0.28, 'South India', 'India'),
('chettinad_kavuni_arisi_pudding_indian', 'Chettinad Kavuni Arisi Pudding', 228, 4.2, 42.8, 5.2, 1.8, 22.4, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-sweets-reference', ARRAY['kavuni_arisi_sweet','black_rice_pudding_chettinad'], true, NULL, 'sweet', 28, 8, 2.8, 0.0, 148, 38, 1.4, 0, 0.4, 0, 22, 0.6, 82, 3.8, 0.04, 'South India', 'India'),
('kongunadu_mutton_kari_indian', 'Kongunadu Mutton Kari', 224, 16.4, 7.4, 14.2, 1.8, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kongunadu-cuisine-reference', ARRAY['kongu_mutton_curry','kongunadu_kari_goat','coimbatore_mutton_kari'], true, NULL, 'mutton_dish', 548, 78, 5.4, 0.0, 348, 42, 2.4, 48, 3.2, 0, 28, 2.2, 188, 12.4, 0.18, 'South India', 'India'),
('kongunadu_chicken_kari_indian', 'Kongunadu Chicken Kari', 198, 17.8, 7.2, 11.4, 1.6, 1.0, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Kongunadu-cuisine-reference', ARRAY['kongu_chicken_curry','kongunadu_koli_kari','erode_chicken_kari'], true, NULL, 'chicken_dish', 528, 82, 3.4, 0.0, 318, 38, 1.6, 52, 3.4, 0, 26, 1.4, 178, 11.8, 0.14, 'South India', 'India'),
('dindigul_biryani_thalappakatti_indian', 'Dindigul Thalappakatti Biryani', 196, 10.8, 22.8, 7.4, 1.4, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Dindigul-biryani-reference', ARRAY['thalappakatti_biryani_dindigul','dindigul_seeraga_samba_biryani'], true, NULL, 'rice_dish', 468, 48, 2.4, 0.0, 188, 32, 1.8, 38, 2.4, 0, 24, 1.2, 158, 9.8, 0.14, 'South India', 'India'),
('dindigul_mutton_biryani_indian', 'Dindigul Mutton Biryani', 208, 11.8, 22.4, 8.8, 1.3, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Dindigul-biryani-reference', ARRAY['dindigul_mutton_biriyani','dindigul_seeraga_samba_mutton_biryani'], true, NULL, 'rice_dish', 488, 54, 3.4, 0.0, 198, 28, 2.0, 34, 2.0, 0, 22, 1.8, 168, 10.8, 0.16, 'South India', 'India'),
('ambur_star_chicken_biryani_indian', 'Ambur Star Chicken Biryani', 192, 10.2, 22.6, 7.2, 1.2, 0.9, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Ambur-biryani-reference', ARRAY['ambur_biryani_chicken','ambur_chicken_biriyani','star_biryani_ambur'], true, NULL, 'rice_dish', 452, 44, 2.2, 0.0, 182, 28, 1.6, 36, 2.2, 0, 22, 1.1, 148, 9.2, 0.12, 'South India', 'India'),
('ambur_mutton_biryani_indian', 'Ambur Mutton Biryani', 204, 11.4, 22.2, 8.6, 1.2, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Ambur-biryani-reference', ARRAY['ambur_biryani_mutton','ambur_mutton_biriyani'], true, NULL, 'rice_dish', 472, 52, 3.2, 0.0, 192, 24, 1.8, 32, 1.8, 0, 20, 1.6, 158, 10.4, 0.14, 'South India', 'India'),
('karaikudi_chicken_dry_indian', 'Karaikudi Chicken Dry', 224, 20.4, 6.4, 13.2, 1.6, 1.0, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karaikudi-Chettinad-reference', ARRAY['karaikudi_chicken','chettinad_dry_chicken','karaikudi_koli_varuval'], true, NULL, 'chicken_dish', 578, 92, 3.8, 0.0, 328, 44, 2.0, 62, 4.2, 0, 30, 1.6, 198, 13.4, 0.16, 'South India', 'India'),
('karaikudi_mutton_fry_indian', 'Karaikudi Mutton Fry', 238, 18.8, 5.8, 15.4, 1.4, 0.8, NULL, 180, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Karaikudi-Chettinad-reference', ARRAY['chettinad_mutton_fry','karaikudi_aattu_kari_varuval'], true, NULL, 'mutton_dish', 598, 88, 6.2, 0.0, 338, 38, 2.4, 52, 3.8, 0, 26, 2.4, 208, 14.2, 0.18, 'South India', 'India'),
('kuzhi_paniyaram_sweet_indian', 'Sweet Kuzhi Paniyaram', 228, 4.8, 38.4, 7.2, 1.4, 18.2, 20, 120, 6, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['sweet_paniyaram','inippu_kuzhi_paniyaram','jaggery_paniyaram'], true, NULL, 'sweet_snack', 88, 18, 2.8, 0.0, 148, 42, 1.2, 8, 0.4, 0, 18, 0.4, 68, 3.4, 0.04, 'South India', 'India'),
('kuzhi_paniyaram_savory_indian', 'Savory Kuzhi Paniyaram', 178, 5.4, 28.4, 5.2, 1.6, 0.8, 20, 120, 6, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['savory_paniyaram','kaara_kuzhi_paniyaram','onion_paniyaram'], true, NULL, 'breakfast_dish', 288, 8, 0.8, 0.0, 168, 38, 1.0, 12, 2.8, 0, 18, 0.4, 72, 3.6, 0.04, 'South India', 'India'),
('idiyappam_with_coconut_milk_indian', 'Idiyappam with Coconut Milk', 168, 3.2, 26.4, 5.8, 1.2, 2.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['string_hoppers_coconut_milk','idiyappam_thengai_paal'], true, NULL, 'breakfast_dish', 88, 0, 4.4, 0.0, 148, 18, 0.8, 0, 1.2, 0, 16, 0.3, 68, 2.8, 0.04, 'South India', 'India'),
('idiyappam_with_kurma_indian', 'Idiyappam with Veg Kurma', 158, 4.8, 25.8, 4.4, 2.4, 2.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['idiyappam_kurma','string_hoppers_korma','idiyappam_with_korma'], true, NULL, 'breakfast_dish', 288, 2, 1.2, 0.0, 228, 48, 1.2, 42, 4.8, 0, 28, 0.6, 88, 3.8, 0.06, 'South India', 'India'),
('idiyappam_with_egg_curry_indian', 'Idiyappam with Egg Curry', 162, 7.4, 22.8, 5.2, 1.2, 1.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['idiyappam_egg_curry','string_hoppers_egg_curry'], true, NULL, 'breakfast_dish', 348, 108, 1.4, 0.0, 198, 42, 1.2, 62, 2.4, 8, 22, 0.8, 118, 7.4, 0.08, 'South India', 'India'),
('kothu_parotta_chicken_indian', 'Chicken Kothu Parotta', 228, 14.4, 22.8, 9.2, 1.6, 1.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-street-food', ARRAY['chicken_kottu_parotta','kotthu_parotta_chicken'], true, NULL, 'street_food', 548, 62, 2.8, 0.0, 298, 42, 1.8, 48, 2.8, 0, 26, 1.2, 168, 10.8, 0.12, 'South India', 'India'),
('kothu_parotta_veg_indian', 'Veg Kothu Parotta', 198, 5.8, 28.4, 7.4, 2.2, 2.2, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-street-food', ARRAY['veg_kottu_parotta','vegetable_kotthu_parotta'], true, NULL, 'street_food', 428, 0, 1.8, 0.0, 228, 48, 1.4, 38, 4.8, 0, 28, 0.6, 108, 5.8, 0.06, 'South India', 'India'),
('kothu_parotta_mutton_indian', 'Mutton Kothu Parotta', 248, 15.2, 22.4, 11.8, 1.4, 1.2, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-street-food', ARRAY['mutton_kottu_parotta','kotthu_parotta_mutton'], true, NULL, 'street_food', 568, 68, 4.2, 0.0, 308, 38, 2.2, 42, 2.4, 0, 24, 1.8, 178, 12.4, 0.16, 'South India', 'India'),
('plain_parotta_tamilnadu_indian', 'Tamil Nadu Plain Parotta', 288, 6.4, 38.2, 12.4, 1.4, 0.8, 60, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-parotta-reference', ARRAY['plain_parotta','tamilnadu_parotta','veechu_parotta'], true, NULL, 'flatbread', 348, 0, 2.2, 0.1, 82, 28, 2.2, 0, 0.0, 0, 14, 0.4, 62, 3.8, 0.04, 'South India', 'India'),
('ceylon_parotta_indian', 'Ceylon Parotta', 298, 6.8, 38.8, 12.8, 1.4, 0.8, 65, 130, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-parotta-reference', ARRAY['srilankan_parotta','ceylon_parata','eelam_parotta'], true, NULL, 'flatbread', 368, 0, 2.4, 0.1, 88, 28, 2.4, 0, 0.0, 0, 14, 0.4, 66, 3.8, 0.04, 'South India', 'India'),
('parotta_with_chicken_salna_indian', 'Parotta with Chicken Salna', 238, 11.4, 26.4, 10.2, 1.8, 1.6, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-street-food', ARRAY['parotta_chicken_salna','parotta_kari','parotta_with_salna_chicken'], true, NULL, 'street_food', 488, 52, 3.2, 0.0, 248, 42, 1.8, 42, 2.8, 0, 22, 1.0, 148, 9.8, 0.12, 'South India', 'India'),
('madurai_jigarthanda_indian', 'Madurai Jigarthanda', 168, 3.8, 28.4, 4.8, 0.4, 22.4, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Madurai-street-drinks', ARRAY['jigarthanda','jigarthanda_madurai','cold_almond_milk_jigarthanda'], true, NULL, 'beverage', 68, 18, 2.8, 0.0, 228, 148, 0.4, 28, 0.8, 0, 18, 0.4, 88, 2.4, 0.08, 'South India', 'India'),
('kal_dosa_tamilnadu_indian', 'Tamil Nadu Kal Dosa', 148, 4.2, 26.8, 3.2, 1.2, 0.4, 80, 160, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['kal_dosai','kal_dosa','stone_dosa_tamilnadu'], true, NULL, 'breakfast_dish', 278, 0, 0.6, 0.0, 88, 22, 1.0, 0, 0.0, 0, 14, 0.4, 58, 3.2, 0.02, 'South India', 'India'),
('kal_dosa_with_sambar_indian', 'Kal Dosa with Sambar', 158, 6.2, 26.2, 3.4, 2.8, 0.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['kal_dosai_sambar','kal_dosa_sambar'], true, NULL, 'breakfast_dish', 398, 2, 0.6, 0.0, 218, 48, 1.6, 18, 3.4, 0, 24, 0.6, 88, 4.2, 0.04, 'South India', 'India'),
('adai_tamilnadu_indian', 'Tamil Nadu Adai', 168, 8.4, 24.4, 4.2, 3.4, 0.6, 80, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['adai_dosai','mixed_lentil_crepe_tamilnadu','adai_tamilnadu'], true, NULL, 'breakfast_dish', 228, 0, 0.6, 0.0, 228, 42, 2.2, 8, 1.2, 0, 36, 0.8, 118, 5.8, 0.04, 'South India', 'India'),
('adai_aviyal_tamilnadu_indian', 'Adai with Aviyal', 178, 7.8, 24.8, 5.8, 3.8, 2.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-breakfast', ARRAY['adai_dosai_aviyal','adai_with_avial'], true, NULL, 'breakfast_dish', 248, 4, 1.4, 0.0, 288, 58, 2.0, 38, 5.4, 0, 38, 0.8, 128, 5.4, 0.06, 'South India', 'India'),
('vellam_dosai_indian', 'Vellam Dosai', 188, 3.8, 32.4, 5.2, 1.2, 14.8, 90, 120, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-traditional-breakfast', ARRAY['jaggery_dosa','vellam_dosa','sweet_dosa_jaggery'], true, NULL, 'breakfast_dish', 128, 0, 0.8, 0.0, 128, 28, 1.2, 0, 0.2, 0, 14, 0.4, 58, 3.0, 0.02, 'South India', 'India'),
('meen_kuzhambu_tamilnadu_indian', 'Tamil Nadu Meen Kuzhambu', 128, 12.4, 8.4, 5.2, 1.8, 1.6, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['meen_kulambu','fish_kuzhambu_tamilnadu','tamil_fish_curry'], true, NULL, 'seafood_dish', 548, 58, 1.4, 0.0, 388, 58, 1.4, 38, 4.8, 0, 32, 0.6, 168, 12.4, 0.42, 'South India', 'India'),
('chettinad_meen_kuzhambu_indian', 'Chettinad Meen Kuzhambu', 142, 13.8, 8.8, 6.2, 1.8, 1.4, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Chettinad-seafood-reference', ARRAY['chettinad_fish_kuzhambu','chettinad_meen_kulambu'], true, NULL, 'seafood_dish', 578, 62, 1.6, 0.0, 408, 64, 1.6, 42, 5.2, 0, 34, 0.8, 178, 13.8, 0.44, 'South India', 'India'),
('nethili_fry_tamilnadu_indian', 'Tamil Nadu Nethili Fry', 218, 22.4, 8.4, 10.8, 0.8, 0.6, NULL, 150, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['nethili_fish_fry','anchovies_fry_tamilnadu','nethali_fry'], true, NULL, 'seafood_dish', 648, 128, 2.2, 0.0, 468, 248, 3.4, 28, 2.4, 0, 44, 1.2, 288, 22.4, 0.48, 'South India', 'India'),
('nethili_kuzhambu_indian', 'Nethili Kuzhambu', 148, 14.8, 7.8, 6.4, 1.4, 1.2, NULL, 200, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-seafood', ARRAY['nethili_fish_curry','anchovy_curry_tamilnadu','nethali_kuzhambu'], true, NULL, 'seafood_dish', 568, 88, 1.6, 0.0, 428, 168, 2.4, 32, 3.8, 0, 38, 0.8, 248, 16.8, 0.44, 'South India', 'India'),
('vaazhaipoo_vadai_tamilnadu_indian', 'Tamil Nadu Vaazhaipoo Vadai', 242, 8.4, 22.8, 14.2, 4.8, 1.4, 40, 160, 4, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-snack', ARRAY['vazhaipoo_vada_tamilnadu','banana_flower_vada','banana_blossom_vadai'], true, NULL, 'snack', 328, 0, 2.4, 0.0, 388, 68, 3.2, 8, 4.8, 0, 42, 0.8, 118, 5.8, 0.04, 'South India', 'India'),
('tamilnadu_rice_murukku_indian', 'Tamil Nadu Rice Murukku', 468, 8.4, 62.4, 22.4, 2.4, 0.8, 10, 50, 5, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-snack', ARRAY['arisi_murukku','rice_murukku_tamilnadu','chakli_rice_tamilnadu'], true, NULL, 'snack', 488, 0, 4.8, 0.0, 148, 28, 2.8, 0, 0.4, 0, 28, 0.6, 88, 4.8, 0.04, 'South India', 'India'),
('paruppu_murukku_indian', 'Paruppu Murukku', 478, 9.8, 60.8, 22.8, 2.8, 0.8, 10, 50, 5, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-snack', ARRAY['dal_murukku','chana_dal_murukku','tamilnadu_paruppu_murukku'], true, NULL, 'snack', 468, 0, 4.4, 0.0, 168, 32, 3.2, 0, 0.2, 0, 32, 0.8, 98, 5.4, 0.04, 'South India', 'India'),
('mysore_pak_karnataka_indian', 'Mysore Pak', 528, 7.8, 58.4, 32.4, 1.4, 42.8, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-sweet-FSSAI-range', ARRAY['mysore_pak_sweet','mysore_paak','karnataka_mysore_pak'], true, NULL, 'sweet', 28, 48, 14.8, 0.1, 148, 38, 2.4, 22, 0.4, 0, 28, 0.8, 118, 5.2, 0.04, 'South India', 'India'),
('soft_mysore_pak_indian', 'Soft Mysore Pak', 498, 7.2, 56.8, 28.4, 1.2, 40.2, 50, 100, 2, 'manual', 'hyperregional-apr2026;recipe-estimated;Karnataka-sweet-FSSAI-range', ARRAY['soft_mysore_paak','ghee_mysore_pak_soft'], true, NULL, 'sweet', 24, 42, 13.2, 0.1, 138, 36, 2.2, 18, 0.4, 0, 26, 0.7, 112, 4.8, 0.04, 'South India', 'India'),
('thalappakatti_veg_biryani_indian', 'Thalappakatti Veg Biryani', 168, 4.8, 26.8, 5.2, 2.4, 1.6, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Dindigul-biryani-reference', ARRAY['thalappakatti_vegetable_biryani','dindigul_veg_biryani'], true, NULL, 'rice_dish', 388, 4, 1.4, 0.0, 228, 48, 1.4, 52, 4.8, 0, 28, 0.8, 108, 5.8, 0.06, 'South India', 'India'),
('thalappakatti_chicken_biryani_indian', 'Thalappakatti Chicken Biryani', 198, 10.4, 22.8, 7.4, 1.4, 0.8, NULL, 350, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Dindigul-biryani-reference', ARRAY['thalappakatti_chicken_biriyani'], true, NULL, 'rice_dish', 448, 46, 2.2, 0.0, 188, 30, 1.6, 36, 2.2, 0, 22, 1.2, 152, 9.4, 0.12, 'South India', 'India'),
('tamilnadu_sambar_rice_indian', 'Tamil Nadu Sambar Rice', 148, 5.8, 24.2, 3.2, 3.2, 1.4, NULL, 300, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rice-dish', ARRAY['tamilnadu_sambar_sadham','sambar_sadam'], true, NULL, 'rice_dish', 428, 2, 0.6, 0.0, 288, 58, 2.0, 22, 3.8, 0, 32, 0.6, 108, 5.2, 0.04, 'South India', 'India'),
('thayir_sadam_tamilnadu_indian', 'Tamil Nadu Thayir Sadam', 128, 3.8, 22.2, 2.8, 0.8, 2.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rice-dish', ARRAY['thayir_sadam','curd_rice_pomegranate_tamilnadu','mosaranna_style_tamilnadu'], true, NULL, 'rice_dish', 188, 8, 0.8, 0.0, 148, 88, 0.6, 8, 2.8, 0, 14, 0.4, 88, 2.8, 0.02, 'South India', 'India'),
('puliyodarai_tamilnadu_indian', 'Tamil Nadu Puliyodarai', 178, 3.8, 28.8, 6.2, 2.4, 2.2, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rice-dish', ARRAY['puliyodarai','pulikachal_rice','tamarind_rice_tamilnadu'], true, NULL, 'rice_dish', 548, 0, 0.8, 0.0, 228, 28, 2.2, 12, 2.8, 0, 24, 0.6, 88, 4.2, 0.06, 'South India', 'India'),
('elumichai_sadam_tamilnadu_indian', 'Tamil Nadu Elumichai Sadam', 168, 3.4, 28.4, 5.2, 1.4, 0.6, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rice-dish', ARRAY['elumichai_sadam','lemon_rice_tamilnadu','chitrannam_tamilnadu'], true, NULL, 'rice_dish', 388, 0, 0.6, 0.0, 148, 18, 1.0, 4, 4.8, 0, 18, 0.4, 68, 3.4, 0.04, 'South India', 'India'),
('thenga_sadam_tamilnadu_indian', 'Tamil Nadu Thenga Sadam', 192, 3.8, 26.4, 8.8, 1.8, 0.8, NULL, 250, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-rice-dish', ARRAY['thenga_sadam','coconut_rice_tamilnadu','thengai_sadam'], true, NULL, 'rice_dish', 228, 0, 5.4, 0.0, 168, 12, 0.8, 0, 1.2, 0, 18, 0.4, 72, 3.4, 0.08, 'South India', 'India'),
('kothamalli_chutney_indian', 'Kothamalli Chutney', 68, 2.4, 6.8, 3.8, 2.8, 1.4, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['coriander_chutney_tamilnadu','kothambari_chutney','kothamalli_thokku'], true, NULL, 'condiment', 288, 0, 0.4, 0.0, 248, 98, 1.8, 188, 22.4, 0, 28, 0.4, 48, 2.4, 0.06, 'South India', 'India'),
('tomato_kothamalli_chutney_indian', 'Tomato Kothamalli Chutney', 72, 2.2, 8.4, 3.2, 2.4, 3.8, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['tomato_coriander_chutney','tamatar_kothamalli_chutney'], true, NULL, 'condiment', 308, 0, 0.4, 0.0, 268, 52, 1.4, 128, 12.4, 0, 22, 0.4, 42, 2.0, 0.04, 'South India', 'India'),
('peanut_chutney_tamilnadu_indian', 'Tamil Nadu Peanut Chutney', 328, 12.8, 14.8, 26.4, 4.4, 3.2, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['kadala_chutney','verkadalai_chutney','peanut_chutney_tamilnadu'], true, NULL, 'condiment', 248, 0, 3.8, 0.0, 328, 48, 1.8, 0, 1.4, 0, 42, 1.2, 148, 4.8, 0.04, 'South India', 'India'),
('vengaya_thakkali_chutney_indian', 'Tamil Nadu Vengaya Thakkali Chutney', 88, 2.2, 10.4, 4.4, 2.2, 4.8, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['onion_tomato_chutney_tamilnadu','vengaya_thakkali_chutney'], true, NULL, 'condiment', 328, 0, 0.6, 0.0, 248, 42, 0.8, 82, 8.4, 0, 18, 0.3, 42, 1.8, 0.04, 'South India', 'India'),
('thengai_chutney_tamilnadu_indian', 'Tamil Nadu Thengai Chutney', 248, 3.8, 8.2, 22.8, 4.8, 2.4, NULL, 50, 1, 'manual', 'hyperregional-apr2026;recipe-estimated;Tamil-Nadu-condiment', ARRAY['thengai_chutney','coconut_chutney_tamilnadu','tengai_chutney'], true, NULL, 'condiment', 128, 0, 18.4, 0.0, 198, 18, 0.6, 0, 1.8, 0, 16, 0.4, 62, 2.4, 0.08, 'South India', 'India')
ON CONFLICT (food_name_normalized) DO NOTHING;
```
