"use client";

import { useRef, useEffect } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

export default function Hero() {
  const sectionRef = useRef<HTMLElement>(null);
  const blobsRef = useRef<HTMLDivElement>(null);
  const headingRef = useRef<HTMLHeadingElement>(null);
  const subtitleRef = useRef<HTMLParagraphElement>(null);
  const ctaRef = useRef<HTMLDivElement>(null);
  const badgeRef = useRef<HTMLDivElement>(null);
  const flyLeftRef = useRef<HTMLDivElement>(null);
  const flyRightRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!blobsRef.current) return;
    const blobs = blobsRef.current.querySelectorAll(".hero-blob");
    blobs.forEach((blob, i) => {
      gsap.to(blob, {
        x: `random(-80, 80)`,
        y: `random(-60, 60)`,
        scale: `random(0.6, 1.6)`,
        rotation: `random(-30, 30)`,
        duration: 5 + i * 1.5,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: i * 0.8,
      });
    });
  }, []);

  // Scroll-triggered: heading fades out as you scroll past hero
  // Delayed so Framer Motion entrance animations finish first
  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    const timer = setTimeout(() => {
      // Triggered fade-out: plays once when you scroll past, stays faded
      const elements = [
        { el: headingRef.current, props: { scale: 0.85, opacity: 0, y: -40, filter: "blur(8px)" } },
        { el: subtitleRef.current, props: { opacity: 0, y: -30 } },
        { el: ctaRef.current, props: { opacity: 0, y: 30, scale: 0.95 } },
        { el: badgeRef.current, props: { opacity: 0, y: -50, scale: 0.7 } },
        { el: flyLeftRef.current, props: { x: -150, opacity: 0 } },
        { el: flyRightRef.current, props: { x: 150, opacity: 0 } },
      ];

      elements.forEach(({ el, props }) => {
        if (!el) return;
        gsap.to(el, {
          ...props,
          duration: 0.8,
          ease: "power2.in",
          scrollTrigger: {
            trigger: section,
            start: "60% top",
            toggleActions: "play none none none",
          },
        });
      });
    }, 2000);

    return () => {
      clearTimeout(timer);
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section
      ref={sectionRef}
      className="relative w-full min-h-[85vh] flex flex-col items-center justify-center text-center overflow-visible pt-8"
    >
      {/* Animated gradient mesh blobs */}
      <div ref={blobsRef} className="absolute inset-0 pointer-events-none overflow-visible">
        <div className="hero-blob absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[500px] bg-primary/25 rounded-full blur-[140px]" />
        <div className="hero-blob absolute top-1/3 left-1/4 w-[350px] h-[350px] bg-neon-blue/20 rounded-full blur-[120px]" />
        <div className="hero-blob absolute bottom-1/4 right-1/4 w-[400px] h-[300px] bg-neon-purple/20 rounded-full blur-[120px]" />
        <div className="hero-blob absolute top-1/4 right-1/3 w-[250px] h-[250px] bg-neon-pink/15 rounded-full blur-[100px]" />
        <div className="hero-blob absolute bottom-1/3 left-1/3 w-[200px] h-[200px] bg-neon-blue/10 rounded-full blur-[80px]" />
      </div>

      {/* Flying decorative elements — left */}
      <div ref={flyLeftRef} className="absolute left-[5%] top-[20%] pointer-events-none hidden md:block">
        <div className="w-8 h-8 rounded-lg bg-primary/10 border border-primary/10 float-slow" />
        <div className="w-5 h-5 rounded-full bg-neon-blue/15 border border-neon-blue/10 float-medium mt-20 ml-8" />
        <div className="w-6 h-6 rounded-lg bg-neon-purple/10 border border-neon-purple/10 float-fast mt-16 -ml-4 rotate-45" />
      </div>

      {/* Flying decorative elements — right */}
      <div ref={flyRightRef} className="absolute right-[5%] top-[25%] pointer-events-none hidden md:block">
        <div className="w-6 h-6 rounded-full bg-neon-blue/10 border border-neon-blue/10 float-medium" />
        <div className="w-9 h-9 rounded-lg bg-primary/10 border border-primary/10 float-slow mt-24 -mr-4" />
        <div className="w-5 h-5 rounded-lg bg-neon-pink/10 border border-neon-pink/10 float-fast mt-12 mr-8 rotate-12" />
      </div>

      {/* Pill badge */}
      <motion.div
        ref={badgeRef}
        initial={{ opacity: 0, y: 30, scale: 0.8 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{ duration: 0.6, type: "spring", bounce: 0.4 }}
        className="relative mb-5"
      >
        <span className="inline-flex items-center gap-2 px-6 py-2.5 rounded-full glass text-sm font-bold text-primary glow-primary">
          <span className="w-2.5 h-2.5 bg-primary rounded-full animate-pulse" style={{ boxShadow: "0 0 10px #0df2a6" }} />
          Now in Beta — Try it Free
        </span>
      </motion.div>

      {/* Main heading — enormous */}
      <motion.h2
        ref={headingRef}
        initial={{ opacity: 0, y: 60, filter: "blur(20px)" }}
        animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
        transition={{ duration: 1, delay: 0.1, ease: "easeOut" }}
        className="relative text-6xl md:text-8xl lg:text-9xl font-extrabold tracking-tight mb-5 leading-[1]"
      >
        <motion.span
          initial={{ x: -100, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.2 }}
          className="block text-white"
        >
          Budget
        </motion.span>
        <motion.span
          initial={{ x: 100, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.35 }}
          className="block gradient-text"
        >
          Smarter
        </motion.span>
        <motion.span
          initial={{ y: 40, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.5 }}
          className="block text-white/70 text-5xl md:text-7xl lg:text-8xl mt-2"
        >
          Not Harder
        </motion.span>
      </motion.h2>

      {/* Subtitle */}
      <motion.p
        ref={subtitleRef}
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.6 }}
        className="relative text-lg md:text-xl text-white/80 max-w-xl leading-relaxed mb-8"
      >
        Snap a receipt. AI does the rest. Track spending, crush goals, earn badges —{" "}
        <span className="text-primary font-bold neon-flicker">budgeting that hits different.</span>
      </motion.p>

      {/* CTA Buttons */}
      <motion.div
        ref={ctaRef}
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.8 }}
        className="relative flex flex-col sm:flex-row items-center gap-5 mb-10"
      >
        <motion.button
          whileHover={{ scale: 1.08, y: -4 }}
          whileTap={{ scale: 0.92 }}
          className="px-10 py-4 bg-linear-to-r from-[#0df2a6] to-[#00c9ff] text-black font-extrabold rounded-2xl text-lg glow-primary-strong transition-all duration-300 flex items-center gap-3 cursor-pointer"
        >
          <span className="material-symbols-outlined text-[24px]">download</span>
          Download for iOS
        </motion.button>
        <motion.button
          whileHover={{ scale: 1.08, y: -4 }}
          whileTap={{ scale: 0.92 }}
          className="px-10 py-4 glass text-white/80 font-bold rounded-2xl text-lg hover:text-white transition-all duration-300 cursor-pointer border border-white/10 hover:border-primary/40"
        >
          Watch Demo
          <span className="material-symbols-outlined text-[20px] ml-2 align-middle">play_circle</span>
        </motion.button>
      </motion.div>

      {/* Animated scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5, duration: 0.5 }}
        className="relative flex flex-col items-center gap-2"
      >
        <span className="text-xs uppercase tracking-[0.3em] text-white/55 font-bold">Scroll Down</span>
        <motion.div
          animate={{ y: [0, 12, 0] }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          className="w-6 h-10 rounded-full border-2 border-white/10 flex items-start justify-center p-2"
        >
          <motion.div
            animate={{ y: [0, 10, 0], opacity: [1, 0.2, 1] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
            className="w-1.5 h-2.5 rounded-full bg-primary"
            style={{ boxShadow: "0 0 8px #0df2a6" }}
          />
        </motion.div>
      </motion.div>
    </section>
  );
}
