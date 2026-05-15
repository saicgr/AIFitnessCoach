import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryProgressiveOverload() {
  return (
    <GlossaryShell
      term="Progressive Overload"
      slug="progressive-overload"
      metaDescription="Progressive overload is gradually increasing training demand over time. The non-negotiable principle behind every strength and hypertrophy program. Learn the four levers: load, volume, density, and tempo."
      relatedCalcSlug="workout-volume-calculator"
      relatedCalcName="Workout Volume Calculator"
      faqs={[
        { q: 'Do I have to add weight every session?', a: 'No. Progress can come from more reps, more sets, better form, or shorter rest. Linear weight progression works for novices but stalls within months for intermediates.' },
        { q: 'How fast should I add weight?', a: 'Beginners can add 2.5 to 5 pounds per session on big lifts. Intermediates add weight every 1 to 4 weeks. Advanced lifters might add 5 to 10 pounds to a single lift in an entire year.' },
        { q: 'What if I cannot progress?', a: 'Plateaus mean a variable is wrong. Sleep, calories, technique, fatigue, or program design. Run a deload, then change one variable. Random program-hopping makes the diagnosis impossible.' },
        { q: 'Can I overload with bodyweight training?', a: 'Yes. Add reps, slow the tempo, add unilateral variations, increase range of motion, or shift leverage. Bodyweight progression just uses geometry instead of plates.' },
        { q: 'Is progressive overload required for hypertrophy?', a: 'Yes. Without rising stimulus the body has no reason to adapt. The mechanism is mechanical tension, which requires either heavier loads or more total work over time.' },
      ]}
    >
      <p>
        Progressive overload is the gradual, planned increase in training demand over time. It is
        the single non-negotiable principle of getting stronger or bigger. No matter how clever
        your program looks, if total stimulus does not rise across weeks and months, your body has
        no reason to adapt.
      </p>

      <h2>The full picture</h2>
      <p>
        The term was popularized by army physician Thomas Delorme during World War II rehab work
        but the principle predates him by centuries. Every progressive overload program rests on
        the same idea. The body adapts to the demand placed on it. To force ongoing adaptation,
        the demand has to keep rising.
      </p>
      <p>
        Overload has four primary levers. <strong>Load</strong> is the weight on the bar.
        <strong> Volume</strong> is sets times reps times weight, or just total reps for many
        purposes. <strong>Density</strong> is volume per unit time, raised by shortening rest
        periods. <strong>Tempo</strong> is rep speed and pause length, raising mechanical tension
        per rep. Most lifters drive load and volume hardest because they produce the largest
        adaptations.
      </p>
      <p>
        For beginners, simple linear progression dominates. Add 5 pounds to compound lifts every
        session until you stall. For intermediates, weekly or block-based progression replaces
        it. Add a set per week, or push reps at a fixed weight, then deload and reset. Advanced
        lifters use mesocycles with deliberate volume ramps from MEV up to MRV and back.
      </p>

      <h2>How it is applied</h2>
      <p>
        The simplest measurable form is double progression. Pick a rep range like 8 to 12. Add
        reps each session at the same weight until you hit the top of the range across all sets.
        Then add weight and drop back to the bottom. Repeat. This guarantees rising stimulus
        without requiring perfect daily readiness.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>Overload is not the same as fatigue accumulation. Doing 30 sets of curls per session is just junk volume, not progressive overload.</li>
        <li>You do not need to overload every single exercise. Prioritize compound lifts and a few key isolation movements. Direct progression on calf raises matters less.</li>
        <li>Sweating, soreness, and pump are not signs of overload. Strength under heavier loads and growth over months are the only reliable signals.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Schoenfeld BJ. (2010). <em>The mechanisms of muscle hypertrophy and their application to resistance training</em>. JSCR, 24(10), 2857-2872.</li>
        <li>Delorme TL. (1945). <em>Restoration of muscle power by heavy-resistance exercises</em>. J Bone Joint Surg, 27, 645-667.</li>
        <li>Plotkin D et al. (2022). <em>Progressive overload without progressing load? The effects of load or repetition progression</em>. PeerJ, 10:e14142.</li>
      </ul>
    </GlossaryShell>
  );
}
