// "Tag @zealova when you share" nudge for share-card generators. Renders
// AFTER the user downloads their card, turning the tool into a UGC loop.
//
// Voice rules: no em dashes, no scare quotes.

interface Props {
  hashtag?: string;
}

export default function TagUsNudge({ hashtag = '#zealova' }: Props) {
  return (
    <div className="mt-4 rounded-xl border border-emerald-500/20 bg-emerald-500/5 px-4 py-3 flex flex-col sm:flex-row sm:items-center gap-2">
      <p className="text-sm text-emerald-300 flex-1">
        Sharing this? Tag <span className="font-bold">@zealova</span> on Instagram or TikTok with {hashtag}. We repost PRs and big progress drops every Sunday.
      </p>
      <div className="flex gap-2">
        <a
          href="https://instagram.com/zealova"
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs px-3 py-1.5 rounded-lg bg-zinc-900 border border-zinc-800 text-zinc-300 hover:border-emerald-500/40 hover:text-emerald-400 transition font-medium"
        >
          @zealova IG
        </a>
        <a
          href="https://tiktok.com/@getzealova"
          target="_blank"
          rel="noopener noreferrer"
          className="text-xs px-3 py-1.5 rounded-lg bg-zinc-900 border border-zinc-800 text-zinc-300 hover:border-emerald-500/40 hover:text-emerald-400 transition font-medium"
        >
          @getzealova TT
        </a>
      </div>
    </div>
  );
}
