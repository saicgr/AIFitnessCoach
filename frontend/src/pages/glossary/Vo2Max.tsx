import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryVo2Max() {
  return (
    <GlossaryShell
      term="VO2 Max"
      slug="vo2-max"
      metaDescription="VO2 max is the maximum volume of oxygen your body can use per minute during intense exercise. The single best lab marker of aerobic fitness. Learn measurement protocols (Cooper, Bruce, Queens College) and trainability."
      relatedCalcSlug="vo2-max-calculator"
      relatedCalcName="VO2 Max Calculator"
      faqs={[
        { q: 'What is a good VO2 max?', a: 'For 30-year-old men, 45 to 50 mL/kg/min is good and 55-plus is excellent. For women the same age, 38 to 42 is good and 48-plus is excellent. Elite endurance athletes reach 70 to 90.' },
        { q: 'How much can VO2 max improve?', a: 'Untrained adults can raise VO2 max by 15 to 25 percent over 6 to 12 months. Genetic ceilings cap the long-term improvement. Roughly 50 percent of VO2 max is heritable.' },
        { q: 'How is VO2 max measured?', a: 'Gold standard is a graded exercise test with a metabolic cart measuring oxygen and CO2. Field tests like the Cooper 12-minute run, Bruce treadmill protocol, and Queens College step test estimate it within 5 to 10 percent.' },
        { q: 'Does VO2 max predict longevity?', a: 'Yes, strongly. Each one-MET increase in VO2 max associates with a 10 to 25 percent reduction in all-cause mortality in long-term studies. It is one of the most powerful health markers.' },
        { q: 'How do I improve VO2 max?', a: 'High-intensity intervals at 90 to 95 percent of max heart rate (4x4 minute or 30/30 protocols) raise VO2 max fastest. Pair with Zone 2 base training for durability.' },
      ]}
    >
      <p>
        VO2 max is the maximum volume of oxygen your body can consume and use per minute during
        all-out exercise. It is measured in milliliters of oxygen per kilogram of bodyweight per
        minute (mL/kg/min) and is the single best lab marker of cardiorespiratory fitness.
      </p>

      <h2>The full picture</h2>
      <p>
        Oxygen is the limiting reagent for aerobic energy production. The more your heart can
        pump, the more oxygen your blood can carry, and the more your muscles can extract, the
        higher your VO2 max. Three systems set the ceiling. <strong>Cardiac output</strong> (heart
        stroke volume × rate), <strong>oxygen-carrying capacity</strong> (hemoglobin and blood
        volume), and <strong>peripheral oxygen extraction</strong> (mitochondrial density and
        capillary supply in trained muscles).
      </p>
      <p>
        Typical ranges in mL/kg/min. Sedentary adult male age 30: 35 to 40. Active male age 30: 45
        to 50. Highly trained male age 30: 55 to 65. Elite male endurance athlete: 70 to 90.
        Women run 5 to 10 percent lower at matched training status, mostly because of smaller
        heart size and lower hemoglobin.
      </p>
      <p>
        VO2 max is heavily trainable. Untrained adults gain 15 to 25 percent in 6 to 12 months of
        proper cardiovascular training. Then genetics increasingly cap the ceiling. The HERITAGE
        Family Study estimated that 47 percent of VO2 max trainability variance is heritable.
        Elite endurance athletes are partly built and partly born.
      </p>
      <p>
        VO2 max also drops with age, roughly 10 percent per decade after 30 in untrained adults.
        Lifelong endurance athletes hold VO2 max far better, losing closer to 5 percent per decade.
      </p>

      <h2>How it is measured</h2>
      <p>
        Lab gold standard. Graded exercise test on treadmill or bike with a face mask measuring
        inhaled and exhaled gases. Exercise intensity ramps until VO2 plateaus despite continuing
        workload. <strong>Field estimates.</strong> Cooper 12-minute run: VO2 max = (distance in
        meters − 504.9) / 44.73. Bruce protocol treadmill test uses time to exhaustion.
        Queens College step test uses heart rate after 3 minutes of stepping at a set cadence.
        Apple Watch and Garmin estimate VO2 max from heart rate at submaximal effort.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>A high VO2 max does not guarantee a fast marathon. Race performance also depends on lactate threshold and movement economy. Two athletes with identical VO2 max can finish 20 minutes apart over 26.2 miles.</li>
        <li>Strength training does not raise VO2 max meaningfully. The aerobic adaptations come from sustained cardiovascular work.</li>
        <li>Wearable VO2 max is an estimate, not a measurement. Real lab tests can differ by 5 to 15 mL/kg/min from what a watch displays.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Cooper KH. (1968). <em>A means of assessing maximal oxygen intake</em>. JAMA, 203(3), 201-204.</li>
        <li>American College of Sports Medicine. (2017). <em>ACSM's Guidelines for Exercise Testing and Prescription</em>, 10th ed. Wolters Kluwer.</li>
        <li>Bouchard C et al. (1999). <em>Familial aggregation of VO2max response to exercise training: results from the HERITAGE Family Study</em>. J Appl Physiol, 87(3), 1003-1008.</li>
      </ul>
    </GlossaryShell>
  );
}
