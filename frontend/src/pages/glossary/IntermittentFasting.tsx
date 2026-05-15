import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryIntermittentFasting() {
  return (
    <GlossaryShell
      term="Intermittent Fasting"
      slug="intermittent-fasting"
      metaDescription="Intermittent fasting compresses daily eating into a fixed window. Learn the common protocols (16:8, 18:6, OMAD), the metabolic phases the body cycles through, and who actually benefits."
      relatedCalcSlug="fasting-timer"
      relatedCalcName="Intermittent Fasting Timer"
      faqs={[
        { q: 'Does intermittent fasting boost fat loss?', a: 'Indirectly. IF works because it reduces calorie intake by shrinking the eating window. Calorie-matched studies show no fat loss advantage over standard dieting.' },
        { q: 'Will I lose muscle while fasting?', a: 'Not on 16:8 or 18:6 with adequate protein. Risk grows past 24 hours fasted, especially without resistance training. Hit 1.6 to 2.2 g protein per kg total daily intake.' },
        { q: 'When does autophagy kick in?', a: 'Cellular autophagy is upregulated after roughly 16 to 24 hours of fasting in animal models. Human data is less clear because measuring autophagy in vivo is difficult.' },
        { q: 'Can I train fasted?', a: 'Yes. Most lifters tolerate fasted training fine for 60 to 90 minute sessions. For intense work over 90 minutes, having some carbs and protein 1 to 2 hours pre-session improves performance.' },
        { q: 'Is OMAD healthy long term?', a: 'Eating one large meal per day makes it hard to hit protein targets and micronutrient needs. It can work short term but is harder to sustain than 16:8 for most people.' },
      ]}
    >
      <p>
        Intermittent fasting (IF) is an eating pattern that alternates periods of eating with
        periods of voluntary fasting. It does not specify what to eat, just when. The most common
        protocols compress all daily calories into a 4 to 10 hour window, leaving 14 to 20 hours
        for water, black coffee, and tea only.
      </p>

      <h2>The full picture</h2>
      <p>
        The popular protocols. <strong>16:8</strong> fasts for 16 hours and eats in an 8-hour
        window. <strong>18:6</strong> fasts for 18, eats in 6. <strong>20:4</strong> fasts for 20,
        eats in 4 (Warrior Diet). <strong>OMAD</strong> is One Meal A Day, around 22 to 23 hours
        fasted. <strong>5:2</strong> eats normally five days a week and restricts to 500 to 600
        calories on two non-consecutive days. <strong>Alternate Day Fasting</strong> alternates
        full eating days with full fasting days.
      </p>
      <p>
        The body cycles through metabolic phases during a fast. <strong>0 to 4 hours.</strong>
        Postprandial. Glucose and insulin elevated, fat storage favored. <strong>4 to 12
        hours.</strong> Glycogen mobilization, insulin drops, fat oxidation rises. <strong>12 to
        24 hours.</strong> Glycogen depletion, gluconeogenesis ramps, ketone production begins.
        <strong> 24-plus hours.</strong> Ketosis deepens, autophagy upregulates, growth hormone
        rises. Most IF protocols never reach the 24-hour line on a daily basis.
      </p>
      <p>
        Calorie-matched trials are consistent. When daily calorie intake is the same, fat loss is
        the same on IF and on standard dieting. The mechanism behind IF's real-world success is
        simpler. Most people find it easier to eat fewer calories when the window is short. No
        breakfast plus no late snack equals 400 to 700 fewer daily calories for many.
      </p>

      <h2>Who it works for</h2>
      <p>
        IF suits people who naturally do not feel hungry in the morning, who hate breakfast, and
        whose social eating happens at night. It is a poor fit for early-morning trainers,
        teenagers, pregnant or breastfeeding women, people with a history of eating disorders, and
        those with diabetes managed by insulin.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>IF does not raise metabolism. Short fasts of 24 to 48 hours produce small adrenaline-mediated boosts that are gone the moment you eat.</li>
        <li>Black coffee with under 5 calories does not break the fast in any practical metabolic sense. Cream and sugar do.</li>
        <li>IF is not a magic protocol. It is a calorie-reduction strategy that works because the window structure suppresses snacking.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Anton SD et al. (2018). <em>Flipping the metabolic switch: understanding and applying health benefits of fasting</em>. Obesity, 26(2), 254-268.</li>
        <li>Mattson MP, Longo VD, Harvie M. (2017). <em>Impact of intermittent fasting on health and disease processes</em>. Ageing Res Rev, 39, 46-58.</li>
        <li>Mizushima N. (2011). <em>Autophagy: process and function</em>. Genes Dev, 21(22), 2861-2873.</li>
      </ul>
    </GlossaryShell>
  );
}
