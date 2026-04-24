"""
Renders two-panel all-in cost chart for FitWiz Pro B2B strategy doc.

Panel 1: Base platform cost (sticker price only)
Panel 2: ALL-IN coach cost = base + mandatory add-ons + platform take rate
         assuming $200/mo average GMV per client (mid-range online-coaching rate)
         Inset shows full TrueCoach 5% curve which otherwise explodes off-chart.
"""
import matplotlib.pyplot as plt

# ----- data -----
clients = [5, 15, 30, 50, 75, 100, 200]
gmv_per_client = 200  # realistic mid-range online coaching price

base = {
    "Trainerize Pro":       [25, 50, 79, 135, 180, 225, 250],
    "Everfit (Pro-Studio)": [19, 19, 19, 105, 105, 105, 105],
    "TrueCoach":            [30, 70, 165, 165, 165, 165, 165],
    "FitBudd":              [15, 79, 79, 149, 149, 149, 149],
    "MyPTHub Premium":      [25, 59, 59,  59,  59,  59,  59],
    "FitWiz Pro":           [ 0, 39, 39,  39,  39,  39,  99],
}

mandatory_addons = {
    "Trainerize Pro":       55,
    "Everfit (Pro-Studio)": 73,
    "TrueCoach":             0,
    "FitBudd":               0,
    "MyPTHub Premium":       0,
    "FitWiz Pro":            0,
}

take_rate_pct = {
    "Trainerize Pro":       0.0,
    "Everfit (Pro-Studio)": 0.25,
    "TrueCoach":            5.0,
    "FitBudd":              0.0,
    "MyPTHub Premium":      0.0,
    "FitWiz Pro":           1.0,
}
take_rate_cap = {"FitWiz Pro": 300}

def take_fee(platform, n):
    pct = take_rate_pct[platform]
    raw = n * gmv_per_client * pct / 100.0
    cap = take_rate_cap.get(platform)
    return min(raw, cap) if cap else raw

allin = {
    name: [vals[i] + mandatory_addons[name] + take_fee(name, clients[i])
           for i in range(len(clients))]
    for name, vals in base.items()
}

colors = {
    "Trainerize Pro":       "#FFC107",
    "Everfit (Pro-Studio)": "#2196F3",
    "TrueCoach":            "#9C27B0",
    "FitBudd":              "#795548",
    "MyPTHub Premium":      "#607D8B",
    "FitWiz Pro":           "#00C853",
}

# ----- plot -----
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 11), dpi=150, sharex=True,
                                gridspec_kw={"height_ratios": [1, 1], "hspace": 0.32})

def draw_panel(ax, data, title, ylim):
    for name, vals in data.items():
        lw = 4 if name == "FitWiz Pro" else 2
        clipped = [min(v, ylim * 0.98) for v in vals]
        ax.plot(clients, clipped, marker="o", label=name,
                color=colors[name], linewidth=lw, markersize=7)
    ax.set_title(title, fontsize=13, fontweight="bold", pad=10, loc="left")
    ax.set_ylabel("USD / month", fontsize=11)
    ax.set_xticks(clients)
    ax.set_ylim(0, ylim)
    ax.grid(True, linestyle="--", alpha=0.35)
    ax.set_facecolor("#FAFAFA")

    # End-of-line labels, stagger if collision
    end_vals = sorted(
        [(name, vals[-1]) for name, vals in data.items()],
        key=lambda x: x[1]
    )
    last_y = -999
    for name, y in end_vals:
        off_chart = y > ylim
        display_y = min(y, ylim * 0.95)
        if display_y - last_y < ylim * 0.05:
            display_y = last_y + ylim * 0.05
        last_y = display_y
        txt = f"USD {int(y)}" + (" (off)" if off_chart else "")
        ax.annotate(txt, xy=(200, display_y),
                    xytext=(8, 0), textcoords="offset points",
                    color=colors[name], fontsize=10,
                    fontweight=("bold" if name == "FitWiz Pro" else "normal"),
                    va="center")

draw_panel(ax1, base,
           "Panel 1 -- Base sticker price only (no add-ons, no take rate)", 300)
draw_panel(ax2, allin,
           f"Panel 2 -- ALL-IN coach cost = base + mandatory add-ons + take rate at {gmv_per_client} USD/mo avg GMV per client",
           600)

ax2.set_xlabel("Active clients on coach's roster", fontsize=11)
ax1.legend(loc="upper left", fontsize=10, framealpha=0.95, ncol=2)

fig.suptitle("FitWiz Pro vs Competitors -- Real Coach Cost at Scale",
             fontsize=16, fontweight="bold", y=0.995)

fig.text(
    0.5, 0.005,
    "FitWiz Pro: 1% platform fee on client GMV, CAPPED at 300 USD/mo. "
    "Everfit: 0.25% hidden Stripe markup. TrueCoach: 5% flat (explodes at scale -- off chart above ~40 clients). "
    "Trainerize/FitBudd/MyPTHub: 0% markup (Stripe passthrough). "
    "Source: April 2026 competitor pricing pages.",
    ha="center", fontsize=9, color="#555",
)

plt.tight_layout(rect=[0, 0.025, 1, 0.975])
out = "/Users/saichetangrandhe/AIFitnessCoach/docs/fitwiz-pro/pricing_chart.png"
fig.savefig(out, dpi=150, bbox_inches="tight", facecolor="white")
print(f"saved: {out}")

# Print numeric table for the doc
print("\nALL-IN at 200 USD/client/mo GMV:")
print(f"{'Clients':>8} | " + " | ".join(f"{k[:14]:>14}" for k in base.keys()))
for i, n in enumerate(clients):
    row = " | ".join(f"{int(allin[k][i]):>14d}" for k in base.keys())
    print(f"{n:>8d} | {row}")
