"use client";

import { useRef, useEffect } from "react";
import { motion } from "framer-motion";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(ScrollTrigger);

const plans = [
  {
    name: "Free",
    price: "$0",
    period: "forever",
    description: "Get started with the basics",
    features: [
      "Limited monthly receipt scans",
      "Basic spending charts",
      "Manual transaction entry",
      "Single budget category",
    ],
    limitations: ["Ads included", "No CSV export", "No advanced analytics"],
    cta: "Get Started Free",
    highlighted: false,
  },
  {
    name: "Premium",
    price: "$4.99",
    period: "/month",
    annual: "$49/year (save 18%)",
    description: "Everything you need to master your money",
    features: [
      "Unlimited receipt scans",
      "AI spending strategies",
      "Savings goal trackers",
      "Exportable CSV reports",
      "Ad-free experience",
      "Advanced analytics & trends",
      "Multiple budget categories",
      "Priority support",
    ],
    limitations: [],
    cta: "Start Free Trial",
    highlighted: true,
  },
];

export default function Pricing() {
  const cardsRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!cardsRef.current) return;
    const cards = cardsRef.current.querySelectorAll(".pricing-card");

    cards.forEach((card, i) => {
      // Free card flies from left, Premium from right
      gsap.fromTo(
        card,
        {
          x: i === 0 ? -300 : 300,
          y: 60,
          rotateY: i === 0 ? 25 : -25,
          opacity: 0,
          scale: 0.8,
        },
        {
          x: 0,
          y: 0,
          rotateY: 0,
          opacity: 1,
          scale: 1,
          duration: 1.2,
          ease: "back.out(1.4)",
          scrollTrigger: {
            trigger: card,
            start: "top 85%",
            end: "top 45%",
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
    <section className="w-full max-w-5xl mb-20">
      <div className="text-center mb-10">
        <span className="text-xs font-bold uppercase tracking-widest text-neon-pink text-glow-pink">
          Pricing
        </span>
        <h2 className="text-3xl md:text-5xl font-extrabold mt-3">
          Simple, <span className="gradient-text">transparent</span> pricing
        </h2>
        <p className="text-white/70 mt-3 max-w-lg mx-auto">
          Start free. Upgrade when you&apos;re ready for the full experience.
        </p>
      </div>

      <div ref={cardsRef} className="grid grid-cols-1 md:grid-cols-2 gap-8" style={{ perspective: 1200 }}>
        {plans.map((plan) => (
          <div
            key={plan.name}
            className={`pricing-card relative flex flex-col p-8 rounded-2xl overflow-hidden cursor-default transition-transform duration-300 hover:scale-[1.03] hover:-translate-y-3 ${
              plan.highlighted
                ? "glass-strong border-gradient glow-primary"
                : "glass border-gradient"
            }`}
          >
            {/* Premium card special glow */}
            {plan.highlighted && (
              <>
                <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 z-20 bg-linear-to-r from-[#0df2a6] to-[#00c9ff] text-black text-xs font-extrabold px-5 py-1.5 rounded-full" style={{ boxShadow: "0 0 25px rgba(13,242,166,0.5)" }}>
                  Most Popular
                </div>
                <div className="absolute inset-0 bg-linear-to-br from-[#0df2a6]/5 to-[#00c9ff]/5 pointer-events-none" />
              </>
            )}

            <h3 className={`text-2xl font-extrabold mb-1 ${plan.highlighted ? "gradient-text-fast" : "text-white"}`}>{plan.name}</h3>
            <p className="text-sm text-white/60 mb-6">
              {plan.description}
            </p>

            <div className="flex items-baseline gap-1 mb-1">
              <span className={`text-6xl font-extrabold ${plan.highlighted ? "text-primary text-glow-primary" : "text-white"}`}>{plan.price}</span>
              <span className="text-white/50 text-sm">
                {plan.period}
              </span>
            </div>
            {plan.annual && (
              <p className="text-xs text-neon-blue font-bold mb-6">{plan.annual}</p>
            )}
            {!plan.annual && <div className="mb-6" />}

            <ul className="space-y-3 mb-8 grow">
              {plan.features.map((feature) => (
                <li key={feature} className="flex items-start gap-2.5 text-sm">
                  <span className="material-symbols-outlined text-primary text-[18px] mt-0.5 shrink-0" style={{ textShadow: "0 0 8px rgba(13,242,166,0.5)" }}>
                    check_circle
                  </span>
                  <span className="text-white/80">{feature}</span>
                </li>
              ))}
              {plan.limitations.map((limitation) => (
                <li key={limitation} className="flex items-start gap-2.5 text-sm">
                  <span className="material-symbols-outlined text-white/50 text-[18px] mt-0.5 shrink-0">
                    cancel
                  </span>
                  <span className="text-white/60">{limitation}</span>
                </li>
              ))}
            </ul>

            <motion.button
              whileHover={{ scale: 1.06, y: -3 }}
              whileTap={{ scale: 0.95 }}
              className={`w-full py-4 px-6 rounded-xl font-bold text-sm cursor-pointer transition-all duration-300 ${
                plan.highlighted
                  ? "bg-linear-to-r from-[#0df2a6] to-[#00c9ff] text-black hover:shadow-lg glow-primary-strong"
                  : "glass border border-white/10 text-white hover:border-primary/50 hover:text-primary"
              }`}
            >
              {plan.cta}
            </motion.button>
          </div>
        ))}
      </div>
    </section>
  );
}
