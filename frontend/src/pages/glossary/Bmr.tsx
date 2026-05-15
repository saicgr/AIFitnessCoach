import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryBmr() {
  return (
    <GlossaryShell
      term="Basal Metabolic Rate (BMR)"
      slug="bmr"
      metaDescription="Basal Metabolic Rate is the calories your body burns at total rest to keep organs, brain, and cells functioning. Learn the Mifflin-St Jeor, Harris-Benedict, Katch-McArdle, and Cunningham equations."
      relatedCalcSlug="bmr-calculator"
      relatedCalcName="BMR Calculator"
      faqs={[
        { q: 'Is BMR the same as RMR?', a: 'Almost. BMR is measured after an overnight fast in a thermo-neutral room. RMR is measured under more relaxed conditions and runs about 10 percent higher. Most calculators report RMR but label it BMR.' },
        { q: 'Why is BMR so much of TDEE?', a: 'Brain, liver, heart, kidneys, and digestion run nonstop and burn calories around the clock. For a sedentary office worker, BMR is 70 percent or more of total daily burn.' },
        { q: 'Does muscle really boost BMR?', a: 'Yes, but modestly. Each pound of muscle burns roughly 6 calories per day at rest. Adding 10 pounds of muscle adds about 60 calories per day, not the 500 some claims suggest.' },
        { q: 'Which BMR formula is most accurate?', a: 'Mifflin-St Jeor is the most accurate for the general population. Katch-McArdle is more accurate if you know your body fat percentage, because it uses lean body mass directly.' },
        { q: 'Does BMR drop on a long diet?', a: 'Yes. Beyond just losing tissue, the body adapts by 5 to 15 percent below predicted BMR during prolonged deficits, called adaptive thermogenesis.' },
      ]}
    >
      <p>
        Basal Metabolic Rate, or BMR, is the number of calories your body burns at complete rest to
        keep its essential processes running. Heart beating, lungs breathing, kidneys filtering,
        brain firing, cells dividing. BMR is what you would burn if you stayed in bed all day in a
        warm dark room.
      </p>

      <h2>The full picture</h2>
      <p>
        Your organs are surprisingly metabolic. The brain alone burns around 300 to 500 calories
        per day. The liver, heart, and kidneys together burn another 1000 calories per day. These
        organs do not stop just because you are not moving, which is why BMR is the largest single
        component of Total Daily Energy Expenditure.
      </p>
      <p>
        BMR scales with body size, lean tissue, sex, and age. Bigger people burn more. Men burn
        more than women of the same weight because they carry more lean mass on average. Older
        adults burn less, partly from muscle loss and partly from cellular changes. By age 60,
        BMR is typically 10 to 15 percent lower than at age 30 in untrained populations.
      </p>
      <p>
        Crash diets can drop BMR meaningfully. After 6 to 12 months of aggressive caloric
        restriction, BMR sits 10 to 15 percent below what equations predict for your new
        bodyweight. This is adaptive thermogenesis, and it is one of the main reasons aggressive
        cuts produce post-diet rebound weight gain.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Four equations dominate practice. <strong>Mifflin-St Jeor</strong> uses weight, height,
        age, and sex and is the modern default for the general population. <strong>Harris-Benedict
        (revised 1984)</strong> uses the same inputs but slightly different coefficients and tends
        to overestimate in obese populations. <strong>Katch-McArdle</strong> bypasses sex
        adjustments by using lean body mass directly, so it needs a body fat percentage.
        <strong> Cunningham</strong> is similar to Katch-McArdle but uses different coefficients
        and is preferred for athletes.
      </p>
      <p>
        Mifflin-St Jeor formula. <strong>Men:</strong> 10 × kg + 6.25 × cm − 5 × age + 5.
        <strong> Women:</strong> 10 × kg + 6.25 × cm − 5 × age − 161.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>BMR does not predict how easily you gain or lose weight. NEAT and TEF vary far more between people than BMR does at the same body size.</li>
        <li>You cannot meaningfully "boost BMR" with green tea, cayenne, or supplements. Effects are real but tiny, in the 30 to 80 calorie per day range at best.</li>
        <li>BMR does not collapse from skipping breakfast or eating less often. Meal timing has almost no measured effect on resting energy expenditure.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Mifflin MD et al. (1990). <em>A new predictive equation for resting energy expenditure in healthy individuals</em>. AJCN, 51(2), 241-247.</li>
        <li>Cunningham JJ. (1991). <em>Body composition as a determinant of energy expenditure</em>. AJCN, 54, 963-969.</li>
        <li>Rosenbaum M, Leibel RL. (2010). <em>Adaptive thermogenesis in humans</em>. Int J Obes, 34, S47-S55.</li>
      </ul>
    </GlossaryShell>
  );
}
