import type { Metadata } from "next";
import { Manrope } from "next/font/google";
import "./globals.css";

const manrope = Manrope({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["400", "500", "700", "800"],
});

export const metadata: Metadata = {
  title: "SnapBudget - Smart Expense Tracking",
  description: "The effortless way to track expenses. Snap a photo, let AI do the rest.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="light">
      <head>
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
          rel="stylesheet"
        />
      </head>
      <body
        className={`${manrope.variable} antialiased bg-background-light dark:bg-background-dark text-text-main dark:text-text-main-dark font-(--font-display) transition-colors duration-300 min-h-screen flex flex-col`}
      >
        {children}
      </body>
    </html>
  );
}
