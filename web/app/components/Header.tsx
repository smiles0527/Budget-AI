"use client";

import Link from "next/link";

export default function Header() {
  return (
    <header className="w-full px-6 py-4 md:px-12 md:py-6 flex items-center justify-between z-50 bg-background-light/80 dark:bg-background-dark/80 backdrop-blur-md sticky top-0 border-b border-gray-100 dark:border-gray-800">
      <div className="flex items-center gap-3">
        <div className="text-primary">
          <span className="material-symbols-outlined text-3xl">account_balance_wallet</span>
        </div>
        <h1 className="text-lg md:text-xl font-bold tracking-tight text-text-main dark:text-text-main-dark">
          SnapBudget:{" "}
          <span className="font-normal text-text-muted dark:text-text-muted-dark">
            Smart Expense Tracking
          </span>
        </h1>
      </div>
      <div className="flex items-center">
        <Link
          href="#"
          className="inline-flex items-center gap-2 px-4 py-2 bg-black text-white dark:bg-white dark:text-black rounded-full font-medium text-sm hover:opacity-80 transition-opacity"
        >
          <span className="material-symbols-outlined text-[20px]">download</span>
          <span className="hidden sm:inline">Download iOS App</span>
          <span className="sm:hidden">Download</span>
        </Link>
      </div>
    </header>
  );
}
