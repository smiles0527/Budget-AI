"use client";

import { useRef, useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, AnimatePresence, useScroll, useTransform, useMotionValueEvent } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

/* ═══════════════════════════════════════════════════════
   DATA
   ═══════════════════════════════════════════════════════ */

interface Screen {
  src: string;
  title: string;
  tagline: string;
  description: string;
  features: { icon: string; text: string }[];
  accent: string;
  gradient: string;
}

const screens: Screen[] = [
  {
    src: "/screenshots/homepage.png",
    title: "Home Dashboard",
    tagline: "Your financial command center.",
    description:
      "Everything at a glance — spending breakdowns, active quests, streak counter, and quick actions. Designed so you never need more than one tap to see what matters.",
    features: [
      { icon: "pie_chart", text: "Real-time spending breakdown by category" },
      { icon: "local_fire_department", text: "Daily streak tracker to keep you motivated" },
      { icon: "bolt", text: "Quick-action shortcuts for receipts & goals" },
      { icon: "palette", text: "Dark-mode native with neon accent theming" },
    ],
    accent: "#0df2a6",
    gradient: "from-[#0df2a6] to-[#00c9ff]",
  },
  {
    src: "/screenshots/newquest.png",
    title: "New Quest",
    tagline: "Turn saving into an adventure.",
    description:
      "Create custom money quests with deadlines, reward tiers, and difficulty levels. It's budgeting meets RPG — because saving should feel like winning, not suffering.",
    features: [
      { icon: "add_circle", text: "One-tap quest creation with smart defaults" },
      { icon: "emoji_events", text: "Choose difficulty: Easy, Medium, Hard, Legendary" },
      { icon: "timer", text: "Set deadlines with countdown notifications" },
      { icon: "stars", text: "Earn XP and badges on completion" },
    ],
    accent: "#00c9ff",
    gradient: "from-[#00c9ff] to-[#a855f7]",
  },
  {
    src: "/screenshots/questlog.png",
    title: "Quest Log",
    tagline: "Your progress, gamified.",
    description:
      "A live feed of every quest you've started, completed, or abandoned. Filter by status, sort by deadline, and watch your completion rate climb.",
    features: [
      { icon: "checklist", text: "Filter: Active, Completed, Failed, All" },
      { icon: "trending_up", text: "Completion rate percentage with history graph" },
      { icon: "notifications_active", text: "Smart reminders before quest deadlines" },
      { icon: "military_tech", text: "Badge unlock animations on completion" },
    ],
    accent: "#a855f7",
    gradient: "from-[#a855f7] to-[#ff6bcb]",
  },
  {
    src: "/screenshots/battlelog.png",
    title: "Battle Log",
    tagline: "Compete against yourself.",
    description:
      "Weekly spending battles where you face off against your past habits. Beat last week's budget and earn battle points. Lose, and the log remembers.",
    features: [
      { icon: "swords", text: "Week-over-week spending showdowns" },
      { icon: "leaderboard", text: "Battle points ranking system" },
      { icon: "analytics", text: "Win/loss history with category breakdown" },
      { icon: "whatshot", text: "Win streak multipliers for bonus XP" },
    ],
    accent: "#ff6bcb",
    gradient: "from-[#ff6bcb] to-[#ff4444]",
  },
  {
    src: "/screenshots/profile.png",
    title: "Your Profile",
    tagline: "Flex your financial journey.",
    description:
      "Your trophy case. See every badge earned, every streak maintained, your all-time level, and a timeline of your best financial moments.",
    features: [
      { icon: "person", text: "Customizable avatar with unlockable frames" },
      { icon: "workspace_premium", text: "Badge showcase with rarity tiers" },
      { icon: "timeline", text: "Financial journey timeline with milestones" },
      { icon: "share", text: "Share your profile card to flex on friends" },
    ],
    accent: "#0df2a6",
    gradient: "from-[#0df2a6] to-[#a855f7]",
  },
  {
    src: "/screenshots/addrecipe.png",
    title: "Budget Recipes",
    tagline: "Templates that actually work.",
    description:
      "Pre-built budget recipes for common scenarios — college student, first job, side hustle. Pick one, customize it, and start tracking instantly.",
    features: [
      { icon: "auto_fix_high", text: "AI-suggested recipes based on your spending" },
      { icon: "tune", text: "Fully customizable category allocations" },
      { icon: "groups", text: "Community-shared recipes with ratings" },
      { icon: "rocket_launch", text: "One-tap activation — budgeting in seconds" },
    ],
    accent: "#00c9ff",
    gradient: "from-[#00c9ff] to-[#0df2a6]",
  },
];

