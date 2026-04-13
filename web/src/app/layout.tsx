import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Hexlens — LoL Overlay for Mac",
  description:
    "The first League of Legends overlay for macOS. CS tracker, jungle timers, spell tracking, rune import. Native Swift. Free and open source.",
  openGraph: {
    title: "Hexlens — LoL Overlay for Mac",
    description:
      "CS tracker, jungle timers, spell tracking, rune import. Native Swift. The first LoL overlay built for macOS.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={`${inter.variable} dark antialiased`}>
      <body className="min-h-screen bg-[#06060f] text-white">{children}</body>
    </html>
  );
}
