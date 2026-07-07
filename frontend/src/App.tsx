import { lazy, Suspense, useEffect } from 'react';
import { Routes, Route, Navigate, useParams, Link } from 'react-router-dom';
import ScrollToTop from './components/ScrollToTop';
import { useAppStore } from './store';
import { useAdminStore } from './store/adminStore';
import { supabase } from './lib/supabase';
import { isPrerender } from './lib/runtimeEnv';
// Homepage stays eager — it's the most-hit route and the LCP-critical path.
import MarketingLanding from './pages/MarketingLanding';

// Route-chunk loading state. MUST render null during prerender (the SSG
// snapshot waits for #root children + 300ms; a visible fallback could get
// baked into SEO HTML). For real users a blank screen while a lazy chunk
// downloads reads as "the page is broken", so show a minimal boot pulse.
function RouteFallback() {
  if (isPrerender()) return null;
  return (
    <div className="fixed inset-0 z-50 grid place-items-center bg-[#050505]">
      <img
        src="/zealova-logo.png"
        alt=""
        className="h-12 w-12 animate-pulse rounded-2xl"
      />
    </div>
  );
}

// Every other page is route-split via React.lazy so the homepage bundle stays
// lean. IMPORTANT: the Suspense fallback must remain `null` — the SSG
// prerenderer (scripts/prerender.mjs) waits for `#root` to have children and
// then snapshots after a 300ms settle; a visible fallback could be captured
// into the SEO HTML. A null fallback means snapshots only ever contain real
// page content.
const Landing = lazy(() => import('./pages/Landing'));
const Features = lazy(() => import('./pages/Features'));
const Pricing = lazy(() => import('./pages/Pricing'));
const Lifetime = lazy(() => import('./pages/Lifetime'));
const LifetimeSuccess = lazy(() => import('./pages/LifetimeSuccess'));
const PrivacyPolicy = lazy(() => import('./pages/PrivacyPolicy'));
const TermsOfService = lazy(() => import('./pages/TermsOfService'));
const HealthDisclaimer = lazy(() => import('./pages/HealthDisclaimer'));
const RefundPolicy = lazy(() => import('./pages/RefundPolicy'));
const FAQ = lazy(() => import('./pages/FAQ'));
const About = lazy(() => import('./pages/About'));
const Architecture = lazy(() => import('./pages/Architecture'));
const MCPDocs = lazy(() => import('./pages/MCPDocs'));
const Contact = lazy(() => import('./pages/Contact'));
const Changelog = lazy(() => import('./pages/Changelog'));
const Roadmap = lazy(() => import('./pages/Roadmap'));
const Waitlist = lazy(() => import('./pages/Waitlist'));
const DeleteAccount = lazy(() => import('./pages/DeleteAccount'));
const Invite = lazy(() => import('./pages/Invite'));
const Onboarding = lazy(() => import('./pages/Onboarding'));
const OnboardingSelector = lazy(() => import('./pages/OnboardingSelector'));
const ConversationalOnboarding = lazy(() => import('./pages/ConversationalOnboarding'));
const Home = lazy(() => import('./pages/Home'));
const WorkoutDetails = lazy(() => import('./pages/WorkoutDetails'));
const ActiveWorkout = lazy(() => import('./pages/ActiveWorkout'));
const Chat = lazy(() => import('./pages/Chat'));
const Settings = lazy(() => import('./pages/Settings'));
const AuthCallback = lazy(() => import('./pages/AuthCallback'));
const Profile = lazy(() => import('./pages/Profile'));
const Metrics = lazy(() => import('./pages/Metrics'));
const Nutrition = lazy(() => import('./pages/Nutrition'));
const Library = lazy(() => import('./pages/Library'));
const Achievements = lazy(() => import('./pages/Achievements'));
const Share = lazy(() => import('./pages/Share'));
const PublicWorkout = lazy(() => import('./pages/PublicWorkout'));
const GoogleHealthVs = lazy(() => import('./pages/vs/GoogleHealth'));
const GoogleHealthHallucination = lazy(() => import('./pages/blog/GoogleHealthHallucination'));
const BevelVs = lazy(() => import('./pages/vs/Bevel'));
const BestAiFitnessApps2026 = lazy(() => import('./pages/best/AiFitnessApps2026'));
const BestCalorieTrackerApps2026 = lazy(() => import('./pages/best/CalorieTrackerApps2026'));
const BestWorkoutGeneratorApps2026 = lazy(() => import('./pages/best/WorkoutGeneratorApps2026'));
const BestFitbitAlternatives2026 = lazy(() => import('./pages/best/FitbitAlternatives2026'));
const BestMyFitnessPalAlternatives2026 = lazy(() => import('./pages/best/MyFitnessPalAlternatives2026'));
const AndroidAiFitnessCoach = lazy(() => import('./pages/best/AndroidAiFitnessCoach'));
const ToolsIndex = lazy(() => import('./pages/tools'));
const Blog = lazy(() => import('./pages/Blog'));
const OneRmCalculator = lazy(() => import('./pages/tools/OneRmCalculator'));
const TdeeCalculator = lazy(() => import('./pages/tools/TdeeCalculator'));
const BmrCalculator = lazy(() => import('./pages/tools/BmrCalculator'));
const BodyFatCalculator = lazy(() => import('./pages/tools/BodyFatCalculator'));
const LeanBodyMassCalculator = lazy(() => import('./pages/tools/LeanBodyMassCalculator'));
const BmiCalculator = lazy(() => import('./pages/tools/BmiCalculator'));
const IdealWeightCalculator = lazy(() => import('./pages/tools/IdealWeightCalculator'));
const HealthyWeightCalculator = lazy(() => import('./pages/tools/HealthyWeightCalculator'));
const MacroCalculator = lazy(() => import('./pages/tools/MacroCalculator'));
const AdaptiveMacroCalculator = lazy(() => import('./pages/tools/AdaptiveMacroCalculator'));
const AdaptiveCalorieCalculator = lazy(() => import('./pages/tools/AdaptiveCalorieCalculator'));
const ProteinPerMealCalculator = lazy(() => import('./pages/tools/ProteinPerMealCalculator'));
const CarbCyclingCalculator = lazy(() => import('./pages/tools/CarbCyclingCalculator'));
const CaloriesBurnedCalculator = lazy(() => import('./pages/tools/CaloriesBurnedCalculator'));
const WilksCalculator = lazy(() => import('./pages/tools/WilksCalculator'));
const DotsCalculator = lazy(() => import('./pages/tools/DotsCalculator'));
const IpfGlCalculator = lazy(() => import('./pages/tools/IpfGlCalculator'));
const SchwartzMaloneCalculator = lazy(() => import('./pages/tools/SchwartzMaloneCalculator'));
const StrengthLevel = lazy(() => import('./pages/tools/StrengthLevel'));
const PlateLoader = lazy(() => import('./pages/tools/PlateLoader'));
const RirRpeConverter = lazy(() => import('./pages/tools/RirRpeConverter'));
const Vo2MaxCalculator = lazy(() => import('./pages/tools/Vo2MaxCalculator'));
const SweatRateCalculator = lazy(() => import('./pages/tools/SweatRateCalculator'));
const PaceCalculator = lazy(() => import('./pages/tools/PaceCalculator'));
const TargetHeartRateCalculator = lazy(() => import('./pages/tools/TargetHeartRateCalculator'));
const WorkoutVolumeCalculator = lazy(() => import('./pages/tools/WorkoutVolumeCalculator'));
const MesocycleVolumeCalculator = lazy(() => import('./pages/tools/MesocycleVolumeCalculator'));
const DeloadWeekCalculator = lazy(() => import('./pages/tools/DeloadWeekCalculator'));
const CutBulkDurationCalculator = lazy(() => import('./pages/tools/CutBulkDurationCalculator'));
const TaperingCalculator = lazy(() => import('./pages/tools/TaperingCalculator'));
const PhotoComparison = lazy(() => import('./pages/tools/PhotoComparison'));
const PrCelebrationCard = lazy(() => import('./pages/tools/PrCelebrationCard'));
const StreakCertificate = lazy(() => import('./pages/tools/StreakCertificate'));
const WorkoutSummaryCard = lazy(() => import('./pages/tools/WorkoutSummaryCard'));
const YearInFitnessWrapped = lazy(() => import('./pages/tools/YearInFitnessWrapped'));
const LifterPersonalityQuiz = lazy(() => import('./pages/tools/LifterPersonalityQuiz'));
const FastingTimer = lazy(() => import('./pages/tools/FastingTimer'));
const WorkoutRestTimer = lazy(() => import('./pages/tools/WorkoutRestTimer'));
const HiitIntervalTimer = lazy(() => import('./pages/tools/HiitIntervalTimer'));
const SleepCycleCalculator = lazy(() => import('./pages/tools/SleepCycleCalculator'));
const AiFoodPhoto = lazy(() => import('./pages/tools/AiFoodPhoto'));
const AiWorkoutGenerator = lazy(() => import('./pages/tools/AiWorkoutGenerator'));
const AiRoastMyRoutine = lazy(() => import('./pages/tools/AiRoastMyRoutine'));
const AiPhysiqueAnalyzer = lazy(() => import('./pages/tools/AiPhysiqueAnalyzer'));
const AiFormCheck = lazy(() => import('./pages/tools/AiFormCheck'));
const FatLossProtocolCalculator = lazy(() => import('./pages/tools/FatLossProtocolCalculator'));
const HowToGetJacked = lazy(() => import('./pages/tools/HowToGetJacked'));
const HowToGetRipped = lazy(() => import('./pages/tools/HowToGetRipped'));
const HowToCutWithoutLosingMuscle = lazy(() => import('./pages/tools/HowToCutWithoutLosingMuscle'));
const AlcoholImpactCalculator = lazy(() => import('./pages/tools/AlcoholImpactCalculator'));
const WorkoutLogExporter = lazy(() => import('./pages/tools/WorkoutLogExporter'));
const WorkoutPlanBuilder = lazy(() => import('./pages/tools/WorkoutPlanBuilder'));
const CalorieDeficitTracker = lazy(() => import('./pages/tools/CalorieDeficitTracker'));
const SupplementStackAnalyzer = lazy(() => import('./pages/tools/SupplementStackAnalyzer'));
const GlossaryIndex = lazy(() => import('./pages/glossary'));
const GlossaryOneRm = lazy(() => import('./pages/glossary/OneRm'));
const GlossaryTdee = lazy(() => import('./pages/glossary/Tdee'));
const GlossaryBmr = lazy(() => import('./pages/glossary/Bmr'));
const GlossaryMacros = lazy(() => import('./pages/glossary/Macros'));
const GlossaryProgressiveOverload = lazy(() => import('./pages/glossary/ProgressiveOverload'));
const GlossaryRirRpe = lazy(() => import('./pages/glossary/RirRpe'));
const GlossaryDeload = lazy(() => import('./pages/glossary/Deload'));
const GlossaryCutBulk = lazy(() => import('./pages/glossary/CutBulk'));
const GlossaryMesocycle = lazy(() => import('./pages/glossary/Mesocycle'));
const GlossaryWilksScore = lazy(() => import('./pages/glossary/WilksScore'));
const GlossaryBodyFatPercentage = lazy(() => import('./pages/glossary/BodyFatPercentage'));
const GlossarySleepCycles = lazy(() => import('./pages/glossary/SleepCycles'));
const GlossaryIntermittentFasting = lazy(() => import('./pages/glossary/IntermittentFasting'));
const GlossaryVo2Max = lazy(() => import('./pages/glossary/Vo2Max'));
const GlossaryZone2Cardio = lazy(() => import('./pages/glossary/Zone2Cardio'));
const WorkoutVibeGenerator = lazy(() => import('./pages/tools/WorkoutVibeGenerator'));
const AestheticBodyTypeMatcher = lazy(() => import('./pages/tools/AestheticBodyTypeMatcher'));
const CostOfSkippingCalculator = lazy(() => import('./pages/tools/CostOfSkippingCalculator'));
const CaffeineCutoffCalculator = lazy(() => import('./pages/tools/CaffeineCutoffCalculator'));
const RecipeScaler = lazy(() => import('./pages/tools/RecipeScaler'));
const ShouldITrainToday = lazy(() => import('./pages/tools/ShouldITrainToday'));
const WorkoutBuddyCompatibility = lazy(() => import('./pages/tools/WorkoutBuddyCompatibility'));
const MarathonPlanGenerator = lazy(() => import('./pages/tools/MarathonPlanGenerator'));
const ChatWidget = lazy(() => import('./components/chat/ChatWidget'));
// Admin pages (named exports from the barrel)
const AdminLogin = lazy(() => import('./pages/admin').then((m) => ({ default: m.AdminLogin })));
const AdminDashboard = lazy(() => import('./pages/admin').then((m) => ({ default: m.AdminDashboard })));
const LiveChatQueue = lazy(() => import('./pages/admin').then((m) => ({ default: m.LiveChatQueue })));

