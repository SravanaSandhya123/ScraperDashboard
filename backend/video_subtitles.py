import os
import io
import base64
import argparse
from typing import List, Tuple, Optional

import cv2
import numpy as np
from PIL import Image


def format_timestamp(seconds: float) -> str:
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds - int(seconds)) * 1000)
    return f"{hours:02d}:{minutes:02d}:{secs:02d},{millis:03d}"


def image_to_data_url(image: np.ndarray, quality: int = 85) -> str:
    pil_img = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    buf = io.BytesIO()
    pil_img.save(buf, format="JPEG", quality=quality)
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    return f"data:image/jpeg;base64,{b64}"


def compute_histogram_similarity(frame_a: np.ndarray, frame_b: np.ndarray) -> float:
    a_hsv = cv2.cvtColor(frame_a, cv2.COLOR_BGR2HSV)
    b_hsv = cv2.cvtColor(frame_b, cv2.COLOR_BGR2HSV)
    a_hist = cv2.calcHist([a_hsv], [0, 1], None, [32, 32], [0, 180, 0, 256])
    b_hist = cv2.calcHist([b_hsv], [0, 1], None, [32, 32], [0, 180, 0, 256])
    cv2.normalize(a_hist, a_hist)
    cv2.normalize(b_hist, b_hist)
    # Correlation in [0..1], higher is more similar
    sim = cv2.compareHist(a_hist, b_hist, cv2.HISTCMP_CORREL)
    # Clip to [0, 1] because sometimes numerical issues cause slight negatives
    return float(max(0.0, min(1.0, sim)))


def detect_segments(
    video_path: str,
    min_segment_seconds: float = 2.0,
    similarity_threshold: float = 0.85,
    max_segments: Optional[int] = None,
) -> Tuple[List[Tuple[int, int]], float, int]:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Failed to open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT) or 0)
    if total_frames <= 0:
        # Fallback: iterate to count frames
        total_frames = 0
        while True:
            ret, _ = cap.read()
            if not ret:
                break
            total_frames += 1
        cap.release()
        cap = cv2.VideoCapture(video_path)

    frames_per_min_segment = max(1, int(round(min_segment_seconds * fps)))

    segments: List[Tuple[int, int]] = []
    prev_key_frame: Optional[np.ndarray] = None
    seg_start = 0

    frame_index = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        if prev_key_frame is None:
            prev_key_frame = frame
            frame_index += 1
            continue

        # Create a boundary if content changes a lot and min length satisfied
        if (frame_index - seg_start) >= frames_per_min_segment:
            similarity = compute_histogram_similarity(prev_key_frame, frame)
            if similarity < similarity_threshold:
                segments.append((seg_start, frame_index))
                seg_start = frame_index
                prev_key_frame = frame
                if max_segments and len(segments) >= max_segments:
                    # Snap last segment to end of current frame_index
                    break

        frame_index += 1

    # Close last segment
    if seg_start < total_frames:
        segments.append((seg_start, total_frames - 1))

    cap.release()
    duration_seconds = total_frames / fps if fps > 0 else 0.0
    return segments, duration_seconds, total_frames


def extract_representative_frames(video_path: str, segments: List[Tuple[int, int]]) -> List[np.ndarray]:
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Failed to open video: {video_path}")
    frames: List[np.ndarray] = []
    for start_idx, end_idx in segments:
        rep_idx = (start_idx + end_idx) // 2
        cap.set(cv2.CAP_PROP_POS_FRAMES, rep_idx)
        ret, frame = cap.read()
        if not ret:
            # Fallback to start frame if middle failed
            cap.set(cv2.CAP_PROP_POS_FRAMES, start_idx)
            ret, frame = cap.read()
        if not ret:
            # Create a blank placeholder
            frame = np.zeros((360, 640, 3), dtype=np.uint8)
        frames.append(frame)
    cap.release()
    return frames


def caption_with_openai(frames: List[np.ndarray], system_prompt: str, model: str = "gpt-4o-mini") -> List[str]:
    try:
        from openai import OpenAI
    except Exception as exc:
        raise RuntimeError("openai package not installed. Install with: pip install openai") from exc

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        raise RuntimeError("OPENAI_API_KEY environment variable is required for OpenAI provider.")

    client = OpenAI(api_key=api_key)

    # Batch frames into a single prompt to reduce API calls, but keep within limits
    contents = [{"type": "text", "text": "Generate one concise subtitle per image, only the text content, no numbering."}]
    for frame in frames:
        contents.append({"type": "image_url", "image_url": {"url": image_to_data_url(frame)}})

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": contents},
        ],
        temperature=0.2,
    )

    text = response.choices[0].message.content.strip()
    # Split by lines, align to frames
    lines = [line.strip("- ").strip() for line in text.splitlines() if line.strip()]
    if len(lines) < len(frames):
        # Pad if model returned fewer lines
        lines += [lines[-1] if lines else "(no significant change)" for _ in range(len(frames) - len(lines))]
    return lines[: len(frames)]


