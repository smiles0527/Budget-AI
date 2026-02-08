"use client";

import { useState, useRef, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

export default function PresentationEmbed() {
  const [embedUrl, setEmbedUrl] = useState("");
  const [isLoaded, setIsLoaded] = useState(false);
  const [inputValue, setInputValue] = useState("");
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [copied, setCopied] = useState(false);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [passwordInput, setPasswordInput] = useState("");
  const [passwordError, setPasswordError] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  const ADMIN_PASSWORD = "admin123";

  // Restore saved presentation on mount
  useEffect(() => {
    const saved = localStorage.getItem("snapbudget-embed-url");
    if (saved) {
      setEmbedUrl(saved);
      setIsLoaded(true);
    }
  }, []);

  const handleEmbed = () => {
    if (!inputValue.trim()) return;

    let url = inputValue.trim();

    // Handle Canva links
    if (url.includes("canva.com")) {
      if (!url.includes("/embed")) {
        url = url.replace("/view", "/embed");
      }
    }
    // Handle Google Slides links
    else if (url.includes("docs.google.com/presentation")) {
      if (!url.includes("/embed")) {
        url = url.replace("/pub", "/embed").replace("/edit", "/embed");
      }
    }

    setEmbedUrl(url);
    setIsLoaded(true);
    setIsEditing(false);
    localStorage.setItem("snapbudget-embed-url", url);
  };

  const handleReset = () => {
    setEmbedUrl("");
    setIsLoaded(false);
    setInputValue("");
    setIsEditing(false);
    localStorage.removeItem("snapbudget-embed-url");
  };

  const handleChangeRequest = () => {
    setShowPasswordModal(true);
    setPasswordInput("");
    setPasswordError(false);
  };

  const handlePasswordSubmit = () => {
    if (passwordInput === ADMIN_PASSWORD) {
      setShowPasswordModal(false);
      setIsEditing(true);
      setPasswordInput("");
      setPasswordError(false);
    } else {
      setPasswordError(true);
    }
  };

  const handleShare = useCallback(() => {
    if (!embedUrl) return;
    navigator.clipboard.writeText(embedUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }, [embedUrl]);

  const handleFullscreen = useCallback(() => {
    if (!isLoaded) return;
    setIsFullscreen(true);
  }, [isLoaded]);

  const handleExitFullscreen = useCallback(() => {
    setIsFullscreen(false);
  }, []);

  // Exit fullscreen / close modal on Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && showPasswordModal) {
        setShowPasswordModal(false);
      } else if (e.key === "Escape" && isFullscreen) {
        handleExitFullscreen();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isFullscreen, showPasswordModal, handleExitFullscreen]);

  // Lock body scroll when fullscreen
  useEffect(() => {
    if (isFullscreen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [isFullscreen]);

  return (
    <>
      {/* Password Modal */}
      <AnimatePresence>
        {showPasswordModal && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-9999 bg-black/60 backdrop-blur-sm flex items-center justify-center"
            onClick={() => setShowPasswordModal(false)}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              transition={{ duration: 0.2 }}
              className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl border border-gray-200 dark:border-gray-700 p-8 w-full max-w-sm mx-4"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 bg-amber-50 dark:bg-amber-900/20 rounded-full flex items-center justify-center text-amber-500">
                  <span className="material-symbols-outlined">lock</span>
                </div>
                <div>
                  <h3 className="text-lg font-bold text-text-main dark:text-white">Admin Access</h3>
                  <p className="text-xs text-text-muted dark:text-text-muted-dark">Enter password to change the presentation</p>
                </div>
              </div>
              <input
                type="password"
                value={passwordInput}
                onChange={(e) => { setPasswordInput(e.target.value); setPasswordError(false); }}
                onKeyDown={(e) => e.key === "Enter" && handlePasswordSubmit()}
                className={`block w-full px-4 py-2.5 border rounded-lg bg-gray-50 dark:bg-gray-800 text-text-main dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary sm:text-sm ${
                  passwordError ? "border-red-400 focus:ring-red-400 focus:border-red-400" : "border-gray-200 dark:border-gray-700"
                }`}
                placeholder="Password"
                autoFocus
              />
              {passwordError && (
                <p className="text-xs text-red-400 mt-2 flex items-center gap-1">
                  <span className="material-symbols-outlined text-[14px]">error</span>
                  Incorrect password
                </p>
              )}
              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => setShowPasswordModal(false)}
                  className="grow py-2 px-4 rounded-lg border border-gray-200 dark:border-gray-700 text-text-muted hover:bg-gray-50 dark:hover:bg-gray-800 text-sm font-medium transition-colors cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  onClick={handlePasswordSubmit}
                  className="grow py-2 px-4 rounded-lg bg-primary hover:bg-green-400 text-black text-sm font-semibold transition-colors cursor-pointer"
                >
                  Unlock
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Fullscreen Overlay */}
      <AnimatePresence>
        {isFullscreen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.35, ease: "easeInOut" }}
            className="fixed inset-0 z-9999 bg-black flex flex-col"
          >
            {/* Fullscreen top bar */}
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.25, delay: 0.1 }}
              className="h-12 bg-black/90 backdrop-blur flex items-center justify-between px-6 shrink-0"
            >
              <div className="flex items-center gap-3">
                <span className="text-primary material-symbols-outlined text-xl">account_balance_wallet</span>
                <span className="text-white/70 text-sm font-medium">SnapBudget — Presentation</span>
              </div>
              <button
                onClick={handleExitFullscreen}
                className="text-white/60 hover:text-white transition-colors flex items-center gap-2 text-sm cursor-pointer"
              >
                <span>Exit</span>
                <span className="material-symbols-outlined text-[18px]">fullscreen_exit</span>
              </button>
            </motion.div>

            {/* Fullscreen iframe */}
            <motion.div
              initial={{ opacity: 0, scale: 0.97 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.97 }}
              transition={{ duration: 0.35, delay: 0.05 }}
              className="grow"
            >
              <iframe
                src={embedUrl}
                className="w-full h-full border-0"
                allowFullScreen
                title="Presentation Fullscreen"
              />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Normal embed section */}
      <motion.section
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="w-full max-w-6xl mb-24 relative group"
      >
        <div className="absolute -inset-1 bg-linear-to-r from-primary/30 to-blue-400/30 rounded-xl blur opacity-25 group-hover:opacity-50 transition duration-1000 group-hover:duration-200"></div>
        <div
          ref={containerRef}
          className="relative w-full aspect-video bg-white dark:bg-gray-900 rounded-xl overflow-hidden shadow-2xl border border-gray-200 dark:border-gray-700 flex flex-col"
        >
          {/* Window Controls */}
          <div className="h-10 bg-gray-50 dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between px-4">
            <div className="flex items-center gap-2">
              <button
                onClick={handleReset}
                className="w-3 h-3 rounded-full bg-red-400 hover:bg-red-500 transition-colors cursor-pointer"
                title="Close presentation"
              />
              <button
                onClick={isLoaded ? handleChangeRequest : undefined}
                className={`w-3 h-3 rounded-full bg-yellow-400 transition-colors ${isLoaded ? "hover:bg-yellow-500 cursor-pointer" : ""}`}
                title={isLoaded ? "Change presentation (requires password)" : ""}
              />
              <button
                onClick={handleFullscreen}
                className={`w-3 h-3 rounded-full bg-green-400 transition-colors ${isLoaded ? "hover:bg-green-500 cursor-pointer" : "opacity-50"}`}
                title="Fullscreen"
              />
            </div>
            <div className="text-xs font-mono text-text-muted dark:text-text-muted-dark opacity-60">
              {isLoaded ? "Presentation Loaded" : "Embed Presentation"}
            </div>
            <div className="flex gap-2 text-text-muted dark:text-text-muted-dark">
              <button
                onClick={handleShare}
                disabled={!isLoaded}
                className={`transition-colors cursor-pointer ${isLoaded ? "hover:text-primary" : "opacity-40 cursor-not-allowed"}`}
                title={copied ? "Copied!" : "Copy embed link"}
              >
                <span className="material-symbols-outlined text-sm">
                  {copied ? "check" : "share"}
                </span>
              </button>
              <button
                onClick={handleFullscreen}
                disabled={!isLoaded}
                className={`transition-colors cursor-pointer ${isLoaded ? "hover:text-primary" : "opacity-40 cursor-not-allowed"}`}
                title="Present fullscreen"
              >
                <span className="material-symbols-outlined text-sm">fullscreen</span>
              </button>
            </div>
          </div>

          {/* Main Content */}
          <div className="grow relative bg-gray-50 dark:bg-gray-800 flex items-center justify-center overflow-hidden">
            {isLoaded && !isEditing ? (
              <iframe
                ref={iframeRef}
                src={embedUrl}
                className="w-full h-full border-0"
                allowFullScreen
                title="Presentation"
              />
            ) : isEditing ? (
              <div className="flex flex-col items-center justify-center w-full h-full p-6">
                <div className="w-full max-w-lg bg-white dark:bg-gray-900 rounded-2xl shadow-xl border border-gray-100 dark:border-gray-700 p-8 flex flex-col items-center">
                  <div className="w-16 h-16 bg-amber-50 dark:bg-amber-900/20 rounded-full flex items-center justify-center mb-6 text-amber-500 dark:text-amber-400">
                    <span className="material-symbols-outlined text-3xl">swap_horiz</span>
                  </div>
                  <h3 className="text-xl font-bold text-text-main dark:text-white mb-2">
                    Change Presentation
                  </h3>
                  <p className="text-sm text-text-muted dark:text-text-muted-dark text-center mb-8">
                    Paste a new presentation link to replace the current one.
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
                        placeholder="Paste new Slideshow Link"
                        autoFocus
                      />
                    </div>
                    <button
                      onClick={handleEmbed}
                      className="bg-primary hover:bg-green-400 text-black font-semibold py-2.5 px-6 rounded-lg transition-colors flex items-center justify-center gap-2 shadow-sm hover:shadow cursor-pointer"
                    >
                      <span>Update</span>
                      <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                    </button>
                  </div>
                  <button
                    onClick={() => setIsEditing(false)}
                    className="mt-4 text-xs text-text-muted hover:text-text-main dark:hover:text-white transition-colors cursor-pointer"
                  >
                    Cancel
                  </button>
                </div>
              </div>
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
            <div className="flex items-center gap-3">
              {isLoaded ? (
                <button
                  onClick={handleFullscreen}
                  className="bg-primary/10 hover:bg-primary/20 text-primary font-semibold text-xs px-4 py-1.5 rounded-full transition-colors flex items-center gap-1.5 cursor-pointer"
                >
                  <span className="material-symbols-outlined text-[16px]">slideshow</span>
                  Present
                </button>
              ) : (
                <button
                  disabled
                  className="bg-gray-100 dark:bg-gray-800 text-text-muted font-semibold text-xs px-4 py-1.5 rounded-full opacity-50 flex items-center gap-1.5 cursor-not-allowed"
                >
                  <span className="material-symbols-outlined text-[16px]">slideshow</span>
                  Present
                </button>
              )}
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
    </>
  );
}
