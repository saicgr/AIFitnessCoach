import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryTdee() {
  return (
    <GlossaryShell
      term="Total Daily Energy Expenditure (TDEE)"
      slug="tdee"
      metaDescription="Total Daily Energy Expenditure is every calorie your body burns in 24 hours, including resting metabolism, food digestion, exercise, and unconscious movement. Learn the four components and the Mifflin-St Jeor formula."
      relatedCalcSlug="tdee-calculator"
      relatedCalcName="TDEE Calculator"
      faqs={[
        { q: 'What is the difference between BMR and TDEE?', a: 'BMR is the calories you burn at complete rest. TDEE is BMR plus the calories you burn digesting food, moving around, and exercising. TDEE is always higher.' },
        { q: 'How accurate are TDEE calculators?', a: 'Predicted TDEE is within plus or minus 10 percent for most adults. Real-world tracking over 2 to 3 weeks of stable weight is far more accurate than any formula.' },
        { q: 'Does TDEE change as I lose weight?', a: 'Yes. Smaller bodies burn fewer calories at rest and during movement. Expect TDEE to fall by roughly the calories of the tissue you lost, plus a small adaptive thermogenesis bonus.' },
        { q: 'Which activity multiplier should I use?', a: 'Be honest. Most desk workers who lift 3 to 4 times a week land at 1.4 to 1.55, not 1.7. Overestimating activity is the number one reason cuts stall.' },
        { q: 'Should I eat at TDEE to maintain?', a: 'Yes, that is the definition of maintenance calories. Eat below it to lose weight, above it to gain. A 300 to 500 calorie deficit is the standard sustainable cut.' },
      ]}
    >
      <p>
        Total Daily Energy Expenditure, or TDEE, is the total number of calories your body burns in
        a 24-hour period. It is the single most important number for anyone trying to lose weight,
        gain muscle, or maintain, because every diet decision is just TDEE plus or minus a deficit.
      </p>

      <h2>The full picture</h2>
      <p>
        TDEE has four components. <strong>Basal Metabolic Rate (BMR)</strong> is the energy your
        body burns at total rest, accounting for 60 to 75 percent of TDEE in most adults.
        <strong> Thermic Effect of Food (TEF)</strong> is the energy cost of digesting and storing
        what you ate, around 10 percent of intake. <strong>Exercise Activity Thermogenesis
        (EAT)</strong> is structured workouts. <strong>Non-Exercise Activity Thermogenesis
        (NEAT)</strong> is fidgeting, walking, standing, and posture, and it is the most variable
        component, ranging from 100 to over 1000 calories per day between individuals.
      </p>
      <p>
        TDEE is not fixed. It drifts down during a cut as you lose tissue and unconsciously move
        less, and it drifts up during a bulk. Diet breaks, refeeds, and reverse dieting all exist
        to counter this drift.
      </p>
      <p>
        Wearables can estimate TDEE through heart rate and motion, but the error bars are large.
        The most reliable real-world method is two weeks of honest calorie logging at stable
        weight. Your average intake during that window is your true TDEE.
      </p>

      <h2>How it is calculated</h2>
      <p>
        TDEE = BMR × activity multiplier. The Mifflin-St Jeor BMR equation is the modern standard.
        <strong> For men:</strong> BMR = 10 × kg + 6.25 × cm − 5 × age + 5. <strong>For women:</strong>
        BMR = 10 × kg + 6.25 × cm − 5 × age − 161. Then multiply BMR by 1.2 for sedentary, 1.375
        for light activity, 1.55 for moderate, 1.725 for very active, and 1.9 for athletes.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>TDEE is not "metabolism" in the lay sense. Two people with identical body comp can have TDEE that differs by 600 calories purely from NEAT.</li>
        <li>Cardio does not "boost metabolism" the next day. Most calorie burn happens during the session, not afterward. EPOC for steady cardio is small.</li>
        <li>You cannot meaningfully raise TDEE by eating more frequent small meals. TEF is proportional to total intake, not meal count.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Mifflin MD et al. (1990). <em>A new predictive equation for resting energy expenditure in healthy individuals</em>. AJCN, 51(2), 241-247.</li>
        <li>Hall KD. (2007). <em>Mathematical modelling of weight loss under caloric restriction</em>. Am J Physiol Endocrinol Metab, 293, E1495-E1506.</li>
        <li>Levine JA. (2002). <em>Non-exercise activity thermogenesis</em>. Best Pract Res Clin Endocrinol Metab, 16(4), 679-702.</li>
      </ul>
    </GlossaryShell>
  );
}
