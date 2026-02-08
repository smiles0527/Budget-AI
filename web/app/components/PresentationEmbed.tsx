"use client";

import { useState } from "react";
import { motion } from "framer-motion";

export default function PresentationEmbed() {
  const [embedUrl, setEmbedUrl] = useState("");
  const [isLoaded, setIsLoaded] = useState(false);
  const [inputValue, setInputValue] = useState("");

  const handleEmbed = () => {
    if (!inputValue.trim()) return;

    let url = inputValue.trim();

    // Handle Canva links
    if (url.includes("canva.com")) {
      // Convert Canva share links to embed format if needed
      if (!url.includes("/embed")) {
        url = url.replace("/view", "/embed");
      }
    }
    // Handle Google Slides links
    else if (url.includes("docs.google.com/presentation")) {
      // Convert Google Slides to embed format
      if (!url.includes("/embed")) {
        url = url.replace("/pub", "/embed").replace("/edit", "/embed");
      }
    }

    setEmbedUrl(url);
    setIsLoaded(true);
  };

  return (
    <motion.section
      initial={{ opacity: 0, y: 30 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6, delay: 0.2 }}
      className="w-full max-w-6xl mb-24 relative group"
    >
      <div className="absolute -inset-1 bg-linear-to-r from-primary/30 to-blue-400/30 rounded-xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"></div>
      <div className="relative w-full aspect-video bg-white dark:bg-gray-900 rounded-xl overflow-hidden shadow-2xl border border-gray-200 dark:border-gray-700 flex flex-col">
        {/* Window Controls */}
        <div className="h-10 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-red-400"></div>
            <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
            <div className="w-3 h-3 rounded-full bg-green-400"></div>
          </div>
          <div className="text-xs font-mono text-text-muted dark:text-text-muted-dark opacity-60">
            {isLoaded ? "Presentation Loaded" : "Embed Presentation"}
          </div>
          <div className="flex gap-2 text-text-muted dark:text-text-muted-dark">
            <span className="material-symbols-outlined text-sm cursor-pointer hover:text-primary">share</span>
            <span className="material-symbols-outlined text-sm cursor-pointer hover:text-primary">fullscreen</span>
          </div>
        </div>

        {/* Main Content */}
        <div className="grow relative bg-gray-50 dark:bg-gray-800 flex items-center justify-center overflow-hidden">
          {isLoaded ? (
            <iframe
              src={embedUrl}
              className="w-full h-full border-0"
              allowFullScreen
              title="Presentation"
            />
          ) : (
            <div className="flex flex-col items-center justify-center w-full h-full p-6">
              <div className="w-full max-w-lg bg-white dark:bg-gray-900 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-700 p-8 flex flex-col items-center">
                <div className="w-16 h-16 bg-blue-50 dark:bg-blue-900/20 rounded-full flex items-center justify-center mb-6 text-blue-500 dark:text-blue-400">
                  <span className="material-symbols-outlined text-3xl">add_link</span>
                </div>
                <h3 className="text-xl font-bold text-text-main dark:text-white mb-2">
                  Embed your Presentation
                </h3>
                <p className="text-sm text-text-muted dark:text-text-muted-dark text-center mb-8">
                  Paste a public link from Canva or Google Slides to instantly preview your deck right here.
                </p>
                <div className="w-full flex flex-col sm:flex-row gap-3">
                  <div className="relative grow">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <span className="material-symbols-outlined text-gray-400 text-[20px]">link</span>
                    </div>
                    <input
                      type="text"
                      value={inputValue}
                      onChange={(e) => setInputValue(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && handleEmbed()}
                      className="block w-full pl-10 pr-3 py-2.5 border border-gray-200 dark:border-gray-700 rounded-lg leading-5 bg-gray-50 dark:bg-gray-800 text-text-main dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary sm:text-sm"
                      placeholder="Paste Slideshow Link (Canva/Google Slides)"
                    />
                  </div>
                  <button
                    onClick={handleEmbed}
                    className="bg-primary hover:bg-green-400 text-black font-semibold py-2.5 px-6 rounded-lg transition-colors flex items-center justify-center gap-2 shadow-sm hover:shadow cursor-pointer"
                  >
                    <span>Embed</span>
                    <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                  </button>
                </div>
                <div className="mt-6 flex items-center gap-4 text-xs text-text-muted dark:text-text-muted-dark">
                  <div className="flex items-center gap-1.5 opacity-60">
                    <span className="w-2 h-2 bg-gray-300 dark:bg-gray-600 rounded-full"></span>
                    <span>Supports Canva</span>
                  </div>
                  <div className="flex items-center gap-1.5 opacity-60">
                    <span className="w-2 h-2 bg-gray-300 dark:bg-gray-600 rounded-full"></span>
                    <span>Supports Google Slides</span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Bottom Bar */}
        <div className="h-12 bg-white dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700 flex items-center justify-between px-6">
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${isLoaded ? "bg-green-400" : "bg-gray-300 dark:bg-gray-600"}`}></div>
            <span className="text-xs font-medium text-text-muted dark:text-text-muted-dark">
              {isLoaded ? "Presentation loaded" : "No presentation loaded"}
            </span>
          </div>
          <div className={`flex items-center gap-4 ${!isLoaded ? "opacity-50 pointer-events-none grayscale" : ""}`}>
            <button className="text-text-muted hover:text-text-main transition-colors text-xs flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px]">chevron_left</span> Prev
            </button>
            <span className="text-xs font-bold font-mono text-text-main dark:text-white">- / -</span>
            <button className="text-text-muted hover:text-text-main transition-colors text-xs flex items-center gap-1">
              Next <span className="material-symbols-outlined text-[16px]">chevron_right</span>
            </button>
          </div>
          <div className="flex items-center">
            {isLoaded ? (
              <a
                href={embedUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs font-medium text-primary hover:text-primary/80 transition-colors flex items-center gap-1"
              >
                Open in New Tab <span className="material-symbols-outlined text-[14px]">open_in_new</span>
              </a>
            ) : (
              <span className="text-xs font-medium text-primary opacity-50 cursor-not-allowed flex items-center gap-1">
                Open in New Tab <span className="material-symbols-outlined text-[14px]">open_in_new</span>
              </span>
            )}
          </div>
        </div>
      </div>
    </motion.section>
  );
}