def caption_with_groq(frames: List[np.ndarray], system_prompt: str, model: str = "llama-3.2-vision") -> List[str]:
    try:
        from groq import Groq
    except Exception as exc:
        raise RuntimeError("groq package not installed. Install with: pip install groq") from exc

    api_key = os.getenv("GROQ_API_KEY")
    if not api_key:
        raise RuntimeError("GROQ_API_KEY environment variable is required for Groq provider.")

    client = Groq(api_key=api_key)

    contents = [{"type": "text", "text": "Generate one concise subtitle per image, only the text content, no numbering."}]
    for frame in frames:
        contents.append({"type": "image_url", "image_url": {"url": image_to_data_url(frame)}})

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": contents},
        ],
        temperature=0.2,
    )
    text = response.choices[0].message.content.strip()
    lines = [line.strip("- ").strip() for line in text.splitlines() if line.strip()]
    if len(lines) < len(frames):
        lines += [lines[-1] if lines else "(no significant change)" for _ in range(len(frames) - len(lines))]
    return lines[: len(frames)]


def build_srt(segments: List[Tuple[int, int]], fps: float, captions: List[str]) -> str:
    entries: List[str] = []
    for idx, ((start_f, end_f), caption) in enumerate(zip(segments, captions), start=1):
        start_s = start_f / fps
        end_s = max(start_s + 0.5, end_f / fps)  # ensure non-zero duration
        entries.append(str(idx))
        entries.append(f"{format_timestamp(start_s)} --> {format_timestamp(end_s)}")
        entries.append(caption if caption else "[No speech; scene continues]")
        entries.append("")
    return "\n".join(entries)


def main():
    parser = argparse.ArgumentParser(description="Generate SRT subtitles for a silent video using a vision model.")
    parser.add_argument("--input", required=True, help="Path to input video file")
    parser.add_argument("--output", default=None, help="Path to output SRT file (default: input.srt)")
    parser.add_argument("--provider", choices=["openai", "groq"], default="openai", help="Vision model provider")
    parser.add_argument("--model", default=None, help="Override model name (e.g., gpt-4o-mini or llama-3.2-vision)")
    parser.add_argument("--min-seconds", type=float, default=2.0, help="Minimum seconds per segment")
    parser.add_argument("--similarity", type=float, default=0.85, help="Lower means more segments (0..1)")
    parser.add_argument("--max-segments", type=int, default=0, help="Optional cap on number of segments (0 = unlimited)")

    args = parser.parse_args()

    video_path = args.input
    if not os.path.isfile(video_path):
        raise FileNotFoundError(f"Input video not found: {video_path}")

    print("[1/4] Analyzing video and detecting segments...")
    segments, duration_s, total_frames = detect_segments(
        video_path,
        min_segment_seconds=args.min_seconds,
        similarity_threshold=args.similarity,
        max_segments=(args.max_segments or None),
    )

    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    cap.release()

    if not segments:
        # Fallback: single segment for the whole video
        segments = [(0, max(0, total_frames - 1))]

    print(f"Detected {len(segments)} segments across {duration_s:.1f}s ({total_frames} frames at {fps:.2f} fps)")

    print("[2/4] Extracting representative frames...")
    frames = extract_representative_frames(video_path, segments)

    system_prompt = (
        "You are generating subtitles for a silent video. For each provided image, output a concise, human-friendly subtitle that describes what is happening, including any visible on-screen text if relevant."
        " Keep each line under 100 characters. Do not include numbering or timestamps—only the subtitle text, one line per image, in order."
    )

    provider = args.provider
    model = args.model
    print("[3/4] Captioning segments with", provider, "...")
    if provider == "openai":
        model = model or "gpt-4o-mini"
        captions = caption_with_openai(frames, system_prompt=system_prompt, model=model)
    else:
        model = model or "llama-3.2-vision"
        captions = caption_with_groq(frames, system_prompt=system_prompt, model=model)

    print("[4/4] Writing SRT file...")
    srt_text = build_srt(segments, fps=fps, captions=captions)
    output_path = args.output or os.path.splitext(video_path)[0] + ".srt"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(srt_text)
    print(f"Done. Subtitles written to: {output_path}")


if __name__ == "__main__":
    main()


