import { ArrowRight, ChevronLeft, ChevronRight } from "lucide-react";
import { useState, useRef, useCallback, useEffect } from "react";
import { Card } from "@/components/ui/card";
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
  items = [],
}: {
  heading?: string;
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
    const amount = scrollRef.current.clientWidth * 0.7;
    scrollRef.current.scrollBy({
      left: dir === "next" ? amount : -amount,
      behavior: "smooth",
    });
  };

  return (
    <section className="py-20 sm:py-28 bg-[var(--color-background)]">
      <div className="max-w-[1200px] mx-auto px-6">
        {/* Header */}
        <div className="mb-10 flex flex-col justify-between md:mb-14 md:flex-row md:items-end">
          <div className="max-w-2xl">
            <h3
              className="text-2xl sm:text-3xl lg:text-4xl font-semibold text-[var(--color-text)] tracking-[-0.02em] leading-snug"
              style={{ fontFamily: "var(--font-heading)" }}
            >
              {heading}{" "}
              <span className="text-[var(--color-text-muted)] text-lg sm:text-xl lg:text-2xl font-normal">
                Real screenshots from the app. No mockups.
              </span>
            </h3>
          </div>
          <div className="flex gap-2 mt-4 md:mt-0">
            <Button
              variant="outline"
              size="icon"
              onClick={() => scroll("prev")}
              disabled={!canScrollPrev}
              className="h-10 w-10 rounded-full"
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              onClick={() => scroll("next")}
              disabled={!canScrollNext}
              className="h-10 w-10 rounded-full"
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* Carousel */}
        <div
          ref={scrollRef}
          className="flex gap-5 overflow-x-auto pb-4 snap-x snap-mandatory"
          style={{ scrollbarWidth: "none", msOverflowStyle: "none" }}
        >
          {items.map((item) => (
            <Link
              key={item.id}
              to={item.url}
              className="group flex-shrink-0 snap-start w-[300px] sm:w-[360px] md:w-[400px]"
            >
              <Card className="overflow-hidden rounded-3xl h-[520px] sm:h-[600px] md:h-[660px] relative border-0 shadow-lg">
                {/* Image — full height, shrinks to half on hover */}
                <div className="relative h-full w-full transition-all duration-500 ease-out group-hover:h-1/2">
                  <img
                    src={item.image}
                    alt={item.title}
                    className="h-full w-full object-cover object-top"
                    loading="lazy"
                  />
                  {/* Bottom fade on hover */}
                  <div className="absolute bottom-0 left-0 w-full h-24 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
                </div>

                {/* Text section — revealed on hover */}
                <div className="absolute bottom-0 left-0 w-full h-0 group-hover:h-1/2 transition-all duration-500 ease-out overflow-hidden bg-[var(--color-surface)]/95 backdrop-blur-sm flex flex-col justify-center px-5 opacity-0 group-hover:opacity-100">
                  <h4 className="text-lg font-semibold text-[var(--color-text)] mb-2">
                    {item.title}
                  </h4>
                  <p className="text-[var(--color-text-secondary)] text-sm leading-relaxed line-clamp-3">
                    {item.summary}
                  </p>
                  <div className="absolute bottom-3 right-3">
                    <Button
                      variant="outline"
                      size="icon"
                      className="h-9 w-9 rounded-full group-hover:hover:-rotate-45 transition-all duration-300"
                      tabIndex={-1}
                    >
                      <ArrowRight className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}
