import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryRirRpe() {
  return (
    <GlossaryShell
      term="RIR and RPE"
      slug="rir-rpe"
      metaDescription="RIR is Reps in Reserve. RPE is Rate of Perceived Exertion. Together they let lifters quantify how hard a set was without testing a 1RM. Learn the Zourdos 1-10 scale and how to convert to percent of 1RM."
      relatedCalcSlug="rir-rpe-converter"
      relatedCalcName="RIR / RPE / %1RM Converter"
      faqs={[
        { q: 'What is the difference between RIR and RPE?', a: 'They measure the same thing inversely. RPE 10 = RIR 0 (true failure). RPE 9 = RIR 1. RPE 8 = RIR 2. RPE 7 = RIR 3. RPE is older; RIR was introduced by Mike Tuchscherer to be more intuitive.' },
        { q: 'How accurate is RPE for lifters?', a: 'Trained lifters call RPE within 0.5 to 1 unit of true effort. Novices typically underestimate by 2 to 3 units, mistaking discomfort for proximity to failure. Accuracy improves over 3 to 6 months of practice.' },
        { q: 'Should I always train at RPE 10?', a: 'No. Training to failure on every set accumulates excessive fatigue and reduces total productive volume. Most hypertrophy work happens at RPE 7 to 9, with occasional RPE 10 finishers.' },
        { q: 'How do I convert RPE to percent of 1RM?', a: 'Use the Zourdos chart. A set of 5 at RPE 9 is roughly 85 percent of 1RM. A set of 8 at RPE 8 is roughly 72 percent. Use our converter for any rep and RPE combination.' },
        { q: 'Does RPE work for hypertrophy?', a: 'Yes, and it is the most practical autoregulation tool for hypertrophy. Most evidence-based hypertrophy programs prescribe 1 to 3 RIR for working sets.' },
      ]}
    >
      <p>
        RIR and RPE are autoregulation scales that let lifters quantify how close a set was to
        failure. RIR stands for Reps in Reserve. RPE stands for Rate of Perceived Exertion. They
        are the practical alternative to rigid percentage-based programs, which assume your 1RM is
        the same every day. It is not.
      </p>

      <h2>The full picture</h2>
      <p>
        RPE was adapted from Gunnar Borg's perceived exertion work in cardiovascular research.
        Powerlifting coach Mike Tuchscherer popularized the resistance-training version in the
        2000s. Sports scientist Eric Helms and powerlifter Eric Helms further validated it in the
        2010s. Mike Zourdos published the now-standard 1-to-10 RPE chart in 2016, with
        corresponding RIR values and percent-of-1RM equivalents at each rep count.
      </p>
      <p>
        The translation between the two scales is direct. RPE 10 is true muscular failure with
        zero reps left, equal to RIR 0. RPE 9.5 is one more rep maybe. RPE 9 is one rep left, or
        RIR 1. RPE 8 is two reps left, RIR 2. RPE 7 is three reps left, RIR 3.
      </p>
      <p>
        Most evidence-based hypertrophy programs prescribe working sets at RPE 7 to 9. Strength
        work tends to live at RPE 7 to 9 in accessory lifts and RPE 8 to 9.5 in main lifts. True
        RPE 10 is reserved for testing or occasional drop-the-hammer sets, because failure
        accumulates fatigue disproportionate to its hypertrophic return.
      </p>

      <h2>How it converts to percent of 1RM</h2>
      <p>
        From the Zourdos chart, a few anchor points. RPE 10 for 1 rep = 100 percent of 1RM. RPE
        10 for 5 reps = roughly 85 percent. RPE 8 for 5 reps = roughly 80 percent. RPE 8 for 8
        reps = roughly 72 percent. Each rep below maximum subtracts roughly 2 to 3 percent of
        1RM at a given RPE.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>RPE is not just "how it felt." It is a specific estimate of reps left in the tank at that bar speed and form. Discomfort, soreness, and breathing rate are confounders, not the signal.</li>
        <li>Heart rate does not predict RPE for lifting. A heavy single can produce a 120 bpm response while a 20-rep squat hits 180.</li>
        <li>You do not need to test 1RM to use RPE. That is the whole point. Pick a target rep range and target RPE, and load the bar until both line up.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Zourdos MC et al. (2016). <em>Novel resistance training-specific rating of perceived exertion scale measuring repetitions in reserve</em>. JSCR, 30(1), 267-275.</li>
        <li>Helms ER et al. (2018). <em>Application of the repetitions in reserve-based rating of perceived exertion scale for resistance training</em>. Strength Cond J, 38(4), 42-49.</li>
        <li>Borg GA. (1982). <em>Psychophysical bases of perceived exertion</em>. Med Sci Sports Exerc, 14(5), 377-381.</li>
      </ul>
    </GlossaryShell>
  );
}
