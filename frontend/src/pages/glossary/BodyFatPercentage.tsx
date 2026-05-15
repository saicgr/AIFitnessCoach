import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryBodyFatPercentage() {
  return (
    <GlossaryShell
      term="Body Fat Percentage"
      slug="body-fat-percentage"
      metaDescription="Body fat percentage is the share of your bodyweight that is fat tissue. Learn the five common measurement methods (DEXA, BIA, calipers, Navy, RFM), their accuracy, and healthy ranges for men and women."
      relatedCalcSlug="body-fat-calculator"
      relatedCalcName="Body Fat % Calculator"
      faqs={[
        { q: 'What is a healthy body fat percentage?', a: 'For men, 10 to 20 percent is athletic to healthy. For women, 18 to 28 percent. Essential fat sits at 3 percent for men and 12 percent for women below which hormones and health suffer.' },
        { q: 'How accurate is DEXA?', a: 'DEXA error is around 1 to 2 percent body fat in healthy adults. It is the practical gold standard short of cadaver dissection. Hydration and meal timing can shift readings 1 to 2 percent.' },
        { q: 'Are scales with body fat accurate?', a: 'Consumer bioelectrical impedance scales have errors of 3 to 8 percent body fat. They are useful for tracking trends over time, not for absolute readings.' },
        { q: 'Why do the methods disagree?', a: 'Each method measures something different. Calipers measure subcutaneous fat. BIA measures water and conductivity. DEXA measures X-ray attenuation. Then each estimates total body fat through a different equation.' },
        { q: 'How fast can body fat percentage change?', a: 'Realistically 1 to 2 percentage points per month during a focused cut. Drops faster than that are usually water and glycogen, not fat.' },
      ]}
    >
      <p>
        Body fat percentage is the share of your total bodyweight that is fat tissue, as opposed to
        lean tissue like muscle, bone, organs, and water. For a 200-pound person at 20 percent
        body fat, 40 pounds is fat and 160 pounds is fat-free mass.
      </p>

      <h2>The full picture</h2>
      <p>
        Body fat is not all the same. Essential fat sits inside organs, nerves, and bone marrow
        and is non-negotiable for life. Below 3 percent body fat in men and 12 percent in women,
        hormonal and immune problems appear quickly. Storage fat lives subcutaneously and in
        visceral depots and is what cutting and bulking phases change.
      </p>
      <p>
        Healthy ranges depend on sex. Men. 3 to 5 percent essential, 6 to 13 percent athletic, 14
        to 17 percent fit, 18 to 24 percent average, 25-plus percent obese. Women. 12 percent
        essential, 14 to 20 percent athletic, 21 to 24 percent fit, 25 to 31 percent average,
        32-plus percent obese. Women carry more essential fat for reproductive function.
      </p>
      <p>
        Measurement methods differ in cost, access, and accuracy. <strong>DEXA</strong> is the
        practical gold standard, available at sports clinics for $50 to $150 per scan.
        <strong> Hydrostatic weighing</strong> and <strong>BodPod</strong> are similarly accurate
        but rarer. <strong>Skinfold calipers</strong> (Jackson-Pollock 3 or 7 site) cost $10 and
        give 3 to 4 percent error in trained hands. <strong>Bioelectrical impedance (BIA)</strong>
        is fast but heavily affected by hydration. <strong>Navy method</strong> uses tape
        measurements and gives 3 to 5 percent error. <strong>RFM</strong> (Relative Fat Mass) uses
        height and waist for a quick approximation.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Navy method (men). BF% = 86.010 × log10(waist − neck) − 70.041 × log10(height) + 36.76.
        Navy method (women). BF% = 163.205 × log10(waist + hip − neck) − 97.684 × log10(height) −
        78.387. Jackson-Pollock uses 3 or 7 skinfold sites fed into a body density equation, then
        Siri's formula converts density to percent body fat.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>The bathroom scale's body fat reading is not measuring fat. It is measuring electrical resistance through your body and inferring fat. Hydration, meals, and skin temperature shift it by several percent.</li>
        <li>"Visible abs" is not a fixed body fat percentage. Genetic ab structure, ab thickness, and skin thickness vary. Some men show abs at 15 percent. Others need 9 percent.</li>
        <li>Body fat percentage is not the only health marker. Two people at 20 percent body fat can have very different visceral fat distributions and metabolic profiles.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Jackson AS, Pollock ML. (1978). <em>Generalized equations for predicting body density of men</em>. Br J Nutr, 40, 497-504.</li>
        <li>Hodgdon JA, Beckett MB. (1984). <em>Prediction of percent body fat for U.S. Navy men and women from body circumferences and height</em>. Naval Health Research Center.</li>
        <li>Woolcott OO, Bergman RN. (2018). <em>Relative fat mass (RFM) as a new estimator of whole-body fat percentage</em>. Sci Rep, 8, 10980.</li>
      </ul>
    </GlossaryShell>
  );
}
