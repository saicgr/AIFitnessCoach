// "Tag @zealova when you share" nudge for share-card generators. Renders
// AFTER the user downloads their card, turning the tool into a UGC loop.
//
// Voice rules: no em dashes, no scare quotes.

interface Props {
  hashtag?: string;
}

export default function TagUsNudge({ hashtag = '#zealova' }: Props) {
  // Theme-independent dark accent strip — literal hex throughout so the
  // light-mode palette remap leaves it alone.
  return (
    <div className="mt-4 rounded-xl border border-emerald-500/30 bg-[#0b1f17] px-4 py-3 flex flex-col sm:flex-row sm:items-center gap-3">
      <p className="text-sm text-[#d4d4d8] flex-1">
        Sharing this? Tag <span className="font-bold text-[#34d399]">@zealova</span> on Instagram or TikTok with{' '}
        <span className="font-bold text-[#34d399]">{hashtag}</span>. We repost PRs and big progress drops every Sunday.
      </p>
      <div className="flex gap-2 shrink-0">
        <a
          href="https://instagram.com/zealova"
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs px-3 py-1.5 rounded-lg bg-[#27272a] border border-[#3f3f46] text-[#fafafa] hover:border-emerald-500/50 hover:text-[#34d399] transition font-medium"
        >
          @zealova IG
        </a>
        <a
          href="https://tiktok.com/@getzealova"
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs px-3 py-1.5 rounded-lg bg-[#27272a] border border-[#3f3f46] text-[#fafafa] hover:border-emerald-500/50 hover:text-[#34d399] transition font-medium"
        >
          @getzealova TT
        </a>
      </div>
    </div>
  );
}
