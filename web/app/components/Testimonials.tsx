"use client";

import { useRef, useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const testimonials = [
  {
    name: "Maya R.",
    age: 19,
    role: "College Sophomore",
    initials: "MR",
    color: "#0df2a6",
    quote:
      "I used to just... not look at my bank account. Now I actually enjoy checking my spending. The badges make it feel like a game.",
    highlight: "The badges make it feel like a game",
    rating: 5,
  },
  {
    name: "Jordan T.",
    age: 22,
    role: "Recent Graduate",
    initials: "JT",
    color: "#00c9ff",
    quote:
      "Every other budgeting app wanted my bank login. SnapBudget just lets me take photos. That's it. That's the tweet.",
    highlight: "just lets me take photos",
    rating: 5,
  },
  {
    name: "Aaliyah K.",
    age: 17,
    role: "High School Senior",
    initials: "AK",
    color: "#a855f7",
    quote:
      "My parents kept telling me to track my money. Spreadsheets? No way. But this? I actually use it every day. The streaks keep me going.",
    highlight: "I actually use it every day",
    rating: 5,
  },
  {
    name: "Chris M.",
    age: 24,
    role: "Freelance Designer",
    initials: "CM",
    color: "#ff6bcb",
    quote:
      "As a freelancer, my income is all over the place. Being able to snap receipts and see where my money goes saved me from a lot of stress.",
    highlight: "saved me from a lot of stress",
    rating: 5,
  },
  {
    name: "Priya S.",
    age: 20,
    role: "Business Student",
    initials: "PS",
    color: "#0df2a6",
    quote:
      "The AI categorization is crazy accurate. I scanned a Chipotle receipt and it knew it was dining before I even saw the result. 10/10.",
    highlight: "crazy accurate",
    rating: 5,
  },
  {
    name: "Liam D.",
    age: 16,
    role: "Part-Time Worker",
    initials: "LD",
    color: "#00c9ff",
    quote:
      "I just started my first job at a restaurant and this app helps me see exactly where my paycheck goes. Way better than any bank app.",
    highlight: "Way better than any bank app",
    rating: 5,
  },
];

export default function Testimonials() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const heading = section.querySelector(".test-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { y: 60, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            toggleActions: "play reset play reset",
          },
        }
      );
    }

    const cards = section.querySelectorAll(".test-card");
    cards.forEach((card, i) => {
      // Soft fade + blur — no harsh directional movement
      gsap.fromTo(
        card,
        {
          y: 30,
          opacity: 0,
          filter: "blur(10px)",
        },
        {
          y: 0,
          opacity: 1,
          filter: "blur(0px)",
          duration: 0.7,
          delay: i * 0.08,
          ease: "power2.out",
          scrollTrigger: {
            trigger: card,
            start: "top 92%",
            toggleActions: "play reset play reset",
          },
        }
      );
    });

    return () => {
      ScrollTrigger.getAll().forEach((t) => t.kill());
    };
  }, []);

  return (
    <section ref={sectionRef} className="w-full max-w-6xl mb-20">
      <div className="test-heading text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          What Users Say
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Real people. <span className="gradient-text">Real results.</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-lg mx-auto">
          Don&apos;t take our word for it — hear from users like you.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {testimonials.map((t) => (
          <div
            key={t.name}
            className="test-card glass border border-white/5 rounded-2xl p-6 flex flex-col hover:border-primary/20 hover:-translate-y-2 transition-all duration-300 group"
          >
            {/* Stars */}
            <div className="flex gap-0.5 mb-3">
              {Array.from({ length: t.rating }).map((_, i) => (
                <span key={i} className="text-yellow-400 text-sm">★</span>
              ))}
            </div>

            {/* Quote */}
            <p className="text-sm text-white/75 leading-relaxed mb-4 grow">
              &ldquo;{t.quote}&rdquo;
            </p>

            {/* Avatar & info */}
            <div className="flex items-center gap-3 pt-3 border-t border-white/5">
              <div className="w-10 h-10 rounded-full flex items-center justify-center text-xs font-bold group-hover:scale-110 transition-transform" style={{ background: `${t.color}20`, color: t.color }}>
                {t.initials}
              </div>
              <div>
                <p className="text-sm font-bold text-white/80">{t.name}</p>
                <p className="text-[11px] text-white/50">
                  {t.role}, age {t.age}
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
