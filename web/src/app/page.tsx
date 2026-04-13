import { Hero } from "@/components/hero";
import { OverlayPreview } from "@/components/overlay-preview";
import { Features } from "@/components/features";
import { InstallSection } from "@/components/install-section";
import { Footer } from "@/components/footer";

export default function Home() {
  return (
    <main>
      <Hero />
      <OverlayPreview />
      <Features />
      <InstallSection />
      <Footer />
    </main>
  );
}
