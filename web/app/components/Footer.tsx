import Link from "next/link";

export default function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="w-full py-10 border-t border-gray-100 dark:border-gray-800 bg-background-light dark:bg-background-dark">
      <div className="max-w-7xl mx-auto px-6 md:px-12 flex flex-col md:flex-row items-center justify-between gap-6">
        <p className="text-sm text-text-muted dark:text-text-muted-dark">
          © {currentYear} SnapBudget. All rights reserved.
        </p>
        <div className="flex items-center gap-6">
          <Link
            href="#"
            className="text-text-muted dark:text-text-muted-dark hover:text-primary transition-colors"
          >
            <span className="sr-only">Twitter</span>
            <span className="text-sm font-medium">Twitter</span>
          </Link>
          <Link
            href="#"
            className="text-text-muted dark:text-text-muted-dark hover:text-primary transition-colors"
          >
            <span className="sr-only">LinkedIn</span>
            <span className="text-sm font-medium">LinkedIn</span>
          </Link>
          <Link
            href="#"
            className="text-text-muted dark:text-text-muted-dark hover:text-primary transition-colors"
          >
            <span className="sr-only">Instagram</span>
            <span className="text-sm font-medium">Instagram</span>
          </Link>
        </div>
        {/* Mobile Legal Links */}
        <div className="flex items-center gap-6 text-sm text-text-muted dark:text-text-muted-dark md:hidden">
          <Link href="#" className="hover:text-primary transition-colors">
            Privacy Policy
          </Link>
          <Link href="#" className="hover:text-primary transition-colors">
            Terms of Service
          </Link>
        </div>
        {/* Desktop Legal Links */}
        <div className="hidden md:flex items-center gap-6 text-sm text-text-muted dark:text-text-muted-dark">
          <Link href="#" className="hover:text-primary transition-colors">
            Privacy Policy
          </Link>
          <Link href="#" className="hover:text-primary transition-colors">
            Terms of Service
          </Link>
        </div>
      </div>
    </footer>
  );
}