// /tools/<slug> is the URL people naturally guess (and what at least one
// reviewer typed) — the real path is /free-tools/<slug>. Param-preserving
// redirect so guessed links land on the tool instead of a 404.
function ToolsRedirect() {
  const { slug } = useParams();
  return <Navigate to={slug ? `/free-tools/${slug}` : '/free-tools'} replace />;
}

// Branded 404 — previously unmatched URLs rendered NOTHING (blank page).
function NotFound() {
  useEffect(() => {
    document.title = 'Page not found | Zealova';
  }, []);
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6 bg-[#050505] px-6 text-center">
      <p className="condensed-kicker text-xs text-volt-500">404</p>
      <h1 className="display-heading text-5xl text-white sm:text-7xl">Lost the set.</h1>
      <p className="max-w-md text-zinc-400">
        That page doesn't exist. The bar is still loaded though, so pick your next move.
      </p>
      <div className="flex flex-wrap items-center justify-center gap-4">
        <Link to="/" className="btn-volt rounded-full px-6 py-3 text-sm">Back home</Link>
        <Link
          to="/free-tools"
          className="rounded-full border border-white/15 px-6 py-3 text-sm font-medium text-white transition-colors hover:border-volt-500/50 hover:text-volt-300"
        >
          Browse free tools
        </Link>
      </div>
    </div>
  );
}