/* ═══════════════════════════════════════════════════════
   PHONE COMPONENT — 3D tilt on hover
   ═══════════════════════════════════════════════════════ */
function Phone3D({ src, alt, accent }: { src: string; alt: string; accent: string }) {
  const ref = useRef<HTMLDivElement>(null);

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width - 0.5;
    const y = (e.clientY - rect.top) / rect.height - 0.5;
    ref.current.style.transform = `perspective(800px) rotateY(${x * 15}deg) rotateX(${-y * 15}deg)`;
  };

  const handleMouseLeave = () => {
    if (!ref.current) return;
    ref.current.style.transform = "perspective(800px) rotateY(0deg) rotateX(0deg)";
  };

  return (
    <div
      ref={ref}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className="relative transition-transform duration-200 ease-out cursor-default"
      style={{ transformStyle: "preserve-3d" }}
    >
      {/* Glow */}
      <div
        className="absolute -inset-8 rounded-[2.5rem] blur-[60px] opacity-25 pointer-events-none"
        style={{ background: accent }}
      />
      {/* Phone frame */}
      <div
        className="relative rounded-[2rem] overflow-hidden border-2 shadow-2xl"
        style={{ borderColor: `${accent}50` }}
      >
        <Image
          src={src}
          alt={alt}
          width={390}
          height={844}
          className="w-full h-auto"
          sizes="(max-width: 768px) 80vw, 320px"
          priority
        />
        {/* Reflection overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-white/[0.08] via-transparent to-transparent pointer-events-none" />
      </div>
      {/* Notch */}
      <div
        className="absolute top-3 left-1/2 -translate-x-1/2 w-24 h-1.5 rounded-full opacity-50"
        style={{ background: accent }}
      />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   ANIMATED FEATURE PILL
   ═══════════════════════════════════════════════════════ */
function FeaturePill({
  icon,
  text,
  accent,
  index,
}: {
  icon: string;
  text: string;
  accent: string;
  index: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, x: -30, filter: "blur(8px)" }}
      whileInView={{ opacity: 1, x: 0, filter: "blur(0px)" }}
      viewport={{ once: false, amount: 0.5 }}
      transition={{ duration: 0.5, delay: index * 0.1, ease: "easeOut" }}
      whileHover={{ scale: 1.03, x: 6 }}
      className="flex items-start gap-3 p-3 rounded-xl border border-white/5 hover:border-white/10 transition-all duration-300 group"
      style={{ background: `linear-gradient(135deg, ${accent}08, transparent)` }}
    >
      <div
        className="w-9 h-9 rounded-lg flex items-center justify-center shrink-0 group-hover:scale-110 transition-transform"
        style={{ background: `${accent}15`, border: `1px solid ${accent}25` }}
      >
        <span className="material-symbols-outlined text-lg" style={{ color: accent }}>
          {icon}
        </span>
      </div>
      <span className="text-white/75 text-sm leading-relaxed pt-1.5">{text}</span>
    </motion.div>
  );
}

/* ═══════════════════════════════════════════════════════
   FLOATING DECORATIVE SHAPES
   ═══════════════════════════════════════════════════════ */
function FloatingShape({ accent, className }: { accent: string; className?: string }) {
  return (
    <div
      className={`absolute pointer-events-none rounded-full animate-float opacity-10 blur-xl ${className}`}
      style={{ background: accent, width: "200px", height: "200px" }}
    />
  );
}

/* ═══════════════════════════════════════════════════════
   SCREEN SECTION — each screenshot gets a massive section
   ═══════════════════════════════════════════════════════ */
