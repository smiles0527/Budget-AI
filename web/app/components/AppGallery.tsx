"use client";

import { useRef, useEffect } from "react";
import Image from "next/image";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

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
      className={`fancy-arrow hidden md:flex items-center justify-center ${
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
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;
    const ctx = gsap.context(() => {
      /* Section intro */
      const intro = section.querySelector(".gallery-intro");
      if (intro) {
        gsap.fromTo(
          intro,
          { y: 60, opacity: 0 },
          {
            y: 0,
            opacity: 1,
            duration: 1,
            ease: "power3.out",
            scrollTrigger: {
              trigger: intro,
              start: "top 85%",
              toggleActions: "play reset play reset",
            },
          }
        );
      }

      /* Each showcase row */
      const rows = section.querySelectorAll(".showcase-row");
      rows.forEach((row) => {
        const phone = row.querySelector(".phone-frame");
        const text = row.querySelector(".slide-text");
        const arrow = row.querySelector(".fancy-arrow");
        const isRight = row.classList.contains("row-right");

        if (phone) {
          gsap.fromTo(
            phone,
            {
              x: isRight ? 120 : -120,
              opacity: 0,
              rotateY: isRight ? -15 : 15,
            },
            {
              x: 0,
              opacity: 1,
              rotateY: 0,
              duration: 1,
              ease: "power3.out",
              scrollTrigger: {
                trigger: row,
                start: "top 80%",
                toggleActions: "play reset play reset",
              },
            }
          );
        }

        if (text) {
          gsap.fromTo(
            text,
            { x: isRight ? -80 : 80, opacity: 0 },
            {
              x: 0,
              opacity: 1,
              duration: 0.9,
              delay: 0.15,
              ease: "power2.out",
              scrollTrigger: {
                trigger: row,
                start: "top 80%",
                toggleActions: "play reset play reset",
              },
            }
          );
        }

        if (arrow) {
          gsap.fromTo(
            arrow,
            { scale: 0, opacity: 0 },
            {
              scale: 1,
              opacity: 1,
              duration: 0.6,
              delay: 0.35,
              ease: "elastic.out(1, 0.5)",
              scrollTrigger: {
                trigger: row,
                start: "top 80%",
                toggleActions: "play reset play reset",
              },
            }
          );
        }
      });
    }, section);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-7xl mb-24 px-4">
      {/* Intro */}
      <div className="gallery-intro text-center mb-16">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          Inside the App
        </span>
        <h2 className="text-4xl md:text-6xl font-extrabold mt-3 leading-tight">
          This is what <span className="gradient-text">you get.</span>
        </h2>
        <p className="text-white/70 mt-4 max-w-xl mx-auto text-lg">
          Real screens. Real features. Swipe through what makes SnapBudget hit different.
        </p>
      </div>

      {/* Showcase slides */}
      <div className="flex flex-col gap-28 md:gap-36">
        {slides.map((slide, i) => {
          const isRight = slide.side === "right";

          /* Phone + glow */
          const phoneBlock = (
            <div key={`phone-${i}`} className="phone-frame relative mx-auto md:mx-0 w-56 md:w-64 shrink-0">
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
            </div>
          );

          /* Text + arrow */
          const textBlock = (
            <div key={`text-${i}`} className="slide-text flex flex-col justify-center gap-4 text-center md:text-left max-w-md">
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
            </div>
          );

          return (
            <div
              key={slide.heading}
              className={`showcase-row ${
                isRight ? "row-right" : "row-left"
              } flex flex-col md:flex-row items-center gap-8 md:gap-12 ${
                isRight ? "md:flex-row-reverse" : ""
              }`}
            >
              {isRight ? (
                <>
                  {phoneBlock}
                  <FancyArrow accent={slide.accent} flip />
                  {textBlock}
                </>
              ) : (
                <>
                  {textBlock}
                  <FancyArrow accent={slide.accent} />
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
