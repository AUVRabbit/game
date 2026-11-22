"""把全量审计的截图/视频帧整理为交付物：技能总览图 + 操作视频。"""
from pathlib import Path
import json

from PIL import Image, ImageDraw
import imageio.v2 as imageio

ROOT = Path(r"C:\Users\l\Documents\GitHub\game\通天入地\docs\FULL_TEST_2026-11-22")
FRAMES = ROOT / "frames"
SKILLS = ROOT / "skills"
SCREENSHOTS = ROOT / "screenshots"
VIDEO = ROOT / "video" / "full_audit_operation.mp4"


def contact_sheet(folder: Path, out: Path, cols: int, thumb: tuple[int, int], pattern: str = "*.jpg", label: bool = True) -> None:
    files = sorted(folder.glob(pattern))
    if not files:
        print(f"[skip] no images in {folder}")
        return
    rows = (len(files) + cols - 1) // cols
    tw, th = thumb
    sheet = Image.new("RGB", (cols * tw, rows * (th + 18)), (28, 28, 34))
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(files):
        img = Image.open(path).convert("RGB")
        img.thumbnail((tw, th))
        x = (i % cols) * tw
        y = (i // cols) * (th + 18)
        sheet.paste(img, (x, y))
        if label:
            draw.text((x + 4, y + th + 2), path.stem[:42], fill=(225, 225, 225))
    sheet.save(out, quality=88)
    print(f"[ok] {out.name}: {len(files)} images, {sheet.width}x{sheet.height}")


def make_video() -> None:
    frames = sorted(FRAMES.glob("*.jpg"))
    if not frames:
        print("[skip] no frames")
        return
    writer = imageio.get_writer(
        str(VIDEO),
        fps=12,
        codec="libx264",
        quality=7,
        output_params=["-pix_fmt", "yuv420p", "-movflags", "+faststart"],
    )
    for i, path in enumerate(frames):
        writer.append_data(imageio.imread(path))
        if (i + 1) % 20 == 0:
            print(f"  video frame {i + 1}/{len(frames)}")
    writer.close()
    print(f"[ok] {VIDEO.name}: {len(frames)} frames, {len(frames) / 12:.1f}s")


def main() -> None:
    contact_sheet(SKILLS, ROOT / "skill_contact_sheet.jpg", 6, (320, 180))
    contact_sheet(SCREENSHOTS, ROOT / "feature_contact_sheet.jpg", 4, (320, 180))
    make_video()
    results = json.loads((ROOT / "logs" / "results.json").read_text(encoding="utf-8"))
    print(
        "SUMMARY checks=%d/%d skills=%d/%d shots=%d frames=%d"
        % (
            results["checks_pass"],
            results["checks_total"],
            results["skills_pass"],
            results["skills_total"],
            results["screenshots"],
            results["video_frames"],
        )
    )


if __name__ == "__main__":
    main()
