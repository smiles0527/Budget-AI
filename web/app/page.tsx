"use client";

import Header from "./components/Header";
import Hero from "./components/Hero";
import PresentationEmbed from "./components/PresentationEmbed";
import Features from "./components/Features";
import Footer from "./components/Footer";

export default function Home() {
  return (
    <>
      <Header />
      <main className="grow flex flex-col items-center w-full max-w-7xl mx-auto px-6 md:px-12 pb-20">
        <Hero />
        <PresentationEmbed />
        <Features />
      </main>
      <Footer />
    </>
  );
}
