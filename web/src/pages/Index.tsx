import { Download, ExternalLink, Keyboard, Timer, Video, Monitor } from "lucide-react";
import { Button } from "@/components/ui/button";
import typepasteLogo from "@/assets/typepaste-logo.png";
import typepasteDemo from "@/assets/typepaste-demo.gif";

const GITHUB_REPO = "https://github.com/trinixlabs/typepaste";
const DOWNLOAD_URL = "https://github.com/trinixlabs/typepaste/releases/tag/v1.0.0";

const features = [
  {
    icon: Keyboard,
    title: "Global Hotkey",
    description: "Type clipboard contents into any app with a single shortcut — ⌘1.",
  },
  {
    icon: Timer,
    title: "Human-like Typing",
    description: "Configurable delays between keystrokes for a natural typing effect.",
  },
  {
    icon: Video,
    title: "Recording Mode",
    description: "Increased delays to avoid dropped characters during screen recordings.",
  },
  {
    icon: Monitor,
    title: "Menu Bar App",
    description: "Lightweight macOS menu-bar UI with quick access to all settings.",
  },
];

/* Decorative triangle SVG */
const Triangle = ({ className }: { className?: string }) => (
  <svg
    viewBox="0 0 100 100"
    className={className}
    fill="none"
    stroke="hsl(168 70% 50% / 0.08)"
    strokeWidth="2"
  >
    <polygon points="50,5 95,95 5,95" />
  </svg>
);

const Index = () => {
  return (
    <div className="relative min-h-screen overflow-hidden bg-background text-foreground">
      {/* Decorative triangles */}
      <Triangle className="absolute -top-10 -left-10 w-60 rotate-12 pointer-events-none" />
      <Triangle className="absolute top-1/4 -right-16 w-80 -rotate-6 pointer-events-none" />
      <Triangle className="absolute bottom-20 left-10 w-44 rotate-45 pointer-events-none" />
      <Triangle className="absolute top-2/3 right-1/4 w-36 rotate-[22deg] pointer-events-none" />

      {/* ── Hero ── */}
      <header className="relative z-10 flex flex-col items-center px-6 pt-24 pb-16 text-center">
        <img
          src={typepasteLogo}
          alt="TypePaste app icon"
          width={96}
          height={96}
          className="mb-6 rounded-2xl shadow-lg shadow-primary/20"
        />

        <h1 className="text-5xl font-bold tracking-tight sm:text-6xl">
          <span className="bg-gradient-to-r from-primary to-[hsl(150_60%_55%)] bg-clip-text text-transparent">
            TypePaste
          </span>
        </h1>

        <p className="mt-4 max-w-md text-lg text-muted-foreground font-mono">
          Instant typing from your clipboard
        </p>

        <div className="mt-8 flex flex-wrap justify-center gap-4">
          <Button asChild size="lg" className="gap-2 font-semibold">
            <a href={DOWNLOAD_URL} target="_blank" rel="noopener noreferrer">
              <Download className="h-4 w-4" /> Download
            </a>
          </Button>
          <Button asChild variant="outline" size="lg" className="gap-2 border-border hover:border-primary/50">
            <a href={GITHUB_REPO} target="_blank" rel="noopener noreferrer">
              <ExternalLink className="h-4 w-4" /> View on GitHub
            </a>
          </Button>
        </div>

        {/* Demo GIF */}
        <div className="mt-14 w-full max-w-2xl overflow-hidden rounded-xl border border-border shadow-2xl shadow-primary/10">
          <img
            src={typepasteDemo}
            alt="TypePaste demo showing typing simulation"
            className="w-full"
            loading="lazy"
          />
        </div>
      </header>

      {/* ── Why TypePaste ── */}
      <section className="relative z-10 mx-auto max-w-3xl px-6 py-16 text-center">
        <h2 className="text-3xl font-bold tracking-tight mb-6">Why TypePaste?</h2>
        <p className="text-muted-foreground leading-relaxed text-lg">
          Some apps and websites block pasting — login forms, terminals, code editors during demos, or
          virtual machines. <span className="text-foreground font-medium">TypePaste solves this</span> by
          simulating real keystrokes from your clipboard, character by character, so every field accepts
          your input as if you typed it by hand.
        </p>
        <p className="mt-4 text-muted-foreground leading-relaxed">
          Perfect for <span className="text-primary font-mono text-sm">screen recordings</span>,{" "}
          <span className="text-primary font-mono text-sm">live demos</span>, and anywhere paste is
          disabled or unreliable.
        </p>
      </section>

      {/* ── Features ── */}
      <section className="relative z-10 mx-auto max-w-5xl px-6 py-20">
        <h2 className="mb-12 text-center text-3xl font-bold tracking-tight">Features</h2>

        <div className="grid gap-6 sm:grid-cols-2">
          {features.map((f) => (
            <div
              key={f.title}
              className="group rounded-xl border border-border bg-card/60 backdrop-blur-sm p-6 transition-colors hover:border-primary/30"
            >
              <f.icon className="mb-3 h-6 w-6 text-primary" />
              <h3 className="text-lg font-semibold">{f.title}</h3>
              <p className="mt-1 text-sm text-muted-foreground leading-relaxed">{f.description}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── Install ── */}
      <section className="relative z-10 mx-auto max-w-2xl px-6 py-16">
        <h2 className="text-3xl font-bold tracking-tight text-center mb-8">Get Started</h2>
        <div className="rounded-xl border border-border bg-card/60 backdrop-blur-sm p-8 space-y-5">
          <div className="flex gap-4 items-start">
            <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-bold">1</span>
            <p className="text-muted-foreground">
              Download the latest release from{" "}
              <a href={DOWNLOAD_URL} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline font-medium">
                GitHub Releases
              </a>.
            </p>
          </div>
          <div className="flex gap-4 items-start">
            <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-bold">2</span>
            <p className="text-muted-foreground">
              Open <span className="font-mono text-foreground text-sm">TypePaste.app</span> — it lives in your menu bar.
            </p>
          </div>
          <div className="flex gap-4 items-start">
            <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-bold">3</span>
            <p className="text-muted-foreground">
              Copy text to your clipboard, focus the target app, and press{" "}
              <kbd className="rounded border border-border bg-secondary px-1.5 py-0.5 font-mono text-xs text-foreground">⌘1</kbd>{" "}
              to type it out.
            </p>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="relative z-10 border-t border-border py-10 text-center text-sm text-muted-foreground">
        <p className="text-lg mb-2">❤️ Open Source</p>
        <p>
          A{" "}
          <a
            href="https://trinixlabs.dev"
            target="_blank"
            rel="noopener noreferrer"
            className="text-primary hover:underline"
          >
            TrinixLabs
          </a>{" "}
          project
        </p>
      </footer>
    </div>
  );
};

export default Index;
