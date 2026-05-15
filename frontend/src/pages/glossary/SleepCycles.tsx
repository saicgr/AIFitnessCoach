import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossarySleepCycles() {
  return (
    <GlossaryShell
      term="Sleep Cycles"
      slug="sleep-cycles"
      metaDescription="A sleep cycle is roughly 90 minutes long and rotates your brain through NREM stages 1, 2, 3, then REM sleep. Learn why waking between cycles feels best and how to time bedtime for your wake target."
      relatedCalcSlug="sleep-cycle-calculator"
      relatedCalcName="Sleep Cycle Calculator"
      faqs={[
        { q: 'Are sleep cycles always exactly 90 minutes?', a: 'No. Cycle length ranges from 80 to 110 minutes and shifts across the night. Early cycles are NREM-dominant. Later cycles have more REM. The 90-minute number is a population average.' },
        { q: 'Why do I feel groggy after a long nap?', a: 'You likely woke in deep slow-wave sleep (NREM stage 3). The brain takes 15 to 30 minutes to clear that fog. Naps of 20 minutes or full 90-minute cycles avoid this.' },
        { q: 'How many sleep cycles do I need?', a: 'Five to six cycles per night for most adults, which equals 7.5 to 9 hours of sleep. Four cycles (6 hours) is consistently linked with worse cognitive and metabolic outcomes.' },
        { q: 'Should I sleep in multiples of 90 minutes?', a: 'It is a useful starting heuristic, but real cycle length varies. Treat sleep cycle calculators as suggestions, not laws. Sleep until you wake naturally on weekends to find your true cycle length.' },
        { q: 'What stage of sleep is most important?', a: 'All four matter. Slow-wave (deep) sleep handles physical recovery and growth hormone release. REM handles memory consolidation and emotional processing. You need a full mix.' },
      ]}
    >
      <p>
        A sleep cycle is one complete rotation through the brain's sleep stages, lasting roughly
        90 minutes on average. Each night the brain runs four to six cycles back to back. Waking
        between cycles feels easy. Waking mid-cycle, especially mid deep sleep, feels rough.
      </p>

      <h2>The full picture</h2>
      <p>
        Each cycle contains four stages. <strong>NREM stage 1</strong> is the few minutes between
        wakefulness and sleep. <strong>NREM stage 2</strong> is light sleep, the longest stage
        across the night. <strong>NREM stage 3</strong> is slow-wave or deep sleep, the most
        physically restorative stage and the hardest to wake from. <strong>REM</strong> sleep is
        when most vivid dreaming, memory consolidation, and emotional processing happen. The eyes
        move rapidly under closed lids and muscle paralysis prevents you from acting out dreams.
      </p>
      <p>
        Cycle composition shifts across the night. Early cycles are dominated by NREM stage 3, the
        deep recovery sleep. Later cycles flip the ratio. By the final cycle, REM may take 40 of
        the 90 minutes. This is why most vivid dreaming and most mornings end on a REM stage.
      </p>
      <p>
        Cycle length is not perfectly fixed at 90 minutes. It can run from 80 to 110 minutes
        depending on the individual, sleep pressure, age, and prior sleep debt. Sleep cycle
        calculators use the 90-minute average plus a 14 to 15 minute sleep-onset buffer to predict
        clean wake windows.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Sleep cycle calculators work backwards from your target wake time. <strong>Example:</strong>
        target wake 6:30 AM. Subtract 5 cycles of 90 minutes (7.5 hours) plus 15 minutes to fall
        asleep. Recommended bedtime is 10:45 PM. Subtract 6 cycles (9 hours) for 9:15 PM. Subtract
        4 cycles (6 hours) for 12:15 AM. The closer your wake time is to a cycle boundary, the
        easier the wake.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>You cannot "hack" sleep cycles by sleeping less if you wake on a cycle boundary. Total sleep duration still matters for cognitive and metabolic recovery.</li>
        <li>Polyphasic sleep schedules (Uberman, Everyman) do not actually compress recovery. They cap your daily REM, and real-world adherence over months is near zero.</li>
        <li>Wearables labeling specific stages "deep" and "REM" are approximations from heart rate and motion, not real EEG measurements. Treat the trends as useful, the exact stage counts as rough.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Stickgold R, Walker MP. (2013). <em>Sleep-dependent memory triage: evolving generalization through selective processing</em>. Nat Neurosci, 16(2), 139-145.</li>
        <li>Hirshkowitz M et al. (2015). <em>National Sleep Foundation's sleep time duration recommendations</em>. Sleep Health, 1(1), 40-43.</li>
        <li>Carskadon MA, Dement WC. (2011). <em>Normal human sleep: an overview</em>. In Principles and Practice of Sleep Medicine, 5th ed.</li>
      </ul>
    </GlossaryShell>
  );
}
