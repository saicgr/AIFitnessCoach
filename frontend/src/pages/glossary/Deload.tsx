import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryDeload() {
  return (
    <GlossaryShell
      term="Deload"
      slug="deload"
      metaDescription="A deload is a planned reduction in training volume or intensity to dissipate accumulated fatigue and enable supercompensation. Learn when to deload, what signals indicate one, and how to structure a deload week."
      relatedCalcSlug="deload-week-calculator"
      relatedCalcName="Deload Week Calculator"
      faqs={[
        { q: 'How often should I deload?', a: 'Most intermediates need a deload every 4 to 6 weeks. Advanced lifters often need one every 3 to 4 weeks. Novices on linear progression often need none for months at a time.' },
        { q: 'Will I lose gains during a deload?', a: 'No. Strength holds for at least 2 to 3 weeks at maintenance volume. Muscle is retained even longer. A 7-day deload is well within the safe zone.' },
        { q: 'Volume deload or intensity deload?', a: 'For hypertrophy and bodybuilding, cut volume to 50 to 60 percent. For powerlifting peaking, keep weight high but cut sets and reps. The fatigue source determines the lever.' },
        { q: 'What are the signs I need a deload?', a: 'Persistent joint pain, dropping bar speed, stalled progression on 2-plus lifts, poor sleep, low motivation, and elevated resting heart rate. Two or more of these signals means deload now.' },
        { q: 'Can I skip a planned deload?', a: 'Once or twice yes, especially if you are still progressing. Beyond that, accumulated fatigue masks fitness and your real strength drops. Programmed deloads are insurance against this.' },
      ]}
    >
      <p>
        A deload is a planned period, usually one week, where training volume or intensity is
        deliberately reduced to let accumulated fatigue dissipate. It is not a break from training.
        It is a strategic dial-down that lets your body actually express the fitness it has built
        underneath the fatigue.
      </p>

      <h2>The full picture</h2>
      <p>
        Every productive training block builds two things in parallel. Fitness and fatigue. As
        weeks accumulate, fatigue can mask fitness, hiding the real strength gains underneath
        soreness, joint irritation, dropping bar speed, and stalled reps. A deload week strips off
        the fatigue layer so the underlying fitness shows up on the bar.
      </p>
      <p>
        The model behind this is supercompensation. After a stressor and recovery, performance
        rebounds above the pre-stressor baseline. Stack too much stress with too little recovery
        and the rebound never happens. Deloads engineer the recovery side of the equation when
        normal between-session recovery is no longer sufficient.
      </p>
      <p>
        Two main flavors. <strong>Volume deload</strong> cuts sets per muscle by 40 to 60 percent
        while keeping load similar. This is the standard for hypertrophy work. <strong>Intensity
        deload</strong> keeps the same sets and reps but drops the load by 20 to 30 percent. This
        suits joint and tendon recovery and is common in powerlifting peaking blocks where
        movement specificity is preserved.
      </p>

      <h2>How to structure a deload week</h2>
      <p>
        A standard hypertrophy deload week. Keep training frequency the same. Cut working sets in
        half. Stop sets 2 to 3 reps shy of failure regardless of program prescription. Drop any
        intensity techniques like drop sets, rest-pause, or myo-reps. Add light cardio and
        prioritize sleep and protein. Resume normal programming the following week.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>A deload is not a rest week. Skipping training entirely is fine occasionally but it neither tests nor preserves movement skill. Reduced loading does both.</li>
        <li>Deloads do not "shock the muscles back to growth." They restore performance so the next overload block can actually overload.</li>
        <li>Deloads are not optional for advanced lifters. The longer you train, the smaller the productive volume window between MEV and MRV, and the more frequently fatigue must be managed.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Helms ER, Aragon AA, Fitschen PJ. (2014). <em>Evidence-based recommendations for natural bodybuilding contest preparation</em>. JISSN, 11(20).</li>
        <li>Pritchard H et al. (2015). <em>Effects and mechanisms of tapering in maximizing muscular strength</em>. Strength Cond J, 37(2), 72-83.</li>
        <li>Bell L et al. (2022). <em>Overreaching and overtraining in strength sports</em>. JISSN, 19(1), 156-186.</li>
      </ul>
    </GlossaryShell>
  );
}