function ScreenSection({ screen, index }: { screen: Screen; index: number }) {
  const sectionRef = useRef<HTMLDivElement>(null);
  const isEven = index % 2 === 0;

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const ctx = gsap.context(() => {
      // Section number zoom-in
      const num = section.querySelector(".section-number");
      if (num) {
        gsap.fromTo(
          num,
          { scale: 3, opacity: 0 },
          {
            scale: 1,
            opacity: 1,
            duration: 1,
            ease: "power3.out",
            scrollTrigger: { trigger: num, start: "top 85%", end: "+=250", scrub: 1 },
          }
        );
      }

      // Connecting line draws in
      const line = section.querySelector(".connect-line");
      if (line) {
        gsap.fromTo(
          line,
          { scaleY: 0 },
          {
            scaleY: 1,
            duration: 1,
            ease: "power2.out",
            scrollTrigger: { trigger: line, start: "top 90%", end: "+=200", scrub: 1 },
          }
        );
      }
    }, section);

    return () => ctx.revert();
  }, []);

  return (
    <div ref={sectionRef} className="relative">
      {/* Floating decorative blobs */}
      <FloatingShape accent={screen.accent} className={`top-10 ${isEven ? "-left-32" : "-right-32"}`} />
      <FloatingShape accent={screen.accent} className={`bottom-20 ${isEven ? "-right-24" : "-left-24"}`} />

      {/* Section number */}
      <div className="section-number flex justify-center mb-8">
        <span
          className="text-7xl md:text-9xl font-black opacity-10"
          style={{ color: screen.accent, WebkitTextStroke: `2px ${screen.accent}` }}
        >
          0{index + 1}
        </span>
      </div>

      {/* Main content grid */}
      <div
        className={`flex flex-col ${
          isEven ? "md:flex-row" : "md:flex-row-reverse"
        } items-center gap-10 md:gap-16 lg:gap-24`}
      >
        {/* Phone */}
        <motion.div
          initial={{ opacity: 0, x: isEven ? -100 : 100 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="w-60 md:w-72 lg:w-80 shrink-0"
        >
          <Phone3D src={screen.src} alt={screen.title} accent={screen.accent} />
        </motion.div>

        {/* Text + features */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: false, amount: 0.3 }}
          transition={{ duration: 0.7, delay: 0.15, ease: "easeOut" }}
          className="flex flex-col gap-5 max-w-xl"
        >
          {/* Tag */}
          <span
            className="text-xs font-bold uppercase tracking-widest w-fit"
            style={{ color: screen.accent }}
          >
            {screen.title}
          </span>

          {/* Tagline */}
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-extrabold leading-tight">
            {screen.tagline.split(".").map((part, i) =>
              i === 0 ? (
                <span key={i} style={{ color: screen.accent }}>
                  {part}.
                </span>
              ) : null
            )}
          </h2>

          {/* Description */}
          <p className="text-white/65 text-base md:text-lg leading-relaxed">
            {screen.description}
          </p>

          {/* Feature pills */}
          <div className="flex flex-col gap-2 mt-2">
            {screen.features.map((f, fi) => (
              <FeaturePill
                key={f.text}
                icon={f.icon}
                text={f.text}
                accent={screen.accent}
                index={fi}
              />
            ))}
          </div>
        </motion.div>
      </div>

      {/* Connecting line to next section */}
      {index < screens.length - 1 && (
        <div className="flex justify-center my-12 md:my-20">
          <div
            className="connect-line w-px h-24 md:h-36 origin-top"
            style={{
              background: `linear-gradient(180deg, ${screen.accent}40, transparent)`,
            }}
          />
        </div>
      )}
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   MINI NAV — sticky screen picker
   ═══════════════════════════════════════════════════════ */
function ScreenNav({ active }: { active: number }) {
  return (
    <motion.div
      initial={{ y: 100, opacity: 0 }}
      animate={{ y: 0, opacity: 1 }}
      transition={{ delay: 0.5, duration: 0.5 }}
      className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 glass-strong rounded-full px-2 py-1.5 flex items-center gap-1 border border-white/10 shadow-2xl"
    >
      {screens.map((s, i) => (
        <a
          key={s.title}
          href={`#screen-${i}`}
          className={`relative w-8 h-8 md:w-10 md:h-10 rounded-full flex items-center justify-center text-xs font-bold transition-all duration-300 ${
            active === i ? "scale-110" : "opacity-50 hover:opacity-80"
          }`}
          title={s.title}
        >
          {active === i && (
            <motion.div
              layoutId="nav-glow"
              className="absolute inset-0 rounded-full"
              style={{ background: `${s.accent}25`, border: `1.5px solid ${s.accent}60` }}
              transition={{ type: "spring", stiffness: 400, damping: 30 }}
            />
          )}
          <span className="relative z-10" style={{ color: active === i ? s.accent : "white" }}>
            {i + 1}
          </span>
        </a>
      ))}
    </motion.div>
  );
}

/* ═══════════════════════════════════════════════════════
   SCROLL PROGRESS BAR
   ═══════════════════════════════════════════════════════ */
function ProgressBar() {
  const { scrollYProgress } = useScroll();
  const width = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  return (
    <div className="fixed top-0 left-0 right-0 z-[60] h-[3px] bg-white/5">
      <motion.div
        className="h-full bg-gradient-to-r from-[#0df2a6] via-[#00c9ff] to-[#a855f7]"
        style={{ width }}
      />
    </div>
  );
}

/* ═══════════════════════════════════════════════════════
   MAIN SHOWCASE PAGE
   ═══════════════════════════════════════════════════════ */
export default function ShowcasePage() {
  const [activeScreen, setActiveScreen] = useState(0);
  const { scrollY } = useScroll();
  const [headerScrolled, setHeaderScrolled] = useState(false);

  useMotionValueEvent(scrollY, "change", (latest) => {
    setHeaderScrolled(latest > 50);
    // Determine active screen based on scroll
    const sections = document.querySelectorAll("[data-screen-index]");
    sections.forEach((section, i) => {
      const rect = section.getBoundingClientRect();
      if (rect.top < window.innerHeight * 0.5 && rect.bottom > 0) {
        setActiveScreen(i);
      }
    });
  });

  return (
    <>
      <ProgressBar />

      {/* Header */}
      <motion.header
        initial={{ y: -80, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, ease: "easeOut" }}
        className={`w-full px-6 md:px-12 flex items-center justify-between z-50 sticky top-0 transition-all duration-500 ${
          headerScrolled
            ? "py-3 md:py-4 glass-strong shadow-lg shadow-primary/5"
            : "py-4 md:py-6 bg-transparent"
        }`}
      >
        <div className="flex items-center gap-3">
          <Link href="/" className="flex items-center gap-3 group">
            <motion.div
              whileHover={{ rotate: [0, -15, 15, -10, 0], scale: 1.2 }}
              transition={{ duration: 0.5 }}
              className="text-primary text-glow-primary"
            >
              <span className="material-symbols-outlined text-3xl">account_balance_wallet</span>
            </motion.div>
            <h1 className="text-lg md:text-xl font-bold tracking-tight">
              <span className="gradient-text">SnapBudget</span>
            </h1>
          </Link>
          <span className="text-white/30 text-sm hidden sm:inline">/ Showcase</span>
        </div>
        <div className="flex items-center gap-3">
          <motion.div whileHover={{ scale: 1.08, y: -2 }} whileTap={{ scale: 0.95 }}>
            <Link
              href="/"
              className="inline-flex items-center gap-2 px-4 py-2.5 glass text-white/80 rounded-full font-medium text-sm border border-white/10 hover:border-primary/30 hover:text-primary transition-all duration-300"
            >
              <span className="material-symbols-outlined text-[18px]">arrow_back</span>
              <span className="hidden sm:inline">Back to Home</span>
            </Link>
          </motion.div>
          <motion.div whileHover={{ scale: 1.08, y: -2 }} whileTap={{ scale: 0.95 }}>
            <Link
              href="#"
              className="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-black rounded-full font-bold text-sm glow-primary hover:glow-primary-strong transition-all duration-300"
            >
              <span className="material-symbols-outlined text-[20px]">download</span>
              <span className="hidden sm:inline">Download App</span>
            </Link>
          </motion.div>
        </div>
      </motion.header>

      {/* Hero */}
      <section className="relative flex flex-col items-center justify-center text-center min-h-[70vh] px-6 overflow-hidden">
        {/* Animated gradient orbs */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full bg-primary/10 blur-[120px] animate-float" />
          <div className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full bg-neon-blue/10 blur-[100px] animate-float" style={{ animationDelay: "2s" }} />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 rounded-full bg-neon-purple/10 blur-[80px] animate-float" style={{ animationDelay: "4s" }} />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="relative z-10 max-w-3xl"
        >
          <motion.span
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2, duration: 0.5 }}
            className="text-xs font-bold uppercase tracking-[0.3em] text-primary text-glow-primary"
          >
            App Showcase
          </motion.span>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 0.7 }}
            className="text-4xl md:text-6xl lg:text-7xl font-extrabold mt-4 leading-[1.1]"
          >
            Every screen.{" "}
            <span className="gradient-text">Every detail.</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.6 }}
            className="text-white/60 text-lg md:text-xl mt-6 max-w-xl mx-auto leading-relaxed"
          >
            Dive deep into what makes SnapBudget the app Gen Z actually wants to use.
            Interactive previews, feature breakdowns, and the whole vibe.
          </motion.p>

          {/* Scroll hint */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 1, duration: 0.5 }}
            className="mt-10 flex flex-col items-center gap-2"
          >
            <span className="text-white/30 text-xs uppercase tracking-widest">Scroll to explore</span>
            <motion.span
              animate={{ y: [0, 8, 0] }}
              transition={{ repeat: Infinity, duration: 1.5 }}
              className="material-symbols-outlined text-primary text-2xl"
            >
              expand_more
            </motion.span>
          </motion.div>
        </motion.div>

        {/* Phone fan preview */}
        <motion.div
          initial={{ opacity: 0, y: 80 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6, duration: 0.9, ease: "easeOut" }}
          className="relative mt-12 flex items-end justify-center gap-[-20px]"
        >
          {screens.slice(0, 3).map((s, i) => (
            <motion.div
              key={s.title}
              initial={{ rotate: (i - 1) * 12, y: Math.abs(i - 1) * 20 }}
              animate={{ rotate: (i - 1) * 8, y: Math.abs(i - 1) * 15 }}
              whileHover={{ rotate: 0, y: -10, scale: 1.05, zIndex: 10 }}
              transition={{ type: "spring", stiffness: 200 }}
              className="relative w-32 md:w-44 -mx-4 md:-mx-6"
              style={{ zIndex: i === 1 ? 5 : 1 }}
            >
              <div
                className="rounded-2xl overflow-hidden border shadow-xl"
                style={{ borderColor: `${s.accent}30` }}
              >
                <Image
                  src={s.src}
                  alt={s.title}
                  width={195}
                  height={422}
                  className="w-full h-auto"
                  sizes="180px"
                />
              </div>
            </motion.div>
          ))}
        </motion.div>
      </section>

      {/* Screen counter */}
      <div className="text-center py-12">
        <span className="text-white/30 text-sm font-medium uppercase tracking-widest">
          {screens.length} screens to explore
        </span>
      </div>

      {/* Screen sections */}
      <main className="relative z-10 max-w-6xl mx-auto px-6 md:px-12 pb-24">
        {screens.map((screen, i) => (
          <div key={screen.title} data-screen-index={i} id={`screen-${i}`} className="scroll-mt-24">
            <ScreenSection screen={screen} index={i} />
          </div>
        ))}

        {/* Final CTA */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: false }}
          transition={{ duration: 0.8 }}
          className="text-center mt-20 md:mt-32"
        >
          <h2 className="text-3xl md:text-5xl font-extrabold">
            Ready to <span className="gradient-text">start your quest?</span>
          </h2>
          <p className="text-white/60 mt-4 text-lg max-w-md mx-auto">
            Download SnapBudget and turn your finances into a game you actually want to play.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mt-8">
            <motion.div whileHover={{ scale: 1.08, y: -3 }} whileTap={{ scale: 0.95 }}>
              <Link
                href="#"
                className="inline-flex items-center gap-3 px-8 py-4 bg-primary text-black rounded-full font-bold text-base glow-primary hover:glow-primary-strong transition-all duration-300"
              >
                <span className="material-symbols-outlined text-2xl">download</span>
                Download for iOS
              </Link>
            </motion.div>
            <motion.div whileHover={{ scale: 1.08, y: -3 }} whileTap={{ scale: 0.95 }}>
              <Link
                href="/"
                className="inline-flex items-center gap-3 px-8 py-4 glass text-white/80 rounded-full font-medium text-base border border-white/10 hover:border-primary/30 hover:text-primary transition-all duration-300"
              >
                <span className="material-symbols-outlined text-2xl">arrow_back</span>
                Back to Home
              </Link>
            </motion.div>
          </div>
        </motion.div>
      </main>

      {/* Bottom nav */}
      <ScreenNav active={activeScreen} />

      {/* Footer */}
      <footer className="w-full py-8 border-t border-white/5">
        <div className="max-w-6xl mx-auto px-6 flex items-center justify-between">
          <span className="text-white/30 text-sm">
            &copy; {new Date().getFullYear()} SnapBudget
          </span>
          <Link href="/" className="text-primary text-sm hover:text-primary/80 transition-colors">
            Home
          </Link>
        </div>
      </footer>
    </>
  );
}
