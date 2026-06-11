// Vanilla three.js "volt flow field" — the ONLY file that imports three.
// One fullscreen triangle + one RawShaderMaterial = one draw call.
// The "glow" is faked in the fragment shader (exponential falloff on
// domain-warped fbm ridges); no postprocessing, no lights.

import {
  WebGLRenderer,
  Scene,
  OrthographicCamera,
  BufferGeometry,
  BufferAttribute,
  RawShaderMaterial,
  Mesh,
  Vector2,
} from 'three';

const VERT = /* glsl */ `
precision highp float;
attribute vec3 position;
void main() {
  gl_Position = vec4(position, 1.0);
}
`;

const FRAG = /* glsl */ `
precision highp float;
uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uMouse;
uniform float uOctaves;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
    u.y
  );
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.55;
  for (int i = 0; i < 3; i++) {
    if (float(i) >= uOctaves) break;
    v += a * noise(p);
    p = p * 2.1 + vec2(13.7, 7.3);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = gl_FragCoord.xy / uResolution.xy;
  vec2 p = uv * vec2(uResolution.x / uResolution.y, 1.0) * 2.2;

  // Slow domain warp + gentle mouse drift
  vec2 warp = vec2(
    fbm(p + uTime * 0.045),
    fbm(p + vec2(5.2, 1.3) - uTime * 0.03)
  );
  p += 0.55 * warp + uMouse * 0.18;

  float n = fbm(p + uTime * 0.02);

  // Thin volt filaments: distance from mid-level ridge, exponential glow
  float ridge = abs(n - 0.5);
  float filament = exp(-ridge * 26.0);
  float haze = exp(-ridge * 6.0) * 0.22;

  vec3 bg = vec3(0.031, 0.024, 0.020);                 // warm near-black
  vec3 moss = vec3(0.20, 0.09, 0.02);                  // dark ember
  vec3 volt = vec3(1.0, 0.478, 0.0);                   // #FF7A00 brand orange

  vec3 col = bg;
  col = mix(col, moss, haze);
  col += volt * filament * 0.34;

  // Vignette
  float vig = smoothstep(1.25, 0.35, length(uv - 0.5));
  col *= mix(0.55, 1.0, vig);

  gl_FragColor = vec4(col, 1.0);
}
`;

export interface VoltSceneHandle {
  setRunning(running: boolean): void;
  dispose(): void;
}

export function createVoltScene(canvas: HTMLCanvasElement): VoltSceneHandle | null {
  let renderer: WebGLRenderer;
  try {
    renderer = new WebGLRenderer({
      canvas,
      antialias: false,
      alpha: false,
      powerPreference: 'high-performance',
    });
  } catch {
    return null;
  }

  const dprCap = 1.5;
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, dprCap));

  const scene = new Scene();
  const camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);

  // Fullscreen triangle (no quad diagonal seam / overdraw)
  const geometry = new BufferGeometry();
  geometry.setAttribute(
    'position',
    new BufferAttribute(new Float32Array([-1, -1, 0, 3, -1, 0, -1, 3, 0]), 3)
  );

  const uniforms = {
    uTime: { value: 0 },
    uResolution: { value: new Vector2(1, 1) },
    uMouse: { value: new Vector2(0, 0) },
    uOctaves: { value: 3 },
  };

  const material = new RawShaderMaterial({
    vertexShader: VERT,
    fragmentShader: FRAG,
    uniforms,
    depthTest: false,
    depthWrite: false,
  });

  scene.add(new Mesh(geometry, material));

  const mouseTarget = new Vector2(0, 0);

  const resize = () => {
    const w = canvas.clientWidth || window.innerWidth;
    const h = canvas.clientHeight || window.innerHeight;
    renderer.setSize(w, h, false);
    uniforms.uResolution.value.set(
      w * renderer.getPixelRatio(),
      h * renderer.getPixelRatio()
    );
  };
  resize();
  window.addEventListener('resize', resize);

  // Mouse drift — event only writes a target; the rAF loop lerps toward it
  // (no event-driven tweens, no layout reads).
  const onPointerMove = (e: PointerEvent) => {
    mouseTarget.set(
      (e.clientX / window.innerWidth - 0.5) * 2,
      (e.clientY / window.innerHeight - 0.5) * -2
    );
  };
  window.addEventListener('pointermove', onPointerMove, { passive: true });

  let raf = 0;
  let running = false;
  let start = performance.now();
  let pausedAt = 0;

  // Adaptive degrade: measure mean frame time over the first 90 frames;
  // if the device can't hold ~60fps, drop DPR to 1 and octaves to 2.
  let frameCount = 0;
  let frameAccum = 0;
  let lastFrame = 0;
  let degraded = false;

  const loop = (now: number) => {
    if (!running) return;

    if (lastFrame > 0 && !degraded && frameCount < 90) {
      frameAccum += now - lastFrame;
      frameCount++;
      if (frameCount === 90 && frameAccum / 90 > 18) {
        degraded = true;
        renderer.setPixelRatio(1);
        uniforms.uOctaves.value = 2;
        resize();
      }
    }
    lastFrame = now;

    uniforms.uTime.value = (now - start) / 1000;
    uniforms.uMouse.value.lerp(mouseTarget, 0.05);
    renderer.render(scene, camera);
    raf = requestAnimationFrame(loop);
  };

  const setRunning = (next: boolean) => {
    if (next === running) return;
    running = next;
    if (next) {
      // Shift the clock so time doesn't jump after a pause.
      if (pausedAt) start += performance.now() - pausedAt;
      lastFrame = 0;
      raf = requestAnimationFrame(loop);
    } else {
      pausedAt = performance.now();
      cancelAnimationFrame(raf);
    }
  };

  const onVisibility = () => {
    if (document.hidden) setRunning(false);
  };
  document.addEventListener('visibilitychange', onVisibility);

  return {
    setRunning,
    dispose() {
      setRunning(false);
      window.removeEventListener('resize', resize);
      window.removeEventListener('pointermove', onPointerMove);
      document.removeEventListener('visibilitychange', onVisibility);
      geometry.dispose();
      material.dispose();
      renderer.dispose();
      renderer.forceContextLoss();
    },
  };
}