// Protected route component for admin pages
function AdminProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAdminStore();

  if (!isAuthenticated) {
    return <Navigate to="/admin/login" replace />;
  }

  return <>{children}</>;
}

function App() {
  const { user, setSession, setUser } = useAppStore();

  // Listen for auth state changes
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        console.log('🔐 Auth state changed:', event, session?.user?.id);

        if (event === 'SIGNED_OUT') {
          setSession(null);
          setUser(null);
        } else if (session) {
          setSession(session);
        }
      }
    );

    return () => {
      subscription.unsubscribe();
    };
  }, [setSession, setUser]);

  // Check for valid user with proper structure
  const isValidUser = user && (typeof user.id === 'number' || typeof user.id === 'string') && user.onboarding_completed === true;

  // Log user state for debugging
  console.log('🔐 App: User state:', { user, isValidUser });

  return (
    <>
      <ScrollToTop />
      <Suspense fallback={<RouteFallback />}>
      <Routes>
        {/* Marketing pages - public */}
        <Route path="/" element={<MarketingLanding />} />
        <Route path="/features" element={<Features />} />
        <Route path="/pricing" element={<Pricing />} />
        {/* Founding 500 Lifetime — web-only, $149.99 one-time. NEVER linked from inside the iOS/Android app. */}
        <Route path="/lifetime" element={<Lifetime />} />
        <Route path="/lifetime/success" element={<LifetimeSuccess />} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/terms" element={<TermsOfService />} />
        <Route path="/health-disclaimer" element={<HealthDisclaimer />} />
        <Route path="/refunds" element={<RefundPolicy />} />
        <Route path="/faq" element={<FAQ />} />
        <Route path="/about" element={<About />} />
        <Route path="/architecture" element={<Architecture />} />
        <Route path="/mcp/docs" element={<MCPDocs />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/share" element={<Share />} />
        <Route path="/changelog" element={<Changelog />} />
        <Route path="/roadmap" element={<Roadmap />} />
        <Route path="/waitlist" element={<Waitlist />} />
        <Route path="/delete-account" element={<DeleteAccount />} />
        {/* Blog posts — editorial, original-data, technical explainers */}
        <Route path="/blog/google-health-coach-hallucination" element={<GoogleHealthHallucination />} />
        {/* Comparison pages — SEO */}
        <Route path="/vs/google-health" element={<GoogleHealthVs />} />
        <Route path="/vs/bevel" element={<BevelVs />} />
        {/* Best-of segment pages — SEO */}
        <Route path="/best-ai-fitness-apps-2026" element={<BestAiFitnessApps2026 />} />
        <Route path="/best-calorie-tracker-apps-2026" element={<BestCalorieTrackerApps2026 />} />
        <Route path="/best-workout-generator-apps-2026" element={<BestWorkoutGeneratorApps2026 />} />
        <Route path="/best-fitbit-alternatives-2026" element={<BestFitbitAlternatives2026 />} />
        <Route path="/best-myfitnesspal-alternatives-2026" element={<BestMyFitnessPalAlternatives2026 />} />
        <Route path="/android-ai-fitness-coach" element={<AndroidAiFitnessCoach />} />
        {/* Free calculator tools — SEO + acquisition funnel */}
        <Route path="/free-tools" element={<ToolsIndex />} />
        <Route path="/blog" element={<Blog />} />
        <Route path="/free-tools/1rm-calculator" element={<OneRmCalculator />} />
        <Route path="/free-tools/tdee-calculator" element={<TdeeCalculator />} />
        <Route path="/free-tools/bmr-calculator" element={<BmrCalculator />} />
        <Route path="/free-tools/body-fat-calculator" element={<BodyFatCalculator />} />
        <Route path="/free-tools/lean-body-mass-calculator" element={<LeanBodyMassCalculator />} />
        <Route path="/free-tools/bmi-calculator" element={<BmiCalculator />} />
        <Route path="/free-tools/ideal-weight-calculator" element={<IdealWeightCalculator />} />
        <Route path="/free-tools/healthy-weight-calculator" element={<HealthyWeightCalculator />} />
        <Route path="/free-tools/macro-calculator" element={<MacroCalculator />} />
        <Route path="/free-tools/adaptive-macro-calculator" element={<AdaptiveMacroCalculator />} />
        <Route path="/free-tools/adaptive-calorie-calculator" element={<AdaptiveCalorieCalculator />} />
        <Route path="/free-tools/protein-per-meal-calculator" element={<ProteinPerMealCalculator />} />
        <Route path="/free-tools/carb-cycling-calculator" element={<CarbCyclingCalculator />} />
        <Route path="/free-tools/calories-burned-calculator" element={<CaloriesBurnedCalculator />} />
        <Route path="/free-tools/wilks-calculator" element={<WilksCalculator />} />
        <Route path="/free-tools/dots-calculator" element={<DotsCalculator />} />
        <Route path="/free-tools/ipf-gl-calculator" element={<IpfGlCalculator />} />
        <Route path="/free-tools/schwartz-malone-calculator" element={<SchwartzMaloneCalculator />} />
        <Route path="/free-tools/strength-level" element={<StrengthLevel />} />
        <Route path="/free-tools/plate-loader" element={<PlateLoader />} />
        <Route path="/free-tools/rir-rpe-converter" element={<RirRpeConverter />} />
        <Route path="/free-tools/vo2-max-calculator" element={<Vo2MaxCalculator />} />
        <Route path="/free-tools/sweat-rate-calculator" element={<SweatRateCalculator />} />
        <Route path="/free-tools/pace-calculator" element={<PaceCalculator />} />
        <Route path="/free-tools/target-heart-rate-calculator" element={<TargetHeartRateCalculator />} />
        <Route path="/free-tools/workout-volume-calculator" element={<WorkoutVolumeCalculator />} />
        <Route path="/free-tools/mesocycle-volume-calculator" element={<MesocycleVolumeCalculator />} />
        <Route path="/free-tools/deload-week-calculator" element={<DeloadWeekCalculator />} />
        <Route path="/free-tools/cut-bulk-duration-calculator" element={<CutBulkDurationCalculator />} />
        <Route path="/free-tools/tapering-calculator" element={<TaperingCalculator />} />
        <Route path="/free-tools/photo-comparison" element={<PhotoComparison />} />
        <Route path="/free-tools/pr-celebration-card" element={<PrCelebrationCard />} />
        <Route path="/free-tools/streak-certificate" element={<StreakCertificate />} />
        <Route path="/free-tools/workout-summary-card" element={<WorkoutSummaryCard />} />
        <Route path="/free-tools/year-in-fitness-wrapped" element={<YearInFitnessWrapped />} />
        <Route path="/free-tools/lifter-personality-quiz" element={<LifterPersonalityQuiz />} />
        <Route path="/free-tools/fasting-timer" element={<FastingTimer />} />
        <Route path="/free-tools/workout-rest-timer" element={<WorkoutRestTimer />} />
        <Route path="/free-tools/hiit-interval-timer" element={<HiitIntervalTimer />} />
        <Route path="/free-tools/sleep-cycle-calculator" element={<SleepCycleCalculator />} />
        <Route path="/free-tools/ai-food-photo" element={<AiFoodPhoto />} />
        <Route path="/free-tools/ai-workout-generator" element={<AiWorkoutGenerator />} />
        <Route path="/free-tools/ai-roast-my-routine" element={<AiRoastMyRoutine />} />
        <Route path="/free-tools/ai-physique-analyzer" element={<AiPhysiqueAnalyzer />} />
        <Route path="/free-tools/ai-form-check" element={<AiFormCheck />} />
        <Route path="/free-tools/fat-loss-protocol-calculator" element={<FatLossProtocolCalculator />} />
        <Route path="/free-tools/how-to-get-jacked" element={<HowToGetJacked />} />
        <Route path="/free-tools/how-to-get-ripped" element={<HowToGetRipped />} />
        <Route path="/free-tools/how-to-cut-without-losing-muscle" element={<HowToCutWithoutLosingMuscle />} />
        <Route path="/free-tools/alcohol-impact-calculator" element={<AlcoholImpactCalculator />} />
        <Route path="/free-tools/workout-log-exporter" element={<WorkoutLogExporter />} />
        <Route path="/free-tools/workout-plan-builder" element={<WorkoutPlanBuilder />} />
        <Route path="/free-tools/calorie-deficit-tracker" element={<CalorieDeficitTracker />} />
        <Route path="/free-tools/supplement-stack-analyzer" element={<SupplementStackAnalyzer />} />
        {/* Glossary pages — definition-style content, ranks for "what is X" + AI Overviews */}
        <Route path="/glossary" element={<GlossaryIndex />} />
        <Route path="/glossary/1rm" element={<GlossaryOneRm />} />
        <Route path="/glossary/tdee" element={<GlossaryTdee />} />
        <Route path="/glossary/bmr" element={<GlossaryBmr />} />
        <Route path="/glossary/macros" element={<GlossaryMacros />} />
        <Route path="/glossary/progressive-overload" element={<GlossaryProgressiveOverload />} />
        <Route path="/glossary/rir-rpe" element={<GlossaryRirRpe />} />
        <Route path="/glossary/deload" element={<GlossaryDeload />} />
        <Route path="/glossary/cut-bulk" element={<GlossaryCutBulk />} />
        <Route path="/glossary/mesocycle" element={<GlossaryMesocycle />} />
        <Route path="/glossary/wilks-score" element={<GlossaryWilksScore />} />
        <Route path="/glossary/body-fat-percentage" element={<GlossaryBodyFatPercentage />} />
        <Route path="/glossary/sleep-cycles" element={<GlossarySleepCycles />} />
        <Route path="/glossary/intermittent-fasting" element={<GlossaryIntermittentFasting />} />
        <Route path="/glossary/vo2-max" element={<GlossaryVo2Max />} />
        <Route path="/glossary/zone-2-cardio" element={<GlossaryZone2Cardio />} />
        <Route path="/free-tools/workout-vibe-generator" element={<WorkoutVibeGenerator />} />
        <Route path="/free-tools/aesthetic-body-type-matcher" element={<AestheticBodyTypeMatcher />} />
        <Route path="/free-tools/cost-of-skipping-calculator" element={<CostOfSkippingCalculator />} />
        <Route path="/free-tools/caffeine-cutoff-calculator" element={<CaffeineCutoffCalculator />} />
        <Route path="/free-tools/recipe-scaler" element={<RecipeScaler />} />
        <Route path="/free-tools/should-i-train-today" element={<ShouldITrainToday />} />
        <Route path="/free-tools/workout-buddy-compatibility" element={<WorkoutBuddyCompatibility />} />
        <Route path="/free-tools/marathon-plan-generator" element={<MarathonPlanGenerator />} />
        {/* Referral invite landing page. iOS/Android opens the app via
            the `fitwiz://` scheme if installed (see Invite.tsx); desktop
            or not-installed → show the code + store CTAs. */}
        <Route path="/invite/:code" element={<Invite />} />
        {/* Public workout share — anyone can view; backend resolves the
            opaque token via /api/v1/workouts/public/{token}. */}
        <Route path="/w/:token" element={<PublicWorkout />} />
        {/* Legacy landing page */}
        <Route path="/app" element={<Landing />} />
        {/* Protected home (dashboard) */}
        <Route
          path="/home"
          element={isValidUser ? <Home /> : <Navigate to="/login" replace />}
        />
        {/* /login removed — redirects to home page */}
        <Route path="/login" element={<Navigate to="/" replace />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route
          path="/onboarding/selector"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <OnboardingSelector />
          }
        />
        <Route
          path="/onboarding/chat"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <ConversationalOnboarding />
          }
        />
        <Route
          path="/onboarding"
          element={
            user?.onboarding_completed
              ? <Navigate to="/home" replace />
              : <Onboarding />
          }
        />
        <Route path="/workout/:id" element={<WorkoutDetails />} />
        <Route path="/workout/:id/active" element={<ActiveWorkout />} />
        <Route path="/chat" element={<Chat />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/profile" element={<Profile />} />
        <Route path="/metrics" element={<Metrics />} />
        <Route path="/nutrition" element={<Nutrition />} />
        <Route path="/library" element={<Library />} />
        <Route path="/achievements" element={<Achievements />} />

        {/* Admin Routes */}
        <Route path="/admin/login" element={<AdminLogin />} />
        <Route
          path="/admin/dashboard"
          element={
            <AdminProtectedRoute>
              <AdminDashboard />
            </AdminProtectedRoute>
          }
        />
        <Route
          path="/admin/chats"
          element={
            <AdminProtectedRoute>
              <LiveChatQueue />
            </AdminProtectedRoute>
          }
        />
        {/* Redirect /admin to /admin/dashboard */}
        <Route path="/admin" element={<Navigate to="/admin/dashboard" replace />} />
        {/* Guessed/legacy tool URLs → canonical /free-tools paths */}
        <Route path="/tools" element={<Navigate to="/free-tools" replace />} />
        <Route path="/tools/:slug" element={<ToolsRedirect />} />
        {/* Catch-all: unmatched URLs used to render a BLANK page */}
        <Route path="*" element={<NotFound />} />
      </Routes>
      {/* Global Chat Widget - renders via portal, only for authenticated users */}
      {isValidUser && <ChatWidget />}
      </Suspense>
    </>
  );
}

export default App;
