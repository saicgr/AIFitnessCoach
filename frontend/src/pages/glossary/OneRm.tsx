import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryOneRm() {
  return (
    <GlossaryShell
      term="One-Rep Max (1RM)"
      slug="1rm"
      metaDescription="One-Rep Max (1RM) is the maximum weight you can lift for a single repetition with full range of motion. Learn how to estimate or test it, the Epley and Brzycki formulas, and how lifters use 1RM to program every set."
      relatedCalcSlug="1rm-calculator"
      relatedCalcName="1RM Calculator"
      faqs={[
        { q: 'How accurate are 1RM estimates?', a: 'Estimates from sets of 1 to 5 reps are within roughly 5 percent of a true tested max. Beyond 10 reps the error grows quickly, because muscular endurance starts dominating over pure strength.' },
        { q: 'Should I actually test my 1RM?', a: 'Most trained lifters test once or twice a year, or before a competition. Day to day, estimates from a heavy top set are safer, faster, and almost as accurate.' },
        { q: 'Is Epley or Brzycki more accurate?', a: 'Brzycki tends to predict slightly lower than Epley above 5 reps. For most lifters the difference is under 3 percent. Pick one and stay consistent so your numbers are comparable over time.' },
        { q: 'Does 1RM change day to day?', a: 'Yes. Sleep, fueling, stress, and prior training can swing your true max by 5 to 10 percent. That is why programs use percentages of a recent estimated max, not a single fixed number.' },
        { q: 'Can beginners use 1RM percentages?', a: 'Beginners can use percentages, but their max climbs so fast that the chart is stale within a week or two. Most coaches prefer RPE or RIR-based loading for true novices.' },
      ]}
    >
      <p>
        A one-rep max, or 1RM, is the heaviest weight you can lift for a single full-range
        repetition of a given exercise. It is the universal benchmark for strength and the anchor
        point for almost every percentage-based training program.
      </p>

      <h2>The full picture</h2>
      <p>
        Strength scientists treat 1RM as the gold-standard measure of maximal force production for
        a specific movement. Powerlifters compete on the sum of their squat, bench, and deadlift
        1RMs. Hypertrophy lifters use percentages of 1RM to load sets in the productive 60 to 85
        percent zone. Even rehab and youth programs reference 1RM, just with very conservative
        target percentages.
      </p>
      <p>
        You can either test a true 1RM by ramping up to a max single, or you can estimate one from
        a submaximal set taken close to failure. Testing is precise but fatiguing and risky.
        Estimating from a 3 to 5 rep top set is far more common in real training and accurate to
        within a few percent.
      </p>
      <p>
        Different lifts behave differently. Deadlift estimates tend to overshoot a tested max
        because grip and lower-back endurance fall apart faster than the legs. Bench press
        estimates are usually closest to reality. Squat sits in the middle.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Two formulas dominate practice. <strong>Epley:</strong> 1RM = weight × (1 + reps / 30).
        <strong> Brzycki:</strong> 1RM = weight × 36 / (37 − reps). For a 225 pound bench press
        for 5 reps, Epley gives 263 pounds and Brzycki gives 253 pounds.
      </p>
      <p>
        Both formulas are most accurate between 1 and 5 reps. Once you go above 8 reps,
        muscular endurance starts contaminating the signal and estimates drift high. The widely
        cited validity band is plus or minus 5 percent for sets of 2 to 6 reps when taken to
        within 1 to 2 reps of failure.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>A 1RM is not your true ceiling. It is what you produced on one day, with that warm-up, that bar speed, and that fueling. Real max output fluctuates daily.</li>
        <li>Higher 1RM does not always mean more muscle. Neural efficiency, leverage, and technique account for a large share of strength differences between lifters of similar size.</li>
        <li>You do not need to test 1RM to train hard. Most hypertrophy and even most powerlifting work happens at 70 to 85 percent of an estimated max.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Epley B. (1985). <em>Poundage Chart</em>. Boyd Epley Workout. Lincoln, NE.</li>
        <li>Brzycki M. (1993). <em>Strength testing: predicting a one-rep max from reps to fatigue</em>. JOPERD, 64(1), 88-90.</li>
        <li>LeSuer DA et al. (1997). <em>The accuracy of prediction equations for estimating 1-RM performance in the bench press, squat, and deadlift</em>. JSCR, 11(4), 211-213.</li>
      </ul>
    </GlossaryShell>
  );
}
