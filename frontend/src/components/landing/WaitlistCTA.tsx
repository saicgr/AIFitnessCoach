import WaitlistForm from '../marketing/WaitlistForm';

/**
 * Final conversion band. Static layered gradients only (no animated orbs),
 * reusing WaitlistForm unmodified so the POST /api/v1/waitlist/ flow,
 * honeypot, and UTM source resolution keep working exactly as before.
 */
export default function WaitlistCTA() {
  return (
    <section className="relative overflow-hidden border-t border-white/5 py-24 sm:py-32" aria-labelledby="waitlist-heading">
      {/* Static volt atmosphere */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        style={{
          background:
            'radial-gradient(45% 38% at 25% 18%, rgba(255,122,0,0.09), transparent 70%), radial-gradient(40% 32% at 80% 80%, rgba(150,60,0,0.10), transparent 70%)',
        }}
      />

      <div className="relative mx-auto max-w-[760px] px-6 text-center">
        <p className="condensed-kicker mb-4 text-xs text-volt-500">Limited early access</p>
        <h2
          id="waitlist-heading"
          className="display-heading text-5xl text-white sm:text-7xl"
        >
          Be first when<br />
          <span className="text-volt-500">iOS drops.</span>
        </h2>
        <p className="mx-auto mt-6 max-w-md text-zinc-400">
          Join the waitlist for day-one iOS access. Android athletes can start
          training today on Google Play.
        </p>

        <div className="mx-auto mt-9 max-w-md">
          <WaitlistForm source="marketing_landing" />
        </div>

        <div className="mt-10 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs text-zinc-500">
          <span>7-day free trial</span>
          <span className="h-1 w-1 rounded-full bg-volt-500" aria-hidden="true" />
          <span>No spam, just the launch email</span>
          <span className="h-1 w-1 rounded-full bg-volt-500" aria-hidden="true" />
          <span>Live on Google Play now</span>
        </div>
      </div>
    </section>
  );
}
