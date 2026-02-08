"use client";

interface MarqueeProps {
  items: string[];
  reverse?: boolean;
  className?: string;
}

export default function Marquee({ items, reverse = false, className = "" }: MarqueeProps) {
  const doubled = [...items, ...items];

  return (
    <div className={`w-full overflow-hidden py-5 ${className}`}>
      <div className={reverse ? "marquee-track-reverse" : "marquee-track"}>
        {doubled.map((item, i) => (
          <span
            key={i}
            className="flex items-center gap-3 px-6 text-sm md:text-base font-bold whitespace-nowrap"
          >
            <span className="text-white/8 uppercase tracking-widest">{item}</span>
            <span className="text-primary/30 text-lg">✦</span>
          </span>
        ))}
      </div>
    </div>
  );
}
