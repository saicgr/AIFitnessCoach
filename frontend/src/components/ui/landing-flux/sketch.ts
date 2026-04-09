import type p5Type from 'p5';
import type { FluxElement, RowState, ElementType } from './types';
import {
  ROW_CONFIGS,
  INTER_ELEMENT_GAP,
  BAR_WIDTH,
  PILL_WIDTH,
  BROKEN_WIDTH,
  POSITIVE_LABELS,
  NEGATIVE_LABELS,
} from './constants';

// Easing helpers
const easeOut = (t: number) => 1 - Math.pow(1 - t, 3);
const easeIn = (t: number) => Math.pow(t, 3);

function randomLabel(): { label: string; positive: boolean } {
  const positive = Math.random() > 0.5;
  const list = positive ? POSITIVE_LABELS : NEGATIVE_LABELS;
  return { label: list[Math.floor(Math.random() * list.length)], positive };
}

function generateElements(barHeight: number, canvasWidth: number): FluxElement[] {
  const elements: FluxElement[] = [];
  // Generate enough elements to fill ~3x canvas width for seamless looping
  const targetWidth = canvasWidth * 3;
  let x = 0;

  while (x < targetWidth) {
    const roll = Math.random();
    let type: ElementType;
    let width: number;

    if (roll < 0.005) {
      type = 'star';
      width = barHeight;
    } else if (roll < 0.01) {
      type = 'broken';
      width = BROKEN_WIDTH;
    } else if (roll < 0.028) {
      type = 'circle';
      width = barHeight;
    } else if (roll < 0.04) {
      type = 'pill';
      width = PILL_WIDTH;
    } else if (roll < 0.44) {
      type = 'invisible';
      width = BAR_WIDTH;
    } else {
      type = 'bar';
      width = BAR_WIDTH;
    }

    const el: FluxElement = {
      type,
      x,
      width,
      opacity: 0,
      fadeDelay: Math.random() * 2000,
      fadeStarted: false,
    };

    if (type === 'star') {
      el.rotation = 0;
      el.targetRotation = 0;
      el.rotationTimer = Math.random() * 5000 + 2000;
    }

    if (type === 'circle') {
      const { label, positive } = randomLabel();
      el.label = label;
      el.positive = positive;
      el.hoverProgress = 0;
      el.chipWidth = 0;
    }

    if (type === 'broken') {
      el.gapOpen = 0;
    }

    elements.push(el);
    x += width + INTER_ELEMENT_GAP;
  }

  return elements;
}

function initRows(
  numRows: number,
  barHeight: number,
  canvasWidth: number,
): RowState[] {
  const rows: RowState[] = [];
  for (let i = 0; i < numRows; i++) {
    const cfg = ROW_CONFIGS[i % ROW_CONFIGS.length];
    const elements = generateElements(barHeight, canvasWidth);
    const totalWidth = elements.length > 0
      ? elements[elements.length - 1].x + elements[elements.length - 1].width + INTER_ELEMENT_GAP
      : canvasWidth;

    rows.push({
      elements,
      offset: 0,
      speed: cfg[0],
      direction: cfg[1] >= 0 ? 1 : -1,
      totalWidth,
      hoveredCircle: null,
      hoverBarProgress: 0,
      hoverBarX: 0,
      hoverBarWidth: 0,
      hoverBarActive: false,
    });
  }
  return rows;
}

