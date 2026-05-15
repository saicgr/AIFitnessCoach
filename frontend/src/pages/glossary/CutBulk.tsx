import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryCutBulk() {
  return (
    <GlossaryShell
      term="Cutting and Bulking"
      slug="cut-bulk"
      metaDescription="Cutting is an intentional fat-loss phase. Bulking is an intentional muscle-gain phase. Learn sustainable rates (0.5 to 1 percent bodyweight per week to lose, 0.25 to 0.5 percent to gain) and when to recomp instead."
      relatedCalcSlug="cut-bulk-duration-calculator"
      relatedCalcName="Cut / Bulk Duration Calculator"
      faqs={[
        { q: 'How fast should I lose weight on a cut?', a: 'Aggressive cuts can run at 1 percent of bodyweight per week. Sustainable cuts sit at 0.5 to 0.75 percent. Faster than 1 percent and lean mass loss accelerates, especially below 12 percent body fat.' },
        { q: 'How fast should I gain weight on a bulk?', a: 'For beginners, 0.5 to 1 percent of bodyweight per month. For intermediates, 0.25 to 0.5 percent. Anything faster is fat gain. Muscle gain caps at roughly 1 to 2 pounds per month in trained lifters.' },
        { q: 'Can I build muscle and lose fat at the same time?', a: 'Yes, called recomposition. It works best in novices, returning lifters, overweight people, and those running aggressive protein with smart resistance training. It is slower than dedicated phases.' },
        { q: 'How long should a cut last?', a: 'Aim to finish within 12 to 16 weeks. Past that, adherence drops and hormonal adaptation makes further loss inefficient. Take a 2-week diet break at maintenance, then continue if needed.' },
        { q: 'Mini cut or long cut?', a: 'Mini cuts (4 to 6 weeks, larger deficit) work well to strip 3 to 5 pounds before a bulk. Long cuts (12 to 16 weeks, moderate deficit) suit getting visibly lean.' },
      ]}
    >
      <p>
        Cutting and bulking are the two intentional phases of body composition change. A cut is a
        calorie deficit aimed at losing body fat while preserving muscle. A bulk is a calorie
        surplus aimed at building muscle, ideally with minimal fat gain. Together they make up
        traditional periodized physique programming.
      </p>

      <h2>The full picture</h2>
      <p>
        The reason most physique athletes alternate phases is simple. The conditions that
        maximize muscle gain (calorie surplus, full glycogen, recovery capacity) are the opposite
        of those that maximize fat loss (calorie deficit, hunger, reduced recovery). Trying to do
        both at once works for novices but plateaus quickly. Dedicated phases sidestep the
        compromise.
      </p>
      <p>
        Sustainable cut rates sit at 0.5 to 1 percent of bodyweight per week. A 180-pound lifter
        targets 0.9 to 1.8 pounds of weekly loss. The deficit needed is roughly 500 to 1000
        calories per day. Past 1 percent per week, lean mass loss climbs sharply, especially when
        body fat dips below 12 percent in men or 20 percent in women.
      </p>
      <p>
        Bulk rates are slower because muscle gain is biologically rate-limited. Novices can add
        muscle at 1 to 2 pounds per month. Intermediates manage 0.5 to 1 pound per month.
        Advanced lifters fight for 0.25 pounds per month. Eating in a surplus larger than what
        muscle can absorb just produces fat.
      </p>
      <p>
        <strong>Recomposition</strong> is the third option. Eat at maintenance, train hard, hit
        high protein. Net body fat drops while net muscle climbs. It works best for novices,
        returning lifters, overweight beginners, and anyone with substantial untapped muscle
        memory.
      </p>

      <h2>How rates are calculated</h2>
      <p>
        A 1-pound weekly weight loss requires a roughly 500-calorie daily deficit, because a pound
        of fat stores around 3500 calories. <strong>For a cut:</strong> 7700 cal per kg ÷ 7 days =
        1100 cal per kg per day, scaled to your target weekly loss in kg. <strong>For a
        bulk:</strong> roughly a 250-calorie surplus to gain a half pound per week, with most of
        that going to lean tissue if training is in order.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>"Dirty bulks" do not build more muscle. Above a moderate surplus, additional calories overwhelmingly land as fat.</li>
        <li>"Lean bulks" do not build measurably less muscle than dirty bulks, but they leave you with far less fat to cut later. Math wins on net physique.</li>
        <li>Cutting does not destroy muscle if protein stays at 2.0 to 2.4 g per kg and you keep training heavy. Loss is small even at 1 percent per week.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Garthe I et al. (2011). <em>Effect of two different weight-loss rates on body composition and strength and power-related performance in elite athletes</em>. Int J Sport Nutr Exerc Metab, 21(2), 97-104.</li>
        <li>Helms ER, Aragon AA, Fitschen PJ. (2014). <em>Evidence-based recommendations for natural bodybuilding contest preparation</em>. JISSN, 11(20).</li>
        <li>Aragon AA, Schoenfeld BJ. (2013). <em>Nutrient timing revisited</em>. JISSN, 10(1), 5.</li>
      </ul>
    </GlossaryShell>
  );
}
