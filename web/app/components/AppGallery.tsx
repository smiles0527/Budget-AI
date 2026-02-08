"use client";

import { useRef, useEffect } from "react";
import Image from "next/image";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

interface Screenshot {
  src: string | null; // null = placeholder, string = real image path
  alt: string;
  label: string;
  accent: string;
}

const screenshots: Screenshot[] = [
  {
    src: null,
    alt: "Dashboard view showing spending breakdown",
    label: "Dashboard",
    accent: "#0df2a6",
  },
  {
    src: null,
    alt: "Receipt scanning in action",
    label: "Receipt Scan",
    accent: "#00c9ff",
  },
  {
    src: null,
    alt: "Budget tracking with category breakdown",
    label: "Budgets",
    accent: "#a855f7",
  },
  {
    src: null,
    alt: "Badges and streaks progress",
    label: "Badges",
    accent: "#ff6bcb",
  },
  {
    src: null,
    alt: "Savings goals tracker",
    label: "Goals",
    accent: "#0df2a6",
  },
  {
    src: null,
    alt: "Analytics and spending insights",
    label: "Insights",
    accent: "#00c9ff",
  },
];

export default function AppGallery() {
  const sectionRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sectionRef.current) return;
    const section = sectionRef.current;

    const heading = section.querySelector(".gallery-heading");
    if (heading) {
      gsap.fromTo(
        heading,
        { y: 50, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: heading,
            start: "top 85%",
            toggleActions: "play none none none",
          },
        }
      );
    }

    const cards = section.querySelectorAll(".gallery-card");
    cards.forEach((card, i) => {
      gsap.fromTo(
        card,
        { y: 40, opacity: 0, scale: 0.92 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 0.8,
          delay: i * 0.1,
          ease: "power2.out",
          scrollTrigger: {
            trigger: card,
            start: "top 90%",
            toggleActions: "play none none none",
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
      <div className="gallery-heading text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-blue text-glow-blue">
          App Preview
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          See it in <span className="gradient-text">your hands.</span>
        </h2>
        <p className="text-white/70 mt-3 max-w-lg mx-auto">
          Real screenshots from the SnapBudget iOS app — what you&apos;ll actually see.
        </p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 gap-5">
        {screenshots.map((shot) => (
          <div
            key={shot.label}
            className="gallery-card group relative rounded-2xl overflow-hidden cursor-default transition-all duration-300 hover:-translate-y-2"
          >
            {/* Phone frame wrapper */}
            <div
              className="relative aspect-[9/16] rounded-2xl overflow-hidden border border-white/10"
              style={{
                background: "linear-gradient(180deg, rgba(255,255,255,0.04) 0%, rgba(255,255,255,0.01) 100%)",
              }}
            >
              {shot.src ? (
                /* Real screenshot */
                <Image
                  src={shot.src}
                  alt={shot.alt}
                  fill
                  className="object-cover"
                  sizes="(max-width: 768px) 50vw, 33vw"
                />
              ) : (
                /* Placeholder */
                <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 p-6">
                  <div
                    className="w-16 h-16 rounded-2xl flex items-center justify-center"
                    style={{
                      background: `linear-gradient(135deg, ${shot.accent}15, transparent)`,
                      border: `1px solid ${shot.accent}30`,
                    }}
                  >
                    <span
                      className="material-symbols-outlined text-3xl"
                      style={{ color: shot.accent }}
                    >
                      phone_iphone
                    </span>
                  </div>
                  <span className="text-white/30 text-sm font-medium text-center">
                    Screenshot coming soon
                  </span>
                </div>
              )}

              {/* Gradient overlay at bottom */}
              <div className="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-black/60 to-transparent pointer-events-none" />

              {/* Hover glow */}
              <div
                className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
                style={{
                  background: `radial-gradient(circle at center, ${shot.accent}10, transparent 70%)`,
                }}
              />
            </div>

            {/* Label */}
            <div className="absolute bottom-3 left-4 right-4 z-10">
              <span
                className="text-sm font-bold"
                style={{ color: shot.accent }}
              >
                {shot.label}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Note for when screenshots are added */}
      <p className="text-center text-white/40 text-xs mt-6">
        Screenshots will be updated as the app progresses through development.
      </p>
    </section>
  );
}
