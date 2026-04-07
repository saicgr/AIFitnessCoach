import { ArrowRight, ChevronLeft, ChevronRight } from "lucide-react";
import { useState, useRef, useCallback, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";

interface GalleryHoverCarouselItem {
  id: string;
  title: string;
  summary: string;
  url: string;
  image: string;
}

export default function GalleryHoverCarousel({
  heading = "Featured Projects",
  subtitle = "Real screenshots from the app. No mockups.",
  items = [],
}: {
  heading?: string;
  subtitle?: string;
  items?: GalleryHoverCarouselItem[];
}) {
  const scrollRef = useRef<HTMLDivElement>(null);
  const [canScrollPrev, setCanScrollPrev] = useState(false);
  const [canScrollNext, setCanScrollNext] = useState(true);

  const updateScrollState = useCallback(() => {
    if (!scrollRef.current) return;
    const { scrollLeft, scrollWidth, clientWidth } = scrollRef.current;
    setCanScrollPrev(scrollLeft > 5);
    setCanScrollNext(scrollLeft < scrollWidth - clientWidth - 5);
  }, []);

  useEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    updateScrollState();
    el.addEventListener("scroll", updateScrollState, { passive: true });
    window.addEventListener("resize", updateScrollState);
    return () => {
      el.removeEventListener("scroll", updateScrollState);
      window.removeEventListener("resize", updateScrollState);
    };
  }, [updateScrollState]);

  const scroll = (dir: "prev" | "next") => {
    if (!scrollRef.current) return;
    const amount = scrollRef.current.clientWidth * 0.6;
    scrollRef.current.scrollBy({
      left: dir === "next" ? amount : -amount,
      behavior: "smooth",
    });
  };

  return (
    <section className="py-20 sm:py-28 bg-[var(--color-background)]">
      {/* Header — contained */}
      <div className="max-w-[1200px] mx-auto px-6 mb-10 md:mb-14">
        <div className="flex flex-col justify-between md:flex-row md:items-end gap-4">
          <div>
            <h3
              className="text-[32px] sm:text-[40px] lg:text-[48px] font-semibold text-[var(--color-text)] tracking-[-0.02em] leading-tight mb-2"
              style={{ fontFamily: "var(--font-heading)" }}
            >
              {heading}
            </h3>
            <p className="text-[var(--color-text-muted)] text-base sm:text-lg font-normal">
              {subtitle}
            </p>
          </div>
          <div className="flex gap-2 flex-shrink-0">
            <Button
              variant="outline"
              size="icon"
              onClick={() => scroll("prev")}
              disabled={!canScrollPrev}
              className="h-11 w-11 rounded-full"
            >
              <ChevronLeft className="h-5 w-5" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              onClick={() => scroll("next")}
              disabled={!canScrollNext}
              className="h-11 w-11 rounded-full"
            >
              <ChevronRight className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>

      {/* Carousel — full bleed, no max-w constraint */}
      <div
        ref={scrollRef}
        className="flex gap-6 sm:gap-8 overflow-x-auto pl-6 sm:pl-[max(1.5rem,calc((100vw-1200px)/2+1.5rem))] pr-6 pb-4 snap-x snap-mandatory"
        style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
      >
        {items.map((item) => (
          <Link
            key={item.id}
            to={item.url}
            className="group flex-shrink-0 snap-start w-[280px] sm:w-[320px] md:w-[340px]"
          >
            {/* Phone frame */}
            <div
              className="relative rounded-[2.8rem] p-[10px] transition-transform duration-500 ease-out group-hover:scale-[1.03] group-hover:-translate-y-2"
              style={{
                background: "linear-gradient(145deg, #3a3a3c 0%, #1c1c1e 50%, #0a0a0a 100%)",
                boxShadow: "0 40px 80px -20px rgba(0,0,0,0.5), 0 20px 40px -10px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.1)",
              }}
            >
              {/* Notch */}
              <div className="absolute top-[14px] left-1/2 -translate-x-1/2 w-24 h-7 bg-black rounded-full z-20" />

              {/* Screen */}
              <div className="relative rounded-[2.2rem] overflow-hidden bg-black" style={{ aspectRatio: "9/19.5" }}>
                <img
                  src={item.image}
                  alt={item.title}
                  className="absolute inset-0 w-full h-full object-cover object-top"
                  loading="lazy"
                />

                {/* Hover overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

                {/* Text revealed on hover */}
                <div className="absolute bottom-0 left-0 w-full p-5 translate-y-4 opacity-0 group-hover:translate-y-0 group-hover:opacity-100 transition-all duration-500 ease-out">
                  <h4 className="text-lg font-semibold text-white mb-1.5">
                    {item.title}
                  </h4>
                  <p className="text-white/70 text-sm leading-relaxed line-clamp-2">
                    {item.summary}
                  </p>
                  <div className="mt-3 inline-flex items-center gap-1.5 text-emerald-400 text-sm font-medium">
                    Learn more
                    <ArrowRight className="h-3.5 w-3.5 group-hover:translate-x-1 transition-transform duration-300" />
                  </div>
                </div>
              </div>

              {/* Home indicator */}
              <div className="absolute bottom-[8px] left-1/2 -translate-x-1/2 w-28 h-1 bg-white/20 rounded-full" />
            </div>

            {/* Label below phone */}
            <div className="text-center mt-5 px-2">
              <p className="text-[15px] font-semibold text-[var(--color-text)]">{item.title}</p>
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
}
