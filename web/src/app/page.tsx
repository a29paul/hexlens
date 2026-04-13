import { Hero } from "@/components/hero";
import { OverlayPreview } from "@/components/overlay-preview";
import { Features } from "@/components/features";
import { Compliance } from "@/components/compliance";
import { InstallSection } from "@/components/install-section";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main>
      <Hero />
      <OverlayPreview />
      <Features />
      <Compliance />
      <InstallSection />
      <Footer />
    </main>
  );
}
