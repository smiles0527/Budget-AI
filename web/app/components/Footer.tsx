"use client";

import Link from "next/link";

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="w-full py-10 border-t border-white/5">
      <div className="max-w-7xl mx-auto px-6 md:px-12 flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-2">
          <span className="material-symbols-outlined text-primary text-xl" style={{ textShadow: "0 0 10px rgba(13,242,166,0.5)" }}>
            account_balance_wallet
          </span>
          <span className="font-bold text-white/80">SnapBudget</span>
          <span className="text-white/60 text-sm ml-2">© {currentYear}</span>
        </div>
        <div className="flex items-center gap-6">
          {["Twitter", "LinkedIn", "Instagram"].map((social) => (
            <Link
              key={social}
              href="#"
              className="text-white/60 hover:text-primary transition-colors text-sm font-medium hover:text-glow-primary"
            >
              {social}
            </Link>
          ))}
        </div>
        <div className="flex items-center gap-6 text-sm">
          <Link href="#" className="text-white/60 hover:text-primary transition-colors">
            Privacy Policy
          </Link>
          <Link href="#" className="text-white/60 hover:text-primary transition-colors">
            Terms of Service
          </Link>
        </div>
      </div>
    </footer>
  );
}
