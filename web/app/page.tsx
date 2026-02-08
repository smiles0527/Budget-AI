"use client";

import Header from "./components/Header";
import ParticleField from "./components/ParticleField";
import CursorGlow from "./components/CursorGlow";
import Marquee from "./components/Marquee";
import Hero from "./components/Hero";
import Problem from "./components/Problem";
import Features from "./components/Features";
import HowItWorks from "./components/HowItWorks";
import AppShowcase from "./components/AppShowcase";
import Stats from "./components/Stats";
import Comparison from "./components/Comparison";
import Testimonials from "./components/Testimonials";
import Trust from "./components/Trust";
import Pricing from "./components/Pricing";
import ForSchools from "./components/ForSchools";
import PresentationEmbed from "./components/PresentationEmbed";
import CTA from "./components/CTA";
import Footer from "./components/Footer";

const marqueeItems = ["SNAP", "BUDGET", "SAVE", "TRACK", "AI-POWERED", "BADGES", "GOALS", "RECEIPTS", "INSIGHTS"];

export default function Home() {
  return (
    <>
      <ParticleField />
      <CursorGlow />
      <Header />
      <main className="relative z-10 grow flex flex-col items-center w-full max-w-7xl mx-auto px-6 md:px-12 pb-20">
        <Hero />
        <Marquee items={marqueeItems} />
        <Problem />
        <Features />
        <HowItWorks />
        <AppShowcase />
        <Stats />
        <Comparison />
        <Testimonials />
        <Trust />

        <Pricing />
        <ForSchools />
        <PresentationEmbed />
        <CTA />
      </main>
      <Footer />
    </>
  );
}
