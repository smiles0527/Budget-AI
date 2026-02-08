"use client";

import { motion } from "framer-motion";
import Image from "next/image";

/* ── Each showcase "slide" ────────────────────────────── */
interface Slide {
  src: string;
  alt: string;
  heading: string;
  sub: string;
  accent: string;
  side: "left" | "right"; // phone on left or right
}

const slides: Slide[] = [
  {
    src: "/screenshots/homepage.png",
    alt: "Home page dashboard overview",
    heading: "Your home base.",
    sub: "Everything you need at a glance — spending, goals, streaks. One tap away.",
    accent: "#0df2a6",
    side: "left",
  },
  {
    src: "/screenshots/newquest.png",
    alt: "Add a new quest screen",
    heading: "Add your Quest!!!",
    sub: "Set a money challenge, pick your reward, and start leveling up your finances.",
    accent: "#00c9ff",
    side: "right",
  },
  {
    src: "/screenshots/questlog.png",
    alt: "Quest log showing active quests",
    heading: "Track every quest.",
    sub: "See all your active challenges, streaks, and progress — like a game inventory for your wallet.",
    accent: "#a855f7",
    side: "left",
  },
  {
    src: "/screenshots/battlelog.png",
    alt: "Battle log showing spending battles",
    heading: "Battle your spending.",
    sub: "Compete against your past self. Win battles. Earn bragging rights.",
    accent: "#ff6bcb",
    side: "right",
  },
  {
    src: "/screenshots/profile.png",
    alt: "User profile with badges and stats",
    heading: "Flex your profile.",
    sub: "Badges, streaks, level — show off how far you've come.",
    accent: "#0df2a6",
    side: "left",
  },
  {
    src: "/screenshots/addrecipe.png",
    alt: "Add a recipe or budget template",
    heading: "Cook up a budget.",
    sub: "Templates and recipes to get started in seconds — no spreadsheet required.",
    accent: "#00c9ff",
    side: "right",
  },
];

/* ── Animated SVG arrow (big, fancy, bouncing) ────────── */
function FancyArrow({ accent, flip }: { accent: string; flip?: boolean }) {
  return (
    <div
      className={`hidden md:flex items-center justify-center ${
        flip ? "scale-x-[-1]" : ""
      }`}
    >
      <svg
        viewBox="0 0 120 80"
        fill="none"
        className="w-28 h-20 animate-bounce-slow"
        style={{ filter: `drop-shadow(0 0 12px ${accent}80)` }}
      >
        <path
          d="M10 40 C30 10, 70 10, 90 40"
          stroke={accent}
          strokeWidth="3"
          strokeLinecap="round"
          fill="none"
          strokeDasharray="6 4"
        />
        <polygon
          points="85,30 100,42 82,48"
          fill={accent}
        />
        {/* glow circle at tip */}
        <circle cx="94" cy="40" r="6" fill={accent} opacity="0.3">
          <animate
            attributeName="r"
            values="4;8;4"
            dur="1.5s"
            repeatCount="indefinite"
          />
          <animate
            attributeName="opacity"
            values="0.4;0.15;0.4"
            dur="1.5s"
            repeatCount="indefinite"
          />
        </circle>
      </svg>
    </div>
  );
}

export default function AppGallery() {
  return (
    <section className="w-full max-w-7xl mb-24 px-4">
      {/* Intro */}
      <motion.div
        initial={{ y: 60, opacity: 0 }}
        whileInView={{ y: 0, opacity: 1 }}
        viewport={{ once: false, amount: 0.3 }}
        transition={{ duration: 0.7, ease: "easeOut" }}
        className="text-center mb-16"
      >
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          Inside the App
        </span>
        <h2 className="text-4xl md:text-6xl font-extrabold mt-3 leading-tight">
          This is what <span className="gradient-text">you get.</span>
        </h2>
        <p className="text-white/70 mt-4 max-w-xl mx-auto text-lg">
          Real screens. Real features. Swipe through what makes SnapBudget hit different.
        </p>
      </motion.div>

      {/* Showcase slides */}
      <div className="flex flex-col gap-28 md:gap-36">
        {slides.map((slide, i) => {
          const isRight = slide.side === "right";

          /* Phone + glow */
          const phoneBlock = (
            <motion.div
              key={`phone-${i}`}
              initial={{
                x: isRight ? 120 : -120,
                opacity: 0,
                rotateY: isRight ? -15 : 15,
              }}
              whileInView={{ x: 0, opacity: 1, rotateY: 0 }}
              viewport={{ once: false, amount: 0.25 }}
              transition={{ type: "spring", stiffness: 100, damping: 18 }}
              className="relative mx-auto md:mx-0 w-56 md:w-64 shrink-0"
            >
              {/* Glow behind phone */}
              <div
                className="absolute -inset-6 rounded-[2rem] blur-3xl opacity-30 pointer-events-none"
                style={{ background: slide.accent }}
              />
              <div
                className="relative rounded-[2rem] overflow-hidden border-2 shadow-2xl"
                style={{ borderColor: `${slide.accent}40` }}
              >
                <Image
                  src={slide.src}
                  alt={slide.alt}
                  width={390}
                  height={844}
                  className="w-full h-auto"
                  sizes="(max-width: 768px) 60vw, 256px"
                />
              </div>
              {/* Notch accent bar */}
              <div
                className="absolute top-3 left-1/2 -translate-x-1/2 w-20 h-1.5 rounded-full opacity-60"
                style={{ background: slide.accent }}
              />
            </motion.div>
          );

          /* Text */
          const textBlock = (
            <motion.div
              key={`text-${i}`}
              initial={{ x: isRight ? -80 : 80, opacity: 0 }}
              whileInView={{ x: 0, opacity: 1 }}
              viewport={{ once: false, amount: 0.25 }}
              transition={{ duration: 0.7, delay: 0.1, ease: "easeOut" }}
              className="flex flex-col justify-center gap-4 text-center md:text-left max-w-md"
            >
              <h3
                className="text-3xl md:text-5xl font-extrabold leading-tight"
                style={{ color: slide.accent }}
              >
                {slide.heading}
              </h3>
              <p className="text-white/70 text-base md:text-lg leading-relaxed">
                {slide.sub}
              </p>
              {/* Mobile-only small arrow */}
              <div className="md:hidden flex justify-center mt-2">
                <span
                  className="material-symbols-outlined text-4xl animate-bounce"
                  style={{ color: slide.accent }}
                >
                  arrow_downward
                </span>
              </div>
            </motion.div>
          );

          /* Arrow */
          const arrowBlock = (
            <motion.div
              key={`arrow-${i}`}
              initial={{ scale: 0, opacity: 0 }}
              whileInView={{ scale: 1, opacity: 1 }}
              viewport={{ once: false, amount: 0.3 }}
              transition={{ type: "spring", stiffness: 200, damping: 15, delay: 0.2 }}
            >
              <FancyArrow accent={slide.accent} flip={isRight} />
            </motion.div>
          );

          return (
            <div
              key={slide.heading}
              className={`flex flex-col md:flex-row items-center gap-8 md:gap-12 ${
                isRight ? "md:flex-row-reverse" : ""
              }`}
            >
              {isRight ? (
                <>
                  {phoneBlock}
                  {arrowBlock}
                  {textBlock}
                </>
              ) : (
                <>
                  {textBlock}
                  {arrowBlock}
                  {phoneBlock}
                </>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
