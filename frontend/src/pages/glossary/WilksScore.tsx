import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryWilksScore() {
  return (
    <GlossaryShell
      term="Wilks Score"
      slug="wilks-score"
      metaDescription="The Wilks Score is a sex-adjusted coefficient that scales powerlifting totals so lifters of different bodyweights can be compared. Learn its history, the polynomial formula, and how Wilks compares to DOTS and IPF GL."
      relatedCalcSlug="wilks-calculator"
      relatedCalcName="Wilks Calculator"
      faqs={[
        { q: 'Is Wilks still used in powerlifting?', a: 'Less often. The IPF officially adopted IPF GL points in 2020 for international meets. Many federations still use Wilks for awards and informal comparison, and it remains the most widely known coefficient.' },
        { q: 'What is a good Wilks score?', a: 'For raw lifters, 300 is a strong intermediate, 400 is regional-meet competitive, 450 is national-class, and 500-plus is world-class. Equipped lifters trend 50 to 100 points higher.' },
        { q: 'Why was Wilks replaced?', a: 'The original Wilks coefficients overvalued heavier lifters and undervalued lighter classes, especially women. DOTS (2019) and IPF GL (2020) corrected these biases with newer regression curves.' },
        { q: 'Is Wilks fair across sexes?', a: 'Approximately. The female coefficients map elite female totals to similar Wilks values as elite male totals, but the data behind it is older and smaller. Modern formulas use larger competition datasets.' },
        { q: 'Can I compare my Wilks across years?', a: 'Yes within a single formula version. The 1994 original differs from Wilks-2 (2020). Always note which version a published score uses.' },
      ]}
    >
      <p>
        The Wilks Score is a numerical coefficient that scales a powerlifter's total (squat plus
        bench plus deadlift) to account for their bodyweight and sex. It exists to answer one
        question. If a 60 kg woman totals 400 kg and a 120 kg man totals 800 kg, who lifted more
        relative to their size?
      </p>

      <h2>The full picture</h2>
      <p>
        Mathematician Robin Wilks created the formula in 1994 for the International Powerlifting
        Federation. It uses a fifth-degree polynomial fit to elite competition results that
        outputs a coefficient. Your total in kilograms multiplied by this coefficient gives your
        Wilks score. Higher is better. Roughly speaking, an elite male at any weight class lands
        around 500. An elite female lands around 470.
      </p>
      <p>
        The Wilks Score dominated powerlifting comparison for 25 years. It was used to award
        "best lifter" at meets, to seed flight order, and to rank lifters across weight classes in
        team competitions. Its longevity came from being good enough across most of the curve,
        rather than being perfect.
      </p>
      <p>
        In the late 2010s, researchers noted that Wilks coefficients were calibrated against
        smaller and older datasets, and that they overvalued superheavy male lifters while
        undervaluing lightweight female lifters. The IPF responded with Wilks 2 in 2020, and
        independent coaches developed DOTS in 2019. The IPF then adopted GL points (Goodlift) as
        the official scoring system for international meets starting in 2020.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Wilks = total × 500 / (a + b·BW + c·BW² + d·BW³ + e·BW⁴ + f·BW⁵), where BW is bodyweight in
        kg and the six coefficients (a-f) differ by sex. The denominator is a polynomial fit to
        elite-lifter performance versus bodyweight. Total is in kg. Pounds users convert first
        (1 lb = 0.45359237 kg).
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>Wilks is not "absolute strength." It is strength relative to a curve of elite performance, so a 300 Wilks at 60 kg requires very different work than 300 at 120 kg.</li>
        <li>Wilks is not directly comparable to DOTS or IPF GL. The point scales are similar in magnitude but the underlying curves are different.</li>
        <li>A high Wilks does not mean you "would beat" anyone with a lower Wilks. Strength sports are tested by total at a meet, not by coefficient.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Wilks R. (1994). <em>Wilks Coefficient</em>. International Powerlifting Federation technical documentation.</li>
        <li>Vanderburgh PM, Batterham AM. (1999). <em>Validation of the Wilks powerlifting formula</em>. Med Sci Sports Exerc, 31(12), 1869-1875.</li>
        <li>International Powerlifting Federation. (2020). <em>Goodlift (IPF GL) scoring system documentation</em>.</li>
      </ul>
    </GlossaryShell>
  );
}
