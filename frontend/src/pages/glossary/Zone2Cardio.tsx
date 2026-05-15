import GlossaryShell from '../../components/glossary/GlossaryShell';

export default function GlossaryZone2Cardio() {
  return (
    <GlossaryShell
      term="Zone 2 Cardio"
      slug="zone-2-cardio"
      metaDescription="Zone 2 cardio is conversational-pace aerobic training at roughly 60 to 70 percent of max heart rate. The intensity that maximizes mitochondrial density and aerobic base. Learn how to set zones with Karvonen and Maffetone."
      relatedCalcSlug="target-heart-rate-calculator"
      relatedCalcName="Target Heart Rate Calculator"
      faqs={[
        { q: 'How do I find my Zone 2?', a: 'Three methods. Heart rate at 60 to 70 percent of max. Lactate at 1.5 to 2.0 mmol/L. The "nose breathing" or "talk test." If you can hold a full conversation in complete sentences, you are likely in Zone 2.' },
        { q: 'How long should a Zone 2 session be?', a: 'Forty-five to ninety minutes is the productive range. Sessions under 30 minutes provide minimal mitochondrial signal. Sessions over 2 hours add fatigue without much extra adaptation for non-endurance athletes.' },
        { q: 'How often should I do Zone 2?', a: 'Three to five sessions per week for general fitness. Elite endurance athletes do 80 percent of their training volume in Zone 2, equating to 6 to 10 sessions per week.' },
        { q: 'Will Zone 2 interfere with strength training?', a: 'No, when done on separate days or on the same day after lifting. The interference effect is real for concurrent training, but Zone 2 is the lowest-interference cardio modality.' },
        { q: 'What is the difference between Zone 2 and LISS?', a: 'Zone 2 is a specific physiological intensity (lactate threshold 1). LISS, Low-Intensity Steady State, is a casual term for the same thing. Zone 2 is more precise.' },
      ]}
    >
      <p>
        Zone 2 cardio is aerobic training at conversational pace, roughly 60 to 70 percent of
        maximum heart rate, where your body burns mostly fat for fuel and lactate production stays
        low. It is the intensity that drives the largest mitochondrial and capillary adaptations
        per unit of fatigue, which is why elite endurance athletes spend 70 to 80 percent of their
        training volume here.
      </p>

      <h2>The full picture</h2>
      <p>
        Heart rate zones split aerobic and anaerobic work into intensity bands. The 5-zone model
        is most common. <strong>Zone 1</strong> is very light, recovery pace. <strong>Zone
        2</strong> is endurance, the "all day" pace. <strong>Zone 3</strong> is tempo, hard but
        sustainable. <strong>Zone 4</strong> is threshold, near the lactate breakpoint. <strong>Zone
        5</strong> is VO2 max work, all-out intervals.
      </p>
      <p>
        Zone 2 specifically corresponds to the first lactate threshold (LT1), where blood lactate
        stays at 1.5 to 2.0 mmol/L. Below LT1, fat is the dominant fuel and lactate clearance
        easily matches production. Above LT1, the body shifts toward carbohydrate oxidation and
        lactate starts accumulating. Training at or just below LT1 is what builds the aerobic
        base that everything else stacks on top of.
      </p>
      <p>
        The adaptations are deep. Zone 2 increases mitochondrial density, capillary network
        density, and the muscle's ability to use fat for fuel. It improves heart stroke volume.
        It builds the "engine" that determines how much higher-intensity work you can recover from
        and how late lactate accumulates during racing. Skipping Zone 2 caps long-term endurance
        progress, no matter how many intervals you do.
      </p>
      <p>
        The polarized training model popularized by Stephen Seiler argues that elite endurance
        athletes thrive on 80 percent Zone 2 plus 20 percent Zone 4 or 5, with very little
        in-between. The Maffetone method takes an even stricter Zone 2 stance, capping training
        heart rate at 180 minus age for several months to build aerobic base.
      </p>

      <h2>How it is calculated</h2>
      <p>
        Three approaches. <strong>Percent of max HR (Tanaka):</strong> HRmax = 208 − 0.7 × age.
        Zone 2 is 60 to 70 percent of HRmax. <strong>Karvonen heart rate reserve:</strong> Zone 2
        is 60 to 70 percent of (HRmax − resting HR) + resting HR, accounting for fitness level.
        <strong> Maffetone aerobic max:</strong> 180 − age, with adjustments for athletic
        background and health history. For a 30-year-old with resting HR 60, Karvonen Zone 2 is
        roughly 134 to 148 bpm.
      </p>

      <h2>Common misconceptions</h2>
      <ul>
        <li>Zone 2 is not a fat-burning shortcut. The "fat-burning zone" pop-fitness label refers to fuel substrate, not net fat loss. Total fat loss still depends on calorie deficit.</li>
        <li>Zone 2 is not "easy." For trained athletes the pace can feel surprisingly fast. For unfit beginners it can feel like walking. Intensity is set by physiology, not by speed.</li>
        <li>Zone 2 does not require special equipment. A heart rate monitor and a stopwatch are sufficient. Fancy lactate meters add precision, not necessity.</li>
      </ul>

      <h2>Citations</h2>
      <ul>
        <li>Seiler S. (2010). <em>What is best practice for training intensity and duration distribution in endurance athletes?</em> Int J Sports Physiol Perform, 5(3), 276-291.</li>
        <li>Maffetone P. (2010). <em>The Big Book of Endurance Training and Racing</em>. Skyhorse Publishing.</li>
        <li>San-Millan I, Brooks GA. (2018). <em>Assessment of metabolic flexibility by means of measuring blood lactate, fat, and carbohydrate oxidation responses to exercise</em>. Sports Med, 48(2), 467-479.</li>
      </ul>
    </GlossaryShell>
  );
}
