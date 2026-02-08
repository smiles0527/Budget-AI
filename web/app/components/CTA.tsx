"use client";

import { useRef, useEffect } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export default function CTA() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const orbsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current || !orbsRef.current) return;
    const section = sectionRef.current;
    const card = section.querySelector(".cta-card") as HTMLElement;
    const badge = section.querySelector(".cta-badge") as HTMLElement;
    const heading = section.querySelector(".cta-heading") as HTMLElement;
    const desc = section.querySelector(".cta-desc") as HTMLElement;
    const buttons = section.querySelector(".cta-buttons") as HTMLElement;
    const footnote = section.querySelector(".cta-footnote") as HTMLElement;

    // Single zoom-in for the whole card
    gsap.fromTo(
      card,
      { scale: 0.7, opacity: 0, filter: "blur(10px)" },
      {
        scale: 1,
        opacity: 1,
        filter: "blur(0px)",
        duration: 1,
        ease: "power3.out",
        scrollTrigger: {
          trigger: section,
          start: "top 80%",
          end: "top 30%",
          toggleActions: "play none none none",
        },
      }
    );

    // Stagger inner elements with a simple timeline
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: section,
        start: "top 75%",
        toggleActions: "play none none none",
      },
    });
    tl.fromTo(badge, { y: -20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }, 0.3)
      .fromTo(heading, { y: 20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }, 0.4)
      .fromTo(desc, { y: 20, opacity: 0 }, { y: 0, opacity: 1, duration: 0.5, ease: "power2.out" }, 0.5)
      .fromTo(buttons, { y: 20, opacity: 0, scale: 0.95 }, { y: 0, opacity: 1, scale: 1, duration: 0.5, ease: "back.out(1.4)" }, 0.6)
      .fromTo(footnote, { opacity: 0 }, { opacity: 1, duration: 0.4 }, 0.8);

    // Floating orbs
    const orbs = orbsRef.current.querySelectorAll(".cta-orb");
    orbs.forEach((orb, i) => {
      gsap.to(orb, {
        x: `random(-80, 80)`,
        y: `random(-60, 60)`,
        scale: `random(0.5, 1.8)`,
        duration: 3 + i * 0.6,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: i * 0.3,
      });
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-5xl mb-20" style={{ perspective: 1400 }}>
      <div className="cta-card relative overflow-hidden rounded-3xl p-10 md:p-16 text-center" style={{ background: "linear-gradient(135deg, rgba(13,242,166,0.15) 0%, rgba(0,201,255,0.1) 50%, rgba(168,85,247,0.15) 100%)", border: "1px solid rgba(13,242,166,0.2)" }}>
        {/* Animated floating orbs */}
        <div ref={orbsRef} className="absolute inset-0 pointer-events-none">
          <div className="cta-orb absolute top-6 left-10 w-48 h-48 rounded-full opacity-25" style={{ background: "radial-gradient(circle, #0df2a6, transparent)" }} />
          <div className="cta-orb absolute bottom-8 right-12 w-64 h-64 rounded-full opacity-20" style={{ background: "radial-gradient(circle, #00c9ff, transparent)" }} />
          <div className="cta-orb absolute top-1/2 left-1/3 w-36 h-36 rounded-full opacity-25" style={{ background: "radial-gradient(circle, #a855f7, transparent)" }} />
          <div className="cta-orb absolute top-1/4 right-1/4 w-28 h-28 rounded-full opacity-30" style={{ background: "radial-gradient(circle, #ff6bcb, transparent)" }} />
          <div className="cta-orb absolute bottom-1/3 left-1/6 w-40 h-40 rounded-full opacity-20" style={{ background: "radial-gradient(circle, #0df2a6, transparent)" }} />
          <div className="cta-orb absolute top-10 right-1/3 w-24 h-24 rounded-full opacity-25" style={{ background: "radial-gradient(circle, #00c9ff, transparent)" }} />
        </div>

        <div className="relative z-10">
          <span className="cta-badge inline-flex items-center gap-2 glass text-primary text-xs font-bold px-6 py-2.5 rounded-full mb-8">
            <span className="material-symbols-outlined text-[16px]">rocket_launch</span>
            Built for Gen Z & Young Professionals
          </span>

          <h2 className="cta-heading text-4xl md:text-6xl font-extrabold mb-5 leading-tight">
            <span className="gradient-text-fast neon-flicker">Take control</span> of your money.
            <br />
            Start snapping today.
          </h2>
          <p className="cta-desc text-white/70 max-w-xl mx-auto mb-10 leading-relaxed text-lg">
            Join the movement of young people who are finally making budgeting simple, visual, and actually fun. No bank logins. No spreadsheets. Just you and your receipts.
          </p>

          <div className="cta-buttons flex flex-col sm:flex-row items-center justify-center gap-5">
            <motion.button
              whileHover={{ scale: 1.08, y: -4 }}
              whileTap={{ scale: 0.95 }}
              className="bg-linear-to-r from-[#0df2a6] to-[#00c9ff] text-black font-bold py-5 px-12 rounded-xl flex items-center gap-2.5 cursor-pointer text-lg"
              style={{ boxShadow: "0 0 30px rgba(13,242,166,0.4), 0 0 60px rgba(13,242,166,0.15)" }}
            >
              <span className="material-symbols-outlined text-[22px]">download</span>
              Download for iOS
            </motion.button>
            <motion.button
              whileHover={{ scale: 1.08, y: -4 }}
              whileTap={{ scale: 0.95 }}
              className="glass text-white font-semibold py-5 px-12 rounded-xl border border-white/10 hover:border-primary/40 transition-colors cursor-pointer text-lg"
            >
              Learn More
            </motion.button>
          </div>

          <p className="cta-footnote text-white/60 text-sm mt-10">
            Free to start. No credit card required.
          </p>
        </div>
      </div>
    </section>
  );
}