export function createSketch(
  numRows: number,
  barHeight: number,
  gap: number,
  colorHex: string,
  disableMarquee: boolean,
  getContainerWidth: () => number,
) {
  let rows: RowState[] = [];
  let startTime = 0;
  let r = 0, g = 0, b = 0;

  return (p: p5Type) => {
    p.setup = () => {
      const w = getContainerWidth();
      const h = numRows * barHeight + (numRows - 1) * gap + 40;
      p.createCanvas(w, h);
      p.textFont('Inter, system-ui, sans-serif');
      p.textSize(11);
      p.noStroke();

      // Parse hex color
      const c = p.color(colorHex);
      r = p.red(c);
      g = p.green(c);
      b = p.blue(c);

      rows = initRows(numRows, barHeight, w);
      startTime = p.millis();
    };

    p.draw = () => {
      p.clear();
      const now = p.millis();
      const elapsed = now - startTime;
      const mx = p.mouseX;
      const my = p.mouseY;

      for (let ri = 0; ri < rows.length; ri++) {
        const row = rows[ri];
        const rowY = 20 + ri * (barHeight + gap);

        // Check if mouse is in this row's vertical band
        const mouseInRow = my >= rowY && my <= rowY + barHeight && mx >= 0 && mx <= p.width;

        // Scroll speed: pause row if a circle is hovered
        let scrollSpeed = disableMarquee ? 0 : row.speed * row.direction;
        if (row.hoveredCircle !== null) {
          scrollSpeed = 0;
        }
        row.offset += scrollSpeed;

        // Wrap offset for seamless loop
        if (Math.abs(row.offset) > row.totalWidth / 3) {
          row.offset = row.offset % (row.totalWidth / 3);
        }

        // Reset hover state
        let foundCircle = false;

        for (let ei = 0; ei < row.elements.length; ei++) {
          const el = row.elements[ei];

          // Fade in animation
          if (!el.fadeStarted && elapsed > el.fadeDelay) {
            el.fadeStarted = true;
          }
          if (el.fadeStarted && el.opacity < 255) {
            el.opacity = Math.min(255, el.opacity + 6);
          }
          if (el.type === 'invisible') continue;

          // Screen-space X (wrap for seamless loop)
          let sx = (el.x + row.offset) % (row.totalWidth);
          if (sx < -el.width - 100) sx += row.totalWidth;
          if (sx > p.width + 100) continue;

          const alpha = el.opacity;

          switch (el.type) {
            case 'bar': {
              p.fill(r, g, b, alpha);
              p.rect(sx, rowY, BAR_WIDTH, barHeight, 1);
              break;
            }

            case 'star': {
              // Rotate star at random intervals
              el.rotationTimer! -= p.deltaTime;
              if (el.rotationTimer! <= 0) {
                el.targetRotation! += Math.PI / 2;
                el.rotationTimer = Math.random() * 5000 + 2000;
              }
              // Lerp rotation
              el.rotation = el.rotation! + (el.targetRotation! - el.rotation!) * 0.05;

              p.push();
              p.translate(sx + barHeight / 2, rowY + barHeight / 2);
              p.rotate(el.rotation!);
              p.fill(r, g, b, alpha);
              drawStar(p, 0, 0, barHeight * 0.15, barHeight * 0.45);
              p.pop();
              break;
            }

            case 'circle': {
              const diameter = barHeight - 2.5;
              const cx = sx + diameter / 2;
              const cy = rowY + barHeight / 2;
              const isHovered = mouseInRow &&
                mx >= sx - 4 && mx <= sx + diameter + 4 &&
                my >= rowY - 2 && my <= rowY + barHeight + 2;

              if (isHovered) {
                foundCircle = true;
                row.hoveredCircle = ei;
                el.hoverProgress = Math.min(1, (el.hoverProgress ?? 0) + 0.06);
              } else {
                el.hoverProgress = Math.max(0, (el.hoverProgress ?? 0) - 0.08);
                if (row.hoveredCircle === ei) row.hoveredCircle = null;
              }

              const t = easeOut(el.hoverProgress!);

              if (t > 0.01) {
                // Expanded chip
                const labelW = p.textWidth(el.label!) + 40;
                const chipW = diameter + (labelW - diameter) * t;
                const chipH = diameter + (26 - diameter) * t;
                const chipX = cx - chipW / 2;
                const chipY = cy - chipH / 2;

                // Chip background
                const bgR = el.positive ? 34 : 200;
                const bgG = el.positive ? 150 : 50;
                const bgB = el.positive ? 80 : 50;
                p.fill(
                  r + (bgR - r) * t,
                  g + (bgG - g) * t,
                  b + (bgB - b) * t,
                  alpha,
                );
                p.rect(chipX, chipY, chipW, chipH, chipH / 2);

                // Text + indicator
                if (t > 0.3) {
                  const textAlpha = Math.min(255, (t - 0.3) / 0.7 * 255);
                  p.fill(255, 255, 255, textAlpha);
                  p.textAlign(p.CENTER, p.CENTER);
                  p.text(el.label!, cx, cy - 1);

                  // Triangle indicator
                  const triX = cx + p.textWidth(el.label!) / 2 + 10;
                  const triSize = 4;
                  p.fill(255, 255, 255, textAlpha);
                  if (el.positive) {
                    p.triangle(triX, cy - triSize, triX - triSize, cy + triSize, triX + triSize, cy + triSize);
                  } else {
                    p.triangle(triX - triSize, cy - triSize, triX + triSize, cy - triSize, triX, cy + triSize);
                  }
                }
              } else {
                // Simple dot
                p.fill(r, g, b, alpha);
                p.ellipse(cx, cy, diameter, diameter);
              }
              break;
            }

            case 'broken': {
              // Animate gap open/close at random intervals
              const isHoveredBroken = mouseInRow && mx >= sx - 4 && mx <= sx + BROKEN_WIDTH + 4;
              if (isHoveredBroken) {
                el.gapOpen = Math.min(1, (el.gapOpen ?? 0) + 0.04);
              } else {
                el.gapOpen = Math.max(0, (el.gapOpen ?? 0) - 0.03);
              }
              const gapSize = easeOut(el.gapOpen!) * (barHeight * 0.35);
              const halfH = (barHeight - gapSize) / 2;

              p.fill(r, g, b, alpha);
              p.rect(sx, rowY, BROKEN_WIDTH, halfH, 1);
              p.rect(sx, rowY + halfH + gapSize, BROKEN_WIDTH, halfH, 1);
              break;
            }

            case 'pill': {
              p.noFill();
              p.stroke(r, g, b, alpha * 0.6);
              p.strokeWeight(1.5);
              p.rect(sx, rowY + 1, PILL_WIDTH, barHeight - 2, barHeight / 2);
              p.noStroke();
              break;
            }
          }
        }

        if (!foundCircle) {
          row.hoveredCircle = null;
        }

        // Hover bar in gap between elements
        if (mouseInRow && !foundCircle) {
          // Find the gap the mouse is in
          let inGap = false;
          for (let ei = 0; ei < row.elements.length - 1; ei++) {
            const el = row.elements[ei];
            if (el.type === 'invisible') continue;
            let sx = (el.x + row.offset) % row.totalWidth;
            if (sx < -200) sx += row.totalWidth;
            const elEnd = sx + el.width;
            const nextEl = row.elements[ei + 1];
            let nextSx = (nextEl.x + row.offset) % row.totalWidth;
            if (nextSx < -200) nextSx += row.totalWidth;

            if (mx >= elEnd && mx <= nextSx && nextSx - elEnd > 4) {
              inGap = true;
              if (!row.hoverBarActive || Math.abs(row.hoverBarX - elEnd) > 2) {
                row.hoverBarX = elEnd + 1;
                row.hoverBarWidth = nextSx - elEnd - 2;
              }
              row.hoverBarActive = true;
              break;
            }
          }
          if (!inGap) {
            row.hoverBarActive = false;
          }
        } else {
          row.hoverBarActive = false;
        }

        // Animate hover bar
        if (row.hoverBarActive) {
          row.hoverBarProgress = Math.min(1, row.hoverBarProgress + 0.08);
        } else {
          row.hoverBarProgress = Math.max(0, row.hoverBarProgress - 0.06);
        }

        if (row.hoverBarProgress > 0.001) {
          const t = row.hoverBarActive ? easeIn(row.hoverBarProgress) : easeOut(1 - row.hoverBarProgress);
          const barW = row.hoverBarWidth * (row.hoverBarActive ? easeIn(row.hoverBarProgress) : (1 - easeIn(1 - row.hoverBarProgress)));
          p.fill(r, g, b, 200 * t);
          p.rect(row.hoverBarX, rowY, barW, barHeight, 1);
        }
      }
    };

    p.windowResized = () => {
      const w = getContainerWidth();
      const h = numRows * barHeight + (numRows - 1) * gap + 40;
      p.resizeCanvas(w, h);
    };

    // Touch support — p5 v2 uses event handlers on canvas directly
    // mouseX/mouseY are set from touch events automatically by p5
  };
}

// 4-pointed star using vertices (alternating outer/inner points)
function drawStar(p: p5Type, cx: number, cy: number, innerR: number, outerR: number) {
  p.beginShape();
  for (let i = 0; i < 8; i++) {
    const angle = (i * Math.PI) / 4;
    const radius = i % 2 === 0 ? outerR : innerR;
    p.vertex(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
  }
  p.endShape(p.CLOSE);
}
