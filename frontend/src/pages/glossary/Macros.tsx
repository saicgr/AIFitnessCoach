import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryMacros() {
  return (
    <GlossaryShell
      term="Macronutrients (Macros)"
      slug="macros"
      metaDescription="Macronutrients are protein, carbohydrates, and fat. The three energy-yielding nutrients that make up every calorie you eat. Learn calorie densities, evidence-based ratios, and how to set targets for your goal."
      relatedCalcSlug="macro-calculator"
      relatedCalcName="Macro Calculator"
      faqs={[
        { q: 'How much protein do I need to build muscle?', a: 'The strongest evidence supports 1.6 to 2.2 grams per kilogram of bodyweight per day for active lifters. Going higher rarely hurts, but the muscle-building return plateaus around 2.2 g per kg.' },
        { q: 'Are carbs bad for fat loss?', a: 'No. Calorie balance drives fat loss, not carb content. Lower-carb diets work for many people because they reduce appetite, not because of any unique metabolic advantage.' },
        { q: 'How low can I take dietary fat?', a: 'For health, do not drop below 0.5 g per kg bodyweight. Below that, hormones like testosterone can decline and fat-soluble vitamin absorption suffers.' },
        { q: 'Do I need to hit macros exactly every day?', a: 'No. Hit your protein target consistently. Carbs and fat are interchangeable calorie pools and a 20-gram daily swing in either is irrelevant for results.' },
        { q: 'Does alcohol count as a macro?', a: 'Technically alcohol is a fourth energy nutrient at 7 calories per gram. It is not classed as a macro because it has no essential biological role, but it does count against your calorie budget.' },
      ]}
    >
      <p>
        Macronutrients, usually shortened to macros, are the three nutrients that provide energy.
        Protein, carbohydrates, and fat. Every calorie in every food you eat comes from one of
        these three sources, plus alcohol if applicable. Tracking macros means tracking the grams
        of each rather than just total calories.
      </p>

      <h2>The full picture</h2>
      <p>
        <strong>Protein</strong> provides 4 calories per gram and supplies the amino acids your
        body uses for muscle repair, enzyme production, and immune function. It is the only macro
        with a clear dose-response for body composition. Hitting 1.6 to 2.2 grams per kilogram of
        bodyweight per day reliably outperforms lower intakes for muscle retention during cuts and
        muscle gain during bulks.
      </p>
      <p>
        <strong>Carbohydrates</strong> also provide 4 calories per gram. They are the
        preferred fuel for high-intensity exercise because they convert to glycogen and ATP fastest.
        Carb needs scale with training volume, not with morality. A powerlifter doing two-hour
        sessions needs 4 to 6 g per kg per day. A sedentary office worker can thrive on less than
        2 g per kg per day.
      </p>
      <p>
        <strong>Fat</strong> provides 9 calories per gram, more than double the others, because
        fat molecules are denser and more reduced. It supports hormone production, vitamin
        absorption, and cell membrane integrity. Aim for at least 0.5 to 0.8 g per kg per day for
        health, then fill remaining calories with whatever carb-to-fat ratio you prefer.
      </p>

      <h2>How macros are calculated</h2>
      <p>
        Standard approach. Set protein at 1.6 to 2.2 g per kg bodyweight. Set fat at 0.6 to 1.0 g
        per kg. Fill the remaining calories with carbs. <strong>Example:</strong> 80 kg lifter at
        2400 calories. Protein 160 g = 640 cal. Fat 70 g = 630 cal. Remaining 1130 cal ÷ 4 = 283 g
        carbs. Adjust the carb-to-fat ratio based on preference and training volume.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>"Clean" vs "dirty" macros do not exist for body composition. A gram of carbs from rice and a gram from candy have identical metabolic effects. Whole foods win on micronutrients, satiety, and fiber, not macros.</li>
        <li>You do not need a high-protein meal every 3 hours. Total daily protein matters far more than distribution, although 3 to 5 doses of 0.4 to 0.55 g per kg per meal optimize muscle protein synthesis.</li>
        <li>Cutting carbs does not directly burn fat. Lower carbs depletes glycogen and water, which is why the scale drops fast in the first week. Body fat only changes when calories are below TDEE.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Helms ER, Aragon AA, Fitschen PJ. (2014). <em>Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation</em>. JISSN, 11(20).</li>
        <li>Aragon AA, Schoenfeld BJ. (2013). <em>Nutrient timing revisited</em>. JISSN, 10(1), 5.</li>
        <li>Morton RW et al. (2018). <em>A systematic review, meta-analysis and meta-regression of the effect of protein supplementation</em>. BJSM, 52, 376-384.</li>
      </ul>
    </GlossaryShell>
  );
}
