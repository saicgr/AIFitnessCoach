import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryMesocycle() {
  return (
    <GlossaryShell
      term="Mesocycle"
      slug="mesocycle"
      metaDescription="A mesocycle is a 4 to 6 week training block that ramps volume from Minimum Effective Volume (MEV) up to Maximum Recoverable Volume (MRV), then deloads. Learn the MEV-MAV-MRV model used by Renaissance Periodization."
      relatedCalcSlug="mesocycle-volume-calculator"
      relatedCalcName="Mesocycle Volume Calculator"
      faqs={[
        { q: 'How long is a typical mesocycle?', a: 'Four to six weeks of accumulation plus one deload week. Total length 5 to 7 weeks. Longer than that and fatigue outpaces what a single deload can clear.' },
        { q: 'What does MEV, MAV, and MRV mean?', a: 'MEV is the minimum volume that drives growth. MAV is the volume where most progress happens. MRV is the maximum volume you can recover from. A block ramps MEV to MAV to MRV then deloads.' },
        { q: 'How do I know my MEV and MRV?', a: 'They are personal. Start at evidence-based MEV ranges (10 to 12 sets per muscle per week for most lifters) and add 2 to 3 sets per week until pump, performance, or recovery breaks down. That ceiling is your MRV.' },
        { q: 'Do all muscles need separate mesocycles?', a: 'No. Most lifters run one mesocycle for the whole body. Each muscle just has its own MEV-to-MRV range that gets tracked separately within the same block.' },
        { q: 'Is the MEV-MAV-MRV model evidence-based?', a: 'Partially. The dose-response curve for hypertrophy volume is empirically supported (Schoenfeld 2017). The specific MEV-MAV-MRV labels were popularized by Mike Israetel of Renaissance Periodization as a practical heuristic.' },
      ]}
    >
      <p>
        A mesocycle is a 4 to 6 week training block built around a single goal and a planned ramp
        in training volume. It is the medium-sized building block of periodized programming. A
        few mesocycles stacked together form a macrocycle. Within a mesocycle, individual training
        weeks are microcycles.
      </p>

      <h2>The full picture</h2>
      <p>
        The modern hypertrophy-focused mesocycle was popularized by Mike Israetel and Renaissance
        Periodization. The framework rests on a dose-response curve. Too little volume and you do
        not grow. Too much and you cannot recover. The productive zone sits between Minimum
        Effective Volume (MEV) and Maximum Recoverable Volume (MRV), with Maximum Adaptive Volume
        (MAV) somewhere in the middle.
      </p>
      <p>
        A typical block starts at MEV, around 10 to 12 working sets per muscle per week for most
        intermediate lifters. Each subsequent week adds 1 to 3 sets per muscle, climbing through
        MAV until performance markers start breaking down. That breaking point is roughly MRV.
        Then a deload week dissipates fatigue, and the next block restarts at MEV with a slightly
        higher baseline load or rep target.
      </p>
      <p>
        Different muscle groups have different MEV-to-MRV ranges. Side delts, biceps, and calves
        tolerate high volume because they are small and recover fast. Hamstrings, quads, and back
        tolerate less because each set hits more total tissue and produces more systemic fatigue.
      </p>

      <h2>How a mesocycle is structured</h2>
      <p>
        <strong>Week 1 (MEV):</strong> 10 to 12 sets per muscle. RPE 7. <strong>Week 2:</strong> 12
        to 14 sets. RPE 7 to 8. <strong>Week 3:</strong> 14 to 16 sets. RPE 8. <strong>Week 4
        (MAV-to-MRV):</strong> 16 to 20 sets. RPE 8 to 9. <strong>Week 5 (optional MRV
        overshoot):</strong> 18 to 22 sets. RPE 9. <strong>Week 6 (deload):</strong> half volume,
        2 to 3 reps shy of failure.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>MEV and MRV are not fixed numbers. They shift with sleep, nutrition, life stress, and current training age.</li>
        <li>Stacking mesocycles back to back without deloads is not "more progress." It just hides accumulating fatigue until performance crashes.</li>
        <li>Adding volume is not the only way to progress within a block. You can also ramp average load or proximity to failure across the weeks.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Schoenfeld BJ, Ogborn D, Krieger JW. (2017). <em>Dose-response relationship between weekly resistance training volume and increases in muscle mass</em>. J Sports Sci, 35(11), 1073-1082.</li>
        <li>Israetel M, Hoffmann J, Smith C. (2015). <em>Scientific Principles of Hypertrophy Training</em>. Renaissance Periodization.</li>
        <li>Bompa T, Buzzichelli C. (2018). <em>Periodization: Theory and Methodology of Training</em>, 6th edition. Human Kinetics.</li>
      </ul>
    </GlossaryShell>
  );
}
